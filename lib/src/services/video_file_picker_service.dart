import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 发布短视频时的视频来源。
enum VideoPickSource { gallery, files }

/// 发布短视频时的单文件选择结果。
class PickedVideoFile {
  final String path;
  final String name;
  final int sizeBytes;

  const PickedVideoFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });
}

/// 文件选择结果。取消、超限和基础设施错误分开返回，便于 UI 准确提示。
sealed class PickVideoResult {
  const PickVideoResult();
}

class PickVideoSelected extends PickVideoResult {
  final PickedVideoFile file;

  const PickVideoSelected(this.file);
}

class PickVideoCanceled extends PickVideoResult {
  const PickVideoCanceled();
}

class PickVideoTooLarge extends PickVideoResult {
  final int? sizeBytes;

  const PickVideoTooLarge({this.sizeBytes});
}

enum PickVideoFailureReason {
  insufficientStorage,
  permissionDenied,
  sourceUnavailable,
  prepareFailed,
}

class PickVideoFailed extends PickVideoResult {
  final PickVideoFailureReason reason;
  final String? technicalMessage;

  const PickVideoFailed(this.reason, {this.technicalMessage});
}

/// 单个短视频文件选择器。
///
/// Android 使用应用内置的原生选择器，其他平台保持使用 file_picker 12。
class VideoFilePickerService {
  VideoFilePickerService._();

  static const _androidChannel = MethodChannel(
    'com.cestine.officeapp/video_file_picker',
  );

  static Future<PickVideoResult> pick({
    required int maxBytes,
    VideoPickSource source = VideoPickSource.gallery,
  }) {
    if (!kIsWeb && Platform.isAndroid) {
      return _pickWithNativeAndroid(maxBytes: maxBytes, source: source);
    }
    return _pickWithFilePicker(maxBytes: maxBytes);
  }

  static Future<PickVideoResult> _pickWithNativeAndroid({
    required int maxBytes,
    required VideoPickSource source,
  }) async {
    try {
      final result = await _androidChannel.invokeMethod<Object?>(
        'pickVideo',
        <String, Object>{'source': source.name, 'maxBytes': maxBytes},
      );
      if (result is! Map) {
        return const PickVideoFailed(
          PickVideoFailureReason.prepareFailed,
          technicalMessage: 'Native video picker returned an invalid result',
        );
      }

      final status = result['status'];
      switch (status) {
        case 'canceled':
          return const PickVideoCanceled();
        case 'tooLarge':
          return PickVideoTooLarge(
            sizeBytes: (result['sizeBytes'] as num?)?.toInt(),
          );
        case 'selected':
          final path = result['path'];
          final name = result['name'];
          final sizeBytes = result['sizeBytes'];
          if (path is! String ||
              path.isEmpty ||
              name is! String ||
              name.isEmpty ||
              sizeBytes is! num) {
            return const PickVideoFailed(
              PickVideoFailureReason.prepareFailed,
              technicalMessage:
                  'Native video picker returned incomplete file metadata',
            );
          }
          return PickVideoSelected(
            PickedVideoFile(
              path: path,
              name: name,
              sizeBytes: sizeBytes.toInt(),
            ),
          );
        default:
          return PickVideoFailed(
            PickVideoFailureReason.prepareFailed,
            technicalMessage: 'Unknown native video picker status: $status',
          );
      }
    } on PlatformException catch (error) {
      final reason = switch (error.code) {
        'insufficient_storage' => PickVideoFailureReason.insufficientStorage,
        'permission_denied' => PickVideoFailureReason.permissionDenied,
        'source_unavailable' => PickVideoFailureReason.sourceUnavailable,
        _ => PickVideoFailureReason.prepareFailed,
      };
      return PickVideoFailed(
        reason,
        technicalMessage: '${error.code}: ${error.message}',
      );
    } catch (error) {
      return PickVideoFailed(
        PickVideoFailureReason.prepareFailed,
        technicalMessage: error.toString(),
      );
    }
  }

  static Future<PickVideoResult> _pickWithFilePicker({
    required int maxBytes,
  }) async {
    try {
      // file_picker 12 defaults compressionQuality to zero, which requests the
      // current/original representation rather than transcoding a large video.
      final platformFile = await FilePicker.pickFile(type: FileType.video);
      if (platformFile == null) return const PickVideoCanceled();
      final sizeBytes = await platformFile.length();
      if (sizeBytes > maxBytes) {
        return PickVideoTooLarge(sizeBytes: sizeBytes);
      }
      final path = platformFile.path;
      if (path == null || path.isEmpty) {
        return const PickVideoFailed(
          PickVideoFailureReason.prepareFailed,
          technicalMessage: 'Picked video has no local path',
        );
      }
      return PickVideoSelected(
        PickedVideoFile(
          path: path,
          name: platformFile.name,
          sizeBytes: sizeBytes,
        ),
      );
    } on PlatformException catch (error) {
      return PickVideoFailed(
        PickVideoFailureReason.sourceUnavailable,
        technicalMessage: '${error.code}: ${error.message}',
      );
    } catch (error) {
      return PickVideoFailed(
        PickVideoFailureReason.prepareFailed,
        technicalMessage: error.toString(),
      );
    }
  }

  /// 删除移动端原生选择器生成的缓存副本。
  ///
  /// 桌面端的 path 可能直接指向用户原文件，因此只允许 Android/iOS 清理。
  static Future<void> deleteTemporaryFile(String path) async {
    if (path.isEmpty || kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      final parent = file.parent;
      if (await parent.exists() && await parent.list().isEmpty) {
        await parent.delete();
      }
    } catch (_) {
      // 临时文件清理失败不影响上传结果。
    }
  }
}
