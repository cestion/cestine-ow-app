import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mint_actor_nft_request_model.g.dart';

@JsonSerializable()
class MintActorNftRequest extends Equatable {
  final String nftChain;
  final String nftTokenStandard;
  final String nftContractAddress;
  final String walletAddress;
  final String payMethod;

  const MintActorNftRequest({
    required this.nftChain,
    required this.nftTokenStandard,
    required this.nftContractAddress,
    required this.walletAddress,
    this.payMethod = 'usdc',
  });

  factory MintActorNftRequest.fromJson(Map<String, dynamic> json) =>
      _$MintActorNftRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MintActorNftRequestToJson(this);

  @override
  List<Object?> get props => [
    nftChain,
    nftTokenStandard,
    nftContractAddress,
    walletAddress,
    payMethod,
  ];
}
