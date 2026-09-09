import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/centrifugo_ws_service.dart';
import '../services/ws_service.dart';
import 'core_providers.dart';
import 'repository_providers.dart';

/// Single app-wide transport shared by every realtime feature module.
final Provider<WsService> wsServiceProvider = Provider<WsService>((ref) {
  final config = ref.read(storySdkConfigProvider);
  final service = CentrifugoWsService(
    userRepository: ref.read(userRepositoryProvider),
    apiBaseUrl: config.effectiveApiBaseUrl,
    timeout: config.connectTimeout,
  );
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});
