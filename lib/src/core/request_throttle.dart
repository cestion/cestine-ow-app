import 'request_coalescer.dart';

/// Time-window gate: at most one successful [tryClaim] per [key] per window.
///
/// Prefer for UI / lifecycle triggers (tab re-entry, App resume). Not a
/// substitute for [RequestCoalescer] — use both when concurrent + rapid
/// re-entry can stack.
///
/// **State sync:** a rejected claim is not a successful refresh. Callers must
/// not clear UI state on reject. User-initiated refresh should [reset] first.
///
/// See `docs/api_request_policy.md`.
abstract class RequestThrottle {
  /// Records a claim timestamp when returning `true`.
  bool tryClaim(String key, {Duration? window});

  /// Force-update the last-claim time (e.g. after a bypass path succeeds).
  void mark(String key);

  /// Allow the next [tryClaim] to succeed immediately.
  void reset(String key);

  void resetAll();
}

/// What to do when [RequestThrottle.tryClaim] returns false.
enum ThrottleMiss {
  /// Do nothing (caller already has usable UI state).
  skip,

  /// Prefer joining an in-flight coalesce of the same key when available.
  joinInflight,
}

class MemoryRequestThrottle implements RequestThrottle {
  MemoryRequestThrottle({
    this.defaultWindow = const Duration(seconds: 15),
    DateTime Function()? clock,
    this.observer,
  }) : _clock = clock ?? DateTime.now;

  final Duration defaultWindow;
  final DateTime Function() _clock;
  final RequestPolicyObserver? observer;
  final Map<String, DateTime> _lastClaimedAt = <String, DateTime>{};

  @override
  bool tryClaim(String key, {Duration? window}) {
    final now = _clock();
    final last = _lastClaimedAt[key];
    final effective = window ?? defaultWindow;
    if (last != null && now.difference(last) < effective) {
      observer?.onThrottleReject(key);
      return false;
    }
    _lastClaimedAt[key] = now;
    observer?.onThrottleClaim(key);
    return true;
  }

  @override
  void mark(String key) {
    _lastClaimedAt[key] = _clock();
  }

  @override
  void reset(String key) {
    _lastClaimedAt.remove(key);
  }

  @override
  void resetAll() => _lastClaimedAt.clear();
}
