import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';
import 'actor_hourly_rate.dart';
import '../core/json_helpers.dart';
import '../core/story_logger.dart';

part 'drama_model.g.dart';

/// Brief actor collection info embedded in drama list item API responses.
///
/// Matches the `actorCollections` array from `/api/mini-drama/public/dramas`:
/// ```json
/// {
///   "actorCollectionId": "427626785182138368",
///   "actorCollectionName": "顾景渊",
///   "actorCollectionAvatar": "https://..."
/// }
/// ```
@JsonSerializable(explicitToJson: true)
class DramaActorCollection extends Equatable {
  @JsonKey(name: 'actorCollectionId', fromJson: asString)
  final String? id;
  @JsonKey(name: 'actorCollectionName', fromJson: asString)
  final String? name;
  @JsonKey(name: 'actorCollectionAvatar', fromJson: asString)
  final String? avatarUrl;

  /// Actor collection badge from the drama list response.
  @JsonKey(fromJson: asString)
  final String? badge;

  /// Actor collection trust score.
  @JsonKey(fromJson: asDouble)
  final double? trust;

  /// Optional hourly STORY yield when the list API includes it.
  @JsonKey(fromJson: asDouble)
  final num? storyPerHour;

  /// NFT list price from `nft.unitPrice` (or a top-level `unitPrice`).
  /// Used as the STORY/h fallback when [storyPerHour] is omitted.
  @JsonKey(fromJson: asDouble)
  final double? unitPrice;

  /// IP computing power from `computingPower`.
  /// Used as the STORY/h fallback when [storyPerHour] and [unitPrice] are omitted.
  @JsonKey(fromJson: asDouble)
  final double? computingPower;

  const DramaActorCollection({
    this.id,
    this.name,
    this.avatarUrl,
    this.badge,
    this.trust,
    this.storyPerHour,
    this.unitPrice,
    this.computingPower,
  });

  ActorHourlyRate get rate => ActorHourlyRate(
    storyPerHour: storyPerHour,
    unitPrice: unitPrice,
    computingPower: computingPower,
  );

  /// Display rate: [storyPerHour], else [unitPrice], else [computingPower].
  num? get hourlyRate => rate.value;

  /// 片酬 in STORY/h: [storyPerHour], else [computingPower].
  /// Never NFT [unitPrice] / signing list price.
  num? get payRate => rate.payValue;

  factory DramaActorCollection.fromJson(Map<String, dynamic> json) {
    final generated = _$DramaActorCollectionFromJson(json);
    final rates = ActorHourlyRate.fromJson(json);
    return DramaActorCollection(
      id: generated.id,
      name: generated.name,
      avatarUrl: generated.avatarUrl,
      badge: generated.badge,
      trust: generated.trust,
      storyPerHour: rates.storyPerHour,
      unitPrice: rates.unitPrice,
      computingPower: rates.computingPower,
    );
  }

  factory DramaActorCollection.fromBoundRole(
    RoleCharacter role, {
    DramaActorCollection? fallback,
  }) {
    final rates = role.boundRate.overlay(fallback?.rate);
    return DramaActorCollection(
      id: role.boundActorCollectionId,
      name: role.boundActorName ?? role.name,
      avatarUrl: role.boundActorAvatar,
      storyPerHour: rates.storyPerHour,
      unitPrice: rates.unitPrice,
      computingPower: rates.computingPower,
    );
  }

  Map<String, dynamic> toJson() => _$DramaActorCollectionToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    avatarUrl,
    badge,
    trust,
    storyPerHour,
    unitPrice,
    computingPower,
  ];
}

/// A role/character in a drama, optionally bound to an actor NFT collection.
/// Parsed manually from API response (not via json_serializable).
class RoleCharacter extends Equatable {
  final int? id;
  final String? name;
  final String? description;

  /// Role character avatar URL (not the bound actor IP avatar).
  final String? avatar;
  final int? sortNo;

  /// Actor name from boundActorCollection.name.
  final String? boundActorName;

  /// Actor IP avatar from boundActorCollection.
  final String? boundActorAvatar;

  /// Actor collection (NFT IP) ID from boundActorCollection. Null when the
  /// role has no bound actor IP — tapping the card is a no-op in that case.
  final String? boundActorCollectionId;

  /// Hourly STORY yield from the bound actor collection, when the API sends it.
  final num? boundActorStoryPerHour;

  /// NFT list price from `boundActorCollection.nft.unitPrice`.
  /// Used as the STORY/h fallback when [boundActorStoryPerHour] is omitted.
  final double? boundActorUnitPrice;

  /// IP computing power from `boundActorCollection.computingPower`.
  /// Used as the STORY/h fallback when [boundActorStoryPerHour] and
  /// [boundActorUnitPrice] are omitted.
  final double? boundActorComputingPower;

  const RoleCharacter({
    this.id,
    this.name,
    this.description,
    this.avatar,
    this.sortNo,
    this.boundActorName,
    this.boundActorAvatar,
    this.boundActorCollectionId,
    this.boundActorStoryPerHour,
    this.boundActorUnitPrice,
    this.boundActorComputingPower,
  });

  ActorHourlyRate get boundRate => ActorHourlyRate(
    storyPerHour: boundActorStoryPerHour,
    unitPrice: boundActorUnitPrice,
    computingPower: boundActorComputingPower,
  );

  /// Display rate: [boundActorStoryPerHour], else [boundActorUnitPrice],
  /// else [boundActorComputingPower].
  num? get boundActorHourlyRate => boundRate.value;

  /// 片酬 in STORY/h: [boundActorStoryPerHour], else [boundActorComputingPower].
  /// Never NFT [boundActorUnitPrice] / USDC list price.
  num? get boundActorPayRate => boundRate.payValue;

  /// Whether this role is bound to an actor IP (by id or name).
  bool get isBound =>
      (boundActorCollectionId != null && boundActorCollectionId!.isNotEmpty) ||
      (boundActorName != null && boundActorName!.trim().isNotEmpty);

  factory RoleCharacter.fromMap(Map<String, dynamic> json) {
    final boundRaw = json['boundActorCollection'] ?? json['boundActor'];
    final boundMap = _asStringKeyedMap(boundRaw);
    final rates = ActorHourlyRate.fromJson(boundMap);
    return RoleCharacter(
      id: asIntOrNull(json['id']),
      name: asStringOrNull(json['name']),
      description: asStringOrNull(json['description']),
      avatar: asStringOrNull(json['avatar'])?.trim(),
      sortNo: asIntOrNull(json['sortNo']),
      boundActorName: boundMap != null
          ? (asStringOrNull(boundMap['name']) ??
                    asStringOrNull(boundMap['actorCollectionName']))
                ?.trim()
          : null,
      // API sample uses `avatar`; keep older aliases as fallbacks.
      boundActorAvatar: boundMap != null
          ? (asStringOrNull(boundMap['avatar']) ??
                    asStringOrNull(boundMap['actorCollectionAvatar']) ??
                    asStringOrNull(boundMap['avatarUrl']))
                ?.trim()
          : null,
      boundActorCollectionId: boundMap != null
          ? (asStringOrNull(boundMap['actorCollectionId']) ??
                    asStringOrNull(boundMap['id']) ??
                    asStringOrNull(boundMap['actorId']) ??
                    asStringOrNull(boundMap['assetId']))
                ?.trim()
          : null,
      boundActorStoryPerHour: rates.storyPerHour,
      boundActorUnitPrice: rates.unitPrice,
      boundActorComputingPower: rates.computingPower,
    );
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'sortNo': sortNo,
    };
    if (boundActorName != null ||
        boundActorAvatar != null ||
        boundActorCollectionId != null ||
        boundActorStoryPerHour != null ||
        boundActorUnitPrice != null ||
        boundActorComputingPower != null) {
      result['boundActorCollection'] = {
        if (boundActorCollectionId != null) 'id': boundActorCollectionId,
        if (boundActorName != null) 'name': boundActorName,
        if (boundActorAvatar != null) 'avatar': boundActorAvatar,
        if (boundActorStoryPerHour != null)
          'storyPerHour': boundActorStoryPerHour,
        if (boundActorComputingPower != null)
          'computingPower': boundActorComputingPower,
        if (boundActorUnitPrice != null)
          'nft': {'unitPrice': boundActorUnitPrice},
      };
    }
    return result;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    avatar,
    sortNo,
    boundActorName,
    boundActorAvatar,
    boundActorCollectionId,
    boundActorStoryPerHour,
    boundActorUnitPrice,
    boundActorComputingPower,
  ];
}

/// 创建短剧流程中的角色 IP 绑定草稿（本地态）。
///
/// 为兼容既有草稿存储和第三步卡片仍沿用该类型；提交时只提取
/// [boundActorCollectionId]，不再序列化角色名称、简介或头像。
class DramaRoleDraft extends Equatable {
  /// 本地生成的唯一标识，用于列表定位与编辑替换。
  final String id;

  /// 角色 IP 名称，仅用于展示。
  final String name;

  /// 角色简介。
  final String bio;

  /// 已上传头像的对象存储 key；未上传时为 null。
  final String? avatarObjectKey;

  /// 本地选图路径，仅用于表单内预览，提交时不序列化。
  final String? localAvatarPath;

  /// 远程头像 URL；编辑模式回显时使用，提交时不序列化。
  final String? avatarUrl;

  /// 排序序号。
  final int sortNo;

  /// 已绑定的演员 IP（ActorCollection）id；未绑定时为 null。
  /// 创建时汇总到 `CreateDramaRequest.actorCollectionIds`；编辑时用于计算
  /// `ActorCollectionChanges` 增量。
  final String? boundActorCollectionId;

  /// 已绑定演员 IP 的名称，仅用于卡片展示。
  final String? boundActorName;

  /// 已绑定演员 IP 的头像 URL，仅用于卡片展示。
  final String? boundActorAvatarUrl;

  /// 该绑定是否来自后端 edit-session 回显。持久化绑定不可解除或更换。
  final bool actorBindingPersisted;

  const DramaRoleDraft({
    required this.id,
    required this.name,
    this.bio = '',
    this.avatarObjectKey,
    this.localAvatarPath,
    this.avatarUrl,
    this.sortNo = 0,
    this.boundActorCollectionId,
    this.boundActorName,
    this.boundActorAvatarUrl,
    this.actorBindingPersisted = false,
  });

  /// 是否已绑定演员 IP。
  bool get isActorBound =>
      boundActorCollectionId != null && boundActorCollectionId!.isNotEmpty;

  DramaRoleDraft copyWith({
    String? name,
    String? bio,
    String? avatarObjectKey,
    String? localAvatarPath,
    String? avatarUrl,
    int? sortNo,
    String? boundActorCollectionId,
    String? boundActorName,
    String? boundActorAvatarUrl,
    bool? actorBindingPersisted,
    bool clearBoundActor = false,
  }) {
    return DramaRoleDraft(
      id: id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarObjectKey: avatarObjectKey ?? this.avatarObjectKey,
      localAvatarPath: localAvatarPath ?? this.localAvatarPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      sortNo: sortNo ?? this.sortNo,
      boundActorCollectionId: clearBoundActor
          ? null
          : (boundActorCollectionId ?? this.boundActorCollectionId),
      boundActorName: clearBoundActor
          ? null
          : (boundActorName ?? this.boundActorName),
      boundActorAvatarUrl: clearBoundActor
          ? null
          : (boundActorAvatarUrl ?? this.boundActorAvatarUrl),
      actorBindingPersisted:
          actorBindingPersisted ?? this.actorBindingPersisted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    bio,
    avatarObjectKey,
    localAvatarPath,
    avatarUrl,
    sortNo,
    boundActorCollectionId,
    boundActorName,
    boundActorAvatarUrl,
    actorBindingPersisted,
  ];
}

@JsonSerializable(explicitToJson: true)
class DramaListItem extends Equatable {
  @JsonKey(name: 'dramaId', fromJson: asStringRequired)
  final String id;
  @JsonKey(fromJson: asString)
  final String? episodeId;
  @JsonKey(fromJson: asInt)
  final int? episodeNo;
  final String? dramaTitle;
  final String? dramaDescription;
  final String? dramaCoverUrl;
  final List<String>? tags;
  final String? creatorName;

  /// Content badge: OFFICIAL / COMMUNITY / PARTNER / VERIFIED.
  final String? badge;
  final String? type;
  @JsonKey(fromJson: asInt)
  final int? durationSec;
  @JsonKey(fromJson: asDouble)
  final double? avgRating;
  @JsonKey(fromJson: asInt)
  final int? totalEpisodes;
  @JsonKey(fromJson: asInt)
  final int? totalPlayCount;
  @JsonKey(fromJson: asInt)
  final int? totalCompletedViewCount;
  @JsonKey(fromJson: asDouble)
  final double? totalHeatValue;
  @JsonKey(fromJson: asInt)
  final int? likeCount;
  @JsonKey(fromJson: asInt)
  final int? favoriteCount;
  final List<DramaActorCollection>? actorCollections;

  const DramaListItem({
    required this.id,
    this.episodeId,
    this.episodeNo,
    this.dramaTitle,
    this.dramaDescription,
    this.dramaCoverUrl,
    this.tags,
    this.creatorName,
    this.badge,
    this.type,
    this.durationSec,
    this.avgRating,
    this.totalEpisodes,
    this.totalPlayCount,
    this.totalCompletedViewCount,
    this.totalHeatValue,
    this.likeCount,
    this.favoriteCount,
    this.actorCollections,
  });

  factory DramaListItem.fromJson(Map<String, dynamic> json) =>
      _$DramaListItemFromJson(json);

  Map<String, dynamic> toJson() => _$DramaListItemToJson(this);

  @override
  List<Object?> get props => [
    id,
    episodeId,
    episodeNo,
    dramaTitle,
    dramaDescription,
    dramaCoverUrl,
    tags,
    creatorName,
    badge,
    type,
    durationSec,
    avgRating,
    totalEpisodes,
    totalPlayCount,
    totalCompletedViewCount,
    totalHeatValue,
    likeCount,
    favoriteCount,
    actorCollections,
  ];
}

@JsonSerializable()
class DramaDetail extends Equatable {
  @JsonKey(fromJson: asString)
  final String? id;
  @JsonKey(fromJson: asString)
  final String? userId;
  final String? title;
  final String? description;
  final String? coverUrl;
  final String? bannerUrl;
  @JsonKey(fromJson: asInt)
  final int? freeEps;
  @JsonKey(fromJson: asInt)
  final int? totalEpisodes;
  @JsonKey(fromJson: asInt)
  final int? totalRoles;
  @JsonKey(fromJson: asDouble)
  final double? episodePrice;
  @JsonKey(fromJson: asDouble)
  final double? batchUnlockDiscountRate;
  @JsonKey(fromJson: asDouble)
  final double? dramaCommissionRatio;
  @JsonKey(fromJson: asInt)
  final int? totalBoundActorNftCount;
  @JsonKey(fromJson: asDouble)
  final double? totalBoundActorRevenueShareRatio;
  final String? status;
  final String? auditReason;
  @JsonKey(fromJson: asInt)
  final int? onlineAt;
  @JsonKey(fromJson: asInt)
  final int? offlineAt;
  @JsonKey(fromJson: asBool)
  final bool? nftMinted;
  final String? nftChain;
  final String? nftTokenStandard;
  final String? nftContractAddress;
  final String? nftTxHash;
  @JsonKey(fromJson: asInt)
  final int? createdAt;
  @JsonKey(fromJson: asInt)
  final int? updatedAt;
  @JsonKey(fromJson: asInt)
  final int? version;
  @JsonKey(fromJson: asInt)
  final int? unlockedEpsCount;
  @JsonKey(fromJson: asInt)
  final int? totalPlayCount;
  @JsonKey(fromJson: asInt)
  final int? totalCompletedViewCount;
  @JsonKey(fromJson: asDouble)
  final double? totalHeatValue;

  final List<String>? tags;
  final String? creatorName;

  /// Creator profile avatar from `dramaInfo.creator.avatarUrl`.
  final String? creatorAvatarUrl;

  /// Content badge: OFFICIAL / COMMUNITY / PARTNER / VERIFIED.
  final String? badge;
  @JsonKey(fromJson: asDouble)
  final double? avgRating;
  @JsonKey(fromJson: asInt)
  final int? favoriteCount;

  /// Whole-series favorite from `dramaInfo.favoritedByMe` (null when anonymous).
  @JsonKey(fromJson: asBool)
  final bool? favoritedByMe;

  @JsonKey(fromJson: _parseRoles, toJson: _serializeRoles)
  final List<RoleCharacter>? roles;

  const DramaDetail({
    this.id,
    this.userId,
    this.title,
    this.description,
    this.coverUrl,
    this.bannerUrl,
    this.freeEps,
    this.totalEpisodes,
    this.totalRoles,
    this.episodePrice,
    this.batchUnlockDiscountRate,
    this.dramaCommissionRatio,
    this.totalBoundActorNftCount,
    this.totalBoundActorRevenueShareRatio,
    this.status,
    this.auditReason,
    this.onlineAt,
    this.offlineAt,
    this.nftMinted,
    this.nftChain,
    this.nftTokenStandard,
    this.nftContractAddress,
    this.nftTxHash,
    this.createdAt,
    this.updatedAt,
    this.version,
    this.unlockedEpsCount,
    this.totalPlayCount,
    this.totalCompletedViewCount,
    this.totalHeatValue,
    this.tags,
    this.creatorName,
    this.creatorAvatarUrl,
    this.badge,
    this.avgRating,
    this.favoriteCount,
    this.favoritedByMe,
    this.roles,
  });

  static List<RoleCharacter>? _parseRoles(List<dynamic>? list) {
    if (list == null) return null;
    return list
        .map((e) {
          if (e is Map<String, dynamic>) return RoleCharacter.fromMap(e);
          if (e is Map) {
            return RoleCharacter.fromMap(
              e.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
          return null;
        })
        .whereType<RoleCharacter>()
        .toList();
  }

  static List<Map<String, dynamic>>? _serializeRoles(
    List<RoleCharacter>? roles,
  ) {
    return roles?.map((r) => r.toMap()).toList();
  }

  factory DramaDetail.fromJson(Map<String, dynamic> json) =>
      _$DramaDetailFromJson(json);

  /// Decodes a raw API response that nests drama data under [dramaInfo] and
  /// [playbackRule] sub-objects, flattening and merging them before delegating
  /// to [fromJson].
  factory DramaDetail.fromNestedJson(dynamic raw) {
    // Inline normalizer: safe cast to Map, falling back to empty.
    Map<String, dynamic> n(dynamic d) =>
        d is Map<String, dynamic> ? d : <String, dynamic>{};

    final map = n(raw);
    final info = n(map['dramaInfo']);
    final rule = n(map['playbackRule']);

    // Debug: log available keys for troubleshooting
    try {
      StoryLogger.d(
        'fromNestedJson: rawKeys=${map.keys.join(",")} '
        'infoKeys=${info.keys.join(",")} '
        'hasDesc=${info.containsKey("desc")} '
        'hasDescription=${info.containsKey("description")} '
        'hasRoles=${info.containsKey("roles")} '
        'hasActorCollections=${map.containsKey("actorCollections")}',
        tag: 'DramaModel',
      );
    } catch (e) {
      StoryLogger.d(
        'fromNestedJson debug info parse failed',
        error: e,
        tag: 'DramaModel',
      );
    }
    final nft = n(info['nft']);
    final creator = n(info['creator']);

    final legacyRoles = info['roles'] ?? map['roles'];
    final actorCollections =
        info['actorCollections'] ?? map['actorCollections'];
    final rolesList = legacyRoles is List
        ? legacyRoles
        : _rolesFromActorCollections(actorCollections);
    int boundCount = 0;
    if (rolesList is List) {
      for (final r in rolesList) {
        if (r is Map &&
            (r['boundActorCollection'] != null || r['boundActor'] != null)) {
          boundCount++;
        }
      }
    }

    return DramaDetail.fromJson(<String, dynamic>{
      ...map,
      ...info,
      ...rule,
      'description':
          info['description'] ??
          info['desc'] ??
          info['synopsis'] ??
          info['dramaDescription'] ??
          map['description'] ??
          map['dramaDescription'],
      'coverUrl': info['coverImg'] ?? info['coverUrl'] ?? map['coverUrl'],
      'episodePrice':
          rule['priceUsdtPerEp'] ?? rule['episodePrice'] ?? map['episodePrice'],
      'nftMinted': info['nft'] != null || map['nftMinted'] == true,
      'nftChain': nft['chain'] ?? info['nftChain'] ?? map['nftChain'],
      'nftTokenStandard':
          nft['tokenStandard'] ??
          info['nftTokenStandard'] ??
          map['nftTokenStandard'],
      'nftContractAddress':
          nft['mintAddress'] ??
          nft['contractAddress'] ??
          info['nftContractAddress'] ??
          map['nftContractAddress'],
      'nftTxHash': nft['txHash'] ?? info['nftTxHash'] ?? map['nftTxHash'],
      'totalRoles': rolesList is List
          ? rolesList.length
          : (info['totalRoles'] ?? map['totalRoles']),
      'totalBoundActorNftCount': boundCount > 0
          ? boundCount
          : (info['totalBoundActorNftCount'] ?? map['totalBoundActorNftCount']),
      'userId':
          info['userId'] ?? map['userId'] ?? creator['userId']?.toString(),
      'creatorName':
          info['creatorName'] ??
          creator['nickname'] ??
          creator['userName'] ??
          map['creatorName'],
      'creatorAvatarUrl':
          info['creatorAvatarUrl'] ??
          creator['avatarUrl'] ??
          creator['avatar'] ??
          map['creatorAvatarUrl'],
      'roles': rolesList is List ? rolesList : null,
      'totalPlayCount':
          info['totalPlayCount'] ??
          info['playCount'] ??
          map['totalPlayCount'] ??
          map['playCount'],
      'totalCompletedViewCount':
          info['totalCompletedViewCount'] ??
          info['completedViewCount'] ??
          map['totalCompletedViewCount'] ??
          map['completedViewCount'],
      'totalHeatValue':
          info['totalHeatValue'] ??
          info['heatValue'] ??
          map['totalHeatValue'] ??
          map['heatValue'],
    });
  }

  /// v0828 将详情响应中的 `roles` 替换为顶层 `actorCollections`。
  ///
  /// App 下游仍以 [RoleCharacter] 渲染演员区，因此在 API 边界把新结构归一化
  /// 为旧展示结构；这里只做展示适配，不会重新引入旧的角色提交契约。
  static List<Map<String, dynamic>>? _rolesFromActorCollections(dynamic raw) {
    if (raw is! List) return null;
    return [
      for (var i = 0; i < raw.length; i++)
        if (raw[i] is Map)
          _roleFromActorCollection(
            (raw[i] as Map).map(
              (key, dynamic value) => MapEntry(key.toString(), value),
            ),
            i,
          ),
    ];
  }

  static Map<String, dynamic> _roleFromActorCollection(
    Map<String, dynamic> actor,
    int index,
  ) {
    final id = actor['id'] ?? actor['actorCollectionId'];
    final name = actor['name'] ?? actor['actorCollectionName'];
    final avatar = actor['avatar'] ?? actor['actorCollectionAvatar'];
    return <String, dynamic>{
      'name': name,
      'avatar': avatar,
      'sortNo': index,
      'boundActorCollection': <String, dynamic>{
        'id': id,
        'name': name,
        'avatar': avatar,
        if (actor['computingPower'] != null)
          'computingPower': actor['computingPower'],
        if (actor['nft'] != null) 'nft': actor['nft'],
      },
    };
  }

  Map<String, dynamic> toJson() => _$DramaDetailToJson(this);

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    description,
    coverUrl,
    bannerUrl,
    freeEps,
    totalEpisodes,
    totalRoles,
    episodePrice,
    batchUnlockDiscountRate,
    dramaCommissionRatio,
    totalBoundActorNftCount,
    totalBoundActorRevenueShareRatio,
    status,
    auditReason,
    onlineAt,
    offlineAt,
    nftMinted,
    nftChain,
    nftTokenStandard,
    nftContractAddress,
    nftTxHash,
    createdAt,
    updatedAt,
    version,
    unlockedEpsCount,
    totalPlayCount,
    totalCompletedViewCount,
    totalHeatValue,
    tags,
    creatorName,
    creatorAvatarUrl,
    badge,
    avgRating,
    favoriteCount,
    favoritedByMe,
    roles,
  ];
}
