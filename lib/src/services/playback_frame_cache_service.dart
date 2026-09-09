import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../controller/playback_engine.dart';
import '../core/cache_strategy.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';

/// In-memory + on-disk cache of JPEG snapshots captured from native players.
///
/// Used as [VideoFeedPageItem.firstFrameBytes] so cold loads and re-visits
/// show a painted frame instead of a black platform view while decoding.
class PlaybackFrameCacheService {
  PlaybackFrameCacheService._();

  static final PlaybackFrameCacheService instance =
      PlaybackFrameCacheService._();

  /// Bumps when a new frame is stored — UI can listen to refresh posters.
  final ValueNotifier<int> revisions = ValueNotifier(0);

  final MemoryCacheLayer<String, Uint8List> _memory = MemoryCacheLayer(
    maxEntries: StoryConstants.playbackFrameMemoryMaxEntries,
  );

  /// Synchronous hot lookup for itemBuilder (memory hits only).
  /// Entries are moved to the end on access so `_hot.keys.first` always
  /// evicts the least-recently-used entry.
  final LinkedHashMap<String, Uint8List> _hot = LinkedHashMap();

  Directory? _diskDir;
  final Set<String> _captureInFlight = <String>{};

  /// Returns an in-memory JPEG if already loaded this session.
  /// Moves the entry to the end (MRU position) for LRU eviction.
  Uint8List? peek(String playbackId) {
    final key = _normalizeKey(playbackId);
    if (key.isEmpty) return null;
    final bytes = _hot[key];
    if (bytes != null) {
      // Move to end (MRU) — remove + re-insert is O(1) for LinkedHashMap.
      _hot.remove(key);
      _hot[key] = bytes;
    }
    return bytes;
  }

  /// Returns a cached JPEG for [playbackId], checking memory then disk.
  Future<Uint8List?> get(String playbackId) async {
    final key = _normalizeKey(playbackId);
    if (key.isEmpty) return null;

    final cached = await _memory.get(key);
    if (cached != null && cached.isNotEmpty) {
      _rememberHot(key, cached);
      return cached;
    }

    final disk = await _readDisk(key);
    if (disk != null && disk.isNotEmpty) {
      await _memory.set(key, disk);
      _rememberHot(key, disk);
      return disk;
    }
    return null;
  }

  /// Stores JPEG bytes for [playbackId].
  Future<void> put(String playbackId, Uint8List bytes) async {
    final key = _normalizeKey(playbackId);
    if (key.isEmpty || bytes.isEmpty) return;
    await _memory.set(key, bytes);
    _rememberHot(key, bytes);
    revisions.value++;
    unawaited(_writeDisk(key, bytes));
  }

  /// Captures from [engine] once per [playbackId] and stores the JPEG.
  ///
  /// Returns the stored bytes, or null when capture is skipped or fails.
  Future<Uint8List?> captureAndStore({
    required PlaybackEngine engine,
    required String playbackId,
    int maxWidth = StoryConstants.playbackFrameCaptureMaxWidth,
  }) async {
    final key = _normalizeKey(playbackId);
    if (key.isEmpty) return null;

    final existing = await get(key);
    if (existing != null && existing.isNotEmpty) return existing;
    if (_captureInFlight.contains(key)) return null;

    _captureInFlight.add(key);
    try {
      final bytes = await engine.captureCurrentFrame(maxWidth: maxWidth);
      if (bytes == null || bytes.isEmpty) return null;
      await put(key, bytes);
      return bytes;
    } finally {
      _captureInFlight.remove(key);
    }
  }

  Future<void> clear() async {
    await _memory.clear();
    _hot.clear();
    revisions.value++;
    final dir = await _ensureDiskDir();
    if (dir == null) return;
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      StoryLogger.d(
        'Failed to clear playback frame disk cache',
        error: e,
        tag: 'FrameCache',
      );
    }
  }

  String _normalizeKey(String playbackId) => playbackId.trim();

  /// 统一首帧缓存 key：优先 `dramaId:episodeId`（与推荐流 `playbackId` 一致，
  /// 使同一剧集跨入口共享首帧）。短视频（无 dramaId，或 dramaId == episodeId）
  /// 直接用 episodeId；短剧缺少 episodeId 时 fallback 到 `dramaId_ep$episodeNo`
  /// （兼容已存在的磁盘缓存）。
  ///
  /// 所有入口（短剧播放页 / 推荐流 / 混合播放列表）**必须只通过此方法**构造
  /// 首帧缓存 key，禁止直接传 `playbackId` 或其它拼接格式，否则同一集会因
  /// key 不一致而缓存 miss（重新捕获、黑帧多闪）。
  ///
  /// 调用方在捕获（onFrameRendered，engine.currentPlay 已含 episodeId）或
  /// 读取（episodePlays 已加载）时都能提供 episodeId；只有纯 episodeNo
  /// 场景（初始 prime）走 fallback。
  static String frameCacheKey({
    required String dramaId,
    String? episodeId,
    int? episodeNo,
  }) {
    final drama = dramaId.trim();
    final ep = episodeId?.trim() ?? '';
    if (drama.isNotEmpty && ep.isNotEmpty && drama != ep) {
      return '$drama:$ep';
    }
    if (ep.isNotEmpty) return ep;
    if (drama.isNotEmpty && episodeNo != null && episodeNo >= 1) {
      return '${drama}_ep$episodeNo';
    }
    return drama;
  }

  void _rememberHot(String key, Uint8List bytes) {
    _hot.remove(key);
    _hot[key] = bytes;
    while (_hot.length > StoryConstants.playbackFrameMemoryMaxEntries) {
      _hot.remove(_hot.keys.first);
    }
  }

  Future<Directory?> _ensureDiskDir() async {
    if (kIsWeb) return null;
    final existing = _diskDir;
    if (existing != null) return existing;
    try {
      final base = await getTemporaryDirectory();
      final dir = Directory('${base.path}/playback_frames');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _diskDir = dir;
      return dir;
    } catch (e) {
      StoryLogger.d(
        'Failed to open playback frame cache dir',
        error: e,
        tag: 'FrameCache',
      );
      return null;
    }
  }

  File _diskFile(String key) {
    final sanitized = key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File('${_diskDir!.path}/$sanitized.jpg');
  }

  /// Max file size for a frame JPEG — skip reads of corrupted or abnormally
  /// large files (a 480px JPEG should be < 200KB).
  static const int _maxFrameFileSize = 5 * 1024 * 1024; // 5MB

  Future<Uint8List?> _readDisk(String key) async {
    final dir = await _ensureDiskDir();
    if (dir == null) return null;
    final file = _diskFile(key);
    if (!await file.exists()) return null;
    try {
      final stat = await file.stat();
      if (stat.size > _maxFrameFileSize) {
        StoryLogger.w(
          'Skipping oversized frame cache $key (${stat.size} bytes)',
          tag: 'FrameCache',
        );
        return null;
      }
      return await file.readAsBytes();
    } catch (e) {
      StoryLogger.d(
        'Failed to read frame cache $key',
        error: e,
        tag: 'FrameCache',
      );
      return null;
    }
  }

  Future<void> _writeDisk(String key, Uint8List bytes) async {
    final dir = await _ensureDiskDir();
    if (dir == null) return;
    try {
      await _diskFile(key).writeAsBytes(bytes, flush: true);
      await _trimDiskIfNeeded(dir);
    } catch (e) {
      StoryLogger.d(
        'Failed to write frame cache $key',
        error: e,
        tag: 'FrameCache',
      );
    }
  }

  Future<void> _trimDiskIfNeeded(Directory dir) async {
    try {
      final entries = <({File file, int size, DateTime modified})>[];
      var totalBytes = 0;
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.jpg')) {
          try {
            final stat = await entity.stat();
            final size = stat.size;
            entries.add((file: entity, size: size, modified: stat.modified));
            totalBytes += size;
          } catch (_) {
            // stat failed — skip this file (will be cleaned on next pass).
          }
        }
      }
      const maxFiles = StoryConstants.playbackFrameDiskMaxEntries;
      const maxBytes = StoryConstants.playbackFrameDiskMaxBytes;
      const trimTrigger = maxFiles + StoryConstants.playbackFrameDiskTrimSlack;
      final needTrimByCount = entries.length > trimTrigger;
      final needTrimByBytes = totalBytes > maxBytes;
      if (!needTrimByCount && !needTrimByBytes) return;
      entries.sort((a, b) => a.modified.compareTo(b.modified));
      // Evict oldest files until both limits are satisfied.
      var remainingBytes = totalBytes;
      for (var i = 0; i < entries.length; i++) {
        if (entries.length - i <= maxFiles && remainingBytes <= maxBytes) break;
        try {
          remainingBytes -= entries[i].size;
          await entries[i].file.delete();
        } catch (_) {}
      }
    } catch (e) {
      StoryLogger.d(
        'Failed to trim playback frame disk cache',
        error: e,
        tag: 'FrameCache',
      );
    }
  }
}
