import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../components/components.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/controller_providers.dart';
import '../styles/story_colors.dart';
import '../widgets/widgets.dart';
import 'widgets/watch_history/watch_history_content.dart';
import 'widgets/watch_history/watch_history_tabs.dart';

const _backAsset = 'assets/watch_history/back.svg';
const _trashAsset = 'assets/watch_history/trash.svg';

/// Server-backed watch history matching Figma nodes 949:103324 / 949:103332.
class WatchHistoryPage extends ConsumerStatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  ConsumerState<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends ConsumerState<WatchHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  WorkContentType _activeType = WorkContentType.shortDrama;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTypeChanged(WorkContentType type) {
    if (_activeType == type) return;
    setState(() => _activeType = type);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final headerBackground = StoryColors.appBarBackgroundOf(brightness);
    final foreground = _highContrastColor(headerBackground);
    final dramaState = ref.watch(watchHistoryDramaControllerProvider);
    final videoState = ref.watch(watchHistoryVideoControllerProvider);
    final activeItemsEmpty = _activeType.isShortVideo
        ? videoState.items.isEmpty
        : dramaState.items.isEmpty;
    final isClearing = _activeType.isShortVideo
        ? videoState.isClearing
        : dramaState.isClearing;

    return AppScaffold(
      title: context.l10n.profileWatchHistory,
      titleWidget: Text(
        context.l10n.profileWatchHistory,
        style: TextStyle(
          color: foreground,
          fontSize: 18,
          height: 26 / 18,
          letterSpacing: -0.04,
          fontWeight: FontWeight.w700,
        ),
      ),
      toolbarHeight: 44,
      leadingWidth: 56,
      backgroundColor: headerBackground,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).pop(),
        icon: SvgPicture.asset(
          _backAsset,
          key: const ValueKey<String>('watchHistory.backIcon'),
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
        ),
      ),
      actions: [
        if (!activeItemsEmpty)
          IconButton(
            key: const ValueKey<String>('watchHistory.clear'),
            tooltip: context.l10n.searchClear,
            onPressed: isClearing ? null : _confirmClear,
            icon: isClearing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                : SvgPicture.asset(
                    _trashAsset,
                    key: const ValueKey<String>('watchHistory.clearIcon'),
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  ),
          ),
      ],
      bottom: WatchHistoryTabs(
        controller: _tabController,
        foreground: foreground,
      ),
      body: WatchHistoryContent(
        controller: _tabController,
        showTabs: false,
        selectedType: _activeType,
        onTypeChanged: _handleTypeChanged,
      ),
    );
  }

  Color _highContrastColor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1C2024);
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => DeleteConfirmDialog(
        title: context.l10n.watchHistoryClearTitle,
        message: context.l10n.watchHistoryClearMessage,
        confirmLabel: context.l10n.watchHistoryClearConfirm,
        isDeleting: false,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = _activeType.isShortVideo
        ? await ref
              .read(watchHistoryVideoControllerProvider.notifier)
              .clearHistory()
        : await ref
              .read(watchHistoryDramaControllerProvider.notifier)
              .clearHistory();
    if (!mounted) return;
    if (result.isFailure) {
      final error = result.errorOrNull;
      if (error != null) showApiError(context, error);
      return;
    }
    ref.invalidate(drawerWatchHistoryPreviewProvider);
  }
}
