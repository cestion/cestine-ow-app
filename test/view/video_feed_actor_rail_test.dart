import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/components/common/story_per_hour_unit_label.dart';
import 'package:story_app/src/view/widgets/video_feed/video_feed_actor_rail.dart';
import 'package:story_app/src/view/widgets/video_feed/video_feed_bottom_info.dart';

void main() {
  Widget wrap(Widget child, {ActorCollection? detail}) {
    return ProviderScope(
      overrides: [
        actorCollectionDetailProvider.overrideWith((ref, id) async {
          return Result.success(
            detail ?? ActorCollection(id: id, computingPower: 0),
          );
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('VideoFeedActorRail builds without hanging', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Stack(
          children: [
            VideoFeedActorRail(
              actors: [
                RecommendFeedActor(
                  actorId: '1',
                  actorName: 'A',
                  storyPerHour: 6344,
                  badge: 'VERIFIED',
                ),
                RecommendFeedActor(
                  actorId: '2',
                  actorName: 'B',
                  storyPerHour: 8562,
                ),
                RecommendFeedActor(
                  actorId: '3',
                  actorName: 'C',
                  storyPerHour: 1200,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('/h'), findsWidgets);
  });

  testWidgets('VideoFeedActorRail shows all bound actors', (tester) async {
    await tester.pumpWidget(
      wrap(
        VideoFeedActorRail(
          actors: [
            for (var i = 1; i <= 5; i++)
              RecommendFeedActor(
                actorId: '$i',
                actorName: 'Actor $i',
                storyPerHour: i * 100,
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('/h'), findsNWidgets(5));
    expect(find.text('100'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
  });

  test('formatStoryPerHour defaults omitted rates to 0', () {
    expect(VideoFeedActorRail.formatStoryPerHour(null), '0');
    expect(VideoFeedActorRail.formatStoryPerHour(6344), '6,344');
    expect(VideoFeedActorRail.formatStoryPerHour(0), '0');
    expect(VideoFeedActorRail.formatStoryPerHour(0.01), '0.01');
    expect(VideoFeedActorRail.formatStoryPerHour(0.005), '< 0.01');
    expect(VideoFeedActorRail.formatStoryPerHour(10), '10');
    expect(VideoFeedActorRail.formatStoryPerHour(10.5), '10.5');
  });

  testWidgets('VideoFeedActorRail shows < 0.01 for sub-cent pay rates', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const VideoFeedActorRail(
          actors: [
            RecommendFeedActor(
              actorId: '1',
              actorName: 'Small pay',
              storyPerHour: 0.005,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('< 0.01'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets(
    'VideoFeedActorRail overlays actor-detail computingPower for sub-cent pay',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const VideoFeedActorRail(
            actors: [
              RecommendFeedActor(
                actorId: 'c-1',
                actorName: '王一博',
                storyPerHour: 0,
              ),
            ],
          ),
          detail: const ActorCollection(id: 'c-1', computingPower: 0.005),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('< 0.01'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    },
  );

  testWidgets('VideoFeedActorRail shows icon/h when rate is zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const VideoFeedActorRail(
          actors: [
            RecommendFeedActor(
              actorId: '1',
              actorName: 'Velvet Horizon',
              storyPerHour: 0,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('/h'), findsOneWidget);
  });

  testWidgets('VideoFeedActorRail shows 0 icon/h when rate is omitted', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const VideoFeedActorRail(
          actors: [
            RecommendFeedActor(
              actorId: '1',
              actorName: 'Velvet Horizon',
              avatarUrl: 'https://example.com/a.jpg',
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('/h'), findsOneWidget);
  });

  testWidgets('VideoFeedActorRail skips unitPrice for icon/h', (tester) async {
    await tester.pumpWidget(
      wrap(
        const VideoFeedActorRail(
          actors: [
            RecommendFeedActor(
              actorId: '1',
              actorName: '兵马俑',
              unitPrice: 0.01,
              computingPower: 19,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('0.01'), findsNothing);
    expect(find.text('19'), findsOneWidget);
    expect(find.text('/h'), findsOneWidget);
  });

  testWidgets('VideoFeedActorRail shows 0 when only unitPrice exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const VideoFeedActorRail(
          actors: [
            RecommendFeedActor(actorId: '1', actorName: '兵马俑', unitPrice: 0.01),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('0.01'), findsNothing);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('/h'), findsOneWidget);
  });

  testWidgets('VideoFeedBottomInfo synopsisMaxLines 2 builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              VideoFeedBottomInfo(
                drama: DramaDetail(
                  id: '1',
                  title: '总裁的秘密宠妻',
                  description: '霸道总裁爱上灰姑娘，一场意外的相遇改变了两人的命运，甜蜜与虐恋交织，精彩剧情等你来看。',
                  badge: 'OFFICIAL',
                ),
                currentEpisodeNo: 1,
                showRoles: false,
                showDramaBadge: true,
                synopsisMaxLines: 2,
                pinProgressToBottom: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('总裁的秘密宠妻'), findsOneWidget);
    expect(find.text('官方短剧'), findsOneWidget);
    expect(find.text('社区短剧'), findsNothing);
  });

  testWidgets('alwaysShowDramaBadge keeps feed OFFICIAL badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              VideoFeedBottomInfo(
                drama: DramaDetail(id: '1', title: '邀请二级', badge: 'OFFICIAL'),
                currentEpisodeNo: 1,
                showRoles: false,
                showDramaBadge: true,
                alwaysShowDramaBadge: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('官方短剧'), findsOneWidget);
    expect(find.text('社区短剧'), findsNothing);
  });

  testWidgets('showDramaBadge false hides short-video drama chip', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              VideoFeedBottomInfo(
                drama: DramaDetail(id: '1', title: '短视频标题', badge: 'COMMUNITY'),
                currentEpisodeNo: 1,
                showRoles: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('短视频标题'), findsOneWidget);
    expect(find.text('社区短剧'), findsNothing);
    expect(find.text('官方短剧'), findsNothing);
  });

  testWidgets(
    'alwaysShowDramaBadge falls back to community when badge is null',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                VideoFeedBottomInfo(
                  drama: DramaDetail(id: '1', title: '邀请二级'),
                  currentEpisodeNo: 1,
                  showRoles: false,
                  showDramaBadge: true,
                  alwaysShowDramaBadge: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('社区短剧'), findsOneWidget);
      expect(find.text('邀请二级'), findsOneWidget);
    },
  );

  testWidgets('BottomInfo with null roles and short desc does not hang', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              VideoFeedBottomInfo(
                drama: DramaDetail(title: '大唐来的小公主', description: '宫廷甜宠日常'),
                currentEpisodeNo: 1,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('大唐来的小公主'), findsOneWidget);
    expect(find.text('宫廷甜宠日常'), findsOneWidget);
  });

  testWidgets('prefixSynopsisWithEpisode uses playerEpisodeSynopsis', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              VideoFeedBottomInfo(
                drama: DramaDetail(
                  id: '1',
                  title: '邀请二级',
                  description: '整部剧简介不应优先显示',
                ),
                currentEpisodeNo: 2,
                showRoles: false,
                prefixSynopsisWithEpisode: true,
                synopsis: '加密货币市场的至暗时刻',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('第 2 集｜加密货币市场的至暗时刻'), findsOneWidget);
    expect(find.text('整部剧简介不应优先显示'), findsNothing);
  });

  testWidgets('prefixSynopsisWithEpisode falls back to episode label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              VideoFeedBottomInfo(
                drama: DramaDetail(id: '1', title: '邀请二级'),
                currentEpisodeNo: 2,
                showRoles: false,
                prefixSynopsisWithEpisode: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('第 2 集'), findsOneWidget);
  });
}
