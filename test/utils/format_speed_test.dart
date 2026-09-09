import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/styles/story_format.dart';

void main() {
  group('StoryFormat.formatSpeed', () {
    test('returns empty for non-positive rates', () {
      expect(StoryFormat.formatSpeed(0), '');
      expect(StoryFormat.formatSpeed(-1), '');
    });

    test('formats KB/s below 1 MB/s', () {
      expect(StoryFormat.formatSpeed(512 * 1024), '512.0 KB/s');
      expect(StoryFormat.formatSpeed(1024), '1.0 KB/s');
    });

    test('formats MB/s at and above 1 MB/s', () {
      expect(StoryFormat.formatSpeed(1024 * 1024), '1.0 MB/s');
      expect(StoryFormat.formatSpeed((1.4 * 1024 * 1024).round()), '1.4 MB/s');
      expect(StoryFormat.formatSpeed(10 * 1024 * 1024), '10.0 MB/s');
    });
  });
}
