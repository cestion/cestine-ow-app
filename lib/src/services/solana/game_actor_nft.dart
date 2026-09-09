import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../core/result.dart';
import '../../model/actor_collection_model.dart';
import '../../model/actor_nft_mint_digest_model.dart';

/// 演员 NFT 链上 assetId：`{collection_asset_id}_{mint_index}`。
String buildActorAssetId(Object collectionId, Object tokenId) =>
    '${collectionId}_$tokenId';

String? _readSnowflakeId(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

/// 与 web `resolveActorCollectionAssetId` 对齐。
Result<String> resolveActorCollectionAssetId({
  required ActorNftMintDigest digest,
  ActorCollection? actor,
  String? collectionAssetId,
}) {
  final digestActorCollectionId = _readSnowflakeId(digest.actorCollectionId);
  if (digestActorCollectionId != null) {
    return Result.success(digestActorCollectionId);
  }

  final explicit = collectionAssetId?.trim();
  if (explicit != null && explicit.isNotEmpty) {
    return Result.success(explicit);
  }

  final actorCollectionId = _readSnowflakeId(actor?.id);
  if (actorCollectionId != null) {
    return Result.success(actorCollectionId);
  }

  final digestAssetId = digest.assetId?.trim();
  if (digestAssetId != null && digestAssetId.isNotEmpty) {
    return Result.success(digestAssetId);
  }

  final actorAssetId = actor?.assetId?.trim();
  if (actorAssetId != null && actorAssetId.isNotEmpty) {
    return Result.success(actorAssetId);
  }

  return Result.failure(
    ApiError.business(-1, 'Actor collection assetId is missing, please refresh'),
  );
}

/// 从 actorNftId 提取 collection assetId；无法解析时回退 actorCollectionId。
String? resolveCollectionAssetIdFromActorNftId(
  String actorNftId,
  Object? actorCollectionId,
) {
  final trimmed = actorNftId.trim().replaceFirst(RegExp(r'^#'), '');
  final underscoreIndex = trimmed.lastIndexOf('_');
  if (underscoreIndex > 0) {
    return trimmed.substring(0, underscoreIndex);
  }
  if (actorCollectionId != null) {
    return actorCollectionId.toString();
  }
  return null;
}

/// 主 NFT 链上 assetId：优先完整 actorNftId，否则回退拼装。
String? resolveMainActorAssetId({
  String? actorNftId,
  Object? actorCollectionId,
  int? actorTokenId,
}) {
  final trimmedNftId = actorNftId?.trim().replaceFirst(RegExp(r'^#'), '');
  if (trimmedNftId != null && trimmedNftId.contains('_')) {
    return trimmedNftId;
  }

  final collectionAssetId = resolveCollectionAssetIdFromActorNftId(
    trimmedNftId ?? '',
    actorCollectionId,
  );
  if (collectionAssetId == null || actorTokenId == null) {
    return null;
  }
  return buildActorAssetId(collectionAssetId, actorTokenId);
}

/// 补充体力订单 hash：SHA-256(UTF-8 orderNo)，32 字节。
Uint8List resolveRefillOrderHash(String orderNo) {
  final digest = sha256.convert(utf8.encode(orderNo.trim()));
  return Uint8List.fromList(digest.bytes);
}
