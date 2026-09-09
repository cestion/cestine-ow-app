import 'package:flutter/material.dart';

abstract class StoryNavigatorBridge {
  const StoryNavigatorBridge();

  Future<void> pushPath(
    String path, {
    dynamic arguments,
    BuildContext? context,
  });
  Future<void> pop<T>({BuildContext? context, T? result});
  Future<bool> ensureLogin();
}

class DefaultStoryNavigatorBridge extends StoryNavigatorBridge {
  const DefaultStoryNavigatorBridge();

  @override
  Future<void> pushPath(
    String path, {
    dynamic arguments,
    BuildContext? context,
  }) async {}

  @override
  Future<void> pop<T>({BuildContext? context, T? result}) async {}

  @override
  Future<bool> ensureLogin() async => false;
}

class StoryNavigatorBridgeRegistry {
  StoryNavigatorBridgeRegistry._();
  static StoryNavigatorBridge _instance = const DefaultStoryNavigatorBridge();

  static StoryNavigatorBridge get instance => _instance;

  static bool get isRegistered => _instance is! DefaultStoryNavigatorBridge;

  static void set(StoryNavigatorBridge bridge) {
    _instance = bridge;
  }

  static void reset() {
    _instance = const DefaultStoryNavigatorBridge();
  }
}
