import '../core/story_constants.dart';
import 'package:flutter/material.dart';

import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';

/// Provides a shared shimmer [Animation] to all descendant [StorySkeletonBox]
/// widgets.  When multiple skeleton boxes are visible simultaneously (e.g. a
/// full-page skeleton), they share a single [AnimationController] instead of
/// each owning one, reducing CPU/GPU overhead by ~60-80%.
///
/// Wrap the top-level skeleton composite with [ShimmerScope]:
/// ```dart
/// return const ShimmerScope(child: StoryTheaterPageSkeleton());
/// ```
class ShimmerScope extends StatefulWidget {
  const ShimmerScope({super.key, required this.child});

  final Widget child;

  /// Returns the shared shimmer animation if a [ShimmerScope] ancestor exists,
  /// or `null` otherwise.
  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ShimmerInherited>()
        ?.animation;
  }

  /// Returns the shared shimmer animation.  Throws if no [ShimmerScope]
  /// ancestor is found.
  static Animation<double> of(BuildContext context) {
    final animation = maybeOf(context);
    assert(animation != null, 'No ShimmerScope found in context');
    return animation!;
  }

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: StoryDurations.animationSkeleton,
    )..repeat();
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerInherited(animation: _animation, child: widget.child);
  }
}

class _ShimmerInherited extends InheritedWidget {
  const _ShimmerInherited({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_ShimmerInherited oldWidget) =>
      animation != oldWidget.animation;
}

/// A single shimmer box used to build skeleton layouts.
///
/// When placed inside a [ShimmerScope], all boxes share one animation
/// controller.  Outside a [ShimmerScope], a local controller is created for
/// backward compatibility.
class StorySkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const StorySkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  @override
  State<StorySkeletonBox> createState() => _StorySkeletonBoxState();
}

class _StorySkeletonBoxState extends State<StorySkeletonBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _localController;
  Animation<double>? _localShimmer;

  /// The animation to drive the gradient — shared or local.
  Animation<double> get _shimmer => _localShimmer ?? _sharedShimmer!;
  Animation<double>? _sharedShimmer;

  @override
  void initState() {
    super.initState();
    _tryInitLocal();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shared = ShimmerScope.maybeOf(context);
    if (shared != null) {
      // Use the shared animation; tear down any local controller.
      _sharedShimmer = shared;
      _disposeLocalController();
    } else {
      // No scope — ensure local controller exists.
      _sharedShimmer = null;
      _tryInitLocal();
    }
  }

  void _tryInitLocal() {
    if (_localController != null) return;
    _localController = AnimationController(
      vsync: this,
      duration: StoryDurations.animationSkeleton,
    )..repeat();
    _localShimmer = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _localController!, curve: Curves.easeInOut),
    );
  }

  void _disposeLocalController() {
    _localController?.dispose();
    _localController = null;
    _localShimmer = null;
  }

  @override
  void dispose() {
    _disposeLocalController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final base = StoryColors.mutedForegroundOf(
      brightness,
    ).withValues(alpha: 0.12);
    final highlight = StoryColors.mutedForegroundOf(
      brightness,
    ).withValues(alpha: 0.04);
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(_shimmer.value - 0.5, 0),
              end: Alignment(_shimmer.value + 0.5, 0),
              colors: [base, highlight, base],
            ),
          ),
          child: SizedBox(width: widget.width, height: widget.height),
        );
      },
    );
  }
}

/// Skeleton placeholder for a drama list item card.
///
/// 布局与 [DramaCard] 保持一致：6:5 封面图 + 标题 + 标签 + 创作者/播放量。
class StoryDramaCardSkeleton extends StatelessWidget {
  const StoryDramaCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: StorySpacing.md),
      child: StoryCardSkeleton(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image skeleton (6:5)
            AspectRatio(
              aspectRatio: 6 / 5,
              child: StorySkeletonBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(StoryRadius.lgValue),
                ),
              ),
            ),
            // Title + creator row skeleton
            Padding(
              padding: EdgeInsets.fromLTRB(
                StorySpacing.sm,
                StorySpacing.sm,
                StorySpacing.sm,
                StorySpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StorySkeletonBox(width: double.infinity, height: 16),
                  SizedBox(height: 6),
                  StorySkeletonBox(width: 100, height: 10),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      StorySkeletonBox(
                        width: 14,
                        height: 14,
                        borderRadius: BorderRadius.all(Radius.circular(7)),
                      ),
                      SizedBox(width: 3),
                      StorySkeletonBox(width: 80, height: 10),
                      SizedBox(width: StorySpacing.sm),
                      StorySkeletonBox(
                        width: 14,
                        height: 14,
                        borderRadius: BorderRadius.all(Radius.circular(7)),
                      ),
                      SizedBox(width: 3),
                      StorySkeletonBox(width: 40, height: 10),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 个人中心双列网格中使用的短剧卡片骨架。
///
/// 布局与 `GridDramaCard` 保持一致：3:4 封面 + 标题 + 元信息/创作者行。
class GridDramaCardSkeleton extends StatelessWidget {
  const GridDramaCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: const ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: StorySkeletonBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StorySkeletonBox(width: double.infinity, height: 16),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: StorySkeletonBox(
                          width: double.infinity,
                          height: 10,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: StorySkeletonBox(
                          width: double.infinity,
                          height: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton wrapper matching [StoryCard].
class StoryCardSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const StoryCardSkeleton({
    super.key,
    this.padding = const EdgeInsets.all(StorySpacing.md),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        borderRadius: BorderRadius.circular(StoryRadius.lgValue),
      ),
      child: padding == EdgeInsets.zero
          ? ClipRRect(
              borderRadius: BorderRadius.circular(StoryRadius.lgValue),
              child: child,
            )
          : Padding(padding: padding, child: child),
    );
  }
}

/// Skeleton placeholder for an actor collection card.
///
/// 布局与 [ActorCollectionCard] 保持一致：4:3 封面 + 名称/简介 + 统计 + 价格 + 按钮。
class StoryActorCardSkeleton extends StatelessWidget {
  const StoryActorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const StoryCardSkeleton(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: StorySkeletonBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(StoryRadius.lgValue),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(StorySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StorySkeletonBox(width: double.infinity, height: 18),
                SizedBox(height: 2),
                StorySkeletonBox(width: double.infinity, height: 10),
                SizedBox(height: 3),
                StorySkeletonBox(width: 120, height: 10),
                SizedBox(height: StorySpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: StorySkeletonBox(
                        width: double.infinity,
                        height: 28,
                        borderRadius: StoryRadius.brSm,
                      ),
                    ),
                    SizedBox(width: StorySpacing.md),
                    Expanded(
                      child: StorySkeletonBox(
                        width: double.infinity,
                        height: 28,
                        borderRadius: StoryRadius.brSm,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: StorySpacing.md),
                StorySkeletonBox(
                  width: double.infinity,
                  height: 44,
                  borderRadius: StoryRadius.brSm,
                ),
                SizedBox(height: StorySpacing.md),
                StorySkeletonBox(
                  width: double.infinity,
                  height: 38,
                  borderRadius: StoryRadius.brSm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 演员 IP 列表页骨架（与 [NftPage] 单列 [ActorCollectionCard] 布局一致）。
class StoryActorListSkeleton extends StatelessWidget {
  final int itemCount;

  const StoryActorListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: StorySpacing.md),
        itemBuilder: (_, _) => const StoryActorCardSkeleton(),
      ),
    );
  }
}

/// A full-page skeleton list for the theater (drama list) page.
class StoryDramaListSkeleton extends StatelessWidget {
  final int itemCount;
  const StoryDramaListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.screenHorizontal,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) => const StoryDramaCardSkeleton(),
      ),
    );
  }
}

/// 剧场首页骨架，与 [TheaterPage] 布局一致：顶满 Banner + 分类 Tab + 排序栏 + 列表。
class StoryTheaterPageSkeleton extends StatelessWidget {
  final int itemCount;

  const StoryTheaterPageSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    // Keep in sync with [TheaterHeroBanner.contentHeight] + status-bar inset.
    const bannerContentHeight = 380.0;
    final bannerHeight =
        bannerContentHeight + MediaQuery.paddingOf(context).top;
    return ShimmerScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StorySkeletonBox(
            width: double.infinity,
            height: bannerHeight,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StorySpacing.screenHorizontal,
              StorySpacing.sm,
              StorySpacing.screenHorizontal,
              StorySpacing.xs,
            ),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: StorySpacing.sm),
                itemBuilder: (_, index) => StorySkeletonBox(
                  width: index == 0 ? 48 : 64,
                  height: 36,
                  borderRadius: StoryRadius.brPill,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.screenHorizontal,
              vertical: StorySpacing.sm,
            ),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: StorySpacing.md),
                  StorySkeletonBox(
                    width: i == 0 ? 56 : 48,
                    height: 20,
                    borderRadius: StoryRadius.brSm,
                  ),
                ],
                const Spacer(),
                const StorySkeletonBox(
                  width: 32,
                  height: 32,
                  borderRadius: StoryRadius.brSm,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.screenHorizontal,
            ),
            child: Column(
              children: [
                for (var i = 0; i < itemCount; i++)
                  const StoryDramaCardSkeleton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-page skeleton grid for the NFT (actor list) page.
class StoryActorGridSkeleton extends StatelessWidget {
  final int itemCount;
  const StoryActorGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: StorySpacing.md,
          crossAxisSpacing: StorySpacing.md,
          childAspectRatio: 0.72,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) => const StoryActorCardSkeleton(),
      ),
    );
  }
}

/// 个人中心作品/点赞/收藏双列网格骨架，与 `ProfileListTab` 网格布局一致。
class ProfileListSkeleton extends StatelessWidget {
  final int itemCount;

  const ProfileListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.sm,
          vertical: StorySpacing.md,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: StorySpacing.sm,
          mainAxisSpacing: StorySpacing.base,
          childAspectRatio: 0.60,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) => const GridDramaCardSkeleton(),
      ),
    );
  }
}

/// 创作者管理双列卡片骨架，与 `DramaManagementGridCard` / `CreatorVideoManagementCard`
/// 布局保持一致：232:310 封面 + 标题/元信息行 + 可选操作按钮。
///
/// 当可用内容高度充足（≥ 80px，如剧集 Tab）时展示底部按钮骨架；
/// 高度不足（如短视频 Tab 的 72px 内容区）时自动省略按钮。
class CreatorManagementCardSkeleton extends StatelessWidget {
  const CreatorManagementCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AspectRatio(
              aspectRatio: 232 / 310,
              child: StorySkeletonBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showButton = constraints.maxHeight >= 80;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const StorySkeletonBox(
                          width: double.infinity,
                          height: 16,
                        ),
                        const SizedBox(height: 8),
                        const StorySkeletonBox(width: 140, height: 12),
                        if (showButton) ...[
                          const Spacer(),
                          const StorySkeletonBox(
                            width: double.infinity,
                            height: 44,
                            borderRadius: StoryRadius.brSm,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 创作者管理网格骨架。响应式列表传入与内容一致的 [gridDelegate]，
/// 并可通过 [itemBuilder] 对齐卡片内部占位布局。
class CreatorManagementGridSkeleton extends StatelessWidget {
  final int itemCount;
  final double childAspectRatio;
  final SliverGridDelegate? gridDelegate;
  final IndexedWidgetBuilder? itemBuilder;

  const CreatorManagementGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.childAspectRatio = 0.489,
    this.gridDelegate,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        gridDelegate:
            gridDelegate ??
            SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
            ),
        itemCount: itemCount,
        itemBuilder:
            itemBuilder ?? (_, _) => const CreatorManagementCardSkeleton(),
      ),
    );
  }
}
