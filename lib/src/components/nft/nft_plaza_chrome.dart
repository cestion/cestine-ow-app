import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../controller/search_state.dart';
import '../../l10n/story_l10n.dart';
import '../../provider/app_providers.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import 'actor_how_to_play_dialog.dart';
import '../../foundation/navigator.dart';

/// Figma `949:104394` / `949:105095`：汉堡菜单 + 搜索 + 玩法说明。
class NftPlazaNavLeading extends ConsumerWidget {
  const NftPlazaNavLeading({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconColor = StoryColors.foregroundOf(Theme.of(context).brightness);
    return IconButton(
      key: const ValueKey('nft-plaza-menu'),
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      padding: const EdgeInsets.only(left: StorySpacing.screenHorizontal),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
      onPressed: () =>
          ref.read(mainShellScaffoldKeyProvider).currentState?.openDrawer(),
      icon: SvgPicture.asset(
        'assets/common/home_menu.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }
}

/// Right-side search + help icons, 24px with 12px gap and 16px trailing inset.
class NftPlazaNavActions extends ConsumerWidget {
  const NftPlazaNavActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(right: StorySpacing.screenHorizontal),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NftPlazaNavIcon(
            key: const ValueKey('nft-plaza-search'),
            asset: 'assets/common/home_search.svg',
            tooltip: MaterialLocalizations.of(context).searchFieldLabel,
            onPressed: () {
              context.storyPush(RouteNames.search, arguments: {
                  'type': SearchType.actors.name,
                  'hintText': l10n.nftSearchHint,
                });
            },
          ),
          const SizedBox(width: StorySpacing.md),
          _NftPlazaNavIcon(
            key: const ValueKey('nft-plaza-help'),
            asset: 'assets/game/stamina_help.svg',
            tooltip: l10n.actorHowToPlayHelpTooltip,
            onPressed: () => ActorHowToPlayDialog.show(context),
          ),
        ],
      ),
    );
  }
}

class _NftPlazaNavIcon extends StatelessWidget {
  final String asset;
  final String tooltip;
  final VoidCallback onPressed;

  const _NftPlazaNavIcon({
    super.key,
    required this.asset,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = StoryColors.foregroundOf(Theme.of(context).brightness);
    return SizedBox(
      width: 24,
      height: 44,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 44),
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: SvgPicture.asset(
          asset,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}
