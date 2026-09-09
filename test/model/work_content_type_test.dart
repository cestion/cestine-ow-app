import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/work_content_type.dart';

void main() {
  group('WorkContentType.fromApi', () {
    test('defaults to shortDrama', () {
      expect(WorkContentType.fromApi(null), WorkContentType.shortDrama);
      expect(WorkContentType.fromApi(''), WorkContentType.shortDrama);
      expect(
        WorkContentType.fromApi('SHORT_DRAMA'),
        WorkContentType.shortDrama,
      );
      expect(
        WorkContentType.fromApi('drama_episode'),
        WorkContentType.shortDrama,
      );
    });

    test('maps short-video aliases', () {
      expect(
        WorkContentType.fromApi('SHORT_VIDEO'),
        WorkContentType.shortVideo,
      );
      expect(
        WorkContentType.fromApi('short_video'),
        WorkContentType.shortVideo,
      );
      expect(
        WorkContentType.fromApi('short-video'),
        WorkContentType.shortVideo,
      );
    });
  });
}
