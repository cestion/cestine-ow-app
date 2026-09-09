import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../styles/story_colors.dart';

class PublishVideoBottomBar extends StatelessWidget {
  final bool showDraftButton;
  final String draftLabel;
  final String nextLabel;
  final bool canContinue;
  final bool isPublishing;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onContinue;

  const PublishVideoBottomBar({
    super.key,
    this.showDraftButton = true,
    required this.draftLabel,
    required this.nextLabel,
    required this.canContinue,
    required this.isPublishing,
    required this.onSaveDraft,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final background = StoryColors.cardOf(brightness).withValues(alpha: 0.94);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: ColoredBox(
          color: background,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  if (showDraftButton) ...[
                    Expanded(
                      child: _BottomButton(
                        label: draftLabel,
                        enabled: true,
                        outlined: true,
                        onPressed: onSaveDraft,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _BottomButton(
                      label: nextLabel,
                      enabled: canContinue && !isPublishing,
                      loading: isPublishing,
                      onPressed: onContinue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool outlined;
  final bool loading;
  final VoidCallback? onPressed;

  const _BottomButton({
    required this.label,
    required this.enabled,
    this.outlined = false,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final unavailable = brightness == Brightness.light
        ? StoryColors.buttonDisabledForeground
        : StoryColors.darkMutedForeground;
    final background = outlined
        ? Colors.transparent
        : enabled || loading
        ? (isDark ? Colors.white : Colors.black)
        : unavailable;
    final foreground = outlined
        ? (enabled ? StoryColors.foregroundOf(brightness) : unavailable)
        : (isDark ? Colors.black : Colors.white);

    final content = Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: outlined
            ? Border.all(
                color: enabled
                    ? StoryColors.foregroundOf(brightness)
                    : StoryColors.dividerOf(brightness),
                width: 1.5,
              )
            : null,
      ),
      child: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: foreground,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w700,
              ),
            ),
    );

    if (!enabled || loading) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}
