import 'dart:async';

import 'package:flutter/material.dart';

import '../core/story_logger.dart';
import '../data/repository/story_local_repository.dart';

class StoryThemeController {
  StoryThemeController._(this._local);

  final StoryLocalRepository? _local;
  final StreamController<ThemeMode> _changes =
      StreamController<ThemeMode>.broadcast();
  ThemeMode _current = ThemeMode.system;

  Stream<ThemeMode> get changes => _changes.stream;
  ThemeMode get current => _current;

  static StoryThemeController? _instance;

  static StoryThemeController get instance {
    _instance ??= StoryThemeController._(null);
    return _instance!;
  }

  static StoryThemeController initialize(StoryLocalRepository local) {
    _instance = StoryThemeController._(local);
    _instance!._load();
    return _instance!;
  }

  void _load() {
    final local = _local;
    if (local == null) return;
    final raw = local.getThemeMode();
    _current = _parseThemeMode(raw);
    StoryLogger.d('Theme loaded: $_current', tag: 'Theme');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _current = mode;
    _changes.add(mode);
    final local = _local;
    if (local != null) {
      await local.setThemeMode(_modeToString(mode));
    }
    StoryLogger.d('Theme changed: $mode', tag: 'Theme');
  }

  static ThemeMode _parseThemeMode(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> dispose() async {
    await _changes.close();
  }
}
