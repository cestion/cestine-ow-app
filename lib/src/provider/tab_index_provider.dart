import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

/// The four main tabs in the bottom navigation.
enum StoryTab {
  theater,
  nft,
  game,
  profile;

  /// Whether this tab requires user authentication.
  bool get requiresAuth => this == game || this == profile;

  /// Total number of tabs.
  static const int count = 4;
}

/// App-wide bottom-nav tab index.
///
/// Replaces the previous `MainShellPage.selectTab` /
/// `findAncestorStateOfType<_MainShellPageState>()` anti-pattern with a
/// Riverpod `Notifier` so any widget (drawer, bottom nav, deep links) can
/// switch tabs through `ref.read(tabIndexProvider.notifier)`.
class TabIndexController extends Notifier<int> {
  @override
  int build() => 0;

  /// Set tab index directly (no auth guard). Clamps to valid range.
  void setIndex(int index) {
    final clamped = index.clamp(0, StoryTab.count - 1);
    if (state != clamped) state = clamped;
  }

  /// Switches tab with login guard.
  ///
  /// Returns `true` when the tab was switched successfully. Returns `false`
  /// when the target tab requires login and the user is not authenticated;
  /// the caller is responsible for navigating to the login page.
  Future<bool> selectTabWithAuth(int index) async {
    if (index == state) return true;
    final tab = StoryTab.values[index.clamp(0, StoryTab.count - 1)];
    if (tab.requiresAuth) {
      var authState = ref.read(authControllerProvider);
      // 冷启动时本地 JWT 会先恢复出乐观登录态。此时不要等待
      // auth.ready，因为它还包含 Privy/钱包余额等远程初始化，会阻塞 Tab 切换。
      // 只有当尚无本地登录态时才等待恢复，避免把正在恢复的用户误判
      // 为未登录。
      if (!authState.isLoggedIn && !authState.ready) {
        await ref.read(authControllerProvider.notifier).ready;
        authState = ref.read(authControllerProvider);
      }
      if (!authState.isLoggedIn) return false;
    }
    state = index;
    return true;
  }
}

final NotifierProvider<TabIndexController, int> tabIndexProvider =
    NotifierProvider<TabIndexController, int>(TabIndexController.new);
