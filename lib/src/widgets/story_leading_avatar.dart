import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../provider/app_providers.dart';
import '../styles/story_spacing.dart';
import 'story_avatar.dart';

/// Default avatar SVG assets for unauthenticated users.
const _defaultAvatarLight = 'assets/common/avatar.svg';
const _defaultAvatarDark = 'assets/common/avatar_d.svg';

/// Reusable App Bar leading avatar button that opens the main shell profile drawer when tapped.
class StoryLeadingAvatar extends ConsumerWidget {
  const StoryLeadingAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(
      authControllerProvider.select((c) => c.isLoggedIn),
    );
    final profile = ref.watch(authControllerProvider.select((c) => c.profile));

    final avatar = isLoggedIn
        ? StoryAvatar(
            imageUrl: profile?.avatarUrl,
            userId: profile?.userId ?? profile?.id,
            fallbackText: profile?.nickname ?? profile?.email,
            size: 32,
          )
        : _defaultAvatar(context, size: 32);

    return GestureDetector(
      onTap: () =>
          ref.read(mainShellScaffoldKeyProvider).currentState?.openDrawer(),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: StorySpacing.screenHorizontal),
          child: avatar,
        ),
      ),
    );
  }
}

/// Returns a theme-aware default avatar SVG for unauthenticated users.
Widget _defaultAvatar(BuildContext context, {required double size}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return SvgPicture.asset(
    isDark ? _defaultAvatarDark : _defaultAvatarLight,
    width: size,
    height: size,
  );
}
