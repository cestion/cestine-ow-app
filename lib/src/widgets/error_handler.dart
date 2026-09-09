import 'package:flutter/material.dart';

import '../components/common/story_toast.dart';
import '../core/result.dart';
import '../core/story_logger.dart';
import '../foundation/telemetry.dart';
import '../l10n/story_l10n.dart';

/// Displays an [ApiError] to the user: logs to telemetry, logs locally,
/// and shows a localized toast when [showToUser] is true and [ctx] is provided.
///
/// 当 [rootOverlay] 为 `true` 时，toast 渲染在 root overlay 最顶层，
/// 不被 modal bottom sheet / dialog 等遮罩层遮挡。适用于在弹窗内
/// 显示错误提示且不希望关闭弹窗的场景。
void handleApiError(
  ApiError error, {
  bool showToUser = true,
  BuildContext? ctx,
  bool rootOverlay = false,
}) {
  StoryLogger.e(error.toString(), error: error, tag: 'ApiError');
  StoryTelemetryRegistry.instance.error(error);
  if (showToUser && ctx != null) {
    final message = ctx.l10nError(error);
    StoryToast.error(ctx, message, rootOverlay: rootOverlay);
  }
}

/// Convenience method that calls [handleApiError] when the [Result] is a failure.
void handleResult<T>(Result<T> r, {BuildContext? ctx}) {
  if (r case Failure(:final error)) handleApiError(error, ctx: ctx);
}

/// Top-level helper for displaying [ApiError] consistently.
/// Uses [BuildContext.l10nError] to localize, with [ApiError.userMessage]
/// as fallback.
void showApiError(BuildContext context, ApiError error) {
  final message = context.l10nError(error);
  StoryToast.error(context, message);
}
