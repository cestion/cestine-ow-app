import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/follow_action_controller.dart';
import '../../controller/recommend_feed_controller.dart';
import '../../l10n/story_l10n.dart';
import '../../provider/app_providers.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../widgets/widgets.dart';
import 'story_toast.dart';

/// User row for the "拉黑" action on [ReportSuccessDialog].
class ReportBlockTarget {
  final String userId;
  final String? displayName;
  final String? avatarUrl;

  const ReportBlockTarget({
    required this.userId,
    this.displayName,
    this.avatarUrl,
  });
}

/// Content row for the "减少推荐" action on [ReportSuccessDialog].
class ReportReduceTarget {
  final String episodeId;
  final String? title;
  final String? coverUrl;

  const ReportReduceTarget({
    required this.episodeId,
    this.title,
    this.coverUrl,
  });
}

/// Report-submitted feedback dialog with optional block / reduce-recommend rows.
class ReportSuccessDialog extends ConsumerStatefulWidget {
  final ReportBlockTarget? blockTarget;
  final ReportReduceTarget? reduceTarget;

  const ReportSuccessDialog({super.key, this.blockTarget, this.reduceTarget});

  /// Shows the dialog.
  ///
  /// Returns `true` only when "减少推荐" advanced the recommend feed via
  /// [RecommendFeedController.dislikeCurrent] (caller should sync pager, not
  /// advance again). A bare repository dislike returns `false`.
  static Future<bool> show(
    BuildContext context, {
    ReportBlockTarget? blockTarget,
    ReportReduceTarget? reduceTarget,
  }) async {
    final advancedFeed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReportSuccessDialog(
        blockTarget: blockTarget,
        reduceTarget: reduceTarget,
      ),
    );
    return advancedFeed == true;
  }

  @override
  ConsumerState<ReportSuccessDialog> createState() =>
      _ReportSuccessDialogState();
}

class _ReportSuccessDialogState extends ConsumerState<ReportSuccessDialog> {
  bool _blocking = false;
  bool _reducing = false;
  bool _blocked = false;
  bool _reduced = false;

  /// True when reduce used [RecommendFeedController.dislikeCurrent] successfully.
  bool _reducedViaFeed = false;

  String _blockDisplayName(BuildContext context) {
    final name = widget.blockTarget?.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final userId = widget.blockTarget?.userId.trim() ?? '';
    if (userId.isNotEmpty) {
      return context.l10n.publicProfileUserFallback(userId);
    }
    return '';
  }

  String _contentDisplayName(BuildContext context) {
    final title = widget.reduceTarget?.title?.trim() ?? '';
    if (title.isNotEmpty) return title;
    return context.l10n.reportSuccessContentFallback;
  }

  Future<void> _onBlock() async {
    final userId = widget.blockTarget?.userId.trim() ?? '';
    if (userId.isEmpty || _blocking || _blocked) return;

    final confirmed = await StoryDialog.confirm(
      context: context,
      title: context.l10n.publicProfileBlockConfirmTitle,
      message: context.l10n.publicProfileBlockConfirmMessage,
      confirmLabel: context.l10n.publicProfileBlock,
      confirmColor: StoryColors.destructive,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _blocking = true);
    final result = await ref
        .read(followActionControllerProvider.notifier)
        .block(userId);
    if (!mounted) return;
    setState(() => _blocking = false);

    if (result.isFailure) {
      final error = result.errorOrNull;
      if (error != null) {
        StoryToast.error(context, context.l10nError(error));
      }
      return;
    }

    setState(() => _blocked = true);
    ref.invalidate(blockRelationProvider(userId));
    ref.invalidate(publicProfileProvider(userId));
    StoryToast.success(context, context.l10n.publicProfileBlockSuccess);
  }

  Future<void> _onReduceRecommend() async {
    final episodeId = widget.reduceTarget?.episodeId.trim() ?? '';
    if (episodeId.isEmpty || _reducing || _reduced) return;

    setState(() => _reducing = true);

    // Prefer feed controller when this episode is the active recommend item
    // so the feed can remove it from the pager (avoids a second dislike call).
    var usedFeedController = false;
    var ok = false;
    if (ref.exists(recommendFeedControllerProvider)) {
      final feed = ref.read(recommendFeedControllerProvider);
      final currentId =
          feed.currentItem?.episodeId ?? feed.currentPlay?.episodeId;
      if (currentId != null && currentId == episodeId) {
        usedFeedController = true;
        ok = await ref
            .read(recommendFeedControllerProvider.notifier)
            .dislikeCurrent();
      }
    }

    if (!usedFeedController) {
      final result = await ref
          .read(recommendRepositoryProvider)
          .dislike(episodeId);
      ok = result.isSuccess;
      if (!ok && mounted) {
        final error = result.errorOrNull;
        setState(() => _reducing = false);
        if (error != null) {
          StoryToast.error(context, context.l10nError(error));
        }
        return;
      }
    } else if (!ok && mounted) {
      final err = ref.read(recommendFeedControllerProvider).lastError;
      setState(() => _reducing = false);
      StoryToast.error(
        context,
        err != null ? context.l10nError(err) : context.l10n.playerPlayFailed,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _reducing = false;
      _reduced = true;
      // Only feed-controller path removes/activates the next item.
      _reducedViaFeed = usedFeedController;
    });
    StoryToast.success(context, context.l10n.playerNotInterestedDone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final block = widget.blockTarget;
    final reduce = widget.reduceTarget;
    final showActions = block != null || reduce != null;

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
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: StoryColors.success,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_rounded,
                size: 32,
                color: StoryColors.onOverlay,
              ),
            ),
            const SizedBox(height: StorySpacing.base),
            Text(
              l10n.reportSuccessTitle,
              textAlign: TextAlign.center,
              style:
                  StoryTextStyles.titleMedium(
                    color: StoryColors.foregroundOf(brightness),
                  ).copyWith(
                    fontSize: 18,
                    height: 26 / 18,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: StorySpacing.sm),
            Text(
              l10n.reportSuccessThanks,
              textAlign: TextAlign.center,
              style: StoryTextStyles.bodyMedium(
                color: StoryColors.foregroundOf(brightness),
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: StorySpacing.xl),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.reportSuccessAlsoYouCan,
                  style: StoryTextStyles.bodySmall(
                    color: StoryColors.mutedForegroundOf(brightness),
                  ),
                ),
              ),
              const SizedBox(height: StorySpacing.md),
              if (block != null)
                _ActionRow(
                  avatarUrl: block.avatarUrl,
                  userId: block.userId,
                  displayName: _blockDisplayName(context),
                  actionLabel: _blocked
                      ? l10n.publicProfileBlockSuccess
                      : l10n.publicProfileBlock,
                  loading: _blocking,
                  enabled: !_blocked,
                  onPressed: _onBlock,
                ),
              if (block != null && reduce != null)
                const SizedBox(height: StorySpacing.sm),
              if (reduce != null)
                _ActionRow(
                  avatarUrl: reduce.coverUrl,
                  userId: null,
                  displayName: _contentDisplayName(context),
                  actionLabel: _reduced
                      ? l10n.reportReduceRecommendDone
                      : l10n.reportReduceRecommend,
                  loading: _reducing,
                  enabled: !_reduced,
                  onPressed: _onReduceRecommend,
                ),
            ],
            const SizedBox(height: StorySpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_reducedViaFeed),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StoryColors.foregroundOf(brightness),
                  foregroundColor: StoryColors.backgroundOf(brightness),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 44),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                child: Text(
                  l10n.reportSuccessDone,
                  style: StoryTextStyles.labelLarge(
                    color: StoryColors.backgroundOf(brightness),
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String? avatarUrl;
  final String? userId;
  final String displayName;
  final String actionLabel;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionRow({
    required this.avatarUrl,
    required this.userId,
    required this.displayName,
    required this.actionLabel,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final bg = StoryColors.backgroundOf(brightness);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.md,
        vertical: StorySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: StoryColors.fillSecondaryOf(brightness),
        borderRadius: StoryRadius.brMd,
      ),
      child: Row(
        children: [
          StoryAvatar(
            imageUrl: avatarUrl,
            userId: userId,
            fallbackText: displayName,
            size: 36,
          ),
          const SizedBox(width: StorySpacing.sm),
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StoryTextStyles.bodyMedium(
                color: fg,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: StorySpacing.sm),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: enabled && !loading ? onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: fg,
                foregroundColor: bg,
                disabledBackgroundColor: StoryColors.mutedOf(brightness),
                disabledForegroundColor: StoryColors.mutedForegroundOf(
                  brightness,
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const RoundedRectangleBorder(
                  borderRadius: StoryRadius.brSm,
                ),
              ),
              child: loading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(bg),
                      ),
                    )
                  : Text(
                      actionLabel,
                      style: StoryTextStyles.labelMedium(
                        color: enabled
                            ? bg
                            : StoryColors.mutedForegroundOf(brightness),
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
