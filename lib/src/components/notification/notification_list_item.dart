import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../controller/follow_action_controller.dart';
import '../../core/story_logger.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../provider/tab_index_provider.dart';
import '../../routes/content_playback_navigation.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../utils/format_number.dart';
import '../../utils/format_time.dart';
import '../../widgets/story_avatar.dart';
import '../../widgets/story_cached_image.dart';
import '../../widgets/story_loading.dart';
import '../common/story_toast.dart';
import '../../foundation/navigator.dart';

const _showRewardAvatarAsset = 'assets/common/notification_show_reward.svg';

/// A reusable notification row with avatar, unread state, content and action.
///
/// The row is wrapped in a [Slidable] (`flutter_slidable`) exposing a single
/// right-side delete action. Tapping it triggers [onDelete], which performs an
/// optimistic delete via the controller — the row is removed from the list
/// immediately, the API call fires in the background, and on failure the item
/// is restored and a toast is shown.
class NotificationListItem extends ConsumerWidget {
  const NotificationListItem({
    super.key,
    required this.item,
    required this.onDelete,
  });

  final NotificationItem item;

  /// Performs the optimistic delete (state mutation + API call) in the
  /// controller. Returns `true` on success, `false` (with the item already
  /// restored) on failure.
  final Future<bool> Function() onDelete;

  Future<void> _runAsyncNavigation(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final operationKey = item.id ?? item;
    final didShow = StoryLoading.show(context, operationKey: operationKey);
    if (!didShow) return;
    StoryLogger.d(
      'Show centered loading notificationId=${item.id}',
      tag: 'NotificationNavigation',
    );
    try {
      await action();
    } catch (error, stackTrace) {
      StoryLogger.e(
        'Async notification navigation failed notificationId=${item.id}',
        error: error,
        stackTrace: stackTrace,
        tag: 'NotificationNavigation',
      );
      if (context.mounted) {
        StoryToast.error(context, context.l10n.commonLoadFailed);
      }
    } finally {
      StoryLoading.dissmiss(operationKey: operationKey);
      StoryLogger.d(
        'Hide centered loading notificationId=${item.id}',
        tag: 'NotificationNavigation',
      );
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final success = await onDelete();
    if (!success && context.mounted) {
      StoryToast.error(context, context.l10n.notificationDeleteFailed);
    }
  }

  /// 点击「关注 / 已关注」按钮：调用关注或取消关注接口，成功后拉取
  /// `/api/userWallet/otherUserInfo` 中的 `relationStatus` 用服务端真实
  /// 状态覆盖本地值（例如对方回关后应为 MUTUAL 而非 FOLLOWING）。
  ///
  /// 按钮的 loading 持续整个流程（关注/取关 + otherUserInfo），文案只在
  /// loading 结束后变化一次，避免「乐观值 → 服务端值」的二次闪烁。
  /// API 失败时回滚到原状态。
  Future<void> _handleFollowToggle(
    BuildContext context,
    WidgetRef ref, {
    required FollowRelationStatus current,
  }) async {
    final userId = item.operateUserId?.trim() ?? '';
    if (userId.isEmpty) return;
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) {
      context.storyPush(RouteNames.login);
      return;
    }

    final tab = item.tab ?? 2;
    final notifier = ref.read(notificationControllerProvider(tab).notifier);
    final action = ref.read(followActionControllerProvider.notifier);
    final notificationId = item.id ?? '';
    final previous = current;
    final fallback = current.isFollowing
        ? FollowRelationStatus.none
        : FollowRelationStatus.following;

    // 关注/取关（内部已管理 pending）。不在此处做乐观更新，让 loading 覆盖
    // 整个流程，文案仅在最后变化一次。
    final result = current.isFollowing
        ? await action.unfollow(userId)
        : await action.follow(userId);
    if (!context.mounted) return;
    if (result.isFailure) {
      notifier.patchFollowStatus(notificationId, previous);
      StoryToast.error(
        context,
        result.errorOrNull == null
            ? context.l10n.commonLoadFailed
            : context.l10nError(result.errorOrNull!),
      );
      return;
    }

    // 操作成功：重新持有 pending 以覆盖 otherUserInfo 拉取阶段，保证 loading
    // 持续到流程结束。`follow`/`unfollow` 返回时已释放 pending，此处同步再次
    // 持有，UI 下一帧重建只会看到 pending=true，不会出现中间闪烁。
    action.holdPending(userId);
    try {
      final profileResult = await ref
          .read(userRepositoryProvider)
          .getOtherProfile(userId);
      if (!context.mounted) return;
      // 拉取成功用服务端真实状态；拉取失败回退到关注/取关的预期值。
      // 两种情况都只 patch 一次 → 文案只变化一次。
      final status = profileResult.dataOrNull?.relationStatus ?? fallback;
      notifier.patchFollowStatus(notificationId, status);
    } finally {
      action.releasePending(userId);
    }
  }

  Future<void> _openDestination(
    BuildContext context,
    WidgetRef ref,
    ({String routeName, Map<String, dynamic> arguments}) destination, {
    required String source,
  }) async {
    StoryLogger.i(
      'Tap notification id=${item.id} type=${item.eventType.wireValue} '
      'source=$source route=${destination.routeName} '
      'arguments=${destination.arguments}',
      tag: 'NotificationNavigation',
    );
    await context.storyPush(destination.routeName, arguments: destination.arguments);
    if (!context.mounted) return;
    // Returning from a public profile may have changed the follow relation.
    // Re-fetch the server-side status and patch this notification item.
    if (destination.routeName == RouteNames.publicProfile) {
      await _syncFollowStatusFromServer(context, ref);
    }
  }

  Map<String, dynamic> _playerArgsForDrama(
    WidgetRef ref, {
    required String dramaId,
    String? title,
    String? coverUrl,
    bool openComments = false,
  }) {
    return <String, dynamic>{
      'dramaId': dramaId,
      'episodeNo': ref.read(currentDramaEpisodeProvider(dramaId)),
      if (title != null && title.isNotEmpty) 'title': title,
      if (coverUrl?.trim().isNotEmpty == true) 'coverUrl': coverUrl!.trim(),
      if (openComments) 'openComments': true,
    };
  }

  /// Opens the operator's public profile from the avatar tap, then syncs the
  /// follow status from the server upon return (same as content tap).
  Future<void> _openProfileFromAvatar(
    BuildContext context,
    WidgetRef ref, {
    String? userId,
  }) async {
    StoryLogger.i(
      'Tap notification avatar id=${item.id} '
      'type=${item.eventType.wireValue} source=avatar userId=$userId',
      tag: 'NotificationNavigation',
    );
    await context.storyPush(RouteNames.publicProfile, arguments: <String, dynamic>{'userId': userId});
    if (!context.mounted) return;
    await _syncFollowStatusFromServer(context, ref);
  }

  /// 从他人主页返回后，从网络校准本通知的关注状态。
  ///
  /// 用户在「他人主页」可能点击了关注/取关，返回通知列表时本地状态已过期。
  /// 这里重新拉取 `getRelation` 并 patch 到通知项，保证关注按钮文案与服务
  /// 器一致。跳过当前有 in-flight 关注操作的 userId，避免与
  /// `_handleFollowToggle` 的 holdPending 流程竞争。
  Future<void> _syncFollowStatusFromServer(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (item.eventType != NotificationEventType.follow) return;
    final userId = item.operateUserId?.trim() ?? '';
    if (userId.isEmpty) return;
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) return;
    if (ref.read(followActionControllerProvider).isPending(userId)) return;

    final notificationId = item.id ?? '';
    final result = await ref.read(followRepositoryProvider).getRelation(userId);
    if (!context.mounted) return;
    final status = result.dataOrNull;
    if (status == null) return;
    final tab = item.tab ?? 2;
    ref
        .read(notificationControllerProvider(tab).notifier)
        .patchFollowStatus(notificationId, status);
  }

  Future<void> _popToMainInterface(
    BuildContext context,
    WidgetRef ref, {
    required String source,
  }) async {
    StoryLogger.i(
      'Tap notification id=${item.id} type=${item.eventType.wireValue} '
      'source=$source → pop to main shell and switch to 经纪人 tab',
      tag: 'NotificationNavigation',
    );
    // Switch to the 经纪人 (game) tab first (with auth guard), then pop back
    // to the main shell. Setting the index before popping ensures
    // MainShellPage is already on the game tab when it becomes visible.
    await ref
        .read(tabIndexProvider.notifier)
        .selectTabWithAuth(StoryTab.game.index);
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<DramaListItem?> _resolveDramaByName(
    BuildContext context,
    WidgetRef ref, {
    required String targetName,
    String? coverUrl,
  }) async {
    if (targetName.isEmpty) return null;
    final result = await ref
        .read(dramaRepositoryProvider)
        .listPublic(name: targetName);
    if (!context.mounted) return null;
    if (result.isFailure) {
      final error = result.errorOrNull!;
      StoryLogger.e(
        'Failed to resolve notification target drama '
        'notificationId=${item.id} targetName=$targetName error=$error',
        tag: 'NotificationNavigation',
      );
      return null;
    }

    final candidates = result.dataOrNull?.list ?? const <DramaListItem>[];
    final exactMatches = candidates
        .where((drama) => drama.dramaTitle?.trim() == targetName)
        .toList();
    DramaListItem? matchedDrama;
    final normalizedCoverUrl = coverUrl?.trim();
    for (final drama in exactMatches) {
      if (normalizedCoverUrl?.isNotEmpty == true &&
          drama.dramaCoverUrl?.trim() == normalizedCoverUrl) {
        matchedDrama = drama;
        break;
      }
    }
    if (matchedDrama == null && exactMatches.isNotEmpty) {
      matchedDrama = exactMatches.first;
    }
    StoryLogger.i(
      'Notification target lookup finished notificationId=${item.id} '
      'query=$targetName candidates=${candidates.length} '
      'exactMatches=${exactMatches.length} '
      'resolvedDramaId=${matchedDrama?.id}',
      tag: 'NotificationNavigation',
    );
    return matchedDrama;
  }

  Future<int?> _resolveEpisodeNo(
    WidgetRef ref, {
    required DramaListItem drama,
    required String episodeId,
  }) async {
    final repository = ref.read(dramaRepositoryProvider);

    Future<DramaPlayResponse?> load(int episodeNo) async {
      final result = await repository.getEpisodeDetail(drama.id, episodeNo);
      if (result.isFailure) {
        StoryLogger.w(
          'Episode lookup failed notificationId=${item.id} '
          'dramaId=${drama.id} episodeNo=$episodeNo '
          'error=${result.errorOrNull}',
          tag: 'NotificationNavigation',
        );
        return null;
      }
      return result.dataOrNull;
    }

    final first = await load(1);
    if (first?.episodeId?.trim() == episodeId) return first?.episodeNo ?? 1;

    final targetNumericId = BigInt.tryParse(episodeId);
    final totalEpisodes = drama.totalEpisodes ?? 1;
    if (targetNumericId == null || totalEpisodes < 2) return null;

    // Episode snowflake IDs are created in episode order. Use a logarithmic
    // lookup instead of fetching every episode when the payload omits epNo.
    var low = 2;
    var high = totalEpisodes;
    while (low <= high) {
      final middle = low + ((high - low) ~/ 2);
      final play = await load(middle);
      final candidateId = play?.episodeId?.trim();
      if (candidateId == episodeId) return play?.episodeNo ?? middle;
      final candidateNumericId = BigInt.tryParse(candidateId ?? '');
      if (candidateNumericId == null) return null;
      if (candidateNumericId < targetNumericId) {
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return null;
  }

  Future<void> _openTargetInteractionDestination(
    BuildContext context,
    WidgetRef ref,
    TargetInteractionNotificationData data, {
    required String source,
  }) async {
    final objectId = data.objectId?.trim() ?? '';
    final targetType = data.targetType?.trim().toLowerCase() ?? '';
    final targetName = data.targetName?.trim() ?? '';
    StoryLogger.i(
      'Resolve ${item.eventType.wireValue} notification id=${item.id} '
      'source=$source objectId=$objectId targetType=$targetType '
      'targetName=$targetName behaviorId=${data.behaviorId}',
      tag: 'NotificationNavigation',
    );
    if (objectId.isEmpty) {
      StoryToast.error(context, context.l10n.commonLoadFailed);
      return;
    }

    if (item.eventType == NotificationEventType.like) {
      if (targetType == 'drama') {
        await ContentPlaybackNavigation.openDrama(
          context: context,
          ref: ref,
          dramaId: objectId,
          title: targetName,
          coverUrl: data.coverUrl?.trim(),
          showLoading: false,
        );
        return;
      }
      if (targetType == 'video') {
        await ContentPlaybackNavigation.openVideo(
          context: context,
          ref: ref,
          videoId: objectId,
          title: targetName,
          coverUrl: data.coverUrl?.trim(),
          showLoading: false,
        );
        return;
      }
    }

    if (targetType == 'drama') {
      _openDestination(context, ref, (
        routeName: RouteNames.player,
        arguments: _playerArgsForDrama(
          ref,
          dramaId: objectId,
          title: targetName,
          coverUrl: data.coverUrl,
        ),
      ), source: source);
      return;
    }

    if (targetType != 'video') {
      StoryLogger.w(
        'Unsupported interaction targetType notificationId=${item.id} '
        'targetType=$targetType objectId=$objectId',
        tag: 'NotificationNavigation',
      );
      StoryToast.error(context, context.l10n.commonLoadFailed);
      return;
    }

    final drama = await _resolveDramaByName(
      context,
      ref,
      targetName: targetName,
      coverUrl: data.coverUrl,
    );
    if (!context.mounted) return;
    if (drama == null) {
      StoryToast.error(context, context.l10n.commonLoadFailed);
      return;
    }
    final resolvedEpisodeNo = await _resolveEpisodeNo(
      ref,
      drama: drama,
      episodeId: objectId,
    );
    if (!context.mounted) return;
    final episodeNo = resolvedEpisodeNo ?? 1;
    if (resolvedEpisodeNo == null) {
      StoryLogger.w(
        'Could not resolve video episodeNo; defaulting to episode 1 '
        'notificationId=${item.id} episodeId=$objectId dramaId=${drama.id}',
        tag: 'NotificationNavigation',
      );
    }
    _openDestination(context, ref, (
      routeName: RouteNames.player,
      arguments: <String, dynamic>{
        'dramaId': drama.id,
        'episodeNo': episodeNo,
        'totalEpisodes': drama.totalEpisodes ?? 1,
        if (targetName.isNotEmpty) 'title': targetName,
        if (data.coverUrl?.trim().isNotEmpty == true)
          'coverUrl': data.coverUrl!.trim(),
      },
    ), source: source);
  }

  Future<void> _openCommentDestination(
    BuildContext context,
    WidgetRef ref,
    CommentNotificationData data, {
    required String source,
  }) async {
    final objectId = data.objectId?.trim() ?? '';
    final commentId = data.behaviorId?.trim();
    final targetName = data.targetName?.trim() ?? '';
    final targetType = data.targetType?.trim().toLowerCase() ?? '';

    StoryLogger.i(
      'Resolve comment notification id=${item.id} source=$source '
      'objectId=$objectId targetType=$targetType targetName=$targetName '
      'commentBehaviorId=$commentId',
      tag: 'NotificationNavigation',
    );

    if (objectId.isEmpty) {
      StoryToast.error(context, context.l10n.commonLoadFailed);
      return;
    }

    if (targetType != 'drama' && targetType != 'video') {
      StoryLogger.w(
        'Unsupported comment targetType notificationId=${item.id} '
        'targetType=$targetType objectId=$objectId',
        tag: 'NotificationNavigation',
      );
      StoryToast.error(context, context.l10n.commonLoadFailed);
      return;
    }

    if (commentId == null || commentId.isEmpty) {
      StoryLogger.w(
        'Comment notification has no comment id notificationId=${item.id} '
        'episodeId=$objectId',
        tag: 'NotificationNavigation',
      );
      StoryToast.error(context, context.l10n.commonLoadFailed);
      return;
    }

    final commentResult = await ref
        .read(dramaRepositoryProvider)
        .getComment(commentId);
    if (!context.mounted) return;
    final highlightedComment = commentResult.dataOrNull;
    if (highlightedComment == null) {
      StoryLogger.w(
        'Could not load comment notificationId=${item.id} '
        'commentId=$commentId error=${commentResult.errorOrNull}',
        tag: 'NotificationNavigation',
      );
      StoryToast.error(
        context,
        commentResult.errorOrNull == null
            ? context.l10n.commonLoadFailed
            : context.l10nError(commentResult.errorOrNull!),
      );
      return;
    }

    // Comments belong to a concrete episode. For drama-target notifications
    // `objectId` is the drama id, while the comment detail's `workId` is the
    // authoritative episode id. Video-target payloads historically put the
    // episode id in `objectId`, so keep that as a compatibility fallback.
    final episodeId = highlightedComment.workId?.trim().isNotEmpty == true
        ? highlightedComment.workId!.trim()
        : targetType == 'video'
        ? objectId
        : '';
    if (episodeId.isEmpty) {
      StoryLogger.w(
        'Comment notification has no episode id notificationId=${item.id} '
        'targetType=$targetType objectId=$objectId commentId=$commentId',
        tag: 'NotificationNavigation',
      );
      StoryToast.error(context, context.l10n.commonLoadFailed);
      return;
    }

    final repository = ref.read(dramaRepositoryProvider);
    final playResult = await repository.getEpisodeDetailByEpisodeId(episodeId);
    if (!context.mounted) return;
    final play = playResult.dataOrNull;
    if (play == null) {
      StoryLogger.w(
        'Could not resolve comment episode notificationId=${item.id} '
        'episodeId=$episodeId error=${playResult.errorOrNull}',
        tag: 'NotificationNavigation',
      );
      StoryToast.error(
        context,
        playResult.errorOrNull == null
            ? context.l10n.commonLoadFailed
            : context.l10nError(playResult.errorOrNull!),
      );
      return;
    }

    final isStandaloneVideo =
        targetType == 'video' && play.dramaId?.trim().isNotEmpty != true;
    final dramaId = play.dramaId?.trim().isNotEmpty == true
        ? play.dramaId!.trim()
        : targetType == 'drama'
        ? objectId
        : '';
    final episodeNo = play.episodeNo;
    if ((!isStandaloneVideo && dramaId.isEmpty) ||
        episodeNo == null ||
        episodeNo < 1) {
      StoryLogger.w(
        'Incomplete comment episode detail notificationId=${item.id} '
        'episodeId=$episodeId dramaId=$dramaId episodeNo=$episodeNo '
        'standaloneVideo=$isStandaloneVideo',
        tag: 'NotificationNavigation',
      );
      StoryToast.error(context, context.l10n.commonLoadFailed);
      return;
    }

    DramaDetail? detail;
    if (!isStandaloneVideo) {
      final detailResult = await repository.getDetail(dramaId);
      if (!context.mounted) return;
      detail = detailResult.dataOrNull;
      if (detail == null) {
        StoryLogger.w(
          'Could not load comment drama metadata notificationId=${item.id} '
          'dramaId=$dramaId error=${detailResult.errorOrNull}; '
          'opening player with episode metadata only',
          tag: 'NotificationNavigation',
        );
      }
    }

    final knownTotalEpisodes = detail?.totalEpisodes;
    final totalEpisodes = isStandaloneVideo
        ? 1
        : knownTotalEpisodes == null
        ? episodeNo
        : knownTotalEpisodes < episodeNo
        ? episodeNo
        : knownTotalEpisodes;
    final destination = (
      routeName: RouteNames.player,
      arguments: <String, dynamic>{
        'dramaId': dramaId,
        'episodeId': episodeId,
        'contentType': isStandaloneVideo
            ? WorkContentType.shortVideo.apiValue
            : WorkContentType.shortDrama.apiValue,
        'episodeNo': episodeNo,
        'totalEpisodes': totalEpisodes,
        'title': detail?.title?.trim().isNotEmpty == true
            ? detail!.title!.trim()
            : targetName,
        if (data.coverUrl?.trim().isNotEmpty == true ||
            detail?.coverUrl?.trim().isNotEmpty == true)
          'coverUrl': data.coverUrl?.trim().isNotEmpty == true
              ? data.coverUrl!.trim()
              : detail!.coverUrl!.trim(),
        'openComments': true,
        'commentEpisodeId': episodeId,
        'highlightedComment': highlightedComment,
      },
    );
    StoryLogger.i(
      'Open resolved comment notification id=${item.id} '
      'dramaId=$dramaId episodeId=$episodeId episodeNo=$episodeNo '
      'commentId=$commentId standaloneVideo=$isStandaloneVideo',
      tag: 'NotificationNavigation',
    );
    _openDestination(context, ref, destination, source: source);
  }

  ({String routeName, Map<String, dynamic> arguments})? get _destination {
    if (item.eventType == NotificationEventType.follow) {
      final userId = item.operateUserId?.trim();
      if (userId == null || userId.isEmpty) return null;
      return (
        routeName: RouteNames.publicProfile,
        arguments: <String, dynamic>{'userId': userId},
      );
    }

    return null;
  }

  String? get _actionRouteName => switch (item.eventType) {
    NotificationEventType.ipSign ||
    NotificationEventType.showReward => RouteNames.income,
    _ => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = _NotificationPresentation.from(context, item);
    final avatarSeed = _firstNonEmpty([
      item.operateUserId,
      item.operateNickname,
      switch (item.data) {
        IpSignNotificationData(:final ipName) => ipName,
        StaminaLowNotificationData(:final ipName) => ipName,
        _ => null,
      },
      item.eventType.wireValue,
    ]);
    final operateUserId = item.operateUserId?.trim();
    final avatarActorId = item.avatarActorId;
    final isActorNotification =
        item.eventType == NotificationEventType.ipSign ||
        item.eventType == NotificationEventType.staminaLow;
    final canOpenActor = isActorNotification && avatarActorId != null;
    final canOpenProfile =
        !isActorNotification && operateUserId?.isNotEmpty == true;
    final destination = _destination;
    final commentData =
        item.eventType == NotificationEventType.comment &&
            item.data is CommentNotificationData
        ? item.data as CommentNotificationData
        : null;
    final targetInteractionData =
        (item.eventType == NotificationEventType.like ||
                item.eventType == NotificationEventType.favorite) &&
            item.data is TargetInteractionNotificationData
        ? item.data as TargetInteractionNotificationData
        : null;
    final actionRouteName = _actionRouteName;
    final isFollowAction =
        item.eventType == NotificationEventType.follow &&
        presentation.followStatus != null;
    final pendingFollowUserIds = ref.watch(
      followActionControllerProvider.select((s) => s.pendingUserIds),
    );
    final isFollowPending =
        isFollowAction &&
        operateUserId != null &&
        operateUserId.isNotEmpty &&
        pendingFollowUserIds.contains(operateUserId);

    return Slidable(
      key: ValueKey(item.id ?? item.eventTime ?? item.hashCode),
      groupTag: 'notifications',
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.20,
        children: [
          SlidableAction(
            onPressed: (_) => _handleDelete(context),
            backgroundColor: StoryColors.destructive,
            foregroundColor: StoryColors.onOverlay,
            label: context.l10n.notificationDelete,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canOpenActor
                  ? () => _openDestination(context, ref, (
                      routeName: RouteNames.actorDetail,
                      arguments: <String, dynamic>{'actorId': avatarActorId},
                    ), source: 'avatar')
                  : canOpenProfile
                  ? () => _openProfileFromAvatar(
                      context,
                      ref,
                      userId: operateUserId,
                    )
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (item.eventType == NotificationEventType.showReward)
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: StoryColors.sheetSecondaryOf(
                          Theme.of(context).brightness,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SvgPicture.asset(
                        _showRewardAvatarAsset,
                        width: 30,
                        height: 30,
                        colorFilter: const ColorFilter.mode(
                          StoryColors.brandTealRed,
                          BlendMode.srcIn,
                        ),
                      ),
                    )
                  else
                    StoryAvatar(
                      imageUrl: item.leadingAvatarUrl,
                      userId: item.operateUserId,
                      fallbackText: avatarSeed,
                    ),
                  if (item.isUnread)
                    const Positioned(
                      left: -3,
                      top: -3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: StoryColors.destructive,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(dimension: 6),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: commentData != null
                    ? () => _runAsyncNavigation(
                        context,
                        () => _openCommentDestination(
                          context,
                          ref,
                          commentData,
                          source: 'content',
                        ),
                      )
                    : targetInteractionData != null
                    ? () => _runAsyncNavigation(
                        context,
                        () => _openTargetInteractionDestination(
                          context,
                          ref,
                          targetInteractionData,
                          source: 'content',
                        ),
                      )
                    : destination != null
                    ? () => _openDestination(
                        context,
                        ref,
                        destination,
                        source: 'content',
                      )
                    : item.eventType == NotificationEventType.staminaLow
                    ? () => _popToMainInterface(context, ref, source: 'content')
                    : actionRouteName != null
                    ? () => context.storyPush(actionRouteName)
                    : item.eventType == NotificationEventType.comment
                    ? () => StoryLogger.w(
                        'Tap comment notification ignored: invalid data '
                        'id=${item.id} '
                        'runtimeType=${item.data.runtimeType}',
                        tag: 'NotificationNavigation',
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.only(left: StorySpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: presentation.isInteraction
                            ? _InteractionNotificationContent(
                                title: presentation.title,
                                message: presentation.interactionMessage,
                                eventTime: item.eventTime,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _NotificationTag(label: presentation.tag),
                                  const SizedBox(height: 6),
                                  _NotificationMessage(
                                    lines: presentation.lines,
                                  ),
                                  const SizedBox(height: 6),
                                  _NotificationTime(eventTime: item.eventTime),
                                ],
                              ),
                      ),
                      if (presentation.showThumbnail) ...[
                        const SizedBox(width: StorySpacing.md),
                        _NotificationThumbnail(
                          imageUrl: presentation.trailingImageUrl,
                        ),
                      ] else if (presentation.actionLabel != null) ...[
                        const SizedBox(width: StorySpacing.md),
                        _NotificationActionButton(
                          label: presentation.actionLabel!,
                          secondary: presentation.secondaryAction,
                          loading: isFollowPending,
                          onPressed: isFollowAction
                              ? () => _handleFollowToggle(
                                  context,
                                  ref,
                                  current: presentation.followStatus!,
                                )
                              : item.eventType ==
                                    NotificationEventType.staminaLow
                              ? () => _popToMainInterface(
                                  context,
                                  ref,
                                  source: 'action',
                                )
                              : actionRouteName != null
                              ? () => context.storyPush(actionRouteName)
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionNotificationContent extends StatelessWidget {
  const _InteractionNotificationContent({
    required this.title,
    required this.message,
    required this.eventTime,
  });

  final String title;
  final String message;
  final String? eventTime;

  @override
  Widget build(BuildContext context) {
    final foreground = StoryColors.foregroundOf(Theme.of(context).brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 15,
            height: 22 / 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 15,
            height: 22 / 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        _NotificationTime(eventTime: eventTime),
      ],
    );
  }
}

class _NotificationTime extends StatelessWidget {
  const _NotificationTime({required this.eventTime});

  final String? eventTime;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Text(
      _formatEventTime(context, eventTime),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.04,
        color: brightness == Brightness.dark
            ? StoryColors.darkTertiaryText
            : StoryColors.lightTertiaryText,
      ),
    );
  }
}

class _NotificationThumbnail extends StatelessWidget {
  const _NotificationThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallback = SvgPicture.asset(
      isDark ? 'assets/common/empty_d.svg' : 'assets/common/empty.svg',
      width: 48,
      height: 48,
      fit: BoxFit.cover,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: imageUrl == null
          ? SizedBox.square(dimension: 48, child: fallback)
          : StoryCachedImage(
              imageUrl: imageUrl!,
              width: 48,
              height: 48,
              memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
                context,
                48,
              ),
              placeholder: fallback,
              errorWidget: fallback,
            ),
    );
  }
}

class _NotificationTag extends StatelessWidget {
  const _NotificationTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.sheetSecondaryOf(brightness),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            color: StoryColors.foregroundOf(brightness),
            fontSize: 12,
            height: 16 / 12,
            letterSpacing: 0.04,
          ),
        ),
      ),
    );
  }
}

class _NotificationMessage extends StatelessWidget {
  const _NotificationMessage({required this.lines});

  final List<_NotificationLine> lines;

  @override
  Widget build(BuildContext context) {
    final foreground = StoryColors.foregroundOf(Theme.of(context).brightness);
    const baseStyle = TextStyle(fontSize: 15, height: 22 / 15);
    return Text.rich(
      TextSpan(
        style: baseStyle.copyWith(color: foreground),
        children: [
          for (var index = 0; index < lines.length; index++) ...[
            if (index > 0) const TextSpan(text: '\n'),
            ..._buildHighlightedSpans(lines[index], foreground),
          ],
        ],
      ),
    );
  }

  List<InlineSpan> _buildHighlightedSpans(
    _NotificationLine line,
    Color foreground,
  ) {
    if (line.highlights.isEmpty) {
      return [
        TextSpan(
          text: line.text,
          style: TextStyle(
            fontWeight: line.bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ];
    }

    final matches = <({int start, int end, _NotificationHighlight value})>[];
    for (final highlight in line.highlights) {
      if (highlight.text.isEmpty) continue;
      final start = line.text.indexOf(highlight.text);
      if (start >= 0) {
        matches.add((
          start: start,
          end: start + highlight.text.length,
          value: highlight,
        ));
      }
    }
    matches.sort((a, b) => a.start.compareTo(b.start));

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start < cursor) continue;
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: line.text.substring(cursor, match.start),
            style: TextStyle(
              fontWeight: line.bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: line.text.substring(match.start, match.end),
          style: TextStyle(
            color: match.value.color ?? foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < line.text.length) {
      spans.add(
        TextSpan(
          text: line.text.substring(cursor),
          style: TextStyle(
            fontWeight: line.bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      );
    }
    return spans;
  }
}

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({
    required this.label,
    this.secondary = false,
    this.loading = false,
    this.onPressed,
  });

  final String label;
  final bool secondary;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final background = secondary
        ? StoryColors.sheetSecondaryOf(brightness)
        : StoryColors.darkButtonBgOf(brightness);
    final foreground = secondary
        ? StoryColors.foregroundOf(brightness)
        : StoryColors.onOverlay;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(80),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(80),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: loading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ),
      ),
    );
  }
}

class _NotificationPresentation {
  const _NotificationPresentation({
    this.isInteraction = false,
    this.title = '',
    this.interactionMessage = '',
    this.showThumbnail = false,
    this.trailingImageUrl,
    this.secondaryAction = false,
    this.tag = '',
    this.lines = const [],
    this.actionLabel,
    this.followStatus,
  });

  final bool isInteraction;
  final String title;
  final String interactionMessage;
  final bool showThumbnail;
  final String? trailingImageUrl;
  final bool secondaryAction;
  final String tag;
  final List<_NotificationLine> lines;
  final String? actionLabel;

  /// 仅 FOLLOW 类型通知有值，用于关注/取消关注按钮的展示与点击行为。
  /// 后端未下发时为 null（由调用方回退到 [FollowNotificationData.isMutual]）。
  final FollowRelationStatus? followStatus;

  factory _NotificationPresentation.from(
    BuildContext context,
    NotificationItem item,
  ) {
    final l10n = context.l10n;
    final operator =
        _firstNonEmpty([item.operateNickname, item.operateUserId]) ?? '';
    return switch (item.data) {
      final IpSignNotificationData data => () {
        final actor = data.ipName?.trim() ?? '';
        final amount = _amount(data.amount, data.assetCode);
        return _NotificationPresentation(
          tag: l10n.notificationTagIpSign,
          lines: [
            _NotificationLine(
              l10n.notificationSignedActor(operator, actor),
              highlights: [_NotificationHighlight(actor)],
            ),
            if (amount.isNotEmpty)
              _NotificationLine(
                l10n.notificationShareEarned(amount),
                bold: true,
                highlights: [
                  _NotificationHighlight(amount, color: StoryColors.star),
                ],
              ),
          ],
          actionLabel: amount.isEmpty ? null : l10n.notificationActionClaim,
        );
      }(),
      final StaminaLowNotificationData data => () {
        final actor = data.ipName?.trim() ?? '';
        final stamina = data.stamina?.toString() ?? '0';
        return _NotificationPresentation(
          tag: l10n.notificationTagRoleManagement,
          lines: [
            _NotificationLine(
              l10n.notificationStaminaLow(actor),
              highlights: [_NotificationHighlight(actor)],
            ),
            _NotificationLine(
              l10n.notificationCurrentStamina(stamina),
              bold: true,
              highlights: [
                _NotificationHighlight(stamina, color: StoryColors.star),
              ],
            ),
          ],
          actionLabel: l10n.notificationActionRefill,
        );
      }(),
      final ShowRewardNotificationData data => () {
        final amount = _amount(data.amount, data.assetCode);
        final range = _periodRange(context, data.periodStart, data.periodEnd);
        return _NotificationPresentation(
          tag: l10n.notificationTagShowRevenue,
          lines: [
            _NotificationLine(l10n.notificationShowEnded(range)),
            if (amount.isNotEmpty)
              _NotificationLine(
                l10n.notificationIncomeEarned(amount),
                bold: true,
                highlights: [
                  _NotificationHighlight(amount, color: StoryColors.star),
                ],
              ),
          ],
          actionLabel: amount.isEmpty ? null : l10n.notificationActionClaim,
        );
      }(),
      final TargetInteractionNotificationData data => _targetInteraction(
        l10n: l10n,
        type: item.eventType,
        data: data,
        operator: operator,
      ),
      final CommentNotificationData data => _commentInteraction(
        l10n: l10n,
        data: data,
        operator: operator,
      ),
      final FollowNotificationData data => _followInteraction(
        l10n: l10n,
        data: data,
        operator: operator,
      ),
      final UnknownNotificationData data => _NotificationPresentation(
        tag: (data.rawEventType ?? '').replaceAll('_', ' '),
        lines: [_NotificationLine(operator)],
      ),
    };
  }

  static String _amount(String? value, String? assetCode) {
    final rawAmount = value?.trim() ?? '';
    final amount = _formatAmount(rawAmount);
    final asset = assetCode?.trim() ?? '';
    return [amount, asset].where((part) => part.isNotEmpty).join(' ');
  }

  static String _formatAmount(String value) {
    if (value.isEmpty) return '';
    final formatted = formatNumber(value);
    return formatted == '-' ? value : formatted;
  }

  static String _periodRange(
    BuildContext context,
    String? periodStart,
    String? periodEnd,
  ) {
    String format(String? value) {
      final milliseconds = int.tryParse(value?.trim() ?? '');
      if (milliseconds == null) return '';
      final locale = Localizations.localeOf(context).toLanguageTag();
      return DateFormat.yMd(
        locale,
      ).format(DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal());
    }

    final start = format(periodStart);
    final end = format(periodEnd);
    return [start, end].where((part) => part.isNotEmpty).join(' ～ ');
  }

  static _NotificationPresentation _targetInteraction({
    required AppLocalizations l10n,
    required NotificationEventType type,
    required TargetInteractionNotificationData data,
    required String operator,
  }) {
    final targetName = data.targetName?.trim() ?? '';
    final message = switch (type) {
      NotificationEventType.favorite =>
        data.isDrama
            ? l10n.notificationInteractionFavoritedDrama(targetName)
            : l10n.notificationInteractionFavoritedVideo,
      _ =>
        data.isDrama
            ? l10n.notificationInteractionLikedDrama(targetName)
            : l10n.notificationInteractionLikedVideo,
    };

    return _NotificationPresentation(
      isInteraction: true,
      title: operator,
      interactionMessage: message,
      showThumbnail: true,
      trailingImageUrl: data.coverUrl,
    );
  }

  static _NotificationPresentation _commentInteraction({
    required AppLocalizations l10n,
    required CommentNotificationData data,
    required String operator,
  }) {
    return _NotificationPresentation(
      isInteraction: true,
      title: operator,
      interactionMessage: l10n.notificationInteractionCommented(
        data.content?.trim() ?? '',
      ),
      showThumbnail: true,
      trailingImageUrl: data.coverUrl,
    );
  }

  static _NotificationPresentation _followInteraction({
    required AppLocalizations l10n,
    required FollowNotificationData data,
    required String operator,
  }) {
    // 后端未下发 followStatus 时回退到旧的 isMutual 布尔，保持向后兼容。
    final status =
        data.followStatus ??
        (data.isMutual == true
            ? FollowRelationStatus.mutual
            : FollowRelationStatus.none);
    return _NotificationPresentation(
      isInteraction: true,
      title: operator,
      interactionMessage: l10n.notificationInteractionFollowedYou,
      actionLabel: _followActionLabel(l10n, status),
      // 已关注（FOLLOWING / MUTUAL）使用次级样式，未关注（NONE / FOLLOW_BACK）使用主样式。
      secondaryAction: status.isFollowing,
      followStatus: status,
    );
  }

  /// 关注按钮文案，按 4 态映射到现有 i18n key：
  ///
  /// - [FollowRelationStatus.none]       → 关注
  /// - [FollowRelationStatus.followBack] → 回关
  /// - [FollowRelationStatus.following]  → 已关注
  /// - [FollowRelationStatus.mutual]     → 互关
  static String _followActionLabel(
    AppLocalizations l10n,
    FollowRelationStatus status,
  ) {
    return switch (status) {
      FollowRelationStatus.none => l10n.notificationActionFollow,
      FollowRelationStatus.followBack => l10n.followActionFollowBack,
      FollowRelationStatus.following => l10n.followActionFollowing,
      FollowRelationStatus.mutual => l10n.notificationActionMutualFollow,
    };
  }
}

class _NotificationLine {
  const _NotificationLine(
    this.text, {
    this.bold = false,
    this.highlights = const [],
  });

  final String text;
  final bool bold;
  final List<_NotificationHighlight> highlights;
}

class _NotificationHighlight {
  const _NotificationHighlight(this.text, {this.color});

  final String text;
  final Color? color;
}

String _formatEventTime(BuildContext context, String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return '';
  final numeric = int.tryParse(raw);
  final date = numeric == null ? DateTime.tryParse(raw) : null;
  final milliseconds = numeric == null
      ? date?.millisecondsSinceEpoch
      : (numeric < 10000000000 ? numeric * 1000 : numeric);
  return FormatTime.formatRecentOrDateTime(context, milliseconds);
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}
