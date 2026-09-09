import '../core/story_logger.dart';
import '../core/video_url_helpers.dart';

int? asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  if (v is bool) return v ? 1 : 0;
  return null;
}

double? asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool? asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return null;
}

String asStringRequired(dynamic v) {
  if (v == null) {
    StoryLogger.w('asStringRequired received null — check API response');
    return '';
  }
  return v.toString();
}

String? asString(dynamic v) {
  if (v == null) return null;
  return v.toString();
}

/// Play URL field that may be a single string or a multi-source list.
///
/// When the API returns several ladder rungs, keep the lowest numeric /
/// bitrate source (see [VideoUrlHelpers.preferPlaySource]).
String? asPreferredPlayUrl(dynamic v) => VideoUrlHelpers.preferPlaySource(v);

int asIntOrDefault(dynamic v, int defaultValue) => asInt(v) ?? defaultValue;

double asDoubleOrDefault(dynamic v, double defaultValue) =>
    asDouble(v) ?? defaultValue;
