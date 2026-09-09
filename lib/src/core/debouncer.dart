import 'dart:async';

import 'request_coalescer.dart';

/// Leading-edge cancel / trailing-edge fire debounce for input-like triggers.
///
/// Use for search boxes, draft autosave, batch flush schedulers — not for
/// idempotent GET coalescing ([RequestCoalescer]) or tab resume
/// ([RequestThrottle]).
///
/// See `docs/api_request_policy.md`.
abstract class Debouncer {
  void call(String key, void Function() action, {Duration? delay});

  void cancel(String key);

  void cancelAll();

  /// Run a pending action immediately (if any) and clear its timer.
  Future<void> flush(String key);
}

class TimerDebouncer implements Debouncer {
  TimerDebouncer({
    this.defaultDelay = const Duration(milliseconds: 300),
    this.observer,
  });

  final Duration defaultDelay;
  final RequestPolicyObserver? observer;
  final Map<String, Timer> _timers = <String, Timer>{};
  final Map<String, void Function()> _pending = <String, void Function()>{};

  @override
  void call(String key, void Function() action, {Duration? delay}) {
    _timers[key]?.cancel();
    _pending[key] = action;
    _timers[key] = Timer(delay ?? defaultDelay, () {
      _timers.remove(key);
      final pending = _pending.remove(key);
      if (pending == null) return;
      observer?.onDebounceFire(key);
      pending();
    });
  }

  @override
  void cancel(String key) {
    _timers.remove(key)?.cancel();
    _pending.remove(key);
  }

  @override
  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _pending.clear();
  }

  @override
  Future<void> flush(String key) async {
    _timers.remove(key)?.cancel();
    final pending = _pending.remove(key);
    if (pending == null) return;
    observer?.onDebounceFire(key);
    pending();
  }
}
