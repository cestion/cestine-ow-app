import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/actor_collection_model.dart';
import 'package:story_app/src/model/actor_nft_mint_digest_model.dart';
import 'package:story_app/src/services/solana/game_actor_nft.dart';

void main() {
  group('resolveActorCollectionAssetId', () {
    test('prefers digest.actorCollectionId', () {
      const digest = ActorNftMintDigest(actorCollectionId: 434533515028041728);
      const actor = ActorCollection(id: '999', assetId: 'asset');

      final result = resolveActorCollectionAssetId(
        digest: digest,
        actor: actor,
        collectionAssetId: '111',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, '434533515028041728');
    });

    test('falls back to explicit collectionAssetId', () {
      const digest = ActorNftMintDigest();
      final result = resolveActorCollectionAssetId(
        digest: digest,
        collectionAssetId: '222',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, '222');
    });

    test('returns failure when all sources empty', () {
      const digest = ActorNftMintDigest();
      final result = resolveActorCollectionAssetId(digest: digest);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ApiError>());
    });
  });
}
