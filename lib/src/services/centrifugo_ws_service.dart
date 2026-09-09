import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:meta/meta.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../repositories/user_repository.dart';
import 'ws_service.dart';

typedef CentrifugeClientFactory =
    centrifuge.Client Function(String url, centrifuge.ClientConfig config);

/// [WsService] backed by the official `centrifuge` Dart SDK.
///
/// Connection protocol, heartbeat, token refresh, reconnect backoff and
/// subscription recovery are delegated to the SDK. This class owns only the
/// app-specific token endpoint, JSON decoding, logging and channel registry.
class CentrifugoWsService extends WsService {
  static const _tokenEndpoint = '/api/userWallet/centrifugo/token';

  final UserRepository _userRepository;
  final String _apiBaseUrl;
  final Duration _timeout;
  final CentrifugeClientFactory _clientFactory;

  final _statusController = StreamController<WsConnectionStatus>.broadcast(
    sync: true,
  );
  final _channelStateController =
      StreamController<WsChannelStateEvent>.broadcast(sync: true);
  final _publicationController = StreamController<WsPublication>.broadcast(
    sync: true,
  );
  final _errorController = StreamController<Object>.broadcast(sync: true);

  centrifuge.Client? _client;
  final Map<String, centrifuge.Subscription> _subscriptions = {};
  final Map<String, List<StreamSubscription<dynamic>>> _subscriptionListeners =
      {};

  // Cancelled by [reset] and [dispose].
  // ignore: cancel_subscriptions
  final List<StreamSubscription<dynamic>> _clientListeners = [];

  WsConnectionStatus _status = WsConnectionStatus.disconnected;
  final Set<String> _subscribedChannels = {};
  String? _currentUserId;
  bool _disposed = false;
  bool _resetting = false;
  Stopwatch? _connectionStopwatch;

  factory CentrifugoWsService({
    required UserRepository userRepository,
    required String apiBaseUrl,
    Duration timeout = const Duration(seconds: 15),
    CentrifugeClientFactory clientFactory = centrifuge.createClient,
  }) =>
      CentrifugoWsService._(userRepository, apiBaseUrl, timeout, clientFactory);

  CentrifugoWsService._(
    this._userRepository,
    this._apiBaseUrl,
    this._timeout,
    this._clientFactory,
  );

  @override
  WsConnectionStatus get status => _status;

  @override
  String? get currentUserId => _currentUserId;

  @override
  Set<String> get subscribedChannels =>
      Set<String>.unmodifiable(_subscribedChannels);

  @override
  Stream<WsConnectionStatus> get statuses => _statusController.stream;

  @override
  Stream<WsChannelStateEvent> get channelStates =>
      _channelStateController.stream;

  @override
  Stream<WsPublication> get publications => _publicationController.stream;

  @override
  Stream<Object> get errors => _errorController.stream;

  /// SDK endpoint. Protobuf is negotiated through the
  /// `centrifuge-protobuf` WebSocket subprotocol, so no JSON format query is
  /// appended here.
  @visibleForTesting
  static Uri buildWebSocketUri(String apiBaseUrl) {
    final apiUri = Uri.parse(apiBaseUrl);
    final scheme = switch (apiUri.scheme) {
      'https' => 'wss',
      'http' => 'ws',
      final value => value,
    };
    return apiUri.replace(
      scheme: scheme,
      path: '/centrifugo/connection/websocket',
    );
  }

  @override
  Future<void> connect() async {
    if (_disposed) {
      StoryLogger.w(
        'Centrifugo connect ignored because WsService is disposed',
        tag: 'Centrifugo',
      );
      return;
    }

    final client = _client ??= _createClient();
    if (client.state == centrifuge.State.connected ||
        client.state == centrifuge.State.connecting) {
      StoryLogger.d(
        'Centrifugo connect skipped (sdkState=${client.state.name})',
        tag: 'Centrifugo',
      );
      return;
    }

    // Always obtain a fresh connection token after an intentional disconnect.
    client.setToken('');
    _connectionStopwatch = Stopwatch()..start();
    _setStatus(WsConnectionStatus.connecting);
    StoryLogger.i(
      'Centrifugo connecting (endpoint=${buildWebSocketUri(_apiBaseUrl)})',
      tag: 'Centrifugo',
    );
    try {
      await client.connect();
    } catch (error, stackTrace) {
      _setStatus(WsConnectionStatus.disconnected);
      StoryLogger.w(
        'Centrifugo connection failed '
        '(elapsedMs=${_elapsedMilliseconds()})',
        error: error,
        stackTrace: stackTrace,
        tag: 'Centrifugo',
      );
      _emitError(error);
    }
  }

  centrifuge.Client _createClient() {
    final uri = buildWebSocketUri(_apiBaseUrl);
    final client = _clientFactory(
      uri.toString(),
      centrifuge.ClientConfig(
        getToken: (_) => _loadConnectionToken(),
        timeout: _timeout,
        maxReconnectDelay: const Duration(seconds: 30),
        name: 'story_app',
      ),
    );
    _attachClientListeners(client);
    return client;
  }

  Future<String> _loadConnectionToken() async {
    StoryLogger.d(
      'Requesting Centrifugo connection credentials from $_tokenEndpoint',
      tag: 'Centrifugo',
    );
    final result = await _userRepository.getCentrifugoConnectionInfo();
    final info = result.dataOrNull;
    if (info == null || !info.isValid) {
      final error = result.errorOrNull;
      StoryLogger.w(
        'Centrifugo connection token request failed',
        error: error,
        tag: 'Centrifugo',
      );
      if (error is UnauthorizedError) {
        throw centrifuge.UnauthorizedException();
      }
      throw StateError(error?.userMessage ?? 'Invalid Centrifugo credentials');
    }
    _currentUserId = info.userId;
    StoryLogger.d(
      'Centrifugo credentials loaded '
      '(userId=${info.userId}, token=<redacted>)',
      tag: 'Centrifugo',
    );
    return info.token;
  }

  void _attachClientListeners(centrifuge.Client client) {
    _clientListeners
      ..add(
        client.connecting.listen((event) {
          _setStatus(WsConnectionStatus.connecting);
          StoryLogger.i(
            'Centrifugo connecting '
            '(code=${event.code}, reason=${event.reason})',
            tag: 'Centrifugo',
          );
        }),
      )
      ..add(
        client.connected.listen((event) {
          _setStatus(WsConnectionStatus.connected);
          _connectionStopwatch?.stop();
          StoryLogger.i(
            'Centrifugo connection succeeded '
            '(client=${event.client}, serverVersion=${event.version}, '
            'userId=${_currentUserId ?? 'unknown'}, '
            'elapsedMs=${_elapsedMilliseconds()})',
            tag: 'Centrifugo',
          );
        }),
      )
      ..add(
        client.disconnected.listen((event) {
          _setStatus(WsConnectionStatus.disconnected);
          if (!_resetting) {
            StoryLogger.w(
              'Centrifugo disconnected '
              '(code=${event.code}, reason=${event.reason})',
              tag: 'Centrifugo',
            );
          }
        }),
      )
      ..add(
        client.error.listen((event) {
          final error = _asObjectError(event.error, 'Unknown SDK error');
          StoryLogger.w(
            'Centrifugo SDK error',
            error: error,
            tag: 'Centrifugo',
          );
          _emitError(error);
        }),
      );
  }

  @override
  Future<void> subscribe(String channel) async {
    final normalized = channel.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(channel, 'channel', 'must not be empty');
    }
    final client = _client;
    if (client == null) {
      throw StateError('Connect WsService before subscribing');
    }

    var subscription = _subscriptions[normalized];
    if (subscription == null) {
      subscription = client.newSubscription(normalized);
      _subscriptions[normalized] = subscription;
      _attachSubscriptionListeners(subscription);
    }
    if (subscription.state == centrifuge.SubscriptionState.subscribed ||
        subscription.state == centrifuge.SubscriptionState.subscribing) {
      return;
    }

    StoryLogger.d(
      'Centrifugo subscribing (channel=$normalized)',
      tag: 'Centrifugo',
    );
    await subscription.subscribe();
  }

  void _attachSubscriptionListeners(centrifuge.Subscription subscription) {
    final channel = subscription.channel;
    _subscriptionListeners[channel] = [
      subscription.subscribing.listen((event) {
        _subscribedChannels.remove(channel);
        _emitChannelState(
          WsChannelStateEvent(
            channel: channel,
            status: WsChannelStatus.subscribing,
            code: event.code,
            reason: event.reason,
          ),
        );
        StoryLogger.d(
          'Centrifugo channel subscribing '
          '(channel=$channel, code=${event.code}, reason=${event.reason})',
          tag: 'Centrifugo',
        );
      }),
      subscription.subscribed.listen((event) {
        _subscribedChannels.add(channel);
        _emitChannelState(
          WsChannelStateEvent(
            channel: channel,
            status: WsChannelStatus.subscribed,
          ),
        );
        StoryLogger.i(
          'Centrifugo channel subscribed '
          '(channel=$channel, recovered=${event.recovered})',
          tag: 'Centrifugo',
        );
      }),
      subscription.unsubscribed.listen((event) {
        _subscribedChannels.remove(channel);
        _emitChannelState(
          WsChannelStateEvent(
            channel: channel,
            status: WsChannelStatus.unsubscribed,
            code: event.code,
            reason: event.reason,
          ),
        );
        StoryLogger.w(
          'Centrifugo channel unsubscribed '
          '(channel=$channel, code=${event.code}, reason=${event.reason})',
          tag: 'Centrifugo',
        );
      }),
      subscription.error.listen((event) {
        final error = _asObjectError(event.error, 'Unknown subscription error');
        StoryLogger.w(
          'Centrifugo channel error (channel=$channel)',
          error: error,
          tag: 'Centrifugo',
        );
        _emitError(error);
      }),
      subscription.publication.listen((event) {
        _handlePublication(channel, event.data);
      }),
    ];
  }

  void _handlePublication(String channel, List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        throw const FormatException('Publication data is not a JSON object');
      }
      final data = Map<String, dynamic>.from(decoded);
      StoryLogger.d(
        'Centrifugo publication received '
        '(channel=$channel, keys=${data.keys.join(',')})',
        tag: 'Centrifugo',
      );
      if (!_publicationController.isClosed) {
        _publicationController.add(WsPublication(channel: channel, data: data));
      }
    } catch (error, stackTrace) {
      StoryLogger.w(
        'Unable to decode Centrifugo publication (channel=$channel)',
        error: error,
        stackTrace: stackTrace,
        tag: 'Centrifugo',
      );
      _emitError(error);
    }
  }

  @override
  Future<void> unsubscribe(String channel) async {
    final normalized = channel.trim();
    final client = _client;
    final subscription = _subscriptions.remove(normalized);
    if (client == null || subscription == null) return;

    final listeners = _subscriptionListeners.remove(normalized) ?? const [];
    await client.removeSubscription(subscription);
    await Future.wait(listeners.map((listener) => listener.cancel()));
    _subscribedChannels.remove(normalized);
    _emitChannelState(
      WsChannelStateEvent(
        channel: normalized,
        status: WsChannelStatus.unsubscribed,
      ),
    );
  }

  @override
  Future<void> publish(String channel, Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) throw StateError('WsService is not connected');
    await client.publish(channel, utf8.encode(jsonEncode(data)));
  }

  @override
  Future<void> disconnect() async {
    final client = _client;
    if (client == null || client.state == centrifuge.State.disconnected) return;
    StoryLogger.i('Centrifugo disconnecting temporarily', tag: 'Centrifugo');
    await client.disconnect();
    _setStatus(WsConnectionStatus.disconnected);
  }

  @override
  Future<void> reset() async {
    _resetting = true;
    final client = _client;
    final hadSession =
        client != null ||
        _currentUserId != null ||
        _subscriptions.isNotEmpty ||
        _status != WsConnectionStatus.disconnected;
    _client = null;
    _currentUserId = null;
    _connectionStopwatch?.stop();
    _connectionStopwatch = null;

    await _cancelAll(_clientListeners);
    for (final listeners in _subscriptionListeners.values) {
      await _cancelAll(listeners);
    }
    _subscriptionListeners.clear();
    _subscriptions.clear();
    _subscribedChannels.clear();
    try {
      await client?.close();
    } catch (error, stackTrace) {
      StoryLogger.w(
        'Centrifugo client close failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'Centrifugo',
      );
    } finally {
      _setStatus(WsConnectionStatus.disconnected);
      _resetting = false;
      if (hadSession) {
        StoryLogger.i('Centrifugo session reset', tag: 'Centrifugo');
      }
    }
  }

  Future<void> _cancelAll(List<StreamSubscription<dynamic>> listeners) async {
    final pending = List<StreamSubscription<dynamic>>.of(listeners);
    listeners.clear();
    await Future.wait(pending.map((listener) => listener.cancel()));
  }

  void _setStatus(WsConnectionStatus next) {
    if (_status == next) return;
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  void _emitChannelState(WsChannelStateEvent event) {
    if (!_channelStateController.isClosed) {
      _channelStateController.add(event);
    }
  }

  void _emitError(Object error) {
    if (!_errorController.isClosed) _errorController.add(error);
  }

  static Object _asObjectError(dynamic value, String fallbackMessage) =>
      value == null ? StateError(fallbackMessage) : value as Object;

  int _elapsedMilliseconds() => _connectionStopwatch?.elapsedMilliseconds ?? 0;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await reset();
    await _statusController.close();
    await _channelStateController.close();
    await _publicationController.close();
    await _errorController.close();
  }
}
