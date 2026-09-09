import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository/draft_repository.dart';
import '../repositories/actor_repository.dart';
import '../repositories/agent_v2_config_repository.dart';
import '../repositories/app_version_repository.dart';
import '../repositories/config_repository.dart';
import '../repositories/drama_repository.dart';
import '../repositories/file_upload_repository.dart';
import '../repositories/finance_dashboard_repository.dart';
import '../repositories/follow_repository.dart';
import '../repositories/mining_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/recommend_repository.dart';
import '../repositories/reward_repository.dart';
import '../repositories/short_video_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/user_repository.dart';
import '../services/actor_sign_service.dart';
import '../services/drama_engagement_service.dart';
import '../services/drama_unlock_service.dart';
import '../services/evm/evm_token_balance_service.dart';
import '../services/solana/solana_token_balance_service.dart';
import '../services/sponsor_service.dart';
import 'core_providers.dart';

final Provider<DraftRepository> draftRepositoryProvider =
    Provider<DraftRepository>((ref) {
      return HiveDraftRepository(ref.read(localRepositoryProvider));
    });

final Provider<DramaRepository> dramaRepositoryProvider =
    Provider<DramaRepository>((ref) {
      final impl = DramaRepositoryImpl(
        ref.read(apiClientProvider),
        ref.read(localRepositoryProvider),
        ref.read(requestCoalescerProvider),
      );
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<RecommendRepository> recommendRepositoryProvider =
    Provider<RecommendRepository>((ref) {
      final impl = RecommendRepositoryImpl(
        ref.read(apiClientProvider),
        ref.read(deviceIdServiceProvider),
        ref.read(localRepositoryProvider),
      );
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<ActorRepository> actorRepositoryProvider =
    Provider<ActorRepository>((ref) {
      final impl = ActorRepositoryImpl(
        ref.read(apiClientProvider),
        ref.read(localRepositoryProvider),
      );
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<UserRepository> userRepositoryProvider =
    Provider<UserRepository>((ref) {
      final impl = UserRepositoryImpl(
        ref.read(apiClientProvider),
        ref.read(localRepositoryProvider),
        ref.read(requestCoalescerProvider),
      );
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<ItemRepository> itemRepositoryProvider =
    Provider<ItemRepository>((ref) {
      return ItemRepositoryImpl(ref.read(apiClientProvider));
    });

final Provider<FollowRepository> followRepositoryProvider =
    Provider<FollowRepository>((ref) {
      final impl = FollowRepositoryImpl(
        ref.read(apiClientProvider),
        coalescer: ref.read(requestCoalescerProvider),
      );
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<RewardRepository> rewardRepositoryProvider =
    Provider<RewardRepository>((ref) {
      final impl = RewardRepositoryImpl(
        ref.read(apiClientProvider),
        ref.read(localRepositoryProvider),
      );
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<MiningRepository> miningRepositoryProvider =
    Provider<MiningRepository>((ref) {
      final impl = MiningRepositoryImpl(
        ref.read(apiClientProvider),
        ref.read(localRepositoryProvider),
      );
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<FinanceDashboardRepository> financeDashboardRepositoryProvider =
    Provider<FinanceDashboardRepository>((ref) {
      final impl = FinanceDashboardRepositoryImpl(ref.read(apiClientProvider));
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<NotificationRepository> notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
      final impl = NotificationRepositoryImpl(
        ref.read(apiClientProvider),
        ref.read(localRepositoryProvider),
      );
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<FileUploadRepository> fileUploadRepositoryProvider =
    Provider<FileUploadRepository>((ref) {
      final impl = FileUploadRepositoryImpl(ref.read(apiClientProvider));
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<ShortVideoRepository> shortVideoRepositoryProvider =
    Provider<ShortVideoRepository>((ref) {
      final impl = ShortVideoRepositoryImpl(ref.read(apiClientProvider));
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<TagRepository> tagRepositoryProvider = Provider<TagRepository>((
  ref,
) {
  final impl = TagRepositoryImpl(
    ref.read(apiClientProvider),
    ref.read(localRepositoryProvider),
  );
  ref.onDispose(() => impl.dispose());
  return impl;
});

final Provider<ConfigRepository> configRepositoryProvider =
    Provider<ConfigRepository>((ref) {
      final localRepo = ref.read(localRepositoryProvider);
      final impl = ConfigRepositoryImpl(
        ref.read(apiClientProvider),
        localRepo.cacheBox,
        apiBaseUrl: ref.read(storySdkConfigProvider).effectiveApiBaseUrl,
      );
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<AppVersionRepository> appVersionRepositoryProvider =
    Provider<AppVersionRepository>((ref) {
      final impl = AppVersionRepositoryImpl(ref.read(apiClientProvider));
      ref.onDispose(() => impl.dispose());
      return impl;
    });

final Provider<AgentV2ConfigRepository> agentV2ConfigRepositoryProvider =
    Provider<AgentV2ConfigRepository>((ref) {
      final localRepo = ref.read(localRepositoryProvider);
      return AgentV2ConfigRepositoryImpl(
        ref.read(apiClientProvider),
        localRepo.cacheBox,
        apiBaseUrl: ref.read(storySdkConfigProvider).effectiveApiBaseUrl,
        coalescer: ref.read(requestCoalescerProvider),
      );
    });

final Provider<SolanaTokenBalanceService> solanaTokenBalanceServiceProvider =
    Provider<SolanaTokenBalanceService>((ref) {
      return const SolanaTokenBalanceService();
    });

final Provider<EvmTokenBalanceService> evmTokenBalanceServiceProvider =
    Provider<EvmTokenBalanceService>((ref) {
      return const EvmTokenBalanceService();
    });

final Provider<SponsorService> sponsorServiceProvider =
    Provider<SponsorService>((ref) {
      final privy = ref.read(privyServiceProvider);
      final localRepo = ref.read(localRepositoryProvider);
      return SponsorService(
        privy,
        tokenProvider: () => localRepo.cachedToken ?? '',
        apiBaseUrl: ref.read(storySdkConfigProvider).effectiveApiBaseUrl,
      );
    });

final Provider<ActorSignService> actorSignServiceProvider =
    Provider<ActorSignService>((ref) {
      return ActorSignService(
        actorRepository: ref.read(actorRepositoryProvider),
        sponsorService: ref.read(sponsorServiceProvider),
        privyService: ref.read(privyServiceProvider),
      );
    });

final Provider<DramaEngagementService> dramaEngagementServiceProvider =
    Provider<DramaEngagementService>((ref) {
      return DramaEngagementService(
        ref.read(dramaRepositoryProvider),
        ref.read(localRepositoryProvider),
      );
    });

final Provider<DramaUnlockService> dramaUnlockServiceProvider =
    Provider<DramaUnlockService>((ref) {
      return DramaUnlockService(ref.read(dramaRepositoryProvider));
    });
