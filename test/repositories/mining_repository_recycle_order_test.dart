import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/core/result.dart';
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
  test('creates and parses an actor NFT recycle order', () async {
    const payload =
        'actor_nft_burn|90001_10001|wallet-address|80000000|407319754190667778|1781136000';
    final api = _FakeApiClient({
      'sig': 'base64-signature',
      'expiresAt': '1781136000',
      'orderNo': '407319754190667778',
      'assetId': '90001_10001',
      'refundAmountMinor': '80000000',
      'refundUsdcAmount': '80.0',
      'refundTrainingManual': '4',
      'payload': payload,
    });
    final repository = MiningRepositoryImpl(api);
    addTearDown(repository.dispose);

    final result = await repository.createActorNftRecycleOrder(
      toAddress: '  wallet-address  ',
      nftAddress: '  nft-address  ',
    );

    expect(result.isSuccess, isTrue);
    expect(api.lastPostPath, '/api/userWallet/actorNft/recycleOrder');
    expect(api.lastPostBody, {
      'toAddress': 'wallet-address',
      'nftAddress': 'nft-address',
    });
    expect(result.dataOrNull?.sig, 'base64-signature');
    expect(result.dataOrNull?.expiresAt, '1781136000');
    expect(result.dataOrNull?.orderNo, '407319754190667778');
    expect(result.dataOrNull?.assetId, '90001_10001');
    expect(result.dataOrNull?.refundAmountMinor, '80000000');
    expect(result.dataOrNull?.refundUsdcAmount, '80.0');
    expect(result.dataOrNull?.refundTrainingManual, '4');
    expect(result.dataOrNull?.payload, payload);
  });

  test('returns a parse failure when a required field is missing', () async {
    final repository = MiningRepositoryImpl(
      _FakeApiClient({
        'sig': 'base64-signature',
        'expiresAt': '1781136000',
        'orderNo': '407319754190667778',
        'assetId': '90001_10001',
        'refundAmountMinor': '80000000',
        'refundUsdcAmount': '80.0',
        'refundTrainingManual': '4',
      }),
    );
    addTearDown(repository.dispose);

    final result = await repository.createActorNftRecycleOrder(
      toAddress: 'wallet-address',
      nftAddress: 'nft-address',
    );

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ParseError>());
  });
}
