import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository/iap_pending_queue_repository.dart';
import '../data/repository/iap_pending_queue_repository_impl.dart';
import '../repositories/iap_repository.dart';
import '../services/iap_store_service.dart';
import 'core_providers.dart';

final Provider<IapRepository> iapRepositoryProvider =
    Provider<IapRepository>((ref) {
      final impl = IapRepositoryImpl(
        ref.read(apiClientProvider),
        ref.read(localRepositoryProvider),
      );
      ref.onDispose(() => impl.dispose());
      return impl;
    });

/// Hive-backed pending-delivery queue.
///
/// [FutureProvider] so the box is guaranteed open (`init()` awaited) before
/// any consumer — required by the startup reconcile that must not race the
/// first `Hive.openBox`. Lives for the whole app lifetime.
final FutureProvider<IapPendingQueueRepository>
iapPendingQueueRepositoryProvider =
    FutureProvider<IapPendingQueueRepository>((ref) async {
      final impl = IapPendingQueueRepositoryImpl();
      await impl.init();
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<IapStoreService> iapStoreServiceProvider =
    Provider<IapStoreService>((ref) {
      return IapStoreService();
    });
