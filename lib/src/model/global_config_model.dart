import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'chain_info_model.dart';
import 'init_config_model.dart';
import 'json_converters.dart';
import 'mini_drama_config_model.dart';

part 'global_config_model.g.dart';

@JsonSerializable()
class GlobalConfig extends Equatable {
  final Map<String, ChainInfo>? chainlinks;
  final InitConfig? init;

  @JsonKey(name: 'mini-drama')
  final MiniDramaConfig? miniDrama;

  final BannerConfig? banner;

  const GlobalConfig({this.chainlinks, this.init, this.miniDrama, this.banner});

  factory GlobalConfig.fromJson(Map<String, dynamic> json) =>
      _$GlobalConfigFromJson(json);

  Map<String, dynamic> toJson() => _$GlobalConfigToJson(this);

  @override
  List<Object?> get props => [chainlinks, init, miniDrama, banner];
}

/// Banner section from `/api/admin/v1/configs/keys/...`.
@JsonSerializable()
class BannerConfig extends Equatable {
  final List<BannerItem>? items;
  final bool? enabled;

  const BannerConfig({this.items, this.enabled});

  factory BannerConfig.fromJson(Map<String, dynamic> json) =>
      _$BannerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$BannerConfigToJson(this);

  @override
  List<Object?> get props => [items, enabled];
}

/// A single banner item displayed in the theater hero carousel.
@JsonSerializable()
class BannerItem extends Equatable {
  final String? dramaId;
  final String? title;
  final String? thumbUrl;
  final String? bannerUrl;
  @JsonKey(fromJson: asInt)
  final int? sortOrder;
  final String? description;
  final String? previewHlsUrl;
  @JsonKey(fromJson: asInt)
  final int? totalEpisodes;
  @JsonKey(fromJson: asInt)
  final int? totalPlayCount;
  @JsonKey(fromJson: asInt)
  final int? totalCompletedViewCount;
  final List<String>? actorAvatarUrls;
  final String? previewVideoUrl;

  const BannerItem({
    this.dramaId,
    this.title,
    this.thumbUrl,
    this.bannerUrl,
    this.sortOrder,
    this.description,
    this.previewHlsUrl,
    this.totalEpisodes,
    this.totalPlayCount,
    this.totalCompletedViewCount,
    this.actorAvatarUrls,
    this.previewVideoUrl,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) =>
      _$BannerItemFromJson(json);

  Map<String, dynamic> toJson() => _$BannerItemToJson(this);

  @override
  List<Object?> get props => [
    dramaId,
    title,
    thumbUrl,
    bannerUrl,
    sortOrder,
    description,
    previewHlsUrl,
    totalEpisodes,
    totalPlayCount,
    totalCompletedViewCount,
    actorAvatarUrls,
    previewVideoUrl,
  ];
}
