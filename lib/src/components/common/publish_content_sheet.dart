import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';

/// The content type selected from the center publish action.
enum PublishContentAction { drama, video, actorIp }

/// Figma node 723:87069 — publish content selection bottom sheet.
class PublishContentSheet {
  PublishContentSheet._();

  static Future<PublishContentAction?> show(
    BuildContext context, {
    List<PublishContentAction> actions = const [
      PublishContentAction.drama,
      PublishContentAction.video,
      PublishContentAction.actorIp,
    ],
  }) {
    assert(actions.isNotEmpty);
    final visibleActions = List<PublishContentAction>.unmodifiable(actions);
    return showGeneralDialog<PublishContentAction>(
      context: context,
      barrierColor: Colors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _PublishContentDialog(animation: animation, actions: visibleActions),
    );
  }
}

class _PublishContentDialog extends StatelessWidget {
  final Animation<double> animation;
  final List<PublishContentAction> actions;

  const _PublishContentDialog({required this.animation, required this.actions});

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: curvedAnimation,
              child: GestureDetector(
                key: const ValueKey('publish_sheet_barrier'),
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: const ColoredBox(color: StoryColors.overlayMid),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: _PublishContentSheetBody(actions: actions),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishContentSheetBody extends StatelessWidget {
  final List<PublishContentAction> actions;

  const _PublishContentSheetBody({required this.actions});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final foreground = StoryColors.foregroundOf(brightness);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 16;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          key: const ValueKey('publish_sheet_surface'),
          decoration: BoxDecoration(
            color: brightness == Brightness.dark
                ? StoryColors.backgroundOf(brightness)
                : StoryColors.lightSheetSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24,
                  child: Center(
                    child: Container(
                      key: const ValueKey('publish_sheet_handle'),
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: brightness == Brightness.dark
                            ? StoryColors.darkBorder
                            : StoryColors.buttonDisabledForeground,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    key: const ValueKey('publish_action_card'),
                    color: brightness == Brightness.dark
                        ? StoryColors.sheetSecondaryOf(brightness)
                        : StoryColors.lightCard,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (
                          var index = 0;
                          index < actions.length;
                          index++
                        ) ...[
                          if (index > 0) _SheetDivider(brightness: brightness),
                          _PublishActionRow(
                            key: ValueKey(_keyFor(actions[index])),
                            label: switch (actions[index]) {
                              PublishContentAction.drama => l10n.publishDrama,
                              PublishContentAction.video => l10n.publishVideo,
                              PublishContentAction.actorIp =>
                                l10n.publishActorIp,
                            },
                            icon: switch (actions[index]) {
                              PublishContentAction.drama => _PublishIcon.drama,
                              PublishContentAction.video => _PublishIcon.video,
                              PublishContentAction.actorIp =>
                                _PublishIcon.actorIp,
                            },
                            foreground: foreground,
                            onTap: () =>
                                Navigator.of(context).pop(actions[index]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    key: const ValueKey('publish_sheet_cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: foreground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      side: BorderSide(
                        color: StoryColors.dividerOf(brightness),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.commonCancel,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 18 / 13,
                      ),
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

  String _keyFor(PublishContentAction action) => switch (action) {
    PublishContentAction.drama => 'publish_drama',
    PublishContentAction.video => 'publish_video',
    PublishContentAction.actorIp => 'publish_actor_ip',
  };
}

enum _PublishIcon { drama, video, actorIp }

class _PublishActionRow extends StatelessWidget {
  final String label;
  final _PublishIcon icon;
  final Color foreground;
  final VoidCallback onTap;

  const _PublishActionRow({
    super.key,
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 22 / 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final colorFilter = ColorFilter.mode(foreground, BlendMode.srcIn);
    return SizedBox.square(
      dimension: 24,
      child: switch (icon) {
        _PublishIcon.drama => Center(
          child: SvgPicture.asset(
            'assets/common/publish_drama.svg',
            width: 20.573,
            height: 20.573,
            colorFilter: colorFilter,
          ),
        ),
        _PublishIcon.video => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 2,
              right: 2,
              top: 4.5,
              bottom: 4.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: foreground, width: 1.5),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 8.25,
              child: SvgPicture.asset(
                'assets/common/publish_video.svg',
                width: 6.5,
                height: 7.5,
                colorFilter: colorFilter,
              ),
            ),
          ],
        ),
        _PublishIcon.actorIp => SvgPicture.asset(
          'assets/common/publish_actor_ip.svg',
          width: 24,
          height: 24,
          colorFilter: colorFilter,
        ),
      },
    );
  }
}

class _SheetDivider extends StatelessWidget {
  final Brightness brightness;

  const _SheetDivider({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Divider(
        height: 0,
        thickness: 0.5,
        color: StoryColors.dividerOf(brightness),
      ),
    );
  }
}
