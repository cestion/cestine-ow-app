import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/app_providers.dart';
import '../view/widgets/invite/invite_code_prompt_controller.dart';
import 'alice_inspector_bubble.dart';

class StoryAppBuilder extends ConsumerWidget {
  final Widget? child;

  const StoryAppBuilder({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showInspectorBubble = !ref
        .watch(storySdkConfigProvider)
        .env
        .isProduction;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: child,
          ),
        ),
        // Global invite-code bind prompt after login (aligned with Web).
        const InviteCodePromptController(),
        if (showInspectorBubble) const AliceInspectorBubble(),
      ],
    );
  }
}
