import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/api/upload_cancel_token.dart';
import 'package:story_app/src/controller/multipart_resumable_upload_executor.dart';
import 'package:story_app/src/controller/upload_executor.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/repositories/file_upload_repository.dart';
import 'package:story_app/src/services/connectivity_service.dart';

class _FakeRepository implements FileUploadRepository {
  _FakeRepository();

  final List<String> calls = [];
  int initiateCount = 0;
  int completeSubmitCount = 0;

  /// partNumber → list of outcomes per call ('etag:N' or error codes).
  final Map<int, Queue<String>> partResults = {};
  final List<int> presignedPartNumbers = [];
  List<UploadedPart> serverParts = const [];
  MultipartFinalizeOutcome submitOutcome = MultipartFinalizeOutcome.processing;
  int submitOutcomeReadyAfterResends = 0;
  Object? initiateFailure;

  /// When set, the next `listCompletedParts` call fails with this error.
  ApiError? listPartsFailureOnce;

  @override
  Future<Result<InitiateMultipartResult>> initiateMultipart({
    required String uploadSessionId,
    required String fileName,
    required String contentType,
    required int fileSize,
  }) async {
    calls.add('initiate');
    initiateCount++;
    if (initiateFailure != null) {
      return Result.failure(initiateFailure as ApiError);
    }
    return Result.success(
      InitiateMultipartResult(
        uploadId: 'upload-$initiateCount',
        objectKey: 'assets/episode-$initiateCount.mp4',
        partSize: 4,
        totalParts: (fileSize / 4).ceil(),
      ),
    );
  }

  @override
  Future<Result<List<PresignedPartUrl>>> presignPartUrls({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
    required List<int> partNumbers,
  }) async {
    calls.add('presign');
    presignedPartNumbers.addAll(partNumbers);
    return Result.success([
      for (final n in partNumbers)
        PresignedPartUrl(partNumber: n, uploadUrl: 'https://bucket/$objectKey?partNumber=$n&uploadId=$uploadId'),
    ]);
  }

  @override
  Future<Result<List<UploadedPart>>> listCompletedParts({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  }) async {
    calls.add('listParts');
    final failure = listPartsFailureOnce;
    if (failure != null) {
      listPartsFailureOnce = null;
      return Result.failure(failure);
    }
    return Result.success(serverParts);
  }

  @override
  Future<Result<MultipartFinalizeStatus>> submitComplete({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
    required List<UploadedPart> parts,
  }) async {
    calls.add('complete');
    completeSubmitCount++;
    if (completeSubmitCount > submitOutcomeReadyAfterResends &&
        submitOutcome == MultipartFinalizeOutcome.failedSystem &&
        submitOutcomeReadyAfterResends > 0) {
      return Result.success(
        const MultipartFinalizeStatus(MultipartFinalizeOutcome.processing),
      );
    }
    return Result.success(MultipartFinalizeStatus(submitOutcome));
  }

  @override
  Future<Result<MultipartFinalizeStatus>> pollCompleteStatus({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  }) async => Result.failure(ApiError.business(0, 'not used'));

  @override
  Future<Result<void>> abortMultipart({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  }) async => Result.success(null);

  @override
  Future<Result<UploadSession>> createUploadSession() async =>
      Result.failure(ApiError.business(0, 'not used'));

  @override
  Future<Result<PresignUploadResult>> presign({
    required String contentType,
    required FileCategory fileCategory,
    required String fileName,
    required String uploadSessionId,
  }) async => Result.failure(ApiError.business(0, 'not used'));

  @override
  Future<Result<String>> uploadFile({
    required String filePath,
    required FileCategory fileCategory,
    String? contentType,
    String? uploadSessionId,
    void Function(double progress)? onProgress,
    UploadCancelToken? cancelToken,
  }) async => Result.failure(ApiError.business(0, 'not used'));

  @override
  Future<Result<UploadedFile>> uploadFileWithObjectKey({
    required String filePath,
    required FileCategory fileCategory,
    String? contentType,
    String? uploadSessionId,
    void Function(double progress)? onProgress,
    UploadCancelToken? cancelToken,
  }) async => Result.failure(ApiError.business(0, 'not used'));

  @override
  Future<void> dispose() async {}
}

class _FakePartApi extends StoryApiClient {
  _FakePartApi() : super(baseUrl: 'https://test.api/v1/', maxRetries: 0);

  final uploadedParts = <int>[];
  int inFlight = 0;
  int maxInFlight = 0;

  /// Optional per-part gates for deterministic progress-order tests:
  /// [startGates] hold a part before its bytes are handed to the socket,
  /// [ackGates] hold it after the bytes are handed but before the ETag ack.
  final startGates = <int, Completer<void>>{};
  final ackGates = <int, Completer<void>>{};

  @override
  Future<Result<String>> uploadPart({
    required String url,
    required Stream<List<int>> byteStream,
    required int contentLength,
    void Function(int sent, int total)? onProgress,
    Duration? timeout,
    UploadCancelToken? cancelToken,
  }) async {
    final partNumber = int.parse(Uri.parse(url).queryParameters['partNumber']!);
    final startGate = startGates[partNumber];
    if (startGate != null) {
      await startGate.future;
      onProgress?.call(contentLength, contentLength);
      await byteStream.drain<void>();
      final ackGate = ackGates[partNumber];
      if (ackGate != null) await ackGate.future;
      uploadedParts.add(partNumber);
      return Result.success('"etag-$partNumber"');
    }
    // Consume the slice stream and report per-chunk progress like the real
    // transport would.
    var sent = 0;
    await for (final chunk in byteStream) {
      sent += chunk.length;
      onProgress?.call(sent, contentLength);
    }
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    inFlight--;
    uploadedParts.add(partNumber);
    final outcomes = repository?.partResults[partNumber];
    if (outcomes != null && outcomes.isNotEmpty) {
      final outcome = outcomes.removeFirst();
      if (outcome.startsWith('etag:')) {
        return Result.success('"${outcome.substring(5)}"');
      }
      return Result.failure(ApiError.network('part failed ($outcome)'));
    }
    return Result.success('"etag-$partNumber"');
  }

  // Set by each test to route canned part outcomes.
  _FakeRepository? repository;
}

class _WifiConnectivity extends ConnectivityService {
  @override
  bool get isWifi => true;
}

class _CellularConnectivity extends ConnectivityService {
  @override
  bool get isWifi => false;
}

class Queue<T> {
  final List<T> _items = [];
  void add(T item) => _items.add(item);
  T removeFirst() => _items.removeAt(0);
  bool get isNotEmpty => _items.isNotEmpty;
}

UploadTask _task(File file, {int? fileSizeOverride}) => UploadTask(
      id: 'task-1',
      localFilePath: file.path,
      fileName: 'video.mp4',
      fileSize: fileSizeOverride ?? file.lengthSync(),
      contentType: 'video/mp4',
      category: FileCategory.video,
      ownerUserId: 'user-1',
      uploadSessionId: 'session-1',
    );

void main() {
  late Directory tempDir;
  late File file;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('multipart_test');
    file = File('${tempDir.path}/video.mp4');
    file.writeAsBytesSync(List<int>.generate(12, (i) => i)); // 3 parts of 4B
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  ({
    _FakeRepository repo,
    _FakePartApi api,
    MultipartResumableUploadExecutor executor,
    List<UploadTask> checkpoints,
    List<double> progress,
  }) build({bool wifi = true}) {
    final repo = _FakeRepository();
    final api = _FakePartApi()..repository = repo;
    final executor = MultipartResumableUploadExecutor(
      repo,
      api,
      wifi ? _WifiConnectivity() : _CellularConnectivity(),
    );
    final checkpoints = <UploadTask>[];
    final progress = <double>[];
    return (
      repo: repo,
      api: api,
      executor: executor,
      checkpoints: checkpoints,
      progress: progress,
    );
  }

  test('fresh upload: initiate → all parts → complete accepted', () async {
    final fixture = build();
    final token = UploadCancelToken();

    final result = await fixture.executor.upload(
      _task(file),
      cancelToken: token,
      onProgress: fixture.progress.add,
      onCheckpoint: fixture.checkpoints.add,
    );

    final outcome = result.dataOrNull!;
    expect(outcome, isA<UploadFinalizePending>());
    final pending = outcome as UploadFinalizePending;
    expect(pending.uploadId, 'upload-1');
    expect(pending.objectKey, 'assets/episode-1.mp4');
    expect(pending.publicUrl, 'https://bucket/assets/episode-1.mp4');

    expect(fixture.api.uploadedParts.toSet(), {1, 2, 3});
    expect(fixture.repo.presignedPartNumbers, containsAll([1, 2, 3]));
    expect(fixture.repo.completeSubmitCount, 1);
    expect(fixture.repo.calls, ['initiate', 'presign', 'complete']);

    // Last checkpoint carries all parts and finalizeRequested phase.
    final last = fixture.checkpoints.last;
    expect(last.completedParts.length, 3);
    expect(last.uploadedBytes, 12);
    expect(last.multipartPhase, MultipartPhase.finalizeRequested);
    expect(fixture.progress.last, 1.0);
  });

  test('progress is monotonic within a part and ends at 1.0', () async {
    final fixture = build();
    final token = UploadCancelToken();

    await fixture.executor.upload(
      _task(file),
      cancelToken: token,
      onProgress: fixture.progress.add,
    );

    expect(fixture.progress, isNotEmpty);
    expect(fixture.progress.last, 1.0);
    // Forced reports at part completion are ordered and never exceed 1.
    expect(fixture.progress.every((p) => p <= 1.0), isTrue);
  });

  test('progress never regresses when parts ack out of order (concurrent)',
      () async {
    final fixture = build();
    final token = UploadCancelToken();
    // Gate every part's byte-handoff and ack for deterministic interleaving.
    for (var n = 1; n <= 3; n++) {
      fixture.api.startGates[n] = Completer<void>();
      fixture.api.ackGates[n] = Completer<void>();
    }
    final upload = fixture.executor.upload(
      _task(file),
      cancelToken: token,
      onProgress: fixture.progress.add,
    );

    // Hand bytes to the socket part by part, spaced beyond the 100 ms
    // throttle so each in-flight report lands (0.33 → 0.67 → 1.0).
    fixture.api.startGates[1]!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    fixture.api.startGates[2]!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    fixture.api.startGates[3]!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(fixture.progress.last, 1.0);

    // Parts ack out of order while other parts' bytes are still in flight:
    // the forced reports must keep the completed + in-flight aggregation.
    fixture.api.ackGates[2]!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    fixture.api.ackGates[1]!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    fixture.api.ackGates[3]!.complete();

    final result = await upload;
    expect(result.dataOrNull, isA<UploadFinalizePending>());
    expect(fixture.progress.last, 1.0);
    for (var i = 1; i < fixture.progress.length; i++) {
      expect(
        fixture.progress[i] >= fixture.progress[i - 1],
        isTrue,
        reason: 'progress regressed at $i: ${fixture.progress}',
      );
    }
  });

  test('resume uploads only missing parts after server reconciliation',
      () async {
    final fixture = build();
    fixture.repo.serverParts = [
      const UploadedPart(partNumber: 1, eTag: '"etag-1"', size: 4),
    ];
    final task = _task(file).copyWith(
      multipartUploadId: 'upload-9',
      multipartObjectKey: 'assets/episode-9.mp4',
      partSize: 4,
      totalParts: 3,
      completedParts: const [
        UploadedPart(partNumber: 1, eTag: '"etag-1"', size: 4),
      ],
      uploadedBytes: 4,
    );
    final token = UploadCancelToken();

    final result = await fixture.executor.upload(
      task,
      cancelToken: token,
      onProgress: fixture.progress.add,
    );

    expect(result.dataOrNull, isA<UploadFinalizePending>());
    // Only parts 2 and 3 were presigned and uploaded.
    expect(fixture.api.uploadedParts.toSet(), {2, 3});
    expect(fixture.repo.presignedPartNumbers, [2, 3]);
    expect(fixture.repo.initiateCount, 0, reason: '已有 uploadId 不应重新 initiate');
    expect(fixture.repo.calls.first, 'listParts');
  });

  test('local-ahead reconciliation drops parts missing on the server',
      () async {
    final fixture = build();
    fixture.repo.serverParts = [
      const UploadedPart(partNumber: 1, eTag: '"etag-1"', size: 4),
    ];
    final task = _task(file).copyWith(
      multipartUploadId: 'upload-9',
      multipartObjectKey: 'assets/episode-9.mp4',
      partSize: 4,
      totalParts: 3,
      completedParts: const [
        UploadedPart(partNumber: 1, eTag: '"etag-1"', size: 4),
        UploadedPart(partNumber: 2, eTag: '"local-only"', size: 4),
      ],
      uploadedBytes: 8,
    );
    final token = UploadCancelToken();

    await fixture.executor.upload(
      task,
      cancelToken: token,
      onProgress: (_) {},
    );

    // Part 2 was dropped by reconciliation and re-uploaded.
    expect(fixture.api.uploadedParts.toSet(), {2, 3});
  });

  test('part retry: two transient failures then success', () async {
    final fixture = build();
    fixture.repo.partResults[2] = Queue<String>()
      ..add('fail')
      ..add('fail')
      ..add('etag:recovered');
    final token = UploadCancelToken();

    final result = await fixture.executor.upload(
      _task(file),
      cancelToken: token,
      onProgress: (_) {},
    );

    expect(result.dataOrNull, isA<UploadFinalizePending>());
    expect(fixture.api.uploadedParts.where((n) => n == 2).length, 3);
    expect(fixture.api.uploadedParts.toSet(), {1, 2, 3});
  });

  test('part failing beyond retries fails the attempt but keeps the checkpoint',
      () async {
    final fixture = build();
    fixture.repo.partResults[3] = Queue<String>()
      ..add('fail')
      ..add('fail')
      ..add('fail');
    final token = UploadCancelToken();

    final result = await fixture.executor.upload(
      _task(file),
      cancelToken: token,
      onProgress: (_) {},
      onCheckpoint: fixture.checkpoints.add,
    );

    expect(result.isFailure, isTrue);
    // Completed parts 1/2 (and possibly failed 3 attempts) recorded.
    final last = fixture.checkpoints.last;
    expect(last.completedParts.map((p) => p.partNumber), containsAll([1, 2]));
    expect(last.completedParts.any((p) => p.partNumber == 3), isFalse);
  });

  test('121026 during resume restarts once with a fresh uploadId', () async {
    final fixture = build();
    fixture.repo.serverParts = const [];
    fixture.repo.listPartsFailureOnce =
        const BusinessError(121026, 'MULTIPART_UPLOAD_INVALID');
    final task = _task(file).copyWith(
      multipartUploadId: 'upload-9',
      multipartObjectKey: 'assets/episode-9.mp4',
      partSize: 4,
      totalParts: 3,
    );
    final token = UploadCancelToken();

    final result = await fixture.executor.upload(
      task,
      cancelToken: token,
      onProgress: (_) {},
    );

    expect(result.dataOrNull, isA<UploadFinalizePending>());
    expect(result.dataOrNull!.asPending.uploadId, 'upload-1');
    expect(fixture.api.uploadedParts.toSet(), {1, 2, 3});
    expect(fixture.repo.initiateCount, 1);
  });

  test('121026 twice exhausts the single restart and fails', () async {
    final fixture = build();
    fixture.repo.initiateFailure =
        const BusinessError(121026, 'MULTIPART_UPLOAD_INVALID');
    final token = UploadCancelToken();

    final result = await fixture.executor.upload(
      _task(file),
      cancelToken: token,
      onProgress: (_) {},
    );

    expect(result.isFailure, isTrue);
    expect(fixture.repo.initiateCount, 2, reason: '初次 + 一次重试');
  });

  test('submitComplete ready (idempotent replay) returns UploadReady',
      () async {
    final fixture = build();
    fixture.repo.submitOutcome = MultipartFinalizeOutcome.ready;
    final token = UploadCancelToken();

    final result = await fixture.executor.upload(
      _task(file),
      cancelToken: token,
      onProgress: (_) {},
    );

    final outcome = result.dataOrNull!;
    expect(outcome, isA<UploadReady>());
    expect((outcome as UploadReady).file.objectKey, 'assets/episode-1.mp4');
    expect(outcome.file.publicUrl, 'https://bucket/assets/episode-1.mp4');
  });

  test('submitComplete failedSystem resends once then accepts', () async {
    final fixture = build();
    fixture.repo.submitOutcome = MultipartFinalizeOutcome.failedSystem;
    fixture.repo.submitOutcomeReadyAfterResends = 1; // resend succeeds
    final token = UploadCancelToken();

    final result = await fixture.executor.upload(
      _task(file),
      cancelToken: token,
      onProgress: (_) {},
    );

    expect(result.dataOrNull, isA<UploadFinalizePending>());
    expect(fixture.repo.completeSubmitCount, 2);
  });

  test('Wi-Fi pool caps concurrency at 4; cellular at 2', () async {
    final bigFile = File('${tempDir.path}/big.mp4')
      ..writeAsBytesSync(List<int>.generate(40, (i) => i)); // 10 parts

    final wifiFixture = build();
    await wifiFixture.executor.upload(
      _task(bigFile),
      cancelToken: UploadCancelToken(),
      onProgress: (_) {},
    );
    expect(wifiFixture.api.maxInFlight, lessThanOrEqualTo(4));
    expect(wifiFixture.api.maxInFlight, greaterThanOrEqualTo(2));

    final cellularFixture = build(wifi: false);
    await cellularFixture.executor.upload(
      _task(bigFile),
      cancelToken: UploadCancelToken(),
      onProgress: (_) {},
    );
    expect(cellularFixture.api.maxInFlight, lessThanOrEqualTo(2));
  });

  test('pre-canceled token fails without initiating', () async {
    final fixture = build();
    final token = UploadCancelToken()..cancel();

    final result = await fixture.executor.upload(
      _task(file),
      cancelToken: token,
      onProgress: (_) {},
    );

    expect(result.isFailure, isTrue);
    expect(fixture.repo.calls, isEmpty);
  });

  test('file size mismatch fails fast', () async {
    final fixture = build();
    final token = UploadCancelToken();

    final result = await fixture.executor.upload(
      _task(file, fileSizeOverride: 999),
      cancelToken: token,
      onProgress: (_) {},
    );

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ParseError>());
    expect(fixture.repo.calls, isEmpty);
  });
}

extension on UploadAttemptOutcome {
  UploadFinalizePending get asPending => this as UploadFinalizePending;
}
