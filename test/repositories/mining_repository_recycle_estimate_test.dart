import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/repositories/mining_repository.dart';

class _FakeApiClient extends StoryApiClient {
  _FakeApiClient(this.payload) : super(baseUrl: 'https://test.api/');

  final dynamic payload;
  String? lastGetPath;
  Map<String, dynamic>? lastGetQuery;

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    lastGetPath = path;
    lastGetQuery = query;
    try {
      return Result.success(decoder(payload));
    } catch (error) {
      return Result.failure(ApiError.parse(error.toString()));
    }
  }
}

void main() {
  test('requests and parses actor NFT recycle estimate', () async {
    final api = _FakeApiClient({
      'actorCollectionId': '90001',
      'tokenId': '10001',
      'assetId': '90001_10001',
      'refundUsdcAmount': '80.0',
      'refundAmountMinor': '80000000',
      'refundTrainingManual': '4',
    });
    final repository = MiningRepositoryImpl(api);
    addTearDown(repository.dispose);

    final result = await repository.getActorNftRecycleEstimate(
      nftAddress: '  nft-address  ',
    );

    expect(result.isSuccess, isTrue);
    expect(api.lastGetPath, '/api/userWallet/actorNft/recycleEstimate');
    expect(api.lastGetQuery, {'nftAddress': 'nft-address'});
    expect(result.dataOrNull?.actorCollectionId, '90001');
    expect(result.dataOrNull?.tokenId, '10001');
    expect(result.dataOrNull?.assetId, '90001_10001');
    expect(result.dataOrNull?.refundUsdcAmount, '80.0');
    expect(result.dataOrNull?.refundAmountMinor, '80000000');
    expect(result.dataOrNull?.refundTrainingManual, '4');
  });

  test('returns a parse failure when a required field is missing', () async {
    final repository = MiningRepositoryImpl(
      _FakeApiClient({
        'actorCollectionId': '90001',
        'tokenId': '10001',
        'assetId': '90001_10001',
        'refundUsdcAmount': '80.0',
        'refundAmountMinor': '80000000',
      }),
    );
    addTearDown(repository.dispose);

    final result = await repository.getActorNftRecycleEstimate(
      nftAddress: 'nft-address',
    );

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ParseError>());
  });
}
