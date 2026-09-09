import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/components/common/story_share.dart';
import 'package:story_app/src/l10n/app_localizations_zh.dart';
import 'package:story_app/src/model/work_content_type.dart';

void main() {
  final l10n = AppLocalizationsZh();

  group('StoryShare.resolvePlayId', () {
    test('short video prefers episodeId', () {
      expect(
        StoryShare.resolvePlayId(
          contentType: WorkContentType.shortVideo,
          dramaId: 'drama',
          episodeId: 'ep-1',
        ),
        'ep-1',
      );
    });

    test('short video falls back to dramaId', () {
      expect(
        StoryShare.resolvePlayId(
          contentType: WorkContentType.shortVideo,
          dramaId: 'work-1',
        ),
        'work-1',
      );
    });

    test('short drama prefers dramaId', () {
      expect(
        StoryShare.resolvePlayId(
          contentType: WorkContentType.shortDrama,
          dramaId: 'drama',
          episodeId: 'ep-1',
        ),
        'drama',
      );
    });
  });

  group('StoryShare.truncateDescription', () {
    test('keeps short text', () {
      expect(StoryShare.truncateDescription('你好世界'), '你好世界');
    });

    test('truncates at 20 graphemes with ellipsis', () {
      expect(
        StoryShare.truncateDescription('一二三四五六七八九十一二三四五六七八九十多余'),
        '一二三四五六七八九十一二三四五六七八九十...',
      );
    });
  });

  group('StoryShare.buildShareText', () {
    test('formats short drama episode with description', () {
      expect(
        StoryShare.buildShareText(
          l10n: l10n,
          contentType: WorkContentType.shortDrama,
          url: 'https://story.fun/play/430849900704436224',
          title: '短剧名称',
          episodeNo: 2,
          description: '这是一段很长的分集描述语超过二十个字用来截断测试内容',
        ),
        '短剧名称 | 第2集：这是一段很长的分集描述语超过二十个字用来... '
        'https://story.fun/play/430849900704436224 。来 StoryFun，观看精美AI短剧。',
      );
    });

    test('formats short video with description', () {
      expect(
        StoryShare.buildShareText(
          l10n: l10n,
          contentType: WorkContentType.shortVideo,
          url: 'https://story.fun/play/430849900704436224',
          description: '短视频描述最多二十个字然后还有更多内容会被截掉',
        ),
        '短视频描述最多二十个字然后还有更多内容会... '
        'https://story.fun/play/430849900704436224。来 StoryFun，观看精美短视频。',
      );
    });

    test('formats short video without description', () {
      expect(
        StoryShare.buildShareText(
          l10n: l10n,
          contentType: WorkContentType.shortVideo,
          url: 'https://story.fun/play/abc',
        ),
        'https://story.fun/play/abc。来 StoryFun，观看精美短视频。',
      );
    });
  });
}
