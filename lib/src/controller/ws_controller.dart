import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ws_service.dart';
import 'auth_controller.dart';
import 'provider/ws_controller_providers.dart';
import 'ws_state.dart';

/// App-scoped realtime coordinator.
///
/// Owns authentication and app-lifecycle orchestration while [WsService]
/// remains a reusable transport that feature modules can share.
class WsController extends Notifier<WsState> with WidgetsBindingObserver {
  late final WsService _service;
  late final AuthController _auth;

  StreamSubscription<bool>? _authSubscription;
  StreamSubscription<WsConnectionStatus>? _statusSubscription;
  StreamSubscription<WsChannelStateEvent>? _channelSubscription;
  StreamSubscription<Object>? _errorSubscription;

  bool _isForeground = true;
  int _authRevision = 0;
  Future<void> _resetFuture = Future<void>.value();

  @override
  WsState build() {
    _service = ref.read(wsServiceProvider);
    _auth = ref.read(authControllerProvider.notifier);

    WidgetsBinding.instance.addObserver(this);
    _authSubscription = _auth.authStateChanges.listen(_handleAuthChange);
    _statusSubscription = _service.statuses.listen(_handleStatus);
    _channelSubscription = _service.channelStates.listen(_handleChannelState);
    _errorSubscription = _service.errors.listen(_handleError);

    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      unawaited(_authSubscription?.cancel());
      unawaited(_statusSubscription?.cancel());
      unawaited(_channelSubscription?.cancel());
      unawaited(_errorSubscription?.cancel());
      unawaited(_resetSession());
    });

    Future.microtask(_syncAuthState);
    return WsState(
      status: _service.status,
      currentUserId: _service.currentUserId,
      subscribedChannels: _service.subscribedChannels,
    );
  }

  void _handleAuthChange(bool loggedIn) {
    final revision = ++_authRevision;
    if (!loggedIn) {
      state = state.copyWith(
        status: WsConnectionStatus.disconnected,
        clearCurrentUserId: true,
        subscribedChannels: const {},
        clearError: true,
      );
      unawaited(_resetSession());
      return;
    }
    unawaited(_connectWhenReady(revision));
  }

  Future<void> _syncAuthState() async {
    final revision = ++_authRevision;
    await _connectWhenReady(revision);
  }

  Future<void> _connectWhenReady(int revision) async {
    await _auth.ready;
    await _resetFuture;
    if (!ref.mounted || revision != _authRevision) return;
    if (!_auth.isLoggedIn) {
      await _resetSession();
      return;
    }
    if (!_isForeground) return;

    await _service.connect();
    if (!ref.mounted || revision != _authRevision) return;
    if (!_isForeground) {
      await _service.disconnect();
    }
  }

  void _handleStatus(WsConnectionStatus status) {
    if (!ref.mounted) return;
    state = state.copyWith(
      status: status,
      currentUserId: _service.currentUserId,
      subscribedChannels: _service.subscribedChannels,
      clearError: status == WsConnectionStatus.connected,
    );
  }

  void _handleChannelState(WsChannelStateEvent event) {
    if (!ref.mounted) return;
    state = state.copyWith(subscribedChannels: _service.subscribedChannels);
  }

  void _handleError(Object error) {
    if (!ref.mounted) return;
    state = state.copyWith(errorMessage: error.toString());
  }

  Future<void> _resetSession() {
    final previous = _resetFuture;
    final next = () async {
      try {
        await previous;
      } catch (_) {
        // A new reset still needs to run after an earlier cleanup failure.
      }
      await _service.reset();
    }();
    _resetFuture = next;
    return next;
  }

  /// Allows feature modules to share the same authenticated connection.
  Future<void> subscribeChannel(String channel) => _service.subscribe(channel);

  Future<void> unsubscribeChannel(String channel) =>
      _service.unsubscribe(channel);

  Future<void> publish(String channel, Map<String, dynamic> data) =>
      _service.publish(channel, data);

  Stream<WsPublication> get publications => _service.publications;

  Stream<WsPublication> publicationsFor(String channel) =>
      _service.publicationsFor(channel);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isForeground = true;
        unawaited(_syncAuthState());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _isForeground = false;
        unawaited(_service.disconnect());
      case AppLifecycleState.detached:
        _isForeground = false;
        unawaited(_resetSession());
      case AppLifecycleState.inactive:
        // Keep the connection for short interruptions such as system dialogs.
        break;
    }
  }
}
