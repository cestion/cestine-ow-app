import 'dart:async';

import 'package:flutter/material.dart';

import '../core/story_logger.dart';
import '../data/repository/story_local_repository.dart';
export '../l10n/story_l10n.dart';

class StoryLocaleController {
  StoryLocaleController._(this._local);

  final StoryLocalRepository? _local;
  final StreamController<Locale> _changes =
      StreamController<Locale>.broadcast();
  Locale _current = const Locale('zh', 'CN');

  static StoryLocaleController? _instance;

  static StoryLocaleController get instance {
    _instance ??= StoryLocaleController._(null);
    return _instance!;
  }

  static StoryLocaleController initialize(StoryLocalRepository local) {
    _instance = StoryLocaleController._(local);
    return _instance!;
  }

  Stream<Locale> get changes => _changes.stream;
  Locale get current => _current;

  Future<void> setLocale(Locale locale) async {
    _current = locale;
    _changes.add(locale);
    final local = _local;
    if (local != null) {
      await local.setLocale(
        LocaleInfo(
          languageCode: locale.languageCode,
          countryCode: locale.countryCode,
        ),
      );
    }
    StoryLogger.d('Locale changed: $locale', tag: 'Locale');
  }

  /// Seed the in-memory locale without persisting.
  ///
  /// Cold-start path: the value was just read from Hive, so writing it back
  /// is pointless disk I/O on the critical path before `runApp`.
  void seedLocale(Locale locale) {
    _current = locale;
    _changes.add(locale);
  }

  Future<void> dispose() async {
    await _changes.close();
  }
}
