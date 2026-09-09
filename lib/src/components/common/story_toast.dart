import 'dart:async';

import 'package:flutter/material.dart';

import '../../styles/story_colors.dart';
import '../../styles/story_text_styles.dart';
import '../../foundation/navigator.dart';

enum StoryToastType { info, success, warning, error }

class StoryToast {
  StoryToast._();

  /// 当前 root overlay toast 的 entry，确保同一时间只显示一个。
  static OverlayEntry? _rootOverlayEntry;

  /// 当前 toast 的自动关闭定时器；替换 toast 时必须取消，
  /// 否则旧定时器触发会提前移除新 toast。
  static Timer? _dismissTimer;

  /// Show a custom designed toast using SnackBar matching the Figma specification.
  ///
  /// 当 [rootOverlay] 为 `true` 时，toast 渲染在 root overlay 最顶层，
  /// 不被 modal bottom sheet / dialog 等遮罩层遮挡。适用于在弹窗内
  /// 显示错误提示且不希望关闭弹窗的场景。
  static void show(
    BuildContext context, {
    required String message,
    StoryToastType type = StoryToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    bool rootOverlay = false,
  }) {
    _showRootOverlay(
      context: context,
      message: message,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Insert toast directly into [overlay] (e.g. [NavigatorState.overlay]).
  ///
  /// Use this when [BuildContext] sits on the Navigator itself and
  /// [Overlay.of] would fail (no Overlay ancestor).
  static void showOnOverlay(
    OverlayState overlay, {
    required String message,
    StoryToastType type = StoryToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showRootOverlay(
      overlay: overlay,
      message: message,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static OverlayState? _resolveOverlay(BuildContext? context) {
    if (context != null) {
      final fromContext = Overlay.maybeOf(context, rootOverlay: true);
      if (fromContext != null) return fromContext;
    }
    return StoryNavigator.instance.navigatorKey.currentState?.overlay;
  }

  /// 在 root overlay 上渲染 toast，位于所有 modal / bottom sheet 之上。
  static void _showRootOverlay({
    BuildContext? context,
    OverlayState? overlay,
    required String message,
    required StoryToastType type,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Dismiss keyboard so the toast is not obscured / competing with IME.
    FocusManager.instance.primaryFocus?.unfocus();

    _dismissTimer?.cancel();
    _rootOverlayEntry?.remove();
    _rootOverlayEntry = null;

    final target = overlay ?? _resolveOverlay(context);
    if (target == null) return;

    final themeContext = context ?? target.context;
    final theme = Theme.of(themeContext);
    final isDark = theme.brightness == Brightness.dark;

    final bg = _backgroundColor(type, isDark);
    final fg = _foregroundColor(type, isDark);
    final iconData = _icon(type);
    final iconCol = _iconColor(type, isDark);

    Widget? actionWidget;
    if (actionLabel != null) {
      final isSuccessAction = type == StoryToastType.success;
      actionWidget = Padding(
        padding: EdgeInsets.only(left: isSuccessAction ? 4 : 12),
        child: TextButton(
          onPressed: () {
            _removeRootOverlay();
            onAction?.call();
          },
          style: TextButton.styleFrom(
            backgroundColor: _actionBgColor(type, isDark),
            foregroundColor: _actionTextColor(type, isDark),
            padding: EdgeInsets.symmetric(
              horizontal: isSuccessAction ? 8 : 12,
              vertical: isSuccessAction ? 4 : 6,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSuccessAction ? 4 : 6),
            ),
          ),
          child: Text(
            actionLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSuccessAction ? FontWeight.w500 : FontWeight.bold,
              height: isSuccessAction ? 16 / 12 : null,
              letterSpacing: isSuccessAction ? 0.04 : null,
            ),
          ),
        ),
      );
    }

    final toastContent = _buildToastContent(
      message: message,
      type: type,
      isDark: isDark,
      bg: bg,
      fg: fg,
      iconData: iconData,
      iconCol: iconCol,
      actionLabel: actionLabel,
      actionWidget: actionWidget,
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        final viewInsets = MediaQuery.of(overlayContext).viewInsets;
        final padding = MediaQuery.of(overlayContext).padding;
        return Positioned(
          left: 16 + padding.left,
          right: 16 + padding.right,
          top: 24 + padding.top + viewInsets.top,
          child: Material(color: Colors.transparent, child: toastContent),
        );
      },
    );
    _rootOverlayEntry = entry;
    target.insert(entry);

    _dismissTimer = Timer(duration, _removeRootOverlay);
  }

  static void _removeRootOverlay() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _rootOverlayEntry?.remove();
    _rootOverlayEntry = null;
  }

  /// 构建 toast 内容 Widget（SnackBar 和 root overlay 共用）。
  static Widget _buildToastContent({
    required String message,
    required StoryToastType type,
    required bool isDark,
    required Color bg,
    required Color fg,
    required IconData iconData,
    required Color iconCol,
    String? actionLabel,
    Widget? actionWidget,
  }) {
    final isActionableSuccess =
        type == StoryToastType.success && actionLabel != null;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isActionableSuccess ? 8 : 16,
        vertical: isActionableSuccess ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: isDark
            ? null
            : Border.all(
                color: _borderColor(type),
                width: isActionableSuccess ? 0.5 : 1,
              ),
        boxShadow: [
          BoxShadow(
            color: isActionableSuccess
                ? StoryColors.success.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isActionableSuccess ? 8 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Icon(iconData, color: iconCol, size: 20),
          Expanded(
            child: Text(
              message,
              style: StoryTextStyles.bodyMedium(
                color: fg,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          ?actionWidget,
        ],
      ),
    );
  }

  static void info(
    BuildContext context,
    String message, {
    VoidCallback? onAction,
    String? actionLabel,
    bool rootOverlay = false,
  }) => show(
    context,
    message: message,
    onAction: onAction,
    actionLabel: actionLabel,
    rootOverlay: rootOverlay,
  );

  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool rootOverlay = false,
  }) => show(
    context,
    message: message,
    type: StoryToastType.success,
    actionLabel: actionLabel,
    onAction: onAction,
    rootOverlay: rootOverlay,
  );

  static void warning(
    BuildContext context,
    String message, {
    bool rootOverlay = false,
  }) => show(
    context,
    message: message,
    type: StoryToastType.warning,
    rootOverlay: rootOverlay,
  );

  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool rootOverlay = false,
    Duration duration = const Duration(seconds: 5),
  }) => show(
    context,
    message: message,
    type: StoryToastType.error,
    duration: actionLabel != null ? const Duration(seconds: 8) : duration,
    actionLabel: actionLabel,
    onAction: onAction,
    rootOverlay: rootOverlay,
  );

  static Color _backgroundColor(StoryToastType type, bool isDark) {
    if (isDark) {
      return switch (type) {
        StoryToastType.success => const Color(0xFF192A20),
        StoryToastType.error => const Color(0xFF2D1A1A),
        StoryToastType.warning => const Color(0xFF2D251A),
        StoryToastType.info => const Color(0xFF1E1E1E),
      };
    } else {
      return switch (type) {
        StoryToastType.success => const Color(0xFFE6F6EB),
        StoryToastType.error => const Color(0xFFFDF2F2),
        StoryToastType.warning => const Color(0xFFFEF9C3),
        StoryToastType.info => const Color(0xFFFFFFFF),
      };
    }
  }

  static Color _borderColor(StoryToastType type) {
    return switch (type) {
      StoryToastType.success => const Color(0xFFE6F6EB),
      StoryToastType.error => const Color(0xFFFDE8E8),
      StoryToastType.warning => const Color(0xFFFEF08A),
      StoryToastType.info => const Color(0xFFE5E7EB),
    };
  }

  static Color _foregroundColor(StoryToastType type, bool isDark) {
    if (isDark) {
      return const Color(0xFFE2E8F0);
    } else {
      return const Color(0xFF1F2937);
    }
  }

  static IconData _icon(StoryToastType type) {
    return switch (type) {
      StoryToastType.success => Icons.check_circle_rounded,
      StoryToastType.error => Icons.error_rounded,
      StoryToastType.warning => Icons.warning_rounded,
      StoryToastType.info => Icons.info_rounded,
    };
  }

  static Color _iconColor(StoryToastType type, bool isDark) {
    if (isDark) {
      return switch (type) {
        StoryToastType.success => const Color(0xFF4ADE80),
        StoryToastType.error => const Color(0xFFF87171),
        StoryToastType.warning => const Color(0xFFFBBF24),
        StoryToastType.info => const Color(0xFF9CA3AF),
      };
    } else {
      return switch (type) {
        StoryToastType.success => const Color(0xFF2FB36C),
        StoryToastType.error => const Color(0xFFF04438),
        StoryToastType.warning => const Color(0xFFF59E0B),
        StoryToastType.info => const Color(0xFF1F2937),
      };
    }
  }

  static Color _actionBgColor(StoryToastType type, bool isDark) {
    if (isDark) {
      return switch (type) {
        StoryToastType.success => const Color(0xFF2A3E31),
        StoryToastType.error => const Color(0xFF3E2A2A),
        StoryToastType.warning => const Color(0xFF3E352A),
        StoryToastType.info => StoryColors.darkFillSecondary,
      };
    } else {
      return switch (type) {
        StoryToastType.success => const Color(0x2900A838),
        StoryToastType.error => const Color(0xFFFEE4E2),
        StoryToastType.warning => const Color(0xFFFEF08A),
        StoryToastType.info => const Color(0xFFF3F4F6),
      };
    }
  }

  static Color _actionTextColor(StoryToastType type, bool isDark) {
    if (isDark) {
      return switch (type) {
        StoryToastType.success => const Color(0xFF4ADE80),
        StoryToastType.error => const Color(0xFFF87171),
        StoryToastType.warning => const Color(0xFFFBBF24),
        StoryToastType.info => const Color(0xFFE2E8F0),
      };
    } else {
      return switch (type) {
        StoryToastType.success => StoryColors.success,
        StoryToastType.error => const Color(0xFFD92D20),
        StoryToastType.warning => const Color(0xFFD97706),
        StoryToastType.info => const Color(0xFF4B5563),
      };
    }
  }
}
