import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/video_feed_controller.dart';
import 'package:story_app/src/view/widgets/video_feed/video_feed_overlays.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/foundation/router.dart';
import 'package:story_app/src/routes/story_routes.dart';

class MockVideoFeedController extends Mock implements VideoFeedController {
  @override
  Future<T> holdAutoAdvance<T>(
    Future<T> Function() action, {
    bool advanceIfCompletedOnEnd = true,
  }) async {
    return await action();
  }

  @override
  void beginOverlayHold() {}

  @override
  void endOverlayHold({bool advanceIfCompleted = true}) {}
}

class MockDramaRepository extends Mock implements DramaRepository {}

class MockLocalRepository extends Mock implements StoryLocalRepository {}

class _LoggedInAuthController extends AuthController {
  @override
  AuthState build() {
    Future.microtask(completeReady);
    return const AuthState(
      ready: true,
      isLoggedIn: true,
      profile: UserProfile(userId: 'u1', email: 'test@example.com'),
    );
  }
}

void main() {
  late MockVideoFeedController mockController;
  late MockDramaRepository mockDramaRepo;
  late MockLocalRepository mockLocalRepo;
  late ValueNotifier<Duration> positionNotifier;
  late ValueNotifier<bool> playingListenable;
  late ValueNotifier<bool> userPausedListenable;

  setUpAll(() {
    registerFallbackValue(WorkContentType.shortDrama);
    registerFallbackValue(() async {});
    StoryRoutes.registerRoutes();
  });

  tearDownAll(() {
    StoryRouter.instance.clear();
  });

  setUp(() {
    mockController = MockVideoFeedController();
    mockDramaRepo = MockDramaRepository();
    mockLocalRepo = MockLocalRepository();
    positionNotifier = ValueNotifier<Duration>(Duration.zero);
    playingListenable = ValueNotifier<bool>(true);
    userPausedListenable = ValueNotifier<bool>(false);
    when(() => mockLocalRepo.isFavorite(any())).thenReturn(false);

    when(() => mockController.status).thenReturn(FeedPlaybackStatus.ready);
    when(() => mockController.currentEpisodeNo).thenReturn(1);
    when(() => mockController.episodeCount).thenReturn(10);
    when(() => mockController.totalEpisodes).thenReturn(10);
    when(() => mockController.initialEpisodeNo).thenReturn(1);
    when(() => mockController.isPlaying).thenReturn(true);
    when(() => mockController.duration).thenReturn(const Duration(minutes: 1));
    when(() => mockController.positionNotifier).thenReturn(positionNotifier);
    when(() => mockController.playingListenable).thenReturn(playingListenable);
    when(
      () => mockController.userPausedListenable,
    ).thenReturn(userPausedListenable);
    when(() => mockController.dramaId).thenReturn('drama_123');
    when(() => mockController.currentPlay).thenReturn(
      const DramaPlayResponse(
        dramaId: 'drama_123',
        episodeId: 'episode_456',
        episodeNo: 1,
        likedByMe: false,
        likeCount: 0,
        commentCount: 0,
        favoritedByMe: false,
        favoriteCount: 0,
      ),
    );
    when(() => mockController.playForEpisode(any())).thenAnswer((invocation) {
      final epNo = invocation.positionalArguments[0] as int;
      if (epNo == 1) {
        return const DramaPlayResponse(
          dramaId: 'drama_123',
          episodeId: 'episode_456',
          episodeNo: 1,
          likedByMe: false,
          likeCount: 0,
          commentCount: 0,
          favoritedByMe: false,
          favoriteCount: 0,
        );
      }
      return null;
    });
    when(() => mockController.dramaDetail).thenReturn(null);
    when(() => mockController.togglePlayPause()).thenAnswer((_) async {});
    when(() => mockController.isShortVideo).thenReturn(false);
    when(() => mockController.isUserPaused).thenReturn(false);
    when(
      () => mockController.contentType,
    ).thenReturn(WorkContentType.shortDrama);
    when(() => mockController.autoPlayEnabled).thenReturn(true);

    // Stub getReportTypes
    when(
      () => mockDramaRepo.getReportTypes(scope: any(named: 'scope')),
    ).thenAnswer(
      (_) async => Result.success([
        const ReportTypeItem(id: '1', code: 'PORN', name: '低俗色情'),
        const ReportTypeItem(id: '2', code: 'ILLEGAL', name: '涉嫌违法犯罪'),
        const ReportTypeItem(id: '3', code: 'SENSITIVE', name: '内容敏感'),
        const ReportTypeItem(id: '4', code: 'GAMBLING', name: '涉黑赌博'),
        const ReportTypeItem(id: '5', code: 'MINORS', name: '侵害未成年人'),
        const ReportTypeItem(id: '6', code: 'COPYRIGHT', name: '侵权投诉'),
        const ReportTypeItem(id: '7', code: 'QUALITY', name: '质量问题'),
        const ReportTypeItem(id: '8', code: 'OTHER', name: '其他'),
      ]),
    );

    // Stub reportEpisode
    when(
      () => mockDramaRepo.reportEpisode(
        dramaId: any(named: 'dramaId'),
        episodeId: any(named: 'episodeId'),
        reportType: any(named: 'reportType'),
        description: any(named: 'description'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => Result.success(null));
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        dramaRepositoryProvider.overrideWithValue(mockDramaRepo),
        localRepositoryProvider.overrideWithValue(mockLocalRepo),
        authControllerProvider.overrideWith(_LoggedInAuthController.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: VideoFeedOverlays(
            controller: mockController,
            episodeNo: 1,
            isLiveChrome: true,
            title: 'Test Drama',
          ),
        ),
      ),
    );
  }

  testWidgets(
    'Long press on VideoFeedOverlays background shows Report ActionSheet, navigates to ReportPage, and submits successfully',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Verify overlays render
      expect(find.text('第 1 集'), findsOneWidget);

      // Long press on the center of the screen
      final center = tester.getCenter(find.byType(VideoFeedOverlays));
      await tester.longPressAt(center);
      await tester.pumpAndSettle();

      // Verify ActionSheet with "举报" (Report) appears
      expect(find.text('举报'), findsOneWidget);

      // Tap the "举报" item in ActionSheet to navigate to ReportPage
      await tester.tap(find.text('举报'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Now we should be on ReportPage. Verify report reasons exist
      expect(find.text('低俗色情'), findsOneWidget);
      expect(find.text('涉嫌违法犯罪'), findsOneWidget);
      expect(find.text('举报描述'), findsOneWidget);

      // Select "涉嫌违法犯罪"
      await tester.tap(find.text('涉嫌违法犯罪'));
      await tester.pumpAndSettle();

      // Enter some description text
      await tester.enterText(find.byType(TextField), '测试举报内容违法');
      await tester.pumpAndSettle();

      // Click submit button at the bottom (ElevatedButton)
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Submit shows the success dialog; the report page stays behind it.
      expect(find.text('提交成功，我们将尽快受理'), findsOneWidget);
      expect(find.text('完成'), findsOneWidget);

      // Tap "完成" to dismiss the dialog, which pops back to the player page.
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();

      // Verify we popped back to the player page.
      expect(find.text('低俗色情'), findsNothing);
      expect(find.text('第 1 集'), findsOneWidget);
    },
  );
}
