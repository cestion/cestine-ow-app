import 'package:flutter/material.dart';

/// 三张参演位空卡轮播，对应 Figma 节点 `2984:266168`。
class AgentV3EmptyCarousel extends StatelessWidget {
  static const _asset = 'assets/game_v3/agent_empty_card.png';

  const AgentV3EmptyCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClipRect(
      child: Center(
        child: OverflowBox(
          maxWidth: 867.86,
          child: SizedBox(
            height: 414,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EmptyCard(width: 266.68, height: 355.573, opacity: 0.7),
                SizedBox(width: 12),
                _EmptyCard(width: 310.5, height: 414),
                SizedBox(width: 12),
                _EmptyCard(width: 266.68, height: 355.573, opacity: 0.7),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;

  const _EmptyCard({
    required this.width,
    required this.height,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.asset(
        AgentV3EmptyCarousel._asset,
        width: width,
        height: height,
        fit: BoxFit.fill,
      ),
    );
  }
}
