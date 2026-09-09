import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'mini_drama_config_model.g.dart';

/// `mini-drama` section of `/api/admin/v1/configs/keys/...`.
///
/// Note: this section returns snake_case JSON keys (e.g. `rebate_tiers`),
/// unlike the rest of the payload which uses camelCase.
@JsonSerializable()
class MiniDramaConfig extends Equatable {
  @JsonKey(name: 'rebate_tiers')
  final List<RebateTier>? rebateTiers;

  @JsonKey(name: 'creator_rate_max', fromJson: asDouble)
  final double? creatorRateMax;

  @JsonKey(name: 'default_creator_rate', fromJson: asDouble)
  final double? defaultCreatorRate;

  @JsonKey(name: 'self_reward_usdt_rate', fromJson: asDouble)
  final double? selfRewardUsdtRate;

  @JsonKey(name: 'usdt_to_points_rate', fromJson: asInt)
  final int? usdtToPointsRate;

  @JsonKey(name: 'point_cost_per_episode', fromJson: asInt)
  final int? pointCostPerEpisode;

  @JsonKey(name: 'bulk_unlock_discount_rate', fromJson: asDouble)
  final double? bulkUnlockDiscountRate;

  const MiniDramaConfig({
    this.rebateTiers,
    this.creatorRateMax,
    this.defaultCreatorRate,
    this.selfRewardUsdtRate,
    this.usdtToPointsRate,
    this.pointCostPerEpisode,
    this.bulkUnlockDiscountRate,
  });

  factory MiniDramaConfig.fromJson(Map<String, dynamic> json) =>
      _$MiniDramaConfigFromJson(json);

  Map<String, dynamic> toJson() => _$MiniDramaConfigToJson(this);

  @override
  List<Object?> get props => [
    rebateTiers,
    creatorRateMax,
    defaultCreatorRate,
    selfRewardUsdtRate,
    usdtToPointsRate,
    pointCostPerEpisode,
    bulkUnlockDiscountRate,
  ];
}

/// A single rebate tier. `endEpisode` may be `null` meaning "open-ended".
@JsonSerializable()
class RebateTier extends Equatable {
  @JsonKey(name: 'start_episode', fromJson: asInt)
  final int? startEpisode;

  @JsonKey(name: 'end_episode')
  final int? endEpisode;

  @JsonKey(name: 'direct_inviter_rate', fromJson: asDouble)
  final double? directInviterRate;

  @JsonKey(name: 'indirect_inviter_rate', fromJson: asDouble)
  final double? indirectInviterRate;

  const RebateTier({
    this.startEpisode,
    this.endEpisode,
    this.directInviterRate,
    this.indirectInviterRate,
  });

  factory RebateTier.fromJson(Map<String, dynamic> json) =>
      _$RebateTierFromJson(json);

  Map<String, dynamic> toJson() => _$RebateTierToJson(this);

  /// Whether this tier covers an open-ended range starting at [startEpisode].
  bool get isOpenEnded => endEpisode == null;

  @override
  List<Object?> get props => [
    startEpisode,
    endEpisode,
    directInviterRate,
    indirectInviterRate,
  ];
}
