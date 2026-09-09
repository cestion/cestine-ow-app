import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/app_version_update_policy.dart';
import 'package:story_app/src/model/app_version_update_info.dart';
import 'package:story_app/src/services/app_version_update_store.dart';

void main() {
  const policy = AppVersionUpdatePolicy();
  const remindInfo = AppVersionUpdateInfo(
    type: AppVersionUpdateType.remind,
    versionName: '2.0.0',
    downloadUrl: 'https://example.com',
    contents: 'notes',
  );
  const forceInfo = AppVersionUpdateInfo(
    type: AppVersionUpdateType.force,
    versionName: '2.0.0',
    downloadUrl: 'https://example.com',
    contents: 'notes',
  );

  group('shouldFetchNow', () {
    test('launch always fetches', () {
      expect(
        policy.shouldFetchNow(
          trigger: AppVersionUpdateTrigger.launch,
          store: const AppVersionUpdateStoreData(),
          now: DateTime.utc(2026, 9, 2, 12),
        ),
        isTrue,
      );
    });

    test('resume respects 1h throttle', () {
      final now = DateTime.utc(2026, 9, 2, 12);
      final store = AppVersionUpdateStoreData(
        lastCheckAtMs: now
            .subtract(const Duration(minutes: 30))
            .millisecondsSinceEpoch,
      );
      expect(
        policy.shouldFetchNow(
          trigger: AppVersionUpdateTrigger.resume,
          store: store,
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('shouldReShowFromCache', () {
    test('force + resume within throttle should re-show', () {
      expect(
        policy.shouldReShowFromCache(
          trigger: AppVersionUpdateTrigger.resume,
          pending: forceInfo,
        ),
        isTrue,
      );
    });

    test('remind + resume within throttle should not re-show from cache', () {
      expect(
        policy.shouldReShowFromCache(
          trigger: AppVersionUpdateTrigger.resume,
          pending: remindInfo,
        ),
        isFalse,
      );
    });

    test('force + launch does not use cache path', () {
      expect(
        policy.shouldReShowFromCache(
          trigger: AppVersionUpdateTrigger.launch,
          pending: forceInfo,
        ),
        isFalse,
      );
    });
  });

  group('shouldShowDialog', () {
    test('force always shows on launch', () {
      expect(
        policy.shouldShowDialog(
          info: forceInfo,
          trigger: AppVersionUpdateTrigger.launch,
          store: const AppVersionUpdateStoreData(
            dismissedTargetVersion: '2.0.0',
            dismissedUtcDay: '2026-09-02',
          ),
          now: DateTime.utc(2026, 9, 2, 12),
        ),
        isTrue,
      );
    });

    test('remind hides after dismiss same day', () {
      expect(
        policy.shouldShowDialog(
          info: remindInfo,
          trigger: AppVersionUpdateTrigger.launch,
          store: const AppVersionUpdateStoreData(
            dismissedTargetVersion: '2.0.0',
            dismissedUtcDay: '2026-09-02',
          ),
          now: DateTime.utc(2026, 9, 2, 12),
        ),
        isFalse,
      );
    });

    test('settings always shows remind dialog', () {
      expect(
        policy.shouldShowDialog(
          info: remindInfo,
          trigger: AppVersionUpdateTrigger.settings,
          store: const AppVersionUpdateStoreData(
            dismissedTargetVersion: '2.0.0',
            dismissedUtcDay: '2026-09-02',
          ),
          now: DateTime.utc(2026, 9, 2, 12),
        ),
        isTrue,
      );
    });

    test('click does not auto show on launch', () {
      const clickInfo = AppVersionUpdateInfo(
        type: AppVersionUpdateType.click,
        versionName: '2.0.0',
        downloadUrl: 'https://example.com',
        contents: 'notes',
      );
      expect(
        policy.shouldShowDialog(
          info: clickInfo,
          trigger: AppVersionUpdateTrigger.launch,
          store: const AppVersionUpdateStoreData(),
          now: DateTime.utc(2026, 9, 2, 12),
        ),
        isFalse,
      );
    });

    test('remind shows again next utc day after dismiss', () {
      expect(
        policy.shouldShowDialog(
          info: remindInfo,
          trigger: AppVersionUpdateTrigger.launch,
          store: const AppVersionUpdateStoreData(
            dismissedTargetVersion: '2.0.0',
            dismissedUtcDay: '2026-09-02',
          ),
          now: DateTime.utc(2026, 9, 3, 1),
        ),
        isTrue,
      );
    });

    test('remind shows immediately when target version changes', () {
      expect(
        policy.shouldShowDialog(
          info: const AppVersionUpdateInfo(
            type: AppVersionUpdateType.remind,
            versionName: '2.0.1',
            downloadUrl: 'https://example.com',
            contents: 'notes',
          ),
          trigger: AppVersionUpdateTrigger.launch,
          store: const AppVersionUpdateStoreData(
            dismissedTargetVersion: '2.0.0',
            dismissedUtcDay: '2026-09-02',
          ),
          now: DateTime.utc(2026, 9, 2, 12),
        ),
        isTrue,
      );
    });
  });
}
