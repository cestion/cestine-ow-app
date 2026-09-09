import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'actor_model.g.dart';

@JsonSerializable()
class Actor extends Equatable {
  @JsonKey(fromJson: asString)
  final String? id;
  @JsonKey(fromJson: asString)
  final String? userId;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final String? status;
  final String? auditReason;
  final String? nftMintAddress;
  @JsonKey(fromJson: asInt)
  final int? nftMaxSupply;
  @JsonKey(fromJson: asInt)
  final int? creatorReservedQuantity;
  @JsonKey(fromJson: asInt)
  final int? mintQuantity;
  @JsonKey(fromJson: asDouble)
  final double? nftUnitPrice;
  @JsonKey(fromJson: asInt)
  final int? nftMinHoldThreshold;
  final String? nftChain;
  final String? nftTokenStandard;
  final String? nftTxHash;
  @JsonKey(fromJson: asInt)
  final int? createdAt;
  @JsonKey(fromJson: asInt)
  final int? updatedAt;
  @JsonKey(fromJson: asInt)
  final int? version;

  const Actor({
    this.id,
    this.userId,
    this.name,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.status,
    this.auditReason,
    this.nftMintAddress,
    this.nftMaxSupply,
    this.creatorReservedQuantity,
    this.mintQuantity,
    this.nftUnitPrice,
    this.nftMinHoldThreshold,
    this.nftChain,
    this.nftTokenStandard,
    this.nftTxHash,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  factory Actor.fromJson(Map<String, dynamic> json) => _$ActorFromJson(json);

  Map<String, dynamic> toJson() => _$ActorToJson(this);

  int? get remainingSupply {
    final max = nftMaxSupply;
    final minted = mintQuantity;
    if (max == null || minted == null) return null;
    return max - minted;
  }

  double? get mintProgress {
    final max = nftMaxSupply;
    final minted = mintQuantity;
    if (max == null || minted == null || max == 0) return null;
    return minted / max;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    avatarUrl,
    bio,
    gender,
    status,
    auditReason,
    nftMintAddress,
    nftMaxSupply,
    creatorReservedQuantity,
    mintQuantity,
    nftUnitPrice,
    nftMinHoldThreshold,
    nftChain,
    nftTokenStandard,
    nftTxHash,
    createdAt,
    updatedAt,
    version,
  ];
}
