// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationDeleteRequest _$NotificationDeleteRequestFromJson(
  Map<String, dynamic> json,
) => NotificationDeleteRequest(id: (json['id'] as num).toInt());

Map<String, dynamic> _$NotificationDeleteRequestToJson(
  NotificationDeleteRequest instance,
) => <String, dynamic>{'id': instance.id};

NotificationReadRequest _$NotificationReadRequestFromJson(
  Map<String, dynamic> json,
) => NotificationReadRequest(
  ids: (json['ids'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
  tab: (json['tab'] as num?)?.toInt(),
);

Map<String, dynamic> _$NotificationReadRequestToJson(
  NotificationReadRequest instance,
) => <String, dynamic>{'ids': ?instance.ids, 'tab': ?instance.tab};

NotificationListRequest _$NotificationListRequestFromJson(
  Map<String, dynamic> json,
) => NotificationListRequest(
  eventType: json['eventType'] as String?,
  mark: asInt(json['mark']),
  pageSize: asInt(json['pageSize']),
  tab: asInt(json['tab']),
);

Map<String, dynamic> _$NotificationListRequestToJson(
  NotificationListRequest instance,
) => <String, dynamic>{
  'eventType': ?instance.eventType,
  'mark': ?instance.mark,
  'pageSize': ?instance.pageSize,
  'tab': ?instance.tab,
};

NotificationPage _$NotificationPageFromJson(Map<String, dynamic> json) =>
    NotificationPage(
      hasMore: asBool(json['hasMore']),
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      mark: asString(json['mark']),
      pageSize: asInt(json['pageSize']),
    );

Map<String, dynamic> _$NotificationPageToJson(NotificationPage instance) =>
    <String, dynamic>{
      'hasMore': instance.hasMore,
      'list': instance.list?.map((e) => e.toJson()).toList(),
      'mark': instance.mark,
      'pageSize': instance.pageSize,
    };

IpSignNotificationData _$IpSignNotificationDataFromJson(
  Map<String, dynamic> json,
) => IpSignNotificationData(
  behaviorId: asString(json['behaviorId']),
  objectId: asString(json['objectId']),
  ipName: json['ipName'] as String?,
  ipAvatarUrl: json['ipAvatarUrl'] as String?,
  amount: asString(json['amount']),
  assetCode: json['assetCode'] as String?,
);

Map<String, dynamic> _$IpSignNotificationDataToJson(
  IpSignNotificationData instance,
) => <String, dynamic>{
  'behaviorId': instance.behaviorId,
  'objectId': instance.objectId,
  'ipName': instance.ipName,
  'ipAvatarUrl': instance.ipAvatarUrl,
  'amount': instance.amount,
  'assetCode': instance.assetCode,
};

ShowRewardNotificationData _$ShowRewardNotificationDataFromJson(
  Map<String, dynamic> json,
) => ShowRewardNotificationData(
  behaviorId: asString(json['behaviorId']),
  objectId: asString(json['objectId']),
  amount: asString(json['amount']),
  assetCode: json['assetCode'] as String?,
  periodStart: asString(json['periodStart']),
  periodEnd: asString(json['periodEnd']),
);

Map<String, dynamic> _$ShowRewardNotificationDataToJson(
  ShowRewardNotificationData instance,
) => <String, dynamic>{
  'behaviorId': instance.behaviorId,
  'objectId': instance.objectId,
  'amount': instance.amount,
  'assetCode': instance.assetCode,
  'periodStart': instance.periodStart,
  'periodEnd': instance.periodEnd,
};

StaminaLowNotificationData _$StaminaLowNotificationDataFromJson(
  Map<String, dynamic> json,
) => StaminaLowNotificationData(
  behaviorId: asString(json['behaviorId']),
  objectId: asString(json['objectId']),
  ipName: json['ipName'] as String?,
  ipAvatarUrl: json['ipAvatarUrl'] as String?,
  stamina: asInt(json['stamina']),
);

Map<String, dynamic> _$StaminaLowNotificationDataToJson(
  StaminaLowNotificationData instance,
) => <String, dynamic>{
  'behaviorId': instance.behaviorId,
  'objectId': instance.objectId,
  'ipName': instance.ipName,
  'ipAvatarUrl': instance.ipAvatarUrl,
  'stamina': instance.stamina,
};

TargetInteractionNotificationData _$TargetInteractionNotificationDataFromJson(
  Map<String, dynamic> json,
) => TargetInteractionNotificationData(
  behaviorId: asString(json['behaviorId']),
  objectId: asString(json['objectId']),
  targetType: json['targetType'] as String?,
  targetName: json['targetName'] as String?,
  coverUrl: json['coverUrl'] as String?,
);

Map<String, dynamic> _$TargetInteractionNotificationDataToJson(
  TargetInteractionNotificationData instance,
) => <String, dynamic>{
  'behaviorId': instance.behaviorId,
  'objectId': instance.objectId,
  'targetType': instance.targetType,
  'targetName': instance.targetName,
  'coverUrl': instance.coverUrl,
};

CommentNotificationData _$CommentNotificationDataFromJson(
  Map<String, dynamic> json,
) => CommentNotificationData(
  behaviorId: asString(json['behaviorId']),
  objectId: asString(json['objectId']),
  targetType: json['targetType'] as String?,
  content: json['content'] as String?,
  targetName: json['targetName'] as String?,
  coverUrl: json['coverUrl'] as String?,
);

Map<String, dynamic> _$CommentNotificationDataToJson(
  CommentNotificationData instance,
) => <String, dynamic>{
  'behaviorId': instance.behaviorId,
  'objectId': instance.objectId,
  'targetType': instance.targetType,
  'content': instance.content,
  'targetName': instance.targetName,
  'coverUrl': instance.coverUrl,
};

FollowNotificationData _$FollowNotificationDataFromJson(
  Map<String, dynamic> json,
) => FollowNotificationData(
  behaviorId: asString(json['behaviorId']),
  objectId: asString(json['objectId']),
  isMutual: asBool(json['isMutual']),
  followStatus: _followRelationStatusFromJson(json['followStatus']),
);

Map<String, dynamic> _$FollowNotificationDataToJson(
  FollowNotificationData instance,
) => <String, dynamic>{
  'behaviorId': instance.behaviorId,
  'objectId': instance.objectId,
  'isMutual': instance.isMutual,
  'followStatus': _followRelationStatusToJson(instance.followStatus),
};

NotificationUnreadCount _$NotificationUnreadCountFromJson(
  Map<String, dynamic> json,
) => NotificationUnreadCount(
  incomeUnread: asString(json['incomeUnread']),
  interactionUnread: asString(json['interactionUnread']),
  totalUnread: asString(json['totalUnread']),
);

Map<String, dynamic> _$NotificationUnreadCountToJson(
  NotificationUnreadCount instance,
) => <String, dynamic>{
  'incomeUnread': instance.incomeUnread,
  'interactionUnread': instance.interactionUnread,
  'totalUnread': instance.totalUnread,
};
