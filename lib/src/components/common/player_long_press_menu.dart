import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../model/work_content_type.dart';
import 'story_action_sheet.dart';

/// Shared player long-press sheet used by the drama feed and recommend feed.
///
/// Returns the selected action value (e.g. `'report'`) so callers can keep
/// [holdAutoAdvance] open through follow-up routes like the report page.
class PlayerLongPressMenu {
  PlayerLongPressMenu._();

  static const reportAction = 'report';

  static Future<String?> show({
    required BuildContext context,
    required String dramaId,
    required int episodeNo,
    String? episodeId,
    WorkContentType contentType = WorkContentType.shortDrama,
    String? creatorId,
    String? creatorName,
    String? creatorAvatarUrl,
    String? contentTitle,
    String? contentCoverUrl,
    required bool autoPlayEnabled,
    required ValueChanged<bool> onAutoPlayChanged,
    required VoidCallback onClearScreen,
    required VoidCallback onNotInterested,

    /// 当前作品为登录用户自己创作时隐藏「不感兴趣」与「举报」。
    bool isOwnWork = false,
  }) {
    final l10n = context.l10n;
    return StoryActionSheet.show<String>(
      context: context,
      style: StoryActionSheetStyle.card,
      showCancel: false,
      groups: [
        if (!isOwnWork)
          [
            ActionSheetItem<String>(
              label: l10n.playerNotInterested,
              svgAsset: 'assets/drama/heart-broken.svg',
              value: 'not_interested',
              onTap: (_) => onNotInterested(),
            ),
            ActionSheetItem<String>(
              label: l10n.playerReport,
              svgAsset: 'assets/drama/report.svg',
              value: reportAction,
            ),
          ],
        [
          ActionSheetItem<String>(
            label: l10n.playerClearScreen,
            svgAsset: 'assets/drama/aspect-ratio.svg',
            value: 'clear_screen',
            onTap: (_) => onClearScreen(),
          ),
          ActionSheetItem<String>(
            label: l10n.playerAutoPlay,
            svgAsset: 'assets/drama/auto_play.svg',
            switchValue: autoPlayEnabled,
            onSwitchChanged: onAutoPlayChanged,
          ),
        ],
      ],
    );
  }
}
