/// App 版本更新检查结果的客户端展示模型（与接口字段对齐，供 UI / Controller 共用）。
class AppVersionUpdateInfo {
  const AppVersionUpdateInfo({
    required this.type,
    required this.versionName,
    required this.downloadUrl,
    required this.contents,
  });

  final AppVersionUpdateType type;
  final String versionName;
  final String downloadUrl;

  /// 已按当前语言解析后的更新说明正文。
  final String contents;

  bool get isForce => type == AppVersionUpdateType.force;
}

enum AppVersionUpdateType {
  remind,
  force,
  click,
}
