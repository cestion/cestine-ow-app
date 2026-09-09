import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/view/widgets/agent_v3/agent_v3_actor_carousel.dart';

const _actor = MiningActor(
  actorName: 'Actor',
  actorNftId: '90001_10001',
  actorCollectionId: 9527,
  actorTokenId: 10001,
  level: 2,
  stamina: 120,
);

void main() {
  testWidgets('only the actor image opens detail', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var detailCalls = 0;
    var refillCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: AgentV3ActorCarousel(
              actors: const [_actor],
              staminaLimit: 168,
              initialPage: 0,
              onPageChanged: (_) {},
              onActorPressed: (_) => detailCalls++,
              onRefillPressed: (_) => refillCalls++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('agent-v3-actor-image-9527')));
    await tester.pump();
    expect(detailCalls, 1);

    await tester.tap(
      find.byKey(const ValueKey('agent-v3-card-identity-90001_10001')),
    );
    await tester.pump();
    expect(detailCalls, 1);

    await tester.tap(
      find.byKey(const ValueKey('agent-v3-card-controls-90001_10001')),
    );
    await tester.pump();
    expect(detailCalls, 1);

    await tester.tap(
      find.byKey(const ValueKey('agent-v3-card-refill-90001_10001')),
    );
    await tester.pump();
    expect(refillCalls, 1);
    expect(detailCalls, 1);
  });
}
