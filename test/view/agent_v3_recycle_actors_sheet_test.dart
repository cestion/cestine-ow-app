import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/agent_v3_recycle_actors_controller.dart';
import 'package:story_app/src/controller/agent_v3_recycle_actors_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/actor_repository.dart';
import 'package:story_app/src/routes/route_names.dart';
import 'package:story_app/src/view/widgets/agent_v3/agent_v3_recycle_actors_sheet.dart';

class _RecycleActorsController extends AgentV3RecycleActorsController {
  int recycleCalls = 0;

  @override
  AgentV3RecycleActorsState build() => const AgentV3RecycleActorsState(
    actors: [
      MiningActor(
        actorName: 'Jack willen',
        actorNftId: 'recycle-actor',
        actorCollectionId: 9527,
        actorTokenId: 355,
        level: 1,
        status: 'MINING',
        computingPower: 123.54,
      ),
    ],
    isInitialized: true,
    hasMore: false,
    totalCount: 1,
  );

  @override
  Future<void> refresh() async {}

  @override
  Future<Result<ActorNftRecycleEstimateResponse>> getRecycleEstimate(
    MiningActor actor,
  ) async => Result.success(
    const ActorNftRecycleEstimateResponse(
      actorCollectionId: '9527',
      tokenId: '355',
      assetId: '9527_355',
      refundUsdcAmount: '50.3399',
      refundAmountMinor: '50339900',
      refundTrainingManual: '1',
    ),
  );

  @override
  Future<Result<String>> recycleActor({
    required MiningActor actor,
    required ActorNftRecycleEstimateResponse estimate,
  }) async {
    recycleCalls++;
    return Result.success('tx-signature');
  }
}

class _MockActorRepository extends Mock implements ActorRepository {}

class _FallbackActorCollection extends Fake implements ActorCollection {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FallbackActorCollection());
  });

  testWidgets('matches recycle sheet content and only card opens detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MockActorRepository();
    when(
      () => repository.seedActorCollectionDetail(any()),
    ).thenAnswer((_) async {});

    final controller = _RecycleActorsController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentV3RecycleActorsControllerProvider.overrideWith(() => controller),
          actorRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          onGenerateRoute: (settings) {
            if (settings.name != RouteNames.actorDetail) return null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('角色详情页')),
            );
          },
          home: const Scaffold(body: AgentV3RecycleActorsSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('角色回收'), findsOneWidget);
    expect(find.text('Jack willen'), findsOneWidget);
    expect(find.text('#00355'), findsOneWidget);
    expect(find.text('123.54 /h', findRichText: true), findsOneWidget);
    expect(find.text('回收'), findsOneWidget);
    expect(find.byKey(const ValueKey('agent-v3-recycle-grid')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('agent-v3-recycle-submit')));
    await tester.pumpAndSettle();
    expect(find.text('角色详情页'), findsNothing);
    expect(
      find.byKey(const ValueKey('agent-v3-recycle-confirm-dialog')),
      findsOneWidget,
    );
    expect(find.text('Jack willen #355'), findsOneWidget);
    expect(find.text('演出中'), findsOneWidget);
    expect(find.text('你将获得'), findsOneWidget);
    expect(find.text('50.33'), findsOneWidget);
    expect(find.text('50.3399'), findsNothing);
    expect(
      find.byKey(const ValueKey('agent-v3-recycle-points-icon')),
      findsOneWidget,
    );
    expect(find.text('角色将被永久销毁，不可恢复'), findsOneWidget);
    expect(find.text('确认销毁'), findsOneWidget);
    expect(
      tester.getSize(
        find.byKey(const ValueKey('agent-v3-recycle-dialog-surface')),
      ),
      const Size(343, 387),
    );

    await tester.tap(find.byKey(const ValueKey('agent-v3-recycle-cancel')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('agent-v3-recycle-card-recycle-actor')),
    );
    await tester.pumpAndSettle();
    expect(find.text('角色详情页'), findsOneWidget);
  });

  testWidgets('requires a filled second confirmation before recycle', (
    tester,
  ) async {
    final controller = _RecycleActorsController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentV3RecycleActorsControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: Scaffold(body: AgentV3RecycleActorsSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('agent-v3-recycle-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('agent-v3-recycle-confirm')));
    await tester.pump();

    expect(controller.recycleCalls, 0);
    expect(find.text('再次点击销毁'), findsOneWidget);
    final armedButton = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('agent-v3-recycle-confirm')),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(
      armedButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      const Color(0xFFE50815),
    );

    await tester.tap(find.byKey(const ValueKey('agent-v3-recycle-confirm')));
    await tester.pumpAndSettle();

    expect(controller.recycleCalls, 1);
    expect(
      find.byKey(const ValueKey('agent-v3-recycle-confirm-dialog')),
      findsNothing,
    );
    await tester.pump(const Duration(seconds: 4));
  });
}
