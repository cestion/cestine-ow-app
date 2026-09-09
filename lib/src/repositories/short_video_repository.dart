import '../api/story_api_client.dart';
import '../core/json_helpers.dart';
import '../core/result.dart';
import '../model/page_dto.dart';
import '../model/short_video_model.dart';

abstract class ShortVideoRepository {
  /// 获取当前创作者的短视频列表。
  Future<Result<PageDto<CreatorShortVideo>>> listCreatorShortVideos({
    String? mark,
    int pageSize = 20,
    String? status,
  });

  /// 发布一条短视频。
  Future<Result<ShortVideo>> publish(PublishShortVideoRequest request);

  /// 编辑指定短视频。
  Future<Result<ShortVideo>> edit(int episodeId, EditShortVideoRequest request);

  /// 获取指定短视频的编辑回显及上传会话信息。
  Future<Result<ShortVideoEditSession>> getEditSession(int episodeId);

  /// 删除指定短视频。
  Future<Result<void>> delete(int episodeId);

  Future<void> dispose();
}

class ShortVideoRepositoryImpl implements ShortVideoRepository {
  static const String _creatorShortVideosPath =
      '/api/mini-drama/creator/short-videos';

  final StoryApiClient _api;

  ShortVideoRepositoryImpl(this._api);

  @override
  Future<Result<PageDto<CreatorShortVideo>>> listCreatorShortVideos({
    String? mark,
    int pageSize = 20,
    String? status,
  }) => _api.safeGet(
    _creatorShortVideosPath,
    query: {'mark': mark, 'pageSize': pageSize, 'status': status},
    decoder: (data) =>
        parsePageDto<CreatorShortVideo>(data, CreatorShortVideo.fromJson),
  );

  @override
  Future<Result<ShortVideo>> publish(PublishShortVideoRequest request) =>
      _api.safePost(
        _creatorShortVideosPath,
        body: request.toJson(),
        decoder: decodeWith(ShortVideo.fromJson),
      );

  @override
  Future<Result<ShortVideo>> edit(
    int episodeId,
    EditShortVideoRequest request,
  ) => _api.safePut(
    '$_creatorShortVideosPath/$episodeId',
    body: request.toJson(),
    decoder: decodeWith(ShortVideo.fromJson),
  );

  @override
  Future<Result<ShortVideoEditSession>> getEditSession(int episodeId) =>
      _api.safeGet(
        '$_creatorShortVideosPath/$episodeId/edit-sessions',
        decoder: decodeWith(ShortVideoEditSession.fromJson),
      );

  @override
  Future<Result<void>> delete(int episodeId) =>
      _api.safeDelete('$_creatorShortVideosPath/$episodeId', decoder: (_) {});

  @override
  Future<void> dispose() async {}
}
