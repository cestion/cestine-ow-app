import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/components/common/actor_role_avatar.dart';
import 'package:story_app/src/components/common/story_per_hour_unit_label.dart';
import 'package:story_app/src/components/theater/drama_card.dart';
import 'package:story_app/src/components/theater/drama_card_vm_mapper.dart';
import 'package:story_app/src/components/theater/drama_cast_actors_dialog.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/l10n/story_l10n.dart';
import 'package:story_app/src/model/models.dart';

Widget _dramaCardHarness({
  required DramaListItem drama,
  bool isGrid = false,
  bool showContentBadge = true,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    home: Scaffold(
      body: Builder(
        builder: (context) => SingleChildScrollView(
          child: DramaCard(
            isGrid: isGrid,
            vm: DramaCardVmMapper.fromTheaterList(
              drama,
              l10n: context.l10n,
              showContentBadge: showContentBadge,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('totalStoryPerHour sums all cast pay rates', () {
    expect(
      DramaCardRolePill.totalStoryPerHour(const [
        DramaActorCollection(storyPerHour: 10, computingPower: 5),
        DramaActorCollection(storyPerHour: 26.3),
        DramaActorCollection(computingPower: 19),
      ]),
      closeTo(55.3, 0.001),
    );
  });

  test('totalStoryPerHour ignores NFT unitPrice-only entries', () {
    expect(
      DramaCardRolePill.totalStoryPerHour(const [
        DramaActorCollection(unitPrice: 0.01, computingPower: 19),
        DramaActorCollection(unitPrice: 99),
      ]),
      19,
    );
  });

  test('stackWidthForCount tightens overlap when showing five avatars', () {
    expect(DramaCardRolePill.stackWidthForCount(4), 92);
    expect(DramaCardRolePill.stackWidthForCount(5), 96);
  });

  testWidgets('role pill shows up to five cast avatars', (tester) async {
    final actors = List.generate(
      5,
      (i) => DramaActorCollection(
        id: 'a$i',
        name: '角色$i',
        avatarUrl: 'https://example.com/$i.png',
        storyPerHour: 10,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: DramaCardRolePill(actors: actors)),
      ),
    );
    await tester.pump();
    expect(find.byType(ActorRoleAvatar), findsNWidgets(5));
  });

  testWidgets('role pill scales down instead of overflowing narrow cards', (
    tester,
  ) async {
    final actors = List.generate(
      5,
      (i) => DramaActorCollection(
        id: 'a$i',
        name: '角色$i',
        avatarUrl: 'https://example.com/$i.png',
        storyPerHour: 1234.5,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: SizedBox(width: 151, child: DramaCardRolePill(actors: actors)),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ActorRoleAvatar), findsNWidgets(5));
  });

  testWidgets('null badge shows community drama label', (tester) async {
    await tester.pumpWidget(
      _dramaCardHarness(
        drama: const DramaListItem(
          id: '1',
          dramaTitle: '测试短剧',
          dramaDescription: '简介',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('社区短剧'), findsOneWidget);
    expect(find.text('简介'), findsOneWidget);
  });

  testWidgets('empty badge string shows community drama label', (tester) async {
    await tester.pumpWidget(
      _dramaCardHarness(
        drama: const DramaListItem(id: '2', dramaTitle: '测试短剧', badge: ''),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('社区短剧'), findsOneWidget);
  });

  testWidgets('official badge keeps official label', (tester) async {
    await tester.pumpWidget(
      _dramaCardHarness(
        drama: const DramaListItem(
          id: '3',
          dramaTitle: '测试短剧',
          badge: 'OFFICIAL',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('官方短剧'), findsOneWidget);
  });

  testWidgets('grid card shows dual-row cover stats', (tester) async {
    await tester.pumpWidget(
      _dramaCardHarness(
        isGrid: true,
        drama: const DramaListItem(
          id: '4',
          dramaTitle: '重生之门',
          dramaDescription: '网格不展示简介',
          totalEpisodes: 24,
          creatorName: 'JACK',
          totalCompletedViewCount: 3200,
          totalHeatValue: 3456,
          avgRating: 4.9,
          actorCollections: [
            DramaActorCollection(
              id: 'a1',
              name: '角色A',
              avatarUrl: 'https://example.com/a.png',
              storyPerHour: 123.4,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('重生之门'), findsOneWidget);
    expect(find.text('网格不展示简介'), findsNothing);
    expect(find.text('3.2k'), findsOneWidget);
    expect(find.text('3456'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.text('全24集'), findsOneWidget);
    expect(find.text('@JACK'), findsOneWidget);
    expect(find.text('123.4'), findsOneWidget);
    expect(find.text('/h'), findsOneWidget);
    expect(find.byType(StoryPerHourUnitLabel), findsOneWidget);
    final cardRect = tester.getRect(find.byType(DramaCard));
    final creatorRect = tester.getRect(find.text('@JACK'));
    expect(creatorRect.right, closeTo(cardRect.right - 10, 1));
  });

  testWidgets('homepage grid card hides content badge', (tester) async {
    await tester.pumpWidget(
      _dramaCardHarness(
        isGrid: true,
        showContentBadge: false,
        drama: const DramaListItem(
          id: '8',
          dramaTitle: '重生之门',
          badge: 'OFFICIAL',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('官方短剧'), findsNothing);
    expect(find.text('社区短剧'), findsNothing);
  });

  testWidgets('grid card keeps @creator trailing without episodes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _dramaCardHarness(
        isGrid: true,
        drama: const DramaListItem(
          id: '6',
          dramaTitle: '重生之门',
          creatorName: 'JACK',
        ),
      ),
    );
    await tester.pump();
    final cardRect = tester.getRect(find.byType(DramaCard));
    final creatorRect = tester.getRect(find.text('@JACK'));
    expect(creatorRect.right, closeTo(cardRect.right - 10, 1));
  });

  testWidgets('search grid cover stats keep left-middle slots', (tester) async {
    late final AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              l10n = context.l10n;
              return SingleChildScrollView(
                child: SizedBox(
                  width: 180,
                  child: GridDramaCard(
                    vm: DramaCardVmMapper.fromSearchFeed(
                      const FeedItem(
                        contentType: 'short_video',
                        episodeId: '1',
                        title: '剧名',
                        playCount: 513,
                        likeCount: 6,
                      ),
                      l10n: l10n,
                    ),
                    showPlayCount: true,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final playRect = tester.getRect(find.text('513'));
    final likeRect = tester.getRect(find.text('6'));
    final cardRect = tester.getRect(find.byType(GridDramaCard));

    expect(playRect.left, lessThan(likeRect.left));
    // Like stays in the middle third, not pushed to the trailing edge.
    expect(likeRect.center.dx, lessThan(cardRect.center.dx + 20));
    expect(likeRect.right, lessThan(cardRect.right - 24));
  });

  testWidgets('list card keeps description and bottom stats', (tester) async {
    await tester.pumpWidget(
      _dramaCardHarness(
        drama: const DramaListItem(
          id: '5',
          dramaTitle: '重生之门',
          dramaDescription: '单排简介',
          totalEpisodes: 24,
          creatorName: 'JACK',
          totalCompletedViewCount: 3200,
          totalHeatValue: 3456,
          avgRating: 4.9,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('单排简介'), findsOneWidget);
    expect(find.text('全24集'), findsOneWidget);
    expect(find.text('JACK'), findsOneWidget);
    expect(find.text('@JACK'), findsNothing);
    expect(find.text('3.2k'), findsOneWidget);
    expect(find.text('3456'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
  });
}
