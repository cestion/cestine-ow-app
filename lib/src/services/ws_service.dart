/// Transport-agnostic WebSocket connection status exposed to the app.
enum WsConnectionStatus { disconnected, connecting, connected }

/// Subscription lifecycle for one realtime channel.
enum WsChannelStatus { unsubscribed, subscribing, subscribed }

class WsChannelStateEvent {
  final String channel;
  final WsChannelStatus status;
  final int? code;
  final String? reason;

  const WsChannelStateEvent({
    required this.channel,
    required this.status,
    this.code,
    this.reason,
  });
}

/// A decoded JSON publication shared by all feature modules.
class WsPublication {
  final String channel;
  final Map<String, dynamic> data;

  const WsPublication({required this.channel, required this.data});
}

/// Realtime transport contract consumed by controllers and feature modules.
///
/// This keeps Centrifugo SDK types out of the rest of the application.
abstract class WsService {
  WsConnectionStatus get status;
  String? get currentUserId;
  Set<String> get subscribedChannels;

  Stream<WsConnectionStatus> get statuses;
  Stream<WsChannelStateEvent> get channelStates;
  Stream<WsPublication> get publications;
  Stream<Object> get errors;

  Stream<WsPublication> publicationsFor(String channel) =>
      publications.where((event) => event.channel == channel);

  Future<void> connect();

  /// Temporarily disconnects while retaining channel registrations.
  Future<void> disconnect();

  Future<void> subscribe(String channel);
  Future<void> unsubscribe(String channel);
  Future<void> publish(String channel, Map<String, dynamic> data);

  /// Clears the authenticated client and all user-scoped subscriptions.
  Future<void> reset();

  Future<void> dispose();
}
