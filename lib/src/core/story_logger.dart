import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum StoryLogLevel { verbose, debug, info, warning, error, none }

@immutable
class StoryLogRecord {
  const StoryLogRecord({
    required this.level,
    required this.message,
    required this.timestamp,
    this.tag,
    this.error,
    this.stackTrace,
  });

  final StoryLogLevel level;
  final String message;
  final DateTime timestamp;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;
}

typedef StoryLogListener = void Function(StoryLogRecord record);

class StoryLogger {
  StoryLogger._();

  static StoryLogLevel _minLevel = StoryLogLevel.debug;
  static final Set<String> _ignoredTags = {};
  static final Set<StoryLogListener> _listeners = {};

  static void setMinLevel(StoryLogLevel level) {
    _minLevel = (kReleaseMode && level.index < StoryLogLevel.warning.index)
        ? StoryLogLevel.warning
        : level;
  }

  static void ignoreTag(String tag) => _ignoredTags.add(tag);

  static void addListener(StoryLogListener listener) {
    _listeners.add(listener);
  }

  static void removeListener(StoryLogListener listener) {
    _listeners.remove(listener);
  }

  static bool _shouldLog(StoryLogLevel level, String? tag) {
    if (_ignoredTags.contains(tag)) return false;
    return level.index >= _minLevel.index;
  }

  static void _output(
    String message, {
    required StoryLogLevel logLevel,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    int level = 500,
  }) {
    final prefix = tag != null ? '[$tag]' : '[Story]';
    final logLine = error != null
        ? '$prefix $message\n  error: $error'
        : '$prefix $message';
    // Always print to stdout so logs appear in terminal / flutter run console
    debugPrint(logLine);
    developer.log(
      message,
      name: tag ?? 'Story',
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
    final record = StoryLogRecord(
      level: logLevel,
      message: message,
      timestamp: DateTime.now(),
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
    for (final listener in List<StoryLogListener>.of(_listeners)) {
      try {
        listener(record);
      } catch (listenerError, listenerStackTrace) {
        debugPrint(
          '[StoryLogger] Log listener failed: $listenerError\n'
          '$listenerStackTrace',
        );
      }
    }
  }

  static void v(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(StoryLogLevel.verbose, tag)) return;
    _output(
      message,
      logLevel: StoryLogLevel.verbose,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      level: 300,
    );
  }

  static void d(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(StoryLogLevel.debug, tag)) return;
    _output(
      message,
      logLevel: StoryLogLevel.debug,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void i(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(StoryLogLevel.info, tag)) return;
    _output(
      message,
      logLevel: StoryLogLevel.info,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      level: 800,
    );
  }

  static void w(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(StoryLogLevel.warning, tag)) return;
    _output(
      message,
      logLevel: StoryLogLevel.warning,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      level: 900,
    );
  }

  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(StoryLogLevel.error, tag)) return;
    _output(
      message,
      logLevel: StoryLogLevel.error,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
