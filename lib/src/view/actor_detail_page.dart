import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/components.dart';
import '../core/app_channel.dart';
import '../model/models.dart';
import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../repositories/actor_repository.dart';
import '../routes/route_args.dart';
import '../styles/story_colors.dart';
import '../utils/actor_data_sync.dart';
import '../utils/actor_pricing.dart';
import '../widgets/widgets.dart';
import 'widgets/actor_detail/widgets.dart';

class ActorDetailPage extends ConsumerStatefulWidget {
  final String actorId;
  final ActorCollection? preview;
  final int initialTabIndex;

  const ActorDetailPage({
    super.key,
    required this.actorId,
    this.preview,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<ActorDetailPage> createState() => _ActorDetailPageState();
}

class _ActorDetailPageState extends ConsumerState<ActorDetailPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  late final _CastListController _castList;

  /// Cached / preview UI snapshot. May be shown before network returns.
  ActorCollection? _displayActor;

  /// Only set after a successful server fetch (used for list backfill on pop).
  ActorCollection? _backfillActor;
  int _signedCount = 0;

  bool _bootstrapping = true;
  bool _networkError = false;
  String? _networkErrorMessage;

  @override
  void initState() {
    super.initState();
    _displayActor = widget.preview;
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _castList = _CastListController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
      unawaited(
        _castList.loadMore(
          () => ref.read(actorRepositoryProvider),
          widget.actorId,
        ),
      );
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _castList.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_tabController.index != 0) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(
        _castList.loadMore(
          () => ref.read(actorRepositoryProvider),
          widget.actorId,
        ),
      );
    }
  }

  void _applyNetworkSuccess(ActorCollection actor) {
    _displayActor = actor;
    _backfillActor = actor;
    _networkError = false;
    _networkErrorMessage = null;
  }

  /// Stale-while-revalidate: show cache/preview first, always refetch server.
  Future<void> _bootstrap() async {
    final repo = ref.read(actorRepositoryProvider);

    if (_displayActor == null) {
      final cached = await repo.getActorCollectionDetailCachedOnly(
        widget.actorId,
      );
      if (!mounted) return;
      if (cached != null) {
        setState(() => _displayActor = cached);
      }
    }

    await _refreshFromNetwork(isBootstrap: true);
  }

  Future<void> _refreshFromNetwork({bool isBootstrap = false}) async {
    if (!mounted) return;
    if (!isBootstrap && _displayActor == null) {
      setState(() {
        _bootstrapping = true;
        _networkError = false;
      });
    }

    final fresh = await fetchFreshActorDetail(ref, widget.actorId);
    if (!mounted) return;
    softInvalidateActorDetailProviders(ref, widget.actorId);

    setState(() {
      _bootstrapping = false;
      if (fresh != null) {
        _applyNetworkSuccess(fresh);
      } else if (_displayActor == null) {
        _networkError = true;
        _networkErrorMessage = context.l10n.dramaDetailRetry;
      }
    });
    if (fresh != null) {
      upsertActorIntoLists(ref, fresh);
    }
  }

  Future<void> _reload() async {
    softInvalidateActorDetailProviders(ref, widget.actorId);
    await _refreshFromNetwork();
    if (!mounted) return;
    await _castList.reload(
      () => ref.read(actorRepositoryProvider),
      widget.actorId,
    );
  }

  /// Optimistic supply/price, then delayed refetch until indexer advances.
  Future<void> _reloadAfterSign(ActorCollection signedActor) async {
    _signedCount += 1;
    final baseline = signedActor.mintedSupplyInt ?? 0;
    final optimistic = await applyOptimisticActorSignLocally(ref, signedActor);
    if (!mounted) return;
    setState(() => _applyNetworkSuccess(optimistic));

    final fresh = await refreshActorDetailAfterSign(
      ref: ref,
      actorId: widget.actorId,
      baselineMinted: baseline,
    );
    if (!mounted) return;
    softInvalidateActorDetailProviders(ref, widget.actorId);
    if (fresh != null) {
      setState(() => _applyNetworkSuccess(fresh));
      upsertActorIntoLists(ref, fresh);
    }
    await _castList.reload(
      () => ref.read(actorRepositoryProvider),
      widget.actorId,
    );
  }

  Future<void> _onSignTap(ActorCollection actor) async {
    // Sheet opens immediately; price/supply refresh happens inside the sheet.
    await showActorSignFlow(context, ref, actor, onSuccess: _reloadAfterSign);
  }

  void _popWithBackfill() {
    final result = _signedCount > 0
        ? ActorDetailResult(actor: _backfillActor, signedCount: _signedCount)
        : _backfillActor;
    Navigator.of(context).pop(result);
  }

  Widget _backLeading() {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      onPressed: _popWithBackfill,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final display = _displayActor;

    if (display != null) {
      return _buildDetailScaffold(context, display);
    }
    if (_bootstrapping) {
      return AppScaffold(
        title: l10n.actorDetailTitle,
        leading: _backLeading(),
        body: StoryStateWidget.loading(message: l10n.dramaDetailLoading),
      );
    }
    if (_networkError) {
      return AppScaffold(
        title: l10n.actorDetailTitle,
        leading: _backLeading(),
        body: StoryStateWidget.error(
          message: _networkErrorMessage ?? l10n.dramaDetailRetry,
          actionLabel: l10n.dramaDetailRetry,
          onAction: _reload,
        ),
      );
    }
    return AppScaffold(
      backgroundColor: StoryColors.actorDetailBackgroundOf(
        Theme.of(context).brightness,
      ),
      title: l10n.actorDetailTitle,
      leading: _backLeading(),
      body: StoryStateWidget.loading(message: l10n.dramaDetailLoading),
    );
  }

  Widget _buildDetailScaffold(BuildContext context, ActorCollection a) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final price = a.displayCurrentPriceUsdc;
    final signedCount = a.mintedSupplyInt ?? 0;
    final maxSupply = a.totalSupplyInt ?? 0;
    final remainingCount = a.availableSupplyInt ?? 0;
    final isSoldOut = remainingCount <= 0;
    final issuerName = ActorHeroSection.truncateId(a.creatorName ?? a.id);
    final actorIpLabel = ActorHeroSection.truncateId(a.id);
    final pageBg = StoryColors.actorDetailBackgroundOf(theme.brightness);
    final priceLabel = isSoldOut
        ? formatActorFloorPriceDisplay(
            resolveActorFloorPriceUsdc(floorPriceUsdc: a.floorPriceUsdc),
          )
        : '${formatActorPriceCeilDisplay(price)} USDC';

    final signBottomPriceWidget = AppChannel.isStore
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                priceLabel.replaceAll(' USDC', ''),
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              const IapPointIcon(),
            ],
          )
        : null;

    final hero = ActorHeroSection(
      actor: a,
      theme: theme,
      issuerName: issuerName,
      actorIpLabel: actorIpLabel,
      blendWithPageBackground: true,
    );

    return AppScaffold(
      title: l10n.actorDetailTitle,
      leading: _backLeading(),
      backgroundColor: pageBg,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: hero),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ActorDetailTabBarDelegate(
                    backgroundColor: pageBg,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StoryTabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabs: [
                          Tab(text: l10n.actorDetailTabCast),
                          Tab(text: l10n.actorDetailTabInfo),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_tabController.index == 0)
                  ListenableBuilder(
                    listenable: _castList,
                    builder: (context, _) {
                      return ActorCastDramasList(
                        castItems: _castList.items,
                        loadingMore: _castList.loadingMore,
                        hasMore: _castList.hasMore,
                      );
                    },
                  )
                else
                  SliverToBoxAdapter(
                    child: ActorIssueTab(
                      actor: a,
                      maxSupply: maxSupply,
                      signedCount: signedCount,
                      remainingCount: remainingCount,
                      price: price,
                    ),
                  ),
                if (_tabController.index == 0)
                  ListenableBuilder(
                    listenable: _castList,
                    builder: (context, _) {
                      return SliverToBoxAdapter(
                        child: ActorCastDramasLoadMoreFooter(
                          loadingMore: _castList.loadingMore,
                          hasMore: _castList.hasMore,
                        ),
                      );
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
            ),
          ),
          ActorSignBottomBar(
            isSoldOut: isSoldOut,
            isLoading: _bootstrapping,
            priceLabel: priceLabel,
            priceWidget: signBottomPriceWidget,
            onSign: () => unawaited(_onSignTap(a)),
            onTrade: () => StoryToast.info(context, l10n.nftTradeUnavailable),
          ),
        ],
      ),
    );
  }
}

class _ActorDetailTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color backgroundColor;

  _ActorDetailTabBarDelegate({
    required this.child,
    required this.backgroundColor,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(color: backgroundColor, child: child);
  }

  @override
  bool shouldRebuild(covariant _ActorDetailTabBarDelegate oldDelegate) {
    return child != oldDelegate.child ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

/// Holds cast-drama pagination outside [ActorDetailPage] setState so load-more
/// only rebuilds the cast tab via [ListenableBuilder].
class _CastListController extends ChangeNotifier {
  final List<DramaListItem> items = [];
  bool hasMore = true;
  bool loadingMore = false;
  String mark = '';
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> reload(ActorRepository Function() repoOf, String actorId) async {
    items.clear();
    mark = '';
    hasMore = true;
    if (!_disposed) notifyListeners();
    await loadMore(repoOf, actorId);
  }

  Future<void> loadMore(
    ActorRepository Function() repoOf,
    String actorId,
  ) async {
    if (loadingMore || !hasMore) return;
    loadingMore = true;
    if (!_disposed) notifyListeners();
    try {
      final result = await repoOf().getCastDramas(
        actorId,
        mark: mark.isEmpty ? null : mark,
      );
      if (_disposed) return;
      if (result.isSuccess && result.dataOrNull != null) {
        final page = result.dataOrNull!;
        items.addAll(page.list ?? []);
        hasMore = page.hasMore ?? false;
        if (page.mark != null && page.mark.toString().isNotEmpty) {
          mark = page.mark.toString();
        }
      }
    } finally {
      loadingMore = false;
      if (!_disposed) notifyListeners();
    }
  }
}
