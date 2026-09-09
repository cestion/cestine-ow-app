import '../model/app_version_update_info.dart';
import '../services/app_version_update_store.dart';

enum AppVersionUpdateTrigger {
  launch,
  resume,
  settings,
}

class AppVersionUpdatePolicy {
  const AppVersionUpdatePolicy();

  static const warmStartMinInterval = Duration(hours: 1);

  bool shouldFetchNow({
    required AppVersionUpdateTrigger trigger,
    required AppVersionUpdateStoreData store,
    required DateTime now,
  }) {
    switch (trigger) {
      case AppVersionUpdateTrigger.launch:
      case AppVersionUpdateTrigger.settings:
        return true;
      case AppVersionUpdateTrigger.resume:
        final lastCheckAtMs = store.lastCheckAtMs;
        if (lastCheckAtMs == null) return true;
        return now.millisecondsSinceEpoch - lastCheckAtMs >=
            warmStartMinInterval.inMilliseconds;
    }
  }

  /// 热启动在 1h 节流窗口内：若缓存为 Force，仍应直接重弹（无需重新请求）。
  bool shouldReShowFromCache({
    required AppVersionUpdateTrigger trigger,
    required AppVersionUpdateInfo? pending,
  }) {
    if (trigger != AppVersionUpdateTrigger.resume) return false;
    return pending?.type == AppVersionUpdateType.force;
  }

  bool shouldShowDialog({
    required AppVersionUpdateInfo info,
    required AppVersionUpdateTrigger trigger,
    required AppVersionUpdateStoreData store,
    required DateTime now,
  }) {
    if (trigger == AppVersionUpdateTrigger.settings) return true;
    if (info.type == AppVersionUpdateType.force) return true;
    if (info.type == AppVersionUpdateType.click) return false;

    final today = utcDayKey(now);
    if (store.dismissedTargetVersion == info.versionName &&
        store.dismissedUtcDay == today) {
      return false;
    }
    return true;
  }
}
