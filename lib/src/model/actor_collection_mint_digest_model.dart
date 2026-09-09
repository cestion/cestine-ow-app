import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'actor_collection_mint_digest_model.g.dart';

/// 演员 IP 发行 mint 摘要，与 web `ActorCollectionMintDigestResponse` 对齐。
@JsonSerializable()
class ActorCollectionMintDigest extends Equatable {
  @JsonKey(fromJson: asInt)
  final int? actorCollectionId;
  final String? assetId;
  final String? creatorAddress;
  final String? walletAddress;
  final String? collectionMintAddress;
  final String? name;
  final String? nftChain;
  final String? nftTokenStandard;
  final String? baseUrl;
  @JsonKey(fromJson: asInt)
  final int? totalSupply;
  @JsonKey(fromJson: asDouble)
  final double? initialPriceUsdc;
  final String? initialPriceAmount;
  final String? curveMultiplierAmount;
  final String? payToken;
  final String? feeAmount;
  @JsonKey(fromJson: asInt)
  final int? issuedAt;
  @JsonKey(fromJson: asInt)
  final int? expiresAt;
  final String? canonicalPayload;
  final String? sig;

  const ActorCollectionMintDigest({
    this.actorCollectionId,
    this.assetId,
    this.creatorAddress,
    this.walletAddress,
    this.collectionMintAddress,
    this.name,
    this.nftChain,
    this.nftTokenStandard,
    this.baseUrl,
    this.totalSupply,
    this.initialPriceUsdc,
    this.initialPriceAmount,
    this.curveMultiplierAmount,
    this.payToken,
    this.feeAmount,
    this.issuedAt,
    this.expiresAt,
    this.canonicalPayload,
    this.sig,
  });

  factory ActorCollectionMintDigest.fromJson(Map<String, dynamic> json) =>
      _$ActorCollectionMintDigestFromJson(json);

  Map<String, dynamic> toJson() => _$ActorCollectionMintDigestToJson(this);

  bool get isReadyForChain =>
      (canonicalPayload?.trim().isNotEmpty ?? false) &&
      (sig?.trim().isNotEmpty ?? false) &&
      (payToken?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [
    actorCollectionId,
    assetId,
    creatorAddress,
    walletAddress,
    collectionMintAddress,
    name,
    nftChain,
    nftTokenStandard,
    baseUrl,
    totalSupply,
    initialPriceUsdc,
    initialPriceAmount,
    curveMultiplierAmount,
    payToken,
    feeAmount,
    issuedAt,
    expiresAt,
    canonicalPayload,
    sig,
  ];
}
