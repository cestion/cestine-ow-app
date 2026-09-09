import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../controller/publish_video_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_format.dart';

/// 视频文件选择区域。
///
/// 未选择文件时显示虚线上传框；选择后切换为 Figma `521:77694` 的上传状态卡片。
class PublishVideoUploadCard extends StatelessWidget {
  final String title;
  final String hint;
  final String buttonLabel;
  final String? busyLabel;
  final String? selectedFileName;
  final String? thumbnailPath;
  final String? thumbnailUrl;
  final PublishVideoUploadStatus uploadStatus;
  final bool isBusy;
  final bool isPicking;
  final bool enabled;
  final bool showActions;
  final double uploadProgress;
  final int fileSizeBytes;
  final int durationMs;

  /// 断网等待标志：与 [uploadStatus] 组合渲染「等待网络连接...」胶囊，
  /// 并决定按钮跟随暂停/继续形态。
  final bool networkWait;

  /// 实时上传速度（字节/秒），仅上传中显示。
  final int speedBps;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onPlay;

  /// 暂停按钮（上传中/等待网络-上传形态）。
  final VoidCallback? onPause;

  /// 继续按钮（暂停/等待网络-暂停形态）：从断点续传。
  final VoidCallback? onResume;

  /// 失败态的【继续上传】反色按钮：断点重试。
  final VoidCallback? onRetry;

  const PublishVideoUploadCard({
    super.key,
    required this.title,
    required this.hint,
    required this.buttonLabel,
    required this.onTap,
    this.busyLabel,
    this.selectedFileName,
    this.thumbnailPath,
    this.thumbnailUrl,
    this.uploadStatus = PublishVideoUploadStatus.idle,
    this.isBusy = false,
    this.isPicking = false,
    this.enabled = true,
    this.showActions = true,
    this.uploadProgress = 0,
    this.fileSizeBytes = 0,
    this.durationMs = 0,
    this.networkWait = false,
    this.speedBps = 0,
    this.onDelete,
    this.onPlay,
    this.onPause,
    this.onResume,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = selectedFileName;
    if (fileName != null &&
        fileName.isNotEmpty &&
        uploadStatus != PublishVideoUploadStatus.idle) {
      return _SelectedVideoCard(
        fileName: fileName,
        thumbnailPath: thumbnailPath,
        thumbnailUrl: thumbnailUrl,
        uploadStatus: uploadStatus,
        uploadProgress: uploadProgress,
        fileSizeBytes: fileSizeBytes,
        durationMs: durationMs,
        networkWait: networkWait,
        speedBps: speedBps,
        reuploadLabel: buttonLabel,
        busyLabel: busyLabel,
        reuploadEnabled: enabled && !isPicking,
        showActions: showActions,
        isPicking: isPicking,
        onReupload: onTap,
        onDelete: onDelete,
        onPlay: onPlay,
        onPause: onPause,
        onResume: onResume,
        onRetry: onRetry,
      );
    }

    return _EmptyUploadCard(
      title: title,
      hint: hint,
      buttonLabel: buttonLabel,
      busyLabel: busyLabel,
      isBusy: isBusy,
      enabled: enabled,
      uploadProgress: uploadProgress,
      onTap: onTap,
    );
  }
}

class _SelectedVideoCard extends StatelessWidget {
  final String fileName;
  final String? thumbnailPath;
  final String? thumbnailUrl;
  final PublishVideoUploadStatus uploadStatus;
  final double uploadProgress;
  final int fileSizeBytes;
  final int durationMs;
  final bool networkWait;
  final int speedBps;
  final String reuploadLabel;
  final String? busyLabel;
  final bool reuploadEnabled;
  final bool showActions;
  final bool isPicking;
  final VoidCallback? onReupload;
  final VoidCallback? onDelete;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onRetry;

  const _SelectedVideoCard({
    required this.fileName,
    required this.thumbnailPath,
    required this.thumbnailUrl,
    required this.uploadStatus,
    required this.uploadProgress,
    required this.fileSizeBytes,
    required this.durationMs,
    required this.networkWait,
    required this.speedBps,
    required this.reuploadLabel,
    required this.busyLabel,
    required this.reuploadEnabled,
    required this.showActions,
    required this.isPicking,
    required this.onReupload,
    required this.onDelete,
    required this.onPlay,
    required this.onPause,
    required this.onResume,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final mutedForeground = StoryColors.mutedForegroundOf(brightness);
    final secondarySurface = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : StoryColors.lightSheetSecondary;
    final status = _UploadStatusVisual.resolve(
      context,
      uploadStatus,
      networkWait,
    );
    // Map raw progress to UI progress: normal upload occupies 0–99%,
    // merging pins at 99%, and success fills to 100%.
    final progress = switch (uploadStatus) {
      PublishVideoUploadStatus.success => 1.0,
      PublishVideoUploadStatus.merging => 0.99,
      _ => uploadProgress.clamp(0.0, 1.0) * 0.99,
    };
    final progressColor = uploadStatus == PublishVideoUploadStatus.failed
        ? StoryColors.brandTealRed
        : foreground;
    final metaText = _buildMetaText();
    // Figma: live speed (green) only while transferring; the percent persists
    // through paused/waiting/failed/merging and hides once finished.
    final speedLabel = uploadStatus == PublishVideoUploadStatus.uploading
        ? StoryFormat.formatSpeed(speedBps)
        : '';
    final showPercent = uploadStatus != PublishVideoUploadStatus.success;

    return SizedBox(
      height: showActions ? 172 : 117,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 117,
            child: Row(
              children: [
                _VideoThumbnail(
                  thumbnailPath: thumbnailPath,
                  thumbnailUrl: thumbnailUrl,
                  onTap: onPlay,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  metaText,
                                  key: const Key('publishVideoUploadMeta'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: mutedForeground,
                                    fontSize: 12,
                                    height: 16 / 12,
                                    letterSpacing: 0.04,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (speedLabel.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  speedLabel,
                                  key: const Key('publishVideoUploadSpeed'),
                                  style: const TextStyle(
                                    color: StoryColors.success,
                                    fontSize: 12,
                                    height: 16 / 12,
                                    letterSpacing: 0.04,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (showPercent)
                            Text(
                              '${(progress * 100).round()}%',
                              key: const Key('publishVideoUploadPercent'),
                              style: TextStyle(
                                color: foreground,
                                fontSize: 12,
                                height: 16 / 12,
                                letterSpacing: 0.04,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _UploadProgressBar(
                        progress: progress,
                        backgroundColor: secondarySurface,
                        progressColor: progressColor,
                      ),
                      const SizedBox(height: 8),
                      // Figma: the status pill sits under the progress bar.
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _StatusPill(
                          label: status.label,
                          color: status.color,
                          surfaceColor: status.surface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          if (showActions) _buildActionRow(context, secondarySurface),
        ],
      ),
    );
  }

  /// Figma 按钮组：失败=[继续上传(反色)+重选+删除]、完成/合并中=[重选+删除]
  /// （两等宽）、暂停(含等待网络-暂停形态)=[继续+重选+删除]、其余=[暂停+重选+删除]。
  Widget _buildActionRow(BuildContext context, Color surface) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final deleteEnabled = onDelete != null;
    final trash = _UploadActionButton(
      key: const Key('publishVideoDeleteButton'),
      semanticLabel: l10n.creatorDramaDelete,
      backgroundColor: surface,
      onPressed: deleteEnabled ? () => _showDeleteConfirmDialog(context) : null,
      child: SvgPicture.asset(
        'assets/drama/delete.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          deleteEnabled
              ? StoryColors.brandTealRed
              : StoryColors.trashDisabledForegroundOf(brightness),
          BlendMode.srcIn,
        ),
      ),
    );
    final reupload = _buildReuploadButton(brightness);

    final children = switch (uploadStatus) {
      PublishVideoUploadStatus.failed => [
          _UploadActionButton(
            key: const Key('publishVideoResumeUploadButton'),
            semanticLabel: l10n.uploadActionResume,
            backgroundColor: brightness == Brightness.dark
                ? Colors.white
                : StoryColors.darkButtonBg,
            onPressed: onRetry,
            child: SvgPicture.asset(
              'assets/drama/cloud_upload.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                brightness == Brightness.dark
                    ? StoryColors.darkBackground
                    : StoryColors.onOverlay,
                BlendMode.srcIn,
              ),
            ),
          ),
          reupload,
          trash,
        ],
      PublishVideoUploadStatus.success ||
      PublishVideoUploadStatus.merging => [reupload, trash],
      PublishVideoUploadStatus.paused => [
          _UploadActionButton(
            key: const Key('publishVideoResumeButton'),
            semanticLabel: l10n.uploadActionResume,
            backgroundColor: surface,
            onPressed: onResume,
            child: SvgPicture.asset(
              'assets/drama/player_play.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
            ),
          ),
          reupload,
          trash,
        ],
      _ => [
          _UploadActionButton(
            key: const Key('publishVideoPauseButton'),
            semanticLabel: l10n.uploadActionPause,
            backgroundColor: surface,
            onPressed: onPause,
            child: SvgPicture.asset(
              'assets/drama/pause.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
            ),
          ),
          reupload,
          trash,
        ],
    };

    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _buildReuploadButton(Brightness brightness) {
    return _UploadActionButton(
      key: const Key('publishVideoReuploadButton'),
      semanticLabel: reuploadLabel,
      backgroundColor: StoryColors.sheetSecondaryOf(brightness),
      onPressed: reuploadEnabled ? onReupload : null,
      child: isPicking
          ? Semantics(
              label: busyLabel,
              child: const SizedBox.square(
                key: Key('publishVideoPickingIndicator'),
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: StoryColors.brandTealRed,
                ),
              ),
            )
          : SvgPicture.asset(
              'assets/drama/refresh.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                reuploadEnabled
                    ? StoryColors.foregroundOf(brightness)
                    : StoryColors.buttonDisabledForegroundOf(brightness),
                BlendMode.srcIn,
              ),
            ),
    );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteVideoConfirmDialog(
        title: context.l10n.createDramaVideoDeleteConfirm(fileName),
        onCancel: () => Navigator.of(ctx).pop(false),
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
    if (confirmed == true) onDelete?.call();
  }

  /// 拼接 `10.4 MB · 0:30` 形式的元信息文本；任一字段缺失则省略。
  String _buildMetaText() {
    final parts = <String>[];
    if (fileSizeBytes > 0) parts.add(StoryFormat.formatFileSize(fileSizeBytes));
    if (durationMs > 0) parts.add(StoryFormat.formatDuration(durationMs));
    return parts.join(' · ');
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(46),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          key: const Key('publishVideoUploadStatus'),
          style: TextStyle(
            color: color,
            fontSize: 12,
            height: 16 / 12,
            letterSpacing: 0.04,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  final String? thumbnailPath;
  final String? thumbnailUrl;
  final VoidCallback? onTap;

  const _VideoThumbnail({
    required this.thumbnailPath,
    required this.thumbnailUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hasRemoteThumbnail =
        thumbnailPath == null &&
        thumbnailUrl != null &&
        thumbnailUrl!.isNotEmpty;

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      child: GestureDetector(
        key: const Key('publishVideoThumbnail'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 88,
          height: 117,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: StoryColors.mutedOf(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: brightness == Brightness.dark
                  ? StoryColors.darkBorder
                  : StoryColors.lightSheetSecondary,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnailPath != null)
                Image.file(
                  File(thumbnailPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _thumbnailPlaceholder(brightness),
                )
              else if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: thumbnailUrl!,
                  memCacheWidth: (88 * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  memCacheHeight: (117 * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  imageBuilder: (_, imageProvider) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image(image: imageProvider, fit: BoxFit.cover),
                        _playIndicator(),
                      ],
                    );
                  },
                  placeholder: (_, _) => _thumbnailLoading(),
                  errorWidget: (_, _, _) => _thumbnailPlaceholder(brightness),
                )
              else
                _thumbnailPlaceholder(brightness),
              if (!hasRemoteThumbnail) _playIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playIndicator() {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: SvgPicture.asset(
            'assets/publish_video/selected_video_play.svg',
            width: 14.5,
            height: 17.5,
          ),
        ),
      ),
    );
  }

  Widget _thumbnailLoading() {
    return const ColoredBox(
      key: Key('publishVideoThumbnailLoadingOverlay'),
      color: StoryColors.overlayMedium,
      child: Center(
        child: SizedBox.square(
          key: Key('publishVideoThumbnailLoadingIndicator'),
          dimension: 30,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: StoryColors.onOverlay,
          ),
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder(Brightness brightness) {
    return ColoredBox(
      color: StoryColors.mutedOf(brightness),
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 28,
          color: StoryColors.mutedForegroundOf(brightness),
        ),
      ),
    );
  }
}

class _UploadProgressBar extends StatelessWidget {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  const _UploadProgressBar({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(31),
      child: SizedBox.fromSize(
        size: const Size.fromHeight(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: backgroundColor),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    key: const Key('publishVideoUploadProgressValue'),
                    width: constraints.maxWidth * progress,
                    height: 8,
                    child: ColoredBox(color: progressColor),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UploadActionButton extends StatelessWidget {
  final String semanticLabel;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final Widget child;

  const _UploadActionButton({
    super.key,
    required this.semanticLabel,
    required this.backgroundColor,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: SizedBox(
        height: 40,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _UploadStatusVisual {
  final String label;
  final Color color;
  final Color surface;

  const _UploadStatusVisual(this.label, this.color, this.surface);

  static _UploadStatusVisual resolve(
    BuildContext context,
    PublishVideoUploadStatus status,
    bool networkWait,
  ) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    // Neutral states use the solid secondary surface, not a tint.
    final neutralSurface = brightness == Brightness.dark
        ? StoryColors.darkButtonBg
        : StoryColors.lightSheetSecondary;
    if (networkWait && status != PublishVideoUploadStatus.success) {
      return _UploadStatusVisual(
        l10n.uploadStatusWaitingNetwork,
        foreground,
        neutralSurface,
      );
    }
    return switch (status) {
      PublishVideoUploadStatus.success => _UploadStatusVisual(
        l10n.createDramaVideoStatusDone,
        StoryColors.success,
        StoryColors.success.withValues(alpha: 0.05),
      ),
      PublishVideoUploadStatus.failed => _UploadStatusVisual(
        l10n.createDramaVideoStatusFailed,
        StoryColors.brandTealRed,
        StoryColors.brandTealRed.withValues(alpha: 0.05),
      ),
      PublishVideoUploadStatus.paused => _UploadStatusVisual(
        l10n.createDramaVideoStatusPaused,
        foreground,
        neutralSurface,
      ),
      PublishVideoUploadStatus.idle ||
      PublishVideoUploadStatus.uploading ||
      PublishVideoUploadStatus.merging => _UploadStatusVisual(
        l10n.createDramaVideoStatusUploading,
        StoryColors.pending,
        StoryColors.pending.withValues(alpha: 0.05),
      ),
    };
  }
}

/// Figma `392:107257` / `3091:109909` — 删除视频二次确认居中弹窗。
///
/// 标题单行居中，底部为等宽「取消」/「确定」按钮；无图标，与全局
/// [StoryDialog.confirm] 的视觉密度不同，因此作为本页私有组件保留。
class _DeleteVideoConfirmDialog extends StatelessWidget {
  final String title;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _DeleteVideoConfirmDialog({
    required this.title,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final surface = StoryColors.backgroundOf(brightness);
    final foreground = StoryColors.foregroundOf(brightness);
    final cancelBorder = StoryColors.dividerOf(brightness);
    final confirmBackground = isDark
        ? StoryColors.privyDarkNormal
        : StoryColors.privyLightNormal;
    final confirmForeground = isDark
        ? StoryColors.privyDarkForeground
        : StoryColors.privyLightForeground;
    final l10n = context.l10n;

    return Dialog(
      backgroundColor: surface,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 343,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _DeleteDialogButton(
                      label: l10n.commonCancel,
                      onTap: onCancel,
                      backgroundColor: surface,
                      borderColor: cancelBorder,
                      foregroundColor: foreground,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DeleteDialogButton(
                      label: l10n.commonConfirm,
                      onTap: onConfirm,
                      backgroundColor: confirmBackground,
                      foregroundColor: confirmForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  const _DeleteDialogButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyUploadCard extends StatelessWidget {
  final String title;
  final String hint;
  final String buttonLabel;
  final String? busyLabel;
  final bool isBusy;
  final bool enabled;
  final double uploadProgress;
  final VoidCallback? onTap;

  const _EmptyUploadCard({
    required this.title,
    required this.hint,
    required this.buttonLabel,
    required this.busyLabel,
    required this.isBusy,
    required this.enabled,
    required this.uploadProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final border = StoryColors.dividerOf(brightness);

    return Semantics(
      button: true,
      enabled: enabled,
      label: buttonLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: !enabled || isBusy ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _DashedRoundedBorderPainter(color: border, radius: 16),
            child: SizedBox(
              height: 174,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/publish_video/upload_file.svg',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 12,
                        height: 16 / 12,
                        letterSpacing: 0.04,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicWidth(
                      child: _SelectFileButton(
                        label: buttonLabel,
                        busyLabel: busyLabel,
                        isBusy: isBusy,
                        enabled: enabled,
                        progress: uploadProgress,
                        onPressed: onTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectFileButton extends StatelessWidget {
  final String label;
  final String? busyLabel;
  final bool isBusy;
  final bool enabled;
  final double progress;
  final VoidCallback? onPressed;

  const _SelectFileButton({
    required this.label,
    required this.busyLabel,
    required this.isBusy,
    required this.enabled,
    required this.progress,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final progressLabel = '${(progress * 100).clamp(0, 100).round()}%';
    return SizedBox(
      height: 36,
      child: Material(
        color: enabled
            ? StoryColors.brandTealRed
            : StoryColors.buttonDisabledForegroundOf(brightness),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: !enabled || isBusy ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBusy) ...[
                    const SizedBox.square(
                      key: Key('publishVideoPickingIndicator'),
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isBusy
                        ? (progress > 0 ? progressLabel : busyLabel ?? label)
                        : label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dashLength = 3.0;
    const gapLength = 3.0;
    var distance = 0.0;
    while (distance < metric.length) {
      canvas.drawPath(
        metric.extractPath(distance, distance + dashLength),
        paint,
      );
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
