import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../controller/app_version_update_controller.dart';
import '../controller/app_version_update_state.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

final appVersionUpdateControllerProvider =
    NotifierProvider<AppVersionUpdateController, AppVersionUpdateState>(
      AppVersionUpdateController.new,
    );
