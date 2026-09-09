/// 数字格式化工具（统一管理，避免重复定义）
class StoryFormat {
  StoryFormat._();

  /// 格式化数字：>=10000 显示为 x.xw，>=1000 显示为 x.xk，否则原样显示
  static String formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}w';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  /// 格式化文件大小：>=1MB 显示为 x.x MB，>=1KB 显示为 x.x KB，否则 x B。
  static String formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  /// 格式化上传进度，例如 `4.2 MB / 12.6 MB`。
  static String formatFileProgress(int totalBytes, double progress) {
    final safeTotal = totalBytes < 0 ? 0 : totalBytes;
    final normalized = progress.clamp(0.0, 1.0);
    final uploaded = (safeTotal * normalized).round();
    return '${formatFileSize(uploaded)} / ${formatFileSize(safeTotal)}';
  }

  /// 格式化上传速度，例如 `1.4 MB/s` / `512.0 KB/s`；非正值返回空字符串。
  static String formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond <= 0) return '';
    if (bytesPerSecond >= 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
  }

  /// 将秒/毫秒时间戳字符串格式化为 `yyyy/MM/dd HH:mm:ss`。
  ///
  /// 兼容 10 位（秒）与 13 位（毫秒）时间戳；空值或解析失败返回空字符串。
  static String formatDateTime(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '';
    final ts = int.tryParse(trimmed);
    if (ts == null || ts == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      ts < 10000000000 ? ts * 1000 : ts,
    );
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '${dt.year}/$mm/$dd $hh:$mi:$ss';
  }

  /// 格式化时长（毫秒）为 m:ss 或 h:mm:ss。
  static String formatDuration(int milliseconds) {
    if (milliseconds <= 0) return '0:00';
    final totalSec = (milliseconds / 1000).round();
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }
}
