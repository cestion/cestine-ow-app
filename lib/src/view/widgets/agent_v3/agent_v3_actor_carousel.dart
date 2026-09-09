import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../controller/agent_v3_state.dart';
import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import 'agent_v3_actor_card.dart';

const _designViewportWidth = 375.0;
const _designCardWidth = 310.5;
const _designCardHeight = 414.0;
const _designSideCardWidth = 266.68;
const _designCardGap = 12.0;
const _emptyCardShadowOverflow = 24.0;
const _viewportFraction =
    ((_designCardWidth + _designSideCardWidth) / 2 + _designCardGap) /
    _designViewportWidth;
const _sideCardScale = _designSideCardWidth / _designCardWidth;

/// 五个在演位的横向轮播。中心卡使用全部可用高度，邻卡按 Figma 比例缩放。
class AgentV3ActorCarousel extends StatefulWidget {
  const AgentV3ActorCarousel({
    super.key,
    required this.actors,
    required this.staminaLimit,
    required this.initialPage,
    required this.onPageChanged,
    this.onActorPressed,
    this.onRefillPressed,
    this.onRestPressed,
    this.onEmptySlotPressed,
  });

  final List<MiningActor> actors;
  final int? staminaLimit;
  final int initialPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<MiningActor>? onActorPressed;
  final ValueChanged<MiningActor>? onRefillPressed;
  final ValueChanged<MiningActor>? onRestPressed;
  final VoidCallback? onEmptySlotPressed;

  @override
  State<AgentV3ActorCarousel> createState() => _AgentV3ActorCarouselState();
}

class _AgentV3ActorCarouselState extends State<AgentV3ActorCarousel> {
  late final PageController _controller = PageController(
    initialPage: widget.initialPage,
    viewportFraction: _viewportFraction,
  );

  @override
  void didUpdateWidget(covariant AgentV3ActorCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage == widget.initialPage) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final currentPage = _controller.page?.round();
      if (currentPage == widget.initialPage) return;
      unawaited(
        _controller.animateToPage(
          widget.initialPage,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tall screens give this region more vertical room. Let the card use
        // it without growing wider than the Figma viewport proportion.
        final cardHeight = constraints.maxHeight;
        final widthFromViewport =
            constraints.maxWidth * (_designCardWidth / _designViewportWidth);
        final widthFromHeight =
            cardHeight * (_designCardWidth / _designCardHeight);
        final cardWidth = widthFromViewport < widthFromHeight
            ? widthFromViewport
            : widthFromHeight;
        final hasEmptySlots = widget.actors.length < agentV3DeploySlotCount;
        final shadowOverflow = hasEmptySlots
            ? _emptyCardShadowOverflow * (cardWidth / _designCardWidth)
            : 0.0;

        // Keep the carousel cropped horizontally while allowing empty-card
        // artwork to paint its exported shadow above and below the viewport.
        return ClipRect(
          key: const ValueKey('agent-v3-carousel-clip'),
          clipper: _CarouselClipper(verticalOverflow: shadowOverflow),
          child: PageView.builder(
            controller: _controller,
            clipBehavior: Clip.none,
            physics: const PageScrollPhysics(),
            itemCount: agentV3DeploySlotCount,
            onPageChanged: widget.onPageChanged,
            itemBuilder: (context, index) {
              final actor = index < widget.actors.length
                  ? widget.actors[index]
                  : null;
              return AnimatedBuilder(
                animation: _controller,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: actor == null
                      ? Semantics(
                          button: widget.onEmptySlotPressed != null,
                          child: GestureDetector(
                            key: ValueKey('agent-v3-empty-slot-$index'),
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.onEmptySlotPressed,
                            child: const _EmptyActorCard(),
                          ),
                        )
                      : AgentV3ActorCard(
                          key: ValueKey(
                            'agent-v3-actor-card-${actor.actorCollectionId ?? actor.nftId}',
                          ),
                          actor: actor,
                          staminaLimit: widget.staminaLimit,
                          onImagePressed:
                              widget.onActorPressed == null ||
                                  actor.actorCollectionId == null
                              ? null
                              : () => widget.onActorPressed!(actor),
                          onRefillPressed:
                              widget.onRefillPressed == null ||
                                  (widget.staminaLimit != null &&
                                      actor.isStaminaFull(widget.staminaLimit!))
                              ? null
                              : () => widget.onRefillPressed!(actor),
                          onRestPressed: widget.onRestPressed == null
                              ? null
                              : () => widget.onRestPressed!(actor),
                        ),
                ),
                builder: (context, child) {
                  final page = _controller.hasClients
                      ? (_controller.page ?? widget.initialPage.toDouble())
                      : widget.initialPage.toDouble();
                  final distance = (page - index).abs().clamp(0.0, 1.0);
                  final scale = lerpDouble(1, _sideCardScale, distance)!;
                  final opacity = lerpDouble(1, 0.7, distance)!;
                  return Center(
                    child: OverflowBox(
                      maxWidth: cardWidth,
                      maxHeight: cardHeight,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(opacity: opacity, child: child),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _CarouselClipper extends CustomClipper<Rect> {
  const _CarouselClipper({required this.verticalOverflow});

  final double verticalOverflow;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    0,
    -verticalOverflow,
    size.width,
    size.height + verticalOverflow,
  );

  @override
  bool shouldReclip(_CarouselClipper oldClipper) =>
      oldClipper.verticalOverflow != verticalOverflow;
}

class _EmptyActorCard extends StatelessWidget {
  const _EmptyActorCard();

  static const _lightAsset = 'assets/game_v3/agent_empty_card_light.png';
  static const _darkAsset = 'assets/game_v3/agent_empty_card.png';
  static const _wavesAsset = 'assets/game_v3/agent_empty_card_waves.svg';
  static const _personAsset = 'assets/game_v3/agent_empty_card_person.png';

  // Figma exports include the card's drop-shadow outside its 310.5 x 414
  // layout bounds. Keep that overflow instead of squeezing it into the card.
  static const _lightExportSize = Size(348, 452);
  static const _darkExportSize = Size(334, 438);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exportSize = isDark ? _darkExportSize : _lightExportSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / _designCardWidth;
        final designHeight = _designCardHeight * scale;
        if (constraints.maxHeight > designHeight + 0.5) {
          return _ResponsiveEmptyActorCard(isDark: isDark, scale: scale);
        }

        final width = exportSize.width * scale;
        final height = exportSize.height * scale;
        return OverflowBox(
          minWidth: width,
          maxWidth: width,
          minHeight: height,
          maxHeight: height,
          child: Image.asset(
            isDark ? _darkAsset : _lightAsset,
            key: const ValueKey('agent-v3-empty-card'),
            width: width,
            height: height,
            fit: BoxFit.fill,
          ),
        );
      },
    );
  }
}

class _ResponsiveEmptyActorCard extends StatelessWidget {
  const _ResponsiveEmptyActorCard({required this.isDark, required this.scale});

  final bool isDark;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? StoryColors.darkCard : StoryColors.lightCard;
    return DecoratedBox(
      key: const ValueKey('agent-v3-empty-card-responsive'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 4.658),
            blurRadius: 18.63,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12 * scale),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final personWidth = 127.305 * scale;
            final personHeight = 145.441 * scale;
            final personCenterY = constraints.maxHeight * (175.19 / 414);
            final waveHeight = 444.015 * scale;
            final waveCenterY = constraints.maxHeight * 0.63;
            final waveTop = waveCenterY - 366.39 * scale;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: -1.553 * scale,
                  right: -1.553 * scale,
                  top: waveTop,
                  height: waveHeight,
                  child: SvgPicture.asset(
                    _EmptyActorCard._wavesAsset,
                    fit: BoxFit.fill,
                    colorFilter: isDark
                        ? const ColorFilter.mode(
                            StoryColors.darkMuted,
                            BlendMode.srcIn,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  key: const ValueKey('agent-v3-empty-card-person'),
                  left: (constraints.maxWidth - personWidth) / 2,
                  top: personCenterY - personHeight / 2,
                  width: personWidth,
                  height: personHeight,
                  child: Image.asset(
                    _EmptyActorCard._personAsset,
                    fit: BoxFit.fill,
                    color: isDark ? StoryColors.darkMutedForeground : null,
                    colorBlendMode: isDark ? BlendMode.srcIn : null,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
