import 'package:hive/hive.dart';

import '../model/app_version_update_info.dart';

/// 版本更新频次策略所需的本地快照。
class AppVersionUpdateStoreData {
  const AppVersionUpdateStoreData({
    this.lastCheckAtMs,
    this.dismissedTargetVersion,
    this.dismissedUtcDay,
    this.lastKnownNeedUpdate = false,
    this.pendingUpdate,
  });

  final int? lastCheckAtMs;
  final String? dismissedTargetVersion;
  final String? dismissedUtcDay;
  final bool lastKnownNeedUpdate;

  /// 最近一次检查到的可展示更新（Force 热启动可据此重弹）。
  final AppVersionUpdateInfo? pendingUpdate;

  AppVersionUpdateStoreData copyWith({
    int? lastCheckAtMs,
    String? dismissedTargetVersion,
    String? dismissedUtcDay,
    bool? lastKnownNeedUpdate,
    AppVersionUpdateInfo? pendingUpdate,
    bool clearDismissed = false,
    bool clearPending = false,
  }) {
    return AppVersionUpdateStoreData(
      lastCheckAtMs: lastCheckAtMs ?? this.lastCheckAtMs,
      dismissedTargetVersion: clearDismissed
          ? null
          : (dismissedTargetVersion ?? this.dismissedTargetVersion),
      dismissedUtcDay: clearDismissed
          ? null
          : (dismissedUtcDay ?? this.dismissedUtcDay),
      lastKnownNeedUpdate: lastKnownNeedUpdate ?? this.lastKnownNeedUpdate,
      pendingUpdate: clearPending ? null : (pendingUpdate ?? this.pendingUpdate),
    );
  }
}

/// Hive 持久化：热启动 1h 节流、Remind 日限、设置页小红点、Force pending 快照。
class AppVersionUpdateStore {
  static const _prefix = 'app_version_update_';
  static const _lastCheckAtKey = '${_prefix}last_check_at_ms';
  static const _dismissedVersionKey = '${_prefix}dismissed_target_version';
  static const _dismissedDayKey = '${_prefix}dismissed_utc_day';
  static const _lastKnownNeedUpdateKey = '${_prefix}last_known_need_update';
  static const _pendingTypeKey = '${_prefix}pending_type';
  static const _pendingVersionKey = '${_prefix}pending_version_name';
  static const _pendingUrlKey = '${_prefix}pending_download_url';
  static const _pendingContentsKey = '${_prefix}pending_contents';

  AppVersionUpdateStore(this._box);

  final Box<dynamic> _box;

  AppVersionUpdateStoreData read() {
    return AppVersionUpdateStoreData(
      lastCheckAtMs: _readInt(_lastCheckAtKey),
      dismissedTargetVersion: _box.get(_dismissedVersionKey)?.toString(),
      dismissedUtcDay: _box.get(_dismissedDayKey)?.toString(),
      lastKnownNeedUpdate: _box.get(_lastKnownNeedUpdateKey) == true,
      pendingUpdate: _readPendingUpdate(),
    );
  }

  Future<void> markChecked(DateTime now) async {
    await _box.put(_lastCheckAtKey, now.millisecondsSinceEpoch);
  }

  Future<void> markDismissed({
    required String targetVersion,
    required DateTime now,
  }) async {
    await _box.put(_dismissedVersionKey, targetVersion);
    await _box.put(_dismissedDayKey, utcDayKey(now));
  }

  Future<void> setLastKnownNeedUpdate(bool value) async {
    await _box.put(_lastKnownNeedUpdateKey, value);
  }

  /// 持久化最近一次可展示的更新；[info] 为 null 时清空。
  Future<void> savePendingUpdate(AppVersionUpdateInfo? info) async {
    if (info == null) {
      await _box.delete(_pendingTypeKey);
      await _box.delete(_pendingVersionKey);
      await _box.delete(_pendingUrlKey);
      await _box.delete(_pendingContentsKey);
      return;
    }

    await _box.put(_pendingTypeKey, _typeToWire(info.type));
    await _box.put(_pendingVersionKey, info.versionName);
    await _box.put(_pendingUrlKey, info.downloadUrl);
    await _box.put(_pendingContentsKey, info.contents);
  }

  AppVersionUpdateInfo? _readPendingUpdate() {
    final type = _typeFromWire(_box.get(_pendingTypeKey)?.toString());
    final versionName = _box.get(_pendingVersionKey)?.toString().trim() ?? '';
    final downloadUrl = _box.get(_pendingUrlKey)?.toString().trim() ?? '';
    if (type == null || versionName.isEmpty || downloadUrl.isEmpty) {
      return null;
    }

    return AppVersionUpdateInfo(
      type: type,
      versionName: versionName,
      downloadUrl: downloadUrl,
      contents: _box.get(_pendingContentsKey)?.toString() ?? '',
    );
  }

  int? _readInt(String key) {
    final raw = _box.get(key);
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }
}

String utcDayKey(DateTime now) {
  final utc = now.toUtc();
  final month = utc.month.toString().padLeft(2, '0');
  final day = utc.day.toString().padLeft(2, '0');
  return '${utc.year}-$month-$day';
}

String _typeToWire(AppVersionUpdateType type) {
  return switch (type) {
    AppVersionUpdateType.remind => 'remind',
    AppVersionUpdateType.force => 'force',
    AppVersionUpdateType.click => 'click',
  };
}

AppVersionUpdateType? _typeFromWire(String? raw) {
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
