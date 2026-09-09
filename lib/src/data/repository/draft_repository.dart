import '../../core/story_logger.dart';
import '../../model/models.dart';
import 'story_local_repository.dart';

/// 本地发布草稿仓储。
///
/// 草稿按用户隔离，并与可清理的接口缓存保持独立的 key 命名空间。当前产品
/// 每种发布类型只保留一条进行中的草稿，因此无需草稿列表或服务端同步。
abstract interface class DraftRepository {
  Future<CreateDramaDraft?> getCreateDramaDraft(String userId);

  Future<void> saveCreateDramaDraft(String userId, CreateDramaDraft draft);

  Future<void> deleteCreateDramaDraft(String userId);

  Future<PublishVideoDraft?> getPublishVideoDraft(String userId);

  Future<void> savePublishVideoDraft(String userId, PublishVideoDraft draft);

  Future<void> deletePublishVideoDraft(String userId);
}

class HiveDraftRepository implements DraftRepository {
  HiveDraftRepository(this._localRepository);

  final StoryLocalRepository _localRepository;

  static const _prefix = 'local_draft:v1';
  static const _legacyCreateDramaKey = 'create_drama_draft';
  static const _legacyPublishVideoKey = 'publish_video_draft';

  String _key(String userId, String type) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must not be empty');
    }
    return '$_prefix:${Uri.encodeComponent(normalized)}:$type';
  }

  @override
  Future<CreateDramaDraft?> getCreateDramaDraft(String userId) =>
      _readAndMigrate(
        scopedKey: _key(userId, 'create_drama'),
        legacyKey: _legacyCreateDramaKey,
        decode: CreateDramaDraft.fromMap,
      );

  @override
  Future<void> saveCreateDramaDraft(String userId, CreateDramaDraft draft) =>
      _save(
        scopedKey: _key(userId, 'create_drama'),
        legacyKey: _legacyCreateDramaKey,
        value: draft.toMap(),
      );

  @override
  Future<void> deleteCreateDramaDraft(String userId) => _delete(
    scopedKey: _key(userId, 'create_drama'),
    legacyKey: _legacyCreateDramaKey,
  );

  @override
  Future<PublishVideoDraft?> getPublishVideoDraft(String userId) =>
      _readAndMigrate(
        scopedKey: _key(userId, 'publish_video'),
        legacyKey: _legacyPublishVideoKey,
        decode: PublishVideoDraft.fromMap,
      );

  @override
  Future<void> savePublishVideoDraft(String userId, PublishVideoDraft draft) =>
      _save(
        scopedKey: _key(userId, 'publish_video'),
        legacyKey: _legacyPublishVideoKey,
        value: draft.toMap(),
      );

  @override
  Future<void> deletePublishVideoDraft(String userId) => _delete(
    scopedKey: _key(userId, 'publish_video'),
    legacyKey: _legacyPublishVideoKey,
  );

  Future<T?> _readAndMigrate<T>({
    required String scopedKey,
    required String legacyKey,
    required T? Function(dynamic raw) decode,
  }) async {
    final box = _localRepository.cacheBox;
    var raw = box.get(scopedKey);

    // 兼容升级前的单例草稿。旧数据没有 userId，只能在升级后第一次打开发布
    // 页时归属给当前账号；迁移完成立即删除旧 key，避免其他账号读取。
    if (raw == null) {
      raw = box.get(legacyKey);
      if (raw != null) {
        await box.put(scopedKey, raw);
        await box.delete(legacyKey);
      }
    }
    if (raw == null) return null;

    try {
      final decoded = decode(raw);
      if (decoded == null) {
        StoryLogger.w(
          'Local draft is malformed: $scopedKey',
          tag: 'DraftRepository',
        );
      }
      return decoded;
    } catch (error, stackTrace) {
      // 损坏草稿不自动删除，保留现场以便后续兼容或排查。
      StoryLogger.w(
        'Failed to decode local draft: $scopedKey',
        error: error,
        stackTrace: stackTrace,
        tag: 'DraftRepository',
      );
      return null;
    }
  }

  Future<void> _save({
    required String scopedKey,
    required String legacyKey,
    required Map<String, dynamic> value,
  }) async {
    final box = _localRepository.cacheBox;
    await box.put(scopedKey, value);
    if (box.containsKey(legacyKey)) await box.delete(legacyKey);
  }

  Future<void> _delete({
    required String scopedKey,
    required String legacyKey,
  }) async {
    final box = _localRepository.cacheBox;
    await box.delete(scopedKey);
    if (box.containsKey(legacyKey)) await box.delete(legacyKey);
  }
}
