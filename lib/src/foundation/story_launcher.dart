import 'package:url_launcher/url_launcher.dart';

/// 系统浏览器跳转工具。
///
/// 封装 [url_launcher] 调用，统一以外部浏览器模式打开链接。
class StoryLauncher {
  StoryLauncher._();

  /// 使用系统浏览器打开 [url]。
  ///
  /// 返回是否成功唤起外部应用。
  static Future<bool> openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
