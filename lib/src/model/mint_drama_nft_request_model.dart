import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mint_drama_nft_request_model.g.dart';

@JsonSerializable()
class MintDramaNftRequest extends Equatable {
  final String nftChain;
  final String nftContractAddress;
  final String nftTokenStandard;
  final String walletAddress;
  final String payMethod;

  const MintDramaNftRequest({
    required this.nftChain,
    required this.nftContractAddress,
    required this.nftTokenStandard,
    required this.walletAddress,
    this.payMethod = 'usdc',
  });

  factory MintDramaNftRequest.fromJson(Map<String, dynamic> json) =>
      _$MintDramaNftRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MintDramaNftRequestToJson(this);

  @override
  List<Object?> get props => [
    nftChain,
    nftContractAddress,
    nftTokenStandard,
    walletAddress,
    payMethod,
  ];
}
