import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network connection type for bandwidth-aware strategies.
enum ConnectionType { wifi, cellular, other }

/// Network connectivity monitor.
///
/// Wraps [Connectivity] from `connectivity_plus` to expose a simple
/// `ValueNotifier<bool>` (`true` = online, `false` = offline).
///
/// Also exposes [connectionType] for bandwidth-aware prefetch strategies.
///
/// `StoryApiClient` relies on this to short-circuit retries when offline.
class ConnectivityService extends ValueNotifier<bool> {
  ConnectivityService() : super(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final Connectivity _connectivity = Connectivity();
  ConnectionType _connectionType = ConnectionType.other;

  ConnectionType get connectionType => _connectionType;

  bool get isWifi => _connectionType == ConnectionType.wifi;

  bool get isCellular => _connectionType == ConnectionType.cellular;

  Future<void> initialize() async {
    // Check initial connectivity state.
    try {
      final results = await _connectivity.checkConnectivity();
      _update(results);
    } catch (_) {
      // Assume online if check fails (e.g. platform exception).
      value = true;
    }

    // Listen for changes.
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _update(results);
    });
  }

  void _update(List<ConnectivityResult> results) {
    final wasOnline = value;
    final previousType = _connectionType;
    _connectionType = _classify(results);
    value = _isOnline(results);
    // A Wi-Fi ↔ cellular switch keeps `value` online, but bandwidth-aware
    // consumers (e.g. the upload queue's cellular policy) must still be
    // notified, so fire explicitly when only the type changed.
    if (value == wasOnline && _connectionType != previousType) {
      notifyListeners();
    }
  }

  ConnectionType _classify(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectionType.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionType.cellular;
    }
    return ConnectionType.other;
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      !results.contains(ConnectivityResult.none);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
