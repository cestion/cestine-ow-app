import 'package:flutter/material.dart';

import '../model/app_version_update_info.dart';
import '../model/app_version_update_model.dart';
import 'app_version_update_content_resolver.dart';

AppVersionUpdateType? parseAppVersionUpdateType(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'remind':
      return AppVersionUpdateType.remind;
    case 'force':
      return AppVersionUpdateType.force;
    case 'click':
      return AppVersionUpdateType.click;
    default:
      return null;
  }
}

/// 将接口响应转为 UI 模型。
///
/// **产品规则：** 只要 `need_update == true` 就弹窗；`contents` /
/// `download_url` / `version_name` / `type` 缺失时做容错，不取消弹窗。
/// `type` 无法识别时按 [AppVersionUpdateType.remind] 兜底（可关闭）。
AppVersionUpdateInfo? toAppVersionUpdateInfo(
  AppVersionUpdateCheckResponse response,
  Locale locale,
) {
  if (!response.needUpdate) return null;

  return AppVersionUpdateInfo(
    type: parseAppVersionUpdateType(response.type) ??
        AppVersionUpdateType.remind,
    versionName: response.versionName?.trim() ?? '',
    downloadUrl: response.downloadUrl?.trim() ?? '',
    contents: resolveAppVersionUpdateContent(response.contents, locale),
  );
}
