import 'dart:async';

/// Concurrent request merger: identical [key]s share one in-flight [Future].
///
/// Use for idempotent reads (profile, stats, list page-1). Do **not** coalesce
/// non-idempotent writes unless the key includes an idempotency token.
///
/// See `docs/api_request_policy.md`.
abstract class RequestCoalescer {
  Future<T> run<T>(String key, Future<T> Function() action);

  void invalidate(String key);

  void invalidateAll();

  /// Whether [key] currently has an in-flight future (tests / diagnostics).
  bool isInflight(String key);
}

/// Optional hooks for debug logging / telemetry.
abstract class RequestPolicyObserver {
  void onCoalesceHit(String key) {}
  void onCoalesceStart(String key) {}
  void onThrottleReject(String key) {}
  void onThrottleClaim(String key) {}
  void onDebounceFire(String key) {}
}

/// In-memory coalescer suitable for repository / controller process lifetime.
class MemoryRequestCoalescer implements RequestCoalescer {
  MemoryRequestCoalescer({this.observer});

  final RequestPolicyObserver? observer;
  final Map<String, Future<dynamic>> _inflight = <String, Future<dynamic>>{};

  @override
  Future<T> run<T>(String key, Future<T> Function() action) {
    final existing = _inflight[key];
    if (existing != null) {
      observer?.onCoalesceHit(key);
      return existing as Future<T>;
    }

    observer?.onCoalesceStart(key);
    // Register before invoking [action] so a nested same-key [run] joins this
    // future (and must not be used — it deadlocks) instead of starting a second
    // request that races with the outer whenComplete cleanup.
    final completer = Completer<T>();
    final future = completer.future;
    _inflight[key] = future;
    () async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        if (identical(_inflight[key], future)) {
          _inflight.remove(key);
        }
      }
    }();
    return future;
  }

  @override
  void invalidate(String key) => _inflight.remove(key);

  @override
  void invalidateAll() => _inflight.clear();

  @override
  bool isInflight(String key) => _inflight.containsKey(key);
}

/// Prefixes every key with [scope] so logout / account switch can clear safely.
class ScopedRequestCoalescer implements RequestCoalescer {
  ScopedRequestCoalescer(this._inner, this.scope);

  final RequestCoalescer _inner;
  final String scope;

  String _scoped(String key) => '$scope::$key';

  @override
  Future<T> run<T>(String key, Future<T> Function() action) =>
      _inner.run(_scoped(key), action);

  @override
  void invalidate(String key) => _inner.invalidate(_scoped(key));

  @override
  void invalidateAll() {
    // Scoped clear is best-effort when wrapping a shared Memory coalescer;
    // prefer a dedicated MemoryRequestCoalescer per scope when possible.
    _inner.invalidateAll();
  }

  @override
  bool isInflight(String key) => _inner.isInflight(_scoped(key));
}
