import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../api/story_api_client.dart';
import '../api/upload_cancel_token.dart';
import '../core/result.dart';
import '../core/story_logger.dart';
import '../core/upload_failure.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/file_upload_repository.dart';
import '../services/connectivity_service.dart';
import 'multipart_resumable_upload_executor.dart';
import 'upload_executor.dart';

export 'upload_executor.dart';

class ForegroundSinglePutUploadExecutor implements UploadExecutor {
  ForegroundSinglePutUploadExecutor(this._repository);

  final FileUploadRepository _repository;

  @override
  bool get supportsBackground => false;

  @override
  bool get supportsResume => false;

  @override
  Future<Result<UploadAttemptOutcome>> upload(
    UploadTask task, {
    required UploadCancelToken cancelToken,
    required void Function(double progress) onProgress,
    MultipartCheckpointSink? onCheckpoint,
  }) {
    return _repository
        .uploadFileWithObjectKey(
          filePath: task.localFilePath,
          fileCategory: task.category,
          contentType: task.contentType,
          uploadSessionId: task.uploadSessionId,
          onProgress: onProgress,
          cancelToken: cancelToken,
        )
        .then((result) => result.map(UploadReady.new));
  }
}

/// Global, persistent upload queue.
///
/// Videos route to the multipart executor (byte-level resume: pausing keeps
/// the completed-parts checkpoint, restoring continues from the last part).
/// Small files and covers keep the single-PUT executor, whose pause semantics
/// remain "restart from zero" (gated by `UploadExecutor.supportsResume`).
///
/// Merge polling (the asynchronous complete phase) runs on a dedicated timer
/// per task so it never occupies the single-concurrency pump and never trips
/// the foreground stall detector.
class UploadCoordinator extends Notifier<Map<String, UploadTask>>
    with WidgetsBindingObserver {
  static const _storeKey = 'foreground_upload_tasks:v3';
  static const _legacyStoreKey = 'foreground_upload_tasks:v2';
  static const _maxRetries = 3;
  static const _sessionExpirySkew = Duration(seconds: 30);
  static const _defaultForegroundStallTimeout = Duration(seconds: 15);

  /// Videos at or above this size use the multipart executor.
  static const _multipartThresholdBytes = 10 * 1024 * 1024;

  static const _defaultPollInterval = Duration(seconds: 2);
  static const _defaultPollTimeout = Duration(minutes: 2);
  static const _speedWindowMs = 5000;
  static const _speedSampleIntervalMs = 250;

  static final uploadSessionExpiredError = const UploadFailure(
    UploadFailureKind.sessionExpired,
  ).encoded;
  static final _localFileMissingError = const UploadFailure(
    UploadFailureKind.fileMissing,
  ).encoded;

  late final UploadExecutor _executor;
  late final UploadExecutor _multipartExecutor;
  late final FileUploadRepository _uploadRepository;
  late final ConnectivityService _connectivity;
  late final Box<dynamic> _box;
  final Completer<void> _readyCompleter = Completer<void>();
  final Map<String, UploadCancelToken> _cancelTokens = {};
  final Map<String, int> _attemptGenerations = {};
  final Map<String, int> _persistedProgressBuckets = {};
  final Map<String, int> _lastProgressUpdateAt = {};
  final Set<String> _activeSessions = {};

  /// Tasks downgraded to single-PUT after the backend rejected multipart.
  final Set<String> _singlePutFallbackTasks = {};

  /// Sessions the user confirmed (or manually resumed) for cellular upload.
  final Set<String> _cellularAllowedSessions = {};

  /// Sessions awaiting the cellular confirmation dialog (UI-owned).
  final Set<String> _pendingCellularSessions = {};

  /// Sessions paused by the system (background/cellular), not by the user.
  final Set<String> _systemPausedSessions = {};

  /// Merge-poll timers, keyed by task id.
  final Map<String, Timer> _pollTimers = {};
  final Map<String, DateTime> _pollStartedAt = {};
  final Set<String> _pollingSuspended = {};
  final Map<String, int> _completeResendCounts = {};

  /// Sliding-window speed samples: (timestamp ms, cumulative bytes).
  final Map<String, List<({int ms, int bytes})>> _speedWindows = {};

  /// Per-attempt display anchor: (preserved display D, durable boundary B)
  /// captured when the attempt started. After pause/resume the in-flight
  /// bytes were discarded server-side, so raw reports restart below the
  /// preserved display. Instead of freezing the bar at D (floor), raw bytes
  /// are mapped affinely — `D + (raw-B)·(1-D)/(1-B)` — so re-handed bytes
  /// move the bar IMMEDIATELY from D and the "forgiven" gap converges to
  /// exactly 0% at raw = 1 (true completion). Display ≥ raw always holds,
  /// and the mapping is monotonic and re-entrant across repeated pauses.
  final Map<String, ({double display, double boundary})> _displayAnchors = {};
  final Map<String, int> _lastSpeedComputedAt = {};

  bool _multipartEnabled = true;
  bool _previousWifi = true;
  Future<void> _persistTail = Future<void>.value();
  String? _currentUserId;
  bool _running = false;
  bool _foreground = true;
  String? _lastScheduledSessionId;
  Timer? _foregroundStallTimer;

  @visibleForTesting
  Duration foregroundStallTimeout = _defaultForegroundStallTimeout;

  @visibleForTesting
  Duration pollInterval = _defaultPollInterval;

  @visibleForTesting
  Duration pollTimeout = _defaultPollTimeout;

  @visibleForTesting
  set multipartEnabled(bool value) => _multipartEnabled = value;

  Future<void> get ready => _readyCompleter.future;

  Future<void> waitForIdle() async {
    while (_running && ref.mounted) {
      await Future<void>.delayed(Duration.zero);
    }
    await _persistTail;
  }

  /// Sessions waiting for the cellular confirmation dialog. The UI listens
  /// for state changes and shows the dialog, then calls
  /// [confirmCellularUpload].
  Set<String> get pendingCellularConfirmations =>
      Set.unmodifiable(_pendingCellularSessions);

  @override
  Map<String, UploadTask> build() {
    _uploadRepository = ref.read(fileUploadRepositoryProvider);
    _executor = createSinglePutExecutor(_uploadRepository);
    _multipartExecutor = createMultipartExecutor(
      _uploadRepository,
      ref.read(apiClientProvider),
      ref.read(connectivityProvider),
    );
    _connectivity = ref.read(connectivityProvider);
    _box = ref.read(localRepositoryProvider).cacheBox;
    _currentUserId = ref.read(currentUserIdProvider);
    _previousWifi = _connectivity.isWifi;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _connectivity.addListener(_onConnectivityChanged);
    ref.listen<String?>(currentUserIdProvider, (_, next) {
      unawaited(_switchUser(next));
    });
    ref.onDispose(() {
      _foregroundStallTimer?.cancel();
      for (final timer in _pollTimers.values) {
        timer.cancel();
      }
      _pollTimers.clear();
      WidgetsBinding.instance.removeObserver(this);
      _connectivity.removeListener(_onConnectivityChanged);
      for (final token in _cancelTokens.values) {
        token.cancel();
      }
    });
    Future.microtask(_restore);
    return const {};
  }

  /// Executor factories are protected so tests can substitute fakes.
  @visibleForTesting
  UploadExecutor createSinglePutExecutor(FileUploadRepository repository) =>
      ForegroundSinglePutUploadExecutor(repository);

  @visibleForTesting
  UploadExecutor createMultipartExecutor(
    FileUploadRepository repository,
    StoryApiClient api,
    ConnectivityService connectivity,
  ) => MultipartResumableUploadExecutor(repository, api, connectivity);

  UploadTask? task(String id) {
    final task = state[id];
    return task?.ownerUserId == _currentUserId ? task : null;
  }

  Iterable<UploadTask> tasksForSession(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) return const [];
    return state.values.where(
      (task) =>
          task.ownerUserId == _currentUserId &&
          task.uploadSessionId == sessionId,
    );
  }

  /// Copies a picker-owned file into durable app storage.
  Future<String> adoptFile(String taskId, String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Selected video no longer exists', sourcePath);
    }
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/managed_uploads/$taskId');
    await directory.create(recursive: true);
    final sourceName = sourcePath.split(Platform.pathSeparator).last;
    final safeName = sourceName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final destination = File('${directory.path}/$safeName');
    if (source.absolute.path == destination.absolute.path) {
      return destination.path;
    }
    try {
      if (await destination.exists()) await destination.delete();
      await source.copy(destination.path);
      return destination.path;
    } catch (_) {
      if (await directory.exists()) await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> discardManagedFile(String path) => _deleteManagedFile(path);

  Future<void> enqueue(UploadTask task) async {
    await ready;
    if (task.ownerUserId != _currentUserId) {
      throw StateError('Upload owner does not match the signed-in user');
    }
    final shouldStart = task.status != UploadTaskStatus.paused;
    if (shouldStart) _activeSessions.add(task.uploadSessionId);
    final existing = state[task.id];
    if (existing?.status == UploadTaskStatus.success) return;
    _setTask(
      task.copyWith(
        status: shouldStart ? UploadTaskStatus.queued : UploadTaskStatus.paused,
        progress: _breakpointProgress(task),
      ),
    );
    await _persist();
    if (shouldStart) _schedulePump();
  }

  /// Activates persisted tasks when their owning draft is reopened.
  Future<void> activateSession(String? sessionId) async {
    if (sessionId == null || sessionId.isEmpty) return;
    await ready;
    _activeSessions.add(sessionId);
    var changed = false;
    final next = Map<String, UploadTask>.from(state);
    for (final entry in next.entries.toList()) {
      final task = entry.value;
      if (task.uploadSessionId != sessionId ||
          task.ownerUserId != _currentUserId ||
          task.status != UploadTaskStatus.paused ||
          task.userPaused) {
        continue;
      }
      next[entry.key] = task.copyWith(
        status: UploadTaskStatus.queued,
        progress: _breakpointProgress(task),
        clearError: true,
      );
      changed = true;
    }
    if (changed) {
      state = next;
      await _persist();
    }
    // Merge polling resumes with the session even after a process restart.
    for (final task in state.values) {
      if (task.status == UploadTaskStatus.merging &&
          task.uploadSessionId == sessionId &&
          task.ownerUserId == _currentUserId) {
        _startFinalizePolling(task);
      }
    }
    _schedulePump();
  }

  /// Rebinds unfinished tasks after an expired session is safely replaced.
  Future<bool> replaceSession({
    required String oldSessionId,
    required String newSessionId,
    required int? newSessionExpiresAt,
  }) async {
    await ready;
    final owned = state.values.where(
      (task) =>
          task.ownerUserId == _currentUserId &&
          task.uploadSessionId == oldSessionId &&
          task.status != UploadTaskStatus.canceled,
    );
    if (owned.any((task) => task.status == UploadTaskStatus.success)) {
      return false;
    }

    final canStart = _foreground && _connectivity.value;
    final next = Map<String, UploadTask>.from(state);
    var changed = false;
    for (final task in owned.toList(growable: false)) {
      _attemptGenerations[task.id] = (_attemptGenerations[task.id] ?? 0) + 1;
      _cancelTokens.remove(task.id)?.cancel();
      _stopFinalizePolling(task.id);
      // The multipart uploadId belongs to the old session: abort the parts
      // on object storage and restart the transfer under the new session.
      _abortMultipartQuietly(task);
      // 用户手动暂停的任务：换绑 session 后仍保持 paused，不自动恢复。
      final shouldQueue = canStart && !task.userPaused;
      next[task.id] = task.copyWith(
        uploadSessionId: newSessionId,
        uploadSessionExpiresAt: newSessionExpiresAt,
        clearUploadSessionExpiresAt: newSessionExpiresAt == null,
        status: shouldQueue ? UploadTaskStatus.queued : UploadTaskStatus.paused,
        progress: 0,
        retryCount: 0,
        clearError: true,
        resetMultipartState: true,
      );
      changed = true;
    }

    _activeSessions
      ..remove(oldSessionId)
      ..add(newSessionId);
    if (changed) {
      state = next;
      await _persist();
    }
    if (canStart) _schedulePump();
    return true;
  }

  /// Rebinds persisted tasks to [sessionId], creates missing queue entries,
  /// and activates the session. Templates must belong to the current user.
  Future<bool> restoreTasks(
    Iterable<UploadTask> templates, {
    required String sessionId,
    required int? sessionExpiresAt,
  }) async {
    await ready;
    final tasks = templates.toList(growable: false);
    if (tasks.any((task) => task.ownerUserId != _currentUserId)) {
      return false;
    }

    final oldSessionIds = <String>{
      for (final template in tasks)
        if (state[template.id] case final existing?
            when existing.ownerUserId == _currentUserId &&
                existing.uploadSessionId != sessionId)
          existing.uploadSessionId,
    };
    for (final oldSessionId in oldSessionIds) {
      final replaced = await replaceSession(
        oldSessionId: oldSessionId,
        newSessionId: sessionId,
        newSessionExpiresAt: sessionExpiresAt,
      );
      if (!replaced) return false;
    }

    for (final template in tasks) {
      final existing = task(template.id);
      if (existing?.status == UploadTaskStatus.success) continue;
      if (existing != null && existing.status != UploadTaskStatus.failed) {
        continue;
      }
      await enqueue(
        (existing ?? template).copyWith(
          uploadSessionId: sessionId,
          uploadSessionExpiresAt: sessionExpiresAt,
          clearUploadSessionExpiresAt: sessionExpiresAt == null,
          status: UploadTaskStatus.paused,
          retryCount: 0,
          clearError: true,
        ),
      );
    }
    await activateSession(sessionId);
    return true;
  }

  Future<void> retry(String id) async {
    await ready;
    final task = state[id];
    if (task == null ||
        task.ownerUserId != _currentUserId ||
        task.status == UploadTaskStatus.success) {
      return;
    }
    if (!await File(task.localFilePath).exists()) {
      _setTask(
        task.copyWith(
          status: UploadTaskStatus.failed,
          lastError: _localFileMissingError,
        ),
      );
      await _persist();
      return;
    }
    // A merge-phase failure (e.g. polling timeout) retries by re-entering the
    // poll; the parts are already on object storage and complete is
    // idempotent, so re-uploading would be wasted traffic.
    if (task.multipartPhase == MultipartPhase.finalizeRequested &&
        task.multipartUploadId != null) {
      _setTask(
        task.copyWith(
          status: UploadTaskStatus.merging,
          progress: 1,
          clearError: true,
        ),
      );
      await _persist();
      _startFinalizePolling(task);
      return;
    }
    _setTask(
      task.copyWith(
        status: UploadTaskStatus.queued,
        progress: _breakpointProgress(task),
        retryCount: 0,
        clearError: true,
        clearUserPaused: true,
      ),
    );
    await _persist();
    _schedulePump();
  }

  /// Pauses a task (user action). Multipart tasks keep their breakpoint;
  /// single-PUT tasks restart from zero on the next attempt by design.
  Future<void> pauseTask(String id) async {
    await ready;
    final task = state[id];
    if (task == null || task.ownerUserId != _currentUserId) return;
    switch (task.status) {
      case UploadTaskStatus.uploading ||
            UploadTaskStatus.retryWaiting ||
            UploadTaskStatus.queued:
        _attemptGenerations[id] = (_attemptGenerations[id] ?? 0) + 1;
        _cancelTokens.remove(id)?.cancel();
        _setTask(
          task.copyWith(
            status: UploadTaskStatus.paused,
            progress: _breakpointProgress(task),
            speedBps: 0,
            networkWait: false,
            lastError: 'Upload paused by user',
            userPaused: true,
          ),
        );
        await _persist();
      case UploadTaskStatus.merging:
        // The merge was already accepted; pausing only stops the poll.
        _suspendFinalizePollingTask(id);
        _setTask(task.copyWith(speedBps: 0));
      case UploadTaskStatus.paused ||
            UploadTaskStatus.success ||
            UploadTaskStatus.failed ||
            UploadTaskStatus.canceled:
        break;
    }
  }

  /// Resumes a task (user action). Per the PRD, a manual resume after the
  /// cellular dialog was dismissed uploads directly without asking again,
  /// so the cellular gate is bypassed and the session is marked allowed.
  Future<void> resumeTask(String id) async {
    await ready;
    final task = state[id];
    if (task == null || task.ownerUserId != _currentUserId) return;
    if (task.status == UploadTaskStatus.merging) {
      _resumeFinalizePollingTask(id);
      return;
    }
    if (task.status != UploadTaskStatus.paused) return;
    if (!await File(task.localFilePath).exists()) {
      _setTask(
        task.copyWith(
          status: UploadTaskStatus.failed,
          lastError: _localFileMissingError,
        ),
      );
      await _persist();
      return;
    }
    if (!_connectivity.value) return;
    if (_onCellular) {
      _cellularAllowedSessions.add(task.uploadSessionId);
      _pendingCellularSessions.remove(task.uploadSessionId);
    }
    _activeSessions.add(task.uploadSessionId);
    _setTask(
      task.copyWith(
        status: UploadTaskStatus.queued,
        progress: _breakpointProgress(task),
        clearError: true,
        clearUserPaused: true,
      ),
    );
    await _persist();
    _schedulePump();
  }

  Future<void> remove(String id, {bool deleteFile = true}) async {
    await ready;
    final task = state[id];
    if (task == null || task.ownerUserId != _currentUserId) return;
    _attemptGenerations[id] = (_attemptGenerations[id] ?? 0) + 1;
    _cancelTokens.remove(id)?.cancel();
    _stopFinalizePolling(id);
    _abortMultipartQuietly(task);
    final next = Map<String, UploadTask>.from(state)..remove(id);
    state = next;
    _persistedProgressBuckets.remove(id);
    _lastProgressUpdateAt.remove(id);
    _speedWindows.remove(id);
    _lastSpeedComputedAt.remove(id);
    _displayAnchors.remove(id);
    _singlePutFallbackTasks.remove(id);
    await _persist();
    if (deleteFile) await _deleteManagedFile(task.localFilePath);
  }

  Future<void> removeAll(Iterable<String> ids) async {
    for (final id in ids.toList(growable: false)) {
      await remove(id);
    }
  }

  /// Marks a session as confirmed for cellular upload (used by the pick
  /// flow after the pre-upload dialog, and by the runtime dialog).
  void allowCellularForSession(String sessionId) {
    _cellularAllowedSessions.add(sessionId);
    if (_pendingCellularSessions.remove(sessionId)) _touchState();
  }

  /// Resolves a pending cellular confirmation raised by the coordinator.
  Future<void> confirmCellularUpload(
    String sessionId, {
    required bool accepted,
  }) async {
    await ready;
    if (_pendingCellularSessions.remove(sessionId)) {
      if (accepted) {
        _cellularAllowedSessions.add(sessionId);
      }
      // Whether accepted or rejected, the user has made a decision for this
      // session; remove it from system-paused so foreground/network-resume
      // loops do not ask again automatically.
      _systemPausedSessions.remove(sessionId);
      if (accepted) {
        await _resumePaused();
      }
      // Rejected: tasks stay paused with their breakpoint; a manual resume
      // later uploads directly without asking again (PRD).
      _touchState();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_handleForegroundResume());
      case AppLifecycleState.inactive:
        // Transient system overlays should not affect the active request.
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _foreground = false;
        _foregroundStallTimer?.cancel();
        _suspendFinalizePolling();
        unawaited(
          _pauseActive('Upload paused because the app went to background'),
        );
      case AppLifecycleState.detached:
        _foreground = false;
        _foregroundStallTimer?.cancel();
        _suspendFinalizePolling();
        unawaited(_pauseActive('Upload paused because the app detached'));
    }
  }

  Future<void> _handleForegroundResume() async {
    _foreground = true;
    _resumeFinalizePolling();
    await _resumePaused();
    _watchForegroundUploadForStall();
  }

  void _watchForegroundUploadForStall() {
    _foregroundStallTimer?.cancel();
    if (!_foreground || foregroundStallTimeout <= Duration.zero) return;
    final active = state.values.cast<UploadTask?>().firstWhere(
      (task) =>
          task?.ownerUserId == _currentUserId &&
          task?.status == UploadTaskStatus.uploading,
      orElse: () => null,
    );
    if (active == null) return;
    final taskId = active.id;
    final baselineProgressAt = _lastProgressUpdateAt[taskId] ?? 0;
    final generation = _attemptGenerations[taskId];
    _foregroundStallTimer = Timer(foregroundStallTimeout, () {
      if (!_foreground || !ref.mounted) return;
      final current = state[taskId];
      final hasProgressed =
          (_lastProgressUpdateAt[taskId] ?? 0) > baselineProgressAt;
      if (current?.ownerUserId != _currentUserId ||
          current?.status != UploadTaskStatus.uploading ||
          _attemptGenerations[taskId] != generation) {
        return;
      }
      if (hasProgressed) {
        _watchForegroundUploadForStall();
        return;
      }
      unawaited(_restartActiveUpload(taskId));
    });
  }

  Future<void> _restartActiveUpload(String taskId) async {
    final task = state[taskId];
    if (!_foreground ||
        task == null ||
        task.ownerUserId != _currentUserId ||
        task.status != UploadTaskStatus.uploading) {
      return;
    }
    _attemptGenerations[taskId] = (_attemptGenerations[taskId] ?? 0) + 1;
    _cancelTokens.remove(taskId)?.cancel();
    _setTask(
      task.copyWith(
        status: UploadTaskStatus.queued,
        progress: _breakpointProgress(task),
        lastError: 'Upload restarted after foreground progress stalled',
      ),
    );
    await _persist();
    _schedulePump();
  }

  void _onConnectivityChanged() {
    final online = _connectivity.value;
    final wifi = _connectivity.isWifi;
    final wasWifi = _previousWifi;
    _previousWifi = wifi;
    if (!online) {
      unawaited(_pauseForNetworkLoss());
      return;
    }
    if (!wifi && wasWifi) {
      // Wi-Fi → cellular while uploads are running: auto-pause (breakpoint
      // preserved) and ask the user (PRD cellular policy).
      unawaited(_pauseForCellular());
      return;
    }
    unawaited(_onNetworkRestored());
  }

  bool get _onCellular =>
      _connectivity.connectionType == ConnectionType.cellular;

  /// Offline: in-flight attempts stop but uploading tasks KEEP their status
  /// plus the transient `networkWait` flag, so the UI shows
  /// "waiting for network" and restoration can auto-continue silently.
  Future<void> _pauseForNetworkLoss() async {
    await ready;
    var changed = false;
    final next = Map<String, UploadTask>.from(state);
    for (final entry in next.entries.toList()) {
      final task = entry.value;
      if (task.ownerUserId != _currentUserId) continue;
      switch (task.status) {
        case UploadTaskStatus.uploading ||
              UploadTaskStatus.retryWaiting:
          _attemptGenerations[task.id] = (_attemptGenerations[task.id] ?? 0) + 1;
          _cancelTokens.remove(task.id)?.cancel();
          next[entry.key] = task.copyWith(
            networkWait: true,
            speedBps: 0,
            lastError: 'Waiting for network connection',
          );
          changed = true;
        case UploadTaskStatus.queued:
          _attemptGenerations[task.id] = (_attemptGenerations[task.id] ?? 0) + 1;
          _cancelTokens.remove(task.id)?.cancel();
          next[entry.key] = task.copyWith(
            status: UploadTaskStatus.paused,
            networkWait: true,
            speedBps: 0,
            lastError: 'Waiting for network connection',
          );
          changed = true;
        case UploadTaskStatus.merging:
          // The poll loop re-checks connectivity on every tick; offline time
          // does not count against the merge timeout (reset on restore).
          next[entry.key] = task.copyWith(networkWait: true, speedBps: 0);
          changed = true;
        case UploadTaskStatus.paused ||
              UploadTaskStatus.success ||
              UploadTaskStatus.failed ||
              UploadTaskStatus.canceled:
          break;
      }
    }
    if (changed) {
      state = next;
      await _persist();
    }
  }

  /// Back online: tasks that were waiting for the network resume by type.
  /// Wi-Fi continues silently; cellular parks uploading tasks in paused and
  /// raises the confirmation dialog (PRD).
  Future<void> _onNetworkRestored() async {
    await ready;
    final onCellular = _onCellular;
    var changed = false;
    var confirmationsChanged = false;
    final next = Map<String, UploadTask>.from(state);
    for (final entry in next.entries.toList()) {
      final task = entry.value;
      if (task.ownerUserId != _currentUserId || !task.networkWait) continue;
      switch (task.status) {
        case UploadTaskStatus.uploading ||
              UploadTaskStatus.retryWaiting:
          if (!onCellular ||
              _cellularAllowedSessions.contains(task.uploadSessionId)) {
            next[entry.key] = task.copyWith(
              status: UploadTaskStatus.queued,
              networkWait: false,
              clearError: true,
            );
          } else {
            next[entry.key] = task.copyWith(
              status: UploadTaskStatus.paused,
              networkWait: false,
              speedBps: 0,
              lastError: 'Upload paused on cellular network',
            );
            _systemPausedSessions.add(task.uploadSessionId);
            if (_pendingCellularSessions.add(task.uploadSessionId)) {
              confirmationsChanged = true;
            }
          }
          changed = true;
        case UploadTaskStatus.merging:
          next[entry.key] = task.copyWith(networkWait: false);
          // Offline time excluded from the merge timeout budget.
          _pollStartedAt[task.id] = DateTime.now();
          if (!_pollingSuspended.contains(task.id)) {
            _schedulePoll(task.id, immediate: true);
          }
          changed = true;
        case UploadTaskStatus.queued ||
              UploadTaskStatus.paused:
          // 用户手动暂停的任务：仅清除 networkWait 标记，保持 paused。
          if (task.userPaused) {
            if (task.networkWait) {
              next[entry.key] = task.copyWith(networkWait: false);
              changed = true;
            }
          } else {
            next[entry.key] = task.copyWith(networkWait: false);
            changed = true;
          }
        case UploadTaskStatus.success ||
              UploadTaskStatus.failed ||
              UploadTaskStatus.canceled:
          break;
      }
    }
    if (changed) {
      state = next;
      await _persist();
    }
    if (confirmationsChanged) _touchState();
    await _resumePaused();
  }

  /// Wi-Fi → cellular while online: auto-pause unconfirmed sessions and ask.
  Future<void> _pauseForCellular() async {
    await ready;
    var changed = false;
    var confirmationsChanged = false;
    final next = Map<String, UploadTask>.from(state);
    for (final entry in next.entries.toList()) {
      final task = entry.value;
      if (task.ownerUserId != _currentUserId) continue;
      if (task.status != UploadTaskStatus.uploading &&
          task.status != UploadTaskStatus.retryWaiting &&
          task.status != UploadTaskStatus.queued) {
        continue;
      }
      if (_cellularAllowedSessions.contains(task.uploadSessionId)) continue;
      _attemptGenerations[task.id] = (_attemptGenerations[task.id] ?? 0) + 1;
      _cancelTokens.remove(task.id)?.cancel();
      next[entry.key] = task.copyWith(
        status: UploadTaskStatus.paused,
        progress: _breakpointProgress(task),
        speedBps: 0,
        networkWait: false,
        lastError: 'Upload paused on cellular network',
      );
      _systemPausedSessions.add(task.uploadSessionId);
      if (_pendingCellularSessions.add(task.uploadSessionId)) {
        confirmationsChanged = true;
      }
      changed = true;
    }
    if (changed) {
      state = next;
      await _persist();
    }
    if (confirmationsChanged) _touchState();
  }

  Future<void> _switchUser(String? nextUserId) async {
    await ready;
    if (!ref.mounted) return;
    if (_currentUserId == nextUserId) return;
    _currentUserId = nextUserId;
    _activeSessions.clear();
    _lastScheduledSessionId = null;
    _cellularAllowedSessions.clear();
    _pendingCellularSessions.clear();
    _systemPausedSessions.clear();
    _singlePutFallbackTasks.clear();
    _suspendFinalizePolling();
    await _pauseActive('Upload paused after account change');
  }

  Future<void> _restore() async {
    try {
      var raw = _box.get(_storeKey);
      var migratedFromLegacy = false;
      if (raw == null) {
        // v3 store missing: adopt the v2 queue once (v2 tasks carry no
        // multipart checkpoint, so they resume from zero as before), persist
        // under the new key, then drop the legacy entry.
        final legacy = _box.get(_legacyStoreKey);
        if (legacy != null) {
          raw = legacy;
          migratedFromLegacy = true;
        }
      }
      final restored = <String, UploadTask>{};
      if (raw is List) {
        for (final value in raw) {
          final task = UploadTask.fromMap(value);
          if (task != null && task.status != UploadTaskStatus.canceled) {
            restored[task.id] = task;
          }
        }
      }
      if (state.isEmpty) {
        state = restored;
      } else if (restored.isNotEmpty) {
        state = {...restored, ...state};
      }
      if (migratedFromLegacy) {
        await _persist();
        await _box.delete(_legacyStoreKey);
      }
    } catch (error, stackTrace) {
      StoryLogger.w(
        'Failed to restore upload queue',
        tag: 'UploadCoordinator',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    }
  }

  /// Cancels in-flight attempts and parks queued/uploading tasks in paused.
  /// Multipart tasks keep their breakpoint; single-PUT tasks restart from
  /// zero on the next attempt (executor capability gate).
  Future<void> _pauseActive(String reason) async {
    await ready;
    var changed = false;
    final next = Map<String, UploadTask>.from(state);
    for (final entry in next.entries.toList()) {
      final task = entry.value;
      if (task.status != UploadTaskStatus.uploading &&
          task.status != UploadTaskStatus.retryWaiting &&
          task.status != UploadTaskStatus.queued) {
        continue;
      }
      _attemptGenerations[task.id] = (_attemptGenerations[task.id] ?? 0) + 1;
      _cancelTokens.remove(task.id)?.cancel();
      next[entry.key] = task.copyWith(
        status: UploadTaskStatus.paused,
        progress: _breakpointProgress(task),
        speedBps: 0,
        networkWait: false,
        lastError: reason,
      );
      _systemPausedSessions.add(task.uploadSessionId);
      changed = true;
    }
    if (changed) {
      state = next;
      await _persist();
    }
  }

  Future<void> _resumePaused() async {
    if (!_foreground || !_connectivity.value) return;
    await ready;
    final onCellular = _onCellular;
    var changed = false;
    var confirmationsChanged = false;
    final next = Map<String, UploadTask>.from(state);
    for (final entry in next.entries.toList()) {
      final task = entry.value;
      if (task.status != UploadTaskStatus.paused ||
          task.ownerUserId != _currentUserId ||
          task.userPaused ||
          !_activeSessions.contains(task.uploadSessionId)) {
        continue;
      }
      if (onCellular && !_cellularAllowedSessions.contains(task.uploadSessionId)) {
        // Ask only for sessions the system paused (background/cellular).
        // User-paused tasks stay paused; a manual resume uploads directly.
        if (_systemPausedSessions.contains(task.uploadSessionId)) {
          if (_pendingCellularSessions.add(task.uploadSessionId)) {
            confirmationsChanged = true;
          }
        }
        if (task.networkWait) {
          next[entry.key] = task.copyWith(networkWait: false);
          changed = true;
        }
        continue;
      }
      next[entry.key] = task.copyWith(
        status: UploadTaskStatus.queued,
        progress: _breakpointProgress(task),
        networkWait: false,
        clearError: true,
      );
      changed = true;
      if (_pendingCellularSessions.remove(task.uploadSessionId)) {
        confirmationsChanged = true;
      }
    }
    if (changed) {
      state = next;
      await _persist();
    }
    if (confirmationsChanged) _touchState();
    _schedulePump();
  }

  void _schedulePump() {
    if (_running) return;
    unawaited(_pump());
  }

  Future<void> _pump() async {
    await ready;
    if (!ref.mounted || _running || !_foreground || !_connectivity.value) {
      return;
    }
    _running = true;
    try {
      while (ref.mounted && _foreground && _connectivity.value) {
        final task = _nextQueuedTask();
        if (task == null) break;
        await _runTask(task);
        if (!ref.mounted) break;
      }
    } finally {
      _running = false;
    }
  }

  UploadTask? _nextQueuedTask() {
    final queued = state.values
        .where(
          (task) =>
              task.status == UploadTaskStatus.queued &&
              task.ownerUserId == _currentUserId,
        )
        .toList(growable: false);
    if (queued.isEmpty) return null;

    final sessions = <String>[];
    final seenSessions = <String>{};
    for (final task in queued) {
      if (seenSessions.add(task.uploadSessionId)) {
        sessions.add(task.uploadSessionId);
      }
    }
    var sessionIndex = 0;
    final lastIndex = sessions.indexOf(_lastScheduledSessionId ?? '');
    if (lastIndex >= 0) sessionIndex = (lastIndex + 1) % sessions.length;
    final selectedSessionId = sessions[sessionIndex];
    _lastScheduledSessionId = selectedSessionId;
    return queued.firstWhere(
      (task) => task.uploadSessionId == selectedSessionId,
    );
  }

  bool _usesMultipart(UploadTask task) =>
      _multipartEnabled &&
      !_singlePutFallbackTasks.contains(task.id) &&
      task.category == FileCategory.video &&
      task.fileSize >= _multipartThresholdBytes;

  UploadExecutor _executorFor(UploadTask task) =>
      _usesMultipart(task) ? _multipartExecutor : _executor;

  /// 显示层「保留进度」：暂停/失败/恢复等状态转换时进度条展示的值。
  ///
  /// 与持久层（[UploadTask.completedParts]，断点续传的真正依据）分离：
  /// 并发分片下任何一片 ACK 之前，现场显示进度几乎全部是在途字节，
  /// 若按持久边界（uploadedBytes/fileSize）取值会从 40% 直接跳 0%。
  /// 因此显示取 `max(现场进度, 持久边界)`——在途字节作废造成的真实回退
  /// 由恢复后的显示地板（[_displayFloors]）吸收为「冻结后爬升」，
  /// 保证进度条在一个任务生命周期内单调不减。
  ///
  /// 单 PUT 任务维持「归零重传」语义，恒返回 0；121026 重传/换绑 session
  /// 的全量重传路径显式置 0，不走本方法。
  double _breakpointProgress(UploadTask task) {
    if (!_executorFor(task).supportsResume) return 0;
    if (task.fileSize <= 0) return 0;
    final boundary = _durableBoundary(task);
    return task.progress > boundary ? task.progress : boundary;
  }

  /// 持久边界：已 ACK 分片字节 / 总大小（断点续传的真正依据）。
  double _durableBoundary(UploadTask task) {
    if (!_executorFor(task).supportsResume) return 0;
    if (task.completedParts.isEmpty || task.fileSize <= 0) return 0;
    return (task.uploadedBytes / task.fileSize).clamp(0.0, 1.0);
  }

  bool _isMultipartUnsupported(ApiError error) =>
      error is NotFoundError || error is NotSupportedError;

  Future<void> _runTask(UploadTask initial) async {
    final currentAtStart = state[initial.id];
    if (currentAtStart != initial ||
        currentAtStart?.status != UploadTaskStatus.queued) {
      return;
    }
    if (_isSessionExpired(initial)) {
      _setTask(
        initial.copyWith(
          status: UploadTaskStatus.failed,
          progress: 0,
          lastError: uploadSessionExpiredError,
        ),
      );
      await _persist();
      return;
    }
    final file = File(initial.localFilePath);
    final fileExists = await file.exists();
    final currentAfterFileCheck = state[initial.id];
    if (currentAfterFileCheck != initial ||
        currentAfterFileCheck?.status != UploadTaskStatus.queued) {
      return;
    }
    if (!fileExists) {
      _setTask(
        initial.copyWith(
          status: UploadTaskStatus.failed,
          lastError: _localFileMissingError,
        ),
      );
      await _persist();
      _persistedProgressBuckets.remove(initial.id);
      _lastProgressUpdateAt.remove(initial.id);
      return;
    }

    // Cellular gate: an unconfirmed session never starts traffic on cellular.
    if (_onCellular &&
        !_cellularAllowedSessions.contains(initial.uploadSessionId)) {
      _systemPausedSessions.add(initial.uploadSessionId);
      var confirmationsChanged = false;
      if (_pendingCellularSessions.add(initial.uploadSessionId)) {
        confirmationsChanged = true;
      }
      _setTask(
        initial.copyWith(
          status: UploadTaskStatus.paused,
          progress: _breakpointProgress(initial),
          lastError: 'Upload paused on cellular network',
        ),
      );
      await _persist();
      if (confirmationsChanged) _touchState();
      return;
    }

    final executor = _executorFor(initial);
    final resumable = executor.supportsResume;
    final generation = (_attemptGenerations[initial.id] ?? 0) + 1;
    _attemptGenerations[initial.id] = generation;
    final cancelToken = UploadCancelToken();
    _cancelTokens[initial.id] = cancelToken;
    _speedWindows.remove(initial.id);
    _lastSpeedComputedAt.remove(initial.id);
    final startProgress = _breakpointProgress(initial);
    _displayAnchors[initial.id] = (
      display: startProgress,
      boundary: _durableBoundary(initial),
    );
    _setTask(
      initial.copyWith(
        status: UploadTaskStatus.uploading,
        progress: startProgress,
        speedBps: 0,
        networkWait: false,
        clearError: true,
      ),
    );
    await _persist();

    if (!ref.mounted || _attemptGenerations[initial.id] != generation) return;
    final uploading = state[initial.id];
    if (uploading == null || uploading.status != UploadTaskStatus.uploading) {
      return;
    }
    final result = await executor.upload(
      uploading,
      cancelToken: cancelToken,
      onProgress: (progress) => _onProgress(initial.id, generation, progress),
      onCheckpoint: resumable
          ? (checkpoint) =>
              _onMultipartCheckpoint(initial.id, generation, checkpoint)
          : null,
    );
    if (!ref.mounted) return;
    _cancelTokens.remove(initial.id);
    if (_attemptGenerations[initial.id] != generation) return;
    final current = state[initial.id];
    if (current == null || current.status != UploadTaskStatus.uploading) {
      return;
    }

    if (result case Success(:final data)) {
      switch (data) {
        case UploadReady(:final file):
          _setTask(
            current.copyWith(
              status: UploadTaskStatus.success,
              progress: 1,
              objectKey: file.objectKey,
              publicUrl: file.publicUrl,
              clearError: true,
              resetMultipartState: true,
              networkWait: false,
              speedBps: 0,
            ),
          );
          _speedWindows.remove(initial.id);
          _lastSpeedComputedAt.remove(initial.id);
          await _persist();
          return;
        case UploadFinalizePending(:final uploadId, :final objectKey, :final publicUrl):
          // All parts are on object storage and the merge was accepted:
          // switch to the merge-polling phase (never blocks the pump).
          _setTask(
            current.copyWith(
              status: UploadTaskStatus.merging,
              progress: 1,
              speedBps: 0,
              multipartUploadId: uploadId,
              multipartObjectKey: objectKey,
              publicUrl: publicUrl ?? current.publicUrl,
              multipartPhase: MultipartPhase.finalizeRequested,
            ),
          );
          await _persist();
          _startFinalizePolling(current);
          return;
      }
    }

    final error = result.errorOrNull!;
    // Backend without multipart support: downgrade this task to single-PUT.
    if (identical(executor, _multipartExecutor) &&
        _isMultipartUnsupported(error)) {
      _singlePutFallbackTasks.add(initial.id);
      StoryLogger.w(
        'Multipart not supported by backend; falling back to single-PUT',
        tag: 'UploadCoordinator',
      );
      _setTask(
        current.copyWith(
          status: UploadTaskStatus.queued,
          progress: 0,
          clearError: true,
        ),
      );
      await _persist();
      _schedulePump();
      return;
    }
    final safeError = UploadFailure.fromApiError(error).encoded;
    if (!_foreground || !_connectivity.value) {
      _setTask(
        current.copyWith(
          status: UploadTaskStatus.paused,
          progress: resumable ? _breakpointProgress(current) : 0,
          networkWait: !_connectivity.value,
          speedBps: 0,
          lastError: safeError,
        ),
      );
      await _persist();
      return;
    }
    final retryCount = current.retryCount + 1;
    if (_isRetryable(error) && retryCount <= _maxRetries) {
      _setTask(
        current.copyWith(
          status: UploadTaskStatus.retryWaiting,
          progress: resumable ? _breakpointProgress(current) : 0,
          retryCount: retryCount,
          lastError: safeError,
        ),
      );
      await _persist();
      await Future<void>.delayed(Duration(seconds: 1 << (retryCount - 1)));
      if (!ref.mounted) return;
      final waiting = state[initial.id];
      if (waiting?.status == UploadTaskStatus.retryWaiting &&
          _foreground &&
          _connectivity.value) {
        _setTask(waiting!.copyWith(status: UploadTaskStatus.queued));
        await _persist();
      }
      return;
    }
    _setTask(
      current.copyWith(
        status: UploadTaskStatus.failed,
        progress: resumable ? _breakpointProgress(current) : 0,
        retryCount: retryCount,
        speedBps: 0,
        lastError: safeError,
      ),
    );
    await _persist();
  }

  /// Executor write-back for durable multipart checkpoints. The executor
  /// never touches UI-only fields, so those are merged from the live task.
  void _onMultipartCheckpoint(String id, int generation, UploadTask checkpoint) {
    if (!ref.mounted) return;
    if (_attemptGenerations[id] != generation) return;
    final task = state[id];
    if (task == null || task.status != UploadTaskStatus.uploading) return;
    _setTask(
      checkpoint.copyWith(
        status: UploadTaskStatus.uploading,
        progress: task.progress,
        networkWait: task.networkWait,
        speedBps: task.speedBps,
      ),
    );
    unawaited(_persist());
  }

  void _onProgress(String id, int generation, double progress) {
    if (!ref.mounted) return;
    if (_attemptGenerations[id] != generation) return;
    final task = state[id];
    if (task == null || task.status != UploadTaskStatus.uploading) return;
    final raw = progress.clamp(0.0, 1.0);
    // Affine catch-up mapping (see _displayAnchors): the bar continues from
    // the preserved display and moves immediately as re-handed bytes arrive,
    // converging to the true position at completion. Identity for fresh
    // uploads (D = B = 0).
    final anchor = _displayAnchors[id];
    final normalized =
        anchor == null || anchor.boundary >= 1.0
        ? raw
        : (anchor.display +
                (raw - anchor.boundary) *
                    (1 - anchor.display) / (1 - anchor.boundary))
            .clamp(0.0, 1.0);
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastUpdate = _lastProgressUpdateAt[id] ?? 0;
    if (normalized < 1 &&
        normalized - task.progress < 0.01 &&
        now - lastUpdate < 200) {
      return;
    }
    _lastProgressUpdateAt[id] = now;
    var speedBps = task.speedBps;
    if (task.fileSize > 0) {
      final window = _speedWindows.putIfAbsent(
        id,
        () => <({int ms, int bytes})>[],
      );
      // Speed samples track RAW bytes so throughput stays truthful while the
      // display is floored.
      window.add((ms: now, bytes: (raw * task.fileSize).round()));
      window.removeWhere((sample) => now - sample.ms > _speedWindowMs);
      if (window.length >= 2 &&
          now - (_lastSpeedComputedAt[id] ?? 0) >= _speedSampleIntervalMs) {
        final first = window.first;
        final last = window.last;
        final dtMs = last.ms - first.ms;
        if (dtMs >= _speedSampleIntervalMs) {
          final deltaBytes = (last.bytes - first.bytes).clamp(0, 1 << 40);
          speedBps = (deltaBytes * 1000 / dtMs).round();
          _lastSpeedComputedAt[id] = now;
        }
      }
    }
    _setTask(task.copyWith(progress: normalized, speedBps: speedBps));
    final bucket = (normalized * 10).floor();
    if (_persistedProgressBuckets[id] != bucket) {
      _persistedProgressBuckets[id] = bucket;
      unawaited(_persist());
    }
  }

  // ---------------------------------------------------------------------
  // Merge polling (Phase B): asynchronous complete status per task.
  // ---------------------------------------------------------------------

  void _startFinalizePolling(UploadTask task) {
    _pollingSuspended.remove(task.id);
    _pollStartedAt[task.id] = DateTime.now();
    _completeResendCounts.remove(task.id);
    _schedulePoll(task.id, immediate: true);
  }

  void _schedulePoll(String id, {bool immediate = false}) {
    _pollTimers[id]?.cancel();
    _pollTimers[id] = Timer(immediate ? Duration.zero : pollInterval, () {
      unawaited(_pollFinalize(id));
    });
  }

  void _stopFinalizePolling(String id) {
    _pollTimers.remove(id)?.cancel();
    _pollStartedAt.remove(id);
    _completeResendCounts.remove(id);
    _pollingSuspended.remove(id);
  }

  void _suspendFinalizePollingTask(String id) {
    if (_pollTimers.remove(id) != null) {
      _pollingSuspended.add(id);
    }
    _pollTimers.remove(id)?.cancel();
  }

  void _resumeFinalizePollingTask(String id) {
    if (!_pollingSuspended.remove(id)) return;
    final task = state[id];
    if (task == null ||
        task.status != UploadTaskStatus.merging ||
        task.ownerUserId != _currentUserId) {
      return;
    }
    _pollStartedAt[id] = DateTime.now();
    _schedulePoll(id, immediate: true);
  }

  /// Suspends every active merge poll (backgrounding / account switch).
  void _suspendFinalizePolling() {
    for (final id in _pollTimers.keys.toList(growable: false)) {
      _pollingSuspended.add(id);
      _pollTimers.remove(id)?.cancel();
    }
  }

  /// Restores polls suspended by [ _suspendFinalizePolling] (foregrounding).
  void _resumeFinalizePolling() {
    for (final id in _pollingSuspended.toList(growable: false)) {
      _resumeFinalizePollingTask(id);
    }
  }

  Future<void> _pollFinalize(String id) async {
    if (!ref.mounted) return;
    if (!_connectivity.value) {
      _schedulePoll(id);
      return;
    }
    final task = state[id];
    if (task == null ||
        task.status != UploadTaskStatus.merging ||
        task.ownerUserId != _currentUserId) {
      _stopFinalizePolling(id);
      return;
    }
    final uploadId = task.multipartUploadId;
    final objectKey = task.multipartObjectKey;
    if (uploadId == null || objectKey == null) {
      _stopFinalizePolling(id);
      _failMerging(
        id,
        task,
        ApiError.parse('Merging task lost its multipart checkpoint'),
      );
      return;
    }
    final result = await _uploadRepository.pollCompleteStatus(
      uploadSessionId: task.uploadSessionId,
      objectKey: objectKey,
      uploadId: uploadId,
    );
    if (!ref.mounted) return;
    final current = state[id];
    if (current == null || current.status != UploadTaskStatus.merging) {
      _stopFinalizePolling(id);
      return;
    }

    if (result case Failure(:final error)) {
      // Unmapped transport/business failures: keep polling within the
      // overall timeout budget.
      StoryLogger.w(
        'pollCompleteStatus failed: ${error.userMessage}',
        tag: 'UploadCoordinator',
      );
      _continuePollingOrFail(id, current);
      return;
    }

    final status = result.dataOrNull!;
    switch (status.outcome) {
      case MultipartFinalizeOutcome.ready:
        _stopFinalizePolling(id);
        _setTask(
          current.copyWith(
            status: UploadTaskStatus.success,
            progress: 1,
            objectKey: status.objectKey ?? objectKey,
            publicUrl: current.publicUrl,
            clearError: true,
            resetMultipartState: true,
            networkWait: false,
          ),
        );
        await _persist();
        return;
      case MultipartFinalizeOutcome.processing:
      case MultipartFinalizeOutcome.transientError:
        _continuePollingOrFail(id, current);
        return;
      case MultipartFinalizeOutcome.failedSystem:
        final resends = (_completeResendCounts[id] ?? 0) + 1;
        _completeResendCounts[id] = resends;
        if (resends > 1) {
          _failMerging(
            id,
            current,
            ApiError.business(
              MultipartUploadErrorCodes.systemError,
              'Multipart merge failed',
            ),
          );
          return;
        }
        // Parts are still on object storage; complete is idempotent.
        final resend = await _uploadRepository.submitComplete(
          uploadSessionId: current.uploadSessionId,
          objectKey: objectKey,
          uploadId: uploadId,
          parts: current.completedParts,
        );
        if (resend case Failure(:final error)) {
          _failMerging(id, current, error);
          return;
        }
        _continuePollingOrFail(id, current);
        return;
      case MultipartFinalizeOutcome.uploadInvalid:
        _stopFinalizePolling(id);
        _setTask(
          current.copyWith(
            status: UploadTaskStatus.queued,
            progress: 0,
            resetMultipartState: true,
            clearError: true,
          ),
        );
        await _persist();
        _schedulePump();
        return;
      case MultipartFinalizeOutcome.failed:
        _failMerging(
          id,
          current,
          ApiError.business(status.errorCode ?? 0, 'Multipart merge failed'),
        );
        return;
    }
  }

  void _continuePollingOrFail(String id, UploadTask task) {
    final startedAt = _pollStartedAt[id];
    if (startedAt != null &&
        DateTime.now().difference(startedAt) >= pollTimeout) {
      _failMerging(id, task, ApiError.timeout('Multipart merge timed out'));
      return;
    }
    _schedulePoll(id);
  }

  Future<void> _failMerging(String id, UploadTask task, ApiError error) async {
    _stopFinalizePolling(id);
    _setTask(
      task.copyWith(
        status: UploadTaskStatus.failed,
        // All parts are uploaded; keep the display progress at 100%.
        progress: 1,
        speedBps: 0,
        lastError: UploadFailure.fromApiError(error).encoded,
      ),
    );
    await _persist();
  }

  /// Best-effort abort of an unfinished multipart upload (task removal or
  /// session rebind). Completed/successful objects are never aborted.
  void _abortMultipartQuietly(UploadTask task) {
    final uploadId = task.multipartUploadId;
    final objectKey = task.multipartObjectKey;
    if (uploadId == null || objectKey == null) return;
    if (task.status == UploadTaskStatus.success) return;
    unawaited(
      _uploadRepository
          .abortMultipart(
            uploadSessionId: task.uploadSessionId,
            objectKey: objectKey,
            uploadId: uploadId,
          )
          .then((result) {
            if (result case Failure(:final error)) {
              StoryLogger.w(
                'abortMultipart failed: ${error.userMessage}',
                tag: 'UploadCoordinator',
                error: error,
              );
            }
          }),
    );
  }

  void _touchState() {
    if (ref.mounted) state = Map<String, UploadTask>.of(state);
  }

  bool _isRetryable(ApiError error) =>
      error is NetworkError ||
      error is TimeoutError ||
      error is RateLimitError ||
      error is UnknownError;

  bool _isSessionExpired(UploadTask task) {
    final expiresAt = task.uploadSessionExpiresAt;
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch >=
        expiresAt - _sessionExpirySkew.inMilliseconds;
  }

  void _setTask(UploadTask task) {
    state = {...state, task.id: task};
  }

  Future<void> _persist() {
    final snapshot = [for (final task in state.values) task.toMap()];
    return _persistTail = _persistTail.then((_) async {
      try {
        await _box.put(_storeKey, snapshot);
      } catch (error, stackTrace) {
        StoryLogger.w(
          'Failed to persist upload queue',
          tag: 'UploadCoordinator',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<void> _deleteManagedFile(String path) async {
    final taskDirectory = await _resolveManagedTaskDirectory(path);
    if (taskDirectory == null) return;
    try {
      if (await taskDirectory.exists()) {
        await taskDirectory.delete(recursive: true);
      }
    } catch (error, stackTrace) {
      // Concurrent cancel/reset paths may already have removed the task folder.
      if (!await taskDirectory.exists()) return;
      StoryLogger.w(
        'Failed to delete managed upload file: $path',
        tag: 'UploadCoordinator',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Directory?> _resolveManagedTaskDirectory(String path) async {
    try {
      final support = await getApplicationSupportDirectory();
      final managedRoot = Directory('${support.path}/managed_uploads');
      final taskDirectory = File(path).parent;
      if (!await managedRoot.exists() || !await taskDirectory.exists()) {
        return null;
      }
      final rootPath = await managedRoot.resolveSymbolicLinks();
      final taskPath = await taskDirectory.resolveSymbolicLinks();
      final canonicalRoot = Directory(rootPath);
      final canonicalTask = Directory(taskPath);
      return canonicalTask.parent.path == canonicalRoot.path
          ? canonicalTask
          : null;
    } on FileSystemException {
      return null;
    }
  }
}
