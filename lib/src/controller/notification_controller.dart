import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/models.dart';
import '../provider/repository_providers.dart';
import '../repositories/notification_repository.dart';
import 'notification_state.dart';

/// Loads one notification tab using the backend's cursor pagination contract.
class NotificationController extends Notifier<NotificationState> {
  NotificationController(this.tab);

  static const int _pageSize = 20;

  final int tab;
  late final NotificationRepository _repository;

  NotificationListRequest get _firstPageRequest =>
      NotificationListRequest(mark: 0, pageSize: _pageSize, tab: tab);

  @override
  NotificationState build() {
    _repository = ref.read(notificationRepositoryProvider);
    return const NotificationState();
  }

  Future<void> loadInitial() async {
    if (state.hasLoaded || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearLastError: true);

    final cached = await _repository.getCachedFirstPage(_firstPageRequest);
    if (!ref.mounted) return;
    if (cached != null) {
      _applyFirstPage(cached);
      await _fetchFirstPage(silent: true);
      return;
    }

    await _fetchFirstPage();
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearLastError: true);

    await _fetchFirstPage();
  }

  Future<void> _fetchFirstPage({bool silent = false}) async {
    final result = await _repository.listNotifications(_firstPageRequest);
    if (!ref.mounted) return;

    result.when(
      success: _applyFirstPage,
      failure: (error) {
        if (silent) return;
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasLoaded: true,
          lastError: error,
        );
      },
    );
  }

  void _applyFirstPage(NotificationPage page) {
    state = state.copyWith(
      items: page.list ?? const <NotificationItem>[],
      isLoading: false,
      isLoadingMore: false,
      hasLoaded: true,
      hasMore: page.hasMore ?? false,
      mark: page.mark ?? '-1',
      clearLastError: true,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasLoaded ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    final nextMark = int.tryParse(state.mark);
    if (nextMark == null || nextMark < 0) return;
    state = state.copyWith(isLoadingMore: true, clearLastError: true);

    final result = await _repository.listNotifications(
      NotificationListRequest(mark: nextMark, pageSize: _pageSize, tab: tab),
    );
    if (!ref.mounted) return;

    result.when(
      success: (page) {
        state = state.copyWith(
          items: [...state.items, ...?page.list],
          isLoadingMore: false,
          hasMore: page.hasMore ?? false,
          mark: page.mark ?? '-1',
          clearLastError: true,
        );
      },
      failure: (error) {
        state = state.copyWith(isLoadingMore: false, lastError: error);
      },
    );
  }

  /// Marks the tab only when its loaded list contains unread notifications.
  ///
  /// On success, updates the visible list.
  Future<bool> enterTab() async {
    await loadInitial();
    if (!ref.mounted || !state.items.any((item) => item.isUnread)) {
      return false;
    }

    final result = await _repository.markNotificationsRead(
      NotificationReadRequest(tab: tab),
    );
    if (ref.mounted && result.isSuccess) {
      state = state.copyWith(
        items: state.items
            .map((item) => item.copyWith(isRead: 1))
            .toList(growable: false),
      );
    }
    return result.isSuccess;
  }

  /// Optimistically removes the unread dot, restoring it if the API fails.
  Future<void> markRead(NotificationItem item) async {
    if (!item.isUnread) return;
    final id = int.tryParse(item.id ?? '');
    if (id == null) return;

    final index = state.items.indexWhere(
      (candidate) => candidate.id == item.id,
    );
    if (index < 0) return;
    final previous = state.items;
    final updated = List<NotificationItem>.of(previous);
    updated[index] = _copyWithRead(item);
    state = state.copyWith(items: updated);

    final result = await _repository.markNotificationsRead(
      NotificationReadRequest(ids: [id]),
    );
    if (!ref.mounted || result.isSuccess) return;
    state = state.copyWith(items: previous, lastError: result.errorOrNull);
  }

  NotificationItem _copyWithRead(NotificationItem item) =>
      item.copyWith(isRead: 1);

  /// 在内存中将指定通知的 [FollowNotificationData.followStatus] 更新为 [status]。
  ///
  /// 用于「关注 / 取消关注」按钮点击后的乐观更新：UI 立即反映新状态，
  /// 调用方在 API 失败时再以原 status 调用一次本方法回滚即可。
  void patchFollowStatus(String notificationId, FollowRelationStatus status) {
    final index = state.items.indexWhere(
      (candidate) => candidate.id == notificationId,
    );
    if (index < 0 || !ref.mounted) return;
    final item = state.items[index];
    if (item.data is! FollowNotificationData) return;
    final updated = List<NotificationItem>.of(state.items);
    updated[index] = item.copyWith(
      data: (item.data as FollowNotificationData).copyWith(
        followStatus: status,
      ),
    );
    state = state.copyWith(items: updated);
  }

  /// Optimistically removes [item] from the local list, then deletes it on
  /// the server.
  ///
  /// The row disappears immediately (letting the Slidable animation settle)
  /// and the API call fires in the background. If the call fails, the item is
  /// restored to its original position and [ApiError] is surfaced via
  /// [NotificationState.lastError] so the UI can show a toast via
  /// `handleApiError`.
  ///
  /// Returns `true` if the API call succeeds, `false` otherwise (the item
  /// will already be restored by the time `false` is returned).
  Future<bool> deleteNotification(NotificationItem item) async {
    final id = int.tryParse(item.id ?? '');
    if (id == null) return false;

    final previous = state.items;
    final updated = List<NotificationItem>.of(previous)
      ..removeWhere((candidate) => candidate.id == item.id);
    state = state.copyWith(items: updated);

    final result = await _repository.deleteNotification(
      NotificationDeleteRequest(id: id),
    );
    if (!ref.mounted) return result.isSuccess;
    if (result.isSuccess) return true;

    state = state.copyWith(items: previous, lastError: result.errorOrNull);
    return false;
  }
}
