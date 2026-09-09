import 'dart:io';

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../core/story_logger.dart';
import '../data/repository/story_local_repository.dart';
import 'ios_video_cache_service.dart';
import 'playback_frame_cache_service.dart';

/// Aggregates in-app cache usage (decoded images, Hive, temp/Caches dirs)
/// and clears regenerable caches from Settings.
class AppCacheService {
  AppCacheService({
    required this.localRepository,
    Future<List<Directory>> Function()? cacheDirectories,
    Future<void> Function()? clearVideoDisk,
    Future<void> Function()? clearImageDisk,
  }) : _cacheDirectories = cacheDirectories ?? defaultCacheDirectories,
       _clearVideoDisk = clearVideoDisk ?? defaultClearVideoDisk,
       _clearImageDisk = clearImageDisk ?? defaultClearImageDisk;

  final StoryLocalRepository localRepository;
  final Future<List<Directory>> Function() _cacheDirectories;
  final Future<void> Function() _clearVideoDisk;
  final Future<void> Function() _clearImageDisk;

  /// RAM image cache + Hive file + unique temp/Caches directories.
  ///
  /// Walking the platform cache dirs includes Android SimpleCache,
  /// iOS KTVHTTPCache, and `CachedNetworkImage` / `flutter_cache_manager`
  /// files — the volume Settings used to omit, which made the number look
  /// tiny next to the OS "Documents & Data" figure.
  Future<int> totalBytes() async {
    var total = PaintingBinding.instance.imageCache.currentSizeBytes;
    total += await localRepository.getCacheFileSize();
    for (final dir in await _cacheDirectories()) {
      total += await directorySize(dir);
    }
    return total;
  }

  Future<void> clear() async {
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
    await _clearImageDisk();
    await _clearVideoDisk();
    await PlaybackFrameCacheService.instance.clear();
    await localRepository.purgeApiCache();
  }

  @visibleForTesting
  static Future<int> directorySize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
    } catch (e) {
      StoryLogger.d(
        'Failed to measure cache dir ${dir.path}',
        error: e,
        tag: 'AppCache',
      );
    }
    return total;
  }

  @visibleForTesting
  static Future<List<Directory>> defaultCacheDirectories() async {
    if (kIsWeb) return const <Directory>[];
    final dirs = <String, Directory>{};
    try {
      final temp = await getTemporaryDirectory();
      dirs[temp.path] = temp;
    } catch (_) {}
    try {
      final cache = await getApplicationCacheDirectory();
      dirs[cache.path] = cache;
    } catch (_) {}
    return dirs.values.toList();
  }

  @visibleForTesting
  static Future<void> defaultClearImageDisk() async {
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      StoryLogger.w(
        'Failed to clear image disk cache',
        error: e,
        tag: 'AppCache',
      );
    }
  }

  @visibleForTesting
  static Future<void> defaultClearVideoDisk() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await NativeVideoPlayerCache.clearDiskCache();
      } else if (Platform.isIOS) {
        await IosVideoCacheService.instance.clearCache();
      }
    } catch (e) {
      StoryLogger.w(
        'Failed to clear video disk cache',
        error: e,
        tag: 'AppCache',
      );
    }
  }
}
