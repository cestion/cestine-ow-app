import '../model/app_version_update_info.dart';

class AppVersionUpdateState {
  const AppVersionUpdateState({
    this.isChecking = false,
    this.hasPendingUpdate = false,
    this.dialogInfo,
  });

  final bool isChecking;
  final bool hasPendingUpdate;
  final AppVersionUpdateInfo? dialogInfo;

  AppVersionUpdateState copyWith({
    bool? isChecking,
    bool? hasPendingUpdate,
    AppVersionUpdateInfo? dialogInfo,
    bool clearDialog = false,
  }) {
    return AppVersionUpdateState(
      isChecking: isChecking ?? this.isChecking,
      hasPendingUpdate: hasPendingUpdate ?? this.hasPendingUpdate,
      dialogInfo: clearDialog ? null : (dialogInfo ?? this.dialogInfo),
    );
  }
}

enum AppVersionSettingsCheckResult {
  upToDate,
  updateAvailable,
  failedSilent,
}
