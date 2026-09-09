import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'reward_detail_model.g.dart';

/// 与 web `RewardDetailDTOType` 对齐：奖励类型枚举。
@JsonEnum(alwaysCreate: true)
enum RewardDetailType {
  @JsonValue('MINING')
  mining,
  @JsonValue('INVITE')
  invite;

  static RewardDetailType? fromString(String? v) {
    if (v == null) return null;
    final s = v.toUpperCase();
    if (s == 'MINING') return RewardDetailType.mining;
    if (s == 'INVITE') return RewardDetailType.invite;
    return null;
  }

  String get queryString => switch (this) {
    RewardDetailType.mining => 'MINING',
    RewardDetailType.invite => 'INVITE',
  };
}

/// 与 web `ListRewardDetailsParams.type` 对齐：ALL / MINING / INVITE。
enum ListRewardDetailsFilter {
  all,
  mining,
  invite;

  String get queryString => switch (this) {
    ListRewardDetailsFilter.all => 'ALL',
    ListRewardDetailsFilter.mining => 'MINING',
    ListRewardDetailsFilter.invite => 'INVITE',
  };
}

/// 与 web `RewardDetailDTO` 对齐：单条 STORY 奖励明细。
@JsonSerializable(explicitToJson: true)
class RewardDetail extends Equatable {
  final String? rewardTime;
  final RewardDetailType? type;
  final String? rewardPeriodStart;
  final String? rewardPeriodEnd;
  @JsonKey(fromJson: asString)
  final String? sourceUser;
  final String? sourceUserName;
  @JsonKey(fromJson: asDouble)
  final double? storyAmount;

  const RewardDetail({
    this.rewardTime,
    this.type,
    this.rewardPeriodStart,
    this.rewardPeriodEnd,
    this.sourceUser,
    this.sourceUserName,
    this.storyAmount,
  });

  factory RewardDetail.fromJson(Map<String, dynamic> json) =>
      _$RewardDetailFromJson(json);

  Map<String, dynamic> toJson() => _$RewardDetailToJson(this);

  @override
  List<Object?> get props => [
    rewardTime,
    type,
    rewardPeriodStart,
    rewardPeriodEnd,
    sourceUser,
    sourceUserName,
    storyAmount,
  ];
}

/// 与 web `CursorPageResponseRewardDetailDTO` 对齐：STORY 奖励明细分页响应。
@JsonSerializable(explicitToJson: true)
class RewardDetailPage extends Equatable {
  final String? pageSize;
  final String? mark;
  final bool? hasMore;
  final List<RewardDetail>? list;

  const RewardDetailPage({this.pageSize, this.mark, this.hasMore, this.list});

  factory RewardDetailPage.fromJson(Map<String, dynamic> json) =>
      _$RewardDetailPageFromJson(json);

  Map<String, dynamic> toJson() => _$RewardDetailPageToJson(this);

  @override
  List<Object?> get props => [pageSize, mark, hasMore, list];
}
