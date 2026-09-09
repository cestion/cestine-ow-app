import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../provider/app_providers.dart';
import '../../provider/theater_home_tab_provider.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import 'theater_home_tabs.dart';
import '../../foundation/navigator.dart';

/// Top chrome: menu + 短剧/推荐 tabs + search.
///
/// [overlay] paints white controls over an edge-to-edge hero / video.
/// When false (short-drama list with no banner), uses theme colors on a
/// solid bar so the list sits below the chrome instead of under it.
class TheaterHomeChrome extends ConsumerWidget {
  final bool overlay;

  const TheaterHomeChrome({super.key, this.overlay = true});

  static const double contentHeight = 44;

  static double heightOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top + contentHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(theaterHomeTabProvider);
    final top = MediaQuery.paddingOf(context).top;
    final iconColor = overlay
        ? StoryColors.onOverlay
        : Theme.of(context).colorScheme.onSurface;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Material(
        color: overlay
            ? Colors.transparent
            : StoryColors.backgroundOf(Theme.of(context).brightness),
        child: DecoratedBox(
          decoration: overlay
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                )
              : const BoxDecoration(),
          child: Padding(
            padding: EdgeInsets.only(top: top),
            child: SizedBox(
              height: contentHeight,
              child: Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/common/home_menu.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: TheaterHomeChrome.contentHeight,
                    ),
                    visualDensity: VisualDensity.compact,
                    alignment: Alignment.center,
                    onPressed: () => ref
                        .read(mainShellScaffoldKeyProvider)
                        .currentState
                        ?.openDrawer(),
                  ),
                  Expanded(
                    child: Center(
                      child: TheaterHomeTabs(
                        selected: selected,
                        overlay: overlay,
                        onSelected: (tab) => ref
                            .read(theaterHomeTabProvider.notifier)
                            .select(tab),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/common/home_search.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: TheaterHomeChrome.contentHeight,
                    ),
                    visualDensity: VisualDensity.compact,
                    alignment: Alignment.center,
                    onPressed: () {
                      context.storyPush(RouteNames.search, arguments: {
                          'type': 'dramas',
                          'hintText': context.l10n.theaterSearchPlaceholder,
                        });
                    },
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
