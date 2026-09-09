import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_channel.dart';
import '../../core/story_constants.dart';
import '../../core/story_sdk.dart';
import '../../foundation/story_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../widgets/widgets.dart';
import '../common/primary_action_button.dart';
import '../iap/iap_point_icon.dart';
import '../../utils/wallet_balance_gate.dart';

/// Mint drama NFT confirmation bottom sheet.
/// Matches Figma node 5792:81195 "铸造短剧NFT".
///
/// 确认按钮触发完整四步铸造流程（由 [CreatorController.mintDramaNft] 编排）：
///   1. POST /nft/mint → DramaNftMintDigest
///   2. Solana getAccountInfo 预检 USDC ATA
///   3. Privy signTransaction
///   4. POST sponsor 提交链上交易
class MintNftModal extends ConsumerStatefulWidget {
  final CreatorDrama drama;

  const MintNftModal({super.key, required this.drama});

  /// Shows the modal. Returns `true` if mint succeeded, `false`/`null` otherwise.
  static Future<bool?> show(BuildContext context, CreatorDrama drama) {
    return showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MintNftModal(drama: drama),
    );
  }

  @override
  ConsumerState<MintNftModal> createState() => _MintNftModalState();
}

class _MintNftModalState extends ConsumerState<MintNftModal> {
  Future<void> _onConfirm() async {
    final current = ref.read(dramaManagementControllerProvider);
    if (current.isMinting) return;

    // Soft-check the USDC balance; pop the insufficient dialog when short.
    final ok = await ensureUsdcBalanceOrShowDialog(
      ref,
      context,
      StoryConstants.defaultMintFeeUsdc,
    );
    if (!ok || !mounted) return;

    final result = await ref
        .read(dramaManagementControllerProvider.notifier)
        .mintDramaNft(widget.drama, l10n: context.l10n);

    if (!mounted) return;

    result.when(
      success: (txHash) {
        final navigator = Navigator.of(context);
        navigator.pop(true);
        showDialog<void>(
          context: navigator.context,
          builder: (_) => DramaMintSuccessDialog(
            dramaName: widget.drama.title?.trim().isNotEmpty == true
                ? widget.drama.title!.trim()
                : '-',
            txHash: txHash,
          ),
        );
      },
      failure: (error) {
        handleApiError(error, ctx: context, rootOverlay: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final l10n = context.l10n;
    final isMinting = ref.watch(
      dramaManagementControllerProvider.select((state) => state.isMinting),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.backgroundOf(brightness),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(StoryRadius.mdValue),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandle(brightness),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.screenHorizontal,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: StorySpacing.base),
                _buildTitleSection(brightness, l10n),
                const SizedBox(height: StorySpacing.base),
                _buildBody(brightness, isMinting, l10n),
                const SizedBox(height: StorySpacing.base),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }

  // ─── Handle ───────────────────────────────────────────────────────
  Widget _buildHandle(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: StoryColors.mutedOf(brightness),
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
    );
  }

  // ─── Title section (centered) ─────────────────────────────────────
  Widget _buildTitleSection(Brightness brightness, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.creatorMintDramaNft,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 26 / 18,
            letterSpacing: -0.04,
            color: StoryColors.foregroundOf(brightness),
          ),
        ),
        const SizedBox(height: StorySpacing.xs),
        Text(
          l10n.creatorMintConfirmDesc,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 16 / 12,
            letterSpacing: 0.04,
            color: StoryColors.mutedForegroundOf(brightness),
          ),
        ),
      ],
    );
  }

  // ─── Body: drama card + fee row + buttons ─────────────────────────
  Widget _buildBody(
    Brightness brightness,
    bool isMinting,
    AppLocalizations l10n,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDramaCard(brightness, l10n),
        const SizedBox(height: StorySpacing.xl),
        _buildFeeRow(brightness, l10n),
        const SizedBox(height: StorySpacing.xl),
        _buildButtons(brightness, isMinting, l10n),
      ],
    );
  }

  // ─── Drama info card ──────────────────────────────────────────────
  Widget _buildDramaCard(Brightness brightness, AppLocalizations l10n) {
    final drama = widget.drama;
    return Container(
      padding: const EdgeInsets.all(StorySpacing.base),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(brightness),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: SizedBox(
              width: 80,
              height: 60,
              child: drama.coverUrl != null && drama.coverUrl!.isNotEmpty
                  ? Builder(
                      builder: (context) => StoryCachedImage(
                        imageUrl: drama.coverUrl!,
                        memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
                          context,
                          StoryImageCache.searchThumbnail,
                        ),
                        errorWidget: _coverPlaceholder(brightness),
                      ),
                    )
                  : _coverPlaceholder(brightness),
            ),
          ),
          const SizedBox(width: StorySpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drama.title?.trim() ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 24 / 16,
                    color: StoryColors.foregroundOf(brightness),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 11,
                      color: StoryColors.mutedForegroundOf(brightness),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.dramaAllEpisodesFull(drama.totalEpisodes ?? 0),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                        letterSpacing: 0.04,
                        color: StoryColors.mutedForegroundOf(brightness),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder(Brightness brightness) {
    return Container(
      color: StoryColors.mutedOf(brightness),
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_outlined,
        size: 24,
        color: StoryColors.mutedForegroundOf(brightness),
      ),
    );
  }

  // ─── Fee row (teal-tinted) ────────────────────────────────────────
  Widget _buildFeeRow(Brightness brightness, AppLocalizations l10n) {
    final isDark = brightness == Brightness.dark;
    final feeColor = isDark ? StoryColors.brandTeal : StoryColors.brandTealDark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.base,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: StoryColors.brandTeal.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: StoryColors.brandTeal.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.creatorMintFee,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              height: 12 / 10,
              letterSpacing: 0.08,
              color: feeColor,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                  color: feeColor,
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
                    fontWeight: FontWeight.w700,
                    height: 24 / 16,
                    color: feeColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Buttons ──────────────────────────────────────────────────────
  Widget _buildButtons(
    Brightness brightness,
    bool isMinting,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        _buildCancelButton(brightness, isMinting, l10n),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryActionButton(
            label: l10n.commonConfirm,
            loading: isMinting,
            onPressed: _onConfirm,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(
    Brightness brightness,
    bool isMinting,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isMinting ? null : () => Navigator.of(context).pop(false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: StoryColors.backgroundOf(brightness),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: StoryColors.dividerOf(brightness)),
        ),
        child: Text(
          l10n.commonCancel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 20 / 14,
            color: StoryColors.foregroundOf(brightness),
          ),
        ),
      ),
    );
  }
}

/// 短剧铸造成功弹窗。对应 Figma node 6156:47809「铸造成功！」。
///
/// - [dramaName]：短剧名，展示为「《{dramaName}》短剧NFT已上链」
/// - [txHash]：链上交易哈希（teal 强调，可换行）
/// - [nftId]：可选 NFT 编号，为空时隐藏该行
class DramaMintSuccessDialog extends StatelessWidget {
  final String dramaName;
  final String txHash;
  final String? nftId;

  const DramaMintSuccessDialog({
    super.key,
    required this.dramaName,
    required this.txHash,
    this.nftId,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final primary = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final trimmedNftId = nftId?.trim();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.xxxl),
      backgroundColor: StoryColors.backgroundOf(brightness),
      shape: const RoundedRectangleBorder(borderRadius: StoryRadius.brXl),
      child: Padding(
        padding: const EdgeInsets.all(StorySpacing.base),
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
            const SizedBox(height: StorySpacing.sm),
            Text(
              l10n.creatorMintSuccess,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: StorySpacing.sm),
            Text(
              l10n.creatorMintDramaOnChain(dramaName),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: primary,
              ),
            ),
            if (trimmedNftId != null && trimmedNftId.isNotEmpty) ...[
              const SizedBox(height: StorySpacing.sm),
              Text(
                l10n.creatorMintNftNumber(trimmedNftId),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w400,
                  color: secondary,
                ),
              ),
            ],
            const SizedBox(height: StorySpacing.sm),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l10n.creatorMintTxHash,
                    style: TextStyle(color: secondary),
                  ),
                  TextSpan(
                    text: txHash,
                    style: const TextStyle(
                      color: StoryColors.brandTealDark,
                      decoration: TextDecoration.underline,
                      decorationColor: StoryColors.brandTealDark,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => StoryLauncher.openExternal(
                        StorySdk.instance.config.env.txExplorerUrl(txHash),
                      ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: StorySpacing.base),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: StorySpacing.base,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: StoryColors.darkButtonBgOf(brightness),
                  borderRadius: StoryRadius.brPill,
                ),
                alignment: Alignment.center,
                child: Text(
                  l10n.commonConfirm,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w700,
                    color: StoryColors.onOverlay,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
