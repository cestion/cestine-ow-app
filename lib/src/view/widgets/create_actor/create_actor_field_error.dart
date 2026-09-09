import 'package:flutter/material.dart';

import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';

/// Inline field error text below create-actor form inputs (mirrors Web FormMessage).
class CreateActorFieldError extends StatelessWidget {
  final String? message;

  const CreateActorFieldError({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: StorySpacing.xs),
      child: Text(
        message!,
        style: const TextStyle(
          fontSize: 14,
          height: 20 / 14,
          color: StoryColors.destructive,
        ),
      ),
    );
  }
}
