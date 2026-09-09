import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/story_constants.dart';

/// Persists a stable per-installation device identifier for analytics APIs.
class DeviceIdService {
  DeviceIdService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _storageKey = 'device_id';

  final FlutterSecureStorage _secureStorage;
  String? _cachedRaw;

  /// Raw UUID without reporting prefix (for local keys / identity).
  String? get cachedRawDeviceId => _cachedRaw;

  /// Device id for `Device-ID` header, e.g. `app-<uuid>`.
  Future<String> getDeviceId() async {
    final raw = await _getOrCreateRawId();
    if (raw.startsWith(StoryConstants.deviceIdReportingPrefix)) {
      return raw;
    }
    return '${StoryConstants.deviceIdReportingPrefix}$raw';
  }

  Future<String> getRawDeviceId() => _getOrCreateRawId();

  Future<String> _getOrCreateRawId() async {
    final cached = _cachedRaw;
    if (cached != null && cached.isNotEmpty) return cached;

    var id = await _secureStorage.read(key: _storageKey);
    if (id == null || id.trim().isEmpty) {
      id = _generateUuidV4();
      await _secureStorage.write(key: _storageKey, value: id);
    } else {
      id = id.trim();
      // Strip legacy reporting prefix if it was ever persisted.
      const prefix = StoryConstants.deviceIdReportingPrefix;
      if (id.startsWith(prefix)) {
        id = id.substring(prefix.length);
        await _secureStorage.write(key: _storageKey, value: id);
      }
    }
    _cachedRaw = id;
    return id;
  }

  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}'
        '${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
  }
}
