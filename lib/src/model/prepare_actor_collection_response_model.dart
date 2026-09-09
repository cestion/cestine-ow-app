import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'prepare_actor_collection_response_model.g.dart';

@JsonSerializable()
class PrepareActorCollectionResponse extends Equatable {
  @JsonKey(fromJson: asInt)
  final int? actorCollectionId;
  final String? assetId;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  @JsonKey(fromJson: asInt)
  final int? totalSupply;
  @JsonKey(fromJson: asDouble)
  final double? initialPriceUsdc;
  final String? pricingMode;
  final String? status;
  @JsonKey(fromJson: asInt)
  final int? expiresAt;

  const PrepareActorCollectionResponse({
    this.actorCollectionId,
    this.assetId,
    this.name,
    this.avatarUrl,
    this.bio,
    this.totalSupply,
    this.initialPriceUsdc,
    this.pricingMode,
    this.status,
    this.expiresAt,
  });

  factory PrepareActorCollectionResponse.fromJson(Map<String, dynamic> json) =>
      _$PrepareActorCollectionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PrepareActorCollectionResponseToJson(this);

  @override
  List<Object?> get props => [
    actorCollectionId,
    assetId,
    name,
    avatarUrl,
    bio,
    totalSupply,
    initialPriceUsdc,
    pricingMode,
    status,
    expiresAt,
  ];
}
