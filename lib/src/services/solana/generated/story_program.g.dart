// GENERATED CODE - DO NOT MODIFY BY HAND.
// Run: dart run tool/generate_story_contract.dart
// Source environment: development
// Contract: d7ffa721b88c30eee7446f5c69b733fef6c82f9b
// IDL SHA-256: 4cd4b7cc6f906e424a3ef501118824d524c8299e8f94c53d63c14fb129f83c26

import 'dart:convert';
import 'dart:typed_data';

import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../anchor_borsh_writer.dart';

abstract final class StoryContractMetadata {
  static const sourceEnvironment = "development";
  static const contractCommit = "d7ffa721b88c30eee7446f5c69b733fef6c82f9b";
  static const idlSha256 =
      "4cd4b7cc6f906e424a3ef501118824d524c8299e8f94c53d63c14fb129f83c26";
  static const anchorVersion = "1.0.0";
  static const idlIsPartial = false;
  static const protocolVersion = 2;
  static const instructionCount = 20;
  static const programIds = <String, String>{
    "development": "6w1itXjxKn79S6WzR3tY6nkF7rx5DDJbYkH12a7uFyTk",
    "test": "CJEnSe9eJ3s8qLQNdWrcHQpp6199s4NohcBBHZ3UeRQL",
    "production": "7vGTZBAqjk9mArEnj1bZ7aRvAkeoksAcrzB7aEtzb8g1",
  };

  static const protocolVersions = <String, int>{
    "development": 2,
    "test": 2,
    "production": 1,
  };

  static const idlSha256ByEnvironment = <String, String>{
    "development":
        "4cd4b7cc6f906e424a3ef501118824d524c8299e8f94c53d63c14fb129f83c26",
    "test": "2c664599e31572b9e685f3a72bae1a6b087d0a4490ed20670fd30e9590b2c02b",
    "production":
        "9254a15edb5e783280ad3048bfb066c6725ffc44de1ec7aa6a4430fc4f10919f",
  };

  static const compatibleProgramIds = <String>{
    "6w1itXjxKn79S6WzR3tY6nkF7rx5DDJbYkH12a7uFyTk",
    "CJEnSe9eJ3s8qLQNdWrcHQpp6199s4NohcBBHZ3UeRQL",
  };

  static bool isKnownProgramId(String value) => programIds.containsValue(value);
  static bool isAllowedProgramId(String value) =>
      compatibleProgramIds.contains(value);
}

Uint8List _encodeStoryPdaU64(BigInt value) {
  final writer = AnchorBorshWriter()..writeU64(value);
  return writer.toBytes();
}

class StorySignedParams {
  final String canonicalPayload;
  final Uint8List sig;

  const StorySignedParams({required this.canonicalPayload, required this.sig});

  void writeTo(AnchorBorshWriter writer) {
    writer.writeString(canonicalPayload);
    writer.writeFixedBytes(sig, length: 64, name: 'sig');
  }
}

class StoryCreateCollectionParams {
  final String collectionType;
  final String name;
  final String uri;

  const StoryCreateCollectionParams({
    required this.collectionType,
    required this.name,
    required this.uri,
  });

  void writeTo(AnchorBorshWriter writer) {
    writer.writeString(collectionType);
    writer.writeString(name);
    writer.writeString(uri);
  }
}

class StoryInitializeParams {
  final Ed25519HDPublicKey admin;
  final Ed25519HDPublicKey delegator;
  final Ed25519HDPublicKey treasury;

  const StoryInitializeParams({
    required this.admin,
    required this.delegator,
    required this.treasury,
  });

  void writeTo(AnchorBorshWriter writer) {
    writer.writePubkey(admin);
    writer.writePubkey(delegator);
    writer.writePubkey(treasury);
  }
}

class StoryProposeAuthorityTransferParams {
  final Ed25519HDPublicKey newAuthority;
  final int lockDurationSecs;

  const StoryProposeAuthorityTransferParams({
    required this.newAuthority,
    required this.lockDurationSecs,
  });

  void writeTo(AnchorBorshWriter writer) {
    writer.writePubkey(newAuthority);
    writer.writeU32(lockDurationSecs);
  }
}

class StoryProposeConfigUpdateParams {
  final Ed25519HDPublicKey? newAdmin;
  final Ed25519HDPublicKey? newDelegator;
  final bool? newPaused;
  final Ed25519HDPublicKey? newTreasury;
  final int lockDurationSecs;

  const StoryProposeConfigUpdateParams({
    required this.newAdmin,
    required this.newDelegator,
    required this.newPaused,
    required this.newTreasury,
    required this.lockDurationSecs,
  });

  void writeTo(AnchorBorshWriter writer) {
    if (newAdmin == null) {
      writer.writeU8(0);
    } else {
      writer.writeU8(1);
      writer.writePubkey(newAdmin!);
    }
    if (newDelegator == null) {
      writer.writeU8(0);
    } else {
      writer.writeU8(1);
      writer.writePubkey(newDelegator!);
    }
    if (newPaused == null) {
      writer.writeU8(0);
    } else {
      writer.writeU8(1);
      writer.writeBool(newPaused!);
    }
    if (newTreasury == null) {
      writer.writeU8(0);
    } else {
      writer.writeU8(1);
      writer.writePubkey(newTreasury!);
    }
    writer.writeU32(lockDurationSecs);
  }
}

class StoryUpdateConfigParams {
  final bool? paused;
  final int? newPlatformRoyaltyShare;
  final int? newActorSellerFeeBasisPoints;
  final int? newDramaSellerFeeBasisPoints;
  final int? newActorMintTreasuryBps;
  final int? newActorMintVaultBps;

  const StoryUpdateConfigParams({
    required this.paused,
    required this.newPlatformRoyaltyShare,
    required this.newActorSellerFeeBasisPoints,
    required this.newDramaSellerFeeBasisPoints,
    required this.newActorMintTreasuryBps,
    required this.newActorMintVaultBps,
  });

  void writeTo(AnchorBorshWriter writer) {
    if (paused == null) {
      writer.writeU8(0);
    } else {
      writer.writeU8(1);
      writer.writeBool(paused!);
    }
    if (newPlatformRoyaltyShare == null) {
      writer.writeU8(0);
    } else {
      writer.writeU8(1);
      writer.writeU8(newPlatformRoyaltyShare!);
    }
    if (newActorSellerFeeBasisPoints == null) {
      writer.writeU8(0);
    } else {
      writer.writeU8(1);
      writer.writeU16(newActorSellerFeeBasisPoints!);
    }
    if (newDramaSellerFeeBasisPoints == null) {
      writer.writeU8(0);
    } else {
      writer.writeU8(1);
      writer.writeU16(newDramaSellerFeeBasisPoints!);
    }
    if (newActorMintTreasuryBps == null) {
      writer.writeU8(0);
    } else {
      writer.writeU8(1);
      writer.writeU16(newActorMintTreasuryBps!);
    }
    if (newActorMintVaultBps == null) {
      writer.writeU8(0);
    } else {
      writer.writeU8(1);
      writer.writeU16(newActorMintVaultBps!);
    }
  }
}

const acceptAuthorityTransferInstructionDiscriminator = <int>[
  239,
  248,
  177,
  2,
  206,
  97,
  46,
  255,
];

class AcceptAuthorityTransferAccounts {
  final Ed25519HDPublicKey newAuthority;
  final Ed25519HDPublicKey config;

  const AcceptAuthorityTransferAccounts({
    required this.newAuthority,
    required this.config,
  });
}

Uint8List encodeAcceptAuthorityTransferInstructionData() {
  final writer = AnchorBorshWriter()
    ..writeBytes(acceptAuthorityTransferInstructionDiscriminator);
  return writer.toBytes();
}

Instruction buildAcceptAuthorityTransferInstruction({
  required Ed25519HDPublicKey programId,
  required AcceptAuthorityTransferAccounts accounts,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.newAuthority, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.config, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(encodeAcceptAuthorityTransferInstructionData()),
  );
}

Future<Ed25519HDPublicKey> findAcceptAuthorityTransferConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

const batchMintActorNftInstructionDiscriminator = <int>[
  88,
  201,
  32,
  83,
  171,
  30,
  229,
  71,
];

class BatchMintActorNftAccounts {
  final Ed25519HDPublicKey creator;
  final Ed25519HDPublicKey sponor;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey collectionInfo;
  final Ed25519HDPublicKey collectionMint;
  final Ed25519HDPublicKey payTokenMint;
  final Ed25519HDPublicKey creatorPayAccount;
  final Ed25519HDPublicKey treasury;
  final Ed25519HDPublicKey vault;
  final Ed25519HDPublicKey instructions;
  final Ed25519HDPublicKey mplCoreProgram;
  final Ed25519HDPublicKey systemProgram;
  final Ed25519HDPublicKey tokenProgram;

  const BatchMintActorNftAccounts({
    required this.creator,
    required this.sponor,
    required this.config,
    required this.collectionInfo,
    required this.collectionMint,
    required this.payTokenMint,
    required this.creatorPayAccount,
    required this.treasury,
    required this.vault,
    required this.instructions,
    required this.mplCoreProgram,
    required this.systemProgram,
    required this.tokenProgram,
  });
}

Uint8List encodeBatchMintActorNftInstructionData({
  required int mintCount,
  required StorySignedParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(batchMintActorNftInstructionDiscriminator);
  writer.writeU8(mintCount);
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildBatchMintActorNftInstruction({
  required Ed25519HDPublicKey programId,
  required BatchMintActorNftAccounts accounts,
  required int mintCount,
  required StorySignedParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.creator, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.sponor, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.config, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.collectionInfo, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.collectionMint, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.payTokenMint, isSigner: false),
      AccountMeta.writeable(
        pubKey: accounts.creatorPayAccount,
        isSigner: false,
      ),
      AccountMeta.writeable(pubKey: accounts.treasury, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.vault, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.instructions, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.mplCoreProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.tokenProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(
      encodeBatchMintActorNftInstructionData(
        mintCount: mintCount,
        params: params,
      ),
    ),
  );
}

Future<Ed25519HDPublicKey> findBatchMintActorNftConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findBatchMintActorNftCollectionInfoPda({
  required Ed25519HDPublicKey programId,
  required String collectionInfoAssetId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      99,
      111,
      108,
      108,
      101,
      99,
      116,
      105,
      111,
      110,
      95,
      105,
      110,
      102,
      111,
    ],
    utf8.encode(collectionInfoAssetId),
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findBatchMintActorNftCollectionMintPda({
  required Ed25519HDPublicKey programId,
  required String collectionInfoAssetId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      99,
      111,
      108,
      108,
      101,
      99,
      116,
      105,
      111,
      110,
      95,
      109,
      105,
      110,
      116,
    ],
    utf8.encode(collectionInfoAssetId),
  ],
  programId: programId,
);

const batchRefillActorStaminaInstructionDiscriminator = <int>[
  67,
  159,
  179,
  127,
  253,
  208,
  205,
  128,
];

class BatchRefillActorStaminaAccounts {
  final Ed25519HDPublicKey user;
  final Ed25519HDPublicKey sponor;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey payTokenMint;
  final Ed25519HDPublicKey payerPayAccount;
  final Ed25519HDPublicKey treasury;
  final Ed25519HDPublicKey refillRecord;
  final Ed25519HDPublicKey instructions;
  final Ed25519HDPublicKey systemProgram;
  final Ed25519HDPublicKey tokenProgram;

  const BatchRefillActorStaminaAccounts({
    required this.user,
    required this.sponor,
    required this.config,
    required this.payTokenMint,
    required this.payerPayAccount,
    required this.treasury,
    required this.refillRecord,
    required this.instructions,
    required this.systemProgram,
    required this.tokenProgram,
  });
}

Uint8List encodeBatchRefillActorStaminaInstructionData({
  required Uint8List orderHash,
  required StorySignedParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(batchRefillActorStaminaInstructionDiscriminator);
  writer.writeFixedBytes(orderHash, length: 32, name: 'orderHash');
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildBatchRefillActorStaminaInstruction({
  required Ed25519HDPublicKey programId,
  required BatchRefillActorStaminaAccounts accounts,
  required Uint8List orderHash,
  required StorySignedParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.user, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.sponor, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.payerPayAccount, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.treasury, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.refillRecord, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.instructions, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.tokenProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(
      encodeBatchRefillActorStaminaInstructionData(
        orderHash: orderHash,
        params: params,
      ),
    ),
  );
}

Future<Ed25519HDPublicKey> findBatchRefillActorStaminaConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findBatchRefillActorStaminaRefillRecordPda({
  required Ed25519HDPublicKey programId,
  required Uint8List orderHash,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      97,
      99,
      116,
      111,
      114,
      95,
      115,
      116,
      97,
      109,
      105,
      110,
      97,
      95,
      114,
      101,
      102,
      105,
      108,
      108,
    ],
    orderHash,
  ],
  programId: programId,
);

const burnActorNftInstructionDiscriminator = <int>[
  28,
  33,
  203,
  193,
  201,
  102,
  201,
  1,
];

class BurnActorNftAccounts {
  final Ed25519HDPublicKey user;
  final Ed25519HDPublicKey sponor;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey collectionInfo;
  final Ed25519HDPublicKey collectionMint;
  final Ed25519HDPublicKey asset;
  final Ed25519HDPublicKey payTokenMint;
  final Ed25519HDPublicKey vault;
  final Ed25519HDPublicKey refundRecipient;
  final Ed25519HDPublicKey burnRecord;
  final Ed25519HDPublicKey instructions;
  final Ed25519HDPublicKey mplCoreProgram;
  final Ed25519HDPublicKey systemProgram;
  final Ed25519HDPublicKey tokenProgram;

  const BurnActorNftAccounts({
    required this.user,
    required this.sponor,
    required this.config,
    required this.collectionInfo,
    required this.collectionMint,
    required this.asset,
    required this.payTokenMint,
    required this.vault,
    required this.refundRecipient,
    required this.burnRecord,
    required this.instructions,
    required this.mplCoreProgram,
    required this.systemProgram,
    required this.tokenProgram,
  });
}

Uint8List encodeBurnActorNftInstructionData({
  required String assetId,
  required Uint8List orderHash,
  required StorySignedParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(burnActorNftInstructionDiscriminator);
  writer.writeString(assetId);
  writer.writeFixedBytes(orderHash, length: 32, name: 'orderHash');
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildBurnActorNftInstruction({
  required Ed25519HDPublicKey programId,
  required BurnActorNftAccounts accounts,
  required String assetId,
  required Uint8List orderHash,
  required StorySignedParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.user, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.sponor, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.collectionInfo, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.collectionMint, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.asset, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.vault, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.refundRecipient, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.burnRecord, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.instructions, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.mplCoreProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.tokenProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(
      encodeBurnActorNftInstructionData(
        assetId: assetId,
        orderHash: orderHash,
        params: params,
      ),
    ),
  );
}

Future<Ed25519HDPublicKey> findBurnActorNftConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findBurnActorNftCollectionInfoPda({
  required Ed25519HDPublicKey programId,
  required String collectionInfoAssetId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      99,
      111,
      108,
      108,
      101,
      99,
      116,
      105,
      111,
      110,
      95,
      105,
      110,
      102,
      111,
    ],
    utf8.encode(collectionInfoAssetId),
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findBurnActorNftAssetPda({
  required Ed25519HDPublicKey programId,
  required String assetId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[97, 99, 116, 111, 114, 95, 109, 105, 110, 116],
    utf8.encode(assetId),
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findBurnActorNftBurnRecordPda({
  required Ed25519HDPublicKey programId,
  required Uint8List orderHash,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[97, 99, 116, 111, 114, 95, 110, 102, 116, 95, 98, 117, 114, 110],
    orderHash,
  ],
  programId: programId,
);

const cancelAuthorityTransferInstructionDiscriminator = <int>[
  94,
  131,
  125,
  184,
  183,
  24,
  125,
  229,
];

class CancelAuthorityTransferAccounts {
  final Ed25519HDPublicKey authority;
  final Ed25519HDPublicKey config;

  const CancelAuthorityTransferAccounts({
    required this.authority,
    required this.config,
  });
}

Uint8List encodeCancelAuthorityTransferInstructionData() {
  final writer = AnchorBorshWriter()
    ..writeBytes(cancelAuthorityTransferInstructionDiscriminator);
  return writer.toBytes();
}

Instruction buildCancelAuthorityTransferInstruction({
  required Ed25519HDPublicKey programId,
  required CancelAuthorityTransferAccounts accounts,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.authority, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.config, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(encodeCancelAuthorityTransferInstructionData()),
  );
}

Future<Ed25519HDPublicKey> findCancelAuthorityTransferConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

const cancelConfigUpdateInstructionDiscriminator = <int>[
  216,
  180,
  255,
  207,
  118,
  146,
  126,
  89,
];

class CancelConfigUpdateAccounts {
  final Ed25519HDPublicKey authority;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey pendingConfig;

  const CancelConfigUpdateAccounts({
    required this.authority,
    required this.config,
    required this.pendingConfig,
  });
}

Uint8List encodeCancelConfigUpdateInstructionData() {
  final writer = AnchorBorshWriter()
    ..writeBytes(cancelConfigUpdateInstructionDiscriminator);
  return writer.toBytes();
}

Instruction buildCancelConfigUpdateInstruction({
  required Ed25519HDPublicKey programId,
  required CancelConfigUpdateAccounts accounts,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.authority, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.pendingConfig, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(encodeCancelConfigUpdateInstructionData()),
  );
}

Future<Ed25519HDPublicKey> findCancelConfigUpdateConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findCancelConfigUpdatePendingConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[112, 101, 110, 100, 105, 110, 103, 95, 99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

const commitConfigUpdateInstructionDiscriminator = <int>[
  88,
  84,
  135,
  192,
  136,
  94,
  237,
  9,
];

class CommitConfigUpdateAccounts {
  final Ed25519HDPublicKey authority;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey pendingConfig;

  const CommitConfigUpdateAccounts({
    required this.authority,
    required this.config,
    required this.pendingConfig,
  });
}

Uint8List encodeCommitConfigUpdateInstructionData() {
  final writer = AnchorBorshWriter()
    ..writeBytes(commitConfigUpdateInstructionDiscriminator);
  return writer.toBytes();
}

Instruction buildCommitConfigUpdateInstruction({
  required Ed25519HDPublicKey programId,
  required CommitConfigUpdateAccounts accounts,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.authority, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.config, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.pendingConfig, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(encodeCommitConfigUpdateInstructionData()),
  );
}

Future<Ed25519HDPublicKey> findCommitConfigUpdateConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findCommitConfigUpdatePendingConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[112, 101, 110, 100, 105, 110, 103, 95, 99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

const createActorCollectionInstructionDiscriminator = <int>[
  51,
  247,
  218,
  151,
  198,
  93,
  167,
  124,
];

class CreateActorCollectionAccounts {
  final Ed25519HDPublicKey creator;
  final Ed25519HDPublicKey sponor;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey collection;
  final Ed25519HDPublicKey collectionInfo;
  final Ed25519HDPublicKey payTokenMint;
  final Ed25519HDPublicKey creatorPayAccount;
  final Ed25519HDPublicKey treasury;
  final Ed25519HDPublicKey instructions;
  final Ed25519HDPublicKey mplCoreProgram;
  final Ed25519HDPublicKey systemProgram;
  final Ed25519HDPublicKey tokenProgram;

  const CreateActorCollectionAccounts({
    required this.creator,
    required this.sponor,
    required this.config,
    required this.collection,
    required this.collectionInfo,
    required this.payTokenMint,
    required this.creatorPayAccount,
    required this.treasury,
    required this.instructions,
    required this.mplCoreProgram,
    required this.systemProgram,
    required this.tokenProgram,
  });
}

Uint8List encodeCreateActorCollectionInstructionData({
  required String assetId,
  required StorySignedParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(createActorCollectionInstructionDiscriminator);
  writer.writeString(assetId);
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildCreateActorCollectionInstruction({
  required Ed25519HDPublicKey programId,
  required CreateActorCollectionAccounts accounts,
  required String assetId,
  required StorySignedParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.creator, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.sponor, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.collection, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.collectionInfo, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.payTokenMint, isSigner: false),
      AccountMeta.writeable(
        pubKey: accounts.creatorPayAccount,
        isSigner: false,
      ),
      AccountMeta.writeable(pubKey: accounts.treasury, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.instructions, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.mplCoreProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.tokenProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(
      encodeCreateActorCollectionInstructionData(
        assetId: assetId,
        params: params,
      ),
    ),
  );
}

Future<Ed25519HDPublicKey> findCreateActorCollectionConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findCreateActorCollectionCollectionPda({
  required Ed25519HDPublicKey programId,
  required String assetId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      99,
      111,
      108,
      108,
      101,
      99,
      116,
      105,
      111,
      110,
      95,
      109,
      105,
      110,
      116,
    ],
    utf8.encode(assetId),
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findCreateActorCollectionCollectionInfoPda({
  required Ed25519HDPublicKey programId,
  required String assetId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      99,
      111,
      108,
      108,
      101,
      99,
      116,
      105,
      111,
      110,
      95,
      105,
      110,
      102,
      111,
    ],
    utf8.encode(assetId),
  ],
  programId: programId,
);

const createCollectionInstructionDiscriminator = <int>[
  156,
  251,
  92,
  54,
  233,
  2,
  16,
  82,
];

class CreateCollectionAccounts {
  final Ed25519HDPublicKey admin;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey collection;
  final Ed25519HDPublicKey collectionInfo;
  final Ed25519HDPublicKey mplCoreProgram;
  final Ed25519HDPublicKey systemProgram;

  const CreateCollectionAccounts({
    required this.admin,
    required this.config,
    required this.collection,
    required this.collectionInfo,
    required this.mplCoreProgram,
    required this.systemProgram,
  });
}

Uint8List encodeCreateCollectionInstructionData({
  required StoryCreateCollectionParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(createCollectionInstructionDiscriminator);
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildCreateCollectionInstruction({
  required Ed25519HDPublicKey programId,
  required CreateCollectionAccounts accounts,
  required StoryCreateCollectionParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.admin, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.collection, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.collectionInfo, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.mplCoreProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(encodeCreateCollectionInstructionData(params: params)),
  );
}

Future<Ed25519HDPublicKey> findCreateCollectionConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findCreateCollectionCollectionPda({
  required Ed25519HDPublicKey programId,
  required StoryCreateCollectionParams params,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      99,
      111,
      108,
      108,
      101,
      99,
      116,
      105,
      111,
      110,
      95,
      109,
      105,
      110,
      116,
    ],
    utf8.encode(params.collectionType),
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findCreateCollectionCollectionInfoPda({
  required Ed25519HDPublicKey programId,
  required StoryCreateCollectionParams params,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      99,
      111,
      108,
      108,
      101,
      99,
      116,
      105,
      111,
      110,
      95,
      105,
      110,
      102,
      111,
    ],
    utf8.encode(params.collectionType),
  ],
  programId: programId,
);

const initializeInstructionDiscriminator = <int>[
  175,
  175,
  109,
  31,
  13,
  152,
  155,
  237,
];

class InitializeAccounts {
  final Ed25519HDPublicKey authority;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey systemProgram;

  const InitializeAccounts({
    required this.authority,
    required this.config,
    required this.systemProgram,
  });
}

Uint8List encodeInitializeInstructionData({
  required StoryInitializeParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(initializeInstructionDiscriminator);
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildInitializeInstruction({
  required Ed25519HDPublicKey programId,
  required InitializeAccounts accounts,
  required StoryInitializeParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.authority, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.config, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(encodeInitializeInstructionData(params: params)),
  );
}

Future<Ed25519HDPublicKey> findInitializeConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

const initializeUsdcVaultInstructionDiscriminator = <int>[
  186,
  93,
  213,
  60,
  171,
  158,
  253,
  207,
];

class InitializeUsdcVaultAccounts {
  final Ed25519HDPublicKey authority;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey payTokenMint;
  final Ed25519HDPublicKey vault;
  final Ed25519HDPublicKey systemProgram;
  final Ed25519HDPublicKey tokenProgram;
  final Ed25519HDPublicKey associatedTokenProgram;

  const InitializeUsdcVaultAccounts({
    required this.authority,
    required this.config,
    required this.payTokenMint,
    required this.vault,
    required this.systemProgram,
    required this.tokenProgram,
    required this.associatedTokenProgram,
  });
}

Uint8List encodeInitializeUsdcVaultInstructionData() {
  final writer = AnchorBorshWriter()
    ..writeBytes(initializeUsdcVaultInstructionDiscriminator);
  return writer.toBytes();
}

Instruction buildInitializeUsdcVaultInstruction({
  required Ed25519HDPublicKey programId,
  required InitializeUsdcVaultAccounts accounts,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.authority, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.vault, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.tokenProgram, isSigner: false),
      AccountMeta.readonly(
        pubKey: accounts.associatedTokenProgram,
        isSigner: false,
      ),
      ...remainingAccounts,
    ],
    data: ByteArray(encodeInitializeUsdcVaultInstructionData()),
  );
}

Future<Ed25519HDPublicKey> findInitializeUsdcVaultConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findInitializeUsdcVaultVaultPda({
  required Ed25519HDPublicKey config,
  required Ed25519HDPublicKey payTokenMint,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    config.bytes,
    <int>[
      6,
      221,
      246,
      225,
      215,
      101,
      161,
      147,
      217,
      203,
      225,
      70,
      206,
      235,
      121,
      172,
      28,
      180,
      133,
      237,
      95,
      91,
      55,
      145,
      58,
      140,
      245,
      133,
      126,
      255,
      0,
      169,
    ],
    payTokenMint.bytes,
  ],
  programId: Ed25519HDPublicKey(
    Uint8List.fromList(<int>[
      140,
      151,
      37,
      143,
      78,
      36,
      137,
      241,
      187,
      61,
      16,
      41,
      20,
      142,
      13,
      131,
      11,
      90,
      19,
      153,
      218,
      255,
      16,
      132,
      4,
      142,
      123,
      216,
      219,
      233,
      248,
      89,
    ]),
  ),
);

const mintSeriesNftInstructionDiscriminator = <int>[
  86,
  73,
  192,
  56,
  151,
  242,
  122,
  96,
];

class MintSeriesNftAccounts {
  final Ed25519HDPublicKey creator;
  final Ed25519HDPublicKey sponor;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey asset;
  final Ed25519HDPublicKey collectionInfo;
  final Ed25519HDPublicKey collectionMint;
  final Ed25519HDPublicKey payTokenMint;
  final Ed25519HDPublicKey creatorPayAccount;
  final Ed25519HDPublicKey treasury;
  final Ed25519HDPublicKey instructions;
  final Ed25519HDPublicKey mplCoreProgram;
  final Ed25519HDPublicKey systemProgram;
  final Ed25519HDPublicKey tokenProgram;

  const MintSeriesNftAccounts({
    required this.creator,
    required this.sponor,
    required this.config,
    required this.asset,
    required this.collectionInfo,
    required this.collectionMint,
    required this.payTokenMint,
    required this.creatorPayAccount,
    required this.treasury,
    required this.instructions,
    required this.mplCoreProgram,
    required this.systemProgram,
    required this.tokenProgram,
  });
}

Uint8List encodeMintSeriesNftInstructionData({
  required String collectionType,
  required BigInt dramaId,
  required StorySignedParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(mintSeriesNftInstructionDiscriminator);
  writer.writeString(collectionType);
  writer.writeU64(dramaId);
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildMintSeriesNftInstruction({
  required Ed25519HDPublicKey programId,
  required MintSeriesNftAccounts accounts,
  required String collectionType,
  required BigInt dramaId,
  required StorySignedParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.creator, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.sponor, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.asset, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.collectionInfo, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.collectionMint, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.payTokenMint, isSigner: false),
      AccountMeta.writeable(
        pubKey: accounts.creatorPayAccount,
        isSigner: false,
      ),
      AccountMeta.writeable(pubKey: accounts.treasury, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.instructions, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.mplCoreProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.tokenProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(
      encodeMintSeriesNftInstructionData(
        collectionType: collectionType,
        dramaId: dramaId,
        params: params,
      ),
    ),
  );
}

Future<Ed25519HDPublicKey> findMintSeriesNftConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findMintSeriesNftAssetPda({
  required Ed25519HDPublicKey programId,
  required BigInt dramaId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[100, 114, 97, 109, 97, 95, 109, 105, 110, 116],
    _encodeStoryPdaU64(dramaId),
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findMintSeriesNftCollectionInfoPda({
  required Ed25519HDPublicKey programId,
  required String collectionType,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      99,
      111,
      108,
      108,
      101,
      99,
      116,
      105,
      111,
      110,
      95,
      105,
      110,
      102,
      111,
    ],
    utf8.encode(collectionType),
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findMintSeriesNftCollectionMintPda({
  required Ed25519HDPublicKey programId,
  required String collectionType,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      99,
      111,
      108,
      108,
      101,
      99,
      116,
      105,
      111,
      110,
      95,
      109,
      105,
      110,
      116,
    ],
    utf8.encode(collectionType),
  ],
  programId: programId,
);

const proposeAuthorityTransferInstructionDiscriminator = <int>[
  57,
  206,
  225,
  129,
  35,
  111,
  174,
  145,
];

class ProposeAuthorityTransferAccounts {
  final Ed25519HDPublicKey authority;
  final Ed25519HDPublicKey config;

  const ProposeAuthorityTransferAccounts({
    required this.authority,
    required this.config,
  });
}

Uint8List encodeProposeAuthorityTransferInstructionData({
  required StoryProposeAuthorityTransferParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(proposeAuthorityTransferInstructionDiscriminator);
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildProposeAuthorityTransferInstruction({
  required Ed25519HDPublicKey programId,
  required ProposeAuthorityTransferAccounts accounts,
  required StoryProposeAuthorityTransferParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.authority, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.config, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(
      encodeProposeAuthorityTransferInstructionData(params: params),
    ),
  );
}

Future<Ed25519HDPublicKey> findProposeAuthorityTransferConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

const proposeConfigUpdateInstructionDiscriminator = <int>[
  134,
  33,
  64,
  84,
  30,
  156,
  236,
  79,
];

class ProposeConfigUpdateAccounts {
  final Ed25519HDPublicKey authority;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey pendingConfig;
  final Ed25519HDPublicKey systemProgram;

  const ProposeConfigUpdateAccounts({
    required this.authority,
    required this.config,
    required this.pendingConfig,
    required this.systemProgram,
  });
}

Uint8List encodeProposeConfigUpdateInstructionData({
  required StoryProposeConfigUpdateParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(proposeConfigUpdateInstructionDiscriminator);
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildProposeConfigUpdateInstruction({
  required Ed25519HDPublicKey programId,
  required ProposeConfigUpdateAccounts accounts,
  required StoryProposeConfigUpdateParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.authority, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.pendingConfig, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(encodeProposeConfigUpdateInstructionData(params: params)),
  );
}

Future<Ed25519HDPublicKey> findProposeConfigUpdateConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findProposeConfigUpdatePendingConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[112, 101, 110, 100, 105, 110, 103, 95, 99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

const purchaseCardInstructionDiscriminator = <int>[
  237,
  80,
  145,
  82,
  138,
  115,
  153,
  135,
];

class PurchaseCardAccounts {
  final Ed25519HDPublicKey buyer;
  final Ed25519HDPublicKey sponor;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey payTokenMint;
  final Ed25519HDPublicKey buyerPayAccount;
  final Ed25519HDPublicKey treasury;
  final Ed25519HDPublicKey purchaseRecord;
  final Ed25519HDPublicKey instructions;
  final Ed25519HDPublicKey systemProgram;
  final Ed25519HDPublicKey tokenProgram;

  const PurchaseCardAccounts({
    required this.buyer,
    required this.sponor,
    required this.config,
    required this.payTokenMint,
    required this.buyerPayAccount,
    required this.treasury,
    required this.purchaseRecord,
    required this.instructions,
    required this.systemProgram,
    required this.tokenProgram,
  });
}

Uint8List encodePurchaseCardInstructionData({
  required Uint8List orderHash,
  required StorySignedParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(purchaseCardInstructionDiscriminator);
  writer.writeFixedBytes(orderHash, length: 32, name: 'orderHash');
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildPurchaseCardInstruction({
  required Ed25519HDPublicKey programId,
  required PurchaseCardAccounts accounts,
  required Uint8List orderHash,
  required StorySignedParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.buyer, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.sponor, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.buyerPayAccount, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.treasury, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.purchaseRecord, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.instructions, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.tokenProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(
      encodePurchaseCardInstructionData(orderHash: orderHash, params: params),
    ),
  );
}

Future<Ed25519HDPublicKey> findPurchaseCardConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findPurchaseCardPurchaseRecordPda({
  required Ed25519HDPublicKey programId,
  required Uint8List orderHash,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 97, 114, 100, 95, 112, 117, 114, 99, 104, 97, 115, 101],
    orderHash,
  ],
  programId: programId,
);

const refillActorStaminaInstructionDiscriminator = <int>[
  48,
  197,
  12,
  133,
  10,
  207,
  227,
  120,
];

class RefillActorStaminaAccounts {
  final Ed25519HDPublicKey user;
  final Ed25519HDPublicKey sponor;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey collectionInfo;
  final Ed25519HDPublicKey asset;
  final Ed25519HDPublicKey payTokenMint;
  final Ed25519HDPublicKey payerPayAccount;
  final Ed25519HDPublicKey treasury;
  final Ed25519HDPublicKey refillRecord;
  final Ed25519HDPublicKey instructions;
  final Ed25519HDPublicKey systemProgram;
  final Ed25519HDPublicKey tokenProgram;

  const RefillActorStaminaAccounts({
    required this.user,
    required this.sponor,
    required this.config,
    required this.collectionInfo,
    required this.asset,
    required this.payTokenMint,
    required this.payerPayAccount,
    required this.treasury,
    required this.refillRecord,
    required this.instructions,
    required this.systemProgram,
    required this.tokenProgram,
  });
}

Uint8List encodeRefillActorStaminaInstructionData({
  required String assetId,
  required Uint8List orderHash,
  required StorySignedParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(refillActorStaminaInstructionDiscriminator);
  writer.writeString(assetId);
  writer.writeFixedBytes(orderHash, length: 32, name: 'orderHash');
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildRefillActorStaminaInstruction({
  required Ed25519HDPublicKey programId,
  required RefillActorStaminaAccounts accounts,
  required String assetId,
  required Uint8List orderHash,
  required StorySignedParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.user, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.sponor, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.collectionInfo, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.asset, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.payerPayAccount, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.treasury, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.refillRecord, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.instructions, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.tokenProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(
      encodeRefillActorStaminaInstructionData(
        assetId: assetId,
        orderHash: orderHash,
        params: params,
      ),
    ),
  );
}

Future<Ed25519HDPublicKey> findRefillActorStaminaConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findRefillActorStaminaCollectionInfoPda({
  required Ed25519HDPublicKey programId,
  required String collectionInfoAssetId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      99,
      111,
      108,
      108,
      101,
      99,
      116,
      105,
      111,
      110,
      95,
      105,
      110,
      102,
      111,
    ],
    utf8.encode(collectionInfoAssetId),
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findRefillActorStaminaAssetPda({
  required Ed25519HDPublicKey programId,
  required String assetId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[97, 99, 116, 111, 114, 95, 109, 105, 110, 116],
    utf8.encode(assetId),
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findRefillActorStaminaRefillRecordPda({
  required Ed25519HDPublicKey programId,
  required Uint8List orderHash,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      97,
      99,
      116,
      111,
      114,
      95,
      115,
      116,
      97,
      109,
      105,
      110,
      97,
      95,
      114,
      101,
      102,
      105,
      108,
      108,
    ],
    orderHash,
  ],
  programId: programId,
);

const setStoryTokenMintInstructionDiscriminator = <int>[
  144,
  232,
  29,
  146,
  158,
  65,
  250,
  32,
];

class SetStoryTokenMintAccounts {
  final Ed25519HDPublicKey authority;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey tokenMint;
  final Ed25519HDPublicKey vault;
  final Ed25519HDPublicKey tokenProgram;
  final Ed25519HDPublicKey associatedTokenProgram;
  final Ed25519HDPublicKey systemProgram;

  const SetStoryTokenMintAccounts({
    required this.authority,
    required this.config,
    required this.tokenMint,
    required this.vault,
    required this.tokenProgram,
    required this.associatedTokenProgram,
    required this.systemProgram,
  });
}

Uint8List encodeSetStoryTokenMintInstructionData() {
  final writer = AnchorBorshWriter()
    ..writeBytes(setStoryTokenMintInstructionDiscriminator);
  return writer.toBytes();
}

Instruction buildSetStoryTokenMintInstruction({
  required Ed25519HDPublicKey programId,
  required SetStoryTokenMintAccounts accounts,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.authority, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.config, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.tokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.vault, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.tokenProgram, isSigner: false),
      AccountMeta.readonly(
        pubKey: accounts.associatedTokenProgram,
        isSigner: false,
      ),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(encodeSetStoryTokenMintInstructionData()),
  );
}

Future<Ed25519HDPublicKey> findSetStoryTokenMintConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findSetStoryTokenMintVaultPda({
  required Ed25519HDPublicKey config,
  required Ed25519HDPublicKey tokenMint,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    config.bytes,
    <int>[
      6,
      221,
      246,
      225,
      215,
      101,
      161,
      147,
      217,
      203,
      225,
      70,
      206,
      235,
      121,
      172,
      28,
      180,
      133,
      237,
      95,
      91,
      55,
      145,
      58,
      140,
      245,
      133,
      126,
      255,
      0,
      169,
    ],
    tokenMint.bytes,
  ],
  programId: Ed25519HDPublicKey(
    Uint8List.fromList(<int>[
      140,
      151,
      37,
      143,
      78,
      36,
      137,
      241,
      187,
      61,
      16,
      41,
      20,
      142,
      13,
      131,
      11,
      90,
      19,
      153,
      218,
      255,
      16,
      132,
      4,
      142,
      123,
      216,
      219,
      233,
      248,
      89,
    ]),
  ),
);

const updateConfigInstructionDiscriminator = <int>[
  29,
  158,
  252,
  191,
  10,
  83,
  219,
  99,
];

class UpdateConfigAccounts {
  final Ed25519HDPublicKey authority;
  final Ed25519HDPublicKey config;

  const UpdateConfigAccounts({required this.authority, required this.config});
}

Uint8List encodeUpdateConfigInstructionData({
  required StoryUpdateConfigParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(updateConfigInstructionDiscriminator);
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildUpdateConfigInstruction({
  required Ed25519HDPublicKey programId,
  required UpdateConfigAccounts accounts,
  required StoryUpdateConfigParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.authority, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.config, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(encodeUpdateConfigInstructionData(params: params)),
  );
}

Future<Ed25519HDPublicKey> findUpdateConfigConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

const upgradeActorNftInstructionDiscriminator = <int>[
  18,
  145,
  143,
  253,
  252,
  119,
  121,
  70,
];

class UpgradeActorNftAccounts {
  final Ed25519HDPublicKey user;
  final Ed25519HDPublicKey sponor;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey collectionInfo;
  final Ed25519HDPublicKey collectionMint;
  final Ed25519HDPublicKey mint;
  final Ed25519HDPublicKey payTokenMint;
  final Ed25519HDPublicKey payerPayAccount;
  final Ed25519HDPublicKey treasury;
  final Ed25519HDPublicKey instructions;
  final Ed25519HDPublicKey mplCoreProgram;
  final Ed25519HDPublicKey systemProgram;
  final Ed25519HDPublicKey tokenProgram;

  const UpgradeActorNftAccounts({
    required this.user,
    required this.sponor,
    required this.config,
    required this.collectionInfo,
    required this.collectionMint,
    required this.mint,
    required this.payTokenMint,
    required this.payerPayAccount,
    required this.treasury,
    required this.instructions,
    required this.mplCoreProgram,
    required this.systemProgram,
    required this.tokenProgram,
  });
}

Uint8List encodeUpgradeActorNftInstructionData({
  required String assetId,
  required StorySignedParams params,
}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(upgradeActorNftInstructionDiscriminator);
  writer.writeString(assetId);
  params.writeTo(writer);
  return writer.toBytes();
}

Instruction buildUpgradeActorNftInstruction({
  required Ed25519HDPublicKey programId,
  required UpgradeActorNftAccounts accounts,
  required String assetId,
  required StorySignedParams params,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.writeable(pubKey: accounts.user, isSigner: true),
      AccountMeta.writeable(pubKey: accounts.sponor, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.collectionInfo, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.collectionMint, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.mint, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.payerPayAccount, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.treasury, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.instructions, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.mplCoreProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.systemProgram, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.tokenProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(
      encodeUpgradeActorNftInstructionData(assetId: assetId, params: params),
    ),
  );
}

Future<Ed25519HDPublicKey> findUpgradeActorNftConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findUpgradeActorNftCollectionInfoPda({
  required Ed25519HDPublicKey programId,
  required String collectionInfoAssetId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[
      99,
      111,
      108,
      108,
      101,
      99,
      116,
      105,
      111,
      110,
      95,
      105,
      110,
      102,
      111,
    ],
    utf8.encode(collectionInfoAssetId),
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findUpgradeActorNftMintPda({
  required Ed25519HDPublicKey programId,
  required String assetId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[97, 99, 116, 111, 114, 95, 109, 105, 110, 116],
    utf8.encode(assetId),
  ],
  programId: programId,
);

const withdrawFromUsdcVaultInstructionDiscriminator = <int>[
  133,
  247,
  63,
  88,
  235,
  76,
  87,
  177,
];

class WithdrawFromUsdcVaultAccounts {
  final Ed25519HDPublicKey withdrawer;
  final Ed25519HDPublicKey config;
  final Ed25519HDPublicKey payTokenMint;
  final Ed25519HDPublicKey vault;
  final Ed25519HDPublicKey recipient;
  final Ed25519HDPublicKey recipientTokenAccount;
  final Ed25519HDPublicKey tokenProgram;

  const WithdrawFromUsdcVaultAccounts({
    required this.withdrawer,
    required this.config,
    required this.payTokenMint,
    required this.vault,
    required this.recipient,
    required this.recipientTokenAccount,
    required this.tokenProgram,
  });
}

Uint8List encodeWithdrawFromUsdcVaultInstructionData({required BigInt amount}) {
  final writer = AnchorBorshWriter()
    ..writeBytes(withdrawFromUsdcVaultInstructionDiscriminator);
  writer.writeU64(amount);
  return writer.toBytes();
}

Instruction buildWithdrawFromUsdcVaultInstruction({
  required Ed25519HDPublicKey programId,
  required WithdrawFromUsdcVaultAccounts accounts,
  required BigInt amount,
  List<AccountMeta> remainingAccounts = const [],
}) {
  return Instruction(
    programId: programId,
    accounts: [
      AccountMeta.readonly(pubKey: accounts.withdrawer, isSigner: true),
      AccountMeta.readonly(pubKey: accounts.config, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.payTokenMint, isSigner: false),
      AccountMeta.writeable(pubKey: accounts.vault, isSigner: false),
      AccountMeta.readonly(pubKey: accounts.recipient, isSigner: false),
      AccountMeta.writeable(
        pubKey: accounts.recipientTokenAccount,
        isSigner: false,
      ),
      AccountMeta.readonly(pubKey: accounts.tokenProgram, isSigner: false),
      ...remainingAccounts,
    ],
    data: ByteArray(encodeWithdrawFromUsdcVaultInstructionData(amount: amount)),
  );
}

Future<Ed25519HDPublicKey> findWithdrawFromUsdcVaultConfigPda({
  required Ed25519HDPublicKey programId,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    <int>[99, 111, 110, 102, 105, 103],
  ],
  programId: programId,
);

Future<Ed25519HDPublicKey> findWithdrawFromUsdcVaultRecipientTokenAccountPda({
  required Ed25519HDPublicKey recipient,
  required Ed25519HDPublicKey payTokenMint,
}) => Ed25519HDPublicKey.findProgramAddress(
  seeds: [
    recipient.bytes,
    <int>[
      6,
      221,
      246,
      225,
      215,
      101,
      161,
      147,
      217,
      203,
      225,
      70,
      206,
      235,
      121,
      172,
      28,
      180,
      133,
      237,
      95,
      91,
      55,
      145,
      58,
      140,
      245,
      133,
      126,
      255,
      0,
      169,
    ],
    payTokenMint.bytes,
  ],
  programId: Ed25519HDPublicKey(
    Uint8List.fromList(<int>[
      140,
      151,
      37,
      143,
      78,
      36,
      137,
      241,
      187,
      61,
      16,
      41,
      20,
      142,
      13,
      131,
      11,
      90,
      19,
      153,
      218,
      255,
      16,
      132,
      4,
      142,
      123,
      216,
      219,
      233,
      248,
      89,
    ]),
  ),
);
