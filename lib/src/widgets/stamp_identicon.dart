import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../core/story_env.dart';

/// Deterministic color-block collage used when Stamp CDN is unavailable.
///
/// Visually approximates `cdn.stamp.fyi` identicons (mirrored pixel grid).
class StampIdenticon extends StatelessWidget {
  final String seed;
  final double size;
  final BorderRadius? borderRadius;

  const StampIdenticon({
    super.key,
    required this.seed,
    required this.size,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    return ClipRRect(
      borderRadius: radius,
      child: CustomPaint(
        size: Size.square(size),
        painter: _StampIdenticonPainter(seed: seed),
      ),
    );
  }
}

class _StampIdenticonPainter extends CustomPainter {
  final String seed;

  _StampIdenticonPainter({required this.seed});

  static const _grid = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final bytes = _seedBytes(seed);
    final bg = _colorAt(bytes, 0);
    final fg = _colorAt(bytes, 3);
    final accent = _colorAt(bytes, 6);

    final cell = size.width / _grid;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = bg;
    canvas.drawRect(Offset.zero & size, paint);

    // Fill left half; mirror to the right for stamp-like symmetry.
    final half = (_grid / 2).ceil();
    for (var y = 0; y < _grid; y++) {
      for (var x = 0; x < half; x++) {
        final bit = bytes[(y * half + x + 9) % bytes.length];
        if (bit % 3 == 0) continue; // leave background cell
        paint.color = bit.isEven ? fg : accent;
        final rect = Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5);
        canvas.drawRect(rect, paint);
        final mirrorX = _grid - 1 - x;
        if (mirrorX != x) {
          canvas.drawRect(
            Rect.fromLTWH(mirrorX * cell, y * cell, cell + 0.5, cell + 0.5),
            paint,
          );
        }
      }
    }
  }

  static Uint8List _seedBytes(String seed) {
    final digest = sha256.convert(seed.codeUnits);
    return Uint8List.fromList(digest.bytes);
  }

  static Color _colorAt(Uint8List bytes, int offset) {
    final r = bytes[offset % bytes.length];
    final g = bytes[(offset + 1) % bytes.length];
    final b = bytes[(offset + 2) % bytes.length];
    // Bias toward saturated mid tones similar to stamp.fyi blues/teals.
    return Color.fromARGB(255, 40 + (r % 180), 60 + (g % 160), 100 + (b % 140));
  }

  @override
  bool shouldRepaint(covariant _StampIdenticonPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

/// Web-aligned Stamp CDN URL: `{baseUrl}/{id}?s={px}`.
String stampAvatarUrl(String userId, {required double logicalSize}) {
  final px = math.max(40, (logicalSize * 2).round());
  return '${StoryEnv.stampCdnBaseUrl}/${Uri.encodeComponent(userId)}?s=$px';
}
