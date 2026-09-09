import 'dart:convert';

/// Remote video URL parsing helpers shared by player UI and precache.
enum VideoUrlFormat { hls, mp4, unknown }

abstract final class VideoUrlHelpers {
  VideoUrlHelpers._();

  /// Returns the final file extension from a URL path, without the leading
  /// dot. Query parameters and fragments are intentionally ignored.
  ///
  /// For example, a signed URL ending in `episode.mp4?token=...` returns
  /// `mp4`. Paths without a usable extension return null.
  static String? pathExtensionOf(String? url) {
    final value = url?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.pathSegments.isEmpty) return null;
    final fileName = uri.pathSegments.last;
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return null;
    final extension = fileName.substring(dot + 1);
    if (extension.length > 10 ||
        !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(extension)) {
      return null;
    }
    return extension;
  }

  /// True when [url] is served by the Story CloudFront video CDN.
  ///
  /// Those hosts reject unsigned requests (HTTP 403). Open CDNs (S3, generic
  /// `cdn.example.com` fixtures) return false so guest-open media and tests
  /// can still bind without cookies.
  ///
  /// Dev / staging hosts (`dev-video.*`) are explicitly excluded — they serve
  /// content without signed cookies and the cookie-clear path is unnecessary.
  static bool requiresCloudFrontCookies(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    // Dev / staging hosts never require signed cookies.
    if (host.startsWith('dev-')) return false;
    if (host == 'cloudfront.net' || host.endsWith('.cloudfront.net')) {
      return true;
    }
    if (uri.path.toLowerCase().contains('/mini-drama/streaming/')) {
      return true;
    }
    final isActqa = host == 'actqa.com' || host.endsWith('.actqa.com');
    final isStoryFun = host == 'story.fun' || host.endsWith('.story.fun');
    return (isActqa || isStoryFun) && host.contains('video');
  }

  /// True when [url] is an absolute http(s) URL AVPlayer/ExoPlayer can load.
  ///
  /// Rejects scheme-only strings (`http://`), missing hosts, and non-network
  /// schemes — those make iOS AVPlayer fail with "unsupported URL".
  static bool isHttpUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    if (!uri.isScheme('http') && !uri.isScheme('https')) return false;
    return uri.hasAuthority && uri.host.isNotEmpty;
  }

  static VideoUrlFormat formatOf(String url) {
    try {
      final path = Uri.parse(url).path.toLowerCase();
      if (path.endsWith('.m3u8')) return VideoUrlFormat.hls;
      if (path.endsWith('.mp4')) return VideoUrlFormat.mp4;
    } catch (_) {
      // If the URL is malformed, fall through to unknown.
    }
    return VideoUrlFormat.unknown;
  }

  /// Filename suffixes that mark fixed-rung / demuxed HLS playlists (not the
  /// ABR master). Loading these as the primary URL disables ABR and can mute
  /// video-only CMAF variants that rely on a separate `AUDIO` group.
  static final RegExp _hlsFixedRungSuffix = RegExp(
    r'_(?:\d{3,4}p|audio)\.m3u8$',
    caseSensitive: false,
  );

  /// True when [url] looks like an HLS ABR master (or a single non-ladder
  /// package), rather than a `_360p` / `_480p` / `_audio` fixed rung.
  static bool isLikelyHlsMasterPlaylist(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    if (!path.endsWith('.m3u8')) return false;
    return !_hlsFixedRungSuffix.hasMatch(path);
  }

  /// True when [url] looks like a fixed ladder rung or demuxed audio playlist.
  static bool isLikelyHlsVariantPlaylist(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    if (!path.endsWith('.m3u8')) return false;
    return _hlsFixedRungSuffix.hasMatch(path);
  }

  /// Picks one play URL when the API returns multiple sources.
  ///
  /// Accepts a bare [String], a [List] of strings, or a comma-separated
  /// string.
  ///
  /// Preference order:
  /// 1. HLS ABR master / non-ladder `.m3u8` (e.g. CMAF `…/cmaf/{id}.m3u8`)
  ///    over fixed-rung variants (`_360p` / `_480p` / `_audio`) so the native
  ///    player can ABR and keep demuxed audio.
  /// 2. Among the remaining pool, smallest ladder height / numeric path
  ///    segment (e.g. `…/7/…` before `…/9.m3u8`, `_360p` before `_720p`).
  /// 3. Lexicographic tie-break; then first non-empty entry.
  static String? preferPlaySource(Object? raw) {
    final urls = normalizePlayUrls(raw);
    if (urls.isEmpty) return null;
    if (urls.length == 1) return urls.first;

    final masters = [
      for (final url in urls)
        if (isLikelyHlsMasterPlaylist(url)) url,
    ];
    final pool = masters.isNotEmpty ? masters : urls;

    final ranked = [...pool]
      ..sort((a, b) {
        final byRank = playSourceRank(a).compareTo(playSourceRank(b));
        if (byRank != 0) return byRank;
        return a.compareTo(b);
      });
    return ranked.first;
  }

  /// Normalizes API play-URL payloads into a clean list of http(s) URLs.
  static List<String> normalizePlayUrls(Object? raw) {
    if (raw == null) return const [];
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return const [];
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        // Defensive: some gateways stringified a JSON array into hlsUrl.
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) return normalizePlayUrls(decoded);
        } catch (_) {
          // Fall through to comma / single-URL parsing.
        }
      }
      if (trimmed.contains(',') &&
          trimmed.split(',').every((p) => p.trim().startsWith('http'))) {
        return [
          for (final part in trimmed.split(','))
            if (part.trim().isNotEmpty && isHttpUrl(part.trim())) part.trim(),
        ];
      }
      return isHttpUrl(trimmed) ? [trimmed] : const [];
    }
    if (raw is Map) {
      // Some gateways wrap sources as `{ url / hlsUrl / src: "..." }`.
      for (final key in const ['url', 'hlsUrl', 'src', 'mediaAccessUrl']) {
        final v = raw[key];
        if (v is String && isHttpUrl(v)) return [v.trim()];
      }
      return const [];
    }
    if (raw is Iterable) {
      final out = <String>[];
      for (final item in raw) {
        out.addAll(normalizePlayUrls(item));
      }
      return out;
    }
    final asText = raw.toString().trim();
    return asText.isNotEmpty && isHttpUrl(asText) ? [asText] : const [];
  }

  /// Rank used to prefer lower CDN ladder rungs (`360p` / `7` before `720p` /
  /// `9`). Lower is preferred when no ABR master is available.
  static int playSourceRank(String url) {
    try {
      final path = Uri.parse(url).path;
      final height = RegExp(
        r'_(\d{3,4})p(?:\.|$)',
        caseSensitive: false,
      ).firstMatch(path);
      if (height != null) return int.parse(height.group(1)!);

      final segs = path.split('/').where((s) => s.isNotEmpty).toList();
      for (var i = segs.length - 1; i >= 0; i--) {
        var seg = segs[i];
        final dot = seg.lastIndexOf('.');
        if (dot > 0) seg = seg.substring(0, dot);
        final n = int.tryParse(seg);
        if (n != null) return n;
      }
    } catch (_) {
      // Malformed URL — push to the end of the preference order.
    }
    return 1 << 30;
  }

  /// Player poster / work thumbnail: prefer transcoded t=0 frame, else cover.
  ///
  /// [firstFrameUrl] is system-generated at encode time and never overwrites
  /// creator [coverUrl]. Call sites that show episode/short-video chrome should
  /// use this helper (or a model `posterUrl` getter) instead of raw cover.
  static String? preferPosterUrl({
    String? firstFrameUrl,
    String? coverUrl,
  }) {
    final frame = firstFrameUrl?.trim();
    if (frame != null && frame.isNotEmpty) return frame;
    final cover = coverUrl?.trim();
    if (cover != null && cover.isNotEmpty) return cover;
    return null;
  }

  /// Whether [candidate] should replace an already-seeded episode poster.
  ///
  /// Cover-only candidates (equal to [coverOnlyUrl], typically play.coverUrl
  /// when firstFrameUrl is missing) must not displace a different list-seeded
  /// first-frame URL that is already in the image cache.
  static bool shouldReplaceEpisodePoster({
    required String? existing,
    required String? candidate,
    String? coverOnlyUrl,
  }) {
    final next = candidate?.trim();
    if (next == null || next.isEmpty) return false;
    final prev = existing?.trim();
    if (prev == null || prev.isEmpty) return true;
    if (prev == next) return false;
    final cover = coverOnlyUrl?.trim();
    if (cover != null &&
        cover.isNotEmpty &&
        next == cover &&
        prev != cover) {
      return false;
    }
    return true;
  }
}
