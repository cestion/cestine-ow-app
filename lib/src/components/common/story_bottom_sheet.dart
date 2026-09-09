import 'package:flutter/material.dart';

import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';

/// 统一 Modal BottomSheet 配置，消除散落的 backgroundColor/barrierColor/shape 重复。
class StoryBottomSheet {
  StoryBottomSheet._();

  /// 选集弹窗（主题适配背景 + 顶部圆角，可上拉展开）。
  static Future<T?> showEpisodePicker<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    final brightness = Theme.of(context).brightness;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StoryColors.cardOf(brightness),
      barrierColor: StoryColors.overlayMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: builder,
    );
  }

  /// 评论弹窗（透明背景 + 可滚动；宿主全屏透明层供点外部关闭，
  /// 播放器在 sheet 打开时自行缩到上半区）。
  static Future<T?> showCommentSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: builder,
    );
  }

  /// 统一的带标题、内容、操作按钮的底部弹窗。
  static Future<T?> showStyledSheet<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? content,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isLoading = false,
    Color? confirmColor,
    bool showCloseButton = true,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: StoryColors.overlayMedium,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final brightness = theme.brightness;
        return Container(
          decoration: BoxDecoration(
            color: StoryColors.backgroundOf(brightness),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: StorySpacing.xl,
            right: StorySpacing.xl,
            top: StorySpacing.xl,
            bottom: MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: StorySpacing.md),
                  decoration: BoxDecoration(
                    color: StoryColors.dividerOf(brightness),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: StoryTextStyles.titleMedium(
                        color: StoryColors.foregroundOf(brightness),
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (showCloseButton)
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: brightness == Brightness.dark
                                ? StoryColors.darkMuted
                                : StoryColors.lightMuted,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: StoryColors.foregroundOf(brightness),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: StoryTextStyles.bodySmall(
                    color: StoryColors.mutedForegroundOf(brightness),
                  ),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: StorySpacing.lg),
                content,
              ],
              const SizedBox(height: StorySpacing.xl),
              Row(
                children: [
                  if (cancelLabel != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : (onCancel ?? () => Navigator.of(ctx).pop()),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(
                            color: StoryColors.borderOf(brightness),
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          cancelLabel,
                          style: StoryTextStyles.bodyMedium(
                            color: StoryColors.foregroundOf(brightness),
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (cancelLabel != null && confirmLabel != null)
                    const SizedBox(width: StorySpacing.md),
                  if (confirmLabel != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onConfirm,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor:
                              confirmColor ??
                              StoryColors.foregroundOf(brightness),
                          foregroundColor: confirmColor != null
                              ? StoryColors.onOverlay
                              : StoryColors.backgroundOf(brightness),
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: confirmColor != null
                                      ? StoryColors.onOverlay
                                      : StoryColors.backgroundOf(brightness),
                                ),
                              )
                            : Text(
                                confirmLabel,
                                style: StoryTextStyles.bodyMedium().copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: confirmColor != null
                                      ? StoryColors.onOverlay
                                      : StoryColors.backgroundOf(brightness),
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
