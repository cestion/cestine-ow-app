import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../controller/iap_state.dart';
import '../../core/core.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../services/iap_store_service.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../utils/auth_navigation.dart';
import '../../utils/format_number.dart';
import '../common/story_toast.dart';
import 'iap_point_icon.dart';
import 'iap_purchase_result_dialog.dart';

// ─── Figma 购买点数 dark 模式色值（亮暗独立） ────────────────────────
Color _sheetSurface(Brightness b) =>
    b == Brightness.dark ? StoryColors.darkBackground : StoryColors.lightCard;

Color _sheetHandle(Brightness b) => b == Brightness.dark
    ? StoryColors.darkButtonBg
    : StoryColors.lightSheetSecondary;

Color _sheetTitle(Brightness b) => b == Brightness.dark
    ? StoryColors.darkContentText
    : StoryColors.lightForeground;

Color _sheetSubtitle(Brightness b) => b == Brightness.dark
    ? StoryColors.darkPrivyFooterText
    : StoryColors.lightMutedForeground;

Color _sheetCardBg(Brightness b) => b == Brightness.dark
    ? StoryColors.darkButtonBg
    : StoryColors.lightSheetSecondary;

Color _sheetCardText(Brightness b) => b == Brightness.dark
    ? StoryColors.darkContentText
    : StoryColors.lightForeground;

/// Shows the IAP buy sheet (Figma「购买点数」). Returns when dismissed.
///
/// 未登录时跳转登录并直接返回，不弹出购买面板。
Future<void> showIapBuySheet(
  BuildContext context, {
  required WidgetRef ref,
}) async {
  if (!await ensureLoggedInOrRedirect(context, ref)) return;
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const IapBuySheet(),
  );
}

/// 购买点数 BottomSheet（Figma Story.fun-V2-ui · 购买点数）。
///
/// 商品清单来自服务端（P7），商店价格经 `queryProductDetails` 拉取；选择点数
/// 卡后点「确认购买」走 [IapController.buy]（在途拦截 → createOrder →
/// buyConsumable(autoConsume:false)）。成功/失败通过监听状态 toast 提示。
/// 余额行展示 `onChainWalletBalanceProvider.usdcBalance`。
class IapBuySheet extends ConsumerStatefulWidget {
  const IapBuySheet({super.key});

  @override
  ConsumerState<IapBuySheet> createState() => _IapBuySheetState();
}

class _IapBuySheetState extends ConsumerState<IapBuySheet> {
  String? _selectedProductId;
  Map<String, ProductDetails> _storeDetails = const {};

  IapStoreService get _store => ref.read(iapStoreServiceProvider);

  @override
  void initState() {
    super.initState();
    StoryLogger.e('IapBuySheet mounted', tag: 'IapBuySheet');
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureProducts());
  }

  @override
  void dispose() {
    StoryLogger.e('IapBuySheet disposed', tag: 'IapBuySheet');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<IapState>(iapControllerProvider, (prev, next) {
      if (next.isCrediting && prev?.isCrediting != true) {
        // 到账处理中：提示并保持 sheet，终态弹结果弹窗。
        StoryToast.info(context, context.l10n.iapCrediting);
      }
      final fulfilled = next.lastFulfilledProductId;
      if (fulfilled != null && fulfilled != prev?.lastFulfilledProductId) {
        StoryLogger.e(
          'listener: success signal productId=$fulfilled → dialog',
          tag: 'IapBuySheet',
        );
        _onResult(IapPurchaseDialogStatus.success);
      }
      final failedReason = next.lastFailedReason;
      if (failedReason != null && failedReason != prev?.lastFailedReason) {
        StoryLogger.e(
          'listener: failure signal reason=$failedReason → dialog',
          tag: 'IapBuySheet',
        );
        _onResult(IapPurchaseDialogStatus.failure, reason: failedReason);
      }
      final error = next.lastError;
      if (error != null && error != prev?.lastError) {
        _onError(error);
      }
    });

    final state = ref.watch(iapControllerProvider);
    final products = state.products;
    final selectedId = _selectedProductId;
    final points = ref.watch(onChainWalletBalanceProvider).usdcBalance;
    // 业务服务器（IapProduct：发放量/启停）+ 商店 ProductDetails（本地化价格）
    // 按 productId 合并；价格一律取 ProductDetails.price。
    final entries = [
      for (final product in products)
        _IapProductEntry(
          product: product,
          storeDetails: _storeDetails[product.productId],
        ),
    ];
    final canBuy =
        !state.isPurchasing &&
        !state.isCrediting &&
        selectedId != null &&
        _storeDetails.containsKey(selectedId);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            StorySpacing.base,
            StorySpacing.md,
            StorySpacing.base,
            bottomInset + StorySpacing.base,
          ),
          decoration: BoxDecoration(
            color: _sheetSurface(Theme.of(context).brightness),
            borderRadius: StoryRadius.sheet,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DragHandle(brightness: Theme.of(context).brightness),
              const SizedBox(height: StorySpacing.md),
              Text(
                context.l10n.iapSheetTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: _sheetTitle(Theme.of(context).brightness),
                ),
              ),
              const SizedBox(height: StorySpacing.xs),
              Text(
                context.l10n.iapSheetSubtitle,
                textAlign: TextAlign.center,
                style: StoryTextStyles.bodySmall(
                  color: _sheetSubtitle(Theme.of(context).brightness),
                ),
              ),
              const SizedBox(height: StorySpacing.base),
              _BalanceRow(
                points: points,
                brightness: Theme.of(context).brightness,
              ),
              const SizedBox(height: StorySpacing.md),
              if (state.isProductsLoading && products.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    context.l10n.iapNoProducts,
                    textAlign: TextAlign.center,
                    style: StoryTextStyles.bodySmall(
                      color: _sheetSubtitle(Theme.of(context).brightness),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: StorySpacing.sm),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _ProductRow(
                      entry: entry,
                      selected: entry.product.productId == selectedId,
                      brightness: Theme.of(context).brightness,
                      onTap: () => setState(
                        () => _selectedProductId = entry.product.productId,
                      ),
                    );
                  },
                ),
              const SizedBox(height: StorySpacing.lg),
              _FooterButton(
                label: context.l10n.iapConfirmPurchase,
                filled: true,
                brightness: Theme.of(context).brightness,
                loading: state.isPurchasing,
                onTap: canBuy ? _buy : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ensureProducts() async {
    final controller = ref.read(iapControllerProvider.notifier);
    if (ref.read(iapControllerProvider).products.isEmpty) {
      await controller.loadProducts();
    }
    if (!mounted) return;
    final products = ref.read(iapControllerProvider).products;
    if (products.isEmpty) return;

    final response = await _store.queryProductDetails(
      products.map((p) => p.productId).toSet(),
    );
    StoryLogger.e(
      '[in_app_purchase] queryProductDetails ${response.notFoundIDs.length}',
    );
    if (!mounted) return;
    if (response.error != null) {
      StoryToast.error(
        context,
        response.error?.message ?? context.l10n.iapNoProducts,
      );
      return;
    }
    final map = {for (final d in response.productDetails) d.id: d};
    setState(() {
      _storeDetails = map;
      final first = products.firstWhere(
        (p) => map.containsKey(p.productId),
        orElse: () => products.first,
      );
      _selectedProductId ??= first.productId;
    });
  }

  Future<void> _buy() async {
    final selectedId = _selectedProductId;
    if (selectedId == null) return;
    final product = ref.read(iapControllerProvider).productById(selectedId);
    final details = _storeDetails[selectedId];
    if (product == null || details == null) return;

    final ok = await ref
        .read(iapControllerProvider.notifier)
        .buy(product, details);
    if (!mounted) return;
    if (!ok) {
      final error = ref.read(iapControllerProvider).lastError;
      StoryToast.error(
        context,
        error == null
            ? context.l10n.iapPurchaseFailed
            : context.l10nError(error),
      );
    }
  }

  void _onResult(IapPurchaseDialogStatus status, {String? reason}) {
    final granted = ref.read(iapControllerProvider).lastGrantedAmount ?? '';
    ref.read(iapControllerProvider.notifier).clearTransientSignals();
    // 结果弹窗盖在 sheet 上，关闭后再收起 sheet。
    showIapPurchaseResultDialog(
      context,
      grantedAmount: granted,
      status: status,
      failureReason: reason,
    ).whenComplete(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _onError(ApiError error) {
    StoryToast.error(context, context.l10nError(error));
    ref.read(iapControllerProvider.notifier).clearTransientSignals();
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.brightness});
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: _sheetHandle(brightness),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.points, required this.brightness});
  final double points;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const IapPointIcon(),
        const SizedBox(width: StorySpacing.xs),
        Text(
          context.l10n.iapBalance,
          style: StoryTextStyles.bodyMedium(color: _sheetTitle(brightness)),
        ),
        const SizedBox(width: StorySpacing.xs),
        Text(
          formatNumber(points),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: _sheetTitle(brightness),
          ),
        ),
      ],
    );
  }
}

/// 业务商品（[IapProduct]：发放量/启停，来自业务服务器）与商店详情
/// （[ProductDetails]：本地化价格，来自 `in_app_purchase`）按 `productId`
/// 合并的结果。展示价格一律取 [ProductDetails.price]。
class _IapProductEntry {
  const _IapProductEntry({required this.product, this.storeDetails});

  final IapProduct product;

  /// 商店本地化商品详情；缺失时价格显示占位且不可购买。
  final ProductDetails? storeDetails;

  String? get price => storeDetails?.price;
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.entry,
    required this.selected,
    required this.brightness,
    required this.onTap,
  });

  final _IapProductEntry entry;
  final bool selected;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = entry.product;
    // Figma 选中态（亮暗一致）：品牌红 5% 底 + 1px 品牌红描边，文字不反白
    //（亮 #1C2024 / 暗 #EDEEF0）。
    final selectedFg = brightness == Brightness.dark
        ? StoryColors
              .darkPriceSortIconSelected // #EDEEF0
        : StoryColors.lightForeground; // #1C2024
    final foreground = selected ? selectedFg : _sheetCardText(brightness);
    return Material(
      color: selected
          ? StoryColors.brandTealRed.withValues(alpha: 0.05)
          : _sheetCardBg(brightness),
      shape: selected
          ? const RoundedRectangleBorder(
              borderRadius: StoryRadius.brLg,
              side: BorderSide(color: StoryColors.brandTealRed),
            )
          : const RoundedRectangleBorder(borderRadius: StoryRadius.brLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: StoryRadius.brLg,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: StorySpacing.md),
          child: Row(
            children: [
              const IapPointIcon(),
              const SizedBox(width: StorySpacing.xs),
              Expanded(
                child: Text(
                  context.l10n.iapPointsCount(product.grantedAmount),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: foreground,
                  ),
                ),
              ),
              Text(
                // 严格使用 in_app_purchase ProductDetails 的本地化价格
                //（如 ¥1.99 / $1.99）；商店详情未就绪时显示占位。
                entry.price ?? '--',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.filled,
    required this.brightness,
    this.loading = false,
    this.onTap,
  });

  final String label;
  final bool filled;
  final bool loading;
  final Brightness brightness;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    final disabledBg = isDark
        ? StoryColors
              .darkButtonDisabled // #4F5359
        : StoryColors.buttonDisabledForeground; // #C3C5CE
    final disabledFg = isDark
        ? StoryColors
              .darkBackground // #111113
        : StoryColors.onOverlay;
    final bg = filled
        ? (onTap == null ? disabledBg : StoryColors.brandTealRed)
        : Colors.transparent;
    final fg = filled
        ? (onTap == null ? disabledFg : StoryColors.onOverlay)
        : StoryColors.foregroundOf(brightness);
    final border = filled
        ? BorderSide.none
        : BorderSide(color: StoryColors.dividerOf(brightness));

    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StoryRadius.lgValue),
          ),
          padding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: fg,
                ),
              ),
      ),
    );
  }
}
