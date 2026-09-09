import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../routes/actor_detail_navigation.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/format_number.dart';

/// 「演员 IP 金库排行」单条记录行样式（Figma node 6385:52645 等）。
///
/// 同时用于 Tab 内最多 5 条的预览列表（见 [ActorVaultRankingSection]）与
/// 「查看更多」跳转的完整排行页（`ActorVaultRankingHistoryPage`），两处保持
/// 样式一致。点击行跳转到对应演员详情页。
class ActorVaultRankingListItem extends StatelessWidget {
  final ActorVaultRankingItem item;

  /// 是否绘制底部 0.5px 分隔线（列表最后一项通常为 false）。
  final bool showDivider;

  const ActorVaultRankingListItem({
    super.key,
    required this.item,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actorId = item.actorId;
    return InkWell(
      onTap: actorId == null || actorId.isEmpty
          ? null
          : () => openActorDetail(context, actorId: actorId),
      child: Container(
        height: 60,
        alignment: Alignment.centerLeft,
        decoration: showDivider
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: StoryColors.dividerOf(theme.brightness),
                    width: 0.5,
                  ),
                ),
              )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 16,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${item.rank ?? ''}',
                    style: StoryTextStyles.bodyMedium(
                      color: StoryColors.foregroundOf(theme.brightness),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.actorName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StoryTextStyles.titleMedium(
                            color: StoryColors.foregroundOf(theme.brightness),
                          ),
                        ),
                        if (item.number != null && item.number!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '#${item.actorId}',
                            style: StoryTextStyles.labelSmall(
                              color: theme.brightness == Brightness.dark
                                  ? StoryColors.darkTertiaryText
                                  : StoryColors.lightTertiaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${formatNumber(item.vault, 4)} ${context.l10n.currency}',
              style: StoryTextStyles.titleMedium(color: StoryColors.brandTeal),
            ),
          ],
        ),
      ),
    );
  }
}
