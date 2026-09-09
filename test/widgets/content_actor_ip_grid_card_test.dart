import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/components/badge/content_badge.dart';
import 'package:story_app/src/components/content/content_actor_ip_grid_card.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/config_providers.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        globalConfigProvider.overrideWith(
          (ref) async => Result.success(const GlobalConfig()),
        ),
      ],
      child: child,
    );
  }

  testWidgets('sold-out vi card keeps price row within the cell', (
    tester,
  ) async {
    const cardWidth = 175.5;
    const cardHeight =
        cardWidth / ContentActorIpGridCard.coverAspectRatio +
        ContentActorIpGridCard.infoHeight;

    await tester.pumpWidget(
      wrap(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('vi'),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: ContentActorIpGridCard(
                  actor: ActorCollection(
                    id: 'ip-1',
                    name: 'Luna',
                    badge: 'COMMUNITY',
                    availableSupply: '0',
                    floorPriceUsdc: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('--'), findsOneWidget);
    expect(find.text('Cát-xê'), findsOneWidget);
    expect(find.textContaining('STORY/h'), findsOneWidget);
    expect(find.byType(ContentBadge), findsNothing);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(ContentActorIpGridCard)).width,
      closeTo(cardWidth, 0.5),
    );
  });

  testWidgets('grid-sized card does not overflow info column', (tester) async {
    final aspect = ContentActorIpGridCard.gridChildAspectRatioFor(359);
    const cardWidth =
        (359 - ContentActorIpGridCard.gridSpacing) /
        ContentActorIpGridCard.gridCrossAxisCount;
    final cardHeight = cardWidth / aspect;

    await tester.pumpWidget(
      wrap(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: const ContentActorIpGridCard(
                  actor: ActorCollection(
                    id: '437492926326595584',
                    name: '超长角色名称测试溢出',
                    badge: 'COMMUNITY',
                    availableSupply: '3',
                    currentPriceUsdc: 12.34,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('content badge can be shown or hidden', (tester) async {
    Future<void> pump({required bool showContentBadge}) {
      return tester.pumpWidget(
        wrap(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: Scaffold(
              body: SizedBox(
                width: 176,
                height: 291,
                child: ContentActorIpGridCard(
                  showContentBadge: showContentBadge,
                  actor: const ActorCollection(
                    id: 'ip-1',
                    name: 'Luna',
                    badge: 'COMMUNITY',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await pump(showContentBadge: true);
    await tester.pump();
    expect(find.byType(ContentBadge), findsOneWidget);
    expect(find.text('社区发行'), findsOneWidget);

    await pump(showContentBadge: false);
    await tester.pump();
    expect(find.byType(ContentBadge), findsNothing);
  });
}
