import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/story_l10n.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';
import 'widgets/finance_dashboard/actor_vault_ranking_list_item.dart';

/// 「演员 IP 金库排行」查看更多的完整列表页，支持下拉刷新与分页加载
/// （Figma 未提供独立设计，列表项样式与 Tab 内预览保持一致）。
class ActorVaultRankingHistoryPage extends ConsumerStatefulWidget {
  const ActorVaultRankingHistoryPage({super.key});

  @override
  ConsumerState<ActorVaultRankingHistoryPage> createState() =>
      _ActorVaultRankingHistoryPageState();
}

class _ActorVaultRankingHistoryPageState
    extends ConsumerState<ActorVaultRankingHistoryPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(actorVaultRankingHistoryControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(actorVaultRankingHistoryControllerProvider);
    if (state.isLoading || state.isPageLoading || state.items.isEmpty) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            StorySpacing.scrollThreshold) {
      ref.read(actorVaultRankingHistoryControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final items = ref.watch(
      actorVaultRankingHistoryControllerProvider.select((s) => s.items),
    );
    final isLoading = ref.watch(
      actorVaultRankingHistoryControllerProvider.select((s) => s.isLoading),
    );
    final isPageLoading = ref.watch(
      actorVaultRankingHistoryControllerProvider.select((s) => s.isPageLoading),
    );
    final showInitialLoading = isLoading && items.isEmpty;
    final showEmpty = !isLoading && items.isEmpty;

    return AppScaffold(
      title: l10n.financeDashboardActorVaultRanking,
      backgroundColor: StoryColors.appBarBackgroundOf(theme.brightness),
      body: ColoredBox(
        color: StoryColors.storyBgOf(theme.brightness),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: ColoredBox(
            color: StoryColors.appBarBackgroundOf(theme.brightness),
            child: RefreshIndicator(
              color: StoryColors.brandTeal,
              onRefresh: () => ref
                  .read(actorVaultRankingHistoryControllerProvider.notifier)
                  .refresh(),
              child: showInitialLoading
                  ? const _CenteredLoading()
                  : showEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 240,
                          child: Center(
                            child: Text(
                              l10n.searchNoData,
                              style: StoryTextStyles.bodySmall(
                                color: StoryColors.mutedForegroundOf(
                                  theme.brightness,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: StorySpacing.screenHorizontal,
                      ),
                      itemCount: items.length + (isPageLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: StorySpacing.base,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        return ActorVaultRankingListItem(
                          item: items[index],
                          showDivider: index != items.length - 1,
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredLoading extends StatelessWidget {
  const _CenteredLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
