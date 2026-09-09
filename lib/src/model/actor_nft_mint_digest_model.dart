import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'actor_nft_mint_digest_model.g.dart';

/// 演员签约 mint 摘要，与 web `ActorNftMintDigestResponse` 对齐。
@JsonSerializable()
class ActorNftMintDigest extends Equatable {
  @JsonKey(fromJson: asInt)
  final int? actorCollectionId;
  final String? assetId;
  final String? walletAddress;
  final String? collectionMintAddress;
  final String? name;
  final String? nftChain;
  final String? nftTokenStandard;
  @JsonKey(fromJson: asDouble)
  final double? initialPriceUsdc;
  final String? payToken;
  @JsonKey(fromJson: asInt)
  final int? currentSupply;
  @JsonKey(fromJson: asInt)
  final int? quantity;
  @JsonKey(fromJson: asDouble)
  final double? basePrice;
  @JsonKey(fromJson: asDouble)
  final double? totalPrice;
  @JsonKey(fromJson: asDouble)
  final double? totalPriceWithSlippage;
  @JsonKey(fromJson: asDouble)
  final double? nextPrice;
  @JsonKey(fromJson: asInt)
  final int? issuedAt;
  @JsonKey(fromJson: asInt)
  final int? expiresAt;
  final String? canonicalPayload;
  final String? sig;

  const ActorNftMintDigest({
    this.actorCollectionId,
    this.assetId,
    this.walletAddress,
    this.collectionMintAddress,
    this.name,
    this.nftChain,
    this.nftTokenStandard,
    this.initialPriceUsdc,
    this.payToken,
    this.currentSupply,
    this.quantity,
    this.basePrice,
    this.totalPrice,
    this.totalPriceWithSlippage,
    this.nextPrice,
    this.issuedAt,
    this.expiresAt,
    this.canonicalPayload,
    this.sig,
  });

  factory ActorNftMintDigest.fromJson(Map<String, dynamic> json) =>
      _$ActorNftMintDigestFromJson(json);

  Map<String, dynamic> toJson() => _$ActorNftMintDigestToJson(this);

  bool get isReadyForChain =>
      (canonicalPayload?.trim().isNotEmpty ?? false) &&
      (sig?.trim().isNotEmpty ?? false) &&
      (payToken?.trim().isNotEmpty ?? false);

  int get mintStartIndex => (currentSupply ?? 0) + 1;

  @override
  List<Object?> get props => [
    actorCollectionId,
    assetId,
    walletAddress,
    collectionMintAddress,
    name,
    nftChain,
    nftTokenStandard,
    initialPriceUsdc,
    payToken,
    currentSupply,
    quantity,
    basePrice,
    totalPrice,
    totalPriceWithSlippage,
    nextPrice,
    issuedAt,
    expiresAt,
    canonicalPayload,
    sig,
  ];
}
