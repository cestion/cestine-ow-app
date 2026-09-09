import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/format_number.dart';
import '../../../utils/mining_power.dart';
import '../../../widgets/story_cached_image.dart';

const _monetaryBorder = Color(0xFFD99902);
const _cardControlBackground = Color(0xB3111113);
const _controlBorder = Color(0xFF363A3F);

/// Figma `2620:133107` — 在演角色卡片。
///
/// 卡片本身只负责展示；交互入口保留回调，V3 业务接入时无需重做布局。
class AgentV3ActorCard extends StatelessWidget {
  const AgentV3ActorCard({
    super.key,
    required this.actor,
    required this.staminaLimit,
    this.onImagePressed,
    this.onRefillPressed,
    this.onRestPressed,
  });

  final MiningActor actor;
  final int? staminaLimit;
  final VoidCallback? onImagePressed;
  final VoidCallback? onRefillPressed;
  final VoidCallback? onRestPressed;

  @override
  Widget build(BuildContext context) {
    final borderColor = (actor.stamina ?? 0) > 0
        ? _monetaryBorder
        : StoryColors.destructive;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StoryColors.whiteToDarkOf(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(3, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = constraints.maxWidth / 310.5;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      key: ValueKey(
                        'agent-v3-actor-image-${actor.actorCollectionId ?? actor.nftId}',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTap: onImagePressed,
                      child: _ActorImage(
                        actor: actor,
                        logicalWidth: constraints.maxWidth,
                      ),
                    ),
                    const IgnorePointer(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          widthFactor: 1,
                          heightFactor: 1 / 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Color(0x66000000)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Listener(
                        key: ValueKey('agent-v3-card-identity-${actor.nftId}'),
                        behavior: HitTestBehavior.opaque,
                        child: _ActorIdentity(actor: actor, scale: scale),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.all(12 * scale),
                        child: Listener(
                          key: ValueKey(
                            'agent-v3-card-controls-${actor.nftId}',
                          ),
                          behavior: HitTestBehavior.opaque,
                          child: _ActorControls(
                            actor: actor,
                            staminaLimit: staminaLimit,
                            scale: scale,
                            onRefillPressed: onRefillPressed,
                            onRestPressed: onRestPressed,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ActorImage extends StatelessWidget {
  const _ActorImage({required this.actor, required this.logicalWidth});

  final MiningActor actor;
  final double logicalWidth;

  @override
  Widget build(BuildContext context) {
    final url = actor.avatarUrl?.trim();
    if (url == null || url.isEmpty) return const _ActorImageFallback();
    return StoryCachedImage(
      imageUrl: url,
      memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
        context,
        logicalWidth,
      ),
      placeholder: const _ActorImageFallback(),
      errorWidget: const _ActorImageFallback(),
    );
  }
}

class _ActorImageFallback extends StatelessWidget {
  const _ActorImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: StoryColors.mutedOf(Theme.of(context).brightness),
      child: Center(
        child: Icon(
          Icons.person,
          size: 72,
          color: StoryColors.mutedForegroundOf(Theme.of(context).brightness),
        ),
      ),
    );
  }
}

class _ActorIdentity extends StatelessWidget {
  const _ActorIdentity({required this.actor, required this.scale});

  final MiningActor actor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final tokenId = actor.actorTokenId;
    final code = tokenId == null
        ? actor.actorCode ?? '-'
        : '#${tokenId.toString().padLeft(4, '0')}';
    return SizedBox(
      width: 149 * scale,
      height: 58 * scale,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            'assets/game_v3/agent_card_label.svg',
            fit: BoxFit.fill,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12 * scale, 10 * scale, 12 * scale, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actor.displayName.isEmpty ? '-' : actor.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w500,
                    height: 22 / 15,
                  ),
                ),
                Text(
                  code,
                  maxLines: 1,
                  style: TextStyle(
                    color: _monetaryBorder,
                    fontSize: 12 * scale,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActorControls extends StatelessWidget {
  const _ActorControls({
    required this.actor,
    required this.staminaLimit,
    required this.scale,
    this.onRefillPressed,
    this.onRestPressed,
  });

  final MiningActor actor;
  final int? staminaLimit;
  final double scale;
  final VoidCallback? onRefillPressed;
  final VoidCallback? onRestPressed;

  @override
  Widget build(BuildContext context) {
    final isStaminaFull =
        staminaLimit != null && actor.isStaminaFull(staminaLimit!);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SalaryPill(actor: actor, scale: scale),
        SizedBox(height: 4 * scale),
        SizedBox(
          height: 44 * scale,
          child: Row(
            children: [
              Expanded(
                child: _StaminaPill(
                  stamina: actor.stamina,
                  limit: staminaLimit,
                  scale: scale,
                ),
              ),
              SizedBox(width: 6 * scale),
              _ControlButton(
                key: ValueKey('agent-v3-card-refill-${actor.nftId}'),
                asset: 'assets/game_v3/agent_card_refill.svg',
                semanticLabel: context.l10n.gameRefillTitle,
                scale: scale,
                visuallyDisabled: isStaminaFull,
                onPressed: onRefillPressed,
              ),
              SizedBox(width: 6 * scale),
              _ControlButton(
                key: ValueKey('agent-v3-card-rest-${actor.nftId}'),
                asset: 'assets/game_v3/agent_card_rest.svg',
                semanticLabel: context.l10n.gameRest,
                scale: scale,
                onPressed: onRestPressed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalaryPill extends StatelessWidget {
  const _SalaryPill({required this.actor, required this.scale});

  final MiningActor actor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final value = formatNumber(getMiningActorHourlySalary(actor));
    return Container(
      height: 44 * scale,
      padding: EdgeInsets.fromLTRB(3 * scale, 3 * scale, 12 * scale, 3 * scale),
      decoration: BoxDecoration(
        color: _cardControlBackground,
        border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
        borderRadius: BorderRadius.circular(88),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/game_v3/agent_card_salary.svg',
            width: 38 * scale,
            height: 38 * scale,
          ),
          SizedBox(width: 6 * scale),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w700,
                      height: 26 / 18,
                      letterSpacing: -0.04,
                    ),
                  ),
                  SizedBox(width: 2 * scale),
                  Text(
                    '/h',
                    style: TextStyle(
                      color: const Color(0xCCFFFFFF),
                      fontSize: 12 * scale,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 4 * scale,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: StoryColors.star, width: 0.5),
              borderRadius: BorderRadius.circular(52),
            ),
            child: Text(
              'Lv.${actor.level ?? '-'}',
              style: TextStyle(
                color: StoryColors.star,
                fontSize: 12 * scale,
                height: 16 / 12,
                letterSpacing: 0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaminaPill extends StatelessWidget {
  const _StaminaPill({
    required this.stamina,
    required this.limit,
    required this.scale,
  });

  final int? stamina;
  final int? limit;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isDepleted = stamina == 0;
    final progress = stamina == null || limit == null || limit! <= 0
        ? 0.0
        : (stamina! / limit!).clamp(0.0, 1.0);
    return Container(
      height: double.infinity,
      padding: EdgeInsets.fromLTRB(3 * scale, 3 * scale, 12 * scale, 3 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF111113),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
        borderRadius: BorderRadius.circular(88),
      ),
      child: Row(
        children: [
          Container(
            width: 38 * scale,
            height: 38 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/game_v3/agent_card_stamina.svg',
              key: const ValueKey('agent-v3-stamina-icon'),
              width: 30.083 * scale,
              height: 30.083 * scale,
              colorFilter: isDepleted
                  ? const ColorFilter.mode(
                      StoryColors.destructive,
                      BlendMode.srcIn,
                    )
                  : null,
            ),
          ),
          SizedBox(width: 4 * scale),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${stamina ?? '-'}',
                        key: const ValueKey('agent-v3-stamina-value'),
                        style: TextStyle(
                          color: isDepleted
                              ? StoryColors.destructive
                              : StoryColors.star,
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w700,
                          height: 24 / 16,
                        ),
                      ),
                      SizedBox(width: 2 * scale),
                      Text(
                        '/ ${limit ?? '--'}',
                        style: TextStyle(
                          color: const Color(0xCCFFFFFF),
                          fontSize: 12 * scale,
                          height: 16 / 12,
                          letterSpacing: 0.04,
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4 * scale,
                    backgroundColor: const Color(0x26FFFFFF),
                    valueColor: const AlwaysStoppedAnimation(StoryColors.star),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    super.key,
    required this.asset,
    required this.scale,
    this.semanticLabel,
    this.visuallyDisabled = false,
    this.onPressed,
  });

  final String asset;
  final double scale;
  final String? semanticLabel;
  final bool visuallyDisabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onPressed != null,
      enabled: onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 44 * scale,
          height: 44 * scale,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF323238), Color(0xFF111113)],
            ),
            border: Border.all(color: _controlBorder),
            borderRadius: BorderRadius.circular(12 * scale),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                offset: Offset(0.8, 0.8),
                blurRadius: 0.8,
              ),
            ],
          ),
          child: Opacity(
            opacity: visuallyDisabled ? 0.4 : 1,
            child: SvgPicture.asset(
              asset,
              width: 24 * scale,
              height: 24 * scale,
            ),
          ),
        ),
      ),
    );
  }
}
