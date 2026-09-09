import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/models.dart';
import '../repositories/file_upload_repository.dart';
import 'upload_coordinator.dart';

enum UploadSessionFailureReason {
  none,
  ownerChanged,
  expiredWithResources,
  requestFailed,
  unavailable,
}

/// Reusable session state for one publish flow.
///
/// Instances are intentionally not global: a drama and a standalone video may
/// upload concurrently while sharing the same global [UploadCoordinator].
class UploadSessionManager {
  UploadSessionManager({
    required this.uploader,
    required this.coordinator,
    required this.readOwnerUserId,
    required this.onSessionChanged,
  });

  final FileUploadRepository uploader;
  final UploadCoordinator coordinator;
  final String? Function() readOwnerUserId;
  final void Function(String sessionId, int? expiresAt) onSessionChanged;

  String? _sessionId;
  int? _expiresAt;
  String? _ownerUserId;
  bool _hasExternalResources = false;
  int _generation = 0;
  bool _disposed = false;
  Future<String?>? _creationFuture;

  UploadSessionFailureReason lastFailure = UploadSessionFailureReason.none;
  ApiError? lastError;

  String? get sessionId => _sessionId;
  int? get expiresAt => _expiresAt;

  void restore({
    required String? sessionId,
    required int? expiresAt,
    required bool hasExternalResources,
  }) {
    _generation++;
    _creationFuture = null;
    _sessionId = sessionId;
    _expiresAt = expiresAt;
    _ownerUserId = readOwnerUserId();
    _hasExternalResources = hasExternalResources;
    _clearFailure();
  }

  void reset() {
    _generation++;
    _creationFuture = null;
    _sessionId = null;
    _expiresAt = null;
    _ownerUserId = readOwnerUserId();
    _hasExternalResources = false;
    _clearFailure();
  }

  void handleOwnerChanged() {
    _generation++;
    _creationFuture = null;
    _sessionId = null;
    _expiresAt = null;
    _ownerUserId = readOwnerUserId();
    _hasExternalResources = false;
    _clearFailure();
  }

  void markResourceUploaded(String sessionId) {
    if (_sessionId == sessionId) _hasExternalResources = true;
  }

  Future<String?> ensure() async {
    if (_disposed) return null;
    _clearFailure();
    final ownerUserId = readOwnerUserId();
    if (ownerUserId == null) {
      lastFailure = UploadSessionFailureReason.ownerChanged;
      return null;
    }

    final currentSessionId = _sessionId;
    if (currentSessionId != null && _ownerUserId != ownerUserId) {
      lastFailure = UploadSessionFailureReason.ownerChanged;
      StoryLogger.w(
        'Upload session owner changed; refusing reuse',
        tag: 'UploadSession',
      );
      return null;
    }
    final expired = currentSessionId != null && _isExpired(_expiresAt);
    if (currentSessionId != null && !expired) return currentSessionId;
    if (expired && _hasCommittedResources(currentSessionId)) {
      lastFailure = UploadSessionFailureReason.expiredWithResources;
      return null;
    }

    final pending = _creationFuture;
    if (pending != null) return pending;
    final generation = _generation;
    final future = _createAndInstall(
      generation: generation,
      ownerUserId: ownerUserId,
      expiredSessionId: expired ? currentSessionId : null,
    );
    _creationFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_creationFuture, future)) _creationFuture = null;
    }
  }

  /// Restores durable tasks with a valid session and activates that session.
  ///
  /// Both publish flows use this path so missing and expired sessions behave
  /// consistently after a draft or process restore.
  Future<bool> restoreTasks(
    Iterable<UploadTask> Function(String sessionId, int? expiresAt) buildTasks,
  ) async {
    await coordinator.ready;
    final activeSessionId = await ensure();
    if (activeSessionId == null || _disposed) return false;
    final tasks = buildTasks(
      activeSessionId,
      _expiresAt,
    ).toList(growable: false);
    return coordinator.restoreTasks(
      tasks,
      sessionId: activeSessionId,
      sessionExpiresAt: _expiresAt,
    );
  }

  Future<String?> _createAndInstall({
    required int generation,
    required String ownerUserId,
    required String? expiredSessionId,
  }) async {
    final result = await uploader.createUploadSession();
    if (_disposed ||
        generation != _generation ||
        readOwnerUserId() != ownerUserId) {
      return null;
    }
    if (result case Failure(:final error)) {
      lastFailure = UploadSessionFailureReason.requestFailed;
      lastError = error;
      return null;
    }
    final session = result.dataOrNull!;
    final newSessionId = session.uploadSessionId;
    if (newSessionId == null || newSessionId.isEmpty) {
      lastFailure = UploadSessionFailureReason.unavailable;
      return null;
    }
    final newExpiresAt = _expiresAtFor(session);

    if (expiredSessionId != null) {
      if (_sessionId != expiredSessionId ||
          _hasCommittedResources(expiredSessionId)) {
        lastFailure = UploadSessionFailureReason.expiredWithResources;
        return null;
      }
      final replaced = await coordinator.replaceSession(
        oldSessionId: expiredSessionId,
        newSessionId: newSessionId,
        newSessionExpiresAt: newExpiresAt,
      );
      if (!replaced ||
          _disposed ||
          generation != _generation ||
          readOwnerUserId() != ownerUserId) {
        return null;
      }
    } else if (_sessionId != null) {
      return _sessionId;
    }

    _sessionId = newSessionId;
    _expiresAt = newExpiresAt;
    _ownerUserId = ownerUserId;
    _hasExternalResources = false;
    onSessionChanged(newSessionId, newExpiresAt);
    return newSessionId;
  }

  bool _hasCommittedResources(String sessionId) =>
      _hasExternalResources ||
      coordinator
          .tasksForSession(sessionId)
          .any((task) => task.status == UploadTaskStatus.success);

  static int? _expiresAtFor(UploadSession session) {
    final seconds = session.expireSeconds;
    if (seconds == null || seconds <= 0) return null;
    return DateTime.now().millisecondsSinceEpoch + seconds * 1000;
  }

  static bool _isExpired(int? expiresAt) =>
      expiresAt != null &&
      DateTime.now().millisecondsSinceEpoch >= expiresAt - 30000;

  void _clearFailure() {
    lastFailure = UploadSessionFailureReason.none;
    lastError = null;
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _creationFuture = null;
  }
}
