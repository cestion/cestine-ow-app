import '../model/follow_models.dart';
import '../model/notification_models.dart';

/// Temporary notification-list mock.
///
/// It is disabled by default so local builds use the real API. Pass
/// `--dart-define=MOCK_NOTIFICATION_LIST=true` to show the mock list locally.
/// Once the backend data is ready, remove this file and the small branch in
/// `NotificationRepositoryImpl.listNotifications`.
const bool notificationListMockEnabled = bool.fromEnvironment(
  'MOCK_NOTIFICATION_LIST',
);

/// Builds mock data while preserving the API's tab, event-type and paging
/// behavior.
NotificationPage mockNotificationPage(
  NotificationListRequest request, {
  DateTime? now,
}) {
  final timestamp = now ?? DateTime.now();
  String eventTime(int minutesAgo) => timestamp
      .subtract(Duration(minutes: minutesAgo))
      .millisecondsSinceEpoch
      .toString();

  final allItems = <NotificationItem>[
    NotificationItem(
      id: '900001',
      eventType: NotificationEventType.ipSign,
      eventTime: eventTime(1440),
      isRead: 0,
      operateNickname: 'Jack',
      operateUserId: 'mock-user-1',
      tab: 1,
      data: const IpSignNotificationData(
        ipName: '舒婉清',
        amount: '123.43',
        assetCode: 'USDC',
      ),
    ),
    NotificationItem(
      id: '900002',
      eventType: NotificationEventType.staminaLow,
      eventTime: eventTime(1440),
      isRead: 0,
      operateUserId: 'mock-user-2',
      tab: 1,
      data: const StaminaLowNotificationData(ipName: '舒婉清', stamina: 0),
    ),
    NotificationItem(
      id: '900003',
      eventType: NotificationEventType.showReward,
      eventTime: eventTime(1440),
      isRead: 1,
      operateUserId: 'mock-user-3',
      tab: 1,
      data: ShowRewardNotificationData(
        periodStart: timestamp
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch
            .toString(),
        periodEnd: timestamp.millisecondsSinceEpoch.toString(),
        amount: '415.70',
        assetCode: 'STORY',
      ),
    ),
    NotificationItem(
      id: '900004',
      eventType: NotificationEventType.like,
      eventTime: eventTime(8),
      isRead: 0,
      operateNickname: 'Alex',
      operateUserId: 'mock-user-4',
      tab: 2,
      data: const TargetInteractionNotificationData(
        targetType: 'video',
        targetName: 'Neon Harbor · EP03',
        coverUrl: 'https://example.com/cover.jpg',
      ),
    ),
    NotificationItem(
      id: '900005',
      eventType: NotificationEventType.like,
      eventTime: eventTime(20),
      isRead: 1,
      operateNickname: 'Mia',
      operateUserId: 'mock-user-5',
      tab: 2,
      data: const TargetInteractionNotificationData(
        targetType: 'drama',
        targetName: 'Neon Harbor',
      ),
    ),
    NotificationItem(
      id: '900006',
      eventType: NotificationEventType.favorite,
      eventTime: eventTime(35),
      isRead: 1,
      operateNickname: 'Noah',
      operateUserId: 'mock-user-6',
      tab: 2,
      data: const TargetInteractionNotificationData(
        targetType: 'video',
        targetName: 'Neon Harbor · EP05',
      ),
    ),
    NotificationItem(
      id: '900007',
      eventType: NotificationEventType.favorite,
      eventTime: eventTime(50),
      isRead: 1,
      operateNickname: 'Luna',
      operateUserId: 'mock-user-7',
      tab: 2,
      data: const TargetInteractionNotificationData(
        targetType: 'drama',
        targetName: 'Moonlit Protocol',
      ),
    ),
    NotificationItem(
      id: '900008',
      eventType: NotificationEventType.comment,
      eventTime: eventTime(65),
      isRead: 1,
      operateNickname: 'JACK12233JACK12233JACK12233',
      operateUserId: 'mock-user-8',
      tab: 2,
      data: const CommentNotificationData(content: '剧情太精彩了，期待下一集'),
    ),
    NotificationItem(
      id: '900009',
      eventType: NotificationEventType.follow,
      eventTime: eventTime(80),
      isRead: 1,
      operateNickname: 'Ava',
      operateUserId: 'mock-user-9',
      tab: 2,
      data: const FollowNotificationData(
        isMutual: true,
        followStatus: FollowRelationStatus.mutual,
      ),
    ),
    NotificationItem(
      id: '900010',
      eventType: NotificationEventType.follow,
      eventTime: eventTime(95),
      isRead: 1,
      operateNickname: 'Ethan',
      operateUserId: 'mock-user-10',
      tab: 2,
      data: const FollowNotificationData(
        isMutual: false,
        followStatus: FollowRelationStatus.followBack,
      ),
    ),
    NotificationItem(
      id: '900011',
      eventType: NotificationEventType.follow,
      eventTime: eventTime(110),
      isRead: 1,
      operateNickname: 'Olivia',
      operateUserId: 'mock-user-11',
      tab: 2,
      data: const FollowNotificationData(
        isMutual: false,
        followStatus: FollowRelationStatus.none,
      ),
    ),
    NotificationItem(
      id: '900012',
      eventType: NotificationEventType.follow,
      eventTime: eventTime(125),
      isRead: 1,
      operateNickname: 'Liam',
      operateUserId: 'mock-user-12',
      tab: 2,
      data: const FollowNotificationData(
        isMutual: false,
        followStatus: FollowRelationStatus.following,
      ),
    ),
  ];

  final requestedType = request.eventType?.trim().toUpperCase();
  final filtered = allItems.where((item) {
    final matchesTab = request.tab == null || item.tab == request.tab;
    final matchesType =
        requestedType == null ||
        requestedType.isEmpty ||
        item.eventType == NotificationEventType.fromWire(requestedType);
    return matchesTab && matchesType;
  }).toList();

  final offset = (request.mark ?? 0).clamp(0, filtered.length);
  final pageSize = request.pageSize ?? filtered.length;
  final safePageSize = pageSize < 0 ? 0 : pageSize;
  final requestedEnd = offset + safePageSize;
  final end = requestedEnd < filtered.length ? requestedEnd : filtered.length;
  final items = filtered.sublist(offset, end);
  final hasMore = end < filtered.length;

  return NotificationPage(
    hasMore: hasMore,
    list: items,
    mark: hasMore ? end.toString() : '-1',
    pageSize: safePageSize,
  );
}
