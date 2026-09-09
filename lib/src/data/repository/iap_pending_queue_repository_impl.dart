import '../../core/iap_config.dart';
import '../../core/story_logger.dart';
import '../../foundation/hive_mixin.dart';
import '../../model/iap_pending_item.dart';
import 'iap_pending_queue_repository.dart';

/// Hive-backed [IapPendingQueueRepository].
///
/// Storage layout: box [IapConfig.queueBoxName], key = `clientOrderId`,
/// value = `Map` produced by [IapPendingItem.toMap]. No Hive type adapters
/// required (plain maps, mirroring `story_local_cache`).
///
/// Note: the box is intentionally **not** purged by env reconcile — it is
/// user-bound and must survive environment switches / auth resets.
class IapPendingQueueRepositoryImpl
    with HiveMixin<dynamic>
    implements IapPendingQueueRepository {
  @override
  String get boxName => IapConfig.queueBoxName;

  @override
  Future<void> init() async {
    await initBox();
    StoryLogger.d(
      'IapPendingQueue opened (entries=${box.isOpen ? box.length : 0})',
      tag: 'IapPendingQueue',
    );
  }

  @override
  Future<void> dispose() => disposeBox();

  @override
  List<IapPendingItem> getAll() {
    if (!box.isOpen) return const [];
    final items = <IapPendingItem>[];
    for (final raw in box.values) {
      final item = IapPendingItem.fromMap(raw);
      if (item != null) items.add(item);
    }
    return items;
  }

  @override
  List<IapPendingItem> getNonDone() {
    return getAll()
        .where((item) => item.state != IapPendingState.done)
        .toList(growable: false);
  }

  @override
  IapPendingItem? getById(String clientOrderId) {
    if (!box.isOpen) return null;
    final raw = box.get(clientOrderId);
    if (raw == null) return null;
    return IapPendingItem.fromMap(raw);
  }

  @override
  IapPendingItem? getByStoreTransactionId(String storeTransactionId) {
    if (!box.isOpen) return null;
    for (final item in getAll()) {
      if (item.storeTransactionId == storeTransactionId) return item;
    }
    return null;
  }

  @override
  IapPendingItem? getInFlightFor(String productId, String userId) {
    if (!box.isOpen) return null;
    for (final item in getAll()) {
      if (item.productId == productId &&
          item.userId == userId &&
          item.isInFlight) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(IapPendingItem item) async {
    if (!box.isOpen) return;
    await box.put(item.clientOrderId, item.toMap());
  }

  @override
  Future<void> remove(String clientOrderId) async {
    if (!box.isOpen) return;
    await box.delete(clientOrderId);
  }

  @override
  bool hasInFlight(String productId, String userId) {
    if (!box.isOpen) return false;
    return getAll().any(
      (item) =>
          item.productId == productId &&
          item.userId == userId &&
          item.isInFlight,
    );
  }

  @override
  String? getLastLoggedInUserId() {
    if (!box.isOpen) return null;
    final raw = box.get(IapConfig.lastLoggedInUserIdKey);
    return raw is String ? raw : null;
  }

  @override
  Future<void> setLastLoggedInUserId(String userId) async {
    if (!box.isOpen) return;
    await box.put(IapConfig.lastLoggedInUserIdKey, userId);
  }

  @override
  Future<int> cleanupExpired({DateTime? now}) async {
    if (!box.isOpen) return 0;
    final current = now ?? DateTime.now();
    final expired = <String>[];
    for (final item in getAll()) {
      final cancelledPastRetention = item.state == IapPendingState.cancelled &&
          current.difference(item.updatedAt) > IapConfig.cancelledRetention;
      if (cancelledPastRetention) {
        expired.add(item.clientOrderId);
      }
    }
    if (expired.isNotEmpty) {
      await box.deleteAll(expired);
      StoryLogger.d(
        'IapPendingQueue cleanup removed ${expired.length} expired entries',
        tag: 'IapPendingQueue',
      );
    }
    return expired.length;
  }
}
