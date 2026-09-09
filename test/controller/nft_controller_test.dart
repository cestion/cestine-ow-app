import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/nft_controller.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/actor_repository.dart';

class MockActorRepo extends Mock implements ActorRepository {}

void main() {
  late ProviderContainer container;
  late NftController controller;
  late MockActorRepo actorRepo;

  setUp(() {
    actorRepo = MockActorRepo();
    when(
      () => actorRepo.listActorCollections(
        pageSize: any(named: 'pageSize'),
        mark: any(named: 'mark'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer(
      (_) async => Result.success(const PageDto(list: [], hasMore: false)),
    );
    when(() => actorRepo.getDetail(any())).thenAnswer(
      (_) async => Result.success(const Actor(id: 'a1', name: 'Actor 1')),
    );
    when(
      () => actorRepo.getCastDramas(
        any(),
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (_) async => Result.success(const PageDto(list: [], hasMore: false)),
    );
    when(() => actorRepo.getActorCollectionDetail(any())).thenAnswer(
      (_) async =>
          Result.success(const ActorCollection(id: 'c1', name: 'Coll 1')),
    );

    container = ProviderContainer(
      overrides: [actorRepositoryProvider.overrideWithValue(actorRepo)],
    );
    controller = container.read(nftControllerProvider.notifier);
    // Permanent listener prevents autoDispose during async gaps
    container.listen(nftControllerProvider, (prev, next) {});
  });

  tearDown(() {
    container.dispose();
  });

  group('NftController', () {
    test('initial state is empty', () {
      expect(controller.items, isEmpty);
      expect(controller.isLoading, false);
    });

    test('ensureLoaded loads actor collections when empty', () async {
      const actors = [ActorCollection(id: 'a1', name: 'Actor 1')];
      when(
        () => actorRepo.listActorCollections(
          pageSize: any(named: 'pageSize'),
          mark: any(named: 'mark'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer(
        (_) async =>
            Result.success(const PageDto(list: actors, hasMore: false)),
      );

      await controller.ensureLoaded();
      expect(controller.items.length, 1);
    });

    test('ensureLoaded skips when feed already loaded', () async {
      const actors = [ActorCollection(id: 'a1', name: 'Actor 1')];
      when(
        () => actorRepo.listActorCollections(
          pageSize: any(named: 'pageSize'),
          mark: any(named: 'mark'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer(
        (_) async =>
            Result.success(const PageDto(list: actors, hasMore: false)),
      );

      await controller.refresh();
      clearInteractions(actorRepo);
      await controller.ensureLoaded();
      verifyNever(
        () => actorRepo.listActorCollections(
          pageSize: any(named: 'pageSize'),
          mark: any(named: 'mark'),
          sort: any(named: 'sort'),
        ),
      );
    });

    test('refresh loads actor collections', () async {
      const actors = [
        ActorCollection(id: 'a1', name: 'Actor 1'),
        ActorCollection(id: 'a2', name: 'Actor 2'),
      ];
      when(
        () => actorRepo.listActorCollections(
          pageSize: any(named: 'pageSize'),
          mark: any(named: 'mark'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer(
        (_) async =>
            Result.success(const PageDto(list: actors, hasMore: false)),
      );

      await controller.refresh();
      expect(controller.items.length, 2);
    });

    test('setSort changes sort and refreshes', () async {
      when(
        () => actorRepo.listActorCollections(
          pageSize: any(named: 'pageSize'),
          mark: any(named: 'mark'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer(
        (_) async => Result.success(const PageDto(list: [], hasMore: false)),
      );

      await controller.setSort(ActorCollectionSort.computingPower);
      expect(controller.sort, ActorCollectionSort.computingPower);
    });

    test('getDetail returns actor', () async {
      final result = await controller.getDetail('a1');
      expect(result.isSuccess, true);
      expect(result.dataOrNull?.id, 'a1');
    });

    test('getCastDramas returns dramas', () async {
      const dramas = [DramaListItem(id: 'd1', dramaTitle: 'Drama 1')];
      when(
        () => actorRepo.getCastDramas(
          'a1',
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async =>
            Result.success(const PageDto(list: dramas, hasMore: false)),
      );

      final result = await controller.getCastDramas('a1');
      expect(result.isSuccess, true);
      expect(result.dataOrNull?.list?.length, 1);
    });
  });
}
