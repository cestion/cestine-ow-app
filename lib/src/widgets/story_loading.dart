import 'package:flutter/material.dart';

import '../styles/story_colors.dart';

/// 统一的加载指示器组件
///
/// 替代散落在各页面的内联 CircularProgressIndicator，
/// 确保加载指示器样式一致。
class StoryLoading extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final bool centered;

  static const Object _defaultOperationKey = Object();
  static final Set<Object> _activeOperationKeys = <Object>{};
  static OverlayEntry? _globalOverlayEntry;

  const StoryLoading({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.color,
    this.centered = true,
  });

  /// 居中显示的加载指示器（最常用）
  const StoryLoading.centered({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.color,
  }) : centered = true;

  /// 内联加载指示器（不居中，用于行内）
  const StoryLoading.inline({
    super.key,
    this.size = 20,
    this.strokeWidth = 2,
    this.color,
  }) : centered = false;

  /// 大号加载指示器（用于全屏加载）
  const StoryLoading.large({
    super.key,
    this.size = 48,
    this.strokeWidth = 3,
    this.color,
  }) : centered = true;

  /// 显示全局微信样式 Loading。
  ///
  /// 返回 `false` 表示相同 [operationKey] 已经处于加载状态，调用方应停止
  /// 重复执行对应操作。不同 key 可共享同一个全局浮层。
  static bool show(BuildContext context, {Object? operationKey}) {
    final key = operationKey ?? _defaultOperationKey;
    if (!_activeOperationKeys.add(key)) return false;

    if (_globalOverlayEntry == null) {
      final entry = OverlayEntry(
        builder: (_) => const _StoryGlobalLoadingOverlay(),
      );
      _globalOverlayEntry = entry;
      Overlay.of(context, rootOverlay: true).insert(entry);
    }
    return true;
  }

  /// 关闭与 [operationKey] 对应的全局 Loading。
  ///
  /// 所有并发操作都结束后才会真正移除浮层。
  static bool dissmiss({Object? operationKey}) {
    final key = operationKey ?? _defaultOperationKey;
    final removed = _activeOperationKeys.remove(key);
    if (_activeOperationKeys.isEmpty) {
      _globalOverlayEntry?.remove();
      _globalOverlayEntry = null;
    }
    return removed;
  }

  /// [dissmiss] 的标准拼写别名。
  static bool dismiss({Object? operationKey}) =>
      dissmiss(operationKey: operationKey);

  /// 当前是否存在全局 Loading。
  static bool get isShowing => _globalOverlayEntry != null;

  /// 强制关闭全部全局 Loading，适用于页面或应用生命周期清理。
  static void dismissAll() {
    _activeOperationKeys.clear();
    _globalOverlayEntry?.remove();
    _globalOverlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? StoryColors.brandTeal,
        ),
      ),
    );

    if (!centered) return indicator;
    return Center(child: indicator);
  }
}

/// [StoryLoading.show] 使用的全局微信样式阻塞浮层。
class _StoryGlobalLoadingOverlay extends StatelessWidget {
  const _StoryGlobalLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      key: ValueKey('story-loading-overlay'),
      fit: StackFit.expand,
      children: [
        ModalBarrier(dismissible: false, color: Colors.transparent),
        Center(
          child: SizedBox.square(
            key: ValueKey('story-loading-overlay-panel'),
            dimension: 88,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xB8000000),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Center(
                child: StoryLoading.inline(
                  size: 32,
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
