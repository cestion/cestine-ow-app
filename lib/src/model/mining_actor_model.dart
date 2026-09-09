import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'mining_actor_model.g.dart';

/// 挖矿演员算力明细，对齐 mining OpenAPI `Memo`。
@JsonSerializable()
class MiningActorMemo extends Equatable {
  /// Initial price multiplier (价格系数)。
  @JsonKey(fromJson: asDouble)
  final double? p0;

  /// 热度系数。
  @JsonKey(fromJson: asDouble)
  final double? heat;

  /// actor IP trust (Trust1)。
  @JsonKey(fromJson: asDouble)
  final double? trust1;

  /// user trust (Trust2)。
  @JsonKey(fromJson: asDouble)
  final double? trust2;

  /// CP 系数。
  @JsonKey(name: 'CP', fromJson: asDouble)
  final double? cp;

  /// Mining Coefficient（拆解优先取此字段，再回退根级 miningCoefficient）。
  @JsonKey(name: 'MC', fromJson: asDouble)
  final double? mc;

  const MiningActorMemo({
    this.p0,
    this.heat,
    this.trust1,
    this.trust2,
    this.cp,
    this.mc,
  });

  factory MiningActorMemo.fromJson(Map<String, dynamic> json) =>
      _$MiningActorMemoFromJson(json);

  Map<String, dynamic> toJson() => _$MiningActorMemoToJson(this);

  @override
  List<Object?> get props => [p0, heat, trust1, trust2, cp, mc];
}

MiningActorMemo? _memoFromJson(dynamic value) {
  if (value is Map<String, dynamic>) {
    return MiningActorMemo.fromJson(value);
  }
  if (value is Map) {
    return MiningActorMemo.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

Object? _memoToJson(MiningActorMemo? memo) => memo?.toJson();

/// 挖矿演员 DTO，与 web `ActorDTO` 对齐。
@JsonSerializable()
class MiningActor extends Equatable {
  final String? actorName;
  @JsonKey(fromJson: asString)
  final String? actorNftId;
  @JsonKey(fromJson: asInt)
  final int? actorCollectionId;
  @JsonKey(fromJson: asInt)
  final int? level;
  @JsonKey(fromJson: asDouble)
  final double? heat;

  /// Actor/role computing power from mining API.
  @JsonKey(fromJson: asDouble)
  final double? computingPower;
  @JsonKey(fromJson: asDouble)
  final double? miningCoefficient;

  /// Optional breakdown fields when backend expands the DTO (legacy flat).
  @JsonKey(fromJson: asDouble)
  final double? priceCoefficient;
  @JsonKey(fromJson: asDouble)
  final double? ipPower;
  @JsonKey(fromJson: asDouble)
  final double? trust1;
  @JsonKey(fromJson: asDouble)
  final double? trust2;
  @JsonKey(fromJson: asDouble)
  final double? trust;
  @JsonKey(fromJson: asDouble)
  final double? cpCoefficient;

  /// 算力拆解明细（OpenAPI `memo`）。
  @JsonKey(fromJson: _memoFromJson, toJson: _memoToJson)
  final MiningActorMemo? memo;

  /// `MINING` | `REST`
  final String? status;
  @JsonKey(fromJson: asDouble)
  final double? weeklyNominalOutput;
  @JsonKey(fromJson: asInt)
  final int? stamina;
  final String? avatarUrl;
  @JsonKey(fromJson: asInt)
  final int? completedPlayCount;
  @JsonKey(fromJson: asInt)
  final int? materialCount;
  @JsonKey(fromJson: asBool)
  final bool? completePlayThresholdMet;
  @JsonKey(fromJson: asInt)
  final int? actorTokenId;

  const MiningActor({
    this.actorName,
    this.actorNftId,
    this.actorCollectionId,
    this.level,
    this.heat,
    this.computingPower,
    this.miningCoefficient,
    this.priceCoefficient,
    this.ipPower,
    this.trust1,
    this.trust2,
    this.trust,
    this.cpCoefficient,
    this.memo,
    this.status,
    this.weeklyNominalOutput,
    this.stamina,
    this.avatarUrl,
    this.completedPlayCount,
    this.materialCount,
    this.completePlayThresholdMet,
    this.actorTokenId,
  });

  MiningActor copyWith({
    String? actorName,
    String? actorNftId,
    int? actorCollectionId,
    int? level,
    double? heat,
    double? computingPower,
    double? miningCoefficient,
    double? priceCoefficient,
    double? ipPower,
    double? trust1,
    double? trust2,
    double? trust,
    double? cpCoefficient,
    MiningActorMemo? memo,
    String? status,
    double? weeklyNominalOutput,
    int? stamina,
    String? avatarUrl,
    int? completedPlayCount,
    int? materialCount,
    bool? completePlayThresholdMet,
    int? actorTokenId,
  }) {
    return MiningActor(
      actorName: actorName ?? this.actorName,
      actorNftId: actorNftId ?? this.actorNftId,
      actorCollectionId: actorCollectionId ?? this.actorCollectionId,
      level: level ?? this.level,
      heat: heat ?? this.heat,
      computingPower: computingPower ?? this.computingPower,
      miningCoefficient: miningCoefficient ?? this.miningCoefficient,
      priceCoefficient: priceCoefficient ?? this.priceCoefficient,
      ipPower: ipPower ?? this.ipPower,
      trust1: trust1 ?? this.trust1,
      trust2: trust2 ?? this.trust2,
      trust: trust ?? this.trust,
      cpCoefficient: cpCoefficient ?? this.cpCoefficient,
      memo: memo ?? this.memo,
      status: status ?? this.status,
      weeklyNominalOutput: weeklyNominalOutput ?? this.weeklyNominalOutput,
      stamina: stamina ?? this.stamina,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      completedPlayCount: completedPlayCount ?? this.completedPlayCount,
      materialCount: materialCount ?? this.materialCount,
      completePlayThresholdMet:
          completePlayThresholdMet ?? this.completePlayThresholdMet,
      actorTokenId: actorTokenId ?? this.actorTokenId,
    );
  }

  factory MiningActor.fromJson(Map<String, dynamic> json) =>
      _$MiningActorFromJson(json);

  Map<String, dynamic> toJson() => _$MiningActorToJson(this);

  bool get isMining => status?.toUpperCase() == 'MINING';

  bool get isRest => !isMining;

  String get displayName => actorName?.trim() ?? '';

  String get nftId => actorNftId?.trim() ?? '';

  String? get actorCode => actorTokenId != null ? '#$actorTokenId' : null;

  double get weeklyOutput => weeklyNominalOutput ?? 0;

  double? staminaProgress(int limit) {
    if (limit <= 0 || stamina == null) return null;
    return (stamina! / limit).clamp(0.0, 1.0);
  }

  bool isStaminaFull(int limit) =>
      stamina != null && limit > 0 && stamina! >= limit;

  @override
  List<Object?> get props => [
    actorName,
    actorNftId,
    actorCollectionId,
    level,
    heat,
    computingPower,
    miningCoefficient,
    priceCoefficient,
    ipPower,
    trust1,
    trust2,
    trust,
    cpCoefficient,
    memo,
    status,
    weeklyNominalOutput,
    stamina,
    avatarUrl,
    completedPlayCount,
    materialCount,
    completePlayThresholdMet,
    actorTokenId,
  ];
}

/// 分页响应，与 web `PageActorDTO` 对齐（字段 `records`）。
class MiningActorPage {
  final List<MiningActor> records;
  final int pageNumber;
  final int pageSize;
  final int totalPage;
  final int totalRow;

  const MiningActorPage({
    this.records = const [],
    this.pageNumber = 1,
    this.pageSize = 0,
    this.totalPage = 0,
    this.totalRow = 0,
  });

  bool get hasMore => pageNumber < totalPage && totalPage > 0;
}
