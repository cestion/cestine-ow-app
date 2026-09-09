import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'mint_actor_collection_request_model.g.dart';

@JsonSerializable()
class MintActorCollectionRequest extends Equatable {
  @JsonKey(fromJson: asInt)
  final int? actorCollectionId;
  final String nftChain;
  final String nftTokenStandard;
  final String nftContractAddress;
  final String walletAddress;
  final String payMethod;

  const MintActorCollectionRequest({
    this.actorCollectionId,
    required this.nftChain,
    required this.nftTokenStandard,
    required this.nftContractAddress,
    required this.walletAddress,
    this.payMethod = 'usdc',
  });

  factory MintActorCollectionRequest.fromJson(Map<String, dynamic> json) =>
      _$MintActorCollectionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MintActorCollectionRequestToJson(this);

  @override
  List<Object?> get props => [
    actorCollectionId,
    nftChain,
    nftTokenStandard,
    nftContractAddress,
    walletAddress,
    payMethod,
  ];
}
