import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'actor_vault_ranking_item_model.g.dart';

/// 与 web `ActorVaultRankingItemDTO` 对齐：演员金库排行榜单条记录。
@JsonSerializable(explicitToJson: true)
class ActorVaultRankingItem extends Equatable {
  @JsonKey(fromJson: asInt)
  final int? rank;
  final String? actorName;
  final String? number;
  final String? actorId;
  @JsonKey(fromJson: asDouble)
  final double? vault;

  const ActorVaultRankingItem({
    this.rank,
    this.actorName,
    this.number,
    this.actorId,
    this.vault,
  });

  factory ActorVaultRankingItem.fromJson(Map<String, dynamic> json) =>
      _$ActorVaultRankingItemFromJson(json);

  Map<String, dynamic> toJson() => _$ActorVaultRankingItemToJson(this);

  @override
  List<Object?> get props => [rank, actorName, number, actorId, vault];
}
