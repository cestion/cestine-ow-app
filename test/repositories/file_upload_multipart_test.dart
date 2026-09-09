import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/repositories/file_upload_repository.dart';

/// Records gateway calls and returns canned envelope data for the
/// multipart endpoints, so repository mapping logic runs against the
/// real decoder path.
class _FakeGatewayApi extends StoryApiClient {
  _FakeGatewayApi() : super(baseUrl: 'https://test.api/v1/', maxRetries: 0);

  final List<RecordedCall> calls = [];
  final Map<String, dynamic Function(Map<String, dynamic> body)> postHandlers =
      {};
  final Map<String, dynamic Function(Map<String, String> query)> getHandlers =
      {};

  @override
  Future<Result<T>> safePost<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
    bool retry = false,
  }) async {
    calls.add(RecordedCall('POST', path, body: body, retry: retry));
    final handler = postHandlers[path];
    if (handler == null) {
      return Result.failure(ApiError.business(0, 'no handler for $path'));
    }
    return Result.success(decoder(handler(Map<String, dynamic>.from(body as Map))));
  }

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async {
    calls.add(RecordedCall('GET', path, query: query));
    final handler = getHandlers[path];
    if (handler == null) {
      return Result.failure(ApiError.business(0, 'no handler for $path'));
    }
    return Result.success(decoder(handler(_queryString(query))));
  }

  static Map<String, String> _queryString(Map<String, dynamic>? query) => {
        for (final e in (query ?? const {}).entries)
          if (e.value != null) e.key: e.value.toString(),
      };
}

class RecordedCall {
  final String method;
  final String path;
  final dynamic body;
  final Map<String, dynamic>? query;
  final bool retry;
  RecordedCall(this.method, this.path,
      {this.body, this.query, this.retry = false});
}

void main() {
  late _FakeGatewayApi api;
  late FileUploadRepositoryImpl repository;

  const session = '123456789012345';
  const objectKey = 'mini-drama/assets/123/episode/987.mp4';
  const uploadId = 's3-multipart-id';

  setUp(() {
    api = _FakeGatewayApi();
    repository = FileUploadRepositoryImpl(api);
  });

  test('initiateMultipart posts the contract body', () async {
    api.postHandlers['/api/mini-drama/creator/uploads/multipart/initiate'] =
        (_) => {
              'uploadId': uploadId,
              'objectKey': objectKey,
              'partSize': 10485760,
              'totalParts': 103,
            };

    final result = await repository.initiateMultipart(
      uploadSessionId: session,
      fileName: 'my-episode.mp4',
      contentType: 'video/mp4',
      fileSize: 1073741824,
    );

    final data = result.dataOrNull!;
    expect(data.isValid, isTrue);
    expect(data.uploadId, uploadId);
    expect(data.partSize, 10485760);
    expect(data.totalParts, 103);
    final call = api.calls.single;
    expect(call.method, 'POST');
    expect(
      call.body,
      {
        'uploadSessionId': session,
        'fileName': 'my-episode.mp4',
        'contentType': 'video/mp4',
        'fileSize': 1073741824,
      },
    );
    expect(call.retry, isFalse, reason: 'initiate 非幂等，不自动重试');
  });

  test('initiate result with missing uploadId is invalid but passes data',
      () async {
    api.postHandlers['/api/mini-drama/creator/uploads/multipart/initiate'] =
        (_) => {'objectKey': objectKey};

    final result = await repository.initiateMultipart(
      uploadSessionId: session,
      fileName: 'a.mp4',
      contentType: 'video/mp4',
      fileSize: 10,
    );

    expect(result.dataOrNull!.isValid, isFalse);
  });

  test('presignPartUrls posts partNumbers and filters invalid entries',
      () async {
    api.postHandlers[
        '/api/mini-drama/creator/uploads/multipart/parts/presign'] = (body) {
      expect(body['partNumbers'], [5, 2]);
      return {
        'parts': [
          {'partNumber': 5, 'uploadUrl': 'https://s3/5'},
          {'partNumber': 2, 'uploadUrl': 'https://s3/2'},
          {'partNumber': 0, 'uploadUrl': 'https://s3/invalid'},
          {'uploadUrl': 'https://s3/invalid'},
        ],
        'expireSeconds': 7200,
      };
    };

    final result = await repository.presignPartUrls(
      uploadSessionId: session,
      objectKey: objectKey,
      uploadId: uploadId,
      partNumbers: [5, 2],
    );

    final parts = result.dataOrNull!;
    expect(parts.map((p) => p.partNumber), [2, 5]);
    expect(api.calls.single.retry, isTrue, reason: 'presign 无副作用可重试');
  });

  test('listCompletedParts decodes eTag/size and sorts by partNumber',
      () async {
    api.getHandlers['/api/mini-drama/creator/uploads/multipart/parts'] =
        (_) => {
              'parts': [
                {'partNumber': 3, 'eTag': '"c3"', 'size': 10485760},
                {'partNumber': 1, 'eTag': '"c1"', 'size': 10485760},
                {'partNumber': 2, 'eTag': '"c2"', 'size': 10485760},
                {'partNumber': 4, 'eTag': ''},
              ],
            };

    final result = await repository.listCompletedParts(
      uploadSessionId: session,
      objectKey: objectKey,
      uploadId: uploadId,
    );

    final parts = result.dataOrNull!;
    expect(parts.map((p) => p.partNumber), [1, 2, 3]);
    expect(parts.first.eTag, '"c1"');
    expect(parts.first.size, 10485760);
    expect(
      api.calls.single.query,
      {
        'uploadSessionId': session,
        'objectKey': objectKey,
        'uploadId': uploadId,
      },
    );
  });

  group('submitComplete', () {
    test('maps PROCESSING receipt and posts full parts list', () async {
      api.postHandlers[
          '/api/mini-drama/creator/uploads/multipart/complete'] = (body) {
        expect((body['parts'] as List).length, 2);
        return {'objectKey': objectKey, 'status': 'PROCESSING'};
      };

      final result = await repository.submitComplete(
        uploadSessionId: session,
        objectKey: objectKey,
        uploadId: uploadId,
        parts: [
          const UploadedPart(partNumber: 2, eTag: '"c2"', size: 10),
          const UploadedPart(partNumber: 1, eTag: '"c1"', size: 10),
        ],
      );

      expect(result.dataOrNull!.outcome, MultipartFinalizeOutcome.processing);
      expect(api.calls.single.retry, isTrue, reason: 'complete 幂等可重试');
    });

    test('maps READY receipt directly', () async {
      api.postHandlers[
          '/api/mini-drama/creator/uploads/multipart/complete'] = (_) =>
          {'objectKey': objectKey, 'status': 'READY'};

      final result = await repository.submitComplete(
        uploadSessionId: session,
        objectKey: objectKey,
        uploadId: uploadId,
        parts: const [UploadedPart(partNumber: 1, eTag: '"c1"', size: 10)],
      );

      expect(result.dataOrNull!.outcome, MultipartFinalizeOutcome.ready);
      expect(result.dataOrNull!.objectKey, objectKey);
    });

    test('missing status defaults to processing (accepted by the backend)',
        () async {
      api.postHandlers[
          '/api/mini-drama/creator/uploads/multipart/complete'] = (_) =>
          {'objectKey': objectKey};

      final result = await repository.submitComplete(
        uploadSessionId: session,
        objectKey: objectKey,
        uploadId: uploadId,
        parts: const [UploadedPart(partNumber: 1, eTag: '"c1"', size: 10)],
      );

      expect(result.dataOrNull!.outcome, MultipartFinalizeOutcome.processing);
    });
  });

  group('pollCompleteStatus', () {
    Future<Result<MultipartFinalizeStatus>> pollWith(
      Map<String, dynamic> data,
    ) {
      api.getHandlers[
          '/api/mini-drama/creator/uploads/multipart/complete'] = (_) => data;
      return repository.pollCompleteStatus(
        uploadSessionId: session,
        objectKey: objectKey,
        uploadId: uploadId,
      );
    }

    test('maps three-state data: PROCESSING / READY / FAILED(errorCodes)',
        () async {
      final processing = await pollWith({'status': 'PROCESSING'});
      expect(processing.dataOrNull!.outcome, MultipartFinalizeOutcome.processing);

      final ready = await pollWith({'status': 'READY', 'objectKey': objectKey});
      expect(ready.dataOrNull!.outcome, MultipartFinalizeOutcome.ready);

      final failedSystem = await pollWith({
        'status': 'FAILED',
        'errorCode': MultipartUploadErrorCodes.systemError,
      });
      expect(
        failedSystem.dataOrNull!.outcome,
        MultipartFinalizeOutcome.failedSystem,
      );

      final failedInvalid = await pollWith({
        'status': 'FAILED',
        'errorCode': MultipartUploadErrorCodes.multipartUploadInvalid,
      });
      expect(
        failedInvalid.dataOrNull!.outcome,
        MultipartFinalizeOutcome.uploadInvalid,
      );

      final failedUnknown = await pollWith({
        'status': 'FAILED',
        'errorCode': 999999,
      });
      expect(failedUnknown.dataOrNull!.outcome, MultipartFinalizeOutcome.failed);
    });

    test('unexpected data shape is a transient outcome for polling', () async {
      final result = await pollWith({'unexpected': true});
      expect(
        result.dataOrNull!.outcome,
        MultipartFinalizeOutcome.transientError,
      );
    });

    test('error envelope 121026 resolves to uploadInvalid', () async {
      final repo = FileUploadRepositoryImpl(
        _EnvelopeFailureApi(MultipartUploadErrorCodes.multipartUploadInvalid, 'MULTIPART_UPLOAD_INVALID'),
      );

      final result = await repo.pollCompleteStatus(
        uploadSessionId: session,
        objectKey: objectKey,
        uploadId: uploadId,
      );

      expect(
        result.dataOrNull!.outcome,
        MultipartFinalizeOutcome.uploadInvalid,
      );
    });

    test('error envelope 100500 resolves to transientError', () async {
      final repo = FileUploadRepositoryImpl(
        _EnvelopeFailureApi(MultipartUploadErrorCodes.systemError, 'SYSTEM_ERROR'),
      );

      final result = await repo.pollCompleteStatus(
        uploadSessionId: session,
        objectKey: objectKey,
        uploadId: uploadId,
      );

      expect(
        result.dataOrNull!.outcome,
        MultipartFinalizeOutcome.transientError,
      );
    });

    test('other business failures pass through as failures', () async {
      final failureApi = _EnvelopeFailureApi(121013, 'FILE_SIZE_EXCEEDED');
      final repo = FileUploadRepositoryImpl(failureApi);

      final result = await repo.pollCompleteStatus(
        uploadSessionId: session,
        objectKey: objectKey,
        uploadId: uploadId,
      );

      expect(result.isFailure, isTrue);
      final error = result.errorOrNull;
      expect(error, isA<BusinessError>());
      expect((error as BusinessError).code, 121013);
    });
  });

  test('abortMultipart posts the identity triple with retry', () async {
    api.postHandlers['/api/mini-drama/creator/uploads/multipart/abort'] =
        (_) => <String, dynamic>{};

    final result = await repository.abortMultipart(
      uploadSessionId: session,
      objectKey: objectKey,
      uploadId: uploadId,
    );

    expect(result.isSuccess, isTrue);
    final call = api.calls.single;
    expect(call.retry, isTrue);
    expect(
      call.body,
      {'uploadSessionId': session, 'objectKey': objectKey, 'uploadId': uploadId},
    );
  });
}

/// Dedicated fake returning a failure envelope from safeGet.
class _EnvelopeFailureApi extends StoryApiClient {
  _EnvelopeFailureApi(this.code, this.message)
      : super(baseUrl: 'https://test.api/v1/', maxRetries: 0);

  final int code;
  final String message;

  @override
  Future<Result<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic data) decoder,
  }) async => Result.failure(ApiError.business(code, message));
}
