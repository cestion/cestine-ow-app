import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/controller/watch_history_reporter.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/auth_providers.dart';
import 'package:story_app/src/provider/core_providers.dart';
import 'package:story_app/src/provider/repository_providers.dart';
import 'package:story_app/src/repositories/drama_repository.dart';
import 'package:story_app/src/repositories/user_repository.dart';

class _MockUserRepository extends Mock implements UserRepository {}

class _FakeAuthController extends Notifier<AuthState> implements AuthController {
  _FakeAuthController({this.loggedInUserId});

  final String? loggedInUserId;
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
  Stream<bool> get authStateChanges => const Stream.empty();

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
  void completeReady() {}

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
  }) async =>
      Result.success(null);

  @override
  Future<Result<void>> updateAvatar(String avatarUrl) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteAccount() async => Result.success(null);

  @override
  Future<Result<void>> cancelAccountDeletion() async => Result.success(null);
}

class _ReportCaller extends Notifier<void> {
  @override
  void build() {}

  void report(String rawEpisodeId) {
    reportWatchHistory(ref, rawEpisodeId, EpisodeTrackEvent.play);
  }
}

final _reportCallerProvider = NotifierProvider<_ReportCaller, void>(
  _ReportCaller.new,
);

void main() {
  late _MockUserRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const WatchHistoryReportRequest(items: []));
  });

  setUp(() {
    repository = _MockUserRepository();
    WatchHistoryBatchReporter.flushDelay = const Duration(hours: 1);
    WatchHistoryBatchReporter.maxBatchSize = 20;
  });

  tearDown(() {
    container.dispose();
    WatchHistoryBatchReporter.flushDelay = const Duration(seconds: 30);
    WatchHistoryBatchReporter.maxBatchSize = 20;
  });

  ProviderContainer buildContainer({String? userId}) {
    return ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(repository),
        authControllerProvider.overrideWith(
          () => _FakeAuthController(loggedInUserId: userId),
        ),
        currentUserIdProvider.overrideWithValue(userId),
      ],
    );
  }

  group('WatchHistoryBatchReporter', () {
    test('enqueue keeps the latest watchedAt for duplicate episode ids', () async {
      when(
        () => repository.reportWatchHistory(any()),
      ).thenAnswer((_) async => Result.success(null));

      container = buildContainer(userId: 'u1');
      final reporter = container.read(
        watchHistoryBatchReporterProvider.notifier,
      );

      reporter.enqueue(100, watchedAt: 1000);
      reporter.enqueue(100, watchedAt: 2000);
      reporter.enqueue(200, watchedAt: 3000);

      expect(reporter.pendingCountForTest(), 2);
      await reporter.flush();

      verify(
        () => repository.reportWatchHistory(
          const WatchHistoryReportRequest(
            items: [
              WatchHistoryReportItem(episodeId: 100, watchedAt: 2000),
              WatchHistoryReportItem(episodeId: 200, watchedAt: 3000),
            ],
          ),
        ),
      ).called(1);
    });

    test('flush splits pending items into batches of 20', () async {
      WatchHistoryBatchReporter.maxBatchSize = 100;
      when(
        () => repository.reportWatchHistory(any()),
      ).thenAnswer((_) async => Result.success(null));

      container = buildContainer(userId: 'u1');
      final reporter = container.read(
        watchHistoryBatchReporterProvider.notifier,
      );

      for (var i = 1; i <= 21; i++) {
        reporter.enqueue(i, watchedAt: i * 1000);
      }

      WatchHistoryBatchReporter.maxBatchSize = 20;
      await reporter.flush();

      final captured = verify(
        () => repository.reportWatchHistory(captureAny()),
      ).captured;
      expect(captured, hasLength(2));
      final first = captured[0] as WatchHistoryReportRequest;
      final second = captured[1] as WatchHistoryReportRequest;
      expect(first.items, hasLength(20));
      expect(second.items, hasLength(1));
      expect(reporter.pendingCountForTest(), 0);
    });

    test('failed flush merges items back into the queue', () async {
      when(
        () => repository.reportWatchHistory(any()),
      ).thenAnswer(
        (_) async => Result.failure(ApiError.network('offline')),
      );

      container = buildContainer(userId: 'u1');
      final reporter = container.read(
        watchHistoryBatchReporterProvider.notifier,
      );

      reporter.enqueue(42, watchedAt: 9000);
      await reporter.flush();

      expect(reporter.pendingCountForTest(), 1);
      verify(() => repository.reportWatchHistory(any())).called(1);
    });

    test('flush while logged out keeps pending items', () async {
      container = buildContainer();
      final reporter = container.read(
        watchHistoryBatchReporterProvider.notifier,
      );

      reporter.enqueue(7, watchedAt: 7000);
      await reporter.flush();

      expect(reporter.pendingCountForTest(), 1);
      verifyNever(() => repository.reportWatchHistory(any()));
    });
  });

  group('reportWatchHistory', () {
    test('skips invalid episode ids', () {
      when(
        () => repository.reportWatchHistory(any()),
      ).thenAnswer((_) async => Result.success(null));

      container = buildContainer(userId: 'u1');
      container.read(_reportCallerProvider.notifier).report('not-a-number');

      verifyNever(() => repository.reportWatchHistory(any()));
    });
  });
}
