import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_prefetch_orchestrator.dart';
import 'package:story_app/src/core/story_constants.dart';

void main() {
  group('FeedPrefetchOrchestrator.shouldPrefetch', () {
    test('keeps disk warming when metadata already exists', () {
      expect(
        FeedPrefetchOrchestrator.shouldPrefetch(
          hasPlayData: true,
          warmDisk: true,
        ),
        isTrue,
      );
    });

    test('skips metadata-only request when metadata already exists', () {
      expect(
        FeedPrefetchOrchestrator.shouldPrefetch(
          hasPlayData: true,
          warmDisk: false,
        ),
        isFalse,
      );
    });

    test('fetches missing metadata regardless of disk warming', () {
      expect(
        FeedPrefetchOrchestrator.shouldPrefetch(
          hasPlayData: false,
          warmDisk: false,
        ),
        isTrue,
      );
    });
  });

  group('StoryConstants.prefetchDiskBudgetRatioForDistance', () {
    test('gives full N+1 and partial N+2 disk budget on WiFi', () {
      expect(StoryConstants.prefetchDiskBudgetRatioForDistance(1), 1.0);
      expect(StoryConstants.prefetchDiskBudgetRatioForDistance(2), 0.35);
      expect(StoryConstants.prefetchDiskBudgetRatioForDistance(3), 0.0);
      expect(StoryConstants.prefetchDiskBudgetRatioForDistance(4), 0.0);
      expect(StoryConstants.prefetchDiskBudgetRatioForDistance(5), 0.0);
    });

    test('wifi metadata window stays wider than disk window', () {
      expect(StoryConstants.prefetchWindowWifi, 5);
      expect(StoryConstants.prefetchDiskWindowWifi, 2);
      expect(
        StoryConstants.prefetchDiskWindowWifi,
        lessThanOrEqualTo(StoryConstants.prefetchWindowWifi),
      );
    });
  });
}
