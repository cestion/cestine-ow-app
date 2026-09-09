import 'package:flutter/material.dart';

import '../../../components/components.dart';
import '../../../core/story_constants.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import 'video_feed_episode_bar.dart';

class VideoFeedBottomInfo extends StatefulWidget {
  final DramaDetail? drama;
  final int currentEpisodeNo;
  final VoidCallback? onTitleTap;

  /// When set, replaces [drama.title] (e.g. short video `@username`).
  final String? displayTitle;

  /// When false, hides the compact role-avatar wrap (recommend uses a left rail).
  final bool showRoles;

  /// Collapsed synopsis line count (recommend design uses 2).
  final int synopsisMaxLines;

  /// Match [VideoFeedEpisodeBar.pinProgressToBottom] so bottom offset stays aligned.
  final bool pinProgressToBottom;

  /// Match [VideoFeedEpisodeBar.showEpisodeCta] for bottom chrome height.
  final bool showEpisodeCta;

  /// Recommend short dramas always show a drama [ContentBadge] (community
  /// fallback when the feed omits `badge`). Short videos keep this false.
  final bool alwaysShowDramaBadge;

  /// When false, never render the drama [ContentBadge] (short videos).
  /// Defaults to false so badges stay hidden unless explicitly enabled.
  final bool showDramaBadge;

  /// Prefix the synopsis with the existing `playerEpisodeSynopsis` /
  /// `playerEpisodeLabel` copy. Short-drama player already shows the episode
  /// in the header.
  final bool prefixSynopsisWithEpisode;

  /// Episode-level copy when it differs from [drama.description].
  final String? synopsis;

  const VideoFeedBottomInfo({
    super.key,
    required this.drama,
    required this.currentEpisodeNo,
    this.onTitleTap,
    this.displayTitle,
    this.showRoles = true,
    this.synopsisMaxLines = 1,
    this.pinProgressToBottom = false,
    this.showEpisodeCta = true,
    this.alwaysShowDramaBadge = false,
    this.showDramaBadge = false,
    this.prefixSynopsisWithEpisode = false,
    this.synopsis,
  });

  /// Bottom inset for the recommend actor rail so it sits above title +
  /// collapsed synopsis without shifting that text aside.
  static double actorRailBottomOf(
    BuildContext context, {
    bool pinProgressToBottom = false,
    bool showEpisodeCta = true,
    int synopsisMaxLines = 2,
    bool alwaysShowDramaBadge = false,
  }) {
    final lines = synopsisMaxLines < 1 ? 1 : synopsisMaxLines;
    const titleLine = 22.0;
    const synopsisLine = 21.0;
    // ContentBadge standard: 4+16+4 padding/type, plus gap under the chip.
    const badgeBlock = 24.0 + StorySpacing.sm;
    return VideoFeedEpisodeBar.contentHeightOf(
          context,
          pinProgressToBottom: pinProgressToBottom,
          showEpisodeCta: showEpisodeCta,
        ) +
        StorySpacing.xs +
        (alwaysShowDramaBadge ? badgeBlock : 0) +
        titleLine +
        StorySpacing.sm +
        synopsisLine * lines;
  }

  @override
  State<VideoFeedBottomInfo> createState() => _VideoFeedBottomInfoState();
}

class _VideoFeedBottomInfoState extends State<VideoFeedBottomInfo> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant VideoFeedBottomInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drama?.id != widget.drama?.id ||
        oldWidget.drama?.description != widget.drama?.description ||
        oldWidget.synopsis != widget.synopsis ||
        oldWidget.currentEpisodeNo != widget.currentEpisodeNo) {
      _expanded = false;
    }
  }

  String _synopsisText(BuildContext context) {
    final raw = (widget.synopsis ?? widget.drama?.description)?.trim() ?? '';
    if (!widget.prefixSynopsisWithEpisode || widget.currentEpisodeNo < 1) {
      return raw;
    }
    if (raw.isEmpty) {
      return context.l10n.playerEpisodeLabel(widget.currentEpisodeNo);
    }
    return context.l10n.playerEpisodeSynopsis(widget.currentEpisodeNo, raw);
  }

  @override
  Widget build(BuildContext context) {
    final synopsisText = _synopsisText(context);
    final roles = widget.showRoles
        ? (widget.drama?.roles ?? const <RoleCharacter>[])
        : const <RoleCharacter>[];
    final titleText =
        (widget.displayTitle ?? widget.drama?.title)?.trim() ?? '';

    /// Reserve space on the right so the description text does not run under
    /// [VideoFeedRightActions] (right inset + rail width + small gap).
    final double rightActionWidth =
        StorySizes.videoFeedRailRightInset +
        StorySizes.videoFeedRailWidth +
        StorySpacing.sm;

    // Anchor just above the episode bar instead of a hardcoded screen offset,
    // so the gap to the progress bar stays constant across devices.
    final bottomOffset =
        VideoFeedEpisodeBar.contentHeightOf(
          context,
          pinProgressToBottom: widget.pinProgressToBottom,
          showEpisodeCta: widget.showEpisodeCta,
        ) +
        StorySpacing.xs;

    final visibleDramaBadge =
        widget.showDramaBadge &&
        (widget.alwaysShowDramaBadge ||
            ContentBadgeValue.fromApiValue(widget.drama?.badge) != null);

    return Positioned(
      left: 0,
      right: rightActionWidth,
      bottom: bottomOffset,
      child: RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.only(left: StorySpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (visibleDramaBadge) ...[
                ContentBadge(
                  badge: widget.drama?.badge,
                  variant: ContentBadgeVariant.drama,
                  style: ContentBadgeStyle.onOverlay,
                ),
                const SizedBox(height: StorySpacing.sm),
              ],
              if (titleText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: StorySpacing.sm),
                  child: GestureDetector(
                    onTap: widget.onTitleTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StoryTextStyles.titleMedium(
                              color: StoryColors.onOverlay,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (widget.onTitleTap != null) ...[
                          const SizedBox(width: StorySpacing.xxs),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: StoryColors.onOverlay,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (roles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: StorySpacing.sm),
                  child: Wrap(
                    spacing: StorySpacing.xs,
                    runSpacing: StorySpacing.xs,
                    children: [
                      for (final role in roles)
                        ActorRoleAvatar.forRole(role, size: 32),
                    ],
                  ),
                ),
              if (synopsisText.isNotEmpty)
                _SynopsisLine(
                  text: synopsisText,
                  expanded: _expanded,
                  maxLines: widget.synopsisMaxLines,
                  onToggle: () => setState(() => _expanded = !_expanded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Synopsis expand/collapse section.
///
/// Overflow is decided with a cheap length heuristic — [LayoutBuilder] +
/// [TextPainter] on the overlay's first frame can stall the UI thread
/// (especially when drama seed data has `roles == null` and a short desc).
class _SynopsisLine extends StatelessWidget {
  /// Approx. CJK characters that fit one overlay line after the right rail.
  static const int charsPerCollapsedLine = 22;

  final String text;
  final bool expanded;
  final int maxLines;
  final VoidCallback onToggle;

  const _SynopsisLine({
    required this.text,
    required this.expanded,
    required this.onToggle,
    this.maxLines = 1,
  });

  static bool likelyExceeds(String text, int maxLines) {
    final lines = maxLines < 1 ? 1 : maxLines;
    if (text.contains('\n')) return true;
    return text.length > charsPerCollapsedLine * lines;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = StoryTextStyles.bodyMedium(
      color: StoryColors.onOverlayMuted,
    );
    const iconColor = StoryColors.onOverlay;
    final collapsedLines = maxLines < 1 ? 1 : maxLines;
    final canExpand = likelyExceeds(text, collapsedLines);

    if (expanded && canExpand) {
      return GestureDetector(
        onTap: onToggle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: textStyle),
            const SizedBox(height: StorySpacing.xs),
            const Icon(Icons.expand_less, size: 20, color: iconColor),
          ],
        ),
      );
    }

    if (!canExpand) {
      return Text(
        text,
        maxLines: collapsedLines,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    return GestureDetector(
      onTap: onToggle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: collapsedLines,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
          const SizedBox(width: StorySpacing.xxs),
          const Icon(
            Icons.expand_more,
            size: 20,
            color: StoryColors.onOverlayMuted,
          ),
        ],
      ),
    );
  }
}
