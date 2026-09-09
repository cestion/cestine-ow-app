import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/story_sdk.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/story_l10n.dart';
import '../../model/work_content_type.dart';

/// System share helper for `/play/:id` links.
class StoryShare {
  StoryShare._();

  static const MethodChannel _iosShareChannel = MethodChannel(
    'com.cestine.officeapp/share',
  );

  /// Max grapheme length for share description snippets.
  static const int descriptionMaxChars = 20;

  /// Resolve the id in `https://…/play/{id}`.
  ///
  /// Short videos must use [episodeId] (work id). Short dramas prefer
  /// [dramaId], falling back to [episodeId] when the series id is missing.
  static String resolvePlayId({
    required WorkContentType contentType,
    required String dramaId,
    String? episodeId,
  }) {
    final ep = episodeId?.trim() ?? '';
    if (contentType.isShortVideo) {
      if (ep.isNotEmpty) return ep;
      return dramaId.trim();
    }
    final drama = dramaId.trim();
    if (drama.isNotEmpty) return drama;
    return ep;
  }

  /// Truncate [raw] to [maxChars] graphemes, appending `...` when clipped.
  @visibleForTesting
  static String truncateDescription(
    String? raw, [
    int maxChars = descriptionMaxChars,
  ]) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return '';
    final chars = s.characters;
    if (chars.length <= maxChars) return s;
    return '${chars.take(maxChars)}...';
  }

  /// Build the system-share / clipboard body for a playable work.
  @visibleForTesting
  static String buildShareText({
    required AppLocalizations l10n,
    required WorkContentType contentType,
    required String url,
    String? title,
    int episodeNo = 1,
    String? description,
  }) {
    final desc = truncateDescription(description);
    if (contentType.isShortVideo) {
      if (desc.isEmpty) return l10n.playerShareShortVideoNoDesc(url);
      return l10n.playerShareShortVideo(desc, url);
    }
    final name = title?.trim() ?? '';
    final ep = episodeNo < 1 ? 1 : episodeNo;
    if (desc.isEmpty) {
      return l10n.playerShareDramaEpisodeNoDesc(name, ep, url);
    }
    return l10n.playerShareDramaEpisode(name, ep, desc, url);
  }

  /// Share a short-drama episode or short video from the player rail.
  static Future<void> sharePlayable({
    required BuildContext context,
    required WorkContentType contentType,
    required String dramaId,
    String? episodeId,
    String? title,
    int episodeNo = 1,
    String? description,
    Future<void> Function(Future<void> Function() share)? aroundShare,
  }) async {
    final playId = resolvePlayId(
      contentType: contentType,
      dramaId: dramaId,
      episodeId: episodeId,
    );
    if (playId.isEmpty) return;

    final l10n = context.l10n;
    final url = StorySdk.instance.config.env.dramaShareUrl(playId);
    final text = buildShareText(
      l10n: l10n,
      contentType: contentType,
      url: url,
      title: title,
      episodeNo: episodeNo,
      description: description,
    );
    final subject = contentType.isShortVideo
        ? truncateDescription(description, 40)
        : (title?.trim().isNotEmpty == true ? title!.trim() : null);

    await _present(
      context: context,
      text: text,
      subject: subject,
      aroundShare: aroundShare,
    );
  }

  /// Share a whole short drama (detail page) — title + link + StoryFun footer.
  static Future<void> shareDrama({
    required BuildContext context,
    required String dramaId,
    String? title,
    String? fallbackTitle,
    Future<void> Function(Future<void> Function() share)? aroundShare,
  }) async {
    final id = dramaId.trim();
    if (id.isEmpty) return;

    final l10n = context.l10n;
    final shareTitle = _resolveTitle(title, fallbackTitle) ?? '';
    final url = StorySdk.instance.config.env.dramaShareUrl(id);
    final text = shareTitle.isEmpty
        ? l10n.playerShareDramaNoTitle(url)
        : l10n.playerShareDrama(shareTitle, url);

    await _present(
      context: context,
      text: text,
      subject: shareTitle.isEmpty ? null : shareTitle,
      aroundShare: aroundShare,
    );
  }

  static Future<void> _present({
    required BuildContext context,
    required String text,
    String? subject,
    Future<void> Function(Future<void> Function() share)? aroundShare,
  }) async {
    final origin = _shareOrigin(context);

    Future<void> doShare() async {
      // iPhone: present from an elevated UIWindow so PlatformViews cannot
      // steal dimming-view taps (share_plus presents on FlutterViewController).
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _iosShareChannel
            .invokeMethod<void>('shareText', <String, Object?>{
              'text': text,
              'subject': subject,
              'originX': origin.left,
              'originY': origin.top,
              'originW': origin.width,
              'originH': origin.height,
            });
        return;
      }
      await SharePlus.instance.share(
        ShareParams(text: text, title: subject, sharePositionOrigin: origin),
      );
    }

    final wrap = aroundShare;
    if (wrap != null) {
      await wrap(doShare);
    } else {
      await doShare();
    }
  }

  static String? _resolveTitle(String? title, String? fallbackTitle) {
    for (final candidate in [title, fallbackTitle]) {
      final trimmed = candidate?.trim();
      if (trimmed != null && trimmed.isNotEmpty && trimmed != '播放') {
        return trimmed;
      }
    }
    return null;
  }

  static Rect _shareOrigin(BuildContext? context) {
    if (context != null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final rect = box.localToGlobal(Offset.zero) & box.size;
        if (rect.width >= 1 && rect.height >= 1) return rect;
      }
    }
    return const Rect.fromLTWH(0, 0, 1, 1);
  }
}
