// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlobalConfig _$GlobalConfigFromJson(Map<String, dynamic> json) => GlobalConfig(
  chainlinks: (json['chainlinks'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, ChainInfo.fromJson(e as Map<String, dynamic>)),
  ),
  init: json['init'] == null
      ? null
      : InitConfig.fromJson(json['init'] as Map<String, dynamic>),
  miniDrama: json['mini-drama'] == null
      ? null
      : MiniDramaConfig.fromJson(json['mini-drama'] as Map<String, dynamic>),
  banner: json['banner'] == null
      ? null
      : BannerConfig.fromJson(json['banner'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GlobalConfigToJson(GlobalConfig instance) =>
    <String, dynamic>{
      'chainlinks': instance.chainlinks,
      'init': instance.init,
      'mini-drama': instance.miniDrama,
      'banner': instance.banner,
    };

BannerConfig _$BannerConfigFromJson(Map<String, dynamic> json) => BannerConfig(
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => BannerItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  enabled: json['enabled'] as bool?,
);

Map<String, dynamic> _$BannerConfigToJson(BannerConfig instance) =>
    <String, dynamic>{'items': instance.items, 'enabled': instance.enabled};

BannerItem _$BannerItemFromJson(Map<String, dynamic> json) => BannerItem(
  dramaId: json['dramaId'] as String?,
  title: json['title'] as String?,
  thumbUrl: json['thumbUrl'] as String?,
  bannerUrl: json['bannerUrl'] as String?,
  sortOrder: asInt(json['sortOrder']),
  description: json['description'] as String?,
  previewHlsUrl: json['previewHlsUrl'] as String?,
  totalEpisodes: asInt(json['totalEpisodes']),
  totalPlayCount: asInt(json['totalPlayCount']),
  totalCompletedViewCount: asInt(json['totalCompletedViewCount']),
  actorAvatarUrls: (json['actorAvatarUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  previewVideoUrl: json['previewVideoUrl'] as String?,
);

Map<String, dynamic> _$BannerItemToJson(BannerItem instance) =>
    <String, dynamic>{
      'dramaId': instance.dramaId,
      'title': instance.title,
      'thumbUrl': instance.thumbUrl,
      'bannerUrl': instance.bannerUrl,
      'sortOrder': instance.sortOrder,
      'description': instance.description,
      'previewHlsUrl': instance.previewHlsUrl,
      'totalEpisodes': instance.totalEpisodes,
      'totalPlayCount': instance.totalPlayCount,
      'totalCompletedViewCount': instance.totalCompletedViewCount,
      'actorAvatarUrls': instance.actorAvatarUrls,
      'previewVideoUrl': instance.previewVideoUrl,
    };
