import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';

enum StoryStateType { loading, error, empty }

class StoryStateWidget extends StatelessWidget {
  final StoryStateType type;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? action;
  final bool compact;
  final double? iconSize;
  final bool showIcon;

  const StoryStateWidget({
    super.key,
    required this.type,
    this.message,
    this.actionLabel,
    this.onAction,
    this.action,
    this.compact = false,
    this.iconSize,
    this.showIcon = true,
  });

  const StoryStateWidget.loading({
    super.key,
    this.message,
    this.compact = false,
    this.iconSize,
    this.showIcon = true,
  }) : type = StoryStateType.loading,
       actionLabel = null,
       onAction = null,
       action = null;

  const StoryStateWidget.error({
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
    this.action,
    this.compact = false,
    this.iconSize,
    this.showIcon = true,
  }) : type = StoryStateType.error;

  const StoryStateWidget.empty({
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
    this.action,
    this.compact = false,
    this.iconSize,
    this.showIcon = true,
  }) : type = StoryStateType.empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: compact
            ? EdgeInsets.zero
            : const EdgeInsets.all(StorySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) _buildIcon(theme),
            if (message != null) ...[
              if (showIcon)
                SizedBox(height: compact ? StorySpacing.xs : StorySpacing.md),
              Text(
                message!,
                style: StoryTextStyles.bodyMedium(
                  color: StoryColors.mutedForegroundOf(theme.brightness),
                ).copyWith(fontSize: compact ? 12 : 16),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? StorySpacing.xs : StorySpacing.lg),
              action!,
            ] else if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? StorySpacing.xs : StorySpacing.lg),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(color: theme.colorScheme.outline),
                  shape: const RoundedRectangleBorder(
                    borderRadius: StoryRadius.brSm,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: StorySpacing.base,
                    vertical: StorySpacing.sm,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    final resolvedIconSize =
        iconSize ??
        switch (type) {
          StoryStateType.loading => 32.0,
          StoryStateType.error => compact ? 32.0 : 48.0,
          StoryStateType.empty => compact ? 88.0 : 88.0,
        };
    final isDark = theme.brightness == Brightness.dark;
    return switch (type) {
      StoryStateType.loading => SizedBox(
        width: resolvedIconSize,
        height: resolvedIconSize,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(StoryColors.brandTeal),
        ),
      ),
      StoryStateType.error => Icon(
        Icons.error_outline,
        size: resolvedIconSize,
        color: StoryColors.destructive,
      ),
      StoryStateType.empty => SvgPicture.asset(
        isDark ? 'assets/common/empty_d.svg' : 'assets/common/empty.svg',
        width: resolvedIconSize,
        height: resolvedIconSize,
      ),
    };
  }
}
