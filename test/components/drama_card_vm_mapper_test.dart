import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/components/theater/drama_card_vm.dart';
import 'package:story_app/src/components/theater/drama_card_vm_mapper.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('zh'));
  });

  test('fromSearchFeed short video maps playCount and likeCount cover stats', () {
    final vm = DramaCardVmMapper.fromSearchFeed(
      const FeedItem(
        contentType: 'short_video',
        episodeId: '437115344779304960',
        title: '大唐来了个小兜子',
        description: '大唐来了个小兜子',
        playCount: 513,
        likeCount: 6,
      ),
      l10n: l10n,
    );

    expect(vm.isShortVideo, isTrue);
    expect(vm.coverStats, hasLength(2));
    expect(vm.coverStats[0].kind, DramaCardCoverStatKind.play);
    expect(vm.coverStats[0].label, '513');
    expect(vm.coverStats[1].kind, DramaCardCoverStatKind.like);
    expect(vm.coverStats[1].label, '6');
    expect(vm.headline, '大唐来了个小兜子');
  });

  test('fromSearchFeed drama matches theater card meta and cover stats', () {
    final vm = DramaCardVmMapper.fromSearchFeed(
      const FeedItem(
        contentType: 'drama_episode',
        dramaId: 'd-1',
        episodeId: 'e-1',
        episodeNo: 3,
        title: '重生之门',
        description: '简介不进标题',
        tags: ['悬疑'],
        totalEpisodes: 24,
        playCount: 3200,
        completeCount: 3200,
        totalHeatValue: 3456,
        avgRating: 4.9,
        likeCount: 99,
      ),
      l10n: l10n,
    );

    expect(vm.isShortVideo, isFalse);
    expect(vm.isSingleEpisode, isFalse);
    expect(vm.headline, '重生之门');
    expect(vm.gridMetaLine, '悬疑 · ${l10n.dramaAllEpisodesFull(24)}');
    expect(vm.showActorRolePill, isTrue);
    expect(vm.coverStats, hasLength(3));
    expect(vm.coverStats[0].kind, DramaCardCoverStatKind.complete);
    expect(vm.coverStats[0].label, '3.2k');
    expect(vm.coverStats[1].kind, DramaCardCoverStatKind.heat);
    expect(vm.coverStats[1].label, '3456');
    expect(vm.coverStats[2].kind, DramaCardCoverStatKind.rating);
    expect(vm.coverStats[2].label, '4.9');
  });

  test('fromSearchFeed prefers drama-level 完播/热度/评分 from nested search JSON', () async {
    final item = FeedItem.fromJson(const {
      'type': 'DRAMA_EPISODE',
      'creatorName': 'Rock',
      'drama': {
        'dramaId': '437115344779304960',
        'title': '大唐来了个小兜子',
        'tags': ['穿越'],
        'totalEpisodes': 86,
        'totalPlayCount': '10145',
        'totalCompletedViewCount': '10031',
        'totalHeatValue': 2228.0,
        'avgRating': 4.4,
      },
      'episode': {
        'episodeId': '437115344800276480',
        'episodeNo': 1,
        'contentType': 'SHORT_DRAMA',
        'playCount': '522',
        'completeCount': '460',
        'likeCount': '7',
      },
    });

    expect(item.completeCount, 10031);
    expect(item.totalHeatValue, 2228.0);
    expect(item.avgRating, 4.4);
    expect(item.toDramaListItem().episodeId, isNull);
    expect(item.toDramaListItem().type, 'SHORT_DRAMA');

    final vm = DramaCardVmMapper.fromSearchFeed(item, l10n: l10n);
    expect(vm.isSingleEpisode, isFalse);
    expect(vm.coverStats, hasLength(3));
    expect(vm.coverStats[0].kind, DramaCardCoverStatKind.complete);
    expect(vm.coverStats[1].kind, DramaCardCoverStatKind.heat);
    expect(vm.coverStats[1].label, '2228');
    expect(vm.coverStats[2].kind, DramaCardCoverStatKind.rating);
    expect(vm.coverStats[2].label, '4.4');
  });

  test('fromSearchFeed uses title only without description', () {
    final vm = DramaCardVmMapper.fromSearchFeed(
      const FeedItem(
        contentType: 'drama_episode',
        dramaId: '1',
        title: '剧名',
        description: '简介',
        playCount: 1,
        likeCount: 0,
      ),
      l10n: l10n,
    );

    expect(vm.headline, '剧名');
  });

  test('fromTheaterList uses completeCount heat and rating', () {
    final vm = DramaCardVmMapper.fromTheaterList(
      const DramaListItem(
        id: '4',
        dramaTitle: '重生之门',
        totalCompletedViewCount: 3200,
        totalHeatValue: 3456,
        avgRating: 4.9,
      ),
      l10n: l10n,
    );

    expect(vm.coverStats, hasLength(3));
    expect(vm.coverStats[0].label, '3.2k');
    expect(vm.coverStats[1].kind, DramaCardCoverStatKind.heat);
    expect(vm.coverStats[1].label, '3456');
    expect(vm.coverStats[2].kind, DramaCardCoverStatKind.rating);
    expect(vm.coverStats[2].label, '4.9');
    expect(vm.listRating, 4.9);
  });

  test('fromTheaterList omits rating when avgRating is null or zero', () {
    final nullRating = DramaCardVmMapper.fromTheaterList(
      const DramaListItem(
        id: '5',
        dramaTitle: '无评分',
        totalCompletedViewCount: 100,
        totalHeatValue: 10,
      ),
      l10n: l10n,
    );
    expect(nullRating.coverStats, hasLength(2));
    expect(nullRating.coverStats.any((s) => s.kind == DramaCardCoverStatKind.rating), isFalse);
    expect(nullRating.listRating, isNull);

    final zeroRating = DramaCardVmMapper.fromTheaterList(
      const DramaListItem(
        id: '6',
        dramaTitle: '零分',
        totalCompletedViewCount: 100,
        totalHeatValue: 10,
        avgRating: 0,
      ),
      l10n: l10n,
    );
    expect(zeroRating.coverStats, hasLength(2));
    expect(zeroRating.coverStats.any((s) => s.kind == DramaCardCoverStatKind.rating), isFalse);
    expect(zeroRating.listRating, isNull);
  });

  test('fromProfileOwnWorks shows formatted totalPlayCount with play icon stat', () {
    final vm = DramaCardVmMapper.fromProfileOwnWorks(
      const DramaListItem(
        id: 'ep-1',
        episodeId: 'ep-1',
        episodeNo: 2,
        dramaTitle: '剧名',
        dramaDescription: '单集简介',
        type: 'SHORT_DRAMA',
        totalPlayCount: 13200,
        totalCompletedViewCount: 9999,
        likeCount: 3456,
      ),
      l10n: l10n,
    );

    expect(vm.coverStats, hasLength(2));
    expect(vm.coverStats[0].kind, DramaCardCoverStatKind.play);
    expect(vm.coverStats[0].label, '1.3w');
    expect(vm.coverStats[1].kind, DramaCardCoverStatKind.like);
    expect(vm.coverStats[1].label, '3.5k');
  });

  test('fromProfileOwnWorks omits play stat when totalPlayCount is null', () {
    final vm = DramaCardVmMapper.fromProfileOwnWorks(
      const DramaListItem(
        id: 'ep-2',
        episodeId: 'ep-2',
        type: 'SHORT_VIDEO',
        likeCount: 10,
      ),
      l10n: l10n,
    );

    expect(vm.coverStats, hasLength(1));
    expect(vm.coverStats[0].kind, DramaCardCoverStatKind.like);
    expect(vm.listPlayLabel, isNull);
  });
}
