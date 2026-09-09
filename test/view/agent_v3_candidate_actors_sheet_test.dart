import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/agent_v2_candidate_actors_controller.dart';
import 'package:story_app/src/controller/agent_v2_candidate_actors_state.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/view/widgets/agent_v3/agent_v3_actor_list_skeleton.dart';
import 'package:story_app/src/view/widgets/agent_v3/agent_v3_candidate_actors_sheet.dart';
import 'package:story_app/src/widgets/story_state_widget.dart';

class _FakeCandidateActorsController extends AgentV2CandidateActorsController {
  _FakeCandidateActorsController(this.initialState, {this.refreshedState});

  final AgentV2CandidateActorsState initialState;
  final AgentV2CandidateActorsState? refreshedState;
  int refreshCount = 0;
  bool disposedBeforeRefreshCompleted = false;

  @override
  AgentV2CandidateActorsState build() => initialState;

  @override
  Future<void> refresh() async {
    refreshCount++;
    final nextState = refreshedState;
    if (nextState == null) return;

    state = const AgentV2CandidateActorsState(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (!ref.mounted) {
      disposedBeforeRefreshCompleted = true;
      return;
    }
    state = nextState;
  }
}

void main() {
  Widget buildSubject(
    AgentV2CandidateActorsState state, {
    _FakeCandidateActorsController? controller,
  }) {
    return ProviderScope(
      overrides: [
        agentV2CandidateActorsControllerProvider.overrideWith(
          () => controller ?? _FakeCandidateActorsController(state),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(body: AgentV3CandidateActorsSheet()),
      ),
    );
  }

  Widget buildLauncher(_FakeCandidateActorsController controller) {
    return ProviderScope(
      overrides: [
        agentV2CandidateActorsControllerProvider.overrideWith(() => controller),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAgentV3CandidateActorsSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders Figma waiting grid with V2 candidate actor data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const actors = [
      MiningActor(
        actorName: 'Jack willen',
        actorNftId: 'actor-1',
        actorTokenId: 355,
        level: 1,
        stamina: 18,
        computingPower: 123.44,
      ),
      MiningActor(
        actorName: 'Luna',
        actorNftId: 'actor-2',
        actorTokenId: 12,
        level: 2,
        stamina: 20,
        computingPower: 64,
      ),
      MiningActor(
        actorName: 'Nova',
        actorNftId: 'actor-3',
        actorTokenId: 7,
        level: 3,
        stamina: 9,
        computingPower: 32,
      ),
    ];

    await tester.pumpWidget(
      buildSubject(
        const AgentV2CandidateActorsState(
          actors: actors,
          isInitialized: true,
          hasMore: false,
          totalCount: 3,
        ),
      ),
    );
    await tester.pump();
    // EasyRefresh may schedule a zero-duration ballistic timer.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('候场角色'), findsOneWidget);
    expect(find.text('休息中的角色每小时恢复1点体力'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('agent-v3-candidate-grid')),
      findsOneWidget,
    );
    expect(find.text('Jack willen'), findsOneWidget);
    expect(find.text('#00355'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('agent-v3-refill-actor-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('agent-v3-perform-actor-1')),
      findsOneWidget,
    );
    expect(find.text('演出'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the shared empty-state widget when no candidates exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const AgentV2CandidateActorsState(isInitialized: true, hasMore: false),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('agent-v3-candidate-empty')),
      findsOneWidget,
    );
    expect(find.byType(StoryStateWidget), findsOneWidget);
    expect(find.text('暂无角色'), findsOneWidget);
  });

  testWidgets('keeps provider alive until delayed refresh data is rendered', (
    tester,
  ) async {
    const actor = MiningActor(
      actorName: '接口角色',
      actorNftId: 'api-actor',
      actorTokenId: 103,
      level: 1,
      stamina: 168,
      computingPower: 0.3396344418,
    );
    final controller = _FakeCandidateActorsController(
      const AgentV2CandidateActorsState(),
      refreshedState: const AgentV2CandidateActorsState(
        actors: [actor],
        isInitialized: true,
        hasMore: false,
        totalCount: 1,
      ),
    );

    await tester.pumpWidget(buildLauncher(controller));
    await tester.tap(find.text('open'));
    // First frame mounts the sheet; post-frame refresh flips to loading skeleton.
    await tester.pump();
    expect(controller.refreshCount, 1);
    expect(find.byType(AgentV3ActorListSkeleton), findsOneWidget);

    // Fake refresh resolves after 10ms.
    await tester.pump(const Duration(milliseconds: 20));

    expect(controller.disposedBeforeRefreshCompleted, isFalse);
    expect(find.text('接口角色'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('agent-v3-candidate-grid')),
      findsOneWidget,
    );
    // Drain EasyRefresh ballistic timers before the test ends.
    await tester.pump(const Duration(milliseconds: 50));
  });
}
