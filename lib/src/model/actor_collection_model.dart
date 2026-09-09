import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../utils/actor_pricing.dart';
import 'actor_model.dart';
import 'json_converters.dart';

part 'actor_collection_model.g.dart';

/// Actor collection data from `/api/mini-drama/public/actor-collections`.
///
/// Matches the H5 web client's actor IP card data shape.
@JsonSerializable()
class ActorCollection extends Equatable {
  @JsonKey(fromJson: asString)
  final String? id;
  @JsonKey(fromJson: asString)
  final String? userId;
  final String? creatorName;
  final String? assetId;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  final String? status;
  final String? auditReason;
  final String? nftMintAddress;
  final String? pricingMode;

  /// Content badge enum from API: OFFICIAL / COMMUNITY / PARTNER / VERIFIED.
  final String? badge;
  @JsonKey(fromJson: asString)
  final String? totalSupply;
  @JsonKey(fromJson: asString)
  final String? mintedSupply;
  @JsonKey(fromJson: asString)
  final String? availableSupply;
  @JsonKey(fromJson: asDouble)
  final double? initialPriceUsdc;
  @JsonKey(fromJson: asDouble)
  final double? currentPriceUsdc;

  /// Secondary-market floor price (also accepted as floorPrice / lowestListing).
  @JsonKey(fromJson: asDouble)
  final double? floorPriceUsdc;
  final String? nftChain;
  final String? nftTokenStandard;
  final String? nftTxHash;
  @JsonKey(fromJson: asString)
  final String? completedViewCount;
  @JsonKey(fromJson: asDouble)
  final double? heatValue;

  /// Trust coefficient; risk badge when present and not `1`.
  @JsonKey(fromJson: asDouble)
  final double? trust;

  /// Locked price coefficient from issue P0 (`initialPriceMultiplier` on API).
  @JsonKey(fromJson: asDouble)
  final double? initialPriceMultiplier;

  /// IP computing power from API (`computingPower`).
  @JsonKey(fromJson: asDouble)
  final double? computingPower;
  @JsonKey(fromJson: asString)
  final String? createdAt;
  @JsonKey(fromJson: asString)
  final String? updatedAt;
  @JsonKey(fromJson: asString)
  final String? version;

  const ActorCollection({
    this.id,
    this.userId,
    this.creatorName,
    this.assetId,
    this.name,
    this.avatarUrl,
    this.bio,
    this.status,
    this.auditReason,
    this.nftMintAddress,
    this.pricingMode,
    this.badge,
    this.totalSupply,
    this.mintedSupply,
    this.availableSupply,
    this.initialPriceUsdc,
    this.currentPriceUsdc,
    this.floorPriceUsdc,
    this.nftChain,
    this.nftTokenStandard,
    this.nftTxHash,
    this.completedViewCount,
    this.heatValue,
    this.trust,
    this.initialPriceMultiplier,
    this.computingPower,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  factory ActorCollection.fromJson(Map<String, dynamic> json) =>
      _$ActorCollectionFromJson(json);

  /// Best-effort preview for detail navigation from [Actor] list cards.
  factory ActorCollection.fromActor(Actor actor) => ActorCollection(
    id: actor.id,
    userId: actor.userId,
    name: actor.name,
    avatarUrl: actor.avatarUrl,
    bio: actor.bio,
    status: actor.status,
    auditReason: actor.auditReason,
    nftMintAddress: actor.nftMintAddress,
    totalSupply: actor.nftMaxSupply?.toString(),
    mintedSupply: actor.mintQuantity?.toString(),
    availableSupply: actor.remainingSupply?.toString(),
    initialPriceUsdc: actor.nftUnitPrice,
    currentPriceUsdc: actor.nftUnitPrice,
    nftChain: actor.nftChain,
    nftTokenStandard: actor.nftTokenStandard,
    nftTxHash: actor.nftTxHash,
    version: actor.version?.toString(),
  );

  Map<String, dynamic> toJson() => _$ActorCollectionToJson(this);

  /// Parsed integer total supply.
  int? get totalSupplyInt => int.tryParse(totalSupply ?? '');

  /// Parsed integer minted supply.
  int? get mintedSupplyInt => int.tryParse(mintedSupply ?? '');

  /// Parsed integer available supply.
  int? get availableSupplyInt => int.tryParse(availableSupply ?? '');

  /// Parsed integer completed view count.
  ///
  /// API may send an int, double, or numeric string (`"12345.0"`).
  int? get completedViewCountInt {
    final raw = completedViewCount;
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw) ?? double.tryParse(raw)?.truncate();
  }

  /// Signing price for display, aligned with web `getActorPlazaCardDisplay`.
  double get displayCurrentPriceUsdc => resolveActorDisplayCurrentPrice(
    pricingMode: pricingMode,
    initialPrice: initialPriceUsdc ?? 0,
    currentPrice: currentPriceUsdc,
    signedCount: mintedSupplyInt ?? 0,
    maxSupply: totalSupplyInt ?? 0,
  );

  /// Mint progress ratio (0.0 ~ 1.0).
  double? get mintProgress {
    final total = totalSupplyInt;
    final minted = mintedSupplyInt;
    if (total == null || minted == null || total == 0) return null;
    return minted / total;
  }

  /// Aligned with web: `trust !== undefined && trust !== 1`.
  bool get isRiskActorIp => trust != null && trust != 1;

  @override
  List<Object?> get props => [
    id,
    userId,
    creatorName,
    assetId,
    name,
    avatarUrl,
    bio,
    status,
    auditReason,
    nftMintAddress,
    pricingMode,
    badge,
    totalSupply,
    mintedSupply,
    availableSupply,
    initialPriceUsdc,
    currentPriceUsdc,
    floorPriceUsdc,
    nftChain,
    nftTokenStandard,
    nftTxHash,
    completedViewCount,
    heatValue,
    trust,
    initialPriceMultiplier,
    computingPower,
    createdAt,
    updatedAt,
    version,
  ];
}
