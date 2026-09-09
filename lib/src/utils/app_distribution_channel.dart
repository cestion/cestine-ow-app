import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// 解析 App 分发渠道，映射到版本检查接口 `channel` 参数。
String resolveDistributionChannel() {
  if (kIsWeb) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) {
    const channel = String.fromEnvironment(
      'DISTRIBUTION_CHANNEL',
      defaultValue: 'android',
    );
    return channel == 'apk' ? 'apk' : 'android';
  }
  return 'android';
}
