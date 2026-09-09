import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'actor_collection_pricing_mode.dart';

part 'prepare_actor_collection_request_model.g.dart';

/// Backend constraint: totalSupply must be within [minTotalSupply]..[maxTotalSupply].
const prepareActorCollectionMinTotalSupply = 100;
const prepareActorCollectionMaxTotalSupply = 5000;

@JsonSerializable()
class PrepareActorCollectionRequest extends Equatable {
  final String assetId;
  final String name;
  final String bio;
  @JsonKey(fromJson: _toInt)
  final int totalSupply;
  final String pricingMode;
  @JsonKey(fromJson: _toDouble)
  final double initialPriceUsdc;

  const PrepareActorCollectionRequest({
    required this.assetId,
    required this.name,
    required this.bio,
    required this.totalSupply,
    required this.pricingMode,
    required this.initialPriceUsdc,
  });

  factory PrepareActorCollectionRequest.bondingCurve({
    required String assetId,
    required String name,
    required String bio,
    required int totalSupply,
    required double initialPriceUsdc,
  }) => PrepareActorCollectionRequest.create(
    assetId: assetId,
    name: name,
    bio: bio,
    totalSupply: totalSupply,
    pricingMode: ActorCollectionPricingMode.bondingCurve,
    initialPriceUsdc: initialPriceUsdc,
  );

  factory PrepareActorCollectionRequest.fixed({
    required String assetId,
    required String name,
    required String bio,
    required int totalSupply,
    required double initialPriceUsdc,
  }) => PrepareActorCollectionRequest.create(
    assetId: assetId,
    name: name,
    bio: bio,
    totalSupply: totalSupply,
    pricingMode: ActorCollectionPricingMode.fixed,
    initialPriceUsdc: initialPriceUsdc,
  );

  factory PrepareActorCollectionRequest.create({
    required String assetId,
    required String name,
    required String bio,
    required int totalSupply,
    required ActorCollectionPricingMode pricingMode,
    required double initialPriceUsdc,
  }) => PrepareActorCollectionRequest(
    assetId: assetId,
    name: name,
    bio: bio,
    totalSupply: totalSupply,
    pricingMode: pricingMode.apiValue,
    initialPriceUsdc: initialPriceUsdc,
  );

  factory PrepareActorCollectionRequest.fromJson(Map<String, dynamic> json) =>
      _$PrepareActorCollectionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PrepareActorCollectionRequestToJson(this);

  static int _toInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
  static double _toDouble(dynamic v) =>
      v is double ? v : (v is num ? v.toDouble() : 0);

  @override
  List<Object?> get props => [
    assetId,
    name,
    bio,
    totalSupply,
    pricingMode,
    initialPriceUsdc,
  ];
}
