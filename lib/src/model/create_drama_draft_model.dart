import 'package:equatable/equatable.dart';

import '../core/json_helpers.dart';

/// 创建短剧流程的本地草稿（仅新建模式）。
///
/// 持久化到 Hive `create_drama_draft` key，App 重启后可恢复。新选择的视频
/// 会先复制到 App 自有目录，因此待上传/暂停任务也可以安全持久化；
/// 角色头像的本地预览路径同理丢弃，恢复后由 UI 降级到 `avatarUrl`。
///
/// 与 [DramaRoleDraft] 形状解耦：恢复时由 controller 用新本地 id 重建
/// [DramaRoleDraft]，避免本地 id 在重启后碰撞。
class CreateDramaDraft with Equatable {
  final int currentStep;
  final String title;
  final String synopsis;
  final List<String> selectedTagIds;
  final String? coverUrl;
  final String? coverObjectKey;
  final String? uploadSessionId;
  final int? uploadSessionExpiresAt;
  final List<DraftVideoItem> videos;
  final List<DraftRoleItem> roles;
  final int schemaVersion;
  final int savedAt;

  const CreateDramaDraft({
    this.currentStep = 0,
    this.title = '',
    this.synopsis = '',
    this.selectedTagIds = const [],
    this.coverUrl,
    this.coverObjectKey,
    this.uploadSessionId,
    this.uploadSessionExpiresAt,
    this.videos = const [],
    this.roles = const [],
    this.schemaVersion = 3,
    this.savedAt = 0,
  });

  /// 是否有可恢复的实质内容（任一字段非空）。
  bool get hasContent =>
      title.trim().isNotEmpty ||
      synopsis.trim().isNotEmpty ||
      selectedTagIds.isNotEmpty ||
      coverUrl != null ||
      coverObjectKey != null ||
      videos.isNotEmpty ||
      roles.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'currentStep': currentStep,
    'title': title,
    'synopsis': synopsis,
    'selectedTagIds': selectedTagIds,
    if (coverUrl != null) 'coverUrl': coverUrl,
    if (coverObjectKey != null) 'coverObjectKey': coverObjectKey,
    if (uploadSessionId != null) 'uploadSessionId': uploadSessionId,
    if (uploadSessionExpiresAt != null)
      'uploadSessionExpiresAt': uploadSessionExpiresAt,
    'videos': [for (final v in videos) v.toMap()],
    'roles': [for (final r in roles) r.toMap()],
    'schemaVersion': schemaVersion,
    'savedAt': savedAt,
  };

  static CreateDramaDraft? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final videosRaw = map['videos'];
    final rolesRaw = map['roles'];
    final tagsRaw = map['selectedTagIds'];
    return CreateDramaDraft(
      currentStep: asIntOrNull(map['currentStep']) ?? 0,
      title: asStringOrNull(map['title']) ?? '',
      synopsis: asStringOrNull(map['synopsis']) ?? '',
      selectedTagIds: tagsRaw is List
          ? tagsRaw.whereType<String>().toList(growable: false)
          : const [],
      coverUrl: asStringOrNull(map['coverUrl']),
      coverObjectKey: asStringOrNull(map['coverObjectKey']),
      uploadSessionId: asStringOrNull(map['uploadSessionId']),
      uploadSessionExpiresAt: asIntOrNull(map['uploadSessionExpiresAt']),
      videos: videosRaw is List
          ? videosRaw
                .whereType<Map<dynamic, dynamic>>()
                .map((m) => DraftVideoItem.fromMap(m))
                .whereType<DraftVideoItem>()
                .toList(growable: false)
          : const [],
      roles: rolesRaw is List
          ? rolesRaw
                .whereType<Map<dynamic, dynamic>>()
                .map((m) => DraftRoleItem.fromMap(m))
                .whereType<DraftRoleItem>()
                .toList(growable: false)
          : const [],
      schemaVersion: asIntOrNull(map['schemaVersion']) ?? 1,
      savedAt: asIntOrNull(map['savedAt']) ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    title,
    synopsis,
    selectedTagIds,
    coverUrl,
    coverObjectKey,
    uploadSessionId,
    uploadSessionExpiresAt,
    videos,
    roles,
    schemaVersion,
    savedAt,
  ];
}

/// 草稿中的视频项。成功项保存 objectKey，未完成项保存 App 托管路径与任务 id。
///
/// `thumbnailPath` 指向任务目录中的持久化缩略图，App 重启后仍可访问。
class DraftVideoItem with Equatable {
  final String? taskId;
  final String? localFilePath;
  final String? uploadStatus;
  final String name;
  final String description;
  final int durationMs;
  final int sizeBytes;
  final int width;
  final int height;
  final String? url;
  final String? videoObjectKey;
  final String? thumbnailPath;

  /// true 表示该项替换了已有剧集的位置，恢复后不可删除/拖动。
  final bool isReplacement;

  const DraftVideoItem({
    required this.name,
    this.taskId,
    this.localFilePath,
    this.uploadStatus,
    this.description = '',
    this.durationMs = 0,
    this.sizeBytes = 0,
    this.width = 0,
    this.height = 0,
    this.url,
    this.videoObjectKey,
    this.thumbnailPath,
    this.isReplacement = false,
  });

  Map<String, dynamic> toMap() => {
    if (taskId != null) 'taskId': taskId,
    if (localFilePath != null) 'localFilePath': localFilePath,
    if (uploadStatus != null) 'uploadStatus': uploadStatus,
    'name': name,
    'description': description,
    'durationMs': durationMs,
    'sizeBytes': sizeBytes,
    'width': width,
    'height': height,
    if (url != null) 'url': url,
    if (videoObjectKey != null) 'videoObjectKey': videoObjectKey,
    if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
    if (isReplacement) 'isReplacement': true,
  };

  static DraftVideoItem? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final name = asStringOrNull(map['name']);
    if (name == null || name.isEmpty) return null;
    return DraftVideoItem(
      name: name,
      taskId: asStringOrNull(map['taskId']),
      localFilePath: asStringOrNull(map['localFilePath']),
      uploadStatus: asStringOrNull(map['uploadStatus']),
      description: asStringOrNull(map['description']) ?? '',
      durationMs: asIntOrNull(map['durationMs']) ?? 0,
      sizeBytes: asIntOrNull(map['sizeBytes']) ?? 0,
      width: asIntOrNull(map['width']) ?? 0,
      height: asIntOrNull(map['height']) ?? 0,
      url: asStringOrNull(map['url']),
      videoObjectKey: asStringOrNull(map['videoObjectKey']),
      thumbnailPath: asStringOrNull(map['thumbnailPath']),
      isReplacement: asBoolOrNull(map['isReplacement']) ?? false,
    );
  }

  @override
  List<Object?> get props => [
    taskId,
    localFilePath,
    uploadStatus,
    name,
    description,
    durationMs,
    sizeBytes,
    width,
    height,
    url,
    videoObjectKey,
    thumbnailPath,
    isReplacement,
  ];
}

/// 草稿中的角色项：保留提交所需字段，丢弃本地头像预览路径。
class DraftRoleItem with Equatable {
  final String name;
  final String bio;
  final String? avatarObjectKey;
  final String? avatarUrl;
  final int sortNo;
  final String? boundActorCollectionId;
  final String? boundActorName;
  final String? boundActorAvatarUrl;

  /// 与 [DramaRoleDraft.actorBindingPersisted] 同语义；草稿恢复时透传。
  final bool actorBindingPersisted;

  const DraftRoleItem({
    required this.name,
    this.bio = '',
    this.avatarObjectKey,
    this.avatarUrl,
    this.sortNo = 0,
    this.boundActorCollectionId,
    this.boundActorName,
    this.boundActorAvatarUrl,
    this.actorBindingPersisted = false,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'bio': bio,
    if (avatarObjectKey != null) 'avatarObjectKey': avatarObjectKey,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    'sortNo': sortNo,
    if (boundActorCollectionId != null)
      'boundActorCollectionId': boundActorCollectionId,
    if (boundActorName != null) 'boundActorName': boundActorName,
    if (boundActorAvatarUrl != null) 'boundActorAvatarUrl': boundActorAvatarUrl,
    'actorBindingPersisted': actorBindingPersisted,
  };

  static DraftRoleItem? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final name = asStringOrNull(map['name']);
    if (name == null || name.isEmpty) return null;
    return DraftRoleItem(
      name: name,
      bio: asStringOrNull(map['bio']) ?? '',
      avatarObjectKey: asStringOrNull(map['avatarObjectKey']),
      avatarUrl: asStringOrNull(map['avatarUrl']),
      sortNo: asIntOrNull(map['sortNo']) ?? 0,
      boundActorCollectionId: asStringOrNull(map['boundActorCollectionId']),
      boundActorName: asStringOrNull(map['boundActorName']),
      boundActorAvatarUrl: asStringOrNull(map['boundActorAvatarUrl']),
      actorBindingPersisted: map['actorBindingPersisted'] == true,
    );
  }

  @override
  List<Object?> get props => [
    name,
    bio,
    avatarObjectKey,
    avatarUrl,
    sortNo,
    boundActorCollectionId,
    boundActorName,
    boundActorAvatarUrl,
    actorBindingPersisted,
  ];
}
