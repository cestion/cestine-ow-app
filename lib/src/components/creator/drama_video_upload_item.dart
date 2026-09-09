import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../controller/video_upload_state.dart';
import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_format.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';

/// A single video item card used in the "Create Drama" episode upload list.
///
/// Layout (Figma `Story.fun-V2-ui` 392:107154 etc.):
/// header row (drag handle + episode index + status pill) / media row
/// (thumbnail + name + meta with speed & percent + progress bar) / action
/// button row / episode description field. Purely presentational — all data
/// and callbacks are injected by the caller.
class DramaVideoUploadItem extends StatelessWidget {
  /// 1-based episode index shown in the foreground color.
  final int index;

  /// Video file title, e.g. "星际迷航".
  final String title;

  /// Optional extension fallback when [title] does not contain one.
  ///
  /// Edit-session episode titles omit the original file extension, so the
  /// caller can derive it from the remote video URL and pass it here.
  final String? fileExtension;

  /// Meta text, e.g. "10.4 MB · 10:12".
  final String details;

  /// Upload progress in the range 0.0 – 1.0.
  final double progress;

  /// Current upload status driving the pill, meta row and action buttons.
  final VideoUploadStatus status;

  /// Offline flag: combined with [status] it renders the
  /// "waiting for network" pill and toggles the pause/resume button.
  final bool networkWait;

  /// Live upload speed in bytes/second; shown only while uploading.
  final int speedBps;

  /// Status pill label, e.g. "上传中"; hidden when empty.
  final String statusLabel;

  /// 单集简介，展示在卡片最底部。
  final String description;
  final String descriptionHint;
  final String? descriptionError;
  final ValueChanged<String>? onDescriptionChanged;

  /// 本地视频缩略图路径；为 null 时显示占位图标。
  final String? thumbnailPath;

  /// 点击缩略图/标题区域播放视频的回调；为 null 时不响应点击。
  final VoidCallback? onPlay;

  /// 暂停按钮（上传中/排队/等待网络-上传形态）。
  final VoidCallback? onPause;

  /// 继续按钮（暂停/等待网络-暂停形态）：从断点续传。
  final VoidCallback? onResume;

  /// 失败态的【继续上传】反色按钮：断点重试。
  final VoidCallback? onRetry;

  /// 重新选择视频文件替换当前分集。
  final VoidCallback? onReupload;

  final VoidCallback? onDelete;

  /// 为 false 时删除按钮不可点击且视觉变浅，用于编辑模式下已回显的剧集。
  final bool deleteEnabled;

  /// 当且仅当为 true 时，左侧拖把手可响应拖动（用
  /// [ReorderableDragStartListener.enabled] 实现）。为 false 时把手按
  /// `ReorderableDragStartListener` 默认禁用态呈现（透明度自动降低）。
  final bool dragEnabled;

  const DramaVideoUploadItem({
    super.key,
    required this.index,
    required this.title,
    this.fileExtension,
    required this.details,
    this.progress = 0.0,
    this.status = VideoUploadStatus.pending,
    this.networkWait = false,
    this.speedBps = 0,
    this.statusLabel = '',
    this.description = '',
    this.descriptionHint = '',
    this.descriptionError,
    this.onDescriptionChanged,
    this.thumbnailPath,
    this.onPlay,
    this.onPause,
    this.onResume,
    this.onRetry,
    this.onReupload,
    this.onDelete,
    this.deleteEnabled = true,
    this.dragEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // SliverReorderableList moves the complete item into an Overlay while it
    // is dragged. Keep a local Material ancestor with the item so the episode
    // description TextField remains valid outside the page's Scaffold.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: const EdgeInsets.only(bottom: StorySpacing.md),
        padding: const EdgeInsets.all(StorySpacing.cardPadding),
        decoration: BoxDecoration(
          color: StoryColors.createDramaPanelSurfaceOf(brightness),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(
            color: StoryColors.dividerOf(brightness),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(brightness),
            const SizedBox(height: StorySpacing.md),
            _buildMediaRow(brightness),
            const SizedBox(height: StorySpacing.md),
            _buildActionRow(context, brightness),
            const SizedBox(height: StorySpacing.md),
            _EpisodeDescriptionField(
              value: description,
              hintText: descriptionHint,
              hasError: descriptionError != null,
              brightness: brightness,
              onChanged: onDescriptionChanged,
            ),
            if (descriptionError != null) ...[
              const SizedBox(height: StorySpacing.xs),
              Text(
                descriptionError!,
                style: StoryTextStyles.bodySmall(
                  color: StoryColors.destructive,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Maps raw upload progress to displayed progress:
  /// - success fills to 100%
  /// - merging pins at 99%
  /// - everything else occupies 0–99%
  double get _displayProgress => switch (status) {
    VideoUploadStatus.success => 1.0,
    VideoUploadStatus.merging => 0.99,
    _ => progress.clamp(0.0, 1.0) * 0.99,
  };

  Widget _buildHeaderRow(Brightness brightness) {
    final mutedFg = StoryColors.mutedForegroundOf(brightness);
    final dragIconColor = dragEnabled
        ? mutedFg
        : StoryColors.buttonDisabledForeground;
    final pill = _resolvePill(brightness);
    return Row(
      children: [
        ReorderableDragStartListener(
          index: index - 1,
          enabled: dragEnabled,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Icon(
              Icons.drag_indicator,
              color: dragIconColor,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: StorySpacing.base),
        SizedBox(
          width: 40,
          child: Text(
            '$index',
            textAlign: TextAlign.center,
            style: StoryTextStyles.titleMedium(
              color: StoryColors.foregroundOf(brightness),
            ).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 24 / 16,
            ),
          ),
        ),
        const Spacer(),
        if (statusLabel.isNotEmpty)
          _StatusPill(
            label: statusLabel,
            color: pill.$2,
            surfaceColor: pill.$3,
          ),
      ],
    );
  }

  Widget _buildMediaRow(Brightness brightness) {
    return Row(
      children: [
        _Thumbnail(
          brightness: brightness,
          thumbnailPath: thumbnailPath,
          onTap: onPlay,
        ),
        const SizedBox(width: StorySpacing.sm),
        Expanded(
          child: GestureDetector(
            onTap: onPlay,
            child: SizedBox(
              height: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFileName(brightness),
                  const SizedBox(height: StorySpacing.xs),
                  _buildMetaRow(brightness),
                  const SizedBox(height: StorySpacing.xs),
                  _buildProgressBar(brightness),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileName(Brightness brightness) {
    final dotIndex = title.lastIndexOf('.');
    final hasExtension = dotIndex > 0 && dotIndex < title.length - 1;
    final fileName = hasExtension ? title.substring(0, dotIndex) : title;
    final extension = hasExtension
        ? title.substring(dotIndex + 1).toUpperCase()
        : (fileExtension?.trim().toUpperCase() ?? '');
    final titleStyle = StoryTextStyles.bodyMedium(
      color: StoryColors.foregroundOf(brightness),
    ).copyWith(fontWeight: FontWeight.w700, height: 20 / 14);

    return Text.rich(
      TextSpan(
        text: fileName,
        style: titleStyle,
        children: [
          if (extension.isNotEmpty)
            TextSpan(text: ' · $extension', style: titleStyle),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetaRow(Brightness brightness) {
    final mutedFg = StoryColors.mutedForegroundOf(brightness);
    final foreground = StoryColors.foregroundOf(brightness);
    // Speed only while actively transferring (Figma: green, next to details).
    final speedLabel = status == VideoUploadStatus.uploading
        ? StoryFormat.formatSpeed(speedBps)
        : '';
    // Percent persists through paused/waiting/failed/merging; hidden once finished.
    final showPercent = status != VideoUploadStatus.success;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                details,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StoryTextStyles.bodySmall(
                  color: mutedFg,
                ).copyWith(height: 16 / 12, letterSpacing: 0.04),
              ),
            ),
            if (speedLabel.isNotEmpty) ...[
              const SizedBox(width: StorySpacing.xs),
              Text(
                speedLabel,
                style: StoryTextStyles.bodySmall(
                  color: StoryColors.success,
                ).copyWith(height: 16 / 12, letterSpacing: 0.04),
              ),
            ],
          ],
        ),
        if (showPercent)
          Text(
            '${(_displayProgress * 100).round()}%',
            style: StoryTextStyles.bodySmall(
              color: foreground,
            ).copyWith(height: 16 / 12, letterSpacing: 0.04),
          ),
      ],
    );
  }

  Widget _buildProgressBar(Brightness brightness) {
    final color = status == VideoUploadStatus.failed
        ? StoryColors.brandTealRed
        : StoryColors.foregroundOf(brightness);
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      child: LinearProgressIndicator(
        value: _displayProgress,
        minHeight: 8,
        backgroundColor: brightness == Brightness.dark
            ? StoryColors.darkButtonBg
            : StoryColors.lightSheetSecondary,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, Brightness brightness) {
    final l10n = context.l10n;
    final trash = _ActionButton(
      semanticLabel: l10n.creatorDramaDelete,
      assetName: 'assets/drama/delete.svg',
      iconColor: deleteEnabled
          ? StoryColors.brandTealRed
          : StoryColors.trashDisabledForegroundOf(brightness),
      surfaceColor: _buttonSurfaceOf(brightness),
      onTap: deleteEnabled ? onDelete : null,
    );
    final refresh = _ActionButton(
      semanticLabel: l10n.commonRetry,
      assetName: 'assets/drama/refresh.svg',
      iconColor: StoryColors.foregroundOf(brightness),
      surfaceColor: _buttonSurfaceOf(brightness),
      onTap: onReupload,
    );

    final children = switch (status) {
      // Failed: prominent inverted 继续上传 (resume from breakpoint) + delete.
      VideoUploadStatus.failed => [
          _ActionButton(
            semanticLabel: l10n.uploadActionResume,
            assetName: 'assets/drama/cloud_upload.svg',
            iconColor: brightness == Brightness.dark
                ? StoryColors.darkBackground
                : StoryColors.onOverlay,
            surfaceColor: brightness == Brightness.dark
                ? Colors.white
                : StoryColors.darkButtonBg,
            onTap: onRetry,
          ),
          trash,
        ],
      // Finished / merging: two wide slots, no pause control (Figma).
      VideoUploadStatus.success ||
      VideoUploadStatus.merging => [refresh, trash],
      // Paused (incl. waiting-network paused form): resume from breakpoint.
      VideoUploadStatus.paused => [
          _ActionButton(
            semanticLabel: l10n.uploadActionResume,
            assetName: 'assets/drama/player_play.svg',
            iconColor: StoryColors.foregroundOf(brightness),
            surfaceColor: _buttonSurfaceOf(brightness),
            onTap: onResume,
          ),
          refresh,
          trash,
        ],
      // Uploading / queued / waiting-network uploading form: pause control.
      _ => [
          _ActionButton(
            semanticLabel: l10n.uploadActionPause,
            assetName: 'assets/drama/pause.svg',
            iconColor: StoryColors.foregroundOf(brightness),
            surfaceColor: _buttonSurfaceOf(brightness),
            onTap: onPause,
          ),
          refresh,
          trash,
        ],
    };

    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: StorySpacing.md),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Color _buttonSurfaceOf(Brightness brightness) =>
      brightness == Brightness.dark
          ? StoryColors.darkButtonBg
          : StoryColors.lightSheetSecondary;

  /// Pill (label, foreground, surface) per Figma token palette.
  (String, Color, Color) _resolvePill(Brightness brightness) {
    final foreground = StoryColors.foregroundOf(brightness);
    final neutralSurface = _buttonSurfaceOf(brightness);
    if (networkWait && status != VideoUploadStatus.success) {
      return (statusLabel, foreground, neutralSurface);
    }
    return switch (status) {
      VideoUploadStatus.success => (
          statusLabel,
          StoryColors.success,
          StoryColors.success.withValues(alpha: 0.05),
        ),
      VideoUploadStatus.failed => (
          statusLabel,
          StoryColors.brandTealRed,
          StoryColors.brandTealRed.withValues(alpha: 0.05),
        ),
      VideoUploadStatus.paused => (statusLabel, foreground, neutralSurface),
      _ => (
          statusLabel,
          StoryColors.pending,
          StoryColors.pending.withValues(alpha: 0.05),
        ),
    };
  }
}

class _EpisodeDescriptionField extends StatefulWidget {
  static const maxLength = 1000;

  final String value;
  final String hintText;
  final bool hasError;
  final Brightness brightness;
  final ValueChanged<String>? onChanged;

  const _EpisodeDescriptionField({
    required this.value,
    required this.hintText,
    required this.hasError,
    required this.brightness,
    this.onChanged,
  });

  @override
  State<_EpisodeDescriptionField> createState() =>
      _EpisodeDescriptionFieldState();
}

class _EpisodeDescriptionFieldState extends State<_EpisodeDescriptionField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _EpisodeDescriptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() => setState(() {});

  void _handleChanged(String value) {
    setState(() {});
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = StoryColors.foregroundOf(widget.brightness);
    final secondaryColor = StoryColors.mutedForegroundOf(widget.brightness);
    final showEllipsizedValue =
        !_focusNode.hasFocus && _controller.text.isNotEmpty;
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 22 / 15,
    );
    final borderColor = widget.hasError
        ? StoryColors.destructive
        : StoryColors.dividerOf(widget.brightness);

    return Stack(
      alignment: Alignment.center,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _handleChanged,
          maxLength: _EpisodeDescriptionField.maxLength,
          textInputAction: TextInputAction.done,
          style: showEllipsizedValue
              ? textStyle.copyWith(color: Colors.transparent)
              : textStyle,
          decoration: InputDecoration(
            hintText: showEllipsizedValue ? null : widget.hintText,
            hintStyle: textStyle.copyWith(color: secondaryColor),
            filled: true,
            fillColor: StoryColors.createDramaPageSurfaceOf(widget.brightness),
            isDense: true,
            counterText: '',
            contentPadding: const EdgeInsets.fromLTRB(
              StorySpacing.md,
              StorySpacing.md,
              StorySpacing.md,
              StorySpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: borderColor, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: borderColor, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(
                color: widget.hasError
                    ? StoryColors.destructive
                    : StoryColors.brandTeal,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (showEllipsizedValue)
          Positioned(
            left: StorySpacing.md,
            right: StorySpacing.md,
            child: IgnorePointer(
              child: Text(
                _controller.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Brightness brightness;
  final String? thumbnailPath;
  final VoidCallback? onTap;

  const _Thumbnail({required this.brightness, this.thumbnailPath, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasThumb = thumbnailPath != null;
    final canPlay = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: StoryColors.mutedOf(brightness),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(
            color: StoryColors.sheetSecondaryOf(brightness),
            width: 0.5,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasThumb)
              Image.file(
                File(thumbnailPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(
                    Icons.movie_outlined,
                    size: 22,
                    color: StoryColors.mutedForegroundOf(brightness),
                  ),
                ),
              )
            else
              Center(
                child: Icon(
                  Icons.movie_outlined,
                  size: 22,
                  color: StoryColors.mutedForegroundOf(brightness),
                ),
              ),
            if (canPlay)
              const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: StoryColors.overlayMedium,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.play_arrow,
                      size: 16,
                      color: StoryColors.onOverlay,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color surfaceColor;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.sm,
        vertical: StorySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        label,
        style: StoryTextStyles.bodySmall().copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          letterSpacing: 0.04,
        ),
      ),
    );
  }
}

/// Wide rounded action button (Figma: h40, r12, 24px stroke icon).
class _ActionButton extends StatelessWidget {
  final String semanticLabel;
  final String assetName;
  final Color iconColor;
  final Color surfaceColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.semanticLabel,
    required this.assetName,
    required this.iconColor,
    required this.surfaceColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: SvgPicture.asset(
            assetName,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
