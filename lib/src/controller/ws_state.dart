import 'package:equatable/equatable.dart';

import '../services/ws_service.dart';

/// App-facing realtime state. Protocol details remain inside [WsService].
class WsState extends Equatable {
  final WsConnectionStatus status;
  final String? currentUserId;
  final Set<String> subscribedChannels;
  final String? errorMessage;

  const WsState({
    this.status = WsConnectionStatus.disconnected,
    this.currentUserId,
    this.subscribedChannels = const {},
    this.errorMessage,
  });

  WsState copyWith({
    WsConnectionStatus? status,
    String? currentUserId,
    bool clearCurrentUserId = false,
    Set<String>? subscribedChannels,
    String? errorMessage,
    bool clearError = false,
  }) => WsState(
    status: status ?? this.status,
    currentUserId: clearCurrentUserId
        ? null
        : (currentUserId ?? this.currentUserId),
    subscribedChannels: subscribedChannels ?? this.subscribedChannels,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [
    status,
    currentUserId,
    subscribedChannels,
    errorMessage,
  ];
}
