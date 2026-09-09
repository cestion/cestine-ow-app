import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart'
    show
        DiagnosticLevel,
        compute,
        defaultTargetPlatform,
        kIsWeb,
        visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:path_provider/path_provider.dart';

import '../core/story_logger.dart';
import '../styles/story_colors.dart';

const _imagePickerLogTag = 'ImagePicker';

void _logImagePicker(
  String requestId,
  String message, {
  DiagnosticLevel level = DiagnosticLevel.info,
  Object? error,
  StackTrace? stackTrace,
}) {
  final logMessage = '[$requestId] $message';
  switch (level) {
    case DiagnosticLevel.hidden || DiagnosticLevel.fine:
      StoryLogger.d(logMessage, tag: _imagePickerLogTag);
    case DiagnosticLevel.debug:
      StoryLogger.d(logMessage, tag: _imagePickerLogTag);
    case DiagnosticLevel.info:
      StoryLogger.i(logMessage, tag: _imagePickerLogTag);
    case DiagnosticLevel.warning || DiagnosticLevel.hint:
      StoryLogger.w(
        logMessage,
        tag: _imagePickerLogTag,
        error: error,
        stackTrace: stackTrace,
      );
    case DiagnosticLevel.error || DiagnosticLevel.summary:
      StoryLogger.e(
        logMessage,
        tag: _imagePickerLogTag,
        error: error,
        stackTrace: stackTrace,
      );
    case DiagnosticLevel.off:
      return;
  }
}

String _selectedFileSummary(XFile file) {
  final name = file.name;
  final dotIndex = name.lastIndexOf('.');
  final extension = dotIndex >= 0 && dotIndex < name.length - 1
      ? name.substring(dotIndex + 1).toLowerCase()
      : 'none';
  final pathKind = file.path.startsWith('content://')
      ? 'content-uri'
      : file.path.startsWith('/')
      ? 'file-path'
      : file.path.isEmpty
      ? 'empty'
      : 'other';
  return 'extension=$extension mimeType=${file.mimeType ?? 'unknown'} '
      'pathKind=$pathKind pathLength=${file.path.length}';
}

String _lifecycleState() =>
    WidgetsBinding.instance.lifecycleState?.name ?? 'unknown';

/// 选中的图片扩展名不在调用方允许的范围内时抛出。
class UnsupportedImageFormatException implements Exception {
  final String extension;
  final Set<String> allowedExtensions;
  const UnsupportedImageFormatException(this.extension, this.allowedExtensions);
}

/// 选中的图片原始体积超过调用方限制时抛出。
class ImageTooLargeException implements Exception {
  final int sizeBytes;
  final int maxBytes;
  const ImageTooLargeException(this.sizeBytes, this.maxBytes);
}

/// 图片选择与裁剪服务。
///
/// 裁剪界面使用纯 Flutter 实现，不依赖 Android uCrop 或 iOS
/// TOCropViewController，因此各端的布局、手势和返回行为保持一致。
class ImagePickerService {
  ImagePickerService._();

  static bool _isAndroidPickerConfigured = false;

  static void _configureAndroidPicker(String requestId) {
    if (_isAndroidPickerConfigured ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final implementation = ImagePickerPlatform.instance;
    if (implementation is ImagePickerAndroid) {
      // Smartisan and some older OEM gallery apps return content URIs that
      // ACTION_GET_CONTENT cannot read. PickVisualMedia uses the system Photo
      // Picker when available and falls back to ACTION_OPEN_DOCUMENT on older
      // Android versions, which provides a more reliable read grant.
      implementation.useAndroidPhotoPicker = true;
      _isAndroidPickerConfigured = true;
      _logImagePicker(
        requestId,
        'Android 图片选择器已启用 Photo Picker '
        '(旧设备自动回退 ACTION_OPEN_DOCUMENT)',
      );
      return;
    }

    _logImagePicker(
      requestId,
      'Android Photo Picker 配置跳过：'
      'implementation=${implementation.runtimeType}',
      level: DiagnosticLevel.warning,
    );
  }

  /// 选择图片后，打开固定 [ratioX]:[ratioY] 比例的 Flutter 裁剪页。
  ///
  /// 默认将裁剪结果转为 JPEG 并写入临时目录，以便继续使用现有的
  /// file-path 上传接口。[preserveOriginalQuality] 为 true 时不限制原图尺寸、
  /// 不要求系统选图器压缩，并直接保存裁剪组件的最高质量 JPEG / 无损 PNG
  /// 结果，避免额外的二次有损编码。用户取消选图或裁剪时返回 `null`。
  static Future<XFile?> pickAndCropImage({
    required BuildContext context,
    ImageSource source = ImageSource.gallery,
    double ratioX = 6,
    double ratioY = 5,
    int imageQuality = 85,
    int compressQuality = 90,
    double maxDimension = 4096,
    bool preserveOriginalQuality = false,
    String toolbarTitle = '',
    Set<String>? allowedExtensions,
    int? maxSourceBytes,
  }) async {
    assert(ratioX > 0 && ratioY > 0, '裁剪比例必须大于 0');
    assert(maxDimension > 0, '图片最大尺寸必须大于 0');
    final requestId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final totalStopwatch = Stopwatch()..start();
    var stage = 'initializing';

    _logImagePicker(
      requestId,
      '流程开始 source=${source.name} platform=${defaultTargetPlatform.name} '
      'isWeb=$kIsWeb lifecycle=${_lifecycleState()} mounted=${context.mounted} '
      'ratio=$ratioX:$ratioY imageQuality=$imageQuality '
      'compressQuality=$compressQuality maxDimension=$maxDimension '
      'preserveOriginalQuality=$preserveOriginalQuality',
    );

    try {
      if (source == ImageSource.gallery) {
        _configureAndroidPicker(requestId);
      }
      stage = 'opening-picker';
      final pickerStopwatch = Stopwatch()..start();
      _logImagePicker(requestId, '即将打开系统图片选择器');
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: preserveOriginalQuality
            ? null
            : imageQuality.clamp(0, 100),
        maxWidth: preserveOriginalQuality ? null : maxDimension,
        maxHeight: preserveOriginalQuality ? null : maxDimension,
      );
      pickerStopwatch.stop();

      if (picked == null) {
        _logImagePicker(
          requestId,
          '系统图片选择器返回 null，按用户取消处理 '
          'elapsedMs=${pickerStopwatch.elapsedMilliseconds} '
          'mounted=${context.mounted} lifecycle=${_lifecycleState()}',
          level: DiagnosticLevel.warning,
        );
        return null;
      }

      stage = 'picker-returned';
      _logImagePicker(
        requestId,
        '系统图片选择器已返回 ${_selectedFileSummary(picked)} '
        'elapsedMs=${pickerStopwatch.elapsedMilliseconds} '
        'mounted=${context.mounted} lifecycle=${_lifecycleState()}',
      );
      if (!context.mounted) {
        _logImagePicker(
          requestId,
          '已选到图片，但调用页面的 context 已卸载，无法进入裁剪页',
          level: DiagnosticLevel.error,
        );
        return null;
      }

      if (allowedExtensions != null) {
        final dotIndex = picked.name.lastIndexOf('.');
        final extension = dotIndex >= 0 && dotIndex < picked.name.length - 1
            ? picked.name.substring(dotIndex + 1).toLowerCase()
            : '';
        if (!allowedExtensions.contains(extension)) {
          _logImagePicker(
            requestId,
            '图片格式不被允许 extension=$extension '
            'allowed=${allowedExtensions.join(',')}',
            level: DiagnosticLevel.warning,
          );
          throw UnsupportedImageFormatException(extension, allowedExtensions);
        }
      }

      stage = 'reading-source';
      final readStopwatch = Stopwatch()..start();
      int? sourceLength;
      try {
        sourceLength = await picked.length();
      } catch (error, stackTrace) {
        _logImagePicker(
          requestId,
          '读取图片文件长度失败，将继续尝试 readAsBytes',
          level: DiagnosticLevel.warning,
          error: error,
          stackTrace: stackTrace,
        );
      }
      if (maxSourceBytes != null &&
          sourceLength != null &&
          sourceLength > maxSourceBytes) {
        _logImagePicker(
          requestId,
          '图片原始体积超限 sizeBytes=$sourceLength '
          'maxBytes=$maxSourceBytes',
          level: DiagnosticLevel.warning,
        );
        throw ImageTooLargeException(sourceLength, maxSourceBytes);
      }
      _logImagePicker(
        requestId,
        '开始读取图片 bytes fileLength=${sourceLength ?? 'unknown'}',
      );
      final sourceBytes = await picked.readAsBytes();
      readStopwatch.stop();
      _logImagePicker(
        requestId,
        '图片读取完成 bytes=${sourceBytes.length} '
        'elapsedMs=${readStopwatch.elapsedMilliseconds} '
        'mounted=${context.mounted} lifecycle=${_lifecycleState()}',
        level: sourceBytes.isEmpty
            ? DiagnosticLevel.warning
            : DiagnosticLevel.info,
      );
      if (!context.mounted) {
        _logImagePicker(
          requestId,
          '图片读取完成，但调用页面的 context 已卸载，无法进入裁剪页',
          level: DiagnosticLevel.error,
        );
        return null;
      }

      stage = 'opening-crop-page';
      final navigator = Navigator.of(context, rootNavigator: true);
      _logImagePicker(
        requestId,
        '即将进入裁剪页 navigatorMounted=${navigator.mounted} '
        'sourceBytes=${sourceBytes.length}',
      );
      final cropStopwatch = Stopwatch()..start();
      final croppedBytes = await navigator.push<Uint8List>(
        MaterialPageRoute<Uint8List>(
          fullscreenDialog: true,
          builder: (_) => _ImageCropPage(
            image: sourceBytes,
            aspectRatio: ratioX / ratioY,
            title: toolbarTitle,
            requestId: requestId,
          ),
        ),
      );
      cropStopwatch.stop();
      if (croppedBytes == null) {
        _logImagePicker(
          requestId,
          '裁剪页返回 null，按用户取消处理 '
          'elapsedMs=${cropStopwatch.elapsedMilliseconds} '
          'lifecycle=${_lifecycleState()}',
          level: DiagnosticLevel.warning,
        );
        return null;
      }
      _logImagePicker(
        requestId,
        '裁剪页返回成功 bytes=${croppedBytes.length} '
        'elapsedMs=${cropStopwatch.elapsedMilliseconds}',
      );

      late final Uint8List outputBytes;
      late final String outputExtension;
      late final String outputMimeType;
      if (preserveOriginalQuality) {
        stage = 'preserving-crop-output';
        final output = await prepareHighQualityCroppedOutput(croppedBytes);
        outputBytes = output.bytes;
        outputExtension = output.extension;
        outputMimeType = output.mimeType;
        _logImagePicker(
          requestId,
          '保留裁剪最高质量结果 format=$outputExtension '
          'bytes=${outputBytes.length}',
        );
      } else {
        stage = 'encoding-jpeg';
        final encodeStopwatch = Stopwatch()..start();
        _logImagePicker(requestId, '开始 JPEG 编码');
        // 解码/编码可能比较耗时，放到 isolate 避免卡住裁剪页退出动画。
        outputBytes = await compute(_encodeJpeg, (
          bytes: croppedBytes,
          quality: compressQuality.clamp(0, 100),
        ));
        outputExtension = 'jpg';
        outputMimeType = 'image/jpeg';
        encodeStopwatch.stop();
        _logImagePicker(
          requestId,
          'JPEG 编码完成 bytes=${outputBytes.length} '
          'elapsedMs=${encodeStopwatch.elapsedMilliseconds}',
        );
      }

      stage = 'saving-output';
      final outputName =
          'story_crop_${DateTime.now().microsecondsSinceEpoch}.'
          '$outputExtension';
      final tempDirectory = await getTemporaryDirectory();
      final outputPath = '${tempDirectory.path}/$outputName';
      _logImagePicker(
        requestId,
        '开始保存裁剪结果 directoryAvailable=${tempDirectory.path.isNotEmpty}',
      );
      await XFile.fromData(
        outputBytes,
        mimeType: outputMimeType,
        name: outputName,
      ).saveTo(outputPath);
      final output = XFile(
        outputPath,
        mimeType: outputMimeType,
        name: outputName,
      );
      int? savedLength;
      try {
        savedLength = await output.length();
      } catch (error, stackTrace) {
        _logImagePicker(
          requestId,
          '裁剪结果已保存，但读取输出文件长度失败',
          level: DiagnosticLevel.warning,
          error: error,
          stackTrace: stackTrace,
        );
      }
      totalStopwatch.stop();
      _logImagePicker(
        requestId,
        '流程完成 outputBytes=${savedLength ?? outputBytes.length} '
        'totalElapsedMs=${totalStopwatch.elapsedMilliseconds}',
      );
      return output;
    } on PlatformException catch (error, stackTrace) {
      totalStopwatch.stop();
      _logImagePicker(
        requestId,
        '平台异常 stage=$stage code=${error.code} message=${error.message} '
        'totalElapsedMs=${totalStopwatch.elapsedMilliseconds} '
        'mounted=${context.mounted} lifecycle=${_lifecycleState()}',
        level: DiagnosticLevel.error,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      totalStopwatch.stop();
      _logImagePicker(
        requestId,
        '流程异常 stage=$stage type=${error.runtimeType} '
        'totalElapsedMs=${totalStopwatch.elapsedMilliseconds} '
        'mounted=${context.mounted} lifecycle=${_lifecycleState()}',
        level: DiagnosticLevel.error,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

typedef HighQualityCroppedOutput = ({
  Uint8List bytes,
  String extension,
  String mimeType,
});

@visibleForTesting
Future<HighQualityCroppedOutput> prepareHighQualityCroppedOutput(
  Uint8List bytes,
) async {
  switch (image_lib.findFormatForData(bytes)) {
    case image_lib.ImageFormat.jpg:
      return (bytes: bytes, extension: 'jpg', mimeType: 'image/jpeg');
    case image_lib.ImageFormat.png:
      return (bytes: bytes, extension: 'png', mimeType: 'image/png');
    default:
      // crop_your_image 会保留 BMP / ICO 等源格式。上传端以 JPEG / PNG
      // 兼容性最好，因此对少见格式仅做无损 PNG 转换，不降低像素质量。
      final pngBytes = await compute(_encodePng, bytes);
      return (bytes: pngBytes, extension: 'png', mimeType: 'image/png');
  }
}

Uint8List _encodeJpeg(({Uint8List bytes, int quality}) request) {
  final decoded = image_lib.decodeImage(request.bytes);
  if (decoded == null) {
    throw const FormatException('无法解码裁剪后的图片');
  }
  return image_lib.encodeJpg(decoded, quality: request.quality);
}

Uint8List _encodePng(Uint8List bytes) {
  final decoded = image_lib.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('无法解码裁剪后的图片');
  }
  return image_lib.encodePng(decoded);
}

class _ImageCropPage extends StatefulWidget {
  const _ImageCropPage({
    required this.image,
    required this.aspectRatio,
    required this.title,
    required this.requestId,
  });

  final Uint8List image;
  final double aspectRatio;
  final String title;
  final String requestId;

  @override
  State<_ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<_ImageCropPage>
    with WidgetsBindingObserver {
  final CropController _cropController = CropController();
  bool _isReady = false;
  bool _isCropping = false;
  CropStatus? _lastStatus;
  Stopwatch? _cropStopwatch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logImagePicker(
      widget.requestId,
      '裁剪页已创建 sourceBytes=${widget.image.length} '
      'aspectRatio=${widget.aspectRatio} lifecycle=${_lifecycleState()}',
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logImagePicker(
      widget.requestId,
      '裁剪页生命周期变化 state=${state.name} '
      'ready=$_isReady cropping=$_isCropping',
      level: state == AppLifecycleState.resumed
          ? DiagnosticLevel.info
          : DiagnosticLevel.debug,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logImagePicker(
      widget.requestId,
      '裁剪页销毁 ready=$_isReady cropping=$_isCropping '
      'lastStatus=${_lastStatus?.name ?? 'none'}',
    );
    super.dispose();
  }

  void _crop() {
    if (!_isReady || _isCropping) {
      _logImagePicker(
        widget.requestId,
        '忽略裁剪请求 ready=$_isReady cropping=$_isCropping '
        'status=${_lastStatus?.name ?? 'none'}',
        level: DiagnosticLevel.warning,
      );
      return;
    }
    _cropStopwatch = Stopwatch()..start();
    _logImagePicker(widget.requestId, '用户确认裁剪，开始处理');
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  void _onCropped(CropResult result) {
    if (!mounted) {
      _logImagePicker(
        widget.requestId,
        '收到裁剪结果，但裁剪页已经卸载 resultType=${result.runtimeType}',
        level: DiagnosticLevel.error,
      );
      return;
    }
    switch (result) {
      case CropSuccess(:final croppedImage):
        _cropStopwatch?.stop();
        _logImagePicker(
          widget.requestId,
          '裁剪处理成功 bytes=${croppedImage.length} '
          'elapsedMs=${_cropStopwatch?.elapsedMilliseconds ?? -1}',
        );
        Navigator.of(context).pop(croppedImage);
      case CropFailure(:final cause):
        _cropStopwatch?.stop();
        _logImagePicker(
          widget.requestId,
          '裁剪处理失败 elapsedMs=${_cropStopwatch?.elapsedMilliseconds ?? -1}',
          level: DiagnosticLevel.error,
          error: cause,
        );
        setState(() => _isCropping = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(cause.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: StoryColors.onOverlay,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.title),
        leading: IconButton(
          tooltip: localizations.cancelButtonLabel,
          onPressed: () {
            _logImagePicker(widget.requestId, '用户点击关闭裁剪页');
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.close),
        ),
        actions: [
          if (_isCropping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: StoryColors.brandTeal,
                  ),
                ),
              ),
            )
          else
            IconButton(
              tooltip: localizations.okButtonLabel,
              onPressed: _isReady ? _crop : null,
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Crop(
          image: widget.image,
          controller: _cropController,
          aspectRatio: widget.aspectRatio,
          initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
            size: 1,
            aspectRatio: widget.aspectRatio,
          ),
          interactive: true,
          fixCropRect: true,
          baseColor: Colors.black,
          maskColor: StoryColors.overlayMedium,
          filterQuality: FilterQuality.high,
          progressIndicator: const Center(
            child: CircularProgressIndicator(color: StoryColors.brandTeal),
          ),
          onStatusChanged: (status) {
            if (!mounted) return;
            if (_lastStatus != status) {
              _lastStatus = status;
              _logImagePicker(
                widget.requestId,
                '裁剪组件状态变化 status=${status.name}',
                level: status == CropStatus.ready
                    ? DiagnosticLevel.info
                    : DiagnosticLevel.debug,
              );
            }
            final isReady = status == CropStatus.ready;
            if (_isReady != isReady) setState(() => _isReady = isReady);
          },
          onCropped: _onCropped,
        ),
      ),
    );
  }
}
