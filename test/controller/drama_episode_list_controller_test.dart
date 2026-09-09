import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/drama_repository.dart';

class MockDramaRepo extends Mock implements DramaRepository {}

void main() {
  const dramaId = 'd-1';

  late MockDramaRepo repo;

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [dramaRepositoryProvider.overrideWithValue(repo)],
    );
  }

  DramaEpisodeListItem item(int no) => DramaEpisodeListItem(
    episodeId: 'ep-$no',
    dramaId: dramaId,
    episodeNo: no,
    title: '第$no集',
    description: '简介$no',
    coverUrl: 'https://example.com/$no.jpg',
    likeCount: no,
    likedByMe: false,
  );

  setUp(() {
    repo = MockDramaRepo();
  });

  test('load fetches first page', () async {
    when(() => repo.listEpisodes(dramaId)).thenAnswer(
      (_) async =>
          Result.success(PageDto(list: [item(1), item(2)], hasMore: false)),
    );

    final container = createContainer();
    addTearDown(container.dispose);
    container.listen(dramaEpisodeListProvider(dramaId), (_, _) {});

    await container.read(dramaEpisodeListProvider(dramaId).notifier).load();

    final state = container.read(dramaEpisodeListProvider(dramaId));
    expect(state.isLoading, isFalse);
    expect(state.items.map((e) => e.episodeNo), [1, 2]);
    expect(state.hasMore, isFalse);
    verify(() => repo.listEpisodes(dramaId)).called(1);
  });

  test('load(more: true) appends next page', () async {
    when(() => repo.listEpisodes(dramaId)).thenAnswer(
      (_) async =>
          Result.success(PageDto(list: [item(1)], hasMore: true, mark: 'm2')),
    );
    when(() => repo.listEpisodes(dramaId, mark: 'm2')).thenAnswer(
      (_) async => Result.success(PageDto(list: [item(2)], hasMore: false)),
    );

    final container = createContainer();
    addTearDown(container.dispose);
    container.listen(dramaEpisodeListProvider(dramaId), (_, _) {});
    final notifier = container.read(dramaEpisodeListProvider(dramaId).notifier);

    await notifier.load();
    await notifier.load(more: true);

    final state = container.read(dramaEpisodeListProvider(dramaId));
    expect(state.items.map((e) => e.episodeNo), [1, 2]);
    expect(state.hasMore, isFalse);
    verify(() => repo.listEpisodes(dramaId, mark: 'm2')).called(1);
  });

  test('synchronize during loadMore does not join pagination', () async {
    final moreGate = Completer<void>();
    when(() => repo.listEpisodes(dramaId)).thenAnswer(
      (_) async =>
          Result.success(PageDto(list: [item(1)], hasMore: true, mark: 'm2')),
    );
    when(() => repo.listEpisodes(dramaId, mark: 'm2')).thenAnswer((_) async {
      await moreGate.future;
      return Result.success(PageDto(list: [item(2)], hasMore: false));
    });
    when(
      () => repo.listEpisodes(dramaId, forceRefresh: true),
    ).thenAnswer(
      (_) async => Result.success(
        PageDto(list: [item(9)], hasMore: false),
      ),
    );

    final container = createContainer();
    addTearDown(container.dispose);
    container.listen(dramaEpisodeListProvider(dramaId), (_, _) {});
    final notifier = container.read(dramaEpisodeListProvider(dramaId).notifier);

    await notifier.load();
    final moreFuture = notifier.load(more: true);
    // Allow loadMore to enter the repo call before synchronize.
    await Future<void>.delayed(Duration.zero);
    final syncFuture = notifier.synchronize();
    moreGate.complete();
    await Future.wait([moreFuture, syncFuture]);

    final state = container.read(dramaEpisodeListProvider(dramaId));
    // First-page force refresh wins; stale loadMore append must be discarded.
    expect(state.items.map((e) => e.episodeNo), [9]);
    verify(() => repo.listEpisodes(dramaId, forceRefresh: true)).called(1);
  });
}
