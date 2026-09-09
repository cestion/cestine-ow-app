import 'package:flutter/material.dart';

import '../../../styles/story_colors.dart';

class PublishVideoDescriptionField extends StatelessWidget {
  final String label;
  final String requiredLabel;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const PublishVideoDescriptionField({
    super.key,
    required this.label,
    required this.requiredLabel,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final tertiary = brightness == Brightness.light
        ? StoryColors.lightTertiaryText
        : StoryColors.darkTertiaryText;
    final fill = StoryColors.mutedOf(brightness);
    final border = brightness == Brightness.light
        ? StoryColors.lightSheetSecondary
        : StoryColors.darkBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              requiredLabel,
              style: TextStyle(
                color: StoryColors.mutedForegroundOf(brightness),
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 124,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              TextField(
                controller: controller,
                onChanged: onChanged,
                maxLength: 200,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  height: 22 / 15,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: tertiary,
                    fontSize: 15,
                    height: 22 / 15,
                  ),
                  counterText: '',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 12,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => Text(
                    '${value.text.characters.length}/200',
                    style: TextStyle(
                      color: tertiary,
                      fontSize: 12,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
