import 'package:flutter/material.dart';

import 'story_app_builder.dart';

/// Composes app-wide UI behavior without leaking service lifecycle logic into
/// `main.dart`.
class StoryRootBuilder extends StatelessWidget {
  final Widget? child;

  const StoryRootBuilder({super.key, required this.child});

  @override
  Widget build(BuildContext context) => StoryAppBuilder(child: child);
}
