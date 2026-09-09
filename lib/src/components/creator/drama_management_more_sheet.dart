import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';

const _editIconAsset = 'assets/drama/creator_more_edit.svg';
const _deleteIconAsset = 'assets/drama/creator_more_delete.svg';

Future<void> showDramaManagementMoreSheet(
  BuildContext context, {
  required bool showEdit,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: StoryColors.overlayMid,
    showDragHandle: false,
    builder: (_) => DramaManagementMoreSheet(
      showEdit: showEdit,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}

/// Short-drama management action sheet matching Figma node `557:104028`.
class DramaManagementMoreSheet extends StatelessWidget {
  final bool showEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DramaManagementMoreSheet({
    super.key,
    required this.showEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = bottomInset > 34 ? bottomInset + 10 : 44.0;
    final sheetColor = brightness == Brightness.dark
        ? StoryColors.darkBackground
        : StoryColors.lightSheetSecondary;

    return DecoratedBox(
      key: const ValueKey<String>('drama-management-more-sheet'),
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DragHandle(),
            const SizedBox(height: 16),
            Material(
              color: StoryColors.cardOf(brightness),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showEdit) ...[
                    _ActionRow(
                      key: const ValueKey<String>(
                        'drama-management-more-edit-action',
                      ),
                      iconAsset: _editIconAsset,
                      label: context.l10n.creatorDramaEdit,
                      foregroundColor: StoryColors.foregroundOf(brightness),
                      onTap: () => _runAction(context, onEdit),
                    ),
                    const _ActionDivider(),
                  ],
                  _ActionRow(
                    key: const ValueKey<String>(
                      'drama-management-more-delete-action',
                    ),
                    iconAsset: _deleteIconAsset,
                    label: context.l10n.creatorDramaDelete,
                    foregroundColor: StoryColors.brandTealRed,
                    onTap: () => _runAction(context, onDelete),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CancelButton(onTap: () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
    );
  }

  Future<void> _runAction(BuildContext context, VoidCallback action) async {
    await Navigator.of(context).maybePop();
    action();
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Center(
        child: Container(
          width: 48,
          height: 4,
          decoration: const BoxDecoration(
            color: StoryColors.privyLightDisabled,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _ActionRow({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: SvgPicture.asset(
                    iconAsset,
                    key: ValueKey<String>('$key-icon'),
                    width: 24,
                    height: 24,
                    colorFilter: iconAsset == _editIconAsset
                        ? ColorFilter.mode(foregroundColor, BlendMode.srcIn)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 15,
                      height: 22 / 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 37),
      child: Divider(
        height: 0,
        thickness: 0.5,
        color: StoryColors.dividerOf(Theme.of(context).brightness),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CancelButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      key: const ValueKey<String>('drama-management-more-cancel-action'),
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: StoryColors.dividerOf(brightness), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              context.l10n.commonCancel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: StoryColors.foregroundOf(brightness),
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
