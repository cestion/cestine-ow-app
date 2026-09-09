import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:story_app/src/controller/drama_management_controller.dart';
import 'package:story_app/src/controller/drama_management_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/repositories/drama_repository.dart';

class MockDramaRepository extends Mock implements DramaRepository {}

void main() {
  late ProviderContainer container;
  late DramaManagementController controller;
  late MockDramaRepository dramaRepo;

  setUp(() {
    dramaRepo = MockDramaRepository();

    when(
      () => dramaRepo.listMyCreatorDramas(
        mark: any(named: 'mark'),
        pageSize: any(named: 'pageSize'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async => Result<PageDto<CreatorDrama>>.success(
        const PageDto(list: [], hasMore: false),
      ),
    );

    when(
      () => dramaRepo.deleteDrama(any()),
    ).thenAnswer((_) async => Result<void>.success(null));

    when(
      () =>
          dramaRepo.invalidateCreatorDramasCache(status: any(named: 'status')),
    ).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [dramaRepositoryProvider.overrideWithValue(dramaRepo)],
    );
    controller = container.read(dramaManagementControllerProvider.notifier);
    container.listen(dramaManagementControllerProvider, (prev, next) {});
  });

  tearDown(() {
    container.dispose();
  });

  group('DramaManagementController', () {
    test('initial state uses DramaManagementStatus.all and empty items', () {
      final state = container.read(dramaManagementControllerProvider);
      expect(state.currentStatus, DramaManagementStatus.all);
      expect(state.items, isEmpty);
      expect(state.hasMore, isTrue);
      expect(state.activeDialog, DramaManagementDialog.closed);
    });

    test('can rebuild after provider invalidation', () {
      container.invalidate(dramaManagementControllerProvider);

      expect(
        () => container.read(dramaManagementControllerProvider),
        returnsNormally,
      );
    });

    test('refresh loads first page via repo with null status', () async {
      await controller.refresh();

      verify(
        () => dramaRepo.listMyCreatorDramas(
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          status: any(named: 'status'),
        ),
      ).called(1);
      expect(container.read(dramaManagementControllerProvider).items, isEmpty);
    });

    test(
      'silentRefresh keeps items visible until fresh data arrives',
      () async {
        when(
          () => dramaRepo.listMyCreatorDramas(
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async => Result<PageDto<CreatorDrama>>.success(
            const PageDto(
              list: [
                CreatorDrama(
                  id: 'pending',
                  title: 'Pending',
                  status: 'PENDING_REVIEW',
                ),
              ],
              hasMore: false,
            ),
          ),
        );
        await controller.refresh();

        final response = Completer<Result<PageDto<CreatorDrama>>>();
        when(
          () => dramaRepo.listMyCreatorDramas(
            mark: any(named: 'mark'),
            pageSize: any(named: 'pageSize'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) => response.future);

        final refresh = controller.silentRefresh();
        expect(
          container.read(dramaManagementControllerProvider).items.single.id,
          'pending',
        );
        expect(
          container.read(dramaManagementControllerProvider).isLoading,
          isFalse,
        );

        response.complete(
          Result<PageDto<CreatorDrama>>.success(
            const PageDto(
              list: [
                CreatorDrama(id: 'online', title: 'Online', status: 'ONLINE'),
              ],
              hasMore: false,
            ),
          ),
        );

        expect(await refresh, isFalse);
        expect(
          container.read(dramaManagementControllerProvider).items.single.id,
          'online',
        );
      },
    );

    test('silentRefresh reports pending review data for polling', () async {
      when(
        () => dramaRepo.listMyCreatorDramas(
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<CreatorDrama>>.success(
          const PageDto(
            list: [
              CreatorDrama(
                id: '1',
                title: 'Pending',
                status: ' pending_review ',
              ),
            ],
            hasMore: false,
          ),
        ),
      );

      expect(await controller.silentRefresh(), isTrue);
      expect(
        container.read(dramaManagementControllerProvider).hasPendingReview,
        isTrue,
      );
    });

    test('selectStatus(online) refreshes with status=ONLINE', () async {
      final dramas = [
        const CreatorDrama(id: '1', title: 'A', status: 'ONLINE'),
      ];
      when(
        () => dramaRepo.listMyCreatorDramas(
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          status: 'ONLINE',
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<CreatorDrama>>.success(
          PageDto(list: dramas, hasMore: false),
        ),
      );

      await controller.selectStatus(DramaManagementStatus.online);

      final state = container.read(dramaManagementControllerProvider);
      expect(state.currentStatus, DramaManagementStatus.online);
      expect(state.items.length, 1);
      expect(state.items.first.id, '1');
    });

    test('selectStatus(offline) refreshes with status=OFFLINE', () async {
      when(
        () => dramaRepo.listMyCreatorDramas(
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          status: 'OFFLINE',
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<CreatorDrama>>.success(
          const PageDto(
            list: [
              CreatorDrama(
                id: 'offline-1',
                title: 'Offline',
                status: 'OFFLINE',
              ),
            ],
            hasMore: false,
          ),
        ),
      );

      await controller.selectStatus(DramaManagementStatus.offline);

      final state = container.read(dramaManagementControllerProvider);
      expect(state.currentStatus, DramaManagementStatus.offline);
      expect(state.items.single.id, 'offline-1');
    });

    test('selectStatus resets pagination before fetching', () async {
      // Seed some items first
      when(
        () => dramaRepo.listMyCreatorDramas(
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<CreatorDrama>>.success(
          const PageDto(
            list: [CreatorDrama(id: '1', title: 'A')],
            hasMore: false,
          ),
        ),
      );
      await controller.refresh();
      expect(container.read(dramaManagementControllerProvider).items.length, 1);

      // Switch status; first response returns empty
      when(
        () => dramaRepo.listMyCreatorDramas(
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          status: 'PENDING_REVIEW',
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<CreatorDrama>>.success(
          const PageDto(list: [], hasMore: false),
        ),
      );
      await controller.selectStatus(DramaManagementStatus.pendingReview);

      final state = container.read(dramaManagementControllerProvider);
      expect(state.currentStatus, DramaManagementStatus.pendingReview);
      expect(state.items, isEmpty);
    });

    test('confirmDeleteDrama removes the drama from items', () async {
      final dramas = [
        const CreatorDrama(id: '1', title: 'A'),
        const CreatorDrama(id: '2', title: 'B'),
      ];
      when(
        () => dramaRepo.listMyCreatorDramas(
          mark: any(named: 'mark'),
          pageSize: any(named: 'pageSize'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => Result<PageDto<CreatorDrama>>.success(
          PageDto(list: dramas, hasMore: false),
        ),
      );
      await controller.refresh();
      expect(container.read(dramaManagementControllerProvider).items.length, 2);

      controller.requestDeleteDrama(dramas.first);
      expect(
        container.read(dramaManagementControllerProvider).activeDialog,
        DramaManagementDialog.deleteDramaConfirm,
      );

      final deleted = await controller.confirmDeleteDrama();

      final state = container.read(dramaManagementControllerProvider);
      expect(deleted, isTrue);
      expect(state.activeDialog, DramaManagementDialog.closed);
      expect(state.items.length, 1);
      expect(state.items.first.id, '2');
      verify(() => dramaRepo.deleteDrama('1')).called(1);
    });

    test('closeDialog resets activeDialog to closed', () {
      controller.requestDeleteDrama(const CreatorDrama(id: '1', title: 'A'));
      controller.closeDialog();
      expect(
        container.read(dramaManagementControllerProvider).activeDialog,
        DramaManagementDialog.closed,
      );
    });
  });
}
