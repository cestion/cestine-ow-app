import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../components/components.dart';
import '../foundation/story_theme.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../provider/tab_index_provider.dart';
import '../routes/route_names.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';
import '../foundation/navigator.dart';

/// 经纪工坊 — 管理演员，派遣产生收益。
class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_reloadPageData());
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final state = ref.read(gameControllerProvider);
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= max - 200) {
      ref.read(gameControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _reloadPageData({bool force = false}) async {
    final auth = ref.read(authControllerProvider);
    if (!mounted || !auth.isLoggedIn || auth.isLogging) return;
    await Future.wait<void>([
      ref.read(gameControllerProvider.notifier).refresh(force: force),
      ref.read(profileControllerProvider.notifier).refresh(force: true),
    ]);
  }

  Future<void> _handleRefresh() => _reloadPageData(force: true);

  /// Game 页面会被 MainShell 的 IndexedStack 保留。认证身份变化时销毁旧的
  /// Game/Profile controller，可同时清空旧账号数据并让未完成请求失效。
  /// 新账号登录后再从服务端强制加载完整页面数据。
  void _handleAuthChanged(bool isLoggedIn) {
    if (!isLoggedIn) {
      ref.invalidate(gameControllerProvider);
      ref.invalidate(profileControllerProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ref.read(authControllerProvider).isLoggedIn) {
        return;
      }
      unawaited(_reloadPageData(force: true));
    });
  }

  Future<void> _handleDeploy(MiningActor actor) async {
    final state = ref.read(gameControllerProvider);
    if (!state.canDeployMore) {
      StoryToast.error(context, context.l10n.gameDeploySlotFull);
      return;
    }

    await showGameDeployConfirmDialog(context, ref, actor);
  }

  Future<void> _handleRest(MiningActor actor) async {
    final gameState = ref.read(gameControllerProvider);
    final feeAmount = ref
        .read(gameControllerProvider.notifier)
        .supplyFeeForLevel(actor.level);
    final ok = await showGameRestConfirmDialogWithMeta(
      context,
      actor,
      staminaLimit: gameState.staminaLimit,
      restoreFeeLabel: feeAmount != null
          ? '${feeAmount.toStringAsFixed(1)} ${context.l10n.currency}'
          : null,
    );
    if (ok != true || !mounted) return;

    final rested = await ref
        .read(gameControllerProvider.notifier)
        .rest(actor.nftId);
    if (!mounted) return;
    if (!rested) {
      final err = ref.read(gameControllerProvider).lastError;
      if (err != null) handleApiError(err, ctx: context);
    } else {
      StoryToast.success(context, context.l10n.gameRestSuccessToast);
    }
  }

  void _handleSupplement(MiningActor actor) {
    showGameRefillStaminaDialog(context, ref, actor);
  }

  void _handleUpgrade(MiningActor actor) {
    showGameActorUpgradeDialog(context, ref, actor);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    ref.listen<({bool isLoggedIn, bool isLogging})>(
      authControllerProvider.select(
        (state) => (isLoggedIn: state.isLoggedIn, isLogging: state.isLogging),
      ),
      (previous, current) {
        final loggedOut = previous?.isLoggedIn == true && !current.isLoggedIn;
        final loginCompleted =
            current.isLoggedIn &&
            !current.isLogging &&
            (previous?.isLoggedIn != true || previous?.isLogging == true);
        if (loggedOut) {
          _handleAuthChanged(false);
        } else if (loginCompleted) {
          _handleAuthChanged(true);
        }
      },
    );

    return AppScaffold(
      title: l10n.navMy,
      centerTitle: false,
      showBack: false,
      backgroundColor: context.storyColors.appBarBackground,
      leading: const StoryLeadingAvatar(),
      titleWidget: Row(
        children: [
          const Spacer(),
          _GameNavIconButton(
            asset: theme.brightness == Brightness.dark
                ? 'assets/game/game_nav_edit_d.svg'
                : 'assets/game/game_nav_edit.svg',
            tooltip: "",
            onPressed: () => ref
                .read(tabIndexProvider.notifier)
                .setIndex(StoryTab.nft.index),
          ),
          const SizedBox(width: StorySpacing.base),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? StoryColors.backgroundOf(theme.brightness)
              : StoryColors.lightBackground,
        ),
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: _GamePageBody(
            scrollController: _scrollController,
            onDeploy: _handleDeploy,
            onRest: _handleRest,
            onSupplement: _handleSupplement,
            onUpgrade: _handleUpgrade,
          ),
        ),
      ),
    );
  }
}

class _GamePageBody extends ConsumerWidget {
  final ScrollController scrollController;
  final ValueChanged<MiningActor> onDeploy;
  final ValueChanged<MiningActor> onRest;
  final ValueChanged<MiningActor> onSupplement;
  final ValueChanged<MiningActor> onUpgrade;

  const _GamePageBody({
    required this.scrollController,
    required this.onDeploy,
    required this.onRest,
    required this.onSupplement,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      gameControllerProvider.select((s) => s.isLoading),
    );
    final myActors = ref.watch(
      gameControllerProvider.select((s) => s.myActors),
    );
    final isRefreshingList = ref.watch(
      gameControllerProvider.select((s) => s.isRefreshingList),
    );
    final isLoggedIn = ref.watch(
      authControllerProvider.select((state) => state.isLoggedIn),
    );
    final hasRiskTrust = ref.watch(
      profileControllerProvider.select(
        (state) => state.user?.isRiskAccount == true,
      ),
    );
    final isRiskAccount = isLoggedIn && hasRiskTrust;
    final showSkeleton = isLoading && myActors.isEmpty;

    if (showSkeleton) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
        children: const [GamePageSkeleton()],
      );
    }

    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionTitle(
                context.l10n.gameWorkingActors,
                trailing: isRiskAccount ? const GameRiskAccountBadge() : null,
              ),
              const SizedBox(height: StorySpacing.md),
              const GameDeployedActorsSection(),
              const SizedBox(height: StorySpacing.xl),
              const _GameWeeklySection(),
              const SizedBox(height: StorySpacing.xl),
              const _GameMyActorsHeader(),
              const SizedBox(height: StorySpacing.sm),
              const _GameSortSection(),
              const SizedBox(height: StorySpacing.md),
            ]),
          ),
        ),
        if (myActors.isEmpty && !isRefreshingList)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.screenHorizontal,
            ),
            sliver: SliverToBoxAdapter(
              child: StoryEmptyCard(label: context.l10n.gameEmptyMyActors),
            ),
          )
        else if (isRefreshingList && myActors.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.screenHorizontal,
            ),
            sliver: SliverList.builder(
              itemCount: 4,
              itemBuilder: (_, _) => const Padding(
                padding: EdgeInsets.only(bottom: StorySpacing.md),
                child: GameActorCardSkeleton(),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.screenHorizontal,
            ),
            sliver: SliverList.builder(
              itemCount: myActors.length,
              itemBuilder: (context, index) {
                final actor = myActors[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: StorySpacing.md),
                  child: RepaintBoundary(
                    key: ValueKey(actor.nftId),
                    child: _GameActorCardItem(
                      actor: actor,
                      onDeploy: onDeploy,
                      onRest: onRest,
                      onSupplement: onSupplement,
                      onUpgrade: onUpgrade,
                    ),
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: _GameLoadingMoreFooter()),
        const SliverPadding(padding: EdgeInsets.only(bottom: StorySpacing.xxl)),
      ],
    );
  }
}

class _GameWeeklySection extends ConsumerWidget {
  const _GameWeeklySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStats = ref.watch(
      gameControllerProvider.select((s) => s.weeklyStats),
    );

    return GameWeeklyStatsPanel(
      stats: weeklyStats,
      onMiningRules: () =>
          context.storyPush(RouteNames.miningRules),
      onSettlementRecords: () =>
          context.storyPush(RouteNames.income),
    );
  }
}

class _GameMyActorsHeader extends ConsumerWidget {
  const _GameMyActorsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final totalActorCount = ref.watch(
      gameControllerProvider.select((s) => s.totalActorCount),
    );

    return Row(
      children: [
        Text(
          l10n.gameMyActors,
          style: StoryTextStyles.headingLarge(
            color: StoryColors.foregroundOf(theme.brightness),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$totalActorCount',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: StoryColors.brandTeal,
          ),
        ),
      ],
    );
  }
}

class _GameSortSection extends ConsumerWidget {
  const _GameSortSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(gameControllerProvider.select((s) => s.sort));
    final notifier = ref.read(gameControllerProvider.notifier);

    return GameSortFilters(currentSort: sort, onSortChanged: notifier.setSort);
  }
}

class _GameActorCardItem extends ConsumerWidget {
  final MiningActor actor;
  final ValueChanged<MiningActor> onDeploy;
  final ValueChanged<MiningActor> onRest;
  final ValueChanged<MiningActor> onSupplement;
  final ValueChanged<MiningActor> onUpgrade;

  const _GameActorCardItem({
    required this.actor,
    required this.onDeploy,
    required this.onRest,
    required this.onSupplement,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staminaLimit = ref.watch(
      gameControllerProvider.select((s) => s.staminaLimit),
    );

    return GameActorCard(
      actor: actor,
      staminaLimit: staminaLimit,
      onSupplement: () => onSupplement(actor),
      onRest: actor.isMining ? () => onRest(actor) : null,
      onDeploy: actor.isRest && actor.nftId.isNotEmpty
          ? () => onDeploy(actor)
          : null,
      onUpgrade: actor.level != null ? () => onUpgrade(actor) : null,
    );
  }
}

class _GameLoadingMoreFooter extends ConsumerWidget {
  const _GameLoadingMoreFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoadingMore = ref.watch(
      gameControllerProvider.select((s) => s.isLoadingMore),
    );
    if (!isLoadingMore) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.only(
        left: StorySpacing.screenHorizontal,
        right: StorySpacing.screenHorizontal,
        bottom: StorySpacing.md,
      ),
      child: GameActorCardSkeleton(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionTitle(this.title, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StoryTextStyles.headingLarge(
              color: StoryColors.foregroundOf(Theme.of(context).brightness),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: StorySpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

class _GameNavIconButton extends StatelessWidget {
  final String asset;
  final String tooltip;
  final VoidCallback onPressed;

  const _GameNavIconButton({
    required this.asset,
    required this.tooltip,
    required this.onPressed,
  });

  static const _iconSize = 40.0;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: _iconSize,
        minHeight: _iconSize,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
      icon: SvgPicture.asset(asset, width: _iconSize, height: _iconSize),
    );
  }
}
