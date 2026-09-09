import 'package:flutter/material.dart';

import '../model/app_version_update_model.dart';

/// 按 App 内语言 [locale] 从接口 `contents` 中选取展示文案，缺省回退 `en` → `zh`。
/// 空字符串仍返回空串（弹窗照常展示，仅公告区为空）。
String resolveAppVersionUpdateContent(
  AppVersionUpdateContents? contents,
  Locale locale,
) {
  if (contents == null) return '';

  final localized = switch (locale.languageCode) {
    'zh' => contents.zh,
    'en' => contents.en,
    'ja' => contents.ja,
    'es' => contents.es,
    'vi' => contents.vi,
    'tr' => contents.tr,
    _ => null,
  };

  return (localized ?? contents.en ?? contents.zh ?? '').trim();
}
