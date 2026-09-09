import 'package:flutter/material.dart';

import '../styles/story_colors.dart';

/// Minimal capsule switch matching player / sheet design:
/// - On: dark charcoal track, white thumb (right)
/// - Off: light grey track, white thumb (left)
///
/// Prefer this over [Switch.adaptive] for dark overlay surfaces.
class StorySwitch extends StatelessWidget {
  static const double width = 46;
  static const double height = 28;
  static const double thumbSize = 24;
  static const double _inset = 2;

  final bool value;
  final ValueChanged<bool>? onChanged;

  const StorySwitch({super.key, required this.value, required this.onChanged});

  bool get _enabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final trackColor = value ? StoryColors.darkMuted : const Color(0xFFB0B4BA);

    return Semantics(
      toggled: value,
      enabled: _enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: width,
          height: height,
          padding: const EdgeInsets.all(_inset),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: thumbSize,
              height: thumbSize,
              decoration: const BoxDecoration(
                color: StoryColors.onOverlay,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
