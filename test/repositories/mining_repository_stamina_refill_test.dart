import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/repositories/mining_repository.dart';

class _FakeApiClient extends StoryApiClient {
  _FakeApiClient(this.payload) : super(baseUrl: 'https://test.api/');

  final dynamic payload;
  String? lastPostPath;
  dynamic lastPostBody;

  @override
  Future<Result<T>> safePost<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
    bool retry = false,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    try {
      return Result.success(decoder(payload));
    } catch (error) {
      return Result.failure(ApiError.parse(error.toString()));
    }
  }
}

void main() {
  group('centralized stamina-pack refill', () {
    test('single refill posts only the composite actor NFT id', () async {
      final api = _FakeApiClient({
        'actorNftId': '90001_10001',
        'beforeStamina': 120,
        'afterStamina': 168,
      });
      final repository = MiningRepositoryImpl(api);
      addTearDown(repository.dispose);

      final result = await repository.replenishStaminaWithPack(
        actorNftId: ' 90001_10001 ',
      );

      expect(result.isSuccess, isTrue);
      expect(api.lastPostPath, '/api/mining/replenishStamina');
      expect(api.lastPostBody, {'actorNftId': '90001_10001'});
      expect(
        result.dataOrNull,
        const StaminaRefillResult(
          actorNftId: '90001_10001',
          beforeStamina: 120,
          afterStamina: 168,
        ),
      );
    });

    test('single refill requires all documented result fields', () async {
      final repository = MiningRepositoryImpl(
        _FakeApiClient({'actorNftId': '90001_10001', 'beforeStamina': 120}),
      );
      addTearDown(repository.dispose);

      final result = await repository.replenishStaminaWithPack(
        actorNftId: '90001_10001',
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ParseError>());
    });

    test('single refill rejects a mismatched response actor id', () async {
      final repository = MiningRepositoryImpl(
        _FakeApiClient({
          'actorNftId': '90001_99999',
          'beforeStamina': 120,
          'afterStamina': 168,
        }),
      );
      addTearDown(repository.dispose);

      final result = await repository.replenishStaminaWithPack(
        actorNftId: '90001_10001',
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ParseError>());
    });

    test('batch refill posts actor ids without payment fields', () async {
      final api = _FakeApiClient({
        'items': [
          {
            'actorNftId': '90001_10001',
            'beforeStamina': '120',
            'afterStamina': '168',
          },
          {
            'actorNftId': '90001_10002',
            'beforeStamina': 0,
            'afterStamina': 168,
          },
        ],
      });
      final repository = MiningRepositoryImpl(api);
      addTearDown(repository.dispose);

      final result = await repository.replenishStaminaBatchWithPack(
        const StaminaRefillBatchRequest(
          items: [
            StaminaRefillBatchItem(actorNftId: '90001_10001'),
            StaminaRefillBatchItem(actorNftId: '90001_10002'),
          ],
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(api.lastPostPath, '/api/mining/replenishStaminaBatch');
      expect(api.lastPostBody, {
        'items': [
          {'actorNftId': '90001_10001'},
          {'actorNftId': '90001_10002'},
        ],
      });
      expect(result.dataOrNull?.items, const [
        StaminaRefillResult(
          actorNftId: '90001_10001',
          beforeStamina: 120,
          afterStamina: 168,
        ),
        StaminaRefillResult(
          actorNftId: '90001_10002',
          beforeStamina: 0,
          afterStamina: 168,
        ),
      ]);
    });

    test('batch refill can omit items so the backend selects all', () async {
      final api = _FakeApiClient(<String, dynamic>{});
      final repository = MiningRepositoryImpl(api);
      addTearDown(repository.dispose);

      final result = await repository.replenishStaminaBatchWithPack(
        const StaminaRefillBatchRequest(),
      );

      expect(result.isSuccess, isTrue);
      expect(api.lastPostBody, isEmpty);
      expect(result.dataOrNull?.items, isNull);
    });

    test('batch refill preserves an explicit empty items list', () async {
      final api = _FakeApiClient({'items': <Object>[]});
      final repository = MiningRepositoryImpl(api);
      addTearDown(repository.dispose);

      final result = await repository.replenishStaminaBatchWithPack(
        const StaminaRefillBatchRequest(items: []),
      );

      expect(result.isSuccess, isTrue);
      expect(api.lastPostBody, {'items': <Object>[]});
      expect(result.dataOrNull?.items, isEmpty);
    });
  });
}
