import 'package:equatable/equatable.dart';

import '../model/notification_models.dart';

/// Notification-module state derived from the shared realtime transport.
class RealtimeNotificationState extends Equatable {
  final NotificationItem? latestNotification;
  final int revision;
  final String? errorMessage;

  const RealtimeNotificationState({
    this.latestNotification,
    this.revision = 0,
    this.errorMessage,
  });

  RealtimeNotificationState copyWith({
    NotificationItem? latestNotification,
    bool clearLatestNotification = false,
    int? revision,
    String? errorMessage,
    bool clearError = false,
  }) => RealtimeNotificationState(
    latestNotification: clearLatestNotification
        ? null
        : (latestNotification ?? this.latestNotification),
    revision: revision ?? this.revision,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [latestNotification, revision, errorMessage];
}
