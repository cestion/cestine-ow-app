import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/repositories/config_repository.dart';

class MockBox extends Mock implements Box<dynamic> {}

class _FakeApiClient extends StoryApiClient {
  _FakeApiClient() : super(baseUrl: 'https://test.api/');

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    if (path.startsWith('/api/admin/v1/configs/keys/')) {
      final data = decoder({
        'chainlinks': {
          'solana_devnet': {
            'chainId': 901,
            'name': 'Solana Devnet',
            'chainType': 'svm',
            'contracts': {'spender': '11111111111111111111111111111111'},
            'rpc': {'http': 'https://api.devnet.solana.com'},
            'tokens': {
              'USDC': {
                'address': 'Gh9ZwEmdLJ8DscKNTkTqPbNwLNNiXG92spnLxT8gRTgG',
                'symbol': 'USDC',
                'decimals': 6,
              },
            },
          },
        },
        'init': {
          'withdraw': [
            {
              'chain': 'Solana Devnet',
              'tokens': [
                {'fee': '0.1', 'min': '10', 'max': '10000', 'symbol': 'USDC'},
              ],
            },
          ],
          'deposit': [
            {
              'api': 'https://sponsor.test.url/relay',
              'chain': 'Solana Devnet',
              'chainType': 'svm',
            },
          ],
        },
      });
      return Result<T>.success(data);
    }
    return Result<T>.failure(ApiError.network('unexpected call: $path'));
  }
}

class _FailingApiClient extends StoryApiClient {
  _FailingApiClient() : super(baseUrl: 'https://test.api/');

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    return Result<T>.failure(ApiError.network('connection refused'));
  }
}

class _MiniDramaFakeApiClient extends StoryApiClient {
  _MiniDramaFakeApiClient() : super(baseUrl: 'https://test.api/');

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    final data = decoder({
      'mini-drama': {
        'rebate_tiers': [
          {
            'end_episode': 5,
            'start_episode': 0,
            'direct_inviter_rate': 0.2,
            'indirect_inviter_rate': 0.05,
          },
          {
            'end_episode': 10,
            'start_episode': 6,
            'direct_inviter_rate': 0.25,
            'indirect_inviter_rate': 0.1,
          },
          {
            'end_episode': 20,
            'start_episode': 11,
            'direct_inviter_rate': 0.3,
            'indirect_inviter_rate': 0.15,
          },
          {
            'end_episode': 30,
            'start_episode': 21,
            'direct_inviter_rate': 0.35,
            'indirect_inviter_rate': 0.2,
          },
          {
            'end_episode': null,
            'start_episode': 31,
            'direct_inviter_rate': 0.4,
            'indirect_inviter_rate': 0.25,
          },
        ],
        'creator_rate_max': 0.25,
        'usdt_to_points_rate': 100,
        'default_creator_rate': 0.05,
        'self_reward_usdt_rate': 0.1,
        'point_cost_per_episode': 100,
        'bulk_unlock_discount_rate': 0.8,
      },
    });
    return Result<T>.success(data);
  }
}

late MockBox _mockBox;

void main() {
  setUp(() {
    _mockBox = MockBox();
    when(() => _mockBox.get(any<String>())).thenReturn(null);
    when(
      () => _mockBox.put(any<String>(), any<dynamic>()),
    ).thenAnswer((_) async {});
  });

  group('ConfigRepositoryImpl', () {
    test('getGlobalConfig parses chainlinks map and init section', () async {
      final repo = ConfigRepositoryImpl(
        _FakeApiClient(),
        _mockBox,
        apiBaseUrl: 'https://test.api',
      );
      final result = await repo.getGlobalConfig();
      expect(result.isSuccess, true);

      final config = result.dataOrNull;
      expect(config, isNotNull);

      // Verify chainlinks
      expect(config!.chainlinks, isNotNull);
      expect(config.chainlinks!.length, 1);
      final svmChain = config.chainlinks!['solana_devnet'];
      expect(svmChain, isNotNull);
      expect(svmChain!.chainType, 'svm');
      expect(svmChain.rpc?.http, 'https://api.devnet.solana.com');
      expect(svmChain.contracts?.spender, '11111111111111111111111111111111');

      // Verify tokens
      final usdcToken = svmChain.tokens?['USDC'];
      expect(usdcToken, isNotNull);
      expect(usdcToken!.symbol, 'USDC');
      expect(usdcToken.decimals, 6);

      // Verify init.withdraw
      expect(config.init, isNotNull);
      expect(config.init!.withdraw, isNotNull);
      expect(config.init!.withdraw!.length, 1);
      final withdrawCfg = config.init!.withdraw!.first;
      expect(withdrawCfg.chain, 'Solana Devnet');

      final tokenCfg = withdrawCfg.tokens!.first;
      expect(tokenCfg.fee, '0.1');
      expect(tokenCfg.min, '10');
      expect(tokenCfg.max, '10000');
      expect(tokenCfg.symbol, 'USDC');

      // Verify init.deposit
      expect(config.init!.deposit, isNotNull);
      expect(config.init!.deposit!.length, 1);
      final depositCfg = config.init!.deposit!.first;
      expect(depositCfg.api, 'https://sponsor.test.url/relay');
      expect(depositCfg.chain, 'Solana Devnet');
    });

    test('getGlobalConfig parses mini-drama rebate tiers', () async {
      final repo = ConfigRepositoryImpl(
        _MiniDramaFakeApiClient(),
        _mockBox,
        apiBaseUrl: 'https://test.api',
      );
      final result = await repo.getGlobalConfig();
      expect(result.isSuccess, true);

      final miniDrama = result.dataOrNull!.miniDrama;
      expect(miniDrama, isNotNull);
      expect(miniDrama!.rebateTiers!.length, 5);
      expect(miniDrama.rebateTiers!.last.isOpenEnded, isTrue);
      expect(miniDrama.rebateTiers!.first.directInviterRate, 0.2);
      expect(miniDrama.creatorRateMax, 0.25);
      expect(miniDrama.usdtToPointsRate, 100);
      expect(miniDrama.pointCostPerEpisode, 100);
      expect(miniDrama.defaultCreatorRate, 0.05);
      expect(miniDrama.selfRewardUsdtRate, 0.1);
      expect(miniDrama.bulkUnlockDiscountRate, 0.8);
    });

    test('getGlobalConfig returns failure on network error', () async {
      final repo = ConfigRepositoryImpl(
        _FailingApiClient(),
        _mockBox,
        apiBaseUrl: 'https://test.api',
      );
      final result = await repo.getGlobalConfig();
      expect(result.isFailure, true);
    });

    test('getGlobalConfig falls back to Hive when network fails', () async {
      when(() => _mockBox.get(any<String>())).thenReturn(
        jsonEncode({
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
          'apiBaseUrl': 'https://test.api',
          'data': {
            'chainlinks': {
              'solana': {
                'chainId': 1,
                'name': 'Solana',
                'chainType': 'svm',
                'rpc': {'http': 'https://cached.rpc.example'},
              },
            },
          },
        }),
      );
      when(() => _mockBox.delete(any<String>())).thenAnswer((_) async {});

      final repo = ConfigRepositoryImpl(
        _FailingApiClient(),
        _mockBox,
        apiBaseUrl: 'https://test.api',
      );
      final result = await repo.getGlobalConfig();
      expect(result.isSuccess, true);
      expect(
        result.dataOrNull!.chainlinks!['solana']!.rpc?.http,
        'https://cached.rpc.example',
      );
    });

    test(
      'getGlobalConfig ignores Hive cache from a different apiBaseUrl',
      () async {
        when(() => _mockBox.get(any<String>())).thenReturn(
          jsonEncode({
            'cachedAt': DateTime.now().millisecondsSinceEpoch,
            'apiBaseUrl': 'https://test-api-gateway.actqa.com',
            'data': {
              'chainlinks': {
                'solana': {
                  'chainId': 1,
                  'name': 'Solana',
                  'chainType': 'svm',
                  'rpc': {'http': 'https://old-env.rpc.example'},
                },
              },
            },
          }),
        );
        when(() => _mockBox.delete(any<String>())).thenAnswer((_) async {});

        final repo = ConfigRepositoryImpl(
          _FailingApiClient(),
          _mockBox,
          apiBaseUrl: 'https://api-gateway.story.fun',
        );
        final result = await repo.getGlobalConfig();
        expect(result.isFailure, true);
        verify(() => _mockBox.delete('config_global_v4')).called(1);
      },
    );

    test('getGlobalConfig persists mini-drama to Hive for next boot', () async {
      // First call: network returns mini-drama, repo should persist it.
      final repo = ConfigRepositoryImpl(
        _MiniDramaFakeApiClient(),
        _mockBox,
        apiBaseUrl: 'https://test.api',
      );
      final first = await repo.getGlobalConfig();
      expect(first.isSuccess, true);
      expect(first.dataOrNull!.miniDrama, isNotNull);

      final captured =
          verify(
                () => _mockBox.put('config_global_v4', captureAny<dynamic>()),
              ).captured.single
              as String;

      // Second call: a different repo backed by failing network + Hive
      // snapshot from the first must rehydrate mini-drama with no loss.
      final cachedRepo = ConfigRepositoryImpl(
        _FailingApiClient(),
        _mockBox,
        apiBaseUrl: 'https://test.api',
      );
      when(() => _mockBox.get('config_global_v4')).thenReturn(captured);
      when(() => _mockBox.delete(any<String>())).thenAnswer((_) async {});

      final cachedResult = await cachedRepo.getGlobalConfig();
      expect(cachedResult.isSuccess, true);
      final again = cachedResult.dataOrNull!.miniDrama;
      expect(again, isNotNull);
      expect(again!.rebateTiers!.length, 5);
      expect(again.rebateTiers!.last.isOpenEnded, isTrue);
      expect(again.creatorRateMax, 0.25);
      expect(again.usdtToPointsRate, 100);
      expect(again.bulkUnlockDiscountRate, 0.8);
    });
  });
}
