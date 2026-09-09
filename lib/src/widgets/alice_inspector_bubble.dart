import 'package:flutter/material.dart';

import '../services/alice_inspector_service.dart';
import '../styles/story_colors.dart';

class AliceInspectorBubble extends StatefulWidget {
  final VoidCallback? onPressed;

  const AliceInspectorBubble({super.key, this.onPressed});

  @override
  State<AliceInspectorBubble> createState() => _AliceInspectorBubbleState();
}

class _AliceInspectorBubbleState extends State<AliceInspectorBubble> {
  static const double _size = 52;
  static const double _edgeInset = 12;

  Offset? _position;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;
    final minX = padding.left + _edgeInset;
    final minY = padding.top + _edgeInset;
    final maxX = (screenSize.width - padding.right - _size - _edgeInset).clamp(
      minX,
      double.infinity,
    );
    final maxY = (screenSize.height - padding.bottom - _size - _edgeInset)
        .clamp(minY, double.infinity);
    final position = _clampPosition(
      _position ?? Offset(maxX, (minY + maxY) / 2),
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
    );

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Semantics(
        button: true,
        label: 'Network inspector',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed ?? AliceInspectorService.showInspector,
          onPanUpdate: (details) {
            setState(() {
              _position = _clampPosition(
                position + details.delta,
                minX: minX,
                minY: minY,
                maxX: maxX,
                maxY: maxY,
              );
            });
          },
          child: Container(
            width: _size,
            height: _size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: StoryColors.darkButtonBg,
              boxShadow: [
                BoxShadow(
                  color: StoryColors.overlaySubtle,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.terminal_rounded,
              color: StoryColors.onOverlay,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }

  Offset _clampPosition(
    Offset position, {
    required double minX,
    required double minY,
    required double maxX,
    required double maxY,
  }) {
    return Offset(position.dx.clamp(minX, maxX), position.dy.clamp(minY, maxY));
  }
}
