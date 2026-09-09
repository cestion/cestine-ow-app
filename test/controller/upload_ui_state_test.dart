import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/publish_video_state.dart';
import 'package:story_app/src/controller/video_upload_state.dart';

void main() {
  group('VideoUploadItem', () {
    VideoUploadItem item(VideoUploadStatus status, {bool networkWait = false}) =>
        VideoUploadItem(
          id: 'v1',
          path: '/tmp/v.mp4',
          name: 'v.mp4',
          status: status,
          networkWait: networkWait,
        );

    test('isIncomplete covers pending/uploading/paused/merging', () {
      expect(item(VideoUploadStatus.pending).isIncomplete, isTrue);
      expect(item(VideoUploadStatus.uploading).isIncomplete, isTrue);
      expect(item(VideoUploadStatus.paused).isIncomplete, isTrue);
      expect(item(VideoUploadStatus.merging).isIncomplete, isTrue);
      expect(item(VideoUploadStatus.success).isIncomplete, isFalse);
      expect(item(VideoUploadStatus.failed).isIncomplete, isFalse);
    });

    test('isWaitingNetwork: transient flag combined with non-terminal status',
        () {
      expect(item(VideoUploadStatus.uploading).isWaitingNetwork, isFalse);
      expect(
        item(VideoUploadStatus.uploading, networkWait: true).isWaitingNetwork,
        isTrue,
      );
      // PRD：暂停态断网 → "等待网络连接... + 上传按钮"。
      expect(
        item(VideoUploadStatus.paused, networkWait: true).isWaitingNetwork,
        isTrue,
      );
      // 合并中断网同样进入等待展示。
      expect(
        item(VideoUploadStatus.merging, networkWait: true).isWaitingNetwork,
        isTrue,
      );
      // 终态不受 networkWait 影响。
      expect(
        item(VideoUploadStatus.success, networkWait: true).isWaitingNetwork,
        isFalse,
      );
      expect(
        item(VideoUploadStatus.failed, networkWait: true).isWaitingNetwork,
        isFalse,
      );
    });

    test('copyWith carries speedBps and networkWait', () {
      final base = item(VideoUploadStatus.uploading);
      final next = base.copyWith(speedBps: 1024, networkWait: true);
      expect(next.speedBps, 1024);
      expect(next.networkWait, isTrue);
      expect(next, isNot(equals(base)));
    });

    test('cellular confirmation mirror participates in state equality', () {
      const a = VideoUploadState();
      const b = VideoUploadState(cellularConfirmationPending: true);
      expect(a, isNot(equals(b)));
      expect(a.copyWith(cellularConfirmationPending: true), equals(b));
    });
  });

  group('PublishVideoFile', () {
    PublishVideoFile file(
      PublishVideoUploadStatus status, {
      bool networkWait = false,
      String? objectKey,
    }) =>
        PublishVideoFile(
          path: '/tmp/v.mp4',
          name: 'v.mp4',
          sizeBytes: 100,
          durationMs: 1000,
          width: 10,
          height: 10,
          uploadStatus: status,
          networkWait: networkWait,
          objectKey: objectKey,
        );

    test('paused and merging are distinct, non-uploading statuses', () {
      expect(file(PublishVideoUploadStatus.paused).isPaused, isTrue);
      expect(file(PublishVideoUploadStatus.paused).isUploading, isFalse);
      expect(file(PublishVideoUploadStatus.merging).isMerging, isTrue);
      expect(file(PublishVideoUploadStatus.merging).isUploading, isFalse);
      expect(file(PublishVideoUploadStatus.merging).isUploaded, isFalse);
    });

    test('isWaitingNetwork mirrors the drama-side semantics', () {
      expect(
        file(PublishVideoUploadStatus.uploading, networkWait: true)
            .isWaitingNetwork,
        isTrue,
      );
      expect(
        file(PublishVideoUploadStatus.paused, networkWait: true)
            .isWaitingNetwork,
        isTrue,
      );
      expect(
        file(PublishVideoUploadStatus.merging, networkWait: true)
            .isWaitingNetwork,
        isTrue,
      );
      expect(
        file(PublishVideoUploadStatus.success, networkWait: true)
            .isWaitingNetwork,
        isFalse,
      );
    });

    test('upload gating: merging is not uploaded, paused keeps progress',
        () {
      expect(
        file(PublishVideoUploadStatus.merging, objectKey: 'k').isUploaded,
        isFalse,
        reason: '合并未 READY 前不可发布',
      );
      final paused = file(PublishVideoUploadStatus.uploading)
          .copyWith(uploadProgress: 0.4, uploadStatus: PublishVideoUploadStatus.paused);
      expect(paused.uploadProgress, 0.4, reason: '失败/暂停保留进度（PRD）');
    });

    test('state mirrors cellular confirmation pending', () {
      const a = PublishVideoState();
      const b = PublishVideoState(cellularConfirmationPending: true);
      expect(a, isNot(equals(b)));
    });
  });
}
