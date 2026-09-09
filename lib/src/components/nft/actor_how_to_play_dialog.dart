import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/story_sdk.dart';
import '../../foundation/story_launcher.dart';
import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';

const _createArrowAsset = 'assets/common/how_to_play_create_arrow.svg';

enum ActorHowToPlayTab { sign, issue }

/// 角色 IP 怎么玩底部 Sheet：签约 IP / 发行 IP。
/// Figma 亮 `970:118015` / 暗 `970:118345`。
class ActorHowToPlayDialog extends ConsumerStatefulWidget {
  const ActorHowToPlayDialog({super.key});

  static Future<void> show(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: StoryColors.cardOf(brightness),
      barrierColor: StoryColors.overlayMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const ActorHowToPlayDialog(),
    );
  }

  @override
  ConsumerState<ActorHowToPlayDialog> createState() =>
      _ActorHowToPlayDialogState();
}

class _ActorHowToPlayDialogState extends ConsumerState<ActorHowToPlayDialog> {
  ActorHowToPlayTab _tab = ActorHowToPlayTab.sign;

  Future<void> _goCreate() async {
    Navigator.of(context).pop();
    // 对齐 Web / 文案：打开 DreamOS 外链。
    unawaited(
      StoryLauncher.openExternal(StorySdk.instance.config.env.dreamOsUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final mutedFg = StoryColors.mutedForegroundOf(brightness);
    // 内容块 secondary `#F0F0F3`；Tab 轨道 thirdly `#F6F6F6`。
    final panelBg = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : StoryColors.lightSheetSecondary;
    final tabTrackBg = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : StoryColors.lightMuted;
    final isIssue = _tab == ActorHowToPlayTab.issue;

    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final maxBodyHeight = MediaQuery.sizeOf(context).height * 0.55;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StorySpacing.base,
            StorySpacing.sm,
            StorySpacing.base,
            0,
          ),
          child: Text(
            l10n.actorHowToPlayTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              height: 26 / 18,
              letterSpacing: -0.04,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StorySpacing.base,
            StorySpacing.xl,
            StorySpacing.base,
            0,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tabTrackBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _TabCard(
                      title: l10n.actorHowToPlaySignTab,
                      subtitle: l10n.actorHowToPlaySignSubtitle,
                      selected: _tab == ActorHowToPlayTab.sign,
                      onTap: () =>
                          setState(() => _tab = ActorHowToPlayTab.sign),
                    ),
                  ),
                  Expanded(
                    child: _TabCard(
                      title: l10n.actorHowToPlayIssueTab,
                      subtitle: l10n.actorHowToPlayIssueSubtitle,
                      selected: _tab == ActorHowToPlayTab.issue,
                      onTap: () =>
                          setState(() => _tab = ActorHowToPlayTab.issue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxBodyHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              StorySpacing.base,
              StorySpacing.xl,
              StorySpacing.base,
              StorySpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: StorySpacing.base,
                      vertical: StorySpacing.md,
                    ),
                    child: Text(
                      isIssue
                          ? l10n.actorHowToPlayIssuePositioning
                          : l10n.actorHowToPlaySignPositioning,
                      style: TextStyle(
                        fontSize: 17,
                        height: 25 / 17,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: StorySpacing.md),
                _Section(
                  title: l10n.actorHowToPlayAudienceTitle,
                  body: isIssue
                      ? l10n.actorHowToPlayIssueAudience
                      : l10n.actorHowToPlaySignAudience,
                  titleColor: fg,
                  bodyColor: mutedFg,
                ),
                const SizedBox(height: StorySpacing.md),
                _Section(
                  title: l10n.actorHowToPlayGuideTitle,
                  body: isIssue
                      ? l10n.actorHowToPlayIssueGuide
                      : l10n.actorHowToPlaySignGuide,
                  titleColor: fg,
                  bodyColor: mutedFg,
                ),
                const SizedBox(height: StorySpacing.md),
                Text(
                  isIssue
                      ? l10n.actorHowToPlayIssueRightsTitle
                      : l10n.actorHowToPlaySignRightsTitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                if (isIssue) ...[
                  _RightRow(
                    background: panelBg,
                    children: [
                      _RightEmphasis(
                        l10n.actorHowToPlayIssueRightSignLabel,
                        l10n.actorHowToPlayIssueRightSign,
                        fg,
                        mutedFg,
                      ),
                    ],
                  ),
                  const SizedBox(height: StorySpacing.sm),
                  _RightRow(
                    background: panelBg,
                    children: [
                      _RightEmphasis(
                        l10n.actorHowToPlayIssueRightPerformLabel,
                        l10n.actorHowToPlayIssueRightPerform,
                        fg,
                        mutedFg,
                      ),
                    ],
                  ),
                  const SizedBox(height: StorySpacing.sm),
                  _RightRow(
                    background: panelBg,
                    children: [
                      _RightEmphasis(
                        l10n.actorHowToPlayIssueRightValueLabel,
                        l10n.actorHowToPlayIssueRightValue,
                        fg,
                        mutedFg,
                      ),
                    ],
                  ),
                ] else ...[
                  _RightRow(
                    background: panelBg,
                    children: [
                      Text(
                        l10n.actorHowToPlaySignRightPerform,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: mutedFg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: StorySpacing.sm),
                  _RightRow(
                    background: panelBg,
                    children: [
                      Text(
                        l10n.actorHowToPlaySignRightTrade,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: mutedFg,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isIssue) ...[
                  const SizedBox(height: StorySpacing.xl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: panelBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(StorySpacing.base),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.actorHowToPlayCreateHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 22 / 15,
                              color: fg,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            child: _CreateCtaButton(
                              label: l10n.actorHowToPlayCreateCta,
                              onPressed: _goCreate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            StorySpacing.base,
            StorySpacing.sm,
            StorySpacing.base,
            StorySpacing.base + bottomPad,
          ),
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: StoryColors.borderOf(brightness)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: fg,
              ),
              child: Text(
                l10n.gameStaminaMechanismAction,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Figma「去创作」：内容宽度居中、圆角 12、深色底(亮) / 白底(暗)，文案 + 右箭头。
class _CreateCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _CreateCtaButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = StoryColors.actorSignSheetConfirmBgOf(brightness);
    final fg = StoryColors.actorSignSheetConfirmFgOf(brightness);

    // Figma 970:116659 — px 16 / py 10, 内容宽度居中, 圆角 12.
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                _createArrowAsset,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Center(
        child: Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: StoryColors.dividerOf(Theme.of(context).brightness),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _TabCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TabCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final mutedFg = StoryColors.mutedForegroundOf(brightness);
    return Material(
      color: selected ? StoryColors.cardOf(brightness) : Colors.transparent,
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.all(StorySpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  height: 25 / 17,
                  fontWeight: FontWeight.w700,
                  color: selected ? fg : mutedFg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 0.04,
                  fontWeight: FontWeight.w500,
                  color: mutedFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  final Color titleColor;
  final Color bodyColor;

  const _Section({
    required this.title,
    required this.body,
    required this.titleColor,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: TextStyle(fontSize: 14, height: 20 / 14, color: bodyColor),
        ),
      ],
    );
  }
}

class _RightRow extends StatelessWidget {
  final Color background;
  final List<Widget> children;

  const _RightRow({required this.background, required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.base,
          vertical: StorySpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _RightEmphasis extends StatelessWidget {
  final String label;
  final String body;
  final Color labelColor;
  final Color bodyColor;

  const _RightEmphasis(this.label, this.body, this.labelColor, this.bodyColor);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          TextSpan(
            text: body,
            style: TextStyle(fontSize: 14, height: 20 / 14, color: bodyColor),
          ),
        ],
      ),
    );
  }
}
