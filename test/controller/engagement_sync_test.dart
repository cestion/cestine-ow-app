import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:story_app/src/controller/engagement_state.dart';
import 'package:story_app/src/controller/engagement_sync.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';

void main() {
  const key = EpisodeEngagementKey(
    dramaId: 'drama-1',
    episodeId: 'episode-1',
    episodeNo: 1,
  );

  group('reconcileEngagementBool', () {
    test(
      'keeps store true when visible is stale false but API play is true',
      () {
        expect(
          reconcileEngagementBool(
            store: true,
            visible: false,
            authoritativePlay: true,
          ),
          isTrue,
        );
      },
    );

    test('downgrades store true when API play is also false', () {
      expect(
        reconcileEngagementBool(
          store: true,
          visible: false,
          authoritativePlay: false,
        ),
        isFalse,
      );
    });

    test('preserves store true when API play is unknown', () {
      expect(reconcileEngagementBool(store: true, visible: false), isTrue);
    });

    test('accepts visible true over store false', () {
      expect(reconcileEngagementBool(store: false, visible: true), isTrue);
    });

    test('fills cold store from visible', () {
      expect(reconcileEngagementBool(store: null, visible: false), isFalse);
    });
  });

  group('VisibleEpisodeEngagement.reconcileWithStore', () {
    test('does not clobber store like after stale list-row seed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(episodeEngagementProvider(key), (_, _) {});
      final notifier = container.read(episodeEngagementProvider(key).notifier);
      notifier.applyVisible(likedByMe: true, likeCount: 12);

      const visible = VisibleEpisodeEngagement(likedByMe: false, likeCount: 8);
      visible
          .reconcileWithStore(
            container.read(episodeEngagementProvider(key)),
            authoritativePlay: const DramaPlayResponse(
              episodeId: 'episode-1',
              likedByMe: true,
              likeCount: 12,
            ),
          )
          .applyTo(notifier);

      final state = container.read(episodeEngagementProvider(key));
      expect(state.likedByMe, isTrue);
      expect(state.likeCount, 8);
    });

    test('reconciles retained store true away when API play is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(episodeEngagementProvider(key), (_, _) {});
      final notifier = container.read(episodeEngagementProvider(key).notifier);
      notifier.seed(likedByMe: true, likeCount: 9);

      const visible = VisibleEpisodeEngagement(likedByMe: false, likeCount: 8);
      visible
          .reconcileWithStore(
            container.read(episodeEngagementProvider(key)),
            authoritativePlay: const DramaPlayResponse(
              episodeId: 'episode-1',
              likedByMe: false,
              likeCount: 8,
            ),
          )
          .applyTo(notifier);

      final state = container.read(episodeEngagementProvider(key));
      expect(state.likedByMe, isFalse);
      expect(state.likeCount, 8);
    });
  });
}
