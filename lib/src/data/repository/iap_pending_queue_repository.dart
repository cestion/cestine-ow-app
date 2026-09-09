import '../../model/iap_pending_item.dart';

/// Local persistence of the IAP pending-delivery queue (design §4.1 / §6.1).
///
/// The queue survives logout and is bound to [IapPendingItem.userId]. It
/// lives in a dedicated Hive box (`iap_pending_queue`) that is deliberately
/// separate from `story_local_cache` so auth resets never clear it.
abstract class IapPendingQueueRepository {
  Future<void> init();
  Future<void> dispose();

  /// All entries in the queue (any state).
  List<IapPendingItem> getAll();

  /// Entries that are not [IapPendingState.done] — startup reconcile target.
  List<IapPendingItem> getNonDone();

  IapPendingItem? getById(String clientOrderId);

  /// Finds an entry by store transaction id (dedupe for purchaseStream).
  IapPendingItem? getByStoreTransactionId(String storeTransactionId);

  /// Returns the store-side in-flight entry for [productId] owned by
  /// [userId] (`pendingPurchase`/`waitingServer`), used to correlate a
  /// purchaseStream confirmation back to its local order.
  IapPendingItem? getInFlightFor(String productId, String userId);

  /// Idempotent insert/update keyed by [IapPendingItem.clientOrderId].
  Future<void> upsert(IapPendingItem item);

  Future<void> remove(String clientOrderId);

  /// Whether [userId] has a store-side in-flight entry for [productId]
  /// (blocks re-purchase of the same SKU, design §6.2 / §12.1).
  bool hasInFlight(String productId, String userId);

  /// Last logged-in user id on this device (best-effort attribution of
  /// orphaned store transactions, design §12.4). Stored in the queue box so
  /// it survives logout.
  String? getLastLoggedInUserId();
  Future<void> setLastLoggedInUserId(String userId);

  /// Purges expired bookkeeping entries (e.g. `cancelled` past retention).
  /// Returns the number of removed entries.
  Future<int> cleanupExpired({DateTime? now});
}
