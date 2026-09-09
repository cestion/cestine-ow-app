import 'dart:async';

import '../core/debouncer.dart';
import '../core/logging_request_policy_observer.dart';
import '../core/request_keys.dart';

/// 串行协调本地草稿的防抖、定时保存与删除。
///
/// [discard] 会先让所有尚未开始的保存失效，再等待已开始的写入结束并执行删除，
/// 因此点击“不保存”后不会被旧的异步保存任务重新写回。
class DraftAutosaveCoordinator<T> {
  DraftAutosaveCoordinator({
    required this.save,
    required this.onError,
    this.debounceDuration = const Duration(seconds: 2),
    this.checkpointInterval = const Duration(seconds: 30),
  }) : _debouncer = TimerDebouncer(
         defaultDelay: debounceDuration,
         observer: debugRequestPolicyObserver,
       ) {
    _checkpointTimer = Timer.periodic(checkpointInterval, (_) {
      if (_dirty) unawaited(flush());
    });
  }

  final Future<void> Function(T snapshot) save;
  final void Function(Object error, StackTrace stackTrace) onError;
  final Duration debounceDuration;
  final Duration checkpointInterval;

  final Debouncer _debouncer;
  Timer? _checkpointTimer;
  Future<void> _serial = Future<void>.value();
  Future<bool> _lastOperation = Future<bool>.value(true);
  T? _pendingSnapshot;
  bool _dirty = false;
  bool _closed = false;
  bool _discarded = false;
  int _generation = 0;

  bool get isDirty => _dirty;

  void markDirty(T snapshot, {bool immediate = false}) {
    if (_closed || _discarded) return;
    _pendingSnapshot = snapshot;
    _dirty = true;
    _debouncer.cancel(RequestKeys.draftAutosave);
    if (immediate) {
      unawaited(flush());
      return;
    }
    _debouncer(
      RequestKeys.draftAutosave,
      () => unawaited(flush()),
      delay: debounceDuration,
    );
  }

  /// 保存当前最新快照。返回 false 表示本次本地写入失败。
  Future<bool> flush() {
    _debouncer.cancel(RequestKeys.draftAutosave);
    if (_discarded) return Future<bool>.value(true);
    if (!_dirty || _pendingSnapshot == null) return _lastOperation;

    final snapshot = _pendingSnapshot as T;
    final generation = _generation;
    _pendingSnapshot = null;
    _dirty = false;

    final operation = _serial.then((_) async {
      if (_discarded || generation != _generation) return true;
      try {
        await save(snapshot);
        return true;
      } catch (error, stackTrace) {
        if (!_discarded && generation == _generation) {
          // 新快照优先；没有更新内容时才把失败快照放回重试队列。
          _pendingSnapshot ??= snapshot;
          _dirty = true;
        }
        onError(error, stackTrace);
        return false;
      }
    });
    _lastOperation = operation;
    _serial = operation.then<void>((_) {});
    return operation;
  }

  /// 失效所有保存，并在在途写入之后执行删除。
  Future<bool> discard(Future<void> Function() delete) {
    if (!_discarded) {
      _discarded = true;
      _generation++;
      _dirty = false;
      _pendingSnapshot = null;
      _debouncer.cancel(RequestKeys.draftAutosave);
    }

    final operation = _serial.then((_) async {
      try {
        await delete();
        return true;
      } catch (error, stackTrace) {
        onError(error, stackTrace);
        return false;
      }
    });
    _lastOperation = operation;
    _serial = operation.then<void>((_) {});
    return operation;
  }

  /// 删除失败后允许页面继续选择“存草稿”或重试“不保存”。
  void resumeAfterDiscardFailure() {
    if (_closed || !_discarded) return;
    _discarded = false;
    _generation++;
  }

  /// Controller 销毁前把最后一个脏快照排入串行队列。
  void dispose() {
    if (_closed) return;
    _debouncer.cancelAll();
    _checkpointTimer?.cancel();
    _checkpointTimer = null;
    if (!_discarded && _dirty && _pendingSnapshot != null) {
      unawaited(flush());
    }
    _closed = true;
  }
}
