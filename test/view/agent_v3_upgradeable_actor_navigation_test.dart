import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/agent_v2_upgradeable_actors_controller.dart';
import 'package:story_app/src/controller/agent_v2_upgradeable_actors_state.dart';
import 'package:story_app/src/controller/agent_v3_controller.dart';
import 'package:story_app/src/controller/agent_v3_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/actor_repository.dart';
import 'package:story_app/src/routes/route_names.dart';
import 'package:story_app/src/view/widgets/agent_v3/agent_v3_upgradeable_actors_sheet.dart';

class _UpgradeableActorsController extends AgentV2UpgradeableActorsController {
  @override
  AgentV2UpgradeableActorsState build() => const AgentV2UpgradeableActorsState(
    actors: [
      MiningActor(
        actorName: '可跳转角色',
        actorNftId: 'detail-actor',
        actorCollectionId: 9527,
        level: 2,
        materialCount: 0,
      ),
    ],
    isInitialized: true,
    hasMore: false,
  );

  @override
  Future<void> refresh() async {}
}

class _AgentV3Controller extends AgentV3Controller {
  @override
  AgentV3State build() => AgentV3State(assets: UserAssets.empty);
}

class _MockActorRepository extends Mock implements ActorRepository {}

class _FallbackActorCollection extends Fake implements ActorCollection {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FallbackActorCollection());
  });

  testWidgets('tapping an upgrade item opens its actor detail page', (
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
    Object? pushedArguments;
    const config = GlobalConfig(
      init: InitConfig(
        actorNft: InitActorNftConfig(
          levels: {
            '2': InitActorNftLevelConfig(
              upgrade: InitActorNftUpgradeConfig(
                toLevel: 3,
                trainingManualAmount: 4,
                requiredMaterialCount: 2,
              ),
            ),
            '3': InitActorNftLevelConfig(
              upgrade: InitActorNftUpgradeConfig(
                toLevel: 4,
                trainingManualAmount: 8,
                requiredMaterialCount: 2,
              ),
            ),
            '4': InitActorNftLevelConfig(
              upgrade: InitActorNftUpgradeConfig(toLevel: 5),
            ),
            '5': InitActorNftLevelConfig(),
          },
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentV2UpgradeableActorsControllerProvider.overrideWith(
            _UpgradeableActorsController.new,
          ),
          agentV3ControllerProvider.overrideWith(_AgentV3Controller.new),
          globalConfigProvider.overrideWith(
            (ref) async => Result.success(config),
          ),
          agentV3UpgradeConfigCalibrationProvider.overrideWith(
            (ref) async => Result.success(config),
          ),
          actorRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          onGenerateRoute: (settings) {
            if (settings.name != RouteNames.actorDetail) return null;
            pushedArguments = settings.arguments;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('角色详情页')),
            );
          },
          home: const Scaffold(body: AgentV3UpgradeableActorsSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('agent-v3-upgrade-same-ip-add-detail-actor')),
    );
    await tester.pumpAndSettle();

    expect(find.text('角色详情页'), findsOneWidget);
    expect(pushedArguments, isA<Map<String, dynamic>>());
    expect((pushedArguments as Map<String, dynamic>)['actorId'], '9527');
    verify(
      () => repository.seedActorCollectionDetail(
        any(
          that: isA<ActorCollection>().having(
            (actor) => actor.id,
            'id',
            '9527',
          ),
        ),
      ),
    ).called(1);
  });
}
