import 'package:alice/alice.dart';
import 'package:alice/model/alice_configuration.dart';
import 'package:alice_http/alice_http_adapter.dart';
import 'package:flutter/foundation.dart';

import '../core/story_logger.dart';
import '../foundation/navigator.dart';

class AliceInspectorService {
  AliceInspectorService._();

  static bool _isStoryLoggerAttached = false;

  static final Alice instance = Alice(
    configuration: AliceConfiguration(
      navigatorKey: StoryNavigator.instance.navigatorKey,
      storage: AliceMemoryStorage(maxCallsCount: 100),
      showNotification: false,
      showInspectorOnShake: false,
    ),
  );

  static final AliceHttpAdapter httpAdapter = _createHttpAdapter();

  static AliceHttpAdapter _createHttpAdapter() {
    final adapter = AliceHttpAdapter();
    instance.addAdapter(adapter);
    return adapter;
  }

  static void configureStoryLogger({required bool enabled}) {
    if (enabled == _isStoryLoggerAttached) return;
    _isStoryLoggerAttached = enabled;
    if (enabled) {
      StoryLogger.addListener(_addStoryLog);
    } else {
      StoryLogger.removeListener(_addStoryLog);
    }
  }

  static void _addStoryLog(StoryLogRecord record) {
    instance.addLog(
      AliceLog(
        message: record.tag == null
            ? record.message
            : '[${record.tag}] ${record.message}',
        level: _diagnosticLevel(record.level),
        timestamp: record.timestamp,
        error: record.error,
        stackTrace: record.stackTrace,
      ),
    );
  }

  static DiagnosticLevel _diagnosticLevel(StoryLogLevel level) {
    return switch (level) {
      StoryLogLevel.verbose => DiagnosticLevel.fine,
      StoryLogLevel.debug => DiagnosticLevel.debug,
      StoryLogLevel.info => DiagnosticLevel.info,
      StoryLogLevel.warning => DiagnosticLevel.warning,
      StoryLogLevel.error || StoryLogLevel.none => DiagnosticLevel.error,
    };
  }

  static void showInspector() => instance.showInspector();
}
