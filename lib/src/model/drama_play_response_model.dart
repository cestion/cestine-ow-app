import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/json_helpers.dart';
import '../core/video_url_helpers.dart';
import 'cloudfront_signed_cookies_model.dart';
import 'json_converters.dart';

part 'drama_play_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class DramaPlayResponse extends Equatable {
  @JsonKey(fromJson: asString)
  final String? dramaId;
  @JsonKey(fromJson: asString)
  final String? episodeId;
  @JsonKey(fromJson: asInt)
  final int? episodeNo;
  final String? title;
  final String? description;
  @JsonKey(fromJson: asPreferredPlayUrl)
  final String? mediaAccessUrl;
  final String? playbackType;
  @JsonKey(fromJson: asPreferredPlayUrl)
  final String? videoUrl;
  @JsonKey(name: 'hlsUrl', fromJson: asPreferredPlayUrl)
  final String? hlsUrl;
  @JsonKey(fromJson: _signedCookiesFromJson)
  final CloudFrontSignedCookies? signedCookies;
  @JsonKey(fromJson: asInt)
  final int? likeCount;
  @JsonKey(fromJson: asInt)
  final int? commentCount;

  /// Episode / short-video work favorite count (player rail).
  @JsonKey(fromJson: asInt)
  final int? favoriteCount;
  @JsonKey(fromJson: asBool)
  final bool? favoritedByMe;
  @JsonKey(fromJson: asBool)
  final bool? likedByMe;
  @JsonKey(fromJson: asString)
  final String? userId;
  @JsonKey(fromJson: asString)
  final String? creatorId;
  final String? creatorName;
  final String? creatorAvatarUrl;

  /// Auto-generated episode thumbnail (MediaConvert) or manual cover.
  @JsonKey(fromJson: asString)
  final String? coverUrl;

  /// Transcoded t=0 still — independent from [coverUrl].
  @JsonKey(fromJson: asString)
  final String? firstFrameUrl;

  const DramaPlayResponse({
    this.dramaId,
    this.episodeId,
    this.episodeNo,
    this.title,
    this.description,
    this.mediaAccessUrl,
    this.playbackType,
    this.videoUrl,
    this.hlsUrl,
    this.signedCookies,
    this.likeCount,
    this.commentCount,
    this.favoriteCount,
    this.favoritedByMe,
    this.likedByMe,
    this.userId,
    this.creatorId,
    this.creatorName,
    this.creatorAvatarUrl,
    this.coverUrl,
    this.firstFrameUrl,
  });

  DramaPlayResponse copyWith({
    String? dramaId,
    String? episodeId,
    int? episodeNo,
    String? title,
    String? description,
    String? mediaAccessUrl,
    String? playbackType,
    String? videoUrl,
    String? hlsUrl,
    CloudFrontSignedCookies? signedCookies,
    int? likeCount,
    int? commentCount,
    int? favoriteCount,
    bool? favoritedByMe,
    bool? likedByMe,
    String? userId,
    String? creatorId,
    String? creatorName,
    String? creatorAvatarUrl,
    String? coverUrl,
    String? firstFrameUrl,
  }) {
    return DramaPlayResponse(
      dramaId: dramaId ?? this.dramaId,
      episodeId: episodeId ?? this.episodeId,
      episodeNo: episodeNo ?? this.episodeNo,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaAccessUrl: mediaAccessUrl ?? this.mediaAccessUrl,
      playbackType: playbackType ?? this.playbackType,
      videoUrl: videoUrl ?? this.videoUrl,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      signedCookies: signedCookies ?? this.signedCookies,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      favoritedByMe: favoritedByMe ?? this.favoritedByMe,
      likedByMe: likedByMe ?? this.likedByMe,
      userId: userId ?? this.userId,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      firstFrameUrl: firstFrameUrl ?? this.firstFrameUrl,
    );
  }

  factory DramaPlayResponse.fromJson(Map<String, dynamic> json) {
    final mapped = Map<String, dynamic>.from(json);
    mapped['coverUrl'] ??= asString(
      json['coverUrl'] ?? json['coverImg'] ?? json['thumbnailUrl'],
    );
    // Some gateways expose the bitrate ladder as a dedicated array instead of
    // stuffing it into hlsUrl / mediaAccessUrl.
    final sources = json['playSources'] ?? json['hlsUrls'] ?? json['playUrls'];
    if (sources != null) {
      // Merge primary fields with the ladder so a CMAF master in
      // mediaAccessUrl wins over demuxed `_360p` / `_480p` entries that may
      // also appear in playSources (picking a variant would mute / disable ABR).
      final preferred = VideoUrlHelpers.preferPlaySource([
        json['mediaAccessUrl'],
        json['hlsUrl'],
        sources,
      ]);
      if (preferred != null && preferred.isNotEmpty) {
        mapped['hlsUrl'] = preferred;
      }
    }
    return _$DramaPlayResponseFromJson(mapped);
  }

  /// Decodes episode detail payloads that nest play fields under
  /// [episodeInfo] (and drama chrome under [dramaInfo]).
  factory DramaPlayResponse.fromNestedJson(dynamic raw) {
    final map = normalizeJson(raw);
    final dramaInfo = normalizeJson(map['dramaInfo']);
    final episodeInfo = normalizeJson(map['episodeInfo']);
    if (dramaInfo.isEmpty && episodeInfo.isEmpty) {
      return DramaPlayResponse.fromJson(map);
    }
    return DramaPlayResponse.fromJson(<String, dynamic>{
      ...map,
      ...dramaInfo,
      ...episodeInfo,
      'dramaId':
          dramaInfo['dramaId'] ?? episodeInfo['dramaId'] ?? map['dramaId'],
      'signedCookies':
          map['signedCookies'] ??
          episodeInfo['signedCookies'] ??
          dramaInfo['signedCookies'],
    });
  }

  Map<String, dynamic> toJson() => _$DramaPlayResponseToJson(this);

  /// The effective playback URL.
  ///
  /// When [playbackType] indicates HLS, prefer dedicated HLS fields so a
  /// mis-ordered API payload (MP4 in [mediaAccessUrl]) does not win.
  /// Otherwise keep the historical CDN-first order.
  ///
  /// Only absolute `http`/`https` URLs are returned — relative paths and
  /// non-network schemes make AVPlayer fail with "unsupported URL".
  String? get effectivePlayUrl {
    final type = playbackType?.toLowerCase() ?? '';
    final prefersHls = type.contains('hls') || type.contains('m3u8');
    if (prefersHls) {
      return _firstHttpUrl([hlsUrl, mediaAccessUrl, videoUrl]);
    }
    return _firstHttpUrl([mediaAccessUrl, videoUrl, hlsUrl]);
  }

  static String? _firstHttpUrl(List<String?> candidates) {
    for (final c in candidates) {
      if (c == null || c.isEmpty) continue;
      if (VideoUrlHelpers.isHttpUrl(c)) return c;
    }
    return null;
  }

  bool get hasUsableSignedCookies {
    final cookies = signedCookies;
    return cookies != null && cookies.isValid;
  }

  /// CloudFront-hosted media with no usable signature.
  ///
  /// The current test gateway often omits `signedCookies` while still
  /// serving the playlist; callers may bind unsigned. Expired cookies
  /// are a different case and must refetch.
  bool get isUnsignedProtectedPlay {
    final url = effectivePlayUrl;
    if (url == null || url.isEmpty) return false;
    if (!VideoUrlHelpers.requiresCloudFrontCookies(url)) return false;
    return !hasUsableSignedCookies;
  }

  bool get isHls =>
      VideoUrlHelpers.formatOf(effectivePlayUrl ?? '') == VideoUrlFormat.hls;

  bool get isMp4 =>
      VideoUrlHelpers.formatOf(effectivePlayUrl ?? '') == VideoUrlFormat.mp4;

  /// Poster for player / list chrome: [firstFrameUrl] then [coverUrl].
  String? get posterUrl => VideoUrlHelpers.preferPosterUrl(
    firstFrameUrl: firstFrameUrl,
    coverUrl: coverUrl,
  );

  static CloudFrontSignedCookies? _signedCookiesFromJson(Object? json) {
    if (json == null) return null;
    if (json is CloudFrontSignedCookies) return json;
    if (json is Map<String, dynamic>) {
      return CloudFrontSignedCookies.fromJson(json);
    }
    if (json is Map) {
      return CloudFrontSignedCookies.fromJson(
        json.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  @override
  List<Object?> get props => [
    dramaId,
    episodeId,
    episodeNo,
    title,
    description,
    mediaAccessUrl,
    playbackType,
    videoUrl,
    hlsUrl,
    signedCookies,
    likeCount,
    commentCount,
    favoriteCount,
    favoritedByMe,
    likedByMe,
    userId,
    creatorId,
    creatorName,
    creatorAvatarUrl,
    coverUrl,
    firstFrameUrl,
  ];
}
