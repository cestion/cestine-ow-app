import 'dart:collection';
import 'dart:io';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/api/upload_cancel_token.dart';
import 'package:story_app/src/controller/upload_coordinator.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/upload_failure.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/file_upload_repository.dart';
import 'package:story_app/src/services/connectivity_service.dart';
import 'package:story_app/src/data/repository/story_local_repository_impl.dart';

class _ScriptedMultipartExecutor implements UploadExecutor {
  @override
  bool get supportsBackground => false;

  @override
  bool get supportsResume => true;

  Future<Result<UploadAttemptOutcome>> Function(
    UploadTask task,
    UploadCancelToken cancelToken,
    void Function(double progress) onProgress,
    MultipartCheckpointSink? onCheckpoint,
  )? behavior;

  final List<UploadTask> startedTasks = [];

  @override
  Future<Result<UploadAttemptOutcome>> upload(
    UploadTask task, {
    required UploadCancelToken cancelToken,
    required void Function(double progress) onProgress,
    MultipartCheckpointSink? onCheckpoint,
  }) async {
    startedTasks.add(task);
    final script = behavior;
    if (script == null) {
      return Result.success(_pendingOutcome(task));
    }
    return script(task, cancelToken, onProgress, onCheckpoint);
  }
}

class _ScriptedSinglePutExecutor implements UploadExecutor {
  _ScriptedSinglePutExecutor();

  @override
  bool get supportsBackground => false;

  @override
  bool get supportsResume => false;

  Result<UploadAttemptOutcome> result =
      Result.success(const UploadReady(UploadedFile(objectKey: 'ok', publicUrl: 'https://b/ok')));

  final List<UploadTask> startedTasks = [];

  @override
  Future<Result<UploadAttemptOutcome>> upload(
    UploadTask task, {
    required UploadCancelToken cancelToken,
    required void Function(double progress) onProgress,
    MultipartCheckpointSink? onCheckpoint,
  }) async {
    startedTasks.add(task);
    onProgress(0.5);
    return result;
  }
}

class _FakeConnectivity extends ConnectivityService {
  bool wifi = true;

  @override
  bool get isWifi => value && wifi;

  @override
  ConnectionType get connectionType =>
      !value ? ConnectionType.other : (wifi ? ConnectionType.wifi : ConnectionType.cellular);

  void goOffline() => value = false;

  void goOnline({required bool toWifi}) {
    wifi = toWifi;
    value = true;
    if (wifi == false) notifyListeners();
  }

  void switchToCellular() {
    wifi = false;
    // Type-only change: the production service notifies explicitly for this.
    notifyListeners();
  }
}

class _FakeGatewayRepo implements FileUploadRepository {
  final List<String> calls = [];
  final Queue<MultipartFinalizeStatus> pollStatuses = Queue();
  MultipartFinalizeStatus nextPoll =
      const MultipartFinalizeStatus(MultipartFinalizeOutcome.processing);
  int submitCount = 0;
  int abortCount = 0;

  @override
  Future<Result<MultipartFinalizeStatus>> pollCompleteStatus({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  }) async {
    calls.add('poll:$uploadId');
    if (pollStatuses.isNotEmpty) return Result.success(pollStatuses.removeFirst());
    return Result.success(nextPoll);
  }

  @override
  Future<Result<MultipartFinalizeStatus>> submitComplete({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
    required List<UploadedPart> parts,
  }) async {
    submitCount++;
    return Result.success(
      const MultipartFinalizeStatus(MultipartFinalizeOutcome.processing),
    );
  }

  @override
  Future<Result<void>> abortMultipart({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  }) async {
    abortCount++;
    return Result.success(null);
  }

  @override
  Future<Result<InitiateMultipartResult>> initiateMultipart({
    required String uploadSessionId,
    required String fileName,
    required String contentType,
    required int fileSize,
  }) async => Result.failure(ApiError.business(0, 'not used'));

  @override
  Future<Result<List<PresignedPartUrl>>> presignPartUrls({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
    required List<int> partNumbers,
  }) async => Result.failure(ApiError.business(0, 'not used'));

  @override
  Future<Result<List<UploadedPart>>> listCompletedParts({
    required String uploadSessionId,
    required String objectKey,
    required String uploadId,
  }) async => Result.failure(ApiError.business(0, 'not used'));

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

class _NoopApi extends StoryApiClient {
  _NoopApi() : super(baseUrl: 'https://test.api/v1/', maxRetries: 0);
}

class _TestCoordinator extends UploadCoordinator {
  _TestCoordinator(this._singlePut, this._multipart);

  final UploadExecutor _singlePut;
  final UploadExecutor _multipart;

  @override
  UploadExecutor createSinglePutExecutor(FileUploadRepository repository) =>
      _singlePut;

  @override
  UploadExecutor createMultipartExecutor(
    FileUploadRepository repository,
    StoryApiClient api,
    ConnectivityService connectivity,
  ) => _multipart;
}

UploadFinalizePending _pendingOutcome(UploadTask task) =>
    UploadFinalizePending(
      uploadSessionId: task.uploadSessionId,
      uploadId: task.multipartUploadId ?? 'upload-x',
      objectKey: task.multipartObjectKey ?? 'key-x',
      publicUrl: 'https://bucket/key-x',
    );

Future<Result<UploadAttemptOutcome>> hangUntilCanceled(
  UploadCancelToken token,
) async {
  while (!token.isCanceled) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  return Result.failure(
    ApiError.unknown(
      'Upload canceled',
      exception: const UploadCanceledException(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late File bigFile; // ≥ multipart threshold (10MB)
  late File smallFile;

  setUpAll(() {
    tempRoot = Directory.systemTemp.createTempSync('coordinator_p4');
    bigFile = File('${tempRoot.path}/big.mp4')
      ..writeAsBytesSync(List<int>.filled(11 * 1024 * 1024, 1));
    smallFile = File('${tempRoot.path}/small.mp4')
      ..writeAsBytesSync(List<int>.filled(1024, 1));
  });

  tearDownAll(() {
    tempRoot.deleteSync(recursive: true);
  });

  UploadTask videoTask(
    File file, {
    String id = 'task-1',
    String session = 'session-1',
  }) =>
      UploadTask(
        id: id,
        localFilePath: file.path,
        fileName: 'video.mp4',
        fileSize: file.lengthSync(),
        contentType: 'video/mp4',
        category: FileCategory.video,
        ownerUserId: 'user-1',
        uploadSessionId: session,
      );

  Future<({
    ProviderContainer container,
    UploadCoordinator coordinator,
    _FakeGatewayRepo repo,
    _ScriptedMultipartExecutor multipart,
    _ScriptedSinglePutExecutor singlePut,
    _FakeConnectivity connectivity,
    Box<dynamic> box,
  })> setUpCoordinator({
    Future<void> Function(Box<dynamic>)? seedBox,
  }) async {
    final dir = Directory.systemTemp.createTempSync('coordinator_hive');
    Hive.init(dir.path);
    if (seedBox != null) {
      // Seeding must finish before the repository opens the box.
      final seeded = await Hive.openBox<dynamic>('story_local_cache');
      await seedBox(seeded);
      await seeded.close();
    }
    final localRepo = StoryLocalRepositoryImpl();
    await localRepo.init();

    final repo = _FakeGatewayRepo();
    final multipart = _ScriptedMultipartExecutor();
    final singlePut = _ScriptedSinglePutExecutor();
    final connectivity = _FakeConnectivity();
    final coordinator = _TestCoordinator(singlePut, multipart);
    final container = ProviderContainer(
      overrides: [
        localRepositoryProvider.overrideWith((ref) => localRepo),
        fileUploadRepositoryProvider.overrideWith((ref) => repo),
        apiClientProvider.overrideWith((ref) => _NoopApi()),
        connectivityProvider.overrideWith((ref) => connectivity),
        currentUserIdProvider.overrideWith((ref) => 'user-1'),
        uploadCoordinatorProvider.overrideWith(() => coordinator),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });
    // Touch the provider so build() runs.
    container.read(uploadCoordinatorProvider.notifier);
    return (
      container: container,
      coordinator: coordinator,
      repo: repo,
      multipart: multipart,
      singlePut: singlePut,
      connectivity: connectivity,
      box: localRepo.cacheBox,
    );
  }

  /// Lets the pump start, run scripted behaviors, persist to Hive and fire
  /// immediate poll timers without racing the pump's async start.
  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  test('routing: big video → multipart, small video → single-PUT', () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;

    await f.coordinator.enqueue(videoTask(bigFile, id: 'big'));
    await f.coordinator.enqueue(videoTask(smallFile, id: 'small'));
    await settle();

    expect(f.multipart.startedTasks.map((t) => t.id), ['big']);
    expect(f.singlePut.startedTasks.map((t) => t.id), ['small']);
  });

  test('multipart failure keeps the breakpoint and retry preserves it',
      () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    final fileSize = bigFile.lengthSync();
    f.multipart.behavior = (task, token, onProgress, onCheckpoint) async {
      onCheckpoint?.call(
        task.copyWith(
          multipartUploadId: 'u1',
          multipartObjectKey: 'key-1',
          partSize: 4,
          totalParts: 3,
          completedParts: const [
            UploadedPart(partNumber: 1, eTag: '"a"', size: 4),
          ],
          uploadedBytes: 4,
          multipartPhase: MultipartPhase.partsUploading,
        ),
      );
      // Non-retryable business failure → straight to failed.
      return Result.failure(const BusinessError(999, 'rejected'));
    };

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await settle();

    final failed = f.coordinator.state[task.id]!;
    expect(failed.status, UploadTaskStatus.failed);
    expect(failed.completedParts.length, 1, reason: '失败保留分片断点');
    expect(failed.progress, closeTo(4 / fileSize, 0.001));
    expect(failed.multipartUploadId, 'u1');

    await f.coordinator.retry(task.id);
    await settle();

    final retried = f.coordinator.state[task.id]!;
    expect(f.multipart.startedTasks.length, 2, reason: '断点重试重新执行');
    expect(retried.completedParts.length, 1, reason: '重试后断点仍在');
    expect(retried.status, UploadTaskStatus.failed);
  });

  test('single-PUT failure still resets progress to zero (regression guard)',
      () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.singlePut.result =
        Result.failure(const BusinessError(999, 'rejected'));

    final task = videoTask(smallFile);
    await f.coordinator.enqueue(task);
    await settle();

    final failed = f.coordinator.state[task.id]!;
    expect(failed.status, UploadTaskStatus.failed);
    expect(failed.progress, 0);
  });

  test('manual pause keeps the breakpoint; resume re-runs from it', () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.multipart.behavior = (task, token, onProgress, onCheckpoint) async {
      if (f.multipart.startedTasks.length == 1) {
        onCheckpoint?.call(
          task.copyWith(
            multipartUploadId: 'u1',
            multipartObjectKey: 'key-1',
            partSize: 4,
            totalParts: 3,
            completedParts: const [
              UploadedPart(partNumber: 1, eTag: '"a"', size: 4),
            ],
            uploadedBytes: 4,
            multipartPhase: MultipartPhase.partsUploading,
          ),
        );
        onProgress(0.35);
      }
      return hangUntilCanceled(token);
    };

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await f.coordinator.pauseTask(task.id);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final paused = f.coordinator.state[task.id]!;
    expect(paused.status, UploadTaskStatus.paused);
    // 持久断点：已完成分片保留（续传依据）。
    expect(paused.completedParts.length, 1);
    // 显示层：保留现场进度（max(现场, 边界)），不再回退到边界值。
    expect(paused.progress, closeTo(0.35, 0.001));

    await f.coordinator.resumeTask(task.id);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final resumed = f.coordinator.state[task.id]!;
    expect(resumed.status, UploadTaskStatus.uploading);
    expect(f.multipart.startedTasks.length, 2);
    expect(resumed.completedParts.length, 1, reason: '续传仍带断点');
  });

  test('pause keeps the live display progress even with no acked parts',
      () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    // 并发分片下 40% 的显示几乎全是在途字节：没有任何分片 ACK。
    f.multipart.behavior =
        (task, token, onProgress, onCheckpoint) async {
      onProgress(0.40);
      return hangUntilCanceled(token);
    };

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(f.coordinator.state[task.id]!.progress, closeTo(0.40, 0.001));

    await f.coordinator.pauseTask(task.id);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final paused = f.coordinator.state[task.id]!;
    expect(paused.status, UploadTaskStatus.paused);
    expect(
      paused.progress,
      closeTo(0.40, 0.001),
      reason: '暂停保留现场显示进度（持久边界为 0 也不能跳 0%）',
    );
    expect(paused.completedParts, isEmpty);
  });

  test('resume moves the bar immediately via the affine catch-up mapping',
      () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    var calls = 0;
    f.multipart.behavior = (task, token, onProgress, onCheckpoint) {
      calls++;
      if (calls == 1) {
        // 暂停时 40% 全部是在途字节（无 ACK 分片，持久边界 B=0）。
        onProgress(0.40);
        return hangUntilCanceled(token);
      }
      // 恢复后重新交接的字节：raw 从低位重新累积。
      onProgress(0.05);
      return hangUntilCanceled(token);
    };

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await f.coordinator.pauseTask(task.id);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(f.coordinator.state[task.id]!.progress, closeTo(0.40, 0.001));

    await f.coordinator.resumeTask(task.id);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final resumed = f.coordinator.state[task.id]!;
    expect(resumed.status, UploadTaskStatus.uploading);
    // D=0.40, B=0 → display = 0.40 + 0.05×0.60 = 0.43：
    // 重传字节立刻推动进度条，既不回跳也不冻结。
    expect(
      resumed.progress,
      closeTo(0.43, 0.001),
      reason: '仿射映射：恢复后进度条立即从保留值继续移动',
    );

    // raw 继续增长时显示持续爬升，raw=1 精确对齐 100%。
    await f.coordinator.pauseTask(task.id);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    f.multipart.behavior = (task, token, onProgress, onCheckpoint) {
      onProgress(0.42);
      return hangUntilCanceled(token);
    };
    await f.coordinator.resumeTask(task.id);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // 重新锚定：D=0.43, B=0 → display = 0.43 + 0.42×0.57 = 0.6694。
    expect(
      f.coordinator.state[task.id]!.progress,
      closeTo(0.43 + 0.42 * 0.57, 0.001),
      reason: '连续暂停/恢复迭代下映射自洽且单调',
    );
  });

  test('finalize pending → merge poll READY → success', () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.repo.nextPoll = const MultipartFinalizeStatus(
      MultipartFinalizeOutcome.ready,
      objectKey: 'key-x',
    );

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    // The immediate poll resolves READY within the settle window; the mid
    // merging phase is asserted via the poller's call trail below instead.
    await settle();

    final done = f.coordinator.state[task.id]!;
    expect(done.status, UploadTaskStatus.success);
    expect(done.objectKey, 'key-x');
    expect(done.publicUrl, 'https://bucket/key-x');
    expect(done.multipartUploadId, null, reason: '成功后清理分片字段');
    expect(f.repo.calls, contains('poll:upload-x'));
  });

  test('merge poll FAILED+100500 resends complete once, then succeeds',
      () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.coordinator.pollInterval = const Duration(milliseconds: 20);
    f.repo.pollStatuses.addAll([
      const MultipartFinalizeStatus(
        MultipartFinalizeOutcome.failedSystem,
        errorCode: 100500,
      ),
      const MultipartFinalizeStatus(MultipartFinalizeOutcome.ready),
    ]);

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await settle();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(f.repo.submitCount, 1, reason: '幂等重发一次 complete');
    expect(f.coordinator.state[task.id]!.status, UploadTaskStatus.success);
  });

  test('merge poll uploadInvalid(121026) requeues with a clean checkpoint',
      () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.repo.pollStatuses.add(
      const MultipartFinalizeStatus(
        MultipartFinalizeOutcome.uploadInvalid,
        errorCode: 121026,
      ),
    );
    var calls = 0;
    f.multipart.behavior = (task, token, onProgress, onCheckpoint) {
      calls++;
      if (calls == 1) {
        return Future.value(Result.success(_pendingOutcome(task)));
      }
      return hangUntilCanceled(token);
    };

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await settle();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final requeued = f.coordinator.state[task.id]!;
    expect(requeued.multipartUploadId, null, reason: '分片记录已清零');
    expect(f.multipart.startedTasks.length, 2, reason: '全片重新上传');
  });

  test('merge poll timeout fails with progress kept at 100%', () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.coordinator.pollInterval = const Duration(milliseconds: 20);
    f.coordinator.pollTimeout = Duration.zero;

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await settle();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final failed = f.coordinator.state[task.id]!;
    expect(failed.status, UploadTaskStatus.failed);
    expect(failed.progress, 1);
    expect(
      UploadFailure.tryParse(failed.lastError)?.kind,
      UploadFailureKind.timeout,
    );

    // 继续上传 → 重新进入轮询而非重传分片。
    f.coordinator.pollTimeout = const Duration(minutes: 2);
    f.repo.nextPoll = const MultipartFinalizeStatus(
      MultipartFinalizeOutcome.ready,
    );
    await f.coordinator.retry(task.id);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(f.coordinator.state[task.id]!.status, UploadTaskStatus.success);
    expect(f.multipart.startedTasks.length, 1, reason: '未重传任何分片');
  });

  test('offline → uploading keeps status + networkWait; wifi restore auto-continues',
      () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.multipart.behavior =
        (task, token, onProgress, onCheckpoint) => hangUntilCanceled(token);

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    f.connectivity.goOffline();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final waiting = f.coordinator.state[task.id]!;
    expect(waiting.status, UploadTaskStatus.uploading);
    expect(waiting.networkWait, isTrue);

    f.connectivity.goOnline(toWifi: true);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final resumed = f.coordinator.state[task.id]!;
    expect(resumed.status, UploadTaskStatus.uploading);
    expect(resumed.networkWait, isFalse);
    expect(f.multipart.startedTasks.length, 2, reason: '断点续传重新执行');
  });

  test('offline → cellular restore parks paused + raises confirmation', () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.multipart.behavior =
        (task, token, onProgress, onCheckpoint) => hangUntilCanceled(token);

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    f.connectivity.goOffline();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    f.connectivity.goOnline(toWifi: false);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final paused = f.coordinator.state[task.id]!;
    expect(paused.status, UploadTaskStatus.paused);
    expect(f.coordinator.pendingCellularConfirmations, contains('session-1'));

    // 确认 → 从断点继续。
    await f.coordinator.confirmCellularUpload('session-1', accepted: true);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(f.coordinator.state[task.id]!.status, UploadTaskStatus.uploading);
    expect(f.multipart.startedTasks.length, 2);
    expect(f.coordinator.pendingCellularConfirmations, isEmpty);
  });

  test('cellular confirmation rejected → stays paused; manual resume bypasses',
      () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.multipart.behavior =
        (task, token, onProgress, onCheckpoint) => hangUntilCanceled(token);

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    f.connectivity.goOffline();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    f.connectivity.goOnline(toWifi: false);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    await f.coordinator.confirmCellularUpload('session-1', accepted: false);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(f.coordinator.state[task.id]!.status, UploadTaskStatus.paused);

    // 手动点上传：直接续传，不再询问（PRD）。
    await f.coordinator.resumeTask(task.id);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(f.coordinator.state[task.id]!.status, UploadTaskStatus.uploading);
    expect(f.multipart.startedTasks.length, 2);
    expect(f.coordinator.pendingCellularConfirmations, isEmpty);
  });

  test('Wi-Fi → cellular switch auto-pauses unconfirmed uploads', () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.multipart.behavior =
        (task, token, onProgress, onCheckpoint) => hangUntilCanceled(token);

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    f.connectivity.switchToCellular();
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final paused = f.coordinator.state[task.id]!;
    expect(paused.status, UploadTaskStatus.paused);
    expect(f.coordinator.pendingCellularConfirmations, contains('session-1'));
    expect(f.multipart.startedTasks.length, 1);
  });

  test('background auto-pauses with breakpoint; foreground auto-continues',
      () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.multipart.behavior =
        (task, token, onProgress, onCheckpoint) => hangUntilCanceled(token);

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    f.coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final paused = f.coordinator.state[task.id]!;
    expect(paused.status, UploadTaskStatus.paused);
    expect(paused.multipartUploadId, isNull); // scripted executor: no parts yet
    expect(f.multipart.startedTasks.length, 1);

    f.coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(f.coordinator.state[task.id]!.status, UploadTaskStatus.uploading);
    expect(f.multipart.startedTasks.length, 2);
  });

  test('pump cellular gate blocks unconfirmed starts and raises the dialog',
      () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.connectivity.wifi = false;
    f.connectivity.notifyListeners();

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await settle();

    expect(f.multipart.startedTasks, isEmpty);
    expect(f.coordinator.state[task.id]!.status, UploadTaskStatus.paused);
    expect(f.coordinator.pendingCellularConfirmations, contains('session-1'));
  });

  test('v2 queue migrates to v3 on restore and the legacy key is dropped',
      () async {
    final f = await setUpCoordinator(
      seedBox: (box) async {
        await box.put('foreground_upload_tasks:v2', [
          {
            'id': 'legacy-1',
            'localFilePath': bigFile.path,
            'fileName': 'legacy.mp4',
            'fileSize': bigFile.lengthSync(),
            'contentType': 'video/mp4',
            'category': 'video',
            'ownerUserId': 'user-1',
            'uploadSessionId': 'session-old',
            'status': 'paused',
            'progress': 0.4,
            'retryCount': 0,
            'updatedAt': 1,
          },
        ]);
      },
    );
    await f.coordinator.ready;

    final legacy = f.coordinator.state['legacy-1'];
    expect(legacy, isNotNull);
    expect(legacy!.status, UploadTaskStatus.paused);
    expect(legacy.completedParts, isEmpty, reason: 'v2 记录无分片字段');
    expect(f.box.get('foreground_upload_tasks:v3'), isNotNull);
    expect(f.box.get('foreground_upload_tasks:v2'), isNull);
  });

  test('speed sampling produces a positive rate while uploading', () async {
    final f = await setUpCoordinator();
    await f.coordinator.ready;
    f.multipart.behavior =
        (task, token, onProgress, onCheckpoint) async {
      onProgress(0.1);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      onProgress(0.6);
      return hangUntilCanceled(token);
    };

    final task = videoTask(bigFile);
    await f.coordinator.enqueue(task);
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final uploading = f.coordinator.state[task.id]!;
    expect(uploading.status, UploadTaskStatus.uploading);
    expect(uploading.speedBps, greaterThan(0));
  });
}
