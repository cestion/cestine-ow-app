import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_channel.dart';
import '../../core/result.dart';
import '../../core/story_logger.dart';
import '../../l10n/story_l10n.dart';
import '../../widgets/error_handler.dart';
import '../../widgets/story_cached_image.dart';
import '../../widgets/story_loading.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../routes/route_names.dart';
import '../../services/actor_sign_service.dart';
import '../../services/privy_service.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../utils/actor_pricing.dart';
import '../../utils/auth_navigation.dart';
import '../../utils/format_number.dart';
// import '../../utils/mining_power.dart';
import '../../utils/wallet_balance_gate.dart';
import '../common/story_toast.dart';
import '../iap/iap_point_icon.dart';
import 'actor_info_dialogs.dart';
import '../../foundation/navigator.dart';

Future<void> showActorSignFlow(
  BuildContext context,
  WidgetRef ref,
  ActorCollection actor, {
  FutureOr<void> Function(ActorCollection signedActor)? onSuccess,
}) async {
  // Platform JWT + Privy session (embedded wallet) are both required to sign.
  if (!await ensurePrivySessionOrRedirect(context, ref)) return;
  if (!context.mounted) return;

  // Sheet stays open through confirm → chain mint; only pops after a result.
  final signedActor = await showActorSignSheet(context, actor);
  if (signedActor == null || !context.mounted) return;

  // Signing happens outside the Agent tab. Evict user-scoped mining caches at
  // the mutation source so every signing entry point observes the same result.
  await ref
      .read(actorInventorySyncControllerProvider.notifier)
      .markActorSigned();
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => ActorMintSuccessDialog(actor: signedActor),
  );

  ref.read(incomeControllerProvider.notifier).refresh();
  ref.read(onChainWalletBalanceProvider.notifier).refresh();
  await onSuccess?.call(signedActor);
}

bool _isPrivySessionExpired(ApiError error) {
  final message = switch (error) {
    BusinessError(:final message) => message,
    UnauthorizedError(:final message) => message,
    _ => error.userMessage,
  };
  return PrivyService.looksLikeUnauthenticated(message);
}

/// 签约确认底部弹层（演员 IP 列表 / 详情页共用）。
///
/// 立即展示头像、名称等静态信息；价格 / 余量等需最新数据的区域先 loading，
/// 拉回详情后再展示。返回确认时使用的 [ActorCollection]，取消为 `null`。
Future<ActorCollection?> showActorSignSheet(
  BuildContext context,
  ActorCollection actor,
) {
  return showModalBottomSheet<ActorCollection>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    barrierColor: StoryColors.overlayMedium,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: ActorSignSheet(actor: actor),
    ),
  );
}

class ActorSignSheet extends ConsumerStatefulWidget {
  final ActorCollection actor;

  const ActorSignSheet({super.key, required this.actor});

  @override
  ConsumerState<ActorSignSheet> createState() => _ActorSignSheetState();
}

class _ActorSignSheetState extends ConsumerState<ActorSignSheet> {
  late ActorCollection _actor;
  bool _pricingLoading = true;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _actor = widget.actor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshPricingData());
    });
  }

  Future<void> _refreshPricingData() async {
    final actorId = widget.actor.id ?? '';
    try {
      final balanceFuture = ref
          .read(onChainWalletBalanceProvider.notifier)
          .refresh();

      ActorCollection? fresh;
      if (actorId.isNotEmpty) {
        final result = await ref
            .read(actorRepositoryProvider)
            .refreshActorCollectionDetail(actorId);
        if (result.isSuccess) {
          fresh = result.dataOrNull;
        }
      }
      await balanceFuture;

      if (!mounted) return;

      if (fresh != null) {
        ref.invalidate(actorCollectionDetailProvider(actorId));
        ref.invalidate(actorVaultDepositProvider(actorId));
        ref.read(nftControllerProvider.notifier).upsertActor(fresh);
        ref.read(searchControllerProvider.notifier).upsertActor(fresh);
        _actor = fresh;
      }

      final remaining = _actor.availableSupplyInt ?? 0;
      if (remaining <= 0) {
        StoryToast.info(context, context.l10n.actorSignPriceSoldOut);
        Navigator.of(context).pop();
        return;
      }

      setState(() => _pricingLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() => _pricingLoading = false);
      }
    }
  }

  Future<void> _onConfirm() async {
    if (_pricingLoading || _isSigning) return;

    // Enter loading immediately so the button doesn't feel delayed while
    // balance / config / mint RPCs run.
    setState(() => _isSigning = true);
    final l10n = context.l10n;
    final price = _actor.displayCurrentPriceUsdc;
    try {
      // Soft pre-check with display price; authoritative gate+deduct happens
      // inside ActorSignService after the mint digest is fetched.
      if (price > 0) {
        final ok = await ensureUsdcBalanceOrShowDialog(ref, context, price);
        if (!ok || !mounted) return;
      }

      await ref.read(globalConfigProvider.future);
      if (!mounted) return;

      final withdrawConfig = ref.read(withdrawConfigProvider);
      final svmChain = withdrawConfig.svmChainInfo;
      final sponsorApiUrl = withdrawConfig.sponsorApiUrl;
      final contracts = svmChain?.contracts;
      StoryLogger.d(
        'resolveChainContext: rpc=${svmChain?.rpc?.http} '
        'sponsorUrl=$sponsorApiUrl '
        'spender=${contracts?.spender} '
        'story=${contracts?.story} '
        'delegator=${contracts?.storyDelegator} '
        'treasury=${contracts?.storyTreasury} '
        'nftChain=${svmChain?.name}',
        tag: 'ActorSign',
      );
      final chainContext = ActorSignService.resolveChainContext(
        svmChain: svmChain,
        sponsorApiUrl: sponsorApiUrl,
      );
      if (chainContext == null) {
        StoryToast.error(context, l10n.actorSignChainConfigMissing);
        return;
      }

      final result = await ref
          .read(actorSignServiceProvider)
          .signActor(
            actor: _actor,
            chainContext: chainContext,
            walletLedger: ref.read(walletLedgerProvider),
            fallbackPriceUsdc: price > 0 ? price : null,
          );
      if (!mounted) return;

      if (result.isFailure) {
        final error = result.errorOrNull!;
        if (_isPrivySessionExpired(error)) {
          StoryToast.error(context, l10n.authSessionExpired);
          await ref.read(authControllerProvider.notifier).logout();
          if (mounted) {
            await context.storyPush(RouteNames.login);
          }
          return;
        }
        handleApiError(error, ctx: context);
        return;
      }

      // Pop only after a successful on-chain / sponsor result.
      Navigator.of(context).pop(_actor);
    } finally {
      if (mounted) {
        setState(() => _isSigning = false);
      }
    }
  }

  String _truncateId(String? value) {
    final text = value?.trim() ?? '';
    if (text.length <= 12) return text;
    return '${text.substring(0, 6)}...${text.substring(text.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final l10n = context.l10n;
    final price = _actor.displayCurrentPriceUsdc;
    final remaining = _actor.availableSupplyInt ?? 0;
    final totalSupply = _actor.totalSupplyInt ?? 0;
    final isFixed = isFixedActorPricingMode(_actor.pricingMode);
    final pricingModeLabel = isFixed
        ? l10n.actorPricingFixed
        : l10n.actorPricingCurve;
    final actorIpLabel = l10n.actorIpLabel(_truncateId(_actor.id));

    return PopScope(
      canPop: !_isSigning,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: ColoredBox(
          color: StoryColors.cardOf(brightness),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_actor.avatarUrl?.isNotEmpty == true)
                        StoryCachedImage(
                          imageUrl: _actor.avatarUrl!,
                          memCacheWidth:
                              StoryCachedImage.memCacheForLogicalWidth(
                                context,
                                MediaQuery.sizeOf(context).width,
                              ),
                          errorWidget: _imageFallback(),
                        )
                      else
                        _imageFallback(),
                      Positioned(
                        left: StorySpacing.base,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: StorySpacing.sm,
                            right: 6,
                            top: StorySpacing.xs,
                            bottom: StorySpacing.xs,
                          ),
                          decoration: const BoxDecoration(
                            color: StoryColors.brandTeal,
                            borderRadius: StoryRadius.brPill,
                          ),
                          child: Text(
                            actorIpLabel,
                            style: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              letterSpacing: 0.04,
                              fontWeight: FontWeight.w500,
                              color: brightness == Brightness.dark
                                  ? StoryColors.privyDarkForeground
                                  : StoryColors.onOverlay,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StorySpacing.base,
                    StorySpacing.base,
                    StorySpacing.base,
                    StorySpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.actorConfirmSign,
                            style: TextStyle(
                              fontSize: 18,
                              height: 26 / 18,
                              letterSpacing: -0.04,
                              fontWeight: FontWeight.bold,
                              color: StoryColors.foregroundOf(brightness),
                            ),
                          ),
                          const SizedBox(width: StorySpacing.base),
                          Expanded(
                            child: Text(
                              _actor.name ?? '-',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                height: 24 / 16,
                                fontWeight: FontWeight.w500,
                                color: StoryColors.foregroundOf(brightness),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: StorySpacing.base),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: StoryColors.actorSignSheetPriceCardBgOf(
                            brightness,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: StorySpacing.base,
                            vertical: StorySpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.actorSignPriceLabel,
                                          style: TextStyle(
                                            fontSize: 16,
                                            height: 24 / 16,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                StoryColors.actorSignSheetPriceLabelOf(
                                                  brightness,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        _pricingLoading
                                            ? const StoryLoading.inline(
                                                size: 14,
                                              )
                                            : Text(
                                                l10n.actorSignSupplySummary(
                                                  formatNumber(totalSupply, 0),
                                                  formatNumber(remaining, 0),
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  height: 16 / 12,
                                                  letterSpacing: 0.04,
                                                  fontWeight: FontWeight.w400,
                                                  color:
                                                      StoryColors.actorSignSheetPriceRemainingOf(
                                                        brightness,
                                                      ),
                                                ),
                                              ),
                                        // Row(
                                        //   children: [
                                        //     Flexible(
                                        //       child: Text(
                                        //         l10n.actorPriceCoefficientValue(
                                        //           formatPowerFactor(
                                        //             calculateActorPriceCoefficient(
                                        //               _actor.initialPriceUsdc ??
                                        //                   0,
                                        //             ),
                                        //           ),
                                        //         ),
                                        //         style: TextStyle(
                                        //           fontSize: 12,
                                        //           height: 16 / 12,
                                        //           letterSpacing: 0.04,
                                        //           color:
                                        //               StoryColors.actorSignSheetPriceRemainingOf(
                                        //                 brightness,
                                        //               ),
                                        //         ),
                                        //       ),
                                        //     ),
                                        //     const SizedBox(width: 4),
                                        //     GestureDetector(
                                        //       onTap: () =>
                                        //           PriceCoefficientInfoDialog.show(
                                        //             context,
                                        //           ),
                                        //       child: Icon(
                                        //         Icons.help_outline,
                                        //         size: 16,
                                        //         color:
                                        //             StoryColors.actorSignSheetPriceRemainingOf(
                                        //               brightness,
                                        //             ),
                                        //       ),
                                        //     ),
                                        //   ],
                                        // ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: StorySpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        _pricingLoading
                                            ? const StoryLoading.inline(
                                                size: 18,
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    formatActorPriceCeilDisplay(
                                                      price,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      height: 24 / 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: StoryColors
                                                          .actorSignSheetPriceValueOf(
                                                        brightness,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  if (AppChannel.isStore)
                                                    const IapPointIcon()
                                                  else
                                                    Text(
                                                      'USDC',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        height: 24 / 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: StoryColors
                                                            .actorSignSheetPriceValueOf(
                                                              brightness,
                                                            ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                pricingModeLabel,
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  height: 16 / 12,
                                                  letterSpacing: 0.04,
                                                  color:
                                                      StoryColors.actorSignSheetPriceRemainingOf(
                                                        brightness,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: _pricingLoading
                                                  ? null
                                                  : () => PriceInfoDialog.show(
                                                      context: context,
                                                      pricingMode:
                                                          _actor.pricingMode,
                                                      signedCount:
                                                          _actor
                                                              .mintedSupplyInt ??
                                                          0,
                                                      maxSupply: totalSupply,
                                                      initialPrice:
                                                          _actor
                                                              .initialPriceUsdc ??
                                                          price,
                                                      currentPrice: price,
                                                    ),
                                              child: Icon(
                                                Icons.help_outline,
                                                size: 16,
                                                color:
                                                    StoryColors.actorSignSheetPriceRemainingOf(
                                                      brightness,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!_pricingLoading && !isFixed) ...[
                        const SizedBox(height: StorySpacing.base),
                        Text(
                          l10n.actorSignSlippageNote,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            letterSpacing: 0.04,
                            fontWeight: FontWeight.w400,
                            color: StoryColors.actorSignSheetSlippageNoteOf(
                              brightness,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: StorySpacing.base),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSigning
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                side: BorderSide(
                                  color:
                                      StoryColors.actorSignSheetCancelBorderOf(
                                        brightness,
                                      ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                l10n.commonCancel,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 20 / 14,
                                  fontWeight: FontWeight.bold,
                                  color: StoryColors.foregroundOf(brightness),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: StorySpacing.md),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_pricingLoading || _isSigning)
                                  ? null
                                  : _onConfirm,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                backgroundColor:
                                    StoryColors.actorSignSheetConfirmBgOf(
                                      brightness,
                                    ),
                                disabledBackgroundColor:
                                    StoryColors.actorSignSheetConfirmBgOf(
                                      brightness,
                                    ).withValues(alpha: 0.45),
                                foregroundColor:
                                    StoryColors.actorSignSheetConfirmFgOf(
                                      brightness,
                                    ),
                                disabledForegroundColor:
                                    StoryColors.actorSignSheetConfirmFgOf(
                                      brightness,
                                    ).withValues(alpha: 0.7),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: (_pricingLoading || _isSigning)
                                  ? StoryLoading.inline(
                                      size: 18,
                                      color:
                                          StoryColors.actorSignSheetConfirmFgOf(
                                            brightness,
                                          ),
                                    )
                                  : Text(
                                      l10n.actorConfirmSign,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 20 / 14,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            StoryColors.actorSignSheetConfirmFgOf(
                                              brightness,
                                            ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      decoration: const BoxDecoration(gradient: StoryColors.brandGradient),
    );
  }
}

class ActorMintSuccessDialog extends StatelessWidget {
  final ActorCollection actor;

  const ActorMintSuccessDialog({super.key, required this.actor});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final actorName = actor.name ?? '-';
    final mintAddress = actor.nftMintAddress?.trim();
    final nftIdLabel = (mintAddress != null && mintAddress.isNotEmpty)
        ? formatActorNftLabel(l10n, mintAddress)
        : '-';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.xxxl),
      backgroundColor: StoryColors.cardOf(brightness),
      shape: const RoundedRectangleBorder(borderRadius: StoryRadius.brXl),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: StoryColors.success,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check, color: StoryColors.onOverlay),
            ),
            const SizedBox(height: StorySpacing.md),
            Text(
              l10n.actorSignSuccessTitle,
              style: StoryTextStyles.titleMedium(
                color: StoryColors.foregroundOf(brightness),
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: StorySpacing.sm),
            Text(
              l10n.actorSignSuccessMessage(actorName),
              textAlign: TextAlign.center,
              style: StoryTextStyles.bodyMedium(
                color: StoryColors.foregroundOf(brightness),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.actorSignSuccessNftId(nftIdLabel),
              textAlign: TextAlign.center,
              style: StoryTextStyles.bodySmall(
                color: StoryColors.mutedForegroundOf(brightness),
              ),
            ),
            const SizedBox(height: StorySpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StoryColors.foregroundOf(brightness),
                  foregroundColor: StoryColors.backgroundOf(brightness),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(
                    borderRadius: StoryRadius.brPill,
                  ),
                ),
                child: Text(
                  l10n.commonConfirm,
                  style: StoryTextStyles.bodyMedium(
                    color: StoryColors.backgroundOf(brightness),
                  ).copyWith(fontWeight: FontWeight.bold, height: 20 / 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
