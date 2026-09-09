import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../foundation/story_launcher.dart';
import '../../l10n/story_l10n.dart';
import '../../model/app_version_update_info.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';

const _rocketAsset = 'assets/common/app_version_update_rocket.svg';

/// 按 Figma「发现新版本」弹窗展示版本更新；Remind 可「以后再说」，Force 不可关闭。
///
/// [useRootNavigator] 为 true 时挂到根 Navigator（Force 可盖住 DeletingPage 等路由）。
Future<void> showAppVersionUpdateDialog(
  BuildContext context, {
  required AppVersionUpdateInfo info,
  VoidCallback? onLater,
  bool useRootNavigator = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !info.isForce,
    useRootNavigator: useRootNavigator,
    builder: (ctx) => PopScope(
      canPop: !info.isForce,
      child: AppVersionUpdateDialog(
        info: info,
        onLater: onLater,
      ),
    ),
  );
}

class AppVersionUpdateDialog extends StatelessWidget {
  const AppVersionUpdateDialog({
    super.key,
    required this.info,
    this.onLater,
  });

  final AppVersionUpdateInfo info;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final surface = StoryColors.createDramaPageSurfaceOf(brightness);
    final iconBadgeBg = StoryColors.createDramaPanelSurfaceOf(brightness);
    final primaryBg = brightness == Brightness.dark
        ? StoryColors.darkForeground
        : StoryColors.darkButtonBg;
    final primaryFg = StoryColors.whiteToDarkOf(brightness);
    // Figma: 亮色图标 #1C2024 / 暗色图标 #EDEEF0（thirdly 底上需高对比）
    final iconColor = brightness == Brightness.dark
        ? StoryColors.darkPriceSortIconSelected
        : StoryColors.lightForeground;

    return Dialog(
      backgroundColor: surface,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: iconBadgeBg,
                      borderRadius: BorderRadius.circular(76),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SvgPicture.asset(
                        _rocketAsset,
                        width: 44,
                        height: 44,
                        colorFilter: ColorFilter.mode(
                          iconColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Text(
                      l10n.appVersionUpdateTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 18,
                        height: 26 / 18,
                        letterSpacing: -0.04,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (info.versionName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'V${info.versionName}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appVersionUpdateContentsLabel,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 15,
                          height: 22 / 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: SingleChildScrollView(
                          child: Text(
                            info.contents,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: secondary,
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _DialogButton(
                    label: l10n.appVersionUpdateConfirm,
                    onTap: () {
                      final url = info.downloadUrl.trim();
                      if (url.isEmpty) return;
                      StoryLauncher.openExternal(url);
                    },
                    backgroundColor: primaryBg,
                    foregroundColor: primaryFg,
                  ),
                  if (!info.isForce) ...[
                    const SizedBox(height: 12),
                    _DialogButton(
                      label: l10n.appVersionUpdateLater,
                      onTap: () {
                        Navigator.of(context).pop();
                        onLater?.call();
                      },
                      backgroundColor: surface,
                      borderColor: StoryColors.dividerOf(brightness),
                      foregroundColor: foreground,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
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
