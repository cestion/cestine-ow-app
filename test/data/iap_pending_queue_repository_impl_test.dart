import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:story_app/src/data/repository/iap_pending_queue_repository.dart';
import 'package:story_app/src/data/repository/iap_pending_queue_repository_impl.dart';
import 'package:story_app/src/model/iap_pending_item.dart';

void main() {
  late Directory tempDir;
  late IapPendingQueueRepository repo;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'iap_pending_queue_test_',
    );
    Hive.init(tempDir.path);
  });

  setUp(() async {
    repo = IapPendingQueueRepositoryImpl();
    await repo.init();
    for (final item in repo.getAll()) {
      await repo.remove(item.clientOrderId);
    }
  });

  tearDown(() async {
    await repo.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('IapPendingItem serialization', () {
    test('toMap/fromMap round-trips all fields', () {
      final now = DateTime.now();
      final item = IapPendingItem.create(
        clientOrderId: 'order-1',
        productId: 'stamina_100',
        userId: 'user-1',
        now: now,
      ).copyWith(
        orderId: '754ce1d4-6d77-46cd-b121-48bbf8494218',
        storeTransactionId: 'txn-1',
        verificationData: 'receipt-base64',
        retryCount: 3,
        state: IapPendingState.waitingServer,
      );

      final restored = IapPendingItem.fromMap(item.toMap());

      expect(restored, isNotNull);
      expect(restored!.clientOrderId, 'order-1');
      expect(restored.productId, 'stamina_100');
      expect(restored.userId, 'user-1');
      expect(restored.orderId, '754ce1d4-6d77-46cd-b121-48bbf8494218');
      expect(restored.storeTransactionId, 'txn-1');
      expect(restored.verificationData, 'receipt-base64');
      expect(restored.retryCount, 3);
      expect(restored.state, IapPendingState.waitingServer);
      expect(
        restored.createdAt.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });

    test('fromMap returns null on invalid payload', () {
      expect(IapPendingItem.fromMap(null), isNull);
      expect(IapPendingItem.fromMap(<String, dynamic>{}), isNull);
      expect(
        IapPendingItem.fromMap({'clientOrderId': '', 'productId': 'x', 'userId': 'u'}),
        isNull,
      );
    });

    test('isInFlight excludes pendingDelivery/done/cancelled', () {
      final base = IapPendingItem.create(
        clientOrderId: 'order-2',
        productId: 'stamina_100',
        userId: 'user-1',
      );

      expect(base.state, IapPendingState.pendingInit);
      expect(base.isInFlight, isTrue);

      expect(
        base.copyWith(state: IapPendingState.pendingPurchase).isInFlight,
        isTrue,
      );
      expect(
        base.copyWith(state: IapPendingState.waitingServer).isInFlight,
        isTrue,
      );

      // Store transaction already consumed → never blocks other accounts.
      expect(
        base.copyWith(state: IapPendingState.pendingDelivery).isInFlight,
        isFalse,
      );
      expect(
        base.copyWith(state: IapPendingState.done).isInFlight,
        isFalse,
      );
      expect(
        base.copyWith(state: IapPendingState.cancelled).isInFlight,
        isFalse,
      );
    });
  });

  group('IapPendingQueueRepositoryImpl', () {
    test('upsert is idempotent keyed by clientOrderId', () async {
      final first = IapPendingItem.create(
        clientOrderId: 'order-3',
        productId: 'stamina_100',
        userId: 'user-1',
      );
      await repo.upsert(first);

      final second = first.copyWith(
        state: IapPendingState.waitingServer,
        storeTransactionId: 'txn-3',
      );
      await repo.upsert(second);

      final stored = repo.getById('order-3');
      expect(stored, isNotNull);
      expect(stored!.state, IapPendingState.waitingServer);
      expect(stored.storeTransactionId, 'txn-3');
      expect(repo.getAll().length, 1);
    });

    test('getNonDone returns only unfinished entries', () async {
      await repo.upsert(
        IapPendingItem.create(
          clientOrderId: 'a',
          productId: 'stamina_100',
          userId: 'user-1',
        ),
      );
      await repo.upsert(
        IapPendingItem.create(
          clientOrderId: 'b',
          productId: 'stamina_500',
          userId: 'user-1',
        ).copyWith(state: IapPendingState.done),
      );

      final pending = repo.getNonDone();
      expect(pending.map((e) => e.clientOrderId), ['a']);
    });

    test('hasInFlight is scoped by productId and userId', () async {
      await repo.upsert(
        IapPendingItem.create(
          clientOrderId: 'a',
          productId: 'stamina_100',
          userId: 'user-1',
        ).copyWith(state: IapPendingState.waitingServer),
      );

      expect(repo.hasInFlight('stamina_100', 'user-1'), isTrue);
      // Different user (account B) is NOT blocked by user A's entry.
      expect(repo.hasInFlight('stamina_100', 'user-2'), isFalse);
      // Different SKU is not blocked.
      expect(repo.hasInFlight('stamina_500', 'user-1'), isFalse);
      // Settled-for-owner entries never block.
      await repo.upsert(
        repo.getById('a')!.copyWith(state: IapPendingState.pendingDelivery),
      );
      expect(repo.hasInFlight('stamina_100', 'user-1'), isFalse);
    });

    test('remove deletes the entry', () async {
      await repo.upsert(
        IapPendingItem.create(
          clientOrderId: 'a',
          productId: 'stamina_100',
          userId: 'user-1',
        ),
      );
      expect(repo.getById('a'), isNotNull);

      await repo.remove('a');
      expect(repo.getById('a'), isNull);
      expect(repo.getAll(), isEmpty);
    });

    test('getByStoreTransactionId finds entries by txn id', () async {
      await repo.upsert(
        IapPendingItem.create(
          clientOrderId: 'a',
          productId: 'stamina_100',
          userId: 'user-1',
        ).copyWith(storeTransactionId: 'txn-1'),
      );

      expect(repo.getByStoreTransactionId('txn-1')?.clientOrderId, 'a');
      expect(repo.getByStoreTransactionId('txn-nope'), isNull);
    });

    test('getInFlightFor returns the in-flight entry scoped to user/SKU', () async {
      await repo.upsert(
        IapPendingItem.create(
          clientOrderId: 'a',
          productId: 'stamina_100',
          userId: 'user-1',
        ).copyWith(state: IapPendingState.waitingServer),
      );
      await repo.upsert(
        IapPendingItem.create(
          clientOrderId: 'b',
          productId: 'stamina_500',
          userId: 'user-1',
        ).copyWith(state: IapPendingState.pendingPurchase),
      );
      await repo.upsert(
        IapPendingItem.create(
          clientOrderId: 'c',
          productId: 'stamina_100',
          userId: 'user-2',
        ).copyWith(state: IapPendingState.pendingPurchase),
      );
      await repo.upsert(
        IapPendingItem.create(
          clientOrderId: 'd',
          productId: 'stamina_100',
          userId: 'user-1',
        ).copyWith(state: IapPendingState.pendingDelivery),
      );

      expect(repo.getInFlightFor('stamina_100', 'user-1')?.clientOrderId, 'a');
      expect(repo.getInFlightFor('stamina_500', 'user-1')?.clientOrderId, 'b');
      expect(
        repo.getInFlightFor('stamina_100', 'user-2')?.clientOrderId,
        'c',
      );
    });

    test('last logged-in user id survives across entries', () async {
      expect(repo.getLastLoggedInUserId(), isNull);
      await repo.setLastLoggedInUserId('user-9');
      expect(repo.getLastLoggedInUserId(), 'user-9');
    });

    test('cleanupExpired removes cancelled entries past retention', () async {
      final old = DateTime.now().subtract(const Duration(days: 8));
      await repo.upsert(
        IapPendingItem.create(
          clientOrderId: 'old',
          productId: 'stamina_100',
          userId: 'user-1',
          now: old,
        ).copyWith(
          state: IapPendingState.cancelled,
          updatedAt: old,
        ),
      );
      await repo.upsert(
        IapPendingItem.create(
          clientOrderId: 'fresh',
          productId: 'stamina_100',
          userId: 'user-1',
        ),
      );

      final removed = await repo.cleanupExpired(now: DateTime.now());

      expect(removed, 1);
      expect(repo.getById('old'), isNull);
      expect(repo.getById('fresh'), isNotNull);
    });
  });
}
