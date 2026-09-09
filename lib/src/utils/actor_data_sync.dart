import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/nft/actor_sign_dialog.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../controller/user_profile_actor_collections_state.dart';
import '../utils/actor_pricing.dart';
import '../utils/auth_navigation.dart';

/// Soft-invalidates Riverpod detail/vault watchers after repo cache is updated.
void softInvalidateActorDetailProviders(WidgetRef ref, String actorId) {
  if (actorId.isEmpty) return;
  ref.invalidate(actorCollectionDetailProvider(actorId));
  ref.invalidate(actorVaultDepositProvider(actorId));
}

/// Prefer [upsertActorIntoLists] when returning from detail / after signing.
Future<void> refreshActorPlazaList(WidgetRef ref, {bool force = true}) {
  return ref.read(nftControllerProvider.notifier).refresh(force: force);
}

void upsertActorIntoLists(WidgetRef ref, ActorCollection actor) {
  ref.read(nftControllerProvider.notifier).upsertActor(actor);
  ref.read(searchControllerProvider.notifier).upsertActor(actor);
  const param = UserProfileActorParam();
  final provider = userProfileActorCollectionsProvider(param);
  if (ref.exists(provider)) {
    ref.read(provider.notifier).upsertActor(actor);
  }
}

void upsertActorIntoListsFromContainer(
  ProviderContainer container,
  ActorCollection actor,
) {
  container.read(nftControllerProvider.notifier).upsertActor(actor);
  container.read(searchControllerProvider.notifier).upsertActor(actor);
  const param = UserProfileActorParam();
  final provider = userProfileActorCollectionsProvider(param);
  if (container.exists(provider)) {
    container.read(provider.notifier).upsertActor(actor);
  }
}

/// Evicts detail cache, fetches from server, writes cache.
///
/// Does NOT invalidate providers — callers must call
/// [softInvalidateActorDetailProviders] themselves after verifying `mounted`.
Future<ActorCollection?> fetchFreshActorDetail(
  WidgetRef ref,
  String actorId,
) async {
  if (actorId.isEmpty) return null;
  final result = await ref
      .read(actorRepositoryProvider)
      .refreshActorCollectionDetail(actorId);
  if (result.isSuccess) return result.dataOrNull;
  return null;
}

/// Local UI snapshot after a successful mint, before indexer catches up.
///
/// Increments minted / decrements available and recomputes bonding-curve
/// [ActorCollection.currentPriceUsdc] for the *next* sign price.
ActorCollection applyOptimisticActorSign(
  ActorCollection actor, {
  int mintCount = 1,
}) {
  final delta = mintCount < 1 ? 1 : mintCount;
  final mintedBefore = actor.mintedSupplyInt ?? 0;
  final mintedAfter = mintedBefore + delta;
  final total = actor.totalSupplyInt;

  int? availableAfter = actor.availableSupplyInt;
  if (availableAfter != null) {
    availableAfter = (availableAfter - delta).clamp(0, 1 << 30);
  } else if (total != null) {
    availableAfter = (total - mintedAfter).clamp(0, total);
  }

  double? nextPrice = actor.currentPriceUsdc;
  if (!isFixedActorPricingMode(actor.pricingMode)) {
    nextPrice = getActorBondingCurvePrice(
      actor.initialPriceUsdc ?? 0,
      mintedAfter,
      total ?? 0,
    );
  }

  return ActorCollection(
    id: actor.id,
    userId: actor.userId,
    creatorName: actor.creatorName,
    assetId: actor.assetId,
    name: actor.name,
    avatarUrl: actor.avatarUrl,
    bio: actor.bio,
    status: actor.status,
    auditReason: actor.auditReason,
    nftMintAddress: actor.nftMintAddress,
    pricingMode: actor.pricingMode,
    badge: actor.badge,
    totalSupply: actor.totalSupply,
    mintedSupply: mintedAfter.toString(),
    availableSupply: availableAfter?.toString() ?? actor.availableSupply,
    initialPriceUsdc: actor.initialPriceUsdc,
    currentPriceUsdc: nextPrice,
    floorPriceUsdc: actor.floorPriceUsdc,
    nftChain: actor.nftChain,
    nftTokenStandard: actor.nftTokenStandard,
    nftTxHash: actor.nftTxHash,
    completedViewCount: actor.completedViewCount,
    heatValue: actor.heatValue,
    trust: actor.trust,
    initialPriceMultiplier: actor.initialPriceMultiplier,
    computingPower: actor.computingPower,
    createdAt: actor.createdAt,
    updatedAt: actor.updatedAt,
    version: actor.version,
  );
}

/// After mint: wait for indexer, then refetch until supply advances (or give up).
Future<ActorCollection?> refreshActorDetailAfterSign({
  required WidgetRef ref,
  required String actorId,
  required int baselineMinted,
  Duration initialDelay = const Duration(milliseconds: 1500),
  int maxAttempts = 3,
  Duration retryDelay = const Duration(milliseconds: 1500),
}) async {
  if (actorId.isEmpty) return null;
  await Future<void>.delayed(initialDelay);

  ActorCollection? last;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final fresh = await fetchFreshActorDetail(ref, actorId);
    if (fresh != null) {
      last = fresh;
      final minted = fresh.mintedSupplyInt ?? 0;
      if (minted > baselineMinted) return fresh;
    }
    if (attempt < maxAttempts - 1) {
      await Future<void>.delayed(retryDelay);
    }
  }
  return last;
}

/// Apply optimistic supply/price locally, seed cache, and patch plaza lists.
Future<ActorCollection> applyOptimisticActorSignLocally(
  WidgetRef ref,
  ActorCollection signedActor, {
  int mintCount = 1,
}) async {
  final optimistic = applyOptimisticActorSign(
    signedActor,
    mintCount: mintCount,
  );
  final actorId = optimistic.id ?? '';
  if (actorId.isNotEmpty) {
    await ref
        .read(actorRepositoryProvider)
        .seedActorCollectionDetail(optimistic);
    softInvalidateActorDetailProviders(ref, actorId);
  }
  upsertActorIntoLists(ref, optimistic);
  return optimistic;
}

/// List / search sign: open sheet immediately; pricing refreshes inside sheet.
Future<void> showActorSignFlowWithFreshDetail(
  BuildContext context,
  WidgetRef ref,
  ActorCollection actor,
) async {
  if (!await ensureLoggedInOrRedirect(context, ref)) return;
  if (!context.mounted) return;

  await showActorSignFlow(
    context,
    ref,
    actor,
    onSuccess: (signedActor) async {
      final actorId = signedActor.id ?? '';
      final baseline = signedActor.mintedSupplyInt ?? 0;
      await applyOptimisticActorSignLocally(ref, signedActor);
      if (!context.mounted) return;

      final after = await refreshActorDetailAfterSign(
        ref: ref,
        actorId: actorId,
        baselineMinted: baseline,
      );
      if (!context.mounted) return;
      softInvalidateActorDetailProviders(ref, actorId);
      if (after != null) {
        upsertActorIntoLists(ref, after);
      }
      ref.read(gameControllerProvider.notifier).refresh(force: true);
    },
  );
}
