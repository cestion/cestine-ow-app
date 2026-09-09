import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/request_coalescer.dart';
import '../core/request_keys.dart';
import '../core/result.dart';
import '../core/story_logger.dart';
import '../core/wallet_balance_errors.dart';
import '../data/repository/story_local_repository.dart';
import '../model/models.dart';
import '../services/wallet_ledger.dart';
import 'config_providers.dart';
import 'core_providers.dart';
import 'repository_providers.dart';

class WalletBalanceState extends Equatable {
  final double usdcBalance;
  final double storyBalance;
  final double evmUsdcBalance;
  final double evmStoryBalance;
  final bool isLoading;

  const WalletBalanceState({
    this.usdcBalance = 0,
    this.storyBalance = 0,
    this.evmUsdcBalance = 0,
    this.evmStoryBalance = 0,
    this.isLoading = false,
  });

  WalletBalanceState copyWith({
    double? usdcBalance,
    double? storyBalance,
    double? evmUsdcBalance,
    double? evmStoryBalance,
    bool? isLoading,
  }) {
    return WalletBalanceState(
      usdcBalance: usdcBalance ?? this.usdcBalance,
      storyBalance: storyBalance ?? this.storyBalance,
      evmUsdcBalance: evmUsdcBalance ?? this.evmUsdcBalance,
      evmStoryBalance: evmStoryBalance ?? this.evmStoryBalance,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    usdcBalance,
    storyBalance,
    evmUsdcBalance,
    evmStoryBalance,
    isLoading,
  ];
}

class WalletBalanceNotifier extends Notifier<WalletBalanceState> {
  late RequestCoalescer _coalescer;

  /// Bumped in [clear] so in-flight refresh cannot rewrite balances after logout.
  int _refreshEpoch = 0;

  @override
  WalletBalanceState build() {
    _coalescer = ref.read(requestCoalescerProvider);
    final localRepo = ref.read(localRepositoryProvider);
    final cacheBox = localRepo.cacheBox;
    final cachedUsdc = _readDouble(cacheBox.get('wallet_balance_usdc'));
    final cachedStory = _readDouble(cacheBox.get('wallet_balance_story'));
    final cachedEvmUsdc = _readDouble(cacheBox.get('wallet_balance_evm_usdc'));
    final cachedEvmStory = _readDouble(
      cacheBox.get('wallet_balance_evm_story'),
    );

    // Do not listen to authControllerProvider or globalConfigProvider here.
    // - Auth already calls refresh() after login/restore (and clear() on logout).
    // - Listening Auth while Auth also reads this provider → CircularDependencyError.
    // - Listening globalConfig fires refresh before the Solana address is persisted
    //   ("refresh skipped: solanaAddress is empty").
    // UI entry points (drawer / deposit / withdraw) also call refresh() when needed.

    return WalletBalanceState(
      usdcBalance: cachedUsdc ?? 0.0,
      storyBalance: cachedStory ?? 0.0,
      evmUsdcBalance: cachedEvmUsdc ?? 0.0,
      evmStoryBalance: cachedEvmStory ?? 0.0,
    );
  }

  void deduct({double usdc = 0.0, double story = 0.0}) {
    final newUsdc = (state.usdcBalance - usdc).clamp(0.0, double.infinity);
    final newStory = (state.storyBalance - story).clamp(0.0, double.infinity);

    final localRepo = ref.read(localRepositoryProvider);
    final cacheBox = localRepo.cacheBox;
    cacheBox.put('wallet_balance_usdc', newUsdc);
    cacheBox.put('wallet_balance_story', newStory);

    state = state.copyWith(usdcBalance: newUsdc, storyBalance: newStory);
  }

  void deductEvm({double usdc = 0.0, double story = 0.0}) {
    final newUsdc = (state.evmUsdcBalance - usdc).clamp(0.0, double.infinity);
    final newStory = (state.evmStoryBalance - story).clamp(
      0.0,
      double.infinity,
    );

    final localRepo = ref.read(localRepositoryProvider);
    final cacheBox = localRepo.cacheBox;
    cacheBox.put('wallet_balance_evm_usdc', newUsdc);
    cacheBox.put('wallet_balance_evm_story', newStory);

    state = state.copyWith(evmUsdcBalance: newUsdc, evmStoryBalance: newStory);
  }

  void clear() {
    _refreshEpoch++;
    final localRepo = ref.read(localRepositoryProvider);
    final cacheBox = localRepo.cacheBox;
    cacheBox.delete('wallet_balance_usdc');
    cacheBox.delete('wallet_balance_story');
    cacheBox.delete('wallet_balance_evm_usdc');
    cacheBox.delete('wallet_balance_evm_story');
    state = const WalletBalanceState();
  }

  Future<void> refresh() => _refresh(showLoading: true);

  /// Revalidates on-chain balances without replacing cached values with a
  /// loading placeholder in listening wallet UIs.
  Future<void> refreshSilently() => _refresh(showLoading: false);

  Future<void> _refresh({required bool showLoading}) {
    final key = showLoading
        ? RequestKeys.walletOnchainRefresh
        : RequestKeys.walletOnchainRefreshSilent;
    return _coalescer.run(key, () => _doRefresh(showLoading: showLoading));
  }

  /// Force-refresh then verify USDC is enough for [required].
  ///
  /// Call before any spend path; on success the caller may [deduct] then
  /// submit the chain/API transaction. Does not deduct itself.
  Future<Result<void>> ensureUsdc(double required) async {
    if (required <= 0) return Result.success(null);
    await refresh();
    if (!ref.mounted) {
      return Result.failure(ApiError.unknown('wallet disposed'));
    }
    if (state.usdcBalance < required) {
      return Result.failure(
        ApiError.business(-1, WalletBalanceErrorMessages.insufficientUsdc),
      );
    }
    return Result.success(null);
  }

  /// Force-refresh then verify STORY is enough for [required].
  Future<Result<void>> ensureStory(double required) async {
    if (required <= 0) return Result.success(null);
    await refresh();
    if (!ref.mounted) {
      return Result.failure(ApiError.unknown('wallet disposed'));
    }
    if (state.storyBalance < required) {
      return Result.failure(
        ApiError.business(-1, WalletBalanceErrorMessages.insufficientStory),
      );
    }
    return Result.success(null);
  }

  Future<void> _doRefresh({required bool showLoading}) async {
    // Logout / account switch bump [_refreshEpoch] via [clear]. Do not read
    // [currentUserIdProvider] here — that pulls Auth/ApiClient and breaks
    // wallet unit tests (and contradicts the no-auth-listen rule below).
    final epoch = _refreshEpoch;

    // Mirror web `enabled: isReady`: wait for chainlinks before querying SPL.
    final Result<GlobalConfig> configResult;
    try {
      configResult = await ref.read(globalConfigProvider.future);
    } catch (e, st) {
      StoryLogger.e(
        'refresh aborted: globalConfig failed to load',
        error: e,
        stackTrace: st,
        tag: 'WalletBalance',
      );
      return;
    }
    if (!_isRefreshSessionActive(epoch)) return;

    final config = configResult.dataOrNull;
    if (configResult.isFailure || config == null) {
      StoryLogger.w(
        'refresh skipped: globalConfig has no data '
        '(${configResult.errorOrNull?.userMessage ?? 'unknown'})',
        tag: 'WalletBalance',
      );
      return;
    }

    final svmChain = _findChain(config, 'svm');
    final evmChain = _findChain(config, 'evm');
    if (svmChain == null && evmChain == null) {
      StoryLogger.w(
        'refresh skipped: no svm/evm chain in chainlinks '
        '(keys=${config.chainlinks?.keys.toList()})',
        tag: 'WalletBalance',
      );
      return;
    }

    final localRepo = ref.read(localRepositoryProvider);
    if (showLoading) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final results = await Future.wait([
        _fetchSvmBalances(svmChain, localRepo),
        _fetchEvmBalances(evmChain, localRepo),
      ]);
      if (!_isRefreshSessionActive(epoch)) return;

      final svmResults = results[0];
      final evmResults = results[1];
      final usdcResult = svmResults.$1;
      final storyResult = svmResults.$2;
      final evmUsdcResult = evmResults.$1;
      final evmStoryResult = evmResults.$2;

      StoryLogger.d(
        'balance RPC results usdc=$usdcResult story=$storyResult '
        'evmUsdc=$evmUsdcResult evmStory=$evmStoryResult',
        tag: 'WalletBalance',
      );

      final anySuccess =
          usdcResult != null ||
          storyResult != null ||
          evmUsdcResult != null ||
          evmStoryResult != null;
      if (!anySuccess) {
        StoryLogger.w(
          'wallet balance fetch returned null for all tokens',
          tag: 'WalletBalance',
        );
        if (_isRefreshSessionActive(epoch)) {
          state = state.copyWith(isLoading: false);
        }
        return;
      }

      if (!_isRefreshSessionActive(epoch)) return;

      final usdc = usdcResult ?? state.usdcBalance;
      final story = storyResult ?? state.storyBalance;
      final evmUsdc = evmUsdcResult ?? state.evmUsdcBalance;
      final evmStory = evmStoryResult ?? state.evmStoryBalance;

      final cacheBox = localRepo.cacheBox;
      if (usdcResult != null) {
        await cacheBox.put('wallet_balance_usdc', usdc);
      }
      if (storyResult != null) {
        await cacheBox.put('wallet_balance_story', story);
      }
      if (evmUsdcResult != null) {
        await cacheBox.put('wallet_balance_evm_usdc', evmUsdc);
      }
      if (evmStoryResult != null) {
        await cacheBox.put('wallet_balance_evm_story', evmStory);
      }
      if (!_isRefreshSessionActive(epoch)) {
        // Undo puts that may have raced past logout [clear].
        await cacheBox.delete('wallet_balance_usdc');
        await cacheBox.delete('wallet_balance_story');
        await cacheBox.delete('wallet_balance_evm_usdc');
        await cacheBox.delete('wallet_balance_evm_story');
        return;
      }

      state = WalletBalanceState(
        usdcBalance: usdc,
        storyBalance: story,
        evmUsdcBalance: evmUsdc,
        evmStoryBalance: evmStory,
      );
    } catch (e, st) {
      StoryLogger.e(
        'Failed to fetch wallet balances',
        error: e,
        stackTrace: st,
        tag: 'WalletBalance',
      );
      if (_isRefreshSessionActive(epoch)) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  bool _isRefreshSessionActive(int epoch) {
    return ref.mounted && epoch == _refreshEpoch;
  }

  Future<(double?, double?)> _fetchSvmBalances(
    ChainInfo? svmChain,
    StoryLocalRepository localRepo,
  ) async {
    final rpcUrl = svmChain?.rpc?.http?.trim();
    final tokens = svmChain?.tokens;
    if (svmChain == null ||
        rpcUrl == null ||
        rpcUrl.isEmpty ||
        tokens == null ||
        tokens.isEmpty) {
      return (null, null);
    }

    final solanaAddress = await localRepo.getSolanaWalletAddressAsync() ?? '';
    if (!ref.mounted || solanaAddress.isEmpty) {
      if (solanaAddress.isEmpty) {
        StoryLogger.w(
          'svm refresh skipped: solanaAddress is empty',
          tag: 'WalletBalance',
        );
      }
      return (null, null);
    }

    final usdcMint = _findTokenAddress(tokens, 'usdc');
    final storyMint = _findTokenAddress(tokens, 'story');
    final service = ref.read(solanaTokenBalanceServiceProvider);
    final results = await Future.wait<double?>([
      if (usdcMint != null)
        service.getTokenBalance(
          rpcHttpUrl: rpcUrl,
          ownerAddress: solanaAddress,
          tokenMint: usdcMint,
        )
      else
        Future<double?>.value(),
      if (storyMint != null)
        service.getTokenBalance(
          rpcHttpUrl: rpcUrl,
          ownerAddress: solanaAddress,
          tokenMint: storyMint,
        )
      else
        Future<double?>.value(),
    ]);
    return (results[0], results[1]);
  }

  Future<(double?, double?)> _fetchEvmBalances(
    ChainInfo? evmChain,
    StoryLocalRepository localRepo,
  ) async {
    final rpcUrl = evmChain?.rpc?.http?.trim();
    final tokens = evmChain?.tokens;
    if (evmChain == null ||
        rpcUrl == null ||
        rpcUrl.isEmpty ||
        tokens == null ||
        tokens.isEmpty) {
      return (null, null);
    }

    final ethereumAddress =
        await localRepo.getEthereumWalletAddressAsync() ?? '';
    if (!ref.mounted || ethereumAddress.isEmpty) {
      if (ethereumAddress.isEmpty) {
        StoryLogger.w(
          'evm refresh skipped: ethereumAddress is empty',
          tag: 'WalletBalance',
        );
      }
      return (null, null);
    }

    final usdcToken = _findToken(tokens, 'usdc');
    final storyToken = _findToken(tokens, 'story');
    final service = ref.read(evmTokenBalanceServiceProvider);
    final results = await Future.wait<double?>([
      if (usdcToken?.address != null)
        service.getTokenBalance(
          rpcHttpUrl: rpcUrl,
          ownerAddress: ethereumAddress,
          tokenAddress: usdcToken!.address!,
          decimals: usdcToken.decimals ?? 6,
        )
      else
        Future<double?>.value(),
      if (storyToken?.address != null)
        service.getTokenBalance(
          rpcHttpUrl: rpcUrl,
          ownerAddress: ethereumAddress,
          tokenAddress: storyToken!.address!,
          decimals: storyToken.decimals ?? 18,
        )
      else
        Future<double?>.value(),
    ]);
    return (results[0], results[1]);
  }

  static ChainInfo? _findChain(GlobalConfig config, String chainType) {
    final chainlinks = config.chainlinks;
    if (chainlinks == null) return null;
    for (final chain in chainlinks.values) {
      if (chain.chainType == chainType) return chain;
    }
    return null;
  }

  static double? _readDouble(Object? v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return null;
  }
}

final onChainWalletBalanceProvider =
    NotifierProvider<WalletBalanceNotifier, WalletBalanceState>(
      WalletBalanceNotifier.new,
    );

/// On-chain spendable ledger (ensure → deduct → reconcile).
/// Claimable `/assets` balances stay in [IncomeController].
final walletLedgerProvider = Provider<WalletLedger>((ref) {
  final wallet = ref.read(onChainWalletBalanceProvider.notifier);
  return WalletLedger(
    WalletSpendPort(
      ensureUsdc: wallet.ensureUsdc,
      ensureStory: wallet.ensureStory,
      deduct: wallet.deduct,
      refresh: wallet.refreshSilently,
    ),
  );
});

/// Match web `findChainTokenByAsset`: symbol → fullSymbol → map key.
WalletToken? _findToken(Map<String, WalletToken> tokens, String symbol) {
  final target = symbol.toUpperCase();

  for (final e in tokens.entries) {
    if (e.value.symbol?.toUpperCase() == target) return e.value;
  }
  for (final e in tokens.entries) {
    if (e.value.fullSymbol?.toUpperCase() == target) return e.value;
  }
  for (final e in tokens.entries) {
    if (e.key.toUpperCase() == target) return e.value;
  }
  return null;
}

String? _findTokenAddress(Map<String, WalletToken> tokens, String symbol) {
  final address = _findToken(tokens, symbol)?.address?.trim();
  return (address != null && address.isNotEmpty) ? address : null;
}
