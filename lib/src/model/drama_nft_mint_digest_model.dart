import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'drama_nft_mint_digest_model.g.dart';

/// 短剧 NFT mint 摘要，与 web `DramaNftMintDigestResponse` 对齐。
@JsonSerializable()
class DramaNftMintDigest extends Equatable {
  final String? userId;
  final String? dramaId;
  final String? creatorAddress;
  final String? mintWalletAddress;
  final String? nftChain;
  final String? nftTokenStandard;
  final String? nftContractAddress;
  final String? metadataUrl;
  final String? payToken;
  final String? feeAmount;
  @JsonKey(fromJson: asInt)
  final int? issuedAt;
  @JsonKey(fromJson: asInt)
  final int? expiresAt;
  final String? canonicalPayload;
  final String? sig;

  const DramaNftMintDigest({
    this.userId,
    this.dramaId,
    this.creatorAddress,
    this.mintWalletAddress,
    this.nftChain,
    this.nftTokenStandard,
    this.nftContractAddress,
    this.metadataUrl,
    this.payToken,
    this.feeAmount,
    this.issuedAt,
    this.expiresAt,
    this.canonicalPayload,
    this.sig,
  });

  factory DramaNftMintDigest.fromJson(Map<String, dynamic> json) =>
      _$DramaNftMintDigestFromJson(json);

  Map<String, dynamic> toJson() => _$DramaNftMintDigestToJson(this);

  bool get isReadyForChain =>
      (canonicalPayload?.trim().isNotEmpty ?? false) &&
      (sig?.trim().isNotEmpty ?? false) &&
      (payToken?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [
    userId,
    dramaId,
    creatorAddress,
    mintWalletAddress,
    nftChain,
    nftTokenStandard,
    nftContractAddress,
    metadataUrl,
    payToken,
    feeAmount,
    issuedAt,
    expiresAt,
    canonicalPayload,
    sig,
  ];
}
