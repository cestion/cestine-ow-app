import '../core/json_helpers.dart';

/// 多语言更新公告（接口 `contents` 字段）。
class AppVersionUpdateContents {
  const AppVersionUpdateContents({
    this.zh,
    this.en,
    this.ja,
    this.es,
    this.vi,
    this.tr,
  });

  final String? zh;
  final String? en;
  final String? ja;
  final String? es;
  final String? vi;
  final String? tr;

  factory AppVersionUpdateContents.fromJson(Map<String, dynamic> json) {
    return AppVersionUpdateContents(
      zh: asStringOrNull(json['zh']),
      en: asStringOrNull(json['en']),
      ja: asStringOrNull(json['ja']),
      es: asStringOrNull(json['es']),
      vi: asStringOrNull(json['vi']),
      tr: asStringOrNull(json['tr']),
    );
  }
}

/// `GET /api/admin/v1/app-version-updates/check` 响应 `data` 部分。
class AppVersionUpdateCheckResponse {
  const AppVersionUpdateCheckResponse({
    required this.needUpdate,
    this.type,
    this.versionName,
    this.downloadUrl,
    this.contents,
  });

  final bool needUpdate;
  final String? type;
  final String? versionName;
  final String? downloadUrl;
  final AppVersionUpdateContents? contents;

  factory AppVersionUpdateCheckResponse.fromJson(Map<String, dynamic> json) {
    AppVersionUpdateContents? contents;
    final rawContents = json['contents'];
    if (rawContents is Map) {
      contents = AppVersionUpdateContents.fromJson(
        Map<String, dynamic>.from(rawContents),
      );
    }

    return AppVersionUpdateCheckResponse(
      needUpdate: asBoolOrNull(json['need_update']) ?? false,
      type: asStringOrNull(json['type']),
      versionName: asStringOrNull(json['version_name']),
      downloadUrl: asStringOrNull(json['download_url']),
      contents: contents,
    );
  }
}
