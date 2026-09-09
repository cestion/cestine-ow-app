import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/repositories/reward_repository.dart';

/// Simulates StoryApiClient envelope handling: safeGet strips envelope
/// and passes inner `data` to decoder.
class _FakeApiClient extends StoryApiClient {
  _FakeApiClient() : super(baseUrl: 'https://test.api/');

  int safeGetCallCount = 0;
  String? lastGetPath;

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    safeGetCallCount++;
    lastGetPath = path;

    if (path == '/api/userWallet/withdraw/ORD123456') {
      final data = decoder({
        'orderNo': 'ORD123456',
        'status': '2',
        'txHash': '5KtPn1LukWbH8M3Yj2CLPtUXm9Ky4XJAMJDnHtkxQnQy',
      });
      return Result<T>.success(data);
    }
    if (path == '/api/userWallet/withdraw/ORD999999') {
      final data = decoder({'orderNo': 'ORD999999', 'status': '1'});
      return Result<T>.success(data);
    }
    return Result<T>.failure(ApiError.network('unexpected call: $path'));
  }

  @override
  Future<Result<T>> safePost<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
    bool retry = false,
  }) async {
    if (path == '/api/userWallet/withdraw') {
      final data = decoder({'orderNo': 'ORD123456'});
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

  @override
  Future<Result<T>> safePost<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
    bool retry = false,
  }) async {
    return Result<T>.failure(ApiError.network('connection refused'));
  }
}

void main() {
  group('RewardRepositoryImpl', () {
    late _FakeApiClient apiClient;
    late RewardRepositoryImpl repo;

    setUp(() {
      apiClient = _FakeApiClient();
      repo = RewardRepositoryImpl(apiClient);
    });

    group('getWithdrawOrder', () {
      test('returns order detail on success', () async {
        final result = await repo.getWithdrawOrder('ORD123456');

        expect(result.isSuccess, true);
        final detail = result.dataOrNull;
        expect(detail, isNotNull);
        expect(detail!.orderNo, 'ORD123456');
        expect(detail.status, '2');
        expect(detail.txHash, '5KtPn1LukWbH8M3Yj2CLPtUXm9Ky4XJAMJDnHtkxQnQy');
      });

      test('handles in-progress status', () async {
        final result = await repo.getWithdrawOrder('ORD999999');

        expect(result.isSuccess, true);
        final detail = result.dataOrNull;
        expect(detail, isNotNull);
        expect(detail!.orderNo, 'ORD999999');
        expect(detail.status, '1');
        expect(detail.txHash, isNull);
      });

      test('calls correct endpoint with order number', () async {
        await repo.getWithdrawOrder('ORD999999');
        expect(apiClient.lastGetPath, '/api/userWallet/withdraw/ORD999999');
        expect(apiClient.safeGetCallCount, 1);
      });

      test('returns failure on API error', () async {
        final failingRepo = RewardRepositoryImpl(_FailingApiClient());
        final result = await failingRepo.getWithdrawOrder('ORD000000');
        expect(result.isFailure, true);
      });
    });

    group('claim', () {
      test('returns WithdrawCreateResponse with orderNo', () async {
        final result = await repo.claim(
          assetCode: 'USDC',
          amount: 100.0,
          toAddress: 'FakeAddress123',
        );

        expect(result.isSuccess, true);
        final response = result.dataOrNull;
        expect(response, isNotNull);
        expect(response!.orderNo, 'ORD123456');
      });

      test('returns failure on API error', () async {
        final failingRepo = RewardRepositoryImpl(_FailingApiClient());
        final result = await failingRepo.claim(
          assetCode: 'USDC',
          amount: 100.0,
          toAddress: 'FakeAddress123',
        );
        expect(result.isFailure, true);
      });
    });
  });
}
