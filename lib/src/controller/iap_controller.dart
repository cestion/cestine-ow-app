import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/iap_config.dart';
import '../core/result.dart';
import '../core/story_logger.dart';
import '../data/repository/iap_pending_queue_repository.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/iap_repository.dart';
import '../services/iap_store_service.dart';
import 'iap_state.dart';
import 'story_controller_mixin.dart';

/// IAP purchase state machine + anti-loss reconcile (design §6).
///
/// Responsibilities:
/// 1. Global `purchaseStream` subscription (design §6.3);
/// 2. Startup / login reconcile of the local pending queue (design §6.1);
/// 3. Buy flow: in-flight guard → createOrder → buyConsumable(autoConsume:false);
/// 4. Cross-account settle (design §6.4 / §12.4).
///
/// The local queue is deliberately NOT cleared on logout — this controller
/// only resets transient UI state.
class IapController extends Notifier<IapState>
    with StoryControllerMixin<IapState> {
  static const _tag = 'IapController';

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  StreamSubscription<bool>? _authSub;

  /// 正在轮询的订单（防 reconcile 与 finish 流程重复起轮询器）。
  final Set<String> _activePollOrderIds = {};

  IapRepository get _iap => ref.read(iapRepositoryProvider);
  IapStoreService get _store => ref.read(iapStoreServiceProvider);
  Future<IapPendingQueueRepository> get _queue =>
      ref.read(iapPendingQueueRepositoryProvider.future);

  @override
  IapState build() {
    _purchaseSub = _store.purchaseStream.listen(_onPurchaseDetails);
    ref.onDispose(() => _purchaseSub?.cancel());

    final authNotifier = ref.read(authControllerProvider.notifier);
    _authSub = authNotifier.authStateChanges.listen((loggedIn) {
      if (loggedIn) {
        unawaited(_onLoggedIn());
      } else {
        state = state.copyWith(
          clearPurchasing: true,
          isPurchasing: false,
          isCrediting: false,
          clearLastError: true,
        );
      }
    });
    ref.onDispose(() => _authSub?.cancel());

    if (ref.read(authControllerProvider).isLoggedIn) {
      unawaited(_onLoggedIn());
    }
    return const IapState();
  }

  @override
  IapState copyWithLoadingState({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return state.copyWith(
      isLoading: isLoading,
      lastError: lastError,
      clearLastError: clearLastError,
    );
  }

  String? get _currentUserId => ref.read(authControllerProvider).userId;

  bool get _isLoggedIn => ref.read(authControllerProvider).isLoggedIn;

  Future<void> _onLoggedIn() async {
    final queue = await _queue;
    final userId = _currentUserId;
    if (userId != null) {
      await queue.setLastLoggedInUserId(userId);
    }
    await reconcile();
  }

  /// Loads the server-provided product catalog (design §7.1 / P7).
  Future<void> loadProducts() async {
    state = state.copyWith(isProductsLoading: true, clearLastError: true);
    final result = await _iap.getProducts();
    if (!ref.mounted) return;
    if (result.isSuccess) {
      final products = result.dataOrNull!
          .where((IapProduct p) => p.active)
          .toList(growable: false);
      state = state.copyWith(isProductsLoading: false, products: products);
    } else {
      // 缓存兜底已由仓储处理；仍失败则保留上次列表（可能为空）。
      state = state.copyWith(
        isProductsLoading: false,
        lastError: result.errorOrNull,
      );
    }
  }

  /// Full anti-loss reconcile (design §6.1): local queue → 先查后报;
  /// server pending orders → deliver on re-login.
  Future<void> reconcile() async {
    final queue = await _queue;
    if (!_isLoggedIn) return;
    state = state.copyWith(isReconciling: true, clearLastError: true);

    for (final item in queue.getNonDone()) {
      switch (item.state) {
        case IapPendingState.waitingServer:
          await _reconcileItem(item);
        case IapPendingState.recharging:
          // 已受理待终态：冷启动/重登续轮询。不 await——轮询窗口长达
          // 数分钟，串行会阻塞 reconcile 与 isReconciling 状态。
          final orderId = item.orderId;
          if (orderId != null) {
            unawaited(_pollOrderRecharge(orderId, item));
          }
        case IapPendingState.pendingInit:
          // createOrder 中断（杀 App）：购买从未发起，超时清理防永久泄漏。
          if (DateTime.now().difference(item.createdAt) >
              IapConfig.pendingInitStale) {
            await queue.remove(item.clientOrderId);
          }
        case IapPendingState.pendingPurchase:
          // 订单已建但购买从未拉起/事件丢失：无交易可重放，超时清理防
          // hasInFlight 永久卡死同 SKU 复购（服务端订单由超时机制兜底）。
          if (DateTime.now().difference(item.createdAt) >
              IapConfig.pendingPurchaseStale) {
            await queue.remove(item.clientOrderId);
          }
        case IapPendingState.pendingDelivery:
        // 服务端已按 StoreKit 交易归属；本机等待原账号重登后通过
        // 未完成交易重扫/查询处理。
        case IapPendingState.failed:
        case IapPendingState.cancelled:
        case IapPendingState.orphaned:
        case IapPendingState.done:
          break;
      }
    }

    // (Android) queryPastPurchases 兜底：purchaseStream 漏推的未 consume
    // 购买逐条对账（design §6.1 步骤 3 / §10.1 #7）。iOS 上为 no-op。
    await _reconcilePastPurchases();

    state = state.copyWith(isReconciling: false);
  }

  /// Buy flow (design §6.2). [productDetails] is the store-side details from
  /// `queryProductDetails(server identifiers)`.
  Future<bool> buy(IapProduct product, ProductDetails productDetails) async {
    final queue = await _queue;
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      StoryLogger.w('buy rejected: not logged in', tag: _tag);
      state = state.copyWith(lastError: ApiError.unauthorized('Not logged in'));
      return false;
    }
    // 同 SKU 在途守卫：跨会话也生效（设计 §6.2/§12.1）。配套清理见
    // reconcile 中 pendingInit/pendingPurchase 超时移除，防永久卡死。
    if (queue.hasInFlight(product.productId, userId)) {
      StoryLogger.w(
        'buy rejected: ${product.productId} in flight for user $userId',
        tag: _tag,
      );
      state = state.copyWith(
        // message 用作 l10nError 映射键（story_l10n.dart）。
        lastError: ApiError.business(IapErrorCode.orderInFlight, 'iapOrderInFlight'),
      );
      return false;
    }
    if (!await _store.isAvailable()) {
      StoryLogger.w('buy rejected: store not available', tag: _tag);
      state = state.copyWith(
        lastError: ApiError.notSupported('Store not available'),
      );
      return false;
    }

    final clientOrderId = _newClientOrderId();
    final item = IapPendingItem.create(
      clientOrderId: clientOrderId,
      productId: product.productId,
      userId: userId,
    );
    await queue.upsert(item); // pendingInit
    StoryLogger.e(
      'buy start: clientOrderId=$clientOrderId productId=${product.productId} '
      'userId=$userId channel=${_currentChannel.apiValue}',
      tag: _tag,
    );

    state = state.copyWith(
      isPurchasing: true,
      purchasingProductId: product.productId,
      isCrediting: false,
      clearLastError: true,
    );

    final createResult = await _iap.createOrder(
      IapCreateOrderRequest(
        paymentChannel: _currentChannel.apiValue,
        productId: product.productId,
      ),
    );
    if (createResult.isFailure) {
      StoryLogger.w(
        'createOrder failed: ${createResult.errorOrNull}',
        tag: _tag,
      );
      await queue.remove(clientOrderId);
      state = state.copyWith(
        isPurchasing: false,
        clearPurchasing: true,
        lastError: createResult.errorOrNull,
      );
      return false;
    }
    final order = createResult.dataOrNull;
    if (order == null) {
      StoryLogger.w('createOrder returned empty order', tag: _tag);
      await queue.remove(clientOrderId);
      state = state.copyWith(isPurchasing: false, clearPurchasing: true);
      return false;
    }
    await queue.upsert(
      item.copyWith(
        orderId: order.orderId,
        paymentChannel: order.paymentChannel ?? _currentChannel.apiValue,
        providerAccountId: order.providerAccountId,
        state: IapPendingState.pendingPurchase,
      ),
    );
    StoryLogger.e(
      'createOrder ok: orderId=${order.orderId} '
      'providerAccountId=${order.providerAccountId} '
      'tokenAmount=${order.tokenAmount} status=${order.status}',
      tag: _tag,
    );

    int launched;
    try {
      launched = await _store
          .buyConsumable(
            productDetails,
            providerAccountId: order.providerAccountId ?? order.orderId,
          )
          .then((ok) => ok ? 1 : 0);
    } catch (e) {
      // 容错：插件抛异常（平台通道/商品态异常等）→ 清理本次下单，可重试。
      launched = -1;
      StoryLogger.w('buyConsumable threw: $e', tag: _tag);
    }
    if (launched != 1) {
      // 商店拒绝/未拉起支付页/抛异常 → 清理本次下单，可重试。
      await queue.remove(clientOrderId);
      state = state.copyWith(isPurchasing: false, clearPurchasing: true);
      if (launched == -1) {
        state = state.copyWith(
          lastError: ApiError.unknown('Store purchase failed to launch'),
        );
      }
      StoryLogger.w(
        'buyConsumable launch failed (code=$launched) for $clientOrderId',
        tag: _tag,
      );
      return false;
    }
    StoryLogger.e(
      'buyConsumable launched: orderId=${order.orderId} '
      'storeProductId=${productDetails.id}',
      tag: _tag,
    );
    return true;
  }

  /// purchaseStream handler — the anti-loss core (design §6.3).
  Future<void> _onPurchaseDetails(List<PurchaseDetails> details) async {
    final queue = await _queue;
    for (final p in details) {
      StoryLogger.e(
        'purchaseStream: status=${p.status.name} productID=${p.productID} '
        'purchaseID=${p.purchaseID}',
        tag: _tag,
      );
      switch (p.status) {
        case PurchaseStatus.purchased:
          await _handlePurchased(queue, p);
        case PurchaseStatus.error:
          StoryLogger.w('Purchase error: ${p.error}', tag: _tag);
          if (_isItemAlreadyOwned(p)) {
            // ITEM_ALREADY_OWNED（design §9.7）：存在未 consume 的旧购买阻塞
            // 复购。清掉本次在途记录并触发 queryPastPurchases 补单，补完即可
            // 复购；不作为购买失败提示。
            await _clearInFlightForCurrentPurchase(queue);
            unawaited(_reconcilePastPurchases());
            return;
          }
          // 收尾本次异常交易：Android / iOS 均需 completePurchase（插件要求
          // finish/consume，否则异常交易滞留队列）。
          await _store.completePurchase(p);
          // 清理对应的在途队列项，否则 pendingPurchase 会永久阻塞同 SKU 复购。
          await _markPendingTerminal(queue, p, IapPendingState.cancelled);
          final errorMessage = p.error?.message;
          state = state.copyWith(
            isPurchasing: false,
            clearPurchasing: true,
            lastError: ApiError.unknown(
              (errorMessage == null || errorMessage.isEmpty)
                  ? 'Purchase failed'
                  : errorMessage,
            ),
          );
        case PurchaseStatus.canceled:
          await _cancelPending(queue, p);
        case PurchaseStatus.pending:
        case PurchaseStatus.restored:
          break;
      }
    }
  }

  Future<void> _handlePurchased(
    IapPendingQueueRepository queue,
    PurchaseDetails p,
  ) async {
    final channel = _store.isGooglePurchase(p)
        ? IapPaymentChannel.google.apiValue
        : IapPaymentChannel.apple.apiValue;
    // 去重：同一 storeTransactionId 只处理一次。
    var item = p.purchaseID != null
        ? queue.getByStoreTransactionId(p.purchaseID!)
        : null;
    item ??= queue.getInFlightFor(p.productID, _currentUserId ?? '');
    if (item != null &&
        item.state == IapPendingState.failed &&
        item.retryCount >= IapConfig.failedReplayMaxAttempts) {
      // 同一笔失败交易已重放过多次：跳过，防冷启动无限重验（design §12.1）。
      StoryLogger.w(
        'skip replaying failed item '
        '${item.storeTransactionId}(retries=${item.retryCount})',
        tag: _tag,
      );
      return;
    }
    if (item == null) {
      // 遗留交易（本机无记录）：按最后登录账号尽力归属。
      final userId = _currentUserId ?? queue.getLastLoggedInUserId() ?? '';
      item =
          IapPendingItem.create(
            clientOrderId: _newClientOrderId(),
            productId: p.productID,
            userId: userId,
          ).copyWith(
            state: IapPendingState.orphaned,
            paymentChannel: channel,
            storeTransactionId: p.purchaseID,
            verificationData: p.verificationData.serverVerificationData,
          );
    } else {
      item = item.copyWith(
        paymentChannel: item.paymentChannel ?? channel,
        storeTransactionId: p.purchaseID ?? item.storeTransactionId,
        verificationData: p.verificationData.serverVerificationData,
        state: IapPendingState.waitingServer,
      );
    }
    await queue.upsert(item);
    StoryLogger.e(
      'purchased handled: state=${item.state.name} '
      'clientOrderId=${item.clientOrderId} orderId=${item.orderId} '
      'storeTxnId=${item.storeTransactionId}',
      tag: _tag,
    );
    await _reconcileItem(item, purchase: p);
  }

  /// 先查后报 → verify → 终态处理 / settle-foreign / 重试 (Apple IAP 契约 §5/§8)。
  Future<void> _reconcileItem(
    IapPendingItem item, {
    PurchaseDetails? purchase,
    int attempt = 0,
  }) async {
    final queue = await _queue;
    final current = item.copyWith(retryCount: item.retryCount + 1);
    await queue.upsert(current);

    final orderId = current.orderId;
    final txnId = current.storeTransactionId;
    final verification = current.verificationData;

    // 1) 先查后报：终态直接处理，RECHARGING 转入轮询。
    if (orderId != null) {
      final orderResult = await _iap.getOrder(orderId);
      if (orderResult.isSuccess) {
        final order = orderResult.dataOrNull;
        if (order != null) {
          StoryLogger.e(
            'reconcile getOrder($orderId): status=${order.status} '
            '(${order.statusName}) settled=${order.isSettled} '
            'accepted=${order.isAccepted} failed=${order.isFailed}',
            tag: _tag,
          );
          if (order.isSettled) {
            await _finishAndSignalSuccess(
              current,
              purchase,
              tokenAmount: order.tokenAmount,
            );
            return;
          }
          if (order.isAccepted) {
            await _finishAndMarkRecharging(current, purchase);
            return;
          }
          if (order.isFailed) {
            await _handleTerminalFailure(
              current,
              order.statusName ?? 'UNKNOWN',
              purchase: purchase,
            );
            return;
          }
        }
      }
    }

    // 2) 验真。
    if (orderId != null && txnId != null && verification != null) {
      final isGoogle =
          current.paymentChannel == IapPaymentChannel.google.apiValue;
      StoryLogger.e(
        'verify start: channel=${current.paymentChannel} orderId=$orderId '
        'attempt=$attempt txnId=$txnId',
        tag: _tag,
      );
      final result = isGoogle
          ? await _iap.verifyGoogleOrder(
              IapGoogleVerifyRequest(
                orderId: orderId,
                purchaseToken: verification,
              ),
            )
          : await _iap.verifyAppleOrder(
              IapAppleVerifyRequest(
                orderId: orderId,
                signedTransactionInfo: verification,
              ),
            );
      if (result.isSuccess) {
        final order = result.dataOrNull;
        if (order != null) {
          StoryLogger.e(
            'verify result: status=${order.status} (${order.statusName}) '
            'tokenAmount=${order.tokenAmount} '
            'providerTransactionId=${order.providerTransactionId}',
            tag: _tag,
          );
          if (order.isSettled) {
            await _finishAndSignalSuccess(
              current,
              purchase,
              tokenAmount: order.tokenAmount,
            );
            return;
          }
          if (order.isAccepted) {
            await _finishAndMarkRecharging(current, purchase);
            return;
          }
          if (order.isFailed) {
            await _handleTerminalFailure(
              current,
              order.statusName ?? 'UNKNOWN',
              purchase: purchase,
            );
            return;
          }
        }
        // 其它中间态（PENDING_PAYMENT/PAID）→ 保留等待下次。
      }
      final err = result.errorOrNull;
      if (err is BusinessError) {
        if (err.code == IapErrorCode.ownerMismatch) {
          // 跨账号：结算释放商店阻塞，订单仍归原账号。
          await _settleForeign(current, purchase);
          return;
        }
        if (_isRetryableError(err.code)) {
          if (attempt < IapConfig.verifyMaxAttempts) {
            final delay = _retryDelay(attempt);
            StoryLogger.w(
              'verify retryable(${err.code}) attempt=$attempt, retry in $delay',
              tag: _tag,
            );
            await Future<void>.delayed(delay);
            if (!ref.mounted) return;
            await _reconcileItem(
              current,
              purchase: purchase,
              attempt: attempt + 1,
            );
            return;
          }
          // 重试耗尽 → 保留 waitingServer，下次启动/登录再试。
        } else {
          // 明确校验失败（如 110101）→ finish（Apple）、置 failed 保留记录上报。
          await _markFailedKeep(current, err.message, purchase: purchase);
          return;
        }
      }
      // 网络/超时/其它 → 保留 waitingServer 下次启动重试；不 finish（P2）。
    }

    // 3) 无服务端订单（遗留/orphaned）：结算商店、标记待原账号到账。
    if (orderId == null && purchase != null) {
      await _settleForeign(current, purchase);
    }
  }

  /// RECHARGING/RECHARGED 已受理：finish() 并移除本地记录，仅终态 RECHARGED
  /// 触发成功信号（契约 §5.3 / §7）。
  Future<void> _finishAndSignalSuccess(
    IapPendingItem item,
    PurchaseDetails? purchase, {
    String? tokenAmount,
  }) async {
    final queue = await _queue;
    final p = purchase;
    if (p != null && _shouldFinishStore(item, p)) {
      await _store.completePurchase(p);
    }
    await queue.remove(item.clientOrderId);
    StoryLogger.e(
      'purchase settled: orderId=${item.orderId} productId=${item.productId} '
      'granted=$tokenAmount '
      'userId=${item.userId} currentUserId=$_currentUserId '
      'signal=${item.userId == _currentUserId ? 'ON' : 'SKIPPED'}',
      tag: _tag,
    );
    if (item.userId == _currentUserId) {
      state = state.copyWith(
        isPurchasing: false,
        clearPurchasing: true,
        clearFailedReason: true,
        isCrediting: false,
        lastFulfilledProductId: item.productId,
        // tokenAmount（应发放资产）原始字符串，展示格式化交给 view 层。
        lastGrantedAmount: tokenAmount,
        clearLastError: true,
      );
      // 到账后刷新链上钱包余额（未设置钱包地址时内部自动跳过）。
      unawaited(ref.read(onChainWalletBalanceProvider.notifier).refresh());
    }
  }

  /// RECHARGING：可 finish() 但尚未到账。保留记录（state=recharging）供冷启动/
  /// 重登续轮询，不触发成功弹窗。
  Future<void> _finishAndMarkRecharging(
    IapPendingItem item,
    PurchaseDetails? purchase,
  ) async {
    final queue = await _queue;
    final p = purchase;
    if (p != null && _shouldFinishStore(item, p)) {
      await _store.completePurchase(p);
    }
    await queue.upsert(item.copyWith(state: IapPendingState.recharging));
    StoryLogger.e(
      'order recharging: orderId=${item.orderId} productId=${item.productId} '
      '→ polling',
      tag: _tag,
    );
    // 到账处理中：UI 提示、禁止再次购买（跨账号重放不打扰当前用户）。
    if (item.userId == _currentUserId) {
      state = state.copyWith(
        isPurchasing: false,
        clearPurchasing: true,
        isCrediting: true,
      );
    }
    final orderId = item.orderId;
    if (orderId != null) {
      unawaited(_pollOrderRecharge(orderId, item));
    }
  }

  /// 终态失败（PAY_FAILED / RECHARGE_FAILED）：移除本地记录并上报失败原因。
  ///
  /// RECHARGE_FAILED 意味着已扣款，若验单时订单已快速转移到终态（未经
  /// recharging 轮询路径），交易尚未 finish → Apple 端 finish 防重放死循环。
  Future<void> _handleTerminalFailure(
    IapPendingItem item,
    String reason, {
    PurchaseDetails? purchase,
  }) async {
    final queue = await _queue;
    final p = purchase;
    if (p != null && _shouldFinishStore(item, p)) {
      await _store.completePurchase(p);
    }
    if (item.userId == _currentUserId) {
      state = state.copyWith(
        isPurchasing: false,
        clearPurchasing: true,
        clearFulfilledSignal: true,
        isCrediting: false,
        lastFailedReason: reason,
        clearLastError: true,
      );
    }
    await queue.remove(item.clientOrderId);
    StoryLogger.w(
      'order terminal failure: orderId=${item.orderId} reason=$reason',
      tag: _tag,
    );
  }

  /// 明确校验失败（不可重试）：置 failed 保留记录便于上报/排查。
  ///
  /// Apple 侧 finish 该交易（钱已扣，finish 只是出队；`Transaction.all` 历史
  /// 仍可查），否则每次冷启动 purchaseStream 重放同一交易 → 再验单 → 再失败
  /// 的死循环。Google 不 finish（后端 consume，客户端禁 ack）。
  Future<void> _markFailedKeep(
    IapPendingItem item,
    String reason, {
    PurchaseDetails? purchase,
  }) async {
    final queue = await _queue;
    final p = purchase;
    if (p != null && _shouldFinishStore(item, p)) {
      await _store.completePurchase(p);
    }
    await queue.upsert(item.copyWith(state: IapPendingState.failed));
    StoryLogger.w(
      'verify rejected: orderId=${item.orderId} reason=$reason '
      '→ failed(kept)',
      tag: _tag,
    );
    if (item.userId == _currentUserId) {
      state = state.copyWith(
        isPurchasing: false,
        clearPurchasing: true,
        isCrediting: false,
        lastFailedReason: reason,
        clearLastError: true,
      );
    }
  }

  /// RECHARGING 后轮询 getOrder 直到终态（RECHARGED → 成功；PAY_FAILED /
  /// RECHARGE_FAILED → 失败）。超时保留记录，冷启动/重登续轮询。
  Future<void> _pollOrderRecharge(String orderId, IapPendingItem item) async {
    // 去重：reconcile 续轮询与 finish 流程可能同时触发同一订单。
    if (!_activePollOrderIds.add(orderId)) return;
    try {
      var attempt = 0;
      const maxAttempts = 24; // 5s × 24 ≈ 2min 一次会话内的轮询窗口
      while (attempt < maxAttempts) {
        await Future<void>.delayed(const Duration(seconds: 5));
        if (!ref.mounted) return;
        final result = await _iap.getOrder(orderId);
        if (!ref.mounted) return;
        if (result.isSuccess) {
          final order = result.dataOrNull;
          if (order != null) {
            StoryLogger.e(
              'poll($attempt/$maxAttempts) orderId=$orderId: '
              'status=${order.status} (${order.statusName})',
              tag: _tag,
            );
            if (order.isSettled) {
              await _finishAndSignalSuccess(
                item,
                null,
                tokenAmount: order.tokenAmount,
              );
              return;
            }
            if (order.isFailed) {
              await _handleTerminalFailure(
                item,
                order.statusName ?? 'UNKNOWN',
              );
              return;
            }
          }
        }
        attempt++;
      }
      // 轮询窗口结束仍未终态：保留 recharging 记录，冷启动/重登续轮询；
      // 解除全局购买阻塞（到账由队列记录驱动，终态仍会出结果弹窗）。
      if (ref.mounted && item.userId == _currentUserId) {
        state = state.copyWith(isCrediting: false);
      }
    } finally {
      _activePollOrderIds.remove(orderId);
    }
  }

  /// 可退避重试的业务错误码（IAP v2.0.0 契约 §9）。
  static bool _isRetryableError(int code) =>
      code == IapErrorCode.appleServerUnavailable ||
      code == IapErrorCode.googleServerUnavailable ||
      code == IapErrorCode.concurrentUpdateFailed ||
      code == IapErrorCode.operatorWithdrawFailed;

  /// 指数退避：base × factor^attempt（30s → 60s → 120s → …）。
  static Duration _retryDelay(int attempt) {
    final base = IapConfig.verifyRetryInitialDelay.inMilliseconds;
    const factor = IapConfig.verifyRetryBackoffFactor;
    return Duration(milliseconds: (base * pow(factor, attempt)).round());
  }

  /// 跨账号结算（design §6.4）：保留记录置 pendingDelivery，complete 只释放
  /// 商店阻塞；服务端订单仍绑定原 userId，原账号重登通过 pendingOrders 到账。
  Future<void> _settleForeign(
    IapPendingItem item,
    PurchaseDetails? purchase,
  ) async {
    final queue = await _queue;
    await queue.upsert(item.copyWith(state: IapPendingState.pendingDelivery));
    StoryLogger.e(
      'settle foreign: orderId=${item.orderId} ownerUserId=${item.userId} '
      'currentUserId=$_currentUserId',
      tag: _tag,
    );
    final p = purchase;
    if (p != null && _shouldFinishStore(item, p)) {
      await _store.completePurchase(p);
    }
    state = state.copyWith(
      lastSettledForeignUserId: item.userId,
      isPurchasing: false,
      clearPurchasing: true,
    );
  }

  /// Android 兜底：查询未 consume 的历史购买并对账（design §10.1 #7）。
  ///
  /// 场景：purchaseStream 漏推（Billing 断连/进程被杀）、ITEM_ALREADY_OWNED
  /// 阻塞复购。逐条走 [_handlePurchased]，本地按 storeTransactionId 去重，
  /// 服务端幂等，重复调用安全。
  Future<void> _reconcilePastPurchases() async {
    final purchases = await _store.queryPastPurchases();
    if (!ref.mounted || purchases.isEmpty) return;
    final queue = await _queue;
    for (final p in purchases) {
      if (!ref.mounted) return;
      await _handlePurchased(queue, p);
    }
  }

  /// Android `ITEM_ALREADY_OWNED`：插件对错误结果构造空壳 PurchaseDetails
  /// （productID 为空），错误 message 携带 `BillingResponse.itemAlreadyOwned`。
  static bool _isItemAlreadyOwned(PurchaseDetails p) =>
      p.error?.message.contains('itemAlreadyOwned') ?? false;

  /// 清理当前购买流程的在途队列项（ITEM_ALREADY_OWNED 时 productID 为空，
  /// 无法按 SKU 匹配，改按 state.purchasingProductId 清理）。
  Future<void> _clearInFlightForCurrentPurchase(
    IapPendingQueueRepository queue,
  ) async {
    final item = _currentInFlightItem(queue);
    if (item == null) return;
    await queue.upsert(item.copyWith(state: IapPendingState.cancelled));
    state = state.copyWith(isPurchasing: false, clearPurchasing: true);
  }

  Future<void> _cancelPending(
    IapPendingQueueRepository queue,
    PurchaseDetails p,
  ) async {
    await _markPendingTerminal(queue, p, IapPendingState.cancelled);
    state = state.copyWith(isPurchasing: false, clearPurchasing: true);
  }

  /// Marks the in-flight queue entry for [p]'s product/user as [terminal].
  /// Used for terminal statuses (error / canceled) so a stale
  /// `pendingPurchase` never permanently blocks re-purchase (design §12.1).
  ///
  /// 插件对 canceled/error 构造的 PurchaseDetails 可能是空壳（productID /
  /// purchaseID 为空，getInFlightFor 匹配不到）→ 兜底按
  /// `state.purchasingProductId` 清理当前购买流程的在途项。
  Future<void> _markPendingTerminal(
    IapPendingQueueRepository queue,
    PurchaseDetails p,
    IapPendingState terminal,
  ) async {
    final userId = _currentUserId ?? '';
    var item = (p.productID.isNotEmpty)
        ? queue.getInFlightFor(p.productID, userId)
        : null;
    item ??= _currentInFlightItem(queue);
    if (item == null) return;
    await queue.upsert(
      item.copyWith(
        state: terminal,
        storeTransactionId: p.purchaseID ?? item.storeTransactionId,
      ),
    );
  }

  /// 当前购买流程的在途队列项（canceled/error 空壳事件按
  /// `state.purchasingProductId` 匹配）。
  IapPendingItem? _currentInFlightItem(IapPendingQueueRepository queue) {
    final productId = state.purchasingProductId;
    final userId = _currentUserId;
    if (productId == null || userId == null) return null;
    return queue.getInFlightFor(productId, userId);
  }

  /// Clears the transient fulfillment / settle signal (view calls after toast).
  void clearTransientSignals() {
    state = state.copyWith(
      clearFulfilledSignal: true,
      clearFailedReason: true,
      clearSettledForeign: true,
      clearLastError: true,
    );
  }

  /// 当前设备支付渠道：iOS → APPLE，其它 → GOOGLE。
  IapPaymentChannel get _currentChannel => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => IapPaymentChannel.apple,
    _ => IapPaymentChannel.google,
  };

  /// 是否可在本端 finish/consume：Apple 验单受理后调用；Google 客户端不
  /// consume/acknowledge（后端 consume），孤儿订单按 [PurchaseDetails] 判断。
  bool _shouldFinishStore(IapPendingItem item, PurchaseDetails? purchase) {
    if (purchase == null) return false;
    if (item.paymentChannel == IapPaymentChannel.google.apiValue) return false;
    if (_store.isGooglePurchase(purchase)) return false;
    return true;
  }

  static String _newClientOrderId() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '-${random.nextInt(1 << 32).toRadixString(36)}';
  }
}
