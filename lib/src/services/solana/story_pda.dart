import 'dart:convert';

import 'package:solana/solana.dart';

/// Story program PDA 派生，与 web Codama 生成代码对齐。
class StoryPda {
  StoryPda._();

  static const _configSeed = 'config';
  static const _collectionInfoSeed = 'collection_info';
  static const _collectionMintSeed = 'collection_mint';
  static const _actorMintSeed = 'actor_mint';
  static const _dramaMintSeed = 'drama_mint';
  static const _refillRecordSeed = 'actor_stamina_refill';

  static Future<Ed25519HDPublicKey> findConfigPda({
    required Ed25519HDPublicKey programId,
  }) => Ed25519HDPublicKey.findProgramAddress(
    seeds: [utf8.encode(_configSeed)],
    programId: programId,
  );

  static Future<Ed25519HDPublicKey> findCollectionInfoPda({
    required Ed25519HDPublicKey programId,
    required String collectionAssetId,
  }) => Ed25519HDPublicKey.findProgramAddress(
    seeds: [utf8.encode(_collectionInfoSeed), utf8.encode(collectionAssetId)],
    programId: programId,
  );

  static Future<Ed25519HDPublicKey> findCollectionMintPda({
    required Ed25519HDPublicKey programId,
    required String collectionAssetId,
  }) => Ed25519HDPublicKey.findProgramAddress(
    seeds: [utf8.encode(_collectionMintSeed), utf8.encode(collectionAssetId)],
    programId: programId,
  );

  static Future<Ed25519HDPublicKey> findActorMintAssetPda({
    required Ed25519HDPublicKey programId,
    required String assetId,
  }) => Ed25519HDPublicKey.findProgramAddress(
    seeds: [utf8.encode(_actorMintSeed), utf8.encode(assetId)],
    programId: programId,
  );

  /// Drama Core asset PDA — 与 web Codama `findAssetPda` 对齐：
  /// seeds = ['drama_mint', dramaId(u64 LE 8 bytes)]，防止同一部剧重复铸造。
  static Future<Ed25519HDPublicKey> findDramaAssetPda({
    required Ed25519HDPublicKey programId,
    required List<int> dramaIdLeBytes,
  }) => Ed25519HDPublicKey.findProgramAddress(
    seeds: [utf8.encode(_dramaMintSeed), dramaIdLeBytes],
    programId: programId,
  );

  static Future<Ed25519HDPublicKey> findRefillRecordPda({
    required Ed25519HDPublicKey programId,
    required List<int> orderHash,
  }) => Ed25519HDPublicKey.findProgramAddress(
    seeds: [utf8.encode(_refillRecordSeed), orderHash],
    programId: programId,
  );
}
