import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../model/app_version_update_info.dart';
import '../provider/core_providers.dart';
import '../provider/repository_providers.dart';
import '../repositories/app_version_repository.dart';
import '../services/app_version_update_store.dart';
import '../utils/app_distribution_channel.dart';
import '../utils/app_version_update_mapper.dart';
import 'app_version_update_policy.dart';
import 'app_version_update_state.dart';

class AppVersionUpdateController extends Notifier<AppVersionUpdateState> {
  late AppVersionRepository _repository;
  late AppVersionUpdateStore _store;
  final AppVersionUpdatePolicy _policy = const AppVersionUpdatePolicy();
  var _ready = false;

  @override
  AppVersionUpdateState build() {
    _repository = ref.read(appVersionRepositoryProvider);
    _store = AppVersionUpdateStore(ref.read(localRepositoryProvider).cacheBox);
    _ready = true;
    final cached = _store.read();
    return AppVersionUpdateState(hasPendingUpdate: cached.lastKnownNeedUpdate);
  }

  Future<void> checkOnLaunch() => _check(AppVersionUpdateTrigger.launch);

  Future<void> checkOnResume() => _check(AppVersionUpdateTrigger.resume);

  /// 设置页主动检查：始终请求接口；有更新则弹窗（不受 Remind 日限）。
  Future<({AppVersionSettingsCheckResult result, AppVersionUpdateInfo? info})>
  checkFromSettings() async {
    if (!_ready) {
      return (
        result: AppVersionSettingsCheckResult.failedSilent,
        info: null,
      );
    }
    state = state.copyWith(isChecking: true, clearDialog: true);

    final outcome = await _fetchAndMap();
    await _store.markChecked(DateTime.now());

    if (outcome.failed) {
      state = state.copyWith(isChecking: false);
      return (
        result: AppVersionSettingsCheckResult.failedSilent,
        info: null,
      );
    }

    final info = outcome.info;
    await _store.setLastKnownNeedUpdate(info != null);
    await _store.savePendingUpdate(info);

    if (info == null) {
      state = state.copyWith(isChecking: false, hasPendingUpdate: false);
      return (result: AppVersionSettingsCheckResult.upToDate, info: null);
    }

    state = state.copyWith(isChecking: false, hasPendingUpdate: true);
    return (
      result: AppVersionSettingsCheckResult.updateAvailable,
      info: info,
    );
  }

  void clearDialog() {
    if (state.dialogInfo == null) return;
    state = state.copyWith(clearDialog: true);
  }

  Future<void> markDismissed(AppVersionUpdateInfo info) {
    if (!_ready) return Future<void>.value();
    return _store.markDismissed(
      targetVersion: info.versionName,
      now: DateTime.now(),
    );
  }

  Future<void> _check(AppVersionUpdateTrigger trigger) async {
    // build() may have failed (e.g. tests without a Hive box); never crash launch.
    if (!_ready) return;
    final now = DateTime.now();
    final storeData = _store.read();

    if (!_policy.shouldFetchNow(
      trigger: trigger,
      store: storeData,
      now: now,
    )) {
      await _reShowCachedForceIfNeeded(trigger, storeData);
      return;
    }

    state = state.copyWith(isChecking: true, clearDialog: true);

    final outcome = await _fetchAndMap();
    await _store.markChecked(now);

    if (outcome.failed) {
      // 请求失败时：Force 仍可用上次缓存重弹，避免弱网绕过强更。
      state = state.copyWith(isChecking: false);
      await _reShowCachedForceIfNeeded(trigger, _store.read());
      return;
    }

    final info = outcome.info;
    await _store.setLastKnownNeedUpdate(info != null);
    await _store.savePendingUpdate(info);

    AppVersionUpdateInfo? dialogInfo;
    if (info != null &&
        _policy.shouldShowDialog(
          info: info,
          trigger: trigger,
          store: _store.read(),
          now: now,
        )) {
      dialogInfo = info;
    }

    state = state.copyWith(
      isChecking: false,
      hasPendingUpdate: info != null,
      dialogInfo: dialogInfo,
      clearDialog: dialogInfo == null,
    );
  }

  /// 节流窗口内 / 请求失败：若有 Force pending，清空再写入以触发 listener 重弹。
  Future<void> _reShowCachedForceIfNeeded(
    AppVersionUpdateTrigger trigger,
    AppVersionUpdateStoreData storeData,
  ) async {
    final pending = storeData.pendingUpdate;
    if (!_policy.shouldReShowFromCache(trigger: trigger, pending: pending)) {
      return;
    }

    state = state.copyWith(clearDialog: true);
    state = state.copyWith(
      hasPendingUpdate: true,
      dialogInfo: pending,
    );
  }

  Future<({bool failed, AppVersionUpdateInfo? info})> _fetchAndMap() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      // 公告与 App 内语言设置一致（设置 → 语言）。
      final locale = ref.read(appLocaleProvider);
      final result = await _repository.checkUpdate(
        channel: resolveDistributionChannel(),
        versionName: packageInfo.version,
      );

      if (result.isFailure) return (failed: true, info: null);

      final info = toAppVersionUpdateInfo(result.dataOrNull!, locale);
      return (failed: false, info: info);
    } catch (_) {
      return (failed: true, info: null);
    }
  }
}
