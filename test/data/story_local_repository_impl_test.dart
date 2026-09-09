import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/core/cache_strategy.dart';
import 'package:story_app/src/data/repository/story_local_repository.dart';
import 'package:story_app/src/data/repository/story_local_repository_impl.dart';
import 'package:story_app/src/model/models.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late Directory tempDir;
  late StoryLocalRepositoryImpl repo;
  late _MockSecureStorage mockStorage;

  const user = UserProfile(
    id: 'profile-1',
    userId: 'user-1',
    nickname: 'Tester',
    email: 'tester@example.com',
  );

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'story_app_local_repo_test_',
    );
    Hive.init(tempDir.path);
  });

  setUp(() async {
    mockStorage = _MockSecureStorage();
    when(
      () => mockStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(
      () => mockStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    repo = StoryLocalRepositoryImpl(secureStorage: mockStorage);
    await repo.init();
    await repo.cacheBox.clear();
  });

  tearDown(() async {
    await repo.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('StoryLocalRepositoryImpl', () {
    test('token sync getter is intentionally unavailable in unit tests', () {
      // FlutterSecureStorage uses platform channels; this unit test suite covers
      // Hive-backed methods and asserts the sync token API remains a safe null.
      expect(repo.getToken(), isNull);
      expect(repo.getSolanaWalletAddress(), isNull);
      expect(repo.getEthereumWalletAddress(), isNull);
    });

    test('saves, reads, and clears user profile', () async {
      await repo.saveUser(user);

      expect(repo.getUser(), user);

      await repo.clearUser();
      expect(repo.getUser(), isNull);
    });

    test('watchlist add, remove, toggle, and isFavorite roundtrip', () async {
      await repo.addToWatchlist('drama-1');
      await repo.addToWatchlist('drama-1');
      await repo.addToWatchlist('drama-2');

      expect(repo.getWatchlist(), ['drama-1', 'drama-2']);
      expect(repo.isFavorite('drama-1'), isTrue);

      await repo.removeFromWatchlist('drama-1');
      expect(repo.getWatchlist(), ['drama-2']);
      expect(repo.isFavorite('drama-1'), isFalse);

      expect(await repo.toggleWatchlist('drama-3'), isTrue);
      expect(repo.isFavorite('drama-3'), isTrue);
      expect(await repo.toggleWatchlist('drama-3'), isFalse);
      expect(repo.isFavorite('drama-3'), isFalse);
    });

    test(
      'search history deduplicates, keeps newest first, and caps at 10',
      () async {
        for (var index = 0; index < 12; index++) {
          await repo.addSearchHistory('keyword-$index');
        }
        await repo.addSearchHistory('keyword-5');

        final history = repo.getSearchHistory();

        expect(history, hasLength(10));
        expect(history.first, 'keyword-5');
        expect(
          history.where((String item) => item == 'keyword-5'),
          hasLength(1),
        );
        expect(history, isNot(contains('keyword-0')));
        expect(history, isNot(contains('keyword-1')));

        await repo.removeSearchHistory('keyword-5');
        expect(repo.getSearchHistory(), isNot(contains('keyword-5')));

        await repo.clearSearchHistory();
        expect(repo.getSearchHistory(), isEmpty);
      },
    );

    test('watch progress save, read, and clear by episode', () async {
      await repo.saveWatchProgress('drama-1', 1, 12345);
      await repo.saveWatchProgress('drama-1', 2, 23456);

      expect(repo.getWatchProgress('drama-1', 1), 12345);
      expect(repo.getWatchProgress('drama-1', 2), 23456);
      expect(repo.getWatchProgress('drama-2', 1), 0);

      await repo.clearWatchProgress('drama-1', 1);
      expect(repo.getWatchProgress('drama-1', 1), 0);
      expect(repo.getWatchProgress('drama-1', 2), 23456);
    });

    test('locale save and read roundtrip', () async {
      const locale = LocaleInfo(languageCode: 'en', countryCode: 'US');

      await repo.setLocale(locale);

      expect(repo.getLocale(), locale);
    });

    test(
      'Hive cache box supports put/get roundtrip through cache layer',
      () async {
        final cache = HiveCacheLayer<DramaPlayResponse>(
          box: repo.cacheBox,
          prefix: 'episode_play_',
          decoder: (Object? data) {
            if (data is Map<String, dynamic>) {
              return DramaPlayResponse.fromJson(data);
            }
            if (data is Map) {
              return DramaPlayResponse.fromJson(
                Map<String, dynamic>.from(data),
              );
            }
            throw const FormatException('Expected map');
          },
          encoder: (DramaPlayResponse value) => value.toJson(),
        );
        const play = DramaPlayResponse(
          dramaId: 'drama-1',
          episodeId: 'episode-1',
          episodeNo: 1,
          mediaAccessUrl: 'https://cdn.example.com/episode-1.m3u8',
        );

        await cache.set('drama-1_1', play);

        final cached = await cache.get('drama-1_1');
        expect(cached, play);
      },
    );

    group('reconcileEnv', () {
      test('first stamp on empty box does not purge', () async {
        final purged = await repo.reconcileEnv(
          'https://test-api-gateway.actqa.com',
        );
        expect(purged, isFalse);
        expect(
          repo.cacheBox.get(StoryLocalRepositoryImpl.envStampKey),
          'https://test-api-gateway.actqa.com',
        );
      });

      test('same env does not purge', () async {
        await repo.reconcileEnv('https://test-api-gateway.actqa.com');
        await repo.saveUser(user);
        await repo.addToWatchlist('drama-1');

        final purged = await repo.reconcileEnv(
          'https://test-api-gateway.actqa.com/',
        );
        expect(purged, isFalse);
        expect(repo.getUser(), user);
        expect(repo.getWatchlist(), ['drama-1']);
      });

      test('env switch purges content but keeps locale and theme', () async {
        await repo.reconcileEnv('https://test-api-gateway.actqa.com');
        await repo.saveUser(user);
        await repo.addToWatchlist('drama-1');
        await repo.saveWatchProgress('drama-1', 1, 1000);
        await repo.addSearchHistory('old query');
        await repo.setLocale(
          const LocaleInfo(languageCode: 'en', countryCode: 'US'),
        );
        await repo.setThemeMode('dark');
        await repo.cacheBox.put('drama_list_public_first', {
          'data': <String, dynamic>{},
          'expiresAt': DateTime.now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        });
        await repo.cacheBox.put('wallet_balance_usdc', 12.5);

        final purged = await repo.reconcileEnv('https://api-gateway.story.fun');
        expect(purged, isTrue);
        expect(repo.getUser(), isNull);
        expect(repo.getWatchlist(), isEmpty);
        expect(repo.getWatchProgress('drama-1', 1), 0);
        expect(repo.getSearchHistory(), isEmpty);
        expect(repo.cacheBox.get('drama_list_public_first'), isNull);
        expect(repo.cacheBox.get('wallet_balance_usdc'), isNull);
        expect(
          repo.getLocale(),
          const LocaleInfo(languageCode: 'en', countryCode: 'US'),
        );
        expect(repo.getThemeMode(), 'dark');
        expect(
          repo.cacheBox.get(StoryLocalRepositoryImpl.envStampKey),
          'https://api-gateway.story.fun',
        );
        verify(() => mockStorage.delete(key: 'userToken')).called(1);
        verify(
          () => mockStorage.delete(key: 'solana_wallet_address'),
        ).called(1);
        verify(() => mockStorage.delete(key: 'evm_wallet_address')).called(1);
        verify(() => mockStorage.delete(key: 'device_id')).called(1);
      });

      test('legacy data without stamp is purged once', () async {
        await repo.saveUser(user);
        await repo.setLocale(const LocaleInfo(languageCode: 'zh'));

        final purged = await repo.reconcileEnv('https://api-gateway.story.fun');
        expect(purged, isTrue);
        expect(repo.getUser(), isNull);
        expect(repo.getLocale()?.languageCode, 'zh');
      });
    });

    group('reconcileSandboxInstall', () {
      test('empty sandbox clears secure leftovers and stamps marker', () async {
        expect(repo.cacheBox.isEmpty, isTrue);

        final cleared = await repo.reconcileSandboxInstall();
        expect(cleared, isTrue);
        expect(
          repo.cacheBox.get(StoryLocalRepositoryImpl.sandboxInstallMarkerKey),
          1,
        );
        verify(() => mockStorage.delete(key: 'userToken')).called(1);
        verify(
          () => mockStorage.delete(key: 'solana_wallet_address'),
        ).called(1);
        verify(() => mockStorage.delete(key: 'evm_wallet_address')).called(1);
        verify(() => mockStorage.delete(key: 'device_id')).called(1);

        clearInteractions(mockStorage);
        final again = await repo.reconcileSandboxInstall();
        expect(again, isFalse);
        verifyNever(() => mockStorage.delete(key: any(named: 'key')));
      });

      test('existing sandbox only stamps marker (app update path)', () async {
        await repo.saveUser(user);

        final cleared = await repo.reconcileSandboxInstall();
        expect(cleared, isFalse);
        expect(repo.getUser(), user);
        expect(
          repo.cacheBox.get(StoryLocalRepositoryImpl.sandboxInstallMarkerKey),
          1,
        );
        verifyNever(() => mockStorage.delete(key: any(named: 'key')));
      });
    });

    test('purgeApiCache drops regenerable keys and keeps user data', () async {
      await repo.setLocale(
        const LocaleInfo(languageCode: 'en', countryCode: 'US'),
      );
      await repo.setThemeMode('dark');
      await repo.addToWatchlist('drama-1');
      await repo.saveWatchProgress('drama-1', 1, 1000);
      await repo.addSearchHistory('keep me');
      await repo.cacheBox.put('drama_list_public_first', {
        'data': <String, dynamic>{},
      });
      await repo.cacheBox.put('episode_play_d1_1', {
        'data': <String, dynamic>{},
      });
      await repo.cacheBox.put('actor_public_1', {'data': <String, dynamic>{}});
      await repo.cacheBox.put('wallet_balance_usdc', 12.5);
      await repo.cacheBox.put('config_global_v4', {
        'data': <String, dynamic>{},
      });

      await repo.purgeApiCache();

      expect(repo.cacheBox.get('drama_list_public_first'), isNull);
      expect(repo.cacheBox.get('episode_play_d1_1'), isNull);
      expect(repo.cacheBox.get('actor_public_1'), isNull);
      expect(repo.cacheBox.get('wallet_balance_usdc'), isNull);
      expect(repo.cacheBox.get('config_global_v4'), isNull);
      expect(repo.isFavorite('drama-1'), isTrue);
      expect(repo.getWatchProgress('drama-1', 1), 1000);
      expect(repo.getSearchHistory(), ['keep me']);
      expect(
        repo.getLocale(),
        const LocaleInfo(languageCode: 'en', countryCode: 'US'),
      );
      expect(repo.getThemeMode(), 'dark');
    });
  });
}
