import 'dart:io' show Platform;

/// 渠道标识。
///
/// 仅 Android 分渠道，iOS 不分渠道恒为商店包。
/// 默认（未通过 `--dart-define=CHANNEL=...` 指定）即商店包。
///
/// 构建示例：
/// ```
/// flutter build apk --release --dart-define=ENV=production --dart-define=CHANNEL=official
/// ```
class AppChannel {
  AppChannel._();

  static const String _defaultChannel = 'store';
  static const String _envChannel = String.fromEnvironment(
    'CHANNEL',
    defaultValue: _defaultChannel,
  );

  /// 当前渠道：`store`（商店包）或 `official`（官网包）。
  static String get current {
    // iOS 不分渠道，恒为商店包。
    if (Platform.isIOS) return _defaultChannel;
    return _envChannel;
  }

  static bool get isStore => current == 'store';

  static bool get isOfficial => current == 'official';
}
