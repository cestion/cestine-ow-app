import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'nft_info_model.g.dart';

@JsonSerializable()
class NftInfo extends Equatable {
  final String? mintAddress;
  final String? chain;
  final String? tokenStandard;
  @JsonKey(fromJson: asInt)
  final int? maxSupply;
  @JsonKey(fromJson: asDouble)
  final double? unitPrice;
  @JsonKey(fromJson: asInt)
  final int? minHoldThreshold;
  final String? txHash;

  const NftInfo({
    this.mintAddress,
    this.chain,
    this.tokenStandard,
    this.maxSupply,
    this.unitPrice,
    this.minHoldThreshold,
    this.txHash,
  });

  factory NftInfo.fromJson(Map<String, dynamic> json) =>
      _$NftInfoFromJson(json);

  Map<String, dynamic> toJson() => _$NftInfoToJson(this);

  @override
  List<Object?> get props => [
    mintAddress,
    chain,
    tokenStandard,
    maxSupply,
    unitPrice,
    minHoldThreshold,
    txHash,
  ];
}
