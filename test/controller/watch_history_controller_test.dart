import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/user_repository.dart';

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  late _MockUserRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockUserRepository();
    container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('drama controller loads once and appends cursor pages', () async {
    when(repository.getWatchHistoryDramas).thenAnswer(
      (_) async => Result.success(
        const PageDto(
          list: [WatchHistoryDrama(dramaId: 'd1')],
          mark: 'cursor_1',
          hasMore: true,
        ),
      ),
    );
    when(() => repository.getWatchHistoryDramas(mark: 'cursor_1')).thenAnswer(
      (_) async => Result.success(
        const PageDto(
          list: [WatchHistoryDrama(dramaId: 'd2')],
          mark: 'cursor_2',
          hasMore: false,
        ),
      ),
    );
    final subscription = container.listen(
      watchHistoryDramaControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final controller = container.read(
      watchHistoryDramaControllerProvider.notifier,
    );

    await controller.ensureLoaded();
    await controller.ensureLoaded();
    await controller.loadMore();

    final state = container.read(watchHistoryDramaControllerProvider);
    expect(state.items.map((item) => item.dramaId), ['d1', 'd2']);
    expect(state.hasMore, isFalse);
    verify(repository.getWatchHistoryDramas).called(1);
    verify(() => repository.getWatchHistoryDramas(mark: 'cursor_1')).called(1);
  });

  test(
    'video controller clears VIDEO scope and empties only its state',
    () async {
      when(repository.getWatchHistoryVideos).thenAnswer(
        (_) async => Result.success(
          const PageDto(
            list: [WatchHistoryVideo(episodeId: 'e1')],
            hasMore: false,
          ),
        ),
      );
      when(
        () => repository.clearWatchHistory(scope: WatchHistoryClearScope.video),
      ).thenAnswer((_) async => Result.success(null));
      final subscription = container.listen(
        watchHistoryVideoControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      final controller = container.read(
        watchHistoryVideoControllerProvider.notifier,
      );

      await controller.ensureLoaded();
      final result = await controller.clearHistory();

      expect(result.isSuccess, isTrue);
      expect(
        container.read(watchHistoryVideoControllerProvider).items,
        isEmpty,
      );
      verify(
        () => repository.clearWatchHistory(scope: WatchHistoryClearScope.video),
      ).called(1);
    },
  );
}
