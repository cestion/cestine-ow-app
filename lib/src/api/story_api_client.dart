import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:alice_http/alice_http_adapter.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:meta/meta.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../model/api_response.dart';
import '../services/connectivity_service.dart';
import 'upload_cancel_token.dart';

typedef TokenProvider = String? Function();
typedef LocaleProvider = String? Function();

/// [code] is the business/HTTP unauthorized code (e.g. 401, 100001, 100401).
typedef OnUnauthorized = FutureOr<void> Function(int code);

/// Thrown inside _withRetry to signal a retryable server error (5xx).
class _ServerErrorException implements Exception {
  final int statusCode;
  final String body;
  const _ServerErrorException(this.statusCode, this.body);
}

/// Outcome of a streamed PUT to a presigned object-storage URL: HTTP status
/// plus the `ETag` response header captured before the body is drained.
class _PresignedPutResponse {
  final int statusCode;
  final String? eTag;
  const _PresignedPutResponse(this.statusCode, this.eTag);
}

class StoryApiClient {
  final String baseUrl;
  final TokenProvider? tokenProvider;
  final LocaleProvider? localeProvider;
  final OnUnauthorized? onUnauthorized;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final int maxRetries;
  final ConnectivityService? connectivity;
  final AliceHttpAdapter? aliceAdapter;
  final IOClient _client;
  final HttpClient _uploadClient;
  final Random _random = Random();
  Future<void>? _logoutGuard;

  StoryApiClient({
    required this.baseUrl,
    this.tokenProvider,
    this.localeProvider,
    this.onUnauthorized,
    this.connectivity,
    this.aliceAdapter,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
    this.maxRetries = 3,
  }) : _client = IOClient(
         HttpClient()
           ..connectionTimeout = connectTimeout
           ..maxConnectionsPerHost = 15
           ..idleTimeout = const Duration(seconds: 30),
       ),
       _uploadClient = HttpClient()
         ..connectionTimeout = connectTimeout
         ..maxConnectionsPerHost = 5
         ..idleTimeout = const Duration(seconds: 30);

  /// 触发登出回调；同一时刻只跑一次，完成后解锁以便下次会话仍能触发。
  void _triggerUnauthorized(int code) {
    if (_logoutGuard != null) {
      StoryLogger.d(
        'Unauthorized suppressed by logout guard (code=$code)',
        tag: 'ApiClient',
      );
      return;
    }
    final callback = onUnauthorized;
    if (callback == null) return;

    late final Future<void> pending;
    pending = Future<void>.sync(() => callback(code)).whenComplete(() {
      if (identical(_logoutGuard, pending)) {
        _logoutGuard = null;
      }
    });
    _logoutGuard = pending;
  }

  /// 释放 HTTP 客户端资源（关闭底层 Socket 连接）
  void dispose() {
    _client.close();
    _uploadClient.close();
  }

  /// 异步预热 DNS 缓存，缩短首次请求建立连接的延迟时间。
  Future<void> preheatDns() async {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return;
      }
    } catch (_) {
      // Platform.environment is not supported on web
    }

    try {
      final host = Uri.parse(baseUrl).host;
      if (host.isNotEmpty) {
        await InternetAddress.lookup(host).timeout(const Duration(seconds: 3));
        StoryLogger.d('DNS preheated for $host', tag: 'ApiClient');
      }
    } catch (e) {
      // 忽略预热异常，不影响后续实际请求
    }
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{};
    final token = tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final locale = localeProvider?.call();
    if (locale != null && locale.isNotEmpty) {
      headers['Accept-Language'] = locale;
    }
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';
    return headers;
  }

  /// Keys whose values should be redacted in logs.
  static const _sensitiveQueryKeys = {
    'token',
    'signature',
    'privytoken',
    'password',
    'secret',
    'credential',
    'security-token',
  };

  static bool _isSensitiveQueryKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.startsWith('x-amz-') ||
        _sensitiveQueryKeys.any(normalized.contains);
  }

  @visibleForTesting
  Uri buildUri(String path, Map<String, dynamic>? query) {
    var uri = Uri.parse(baseUrl).resolve(path);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: _sanitizeQuery(query));
    }
    return uri;
  }

  /// Returns a log-safe query string with sensitive values redacted.
  String sanitizeUriForLog(Uri uri) {
    final q = uri.queryParametersAll;
    if (q.isEmpty) return uri.toString();
    final safeQuery = q.entries
        .expand((entry) {
          final values = _isSensitiveQueryKey(entry.key)
              ? entry.value.map((_) => '***')
              : entry.value;
          return values.map(
            (value) => '${Uri.encodeQueryComponent(entry.key)}=$value',
          );
        })
        .join('&');
    return uri.replace(query: safeQuery).toString();
  }

  /// Throws [_ServerErrorException] on 5xx so [safeGet] can retry.
  Future<http.Response> _requestWithRetryableCheck(
    Future<http.Response> Function() request,
  ) async {
    final response = await request();
    aliceAdapter?.onResponse(response);
    if (response.statusCode >= 500 && response.statusCode < 600) {
      throw _ServerErrorException(response.statusCode, response.body);
    }
    return response;
  }

  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    return _withRetry(path, () async {
      final uri = buildUri(path, query);
      StoryLogger.d('GET ${sanitizeUriForLog(uri)}', tag: 'ApiClient');
      final requestHeaders = _buildHeaders();
      if (headers != null) {
        requestHeaders.addAll(headers);
      }
      final response = await _requestWithRetryableCheck(
        () => _client.get(uri, headers: requestHeaders).timeout(receiveTimeout),
      );
      StoryLogger.d(
        'GET ${sanitizeUriForLog(uri)} -> ${response.statusCode}',
        tag: 'ApiClient',
      );
      return _handleResponse<T>(response, decoder);
    });
  }

  /// DELETE 请求，默认不重试（确保幂等操作安全）。
  Future<Result<T>> safeDelete<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) decoder,
  }) async {
    return _withRetry(path, () async {
      final uri = buildUri(path, query);
      StoryLogger.d('DELETE ${sanitizeUriForLog(uri)}', tag: 'ApiClient');
      final response = await _requestWithRetryableCheck(
        () => _client
            .delete(uri, headers: _buildHeaders())
            .timeout(receiveTimeout),
      );
      StoryLogger.d(
        'DELETE ${sanitizeUriForLog(uri)} -> ${response.statusCode}',
        tag: 'ApiClient',
      );
      return _handleResponse<T>(response, decoder);
    }, retry: false);
  }

  /// [retry] 控制是否对 POST 请求进行重试。
  /// 默认不重试（POST 默认视为非幂等，避免重复创建/扣费）。
  /// 对于幂等操作（如 login、logout、刷新类），调用方需显式传入 `retry: true`。
  Future<Result<T>> safePost<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
    bool retry = false,
  }) async {
    return _withRetry(path, () async {
      final uri = buildUri(path, query);
      StoryLogger.d('POST ${sanitizeUriForLog(uri)}', tag: 'ApiClient');
      final bodyStr = body != null ? json.encode(body) : null;
      StoryLogger.d('POST body: $bodyStr', tag: 'ApiClient');
      final requestHeaders = _buildHeaders();
      if (headers != null) {
        requestHeaders.addAll(headers);
      }
      final response = await _requestWithRetryableCheck(
        () => _client
            .post(uri, headers: requestHeaders, body: bodyStr)
            .timeout(receiveTimeout),
      );
      StoryLogger.d(
        'POST ${sanitizeUriForLog(uri)} -> ${response.statusCode}',
        tag: 'ApiClient',
      );
      return _handleResponse<T>(response, decoder);
    }, retry: retry);
  }

  /// PUT 请求，使用与 [safePost] 相同的鉴权、JSON 编码和业务信封解析。
  ///
  /// 默认不重试，避免在服务端未严格保证幂等时重复提交更新。
  Future<Result<T>> safePut<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
    bool retry = false,
  }) async {
    return _withRetry(path, () async {
      final uri = buildUri(path, query);
      StoryLogger.d('PUT ${sanitizeUriForLog(uri)}', tag: 'ApiClient');
      final bodyStr = body != null ? json.encode(body) : null;
      StoryLogger.d('PUT body: $bodyStr', tag: 'ApiClient');
      final requestHeaders = _buildHeaders();
      if (headers != null) {
        requestHeaders.addAll(headers);
      }
      final response = await _requestWithRetryableCheck(
        () => _client
            .put(uri, headers: requestHeaders, body: bodyStr)
            .timeout(receiveTimeout),
      );
      StoryLogger.d(
        'PUT ${sanitizeUriForLog(uri)} -> ${response.statusCode}',
        tag: 'ApiClient',
      );
      return _handleResponse<T>(response, decoder);
    }, retry: retry);
  }

  /// 将文件字节以流式 PUT 直传到预签名 URL（如 S3/OSS）。
  ///
  /// 与 [safeGet]/[safePost] 不同：不附加鉴权头、不做业务信封解析，
  /// 直接以 HTTP 状态码判定结果（2xx 视为成功）。用于对象存储预签名直传。
  ///
  /// [url] 预签名的绝对上传地址；[headers] 为签名要求的请求头
  /// （如 `x-amz-acl`、`Content-Type`），必须原样传入以匹配签名。
  /// [onProgress] 上报已交给网络层的字节数与总字节数。
  Future<Result<void>> uploadBytes({
    required String url,
    required Stream<List<int>> byteStream,
    required int contentLength,
    Map<String, String>? headers,
    void Function(int sent, int total)? onProgress,
    Duration? timeout,
    UploadCancelToken? cancelToken,
  }) async {
    final result = await _putToPresignedUrl(
      url: url,
      byteStream: byteStream,
      contentLength: contentLength,
      headers: headers,
      onProgress: onProgress,
      timeout: timeout,
      cancelToken: cancelToken,
    );
    return result.map<void>((response) {});
  }

  /// 将单个分片以流式 PUT 直传到其预签名 URL，返回响应 `ETag` 头。
  ///
  /// `ETag` 由合并（complete）请求按 `{partNumber, eTag}` 回传后端，
  /// S3 分片 PUT 必然携带该头，缺失视为协议异常。
  ///
  /// 分片 PUT 不携带任何附加头（`Content-Type`/`x-amz-acl` 等已在
  /// initiate 阶段由服务端定稿），与 [uploadBytes] 的整文件直传不同。
  /// [onProgress] 上报本分片内已交给网络层的字节数与分片总字节数。
  Future<Result<String>> uploadPart({
    required String url,
    required Stream<List<int>> byteStream,
    required int contentLength,
    void Function(int sent, int total)? onProgress,
    Duration? timeout,
    UploadCancelToken? cancelToken,
  }) async {
    final result = await _putToPresignedUrl(
      url: url,
      byteStream: byteStream,
      contentLength: contentLength,
      onProgress: onProgress,
      timeout: timeout,
      cancelToken: cancelToken,
    );
    if (result case Success(:final data)) {
      final eTag = data.eTag;
      if (eTag == null || eTag.isEmpty) {
        return Result.failure(
          ApiError.parse('Presigned part upload returned no ETag'),
        );
      }
      return Result.success(eTag);
    }
    return Result.failure(result.errorOrNull!);
  }

  /// 流式 PUT 到预签名 URL 的共享传输核心。
  ///
  /// 成功时返回状态码与 `ETag` 响应头（在排空响应体前捕获），供
  /// [uploadBytes]（忽略）与 [uploadPart]（必需）分别消费。
  Future<Result<_PresignedPutResponse>> _putToPresignedUrl({
    required String url,
    required Stream<List<int>> byteStream,
    required int contentLength,
    Map<String, String>? headers,
    void Function(int sent, int total)? onProgress,
    Duration? timeout,
    UploadCancelToken? cancelToken,
  }) async {
    HttpClientRequest? request;
    Timer? inactivityTimer;
    var inactivityTimedOut = false;
    try {
      if (cancelToken?.isCanceled ?? false) {
        return Result.failure(
          ApiError.unknown(
            'Upload canceled',
            exception: const UploadCanceledException(),
          ),
        );
      }
      final uri = Uri.parse(url);
      final rq = await _uploadClient.openUrl('PUT', uri);
      request = rq;
      cancelToken?.attach(rq);
      if (headers != null) {
        headers.forEach((k, v) => rq.headers.set(k, v));
      }
      rq.contentLength = contentLength;

      var sent = 0;
      final inactivityTimeout = timeout ?? const Duration(seconds: 60);
      void armInactivityTimer() {
        inactivityTimer?.cancel();
        inactivityTimer = Timer(inactivityTimeout, () {
          inactivityTimedOut = true;
          rq.abort(TimeoutException('Upload made no progress'));
        });
      }

      armInactivityTimer();
      await rq.addStream(
        byteStream.map((chunk) {
          sent += chunk.length;
          onProgress?.call(sent, contentLength);
          armInactivityTimer();
          return chunk;
        }),
      );
      armInactivityTimer();
      final streamed = await rq.close();
      inactivityTimer?.cancel();
      final statusCode = streamed.statusCode;
      final eTag = streamed.headers.value(HttpHeaders.etagHeader);
      // Consume the response so the HTTP connection can be safely reused.
      await streamed.drain<void>();
      StoryLogger.d('PUT upload -> $statusCode', tag: 'ApiClient');
      if (statusCode >= 200 && statusCode < 300) {
        return Result.success(_PresignedPutResponse(statusCode, eTag));
      }
      return Result.failure(ApiError.network('Upload failed ($statusCode)'));
    } on TimeoutException catch (e, st) {
      StoryLogger.e(
        'Request ${sanitizeUriForLog(Uri.parse(url))} timed out',
        error: e,
        stackTrace: st,
        tag: 'ApiClient',
      );
      return Result.failure(ApiError.timeout('Upload timed out'));
    } on SocketException catch (e) {
      if (inactivityTimedOut) {
        return Result.failure(ApiError.timeout('Upload timed out'));
      }
      return Result.failure(
        ApiError.network('Network connection failed', exception: e),
      );
    } on HttpException catch (e) {
      if (inactivityTimedOut) {
        return Result.failure(ApiError.timeout('Upload timed out'));
      }
      return Result.failure(
        ApiError.network('Upload request failed', exception: e),
      );
    } catch (e, st) {
      if (inactivityTimedOut) {
        return Result.failure(ApiError.timeout('Upload timed out'));
      }
      StoryLogger.e(
        'PUT upload failed',
        error: e,
        stackTrace: st,
        tag: 'ApiClient',
      );
      return Result.failure(
        ApiError.unknown(
          'Upload transport failed',
          exception: e is Exception ? e : null,
        ),
      );
    } finally {
      inactivityTimer?.cancel();
      final rq = request;
      if (rq != null) cancelToken?.detach(rq);
    }
  }

  /// Exponential backoff with jitter: base = 500ms, multiplier = 2x per attempt.
  Duration _backoff(int attempt) {
    final base = 500 * (1 << (attempt - 1)); // 500, 1000, 2000, …
    final jitter = _random.nextInt(base ~/ 2); // up to 50% jitter
    return Duration(milliseconds: base + jitter);
  }

  /// [retry] 为 false 时仅执行一次，不重试。用于非幂等操作（POST/PUT/DELETE）。
  Future<Result<T>> _withRetry<T>(
    String path,
    Future<Result<T>> Function() request, {
    bool retry = true,
  }) async {
    final attempts = (!retry || maxRetries < 1) ? 1 : maxRetries;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      if (attempt > 1 && connectivity != null && !connectivity!.value) {
        StoryLogger.w(
          'Request $path skipped: offline before retry',
          tag: 'ApiClient',
        );
        return Result.failure(ApiError.network('No network connection'));
      }

      try {
        return await request();
      } on TimeoutException catch (e, st) {
        StoryLogger.e(
          'Request $path timed out',
          error: e,
          stackTrace: st,
          tag: 'ApiClient',
        );
        if (attempt >= attempts) {
          return Result.failure(ApiError.timeout('Request timed out'));
        }
        StoryLogger.w(
          'Request $path timed out (attempt $attempt/$attempts), retrying',
          tag: 'ApiClient',
        );
        await Future<void>.delayed(_backoff(attempt));
        continue;
      } on SocketException catch (e) {
        if (attempt >= attempts) {
          return Result.failure(
            ApiError.network('Network connection failed', exception: e),
          );
        }
        StoryLogger.w(
          'Request $path network error (attempt $attempt/$attempts), retrying',
          tag: 'ApiClient',
        );
        await Future<void>.delayed(_backoff(attempt));
        continue;
      } on _ServerErrorException catch (e) {
        if (attempt >= attempts) {
          return Result.failure(
            ApiError.network('Server error (${e.statusCode})'),
          );
        }
        StoryLogger.w(
          'Request $path server error ${e.statusCode} (attempt $attempt/$attempts), retrying',
          tag: 'ApiClient',
        );
        await Future<void>.delayed(_backoff(attempt));
        continue;
      } on http.ClientException catch (e) {
        if (attempt >= attempts) {
          return Result.failure(
            ApiError.network('Network request failed', exception: e),
          );
        }
        StoryLogger.w(
          'Request $path client error (attempt $attempt/$attempts), retrying',
          tag: 'ApiClient',
        );
        await Future<void>.delayed(_backoff(attempt));
        continue;
      } catch (e, st) {
        StoryLogger.e(
          'Request $path failed',
          error: e,
          stackTrace: st,
          tag: 'ApiClient',
        );
        return Result.failure(
          ApiError.unknown(e.toString(), exception: e is Exception ? e : null),
        );
      }
    }
    return Result.failure(ApiError.unknown('Unexpected retry failure'));
  }

  Map<String, String> _sanitizeQuery(Map<String, dynamic>? query) {
    if (query == null) return <String, String>{};
    final result = <String, String>{};
    query.forEach((key, value) {
      if (value == null) return;
      result[key] = value.toString();
    });
    return result;
  }

  @visibleForTesting
  Result<T> safeDecode<T>(
    T Function(dynamic) decoder,
    dynamic data,
    String context,
  ) {
    try {
      return Result.success(decoder(data));
    } catch (e, st) {
      StoryLogger.w(
        'Decode failure in $context',
        error: e,
        stackTrace: st,
        tag: 'ApiClient',
      );
      return Result.failure(
        ApiError.parse(
          'Failed to parse response data',
          exception: e is Exception ? e : null,
        ),
      );
    }
  }

  @visibleForTesting
  Future<ApiResponse<dynamic>> parseEnvelope(http.Response response) {
    return _parseEnvelope(response);
  }

  Future<Result<T>> _handleResponse<T>(
    http.Response response,
    T Function(dynamic) decoder,
  ) async {
    final envelope = await parseEnvelope(response);
    return mapToResult(envelope, decoder);
  }

  Future<ApiResponse<dynamic>> _parseEnvelope(http.Response response) async {
    final statusCode = response.statusCode;
    if (statusCode == 401) {
      // Prefer business code from body (e.g. 100001 / 100401).
      // Hardcoding HTTP 401 alone drops the backend code and skips
      // the session-expired toast.
      if (response.body.isNotEmpty) {
        try {
          final bodyJson = json.decode(response.body);
          if (bodyJson is Map<String, dynamic>) {
            final parsed = ApiResponse<dynamic>.fromJson(
              bodyJson,
              (fromJson) => fromJson,
            );
            if (parsed.isUnauthorized) {
              return parsed;
            }
          }
        } catch (_) {
          // Fall through to generic HTTP 401.
        }
      }
      return const ApiResponse<dynamic>(code: 401, msg: 'Unauthorized');
    }
    if (statusCode == 404) {
      return const ApiResponse<dynamic>(code: 404, msg: 'Resource not found');
    }
    if (response.body.isEmpty) {
      if (statusCode == 204) {
        return const ApiResponse<dynamic>(
          code: 200,
          msg: '',
          data: <String, dynamic>{},
        );
      }
      return const ApiResponse<dynamic>(code: -1, msg: 'Empty response');
    }
    Object? bodyJson;
    try {
      // For large responses (>512KB), decode UTF-8 + JSON in an isolate to
      // avoid blocking the UI thread during heavy parsing.
      if (response.bodyBytes.length > 512 * 1024) {
        final bytes = response.bodyBytes;
        bodyJson = await Isolate.run(() => json.decode(utf8.decode(bytes)));
      } else {
        bodyJson = json.decode(response.body);
      }
    } catch (e) {
      return ApiResponse<dynamic>(
        code: -1,
        msg: 'Failed to parse JSON',
        data: e is Exception ? e : null,
      );
    }
    if (bodyJson is! Map<String, dynamic>) {
      return ApiResponse<dynamic>(code: 200, msg: '', data: bodyJson);
    }
    return ApiResponse<dynamic>.fromJson(bodyJson, (fromJson) => fromJson);
  }

  @visibleForTesting
  Result<T> mapToResult<T>(
    ApiResponse<dynamic> response,
    T Function(dynamic) decoder,
  ) {
    final code = response.code;
    final message = response.effectiveMessage;
    if (code == -1) {
      final data = response.data;
      return Result.failure(
        ApiError.parse(message, exception: data is Exception ? data : null),
      );
    }
    if (code == 401) {
      _triggerUnauthorized(code);
      return Result.failure(ApiError.unauthorized('Unauthorized'));
    }
    if (code == 404) {
      return Result.failure(ApiError.notFound('Resource not found'));
    }
    if (response.isSuccess) {
      return safeDecode(
        decoder,
        response.data ?? <String, dynamic>{},
        code == 200 && message.isEmpty ? 'non-map response' : '$code succeed',
      );
    }
    if (response.isUnauthorized) {
      _triggerUnauthorized(code);
      return Result.failure(
        ApiError.unauthorized(message.isEmpty ? 'Unauthorized' : message),
      );
    }
    StoryLogger.w(
      'API Business Error: code=$code, message=$message, data=${response.data}',
      tag: 'ApiClient',
    );
    // Empty message: UI resolves via [errorOperationFailed] in l10nError.
    return Result.failure(ApiError.business(code, message));
  }
}
