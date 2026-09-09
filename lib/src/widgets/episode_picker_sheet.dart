import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/common/story_bottom_sheet.dart';
import '../core/story_constants.dart';
import '../l10n/app_localizations.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import 'episode_picker_list.dart';

/// Player episode picker. Same cover list as recommend / drama-detail
/// ([EpisodePickerListSliver]).
///
/// Starts at half screen and can be dragged to almost full. Returns the
/// selected episode, or `null` if dismissed.
class EpisodePickerSheet extends ConsumerStatefulWidget {
  final String dramaId;
  final int totalEpisodes;
  final int currentEpisode;
  final String? fallbackCoverUrl;
  final ValueChanged<int> onSelect;

  const EpisodePickerSheet({
    super.key,
    required this.dramaId,
    required this.totalEpisodes,
    required this.currentEpisode,
    required this.onSelect,
    this.fallbackCoverUrl,
  });

  /// Shows the picker and resolves with the selected episode, or `null` if
  /// dismissed without a selection.
  static Future<int?> show({
    required BuildContext context,
    required String dramaId,
    required int totalEpisodes,
    required int currentEpisode,
    String? fallbackCoverUrl,
  }) {
    return StoryBottomSheet.showEpisodePicker<int>(
      context: context,
      builder: (ctx) => EpisodePickerSheet(
        dramaId: dramaId,
        totalEpisodes: totalEpisodes,
        currentEpisode: currentEpisode,
        fallbackCoverUrl: fallbackCoverUrl,
        onSelect: (epNo) => Navigator.of(ctx).pop(epNo),
      ),
    );
  }

  @override
  ConsumerState<EpisodePickerSheet> createState() => _EpisodePickerSheetState();
}

class _EpisodePickerSheetState extends ConsumerState<EpisodePickerSheet> {
  static const double _halfChildSize = 0.5;
  static const double _maxChildSize = 0.92;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetSizeChanged);
    Future<void>.microtask(() {
      if (!mounted) return;
      unawaited(
        ref
            .read(dramaEpisodeListProvider(widget.dramaId).notifier)
            .synchronize(),
      );
    });
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    super.dispose();
  }

  void _onSheetSizeChanged() {
    if (!_sheetController.isAttached) return;
    final fullscreen = _sheetController.size >= _maxChildSize - 0.02;
    if (fullscreen != _isFullscreen) {
      setState(() => _isFullscreen = fullscreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      controller: _sheetController,
      minChildSize: _halfChildSize,
      maxChildSize: _maxChildSize,
      expand: false,
      snap: true,
      snapSizes: const [_halfChildSize, _maxChildSize],
      builder: (context, scrollController) {
        return SafeArea(
          top: false,
          child: CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StorySpacing.base,
                    StorySpacing.sm,
                    StorySpacing.base,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isFullscreen)
                        Center(
                          child: Container(
                            width: StorySizes.dragHandleWidth,
                            height: StorySizes.dragHandleHeight,
                            margin: const EdgeInsets.only(
                              bottom: StorySpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: StoryColors.dividerOf(brightness),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      EpisodePickerHeader(
                        l10n: l10n,
                        totalEpisodes: widget.totalEpisodes,
                        brightness: brightness,
                        showClose: _isFullscreen,
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: StorySpacing.md),
                    ],
                  ),
                ),
              ),
              EpisodePickerListSliver(
                dramaId: widget.dramaId,
                currentEpisode: widget.currentEpisode,
                fallbackCoverUrl: widget.fallbackCoverUrl,
                onSelect: widget.onSelect,
                padding: EdgeInsets.fromLTRB(
                  StorySpacing.base,
                  0,
                  StorySpacing.base,
                  StorySpacing.md + bottomInset,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Picker chrome: `选集` + `全N集`. Fullscreen adds a close button on the right.
class EpisodePickerHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final int totalEpisodes;
  final Brightness brightness;
  final bool showClose;
  final VoidCallback onClose;

  const EpisodePickerHeader({
    super.key,
    required this.l10n,
    required this.totalEpisodes,
    required this.brightness,
    required this.showClose,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final fg = StoryColors.foregroundOf(brightness);
    return Row(
      children: [
        Text(
          l10n.playerEpisodeSelect,
          style: StoryTextStyles.titleMedium(
            color: fg,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l10n.playerEpisodeTotal(totalEpisodes),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StoryTextStyles.bodySmall(
              color: StoryColors.mutedForegroundOf(brightness),
            ),
          ),
        ),
        if (showClose)
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              padding: EdgeInsets.zero,
              splashRadius: 18,
              iconSize: 24,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
              icon: Icon(Icons.close, color: fg),
            ),
          ),
      ],
    );
  }
}
