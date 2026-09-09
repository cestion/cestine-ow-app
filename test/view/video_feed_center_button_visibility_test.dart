import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/video_feed_controller.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/view/widgets/video_feed/feed_paused_play_overlay.dart';
import 'package:story_app/src/view/widgets/video_feed/video_feed_overlays.dart';

class MockVideoFeedController extends Mock implements VideoFeedController {}

class MockLocalRepo extends Mock implements StoryLocalRepository {}

class FakeAuthController extends Notifier<AuthState> implements AuthController {
  @override
  AuthState build() => const AuthState();

  @override
  void completeReady() {}

  @override
  String? get accessToken => state.token;

  @override
  String? get userId => state.userId;

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  bool get isLoggedIn => state.isLoggedIn;

  @override
  bool get isLogging => state.isLogging;

  @override
  bool get isLoggingOut => state.isLoggingOut;

  @override
  String get pendingEmail => state.pendingEmail;

  @override
  UserProfile? get profile => state.profile;

  @override
  Future<void> get ready async {}

  @override
  String get solanaAddress => state.effectiveSolanaAddress;

  @override
  String get ethereumAddress => state.ethereumAddress;

  @override
  Future<void> ensureWallets() async {}

  @override
  Future<void> syncWalletAddressesFromStorage() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<PrivySessionGate> ensurePrivySessionReady() async =>
      isLoggedIn ? PrivySessionGate.ready : PrivySessionGate.needsReauth;

  @override
  Future<String?> getAccessToken() async => state.token;

  @override
  Future<void> setToken(String token) async {}

  @override
  Future<({bool ok, String? err})> sendOtp(String email) async =>
      (ok: true, err: null);

  @override
  Future<({bool ok, String? err})> verifyOtp(String code) async =>
      (ok: true, err: null);

  @override
  void updateProfile(UserProfile newProfile) {}

  @override
  Future<Result<void>> updateNickname({
    required String nickname,
    String? profile,
  }) async => Result.success(null);

  @override
  Future<Result<void>> updateAvatar(String avatarUrl) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteAccount() async => Result.success(null);

  @override
  Future<Result<void>> cancelAccountDeletion() async => Result.success(null);
}

void main() {
  late MockVideoFeedController mockController;
  late ValueNotifier<Duration> positionNotifier;
  late ValueNotifier<bool> playingNotifier;
  late ValueNotifier<bool> userPausedNotifier;

  setUp(() {
    mockController = MockVideoFeedController();
    positionNotifier = ValueNotifier(Duration.zero);
    playingNotifier = ValueNotifier(false);
    userPausedNotifier = ValueNotifier(false);

    when(() => mockController.currentEpisodeNo).thenReturn(3);
    when(() => mockController.episodeCount).thenReturn(3);
    when(() => mockController.initialEpisodeNo).thenReturn(3);
    when(() => mockController.isShortVideo).thenReturn(false);
    when(
      () => mockController.contentType,
    ).thenReturn(WorkContentType.shortDrama);
    when(() => mockController.duration).thenReturn(const Duration(minutes: 1));
    when(() => mockController.positionNotifier).thenReturn(positionNotifier);
    when(() => mockController.playingListenable).thenReturn(playingNotifier);
    when(() => mockController.userPausedListenable).thenReturn(userPausedNotifier);
    when(() => mockController.dramaId).thenReturn('drama_123');
    when(() => mockController.dramaDetail).thenReturn(null);
    when(() => mockController.togglePlayPause()).thenAnswer((_) async {});
    when(() => mockController.isPlaying).thenReturn(false);
    when(() => mockController.isUserPaused).thenReturn(false);
    when(() => mockController.status).thenReturn(FeedPlaybackStatus.ready);
    when(() => mockController.playForEpisode(any())).thenReturn(
      const DramaPlayResponse(
        episodeId: 'ep_3',
        episodeNo: 3,
        likedByMe: false,
        likeCount: 0,
        commentCount: 0,
        favoritedByMe: false,
        favoriteCount: 0,
      ),
    );
  });

  Widget buildOverlay() {
    return ProviderScope(
      overrides: [
        localRepositoryProvider.overrideWithValue(MockLocalRepo()),
        authControllerProvider.overrideWith(() => FakeAuthController()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: VideoFeedOverlays(
            controller: mockController,
            episodeNo: 3,
            isLiveChrome: true,
            title: 'Test Drama',
          ),
        ),
      ),
    );
  }

  testWidgets('shows center play when completed (last episode EOS)', (
    tester,
  ) async {
    when(() => mockController.status).thenReturn(FeedPlaybackStatus.completed);

    await tester.pumpWidget(buildOverlay());
    await tester.pump();

    expect(find.byType(FeedPausedPlayOverlay), findsOneWidget);
  });

  testWidgets('shows center play when user paused', (tester) async {
    userPausedNotifier.value = true;

    await tester.pumpWidget(buildOverlay());
    await tester.pump();

    expect(find.byType(FeedPausedPlayOverlay), findsOneWidget);
  });

  testWidgets('hides center play on swipe settle (ready + not user paused)', (
    tester,
  ) async {
    // Engine pause during swipe leaves ready/!playing without isUserPaused.
    when(() => mockController.status).thenReturn(FeedPlaybackStatus.ready);
    when(() => mockController.isPlaying).thenReturn(false);
    when(() => mockController.isUserPaused).thenReturn(false);

    await tester.pumpWidget(buildOverlay());
    await tester.pump();

    expect(find.byType(FeedPausedPlayOverlay), findsNothing);
  });

  testWidgets('hides center play while playing', (tester) async {
    playingNotifier.value = true;

    await tester.pumpWidget(buildOverlay());
    await tester.pump();

    expect(find.byType(FeedPausedPlayOverlay), findsNothing);
  });
}
