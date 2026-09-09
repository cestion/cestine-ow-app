import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controller/drama_management_controller.dart';
import '../../../controller/drama_management_state.dart';
import '../../../controller/drama_nft_controller.dart';
import '../../../controller/drama_nft_state.dart';
import '../../../core/story_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../widgets/widgets.dart';
import '../../../components/common/delete_confirm_dialog.dart';
import '../../../components/creator/drama_management_card.dart';
import '../../../components/creator/mint_nft_modal.dart';
import '../../../foundation/navigator.dart';

/// Drama management tab — status filter tabs + paginated drama list +
/// delete dialog. Backed by [DramaManagementController] (server-side filter
/// via `status` query param on `/api/mini-drama/creator/dramas`).
class DramaManagementTab extends ConsumerStatefulWidget {
  final AppLocalizations l10n;

  const DramaManagementTab({super.key, required this.l10n});

  @override
  ConsumerState<DramaManagementTab> createState() => _DramaManagementTabState();
}

class _DramaManagementTabState extends ConsumerState<DramaManagementTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dramaManagementControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final state = ref.watch(dramaManagementControllerProvider);
    final notifier = ref.read(dramaManagementControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            StorySpacing.screenHorizontal,
            StorySpacing.sm,
            StorySpacing.screenHorizontal,
            0,
          ),
          child: _buildFilterTabs(theme, state, notifier),
        ),
        const SizedBox(height: StorySpacing.base),
        Expanded(child: _buildDramaList(context, theme, state, notifier)),
      ],
    );
  }

  Widget _buildFilterTabs(
    ThemeData theme,
    DramaManagementState state,
    DramaManagementController notifier,
  ) {
    final labels = <DramaManagementStatus, String>{
      DramaManagementStatus.all: widget.l10n.creatorReviewFilterAll,
      DramaManagementStatus.online: widget.l10n.creatorReviewFilterApproved,
      DramaManagementStatus.pendingReview:
          widget.l10n.creatorReviewFilterPending,
      DramaManagementStatus.reviewRejected:
          widget.l10n.creatorReviewFilterRejected,
      DramaManagementStatus.offline: widget.l10n.creatorReviewFilterOffline,
    };
    return SizedBox(
      height: 20,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: DramaManagementStatus.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: StorySpacing.lg),
        itemBuilder: (context, index) {
          final status = DramaManagementStatus.values[index];
          final isSelected = state.currentStatus == status;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => notifier.selectStatus(status),
            child: Text(
              labels[status]!,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected
                    ? StoryColors.foregroundOf(theme.brightness)
                    : StoryColors.mutedForegroundOf(theme.brightness),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDramaList(
    BuildContext context,
    ThemeData theme,
    DramaManagementState state,
    DramaManagementController notifier,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.screenHorizontal,
        ),
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: StorySpacing.base),
            child: StoryDramaCardSkeleton(),
          ),
        ),
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.screenHorizontal,
        ),
        children: [
          const SizedBox(height: StorySpacing.xxl),
          StoryEmptyCard(label: widget.l10n.creatorNoDramas),
        ],
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent -
                    StorySpacing.scrollThreshold) {
          notifier.loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.screenHorizontal,
        ),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: StorySpacing.base),
              child: Center(child: StoryLoading()),
            );
          }
          final drama = state.items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: StorySpacing.base),
            child: DramaManagementCard(
              drama: drama,
              onMint: () => _showMintDialog(context, notifier, drama),
              onEdit: () async {
                final id = drama.id;
                if (id != null) {
                  final result =
                      await context.storyPushForResult<Object?>(RouteNames.createDrama,
                        arguments: {'dramaId': id});
                  final updated = result is CreatorDrama ? result : null;
                  if (context.mounted && updated != null) {
                    ref
                        .read(dramaManagementControllerProvider.notifier)
                        .updateDrama(updated);
                  }
                }
              },
              onDelete: () => _showDeleteDialog(context, notifier, drama),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showMintDialog(
    BuildContext context,
    DramaManagementController notifier,
    CreatorDrama drama,
  ) async {
    final minted = await MintNftModal.show(context, drama) ?? false;
    if (!minted) return;
    ref
        .read(dramaNftControllerProvider.notifier)
        .addPendingMint(
          drama,
          nftContractAddress: ref.read(authControllerProvider).solanaAddress,
        );
    ref
        .read(creatorControllerProvider.notifier)
        .refreshOwnedNftCount(optimisticIncrement: true);
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    DramaManagementController notifier,
    CreatorDrama drama,
  ) async {
    notifier.requestDeleteDrama(drama);
    await showDialog<void>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final isDeleting = ref.watch(
            dramaManagementControllerProvider.select((s) => s.isDeleting),
          );
          return DeleteConfirmDialog(
            title: widget.l10n.creatorDeleteDramaConfirm,
            isDeleting: isDeleting,
            onCancel: () {
              Navigator.of(ctx).pop();
              notifier.closeDialog();
            },
            onConfirm: () async {
              final deleted = await notifier.confirmDeleteDrama();
              if (deleted) {
                ref
                    .read(creatorControllerProvider.notifier)
                    .refreshOnlineDramaCount();
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
              notifier.closeDialog();
            },
          );
        },
      ),
    );
  }
}

/// Drama NFT tab — vertical list of owned drama NFT cards.
/// Backed by [DramaNftController] (loaded via
/// `/api/userWallet/dramaNft/positions`). Matches Figma design
/// node 6134:32969 ("短剧NFT" tab): rounded-12 white card, 6:5 cover,
/// title 16/bold, NFT id chip, single-line description.
class DramaNftTab extends ConsumerStatefulWidget {
  final AppLocalizations l10n;

  const DramaNftTab({super.key, required this.l10n});

  @override
  ConsumerState<DramaNftTab> createState() => _DramaNftTabState();
}

class _DramaNftTabState extends ConsumerState<DramaNftTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dramaNftControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(dramaNftControllerProvider);
    final nfts = state.myNfts;
    final hasMore = state.hasMoreNfts;
    return _buildNftList(context, nfts, hasMore, state);
  }

  Widget _buildNftList(
    BuildContext context,
    List<NftPosition> nfts,
    bool hasMore,
    DramaNftState state,
  ) {
    const padding = EdgeInsets.fromLTRB(
      StorySpacing.screenHorizontal,
      StorySpacing.base,
      StorySpacing.screenHorizontal,
      0,
    );
    if (state.isLoading && nfts.isEmpty) {
      return ListView(
        padding: padding,
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: StorySpacing.base),
            child: _DramaNftCardSkeleton(),
          ),
        ),
      );
    }
    if (nfts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(
          vertical: StorySpacing.xxl,
          horizontal: StorySpacing.screenHorizontal,
        ),
        children: [StoryEmptyCard(label: widget.l10n.creatorNoCreatedActors)],
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent -
                    StorySpacing.scrollThreshold) {
          ref.read(dramaNftControllerProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: padding,
        itemCount: nfts.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= nfts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: StorySpacing.base),
              child: Center(child: StoryLoading()),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: StorySpacing.base),
            child: DramaNftCard(nft: nfts[index]),
          );
        },
      ),
    );
  }
}

/// NFT card matching Figma node 4967:32752 "短剧NFT未质押2".
class DramaNftCard extends StatelessWidget {
  final NftPosition nft;

  const DramaNftCard({super.key, required this.nft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: StoryColors.cardOf(theme.brightness),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildCover(context, theme), _buildInfo(theme)],
      ),
    );
  }

  Widget _buildCover(BuildContext context, ThemeData theme) {
    return AspectRatio(
      aspectRatio: 6 / 5,
      child: ColoredBox(
        color: StoryColors.mutedOf(theme.brightness),
        child: nft.coverUrl != null && nft.coverUrl!.isNotEmpty
            ? StoryCachedImage(
                imageUrl: nft.coverUrl!,
                memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
                  context,
                  StoryImageCache.cardCover,
                ),
                errorWidget: _coverPlaceholder(theme),
              )
            : _coverPlaceholder(theme),
      ),
    );
  }

  Widget _coverPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.movie_outlined,
        size: 40,
        color: StoryColors.mutedForegroundOf(theme.brightness),
      ),
    );
  }

  Widget _buildInfo(ThemeData theme) {
    final title = nft.dramaName?.trim();
    final code = nft.displayCode;
    final episodes = nft.episodeCount;
    final description = nft.description?.trim();
    final descText = _formatDescription(episodes, description);

    return Padding(
      padding: const EdgeInsets.all(StorySpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty)
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 24 / 16,
                color: StoryColors.foregroundOf(theme.brightness),
              ),
            ),
          if (code != null) ...[
            const SizedBox(height: StorySpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: StoryColors.mutedOf(theme.brightness),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 0.04,
                  color: StoryColors.foregroundOf(theme.brightness),
                ),
              ),
            ),
          ],
          if (descText.isNotEmpty) ...[
            const SizedBox(height: StorySpacing.sm),
            Text(
              descText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: -0.1504,
                color: StoryColors.mutedForegroundOf(theme.brightness),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDescription(int? episodes, String? description) {
    final epText = episodes != null ? '$episodes 集' : '';
    final desc = description?.trim() ?? '';
    if (epText.isEmpty && desc.isEmpty) return '';
    if (epText.isEmpty) return desc;
    if (desc.isEmpty) return epText;
    return '$epText ｜ $desc';
  }
}

class _DramaNftCardSkeleton extends StatelessWidget {
  const _DramaNftCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: StoryColors.cardOf(theme.brightness),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 6 / 5,
            child: ColoredBox(color: StoryColors.mutedOf(theme.brightness)),
          ),
          const Padding(
            padding: EdgeInsets.all(StorySpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StorySkeletonBox(width: 120, height: 16),
                SizedBox(height: StorySpacing.sm),
                StorySkeletonBox(width: 72, height: 20),
                SizedBox(height: StorySpacing.sm),
                StorySkeletonBox(width: double.infinity, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
