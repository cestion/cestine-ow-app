import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/app_providers.dart';
import '../repositories/mining_repository.dart';

/// Coordinates mining-list invalidation after an actor NFT is signed.
///
/// [state] is the cumulative signed count. It intentionally survives tab
/// switches so a retained Agent V2 page can detect changes made elsewhere.
class ActorInventorySyncController extends Notifier<int> {
  MiningRepository get _repository => ref.read(miningRepositoryProvider);

  bool _isReconciling = false;
  int _pendingSignedCount = 0;
  int? _baselineRestActorCount;
  int _signGeneration = 0;

  @override
  int build() => 0;

  Future<void> markActorSigned({
    int count = 1,
    int maxAttempts = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    if (count <= 0 || maxAttempts <= 0) return;

    _signGeneration++;
    _pendingSignedCount += count;

    final cachedPage = await _repository.readCachedRestActors();
    _baselineRestActorCount ??= cachedPage?.totalRow;
    await _repository.invalidateGameCache();
    if (!ref.mounted) return;

    // Publish only after cache eviction so listeners cannot immediately read
    // the stale one-hour rest-actor cache.
    state += count;
    _invalidateActorLists();
    if (_isReconciling) return;

    // The mining indexer may lag behind the successful chain transaction.
    // Poll for the complete MiningActor DTO instead of fabricating one without
    // its server-assigned NFT id and gameplay fields.
    unawaited(
      _reconcileSignedActors(maxAttempts: maxAttempts, retryDelay: retryDelay),
    );
  }

  Future<void> _reconcileSignedActors({
    required int maxAttempts,
    required Duration retryDelay,
  }) async {
    _isReconciling = true;
    final runGeneration = _signGeneration;
    try {
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(retryDelay);
          if (!ref.mounted) return;
        }

        final expectedCount = _baselineRestActorCount == null
            ? null
            : _baselineRestActorCount! + _pendingSignedCount;
        final result = await _repository.refreshRestActors();
        if (!ref.mounted) return;

        final page = result.dataOrNull;
        if (page != null) {
          ref.invalidate(agentV2RestActorsProvider);
          if (expectedCount != null &&
              page.totalRow >= expectedCount &&
              runGeneration == _signGeneration) {
            _pendingSignedCount = 0;
            _baselineRestActorCount = page.totalRow;
            return;
          }
        }
      }

      // Even without a baseline, the final network result is now in cache and
      // will be consumed when the Agent tab or candidate sheet opens.
      if (runGeneration == _signGeneration) {
        _pendingSignedCount = 0;
        _baselineRestActorCount = null;
      }
    } finally {
      _isReconciling = false;
      if (ref.mounted &&
          _pendingSignedCount > 0 &&
          runGeneration != _signGeneration) {
        unawaited(
          _reconcileSignedActors(
            maxAttempts: maxAttempts,
            retryDelay: retryDelay,
          ),
        );
      }
    }
  }

  void _invalidateActorLists() {
    ref.invalidate(agentV2RestActorsProvider);
    ref.invalidate(agentV2CandidateActorsControllerProvider);
    ref.invalidate(agentV2UpgradeableActorsControllerProvider);
  }
}
