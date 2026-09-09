import 'dart:async';
import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/repository/story_local_repository.dart';
import '../data/repository/story_local_repository_impl.dart';
import '../foundation/locale_controller.dart';
import '../foundation/navigator_bridge.dart';
import '../foundation/telemetry.dart';
import '../foundation/theme_controller.dart';
import '../services/privy_service.dart';
import 'android_emulator_probe.dart';
import 'story_constants.dart';
import '../utils/system_number_format.dart';
import 'story_logger.dart';
import 'story_sdk_config.dart';

class StorySdk {
  StorySdk._();
  static final StorySdk instance = StorySdk._();

  bool _initialized = false;
  StorySdkConfig? _config;
  StoryLocalRepository? _localRepository;
  PrivyService? _privyService;

  StorySdkConfig get config => _config ?? const StorySdkConfig();

  StoryLocalRepository get localRepository {
    assert(
      _initialized,
      'StorySdk.initialize() must complete before reading localRepository.',
    );
    return _localRepository!;
  }

  PrivyService get privyService {
    assert(
      _initialized,
      'StorySdk.initialize() must complete before reading privyService.',
    );
    return _privyService!;
  }

  /// Parses a `--dart-define` tri-state: true / false / unset.
  static bool? _defineOverride(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return null;
  }

  /// Whether Android renders video into a Flutter engine texture
  /// (`SurfaceProducer`) instead of a platform view.
  ///
  /// `--dart-define=PLAYER_ANDROID_TEXTURE=true|false` forces the choice.
  /// Off by default: on API 29+ the engine backs the texture with an
  /// `ImageReader`, which drops the decoder's crop metadata and renders the
  /// coded frame's alignment padding as a green strip
  /// (flutter/flutter#159955, still open). [_resolveTextureViewSurface] fixes
  /// the same punch-through problem without that defect.
  static bool _resolveTextureMode() {
    const override = String.fromEnvironment('PLAYER_ANDROID_TEXTURE');
    return _defineOverride(override) ?? false;
  }

  /// Whether the Android platform view is backed by a `TextureView` rather
  /// than a `SurfaceView`.
  ///
  /// `--dart-define=PLAYER_ANDROID_TEXTURE_VIEW=true|false` forces the choice.
  /// Default on for real Android devices: a `SurfaceView` forces the engine
  /// off Texture Layer Hybrid Composition onto full hybrid composition, where
  /// the surface is its own compositor layer that ignores Flutter clipping
  /// and z-order — feed video then punches through bottom sheets and the
  /// translucent top chrome. A `TextureView` keeps the view on TLHC.
  ///
  /// Default **off** on the Android emulator. Soft-decode (needed to hide
  /// goldfish stamp residue) and GL-sampled textures are mutually exclusive
  /// there — `TextureView` + soft-decode flashes green padding; `TextureView`
  /// + goldfish hard-decode brings the stamp back as a thick green/black
  /// band. Emulator keeps `SurfaceView` + soft-decode for a clean picture;
  /// punch-through on sheets is an emulator-only trade-off.
  static bool _resolveTextureViewSurface({required bool isEmulator}) {
    const override = String.fromEnvironment('PLAYER_ANDROID_TEXTURE_VIEW');
    return _defineOverride(override) ??
        (defaultTargetPlatform == TargetPlatform.android && !isEmulator);
  }

  /// Whether Media3 must stay on `c2.android.*` decoders.
  ///
  /// `--dart-define=PLAYER_ANDROID_SOFT_DECODE=true|false` forces the choice.
  /// Unset auto-detects the Android emulator, whose `c2.goldfish.*` decoders
  /// recycle graphic buffers across streams without clearing them: after a
  /// resolution change the new frame only covers part of the buffer and the
  /// rest still shows the previous video.
  ///
  /// Skipped under [textureMode] or [textureViewSurface]: both feed the
  /// decoder into a GL-sampled texture (`SurfaceProducer` / `TextureView`).
  /// On the emulator, software decoders through that path either paint solid
  /// green or flash the coded-frame padding as a green strip — worse than
  /// the stale pixels soft-decode was meant to avoid. Both faults are
  /// emulator-only; real devices never take this branch.
  static bool _resolveSoftwareDecoders({
    required bool textureMode,
    required bool textureViewSurface,
    required bool isEmulator,
  }) {
    const override = String.fromEnvironment('PLAYER_ANDROID_SOFT_DECODE');
    final forced = _defineOverride(override);
    if (forced != null) return forced;
    if (textureMode || textureViewSurface) return false;
    if (isEmulator) {
      StoryLogger.w(
        'Android emulator detected; forcing software video decoders',
        tag: 'StorySdk',
      );
    }
    return isEmulator;
  }

  Future<void> initialize({
    StorySdkConfig config = const StorySdkConfig(),
    StoryNavigatorBridge? navigatorBridge,
    StoryTelemetry? telemetry,
    Locale? initialLocale,
  }) async {
    if (_initialized) {
      StoryLogger.w('initialize() called twice; ignored.', tag: 'StorySdk');
      return;
    }

    // Performance tuning:
    // Feed-oriented plugin knobs (see better_native_video_player PERFORMANCE docs).
    // Quality: disable viewport-driven ABR for feed triple-slot playback.
    // Off-screen preload surfaces can report misleading bounds and trigger
    // extra quality work while the slot is still silent/background. Instead
    // the feed applies its manual 1080p cap only when the episode is about
    // to become active.
    // Precache budget: single source of truth is StoryConstants.precacheBytes*.
    // loadTimeout aligned with StoryConstants.playerOperationTimeout.
    WidgetsFlutterBinding.ensureInitialized();
    final androidTextureMode = _resolveTextureMode();
    final isEmulator = await AndroidEmulatorProbe.detect();
    final androidTextureViewSurface = _resolveTextureViewSurface(
      isEmulator: isEmulator,
    );
    final forceSoftwareDecoders = _resolveSoftwareDecoders(
      textureMode: androidTextureMode,
      textureViewSurface: androidTextureViewSurface,
      isEmulator: isEmulator,
    );
    NativeVideoPlayerConfig.global = NativeVideoPlayerConfig(
      androidTextureMode: androidTextureMode,
      androidTextureViewSurface: androidTextureViewSurface,
      androidForceSoftwareDecoders: forceSoftwareDecoders,
      lightweightInlineViews: true,
      prioritizeActivePlayback: true,
      maxConcurrentPlayingPlayers: 1,
      androidEnableDiskCache: true,
      androidDiskCacheMaxBytes: 250 * 1024 * 1024,
      androidPrecacheBytes: StoryConstants.precacheBytesHls,
      // Buffer config: leaner than feed() presets so active + one preload
      // stay viable on cellular without starving neighbors.
      // iOS: 6s forward (was 10) — enough for brief stalls, less AVPlayer pin.
      iosBufferConfig: const NativeVideoPlayerIosBufferConfig(
        preferredForwardBufferDuration: 6,
      ),
      // Android: min kept for frame starvation avoidance; max tightened.
      androidBufferConfig: const NativeVideoPlayerAndroidBufferConfig(
        minBufferMs: 10000,
        maxBufferMs: 16000,
      ),
      loadTimeout: StoryConstants.playerOperationTimeout,
      bufferingTimeout: const Duration(seconds: 12),
      timeUpdateInterval: const Duration(seconds: 1),
    );

    _config = config;
    StoryLogger.setMinLevel(
      config.env.isProduction ? StoryLogLevel.warning : StoryLogLevel.debug,
    );
    if (navigatorBridge != null) {
      StoryNavigatorBridgeRegistry.set(navigatorBridge);
    }
    if (telemetry != null) {
      StoryTelemetryRegistry.set(telemetry);
    }

    WidgetsFlutterBinding.ensureInitialized();

    // Warm OS number-format separators (iOS Number Format / Android locale).
    unawaited(SystemNumberFormat.instance.refresh());

    // Limit image decode cache for list-heavy UI.
    PaintingBinding.instance.imageCache.maximumSize =
        StoryConstants.imageCacheMaxEntries;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        StoryConstants.imageCacheMaxBytes;

    await Hive.initFlutter();

    final localRepo = StoryLocalRepositoryImpl();
    await localRepo.init();
    // Uninstall wipes the app sandbox (Hive) but iOS Keychain / Android
    // backup can keep JWT + Privy. Clear secure leftovers when sandbox is
    // fresh, before warming the token or restoring auth.
    final sandboxCleared = await localRepo.reconcileSandboxInstall();
    // Overwrite-install / ENV switch keeps the same package data dir — bind
    // Hive + secure storage to this API host before any feature reads cache.
    final envPurged = await localRepo.reconcileEnv(config.effectiveApiBaseUrl);
    // Warm JWT only after env reconcile so a purged host cannot leak a token.
    await localRepo.getTokenAsync();
    // Evict stale cache entries on every cold start so Hive doesn't
    // accumulate expired episode_play_* / drama_detail_* keys that
    // are never re-read before their TTL elapses.
    unawaited(localRepo.vacuumCache());
    _localRepository = localRepo;

    final privyService = PrivyService();
    _privyService = privyService;

    final savedLocale = localRepo.getLocale();
    final locale = savedLocale != null
        ? Locale(savedLocale.languageCode, savedLocale.countryCode)
        : (initialLocale ?? const Locale('zh', 'CN'));

    StoryLocaleController.initialize(localRepo);
    if (savedLocale != null) {
      // Value just came from Hive — seed in memory, skip the write-back.
      StoryLocaleController.instance.seedLocale(locale);
    } else {
      await StoryLocaleController.instance.setLocale(locale);
    }
    StoryThemeController.initialize(localRepo);

    if (sandboxCleared || envPurged) {
      // Block until Privy session is cleared. JWT is already gone, but
      // leftover Privy auth (Keychain / shared Privy app id) must not race
      // AuthController._restore / a fast login tap.
      await privyService.initialize(config, localRepository: localRepo);
      await privyService.logout();
    } else {
      // Normal cold start: don't block first frame; auth awaits init internally.
      unawaited(privyService.initialize(config, localRepository: localRepo));
    }

    _initialized = true;
    StoryLogger.i(
      'StorySdk initialized (env=${config.env.name}'
      '${sandboxCleared ? ', sandboxCleared' : ''}'
      '${envPurged ? ', envPurged' : ''})',
      tag: 'StorySdk',
    );
  }

  Future<void> reconfigure(StorySdkConfig newConfig) async {
    if (!_initialized) {
      throw StateError('Cannot reconfigure before initialize().');
    }
    await dispose();
    await initialize(config: newConfig);
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    await StoryThemeController.instance.dispose();
    await StoryLocaleController.instance.dispose();
    await _localRepository?.dispose();
    _localRepository = null;
    _privyService = null;
    _initialized = false;
    StoryLogger.i('StorySdk disposed', tag: 'StorySdk');
  }
}
