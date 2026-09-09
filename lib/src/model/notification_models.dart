import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/story_logger.dart';
import 'follow_models.dart';
import 'json_converters.dart';

part 'notification_models.g.dart';

/// 删除站内通知请求。
@JsonSerializable()
class NotificationDeleteRequest extends Equatable {
  /// 通知 ID。
  final int id;

  const NotificationDeleteRequest({required this.id});

  factory NotificationDeleteRequest.fromJson(Map<String, dynamic> json) =>
      _$NotificationDeleteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationDeleteRequestToJson(this);

  @override
  List<Object?> get props => [id];
}

/// 标记站内通知已读请求；[ids] 与 [tab] 二选一。
@JsonSerializable(includeIfNull: false)
class NotificationReadRequest extends Equatable {
  /// 按通知 ID 精确置为已读。
  final List<int>? ids;

  /// 按 Tab 全部置为已读：1-收益，2-互动。
  final int? tab;

  const NotificationReadRequest({this.ids, this.tab});

  factory NotificationReadRequest.fromJson(Map<String, dynamic> json) =>
      _$NotificationReadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationReadRequestToJson(this);

  @override
  List<Object?> get props => [ids, tab];
}

/// 站内通知列表查询参数。
@JsonSerializable(includeIfNull: false)
class NotificationListRequest extends Equatable {
  /// 子筛选类型（如 `LIKE`）；不传表示当前 Tab 的全部通知。
  final String? eventType;

  /// 下一页游标，首屏传 0。
  @JsonKey(fromJson: asInt)
  final int? mark;

  /// 每页数量。
  @JsonKey(fromJson: asInt)
  final int? pageSize;

  /// 通知 Tab：1-收益，2-互动。
  @JsonKey(fromJson: asInt)
  final int? tab;

  const NotificationListRequest({
    this.eventType,
    this.mark,
    this.pageSize,
    this.tab,
  });

  factory NotificationListRequest.fromJson(Map<String, dynamic> json) =>
      _$NotificationListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationListRequestToJson(this);

  @override
  List<Object?> get props => [eventType, mark, pageSize, tab];
}

/// 站内通知游标分页结果。
@JsonSerializable(explicitToJson: true)
class NotificationPage extends Equatable {
  /// 是否还有更多数据。
  @JsonKey(fromJson: asBool)
  final bool? hasMore;

  /// 当前页通知。
  final List<NotificationItem>? list;

  /// 下一页游标，`-1` 表示没有更多数据。
  @JsonKey(fromJson: asString)
  final String? mark;

  /// 每页数量。
  @JsonKey(fromJson: asInt)
  final int? pageSize;

  const NotificationPage({this.hasMore, this.list, this.mark, this.pageSize});

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      _$NotificationPageFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPageToJson(this);

  @override
  List<Object?> get props => [hasMore, list, mark, pageSize];
}

/// 站内通知类型。
enum NotificationEventType {
  ipSign,
  showReward,
  staminaLow,
  like,
  favorite,
  comment,
  follow,
  unknown;

  static NotificationEventType fromWire(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return switch (normalized) {
      'IP_SIGN' => ipSign,
      'SHOW_REWARD' => showReward,
      'STAMINA_LOW' => staminaLow,
      'LIKE' || 'LIKE_VIDEO' || 'LIKE_DRAMA' => like,
      'FAVORITE' ||
      'FAVORITE_VIDEO' ||
      'FAVORITE_DRAMA' ||
      'COLLECT' ||
      'COLLECT_VIDEO' ||
      'COLLECT_DRAMA' => favorite,
      'COMMENT' => comment,
      'FOLLOW' => follow,
      _ => unknown,
    };
  }

  String get wireValue => switch (this) {
    ipSign => 'IP_SIGN',
    showReward => 'SHOW_REWARD',
    staminaLow => 'STAMINA_LOW',
    like => 'LIKE',
    favorite => 'FAVORITE',
    comment => 'COMMENT',
    follow => 'FOLLOW',
    unknown => 'UNKNOWN',
  };

  bool get isInteraction => switch (this) {
    like || favorite || comment || follow => true,
    _ => false,
  };
}

/// 类型专属的通知载荷。
///
/// 使用 sealed class 使 UI 能通过穷尽 switch 处理新通知类型。
sealed class NotificationData extends Equatable {
  const NotificationData();

  static NotificationData fromJson(
    NotificationEventType eventType,
    String? rawEventType,
    Map<String, dynamic> json,
  ) {
    return switch (eventType) {
      NotificationEventType.ipSign => IpSignNotificationData.fromJson(json),
      NotificationEventType.showReward => ShowRewardNotificationData.fromJson(
        json,
      ),
      NotificationEventType.staminaLow => StaminaLowNotificationData.fromJson(
        json,
      ),
      NotificationEventType.like || NotificationEventType.favorite =>
        TargetInteractionNotificationData.fromJson(json),
      NotificationEventType.comment => CommentNotificationData.fromJson(json),
      NotificationEventType.follow => FollowNotificationData.fromJson(json),
      NotificationEventType.unknown => UnknownNotificationData(
        rawEventType: rawEventType,
        rawData: json,
      ),
    };
  }

  Map<String, dynamic> toJson();
}

@JsonSerializable()
final class IpSignNotificationData extends NotificationData {
  @JsonKey(fromJson: asString)
  final String? behaviorId;

  @JsonKey(fromJson: asString)
  final String? objectId;

  final String? ipName;
  final String? ipAvatarUrl;

  @JsonKey(fromJson: asString)
  final String? amount;

  final String? assetCode;

  const IpSignNotificationData({
    this.behaviorId,
    this.objectId,
    this.ipName,
    this.ipAvatarUrl,
    this.amount,
    this.assetCode,
  });

  factory IpSignNotificationData.fromJson(Map<String, dynamic> json) =>
      _$IpSignNotificationDataFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$IpSignNotificationDataToJson(this);

  @override
  List<Object?> get props => [
    behaviorId,
    objectId,
    ipName,
    ipAvatarUrl,
    amount,
    assetCode,
  ];
}

@JsonSerializable()
final class ShowRewardNotificationData extends NotificationData {
  @JsonKey(fromJson: asString)
  final String? behaviorId;

  @JsonKey(fromJson: asString)
  final String? objectId;

  @JsonKey(fromJson: asString)
  final String? amount;

  final String? assetCode;

  @JsonKey(fromJson: asString)
  final String? periodStart;

  @JsonKey(fromJson: asString)
  final String? periodEnd;

  const ShowRewardNotificationData({
    this.behaviorId,
    this.objectId,
    this.amount,
    this.assetCode,
    this.periodStart,
    this.periodEnd,
  });

  factory ShowRewardNotificationData.fromJson(Map<String, dynamic> json) =>
      _$ShowRewardNotificationDataFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ShowRewardNotificationDataToJson(this);

  @override
  List<Object?> get props => [
    behaviorId,
    objectId,
    amount,
    assetCode,
    periodStart,
    periodEnd,
  ];
}

@JsonSerializable()
final class StaminaLowNotificationData extends NotificationData {
  @JsonKey(fromJson: asString)
  final String? behaviorId;

  @JsonKey(fromJson: asString)
  final String? objectId;

  final String? ipName;
  final String? ipAvatarUrl;

  @JsonKey(fromJson: asInt)
  final int? stamina;

  const StaminaLowNotificationData({
    this.behaviorId,
    this.objectId,
    this.ipName,
    this.ipAvatarUrl,
    this.stamina,
  });

  factory StaminaLowNotificationData.fromJson(Map<String, dynamic> json) =>
      _$StaminaLowNotificationDataFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StaminaLowNotificationDataToJson(this);

  @override
  List<Object?> get props => [
    behaviorId,
    objectId,
    ipName,
    ipAvatarUrl,
    stamina,
  ];
}

/// LIKE 与 FAVORITE 共用的目标载荷。
@JsonSerializable()
final class TargetInteractionNotificationData extends NotificationData {
  @JsonKey(fromJson: asString)
  final String? behaviorId;

  @JsonKey(fromJson: asString)
  final String? objectId;

  final String? targetType;
  final String? targetName;
  final String? coverUrl;

  const TargetInteractionNotificationData({
    this.behaviorId,
    this.objectId,
    this.targetType,
    this.targetName,
    this.coverUrl,
  });

  factory TargetInteractionNotificationData.fromJson(
    Map<String, dynamic> json,
  ) => _$TargetInteractionNotificationDataFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$TargetInteractionNotificationDataToJson(this);

  bool get isDrama => targetType?.trim().toLowerCase() == 'drama';

  @override
  List<Object?> get props => [
    behaviorId,
    objectId,
    targetType,
    targetName,
    coverUrl,
  ];
}

@JsonSerializable()
final class CommentNotificationData extends NotificationData {
  @JsonKey(fromJson: asString)
  final String? behaviorId;

  @JsonKey(fromJson: asString)
  final String? objectId;

  final String? targetType;
  final String? content;
  final String? targetName;
  final String? coverUrl;

  const CommentNotificationData({
    this.behaviorId,
    this.objectId,
    this.targetType,
    this.content,
    this.targetName,
    this.coverUrl,
  });

  factory CommentNotificationData.fromJson(Map<String, dynamic> json) {
    return _$CommentNotificationDataFromJson(<String, dynamic>{
      ...json,
      'behaviorId': json['commentId'] ?? json['behaviorId'],
      'objectId': json['objectId'] ?? json['episodeId'] ?? json['videoId'],
      'content': json['content'] ?? json['commentContent'],
      'targetName':
          json['targetName'] ?? json['videoTitle'] ?? json['dramaTitle'],
      'coverUrl':
          json['coverUrl'] ?? json['videoCoverUrl'] ?? json['dramaCoverUrl'],
    });
  }

  @override
  Map<String, dynamic> toJson() => _$CommentNotificationDataToJson(this);

  @override
  List<Object?> get props => [
    behaviorId,
    objectId,
    targetType,
    content,
    targetName,
    coverUrl,
  ];
}

FollowRelationStatus? _followRelationStatusFromJson(Object? value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return FollowRelationStatus.fromApi(raw);
}

String? _followRelationStatusToJson(FollowRelationStatus? value) =>
    value?.apiValue;

@JsonSerializable()
final class FollowNotificationData extends NotificationData {
  @JsonKey(fromJson: asString)
  final String? behaviorId;

  @JsonKey(fromJson: asString)
  final String? objectId;

  @JsonKey(fromJson: asBool)
  final bool? isMutual;

  @JsonKey(
    fromJson: _followRelationStatusFromJson,
    toJson: _followRelationStatusToJson,
  )
  final FollowRelationStatus? followStatus;

  const FollowNotificationData({
    this.behaviorId,
    this.objectId,
    this.isMutual,
    this.followStatus,
  });

  factory FollowNotificationData.fromJson(Map<String, dynamic> json) =>
      _$FollowNotificationDataFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FollowNotificationDataToJson(this);

  FollowNotificationData copyWith({FollowRelationStatus? followStatus}) =>
      FollowNotificationData(
        behaviorId: behaviorId,
        objectId: objectId,
        isMutual: isMutual,
        followStatus: followStatus ?? this.followStatus,
      );

  @override
  List<Object?> get props => [behaviorId, objectId, isMutual, followStatus];
}

/// 后端新增通知类型时的兼容载荷，保留完整原始数据。
final class UnknownNotificationData extends NotificationData {
  final String? rawEventType;
  final Map<String, dynamic> rawData;

  const UnknownNotificationData({
    this.rawEventType,
    this.rawData = const <String, dynamic>{},
  });

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.of(rawData);

  @override
  List<Object?> get props => [rawEventType, rawData];
}

/// 单条站内通知。
class NotificationItem extends Equatable {
  /// 经 [eventType] 判别后的类型专属载荷。
  final NotificationData data;

  /// 发生时间（毫秒时间戳）。
  @JsonKey(fromJson: asString)
  final String? eventTime;

  /// 通知类型。
  final NotificationEventType eventType;

  /// 通知 ID。
  @JsonKey(fromJson: asString)
  final String? id;

  /// 是否已读：1-已读，0-未读。
  @JsonKey(fromJson: asInt)
  final int? isRead;

  /// 操作人头像（互动类卡片头像）。
  final String? operateAvatarUrl;

  /// 操作人昵称。
  final String? operateNickname;

  /// 操作人用户 ID。
  @JsonKey(fromJson: asString)
  final String? operateUserId;

  /// 所属 Tab：1-收益，2-互动。
  @JsonKey(fromJson: asInt)
  final int? tab;

  const NotificationItem({
    this.data = const UnknownNotificationData(),
    this.eventTime,
    this.eventType = NotificationEventType.unknown,
    this.id,
    this.isRead,
    this.operateAvatarUrl,
    this.operateNickname,
    this.operateUserId,
    this.tab,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawEventType = asString(json['eventType'])?.trim();
    final eventType = NotificationEventType.fromWire(rawEventType);
    final rawData = json['data'];
    final dataJson = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    final data = NotificationData.fromJson(eventType, rawEventType, dataJson);
    if (data case final CommentNotificationData comment) {
      final message =
          'Decoded comment notification id=${asString(json['id'])} '
          'dataKeys=${dataJson.keys.join(',')} '
          'commentId=${comment.behaviorId} objectId=${comment.objectId} '
          'targetType=${comment.targetType} targetName=${comment.targetName}';
      if (comment.objectId?.trim().isNotEmpty != true) {
        StoryLogger.w(message, tag: 'NotificationNavigation');
      } else {
        StoryLogger.d(message, tag: 'NotificationNavigation');
      }
    }
    return NotificationItem(
      data: data,
      eventTime: asString(json['eventTime']),
      eventType: eventType,
      id: asString(json['id']),
      isRead: asInt(json['isRead']),
      operateAvatarUrl: asString(json['operateAvatarUrl']),
      operateNickname: asString(json['operateNickname']),
      operateUserId: asString(json['operateUserId']),
      tab: asInt(json['tab']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'data': data.toJson(),
    'eventTime': eventTime,
    'eventType': data is UnknownNotificationData
        ? (data as UnknownNotificationData).rawEventType ?? eventType.wireValue
        : eventType.wireValue,
    'id': id,
    'isRead': isRead,
    'operateAvatarUrl': operateAvatarUrl,
    'operateNickname': operateNickname,
    'operateUserId': operateUserId,
    'tab': tab,
  };

  NotificationItem copyWith({int? isRead, NotificationData? data}) =>
      NotificationItem(
        data: data ?? this.data,
        eventTime: eventTime,
        eventType: eventType,
        id: id,
        isRead: isRead ?? this.isRead,
        operateAvatarUrl: operateAvatarUrl,
        operateNickname: operateNickname,
        operateUserId: operateUserId,
        tab: tab,
      );

  bool get isUnread => isRead == 0;

  /// Avatar shown at the leading edge of a notification row.
  ///
  /// IP signing and low-stamina notifications represent the character IP
  /// rather than the operator, so their avatar comes from the type-specific
  /// payload.
  String? get leadingAvatarUrl => switch (data) {
    IpSignNotificationData(:final ipAvatarUrl) => ipAvatarUrl,
    StaminaLowNotificationData(:final ipAvatarUrl) => ipAvatarUrl,
    _ => operateAvatarUrl,
  };

  /// Character IP opened when tapping the leading avatar, when applicable.
  String? get avatarActorId => switch ((eventType, data)) {
    (NotificationEventType.ipSign, IpSignNotificationData(:final objectId)) =>
      _nonEmpty(objectId),
    (
      NotificationEventType.staminaLow,
      StaminaLowNotificationData(:final objectId),
    ) =>
      _nonEmpty(objectId),
    _ => null,
  };

  static String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  List<Object?> get props => [
    data,
    eventTime,
    eventType,
    id,
    isRead,
    operateAvatarUrl,
    operateNickname,
    operateUserId,
    tab,
  ];
}

/// 站内通知未读计数。
@JsonSerializable()
class NotificationUnreadCount extends Equatable {
  /// 收益 Tab 未读数。
  @JsonKey(fromJson: asString)
  final String? incomeUnread;

  /// 互动 Tab 未读数。
  @JsonKey(fromJson: asString)
  final String? interactionUnread;

  /// 总未读数。
  @JsonKey(fromJson: asString)
  final String? totalUnread;

  const NotificationUnreadCount({
    this.incomeUnread,
    this.interactionUnread,
    this.totalUnread,
  });

  factory NotificationUnreadCount.fromJson(Map<String, dynamic> json) =>
      _$NotificationUnreadCountFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationUnreadCountToJson(this);

  @override
  List<Object?> get props => [incomeUnread, interactionUnread, totalUnread];
}
