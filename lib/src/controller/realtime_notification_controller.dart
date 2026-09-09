import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/story_logger.dart';
import '../model/notification_models.dart';
import '../provider/app_providers.dart';
import '../services/ws_service.dart';
import 'realtime_notification_state.dart';
import 'ws_controller.dart';
import 'ws_state.dart';

/// Notification-module adapter for the shared [WsController].
///
/// Other realtime features should follow the same pattern: own their channel
/// naming and payload parsing while reusing the global connection.
class RealtimeNotificationController
    extends Notifier<RealtimeNotificationState> {
  late final WsController _wsController;
  StreamSubscription<WsPublication>? _publicationSubscription;
  String? _channel;
  int _sessionRevision = 0;

  @override
  RealtimeNotificationState build() {
    _wsController = ref.read(wsControllerProvider.notifier);
    _publicationSubscription = _wsController.publications.listen(
      _handlePublication,
    );
    ref.listen<WsState>(wsControllerProvider, (_, next) {
      _handleWsState(next);
    });
    ref.onDispose(() => unawaited(_publicationSubscription?.cancel()));

    Future.microtask(() {
      if (ref.mounted) _handleWsState(ref.read(wsControllerProvider));
    });
    return const RealtimeNotificationState();
  }

  void _handleWsState(WsState wsState) {
    if (!ref.mounted) return;
    final revision = ++_sessionRevision;
    final userId = wsState.currentUserId?.trim();
    if (userId == null || userId.isEmpty) {
      _channel = null;
      state = state.copyWith(clearLatestNotification: true, clearError: true);
      return;
    }
    if (wsState.status != WsConnectionStatus.connected) return;
    unawaited(_subscribeForUser(userId, revision));
  }

  Future<void> _subscribeForUser(String userId, int revision) async {
    final channel = 'personal:user:notification#$userId';
    _channel = channel;
    try {
      await _wsController.subscribeChannel(channel);
      if (!ref.mounted || revision != _sessionRevision) return;
      StoryLogger.d(
        'Realtime notification channel ready (channel=$channel)',
        tag: 'RealtimeNotification',
      );
    } catch (error, stackTrace) {
      StoryLogger.w(
        'Realtime notification subscription failed (channel=$channel)',
        error: error,
        stackTrace: stackTrace,
        tag: 'RealtimeNotification',
      );
      _handleError(error);
    }
  }

  void _handlePublication(WsPublication publication) {
    if (!ref.mounted || publication.channel != _channel) return;
    final raw = publication.data['notification'];
    if (raw is! Map) {
      StoryLogger.w(
        'Realtime notification publication has no notification object',
        tag: 'RealtimeNotification',
      );
      return;
    }
    try {
      final notification = NotificationItem.fromJson(
        Map<String, dynamic>.from(raw),
      );
      StoryLogger.d(
        'Realtime notification decoded '
        '(id=${notification.id ?? 'unknown'}, '
        'type=${notification.eventType.wireValue})',
        tag: 'RealtimeNotification',
      );
      state = state.copyWith(
        latestNotification: notification,
        revision: state.revision + 1,
        clearError: true,
      );
    } catch (error, stackTrace) {
      StoryLogger.w(
        'Realtime notification decode failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'RealtimeNotification',
      );
      _handleError(error);
    }
  }

  void _handleError(Object error) {
    if (ref.mounted) state = state.copyWith(errorMessage: error.toString());
  }
}
