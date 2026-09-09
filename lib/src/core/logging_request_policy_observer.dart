import 'package:flutter/foundation.dart';

import 'request_coalescer.dart';
import 'story_logger.dart';

/// Debug/profile logging for coalesce / throttle / debounce hooks.
///
/// No-op in release ([debugRequestPolicyObserver] returns null). Does not
/// change request behavior — observation only.
class LoggingRequestPolicyObserver implements RequestPolicyObserver {
  const LoggingRequestPolicyObserver();

  static const _tag = 'RequestPolicy';

  @override
  void onCoalesceHit(String key) {
    StoryLogger.d('coalesce hit key=$key', tag: _tag);
  }

  @override
  void onCoalesceStart(String key) {
    StoryLogger.d('coalesce start key=$key', tag: _tag);
  }

  @override
  void onThrottleReject(String key) {
    StoryLogger.d('throttle reject key=$key', tag: _tag);
  }

  @override
  void onThrottleClaim(String key) {
    StoryLogger.d('throttle claim key=$key', tag: _tag);
  }

  @override
  void onDebounceFire(String key) {
    StoryLogger.d('debounce fire key=$key', tag: _tag);
  }
}

/// Shared debug observer for [requestCoalescerProvider] and local throttle /
/// debouncer instances. Null in release builds.
RequestPolicyObserver? get debugRequestPolicyObserver =>
    kReleaseMode ? null : const LoggingRequestPolicyObserver();
