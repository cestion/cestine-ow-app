import '../model/page_dto.dart';
import 'result.dart';

/// 将可能抛出的异步操作安全包装为 [Result]。
///
/// 适用于 Repository / Service 中 `try { return Result.success(...); } catch { ... }`
/// 模式的重复代码。调用方自行处理日志和回退逻辑。
///
/// ```dart
/// // Before
/// try {
///   return Result.success(decoder(data));
/// } catch (e) {
///   StoryLogger.d('解码失败', tag: 'Repo');
/// }
///
/// // After
/// final r = await safeCall(() => decoder(data));
/// if (r.isFailure) StoryLogger.d('解码失败', tag: 'Repo');
/// ```
Future<Result<T>> safeCall<T>(Future<T> Function() fn) async {
  try {
    return Result.success(await fn());
  } catch (e) {
    return Result.failure(ApiError.unknown(e.toString()));
  }
}

Map<String, dynamic> normalizeJson(dynamic d) =>
    d is Map<String, dynamic> ? d : <String, dynamic>{};

int? asIntOrNull(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);

int asIntOrZero(dynamic v) => asIntOrNull(v) ?? 0;

String? asStringOrNull(dynamic v) => v?.toString();

String asStringOrEmpty(dynamic v) => v?.toString() ?? '';

double? asDoubleOrNull(dynamic v) =>
    v is double ? v : (v is num ? v.toDouble() : null);

bool? asBoolOrNull(dynamic v) => v is bool ? v : null;

/// 创建标准化的 JSON 解码器（自动调用 [normalizeJson]）
///
/// 用于 Repository 中的 safeGet/safePost decoder 参数，
/// 避免重复编写 `(d) => Model.fromJson(normalizeJson(d))`。
///
/// 示例：
/// ```dart
/// _api.safeGet('/path', decoder: decodeWith(Model.fromJson));
/// ```
T Function(dynamic) decodeWith<T>(T Function(Map<String, dynamic>) fromJson) =>
    (d) => fromJson(normalizeJson(d));

PageDto<T> parsePageDto<T>(
  dynamic d,
  T Function(Map<String, dynamic>) fromJson,
) {
  final map = d is Map ? deepStringMap(d) : null;
  if (map == null) return const PageDto();
  final list = map['list'];
  final items = <T>[];
  if (list is List) {
    for (final i in list) {
      if (i is Map) items.add(fromJson(deepStringMap(i)));
    }
  }
  return PageDto(
    pageSize: asIntOrNull(map['pageSize']),
    mark: asStringOrNull(map['mark']),
    list: items,
    hasMore: asBoolOrNull(map['hasMore']),
    total: PageDto.parseTotal(map['total']),
  );
}

/// Recursively convert `Map<dynamic, dynamic>` (from Hive) to
/// `Map<String, dynamic>`, handling nested maps AND nested lists of maps.
Map<String, dynamic> deepStringMap(Object? data) {
  if (data is Map<String, dynamic>) return _deepConvertValues(data);
  if (data is Map) {
    return data.map(
      (key, value) => MapEntry(key.toString(), _deepConvert(value)),
    );
  }
  return <String, dynamic>{};
}

Object? _deepConvert(Object? value) {
  if (value is Map<String, dynamic>) return _deepConvertValues(value);
  if (value is Map) return deepStringMap(value);
  if (value is List) {
    return value.map((e) => e is Map ? deepStringMap(e) : e).toList();
  }
  return value;
}

Map<String, dynamic> _deepConvertValues(Map<String, dynamic> map) {
  final result = <String, dynamic>{};
  for (final entry in map.entries) {
    result[entry.key] = _deepConvert(entry.value);
  }
  return result;
}

List<T> parseList<T>(dynamic d, T Function(Map<String, dynamic>) fromJson) {
  if (d is List) {
    return d.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
  if (d is Map<String, dynamic>) {
    final raw = d['list'] ?? d['records'] ?? d;
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
    }
  }
  return [];
}
