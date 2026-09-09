import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/feed_tracking_service.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/services/device_id_service.dart';

class MockDramaRepository extends Mock implements DramaRepository {}

class MockLocalRepository extends Mock implements StoryLocalRepository {}

class MockDeviceIdService extends Mock implements DeviceIdService {}

class FakeAuthController extends Notifier<AuthState> implements AuthController {
  FakeAuthController({this.loggedInUserId});

  final String? loggedInUserId;
  final StreamController<bool> _authChanges =
      StreamController<bool>.broadcast();
  final Completer<void> _readyCompleter = Completer<void>()..complete();

  @override
  AuthState build() => AuthState(
    ready: true,
    isLoggedIn: loggedInUserId != null,
    profile: loggedInUserId == null
        ? null
        : UserProfile(id: loggedInUserId, userId: loggedInUserId),
  );

  @override
  void completeReady() {}

  @override
  Stream<bool> get authStateChanges => _authChanges.stream;

  @override
  bool get isLoggedIn => loggedInUserId != null;

  @override
  String? get accessToken => state.token;

  @override
  String? get userId => state.userId;

  @override
  Future<String?> getAccessToken() async => state.token;

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  Future<void> logout() async {}

  @override
  Future<PrivySessionGate> ensurePrivySessionReady() async =>
      isLoggedIn ? PrivySessionGate.ready : PrivySessionGate.needsReauth;

  @override
  String get pendingEmail => '';

  @override
  String get solanaAddress => '';

  @override
  String get ethereumAddress => '';

  @override
  Future<void> ensureWallets() async {}

  @override
  Future<void> syncWalletAddressesFromStorage() async {}

  @override
  bool get isLogging => false;

  @override
  bool get isLoggingOut => false;

  @override
  UserProfile? get profile => state.profile;

  @override
  Future<({bool ok, String? err})> sendOtp(String email) async =>
      (ok: true, err: null);

  @override
  Future<({bool ok, String? err})> verifyOtp(String code) async =>
      (ok: true, err: null);

  @override
  void updateProfile(UserProfile newProfile) {}

  @override
  Future<void> setToken(String token) async {}

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

  void dispose() {
    _authChanges.close();
  }
}

void main() {
  late MockDramaRepository dramaRepo;
  late MockLocalRepository localRepo;
  late MockDeviceIdService deviceIdService;
  late FakeAuthController fakeAuth;
  late ProviderContainer container;
  late FeedTrackingService tracking;

  setUpAll(() {
    registerFallbackValue(EpisodeTrackEvent.play);
    registerFallbackValue(WorkContentType.shortDrama);
  });

  setUp(() {
    dramaRepo = MockDramaRepository();
    localRepo = MockLocalRepository();
    deviceIdService = MockDeviceIdService();
    fakeAuth = FakeAuthController(loggedInUserId: 'user-1');
    FeedTrackingService.clearTrackingHistory();

    when(
      () => deviceIdService.getDeviceId(),
    ).thenAnswer((_) async => 'app-5a2544f5-a12d-4111-a12d-3ad3f280c40c');
    when(
      () => dramaRepo.trackEpisode(
        any(),
        any(),
        any(),
        deviceId: any(named: 'deviceId'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => Result<void>.success(null));

    container = ProviderContainer(
      overrides: [
        dramaRepositoryProvider.overrideWithValue(dramaRepo),
        localRepositoryProvider.overrideWithValue(localRepo),
        deviceIdServiceProvider.overrideWithValue(deviceIdService),
        authControllerProvider.overrideWith(() => fakeAuth),
      ],
    );
    final trackingProvider = Provider<FeedTrackingService>(
      (ref) => FeedTrackingService(ref),
    );
    tracking = container.read(trackingProvider);
  });

  tearDown(() {
    container.dispose();
    fakeAuth.dispose();
    FeedTrackingService.clearTrackingHistory();
  });

  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 30));

  group('FeedTrackingService', () {
    test('sends Device-ID value with app- prefix', () async {
      tracking.fireTrack(
        dramaId: 'd1',
        episodeId: 'e1',
        event: EpisodeTrackEvent.play,
      );
      await flush();

      verify(
        () => dramaRepo.trackEpisode(
          'd1',
          'e1',
          EpisodeTrackEvent.play,
          deviceId: 'app-5a2544f5-a12d-4111-a12d-3ad3f280c40c',
          type: any(named: 'type'),
        ),
      ).called(1);
    });

    test('does not cap play reports client-side (backend enforces daily limits)',
        () async {
      for (var i = 0; i < 6; i++) {
        tracking.fireTrack(
          dramaId: 'd1',
          episodeId: 'e1',
          event: EpisodeTrackEvent.play,
        );
        await flush();
      }

      verify(
        () => dramaRepo.trackEpisode(
          'd1',
          'e1',
          EpisodeTrackEvent.play,
          deviceId: any(named: 'deviceId'),
          type: any(named: 'type'),
        ),
      ).called(6);
    });

    test('does not cap complete reports client-side', () async {
      tracking.fireTrack(
        dramaId: 'd1',
        episodeId: 'e1',
        event: EpisodeTrackEvent.complete,
      );
      await flush();
      tracking.fireTrack(
        dramaId: 'd1',
        episodeId: 'e1',
        event: EpisodeTrackEvent.complete,
      );
      await flush();

      verify(
        () => dramaRepo.trackEpisode(
          'd1',
          'e1',
          EpisodeTrackEvent.complete,
          deviceId: any(named: 'deviceId'),
          type: any(named: 'type'),
        ),
      ).called(2);
    });

    test('forwards short-video type to the repository', () async {
      tracking.fireTrack(
        dramaId: 'd1',
        episodeId: 'sv-1',
        event: EpisodeTrackEvent.complete,
        type: WorkContentType.shortVideo,
      );
      await flush();

      verify(
        () => dramaRepo.trackEpisode(
          'd1',
          'sv-1',
          EpisodeTrackEvent.complete,
          deviceId: any(named: 'deviceId'),
          type: WorkContentType.shortVideo,
        ),
      ).called(1);
    });
  });
}
