import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/app_version_update_info.dart';
import 'package:story_app/src/model/app_version_update_model.dart';
import 'package:story_app/src/utils/app_version_update_content_resolver.dart';
import 'package:story_app/src/utils/app_version_update_mapper.dart';

void main() {
  group('resolveAppVersionUpdateContent', () {
    const contents = AppVersionUpdateContents(
      zh: '中文公告',
      en: 'English notes',
      ja: '日本語',
      es: 'Español',
      vi: 'Tiếng Việt',
      tr: 'Türkçe',
    );

    test('returns localized text for zh', () {
      expect(
        resolveAppVersionUpdateContent(contents, const Locale('zh', 'CN')),
        '中文公告',
      );
    });

    test('returns localized text for en', () {
      expect(
        resolveAppVersionUpdateContent(contents, const Locale('en', 'US')),
        'English notes',
      );
    });

    test('falls back to en when locale missing', () {
      expect(
        resolveAppVersionUpdateContent(contents, const Locale('ko')),
        'English notes',
      );
    });

    test('returns empty when contents null', () {
      expect(resolveAppVersionUpdateContent(null, const Locale('en')), '');
    });

    test('returns empty when all language fields blank', () {
      expect(
        resolveAppVersionUpdateContent(
          const AppVersionUpdateContents(zh: '  ', en: ''),
          const Locale('zh'),
        ),
        '',
      );
    });
  });

  group('toAppVersionUpdateInfo', () {
    test('maps remind payload with app-locale contents', () {
      final info = toAppVersionUpdateInfo(
        const AppVersionUpdateCheckResponse(
          needUpdate: true,
          type: 'Remind',
          versionName: '2.0.0',
          downloadUrl: 'https://example.com',
          contents: AppVersionUpdateContents(zh: '中文', en: 'EN'),
        ),
        const Locale('en'),
      );

      expect(info, isNotNull);
      expect(info!.type, AppVersionUpdateType.remind);
      expect(info.versionName, '2.0.0');
      expect(info.contents, 'EN');
    });

    test('still returns info when contents empty', () {
      final info = toAppVersionUpdateInfo(
        const AppVersionUpdateCheckResponse(
          needUpdate: true,
          type: 'Force',
          versionName: '2.0.0',
          downloadUrl: 'https://example.com',
        ),
        const Locale('zh'),
      );

      expect(info, isNotNull);
      expect(info!.type, AppVersionUpdateType.force);
      expect(info.contents, '');
    });

    test('still returns info when download_url and version empty', () {
      final info = toAppVersionUpdateInfo(
        const AppVersionUpdateCheckResponse(needUpdate: true, type: 'Remind'),
        const Locale('en'),
      );

      expect(info, isNotNull);
      expect(info!.type, AppVersionUpdateType.remind);
      expect(info.versionName, '');
      expect(info.downloadUrl, '');
    });

    test('unknown type falls back to remind but still shows', () {
      final info = toAppVersionUpdateInfo(
        const AppVersionUpdateCheckResponse(
          needUpdate: true,
          type: 'Unknown',
          versionName: '2.0.0',
          downloadUrl: 'https://example.com',
        ),
        const Locale('en'),
      );

      expect(info, isNotNull);
      expect(info!.type, AppVersionUpdateType.remind);
    });

    test('returns null when need_update false', () {
      expect(
        toAppVersionUpdateInfo(
          const AppVersionUpdateCheckResponse(needUpdate: false),
          const Locale('en'),
        ),
        isNull,
      );
    });
  });
}
