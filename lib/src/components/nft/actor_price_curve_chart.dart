import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../utils/actor_pricing.dart';
import '../../utils/format_number.dart';

export '../../utils/actor_pricing.dart'
    show
        actorBondingCurveBase,
        getActorBondingCurvePrice,
        getActorBondingCurveTailPrice;

List<({int signed, double price})> buildActorPriceCurveData(
  double initialPrice,
  int maxSupply,
) {
  final total = math.max(1, maxSupply);
  return List.generate(81, (index) {
    final signed = ((total * index) / 80).round();
    return (
      signed: signed,
      price: getActorBondingCurvePrice(initialPrice, signed, total),
    );
  });
}

/// Y-axis ticks aligned with web `ActorPriceCurveChart`.
List<double> buildActorPriceCurveYTicks({
  required double initialPrice,
  required double finalPrice,
}) {
  final ticks = <double>[0, initialPrice, finalPrice / 2, finalPrice];
  final unique = <double>[];
  for (final tick in ticks) {
    if (tick < 0) continue;
    if (!unique.contains(tick)) unique.add(tick);
  }
  return unique;
}

/// Plot Y-domain max aligned with web Recharts
/// `ifOverflow="extendDomain"` on the current-price reference line/dot.
///
/// Tick labels still use [tailPrice]; the domain expands when
/// [currentPrice] exceeds the tail so the sold-out segment is not clamped.
double resolveActorPriceCurveMaxPrice({
  required double tailPrice,
  required double currentPrice,
}) => math.max(tailPrice, currentPrice);

/// Price curve chart for actor signing dialog, aligned with web
/// `ActorPriceCurveChart`.
class ActorPriceCurveChart extends StatelessWidget {
  final int signedCount;
  final int maxSupply;
  final double initialPrice;
  final double currentPrice;
  final double height;
  final EdgeInsetsGeometry padding;

  const ActorPriceCurveChart({
    super.key,
    required this.signedCount,
    required this.maxSupply,
    required this.initialPrice,
    required this.currentPrice,
    this.height = 220,
    this.padding = const EdgeInsets.all(StorySpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final normalizedMaxSupply = math.max(1, maxSupply);
    final normalizedSignedCount = signedCount.clamp(0, normalizedMaxSupply);
    final finalPrice = getActorBondingCurveTailPrice(
      initialPrice,
      normalizedMaxSupply,
    );
    final maxPrice = resolveActorPriceCurveMaxPrice(
      tailPrice: finalPrice,
      currentPrice: currentPrice,
    );
    final chartData = buildActorPriceCurveData(
      initialPrice,
      normalizedMaxSupply,
    );
    final supplyTicks = [
      0.0,
      0.25,
      0.5,
      0.75,
      1.0,
    ].map((ratio) => (normalizedMaxSupply * ratio).round()).toList();
    final yTicks = buildActorPriceCurveYTicks(
      initialPrice: initialPrice,
      finalPrice: finalPrice,
    );

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: StoryColors.actorPriceChartBgOf(Theme.of(context).brightness),
        borderRadius: StoryRadius.brMd,
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: _ActorPriceCurveChartPainter._axisLabelGutter,
              top: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(
                painter: _ActorPriceCurveChartPainter(
                  chartData: chartData,
                  supplyTicks: supplyTicks,
                  yTicks: yTicks,
                  maxSupply: normalizedMaxSupply,
                  signedCount: normalizedSignedCount,
                  currentPrice: currentPrice,
                  maxPrice: maxPrice,
                  gridLineColor: StoryColors.actorPriceChartGridOf(
                    Theme.of(context).brightness,
                  ),
                  signedCountAxisLabel: l10n.actorSignedCountAxisLabel,
                  mutedForegroundColor: StoryColors.mutedForegroundOf(
                    Theme.of(context).brightness,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _ActorPriceCurveChartPainter._axisLabelGutter,
              child: _PriceAxisLabel(
                label: l10n.actorPriceAxisLabel(l10n.currency),
                brightness: Theme.of(context).brightness,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceAxisLabel extends StatelessWidget {
  final String label;
  final Brightness brightness;

  const _PriceAxisLabel({required this.label, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            height: 12 / 10,
            letterSpacing: 0.08,
            color: StoryColors.mutedForegroundOf(brightness),
          ),
          softWrap: false,
        ),
      ),
    );
  }
}

class _ActorPriceCurveChartPainter extends CustomPainter {
  final List<({int signed, double price})> chartData;
  final List<int> supplyTicks;
  final List<double> yTicks;
  final int maxSupply;
  final int signedCount;
  final double currentPrice;
  final double maxPrice;
  final Color gridLineColor;
  final String signedCountAxisLabel;
  final Color mutedForegroundColor;

  static const _axisLabelGutter = 14.0;
  static const _leftMargin = 40.0;
  static const _rightMargin = 18.0;
  static const _topMargin = 8.0;
  static const _bottomMargin = 34.0;

  _ActorPriceCurveChartPainter({
    required this.chartData,
    required this.supplyTicks,
    required this.yTicks,
    required this.maxSupply,
    required this.signedCount,
    required this.currentPrice,
    required this.maxPrice,
    required this.gridLineColor,
    required this.signedCountAxisLabel,
    required this.mutedForegroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plotWidth = size.width - _leftMargin - _rightMargin;
    final plotHeight = size.height - _topMargin - _bottomMargin;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    final plotRect = Rect.fromLTWH(
      _leftMargin,
      _topMargin,
      plotWidth,
      plotHeight,
    );

    for (final tick in yTicks) {
      final y = _yForPrice(tick, plotRect);
      if (y < plotRect.top || y > plotRect.bottom) continue;
      final gridPaint = Paint()
        ..color = gridLineColor
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
      _drawText(
        canvas,
        tick == 0 ? '0' : formatNumber(tick),
        Offset(plotRect.left - 10, y),
        align: ui.TextAlign.right,
        centerVertically: true,
        color: mutedForegroundColor,
      );
    }

    final curvePaint = Paint()
      ..color = StoryColors.warning
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < chartData.length; i++) {
      final point = chartData[i];
      final offset = Offset(
        _xForSigned(point.signed, plotRect),
        _yForPrice(point.price, plotRect),
      );
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    canvas.drawPath(path, curvePaint);

    final markerX = _xForSigned(signedCount, plotRect);
    final markerY = _yForPrice(currentPrice, plotRect);
    final dashPaint = Paint()
      ..color = StoryColors.brandTeal
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(markerX, plotRect.top),
      Offset(markerX, plotRect.bottom),
      dashPaint,
    );
    _drawDashedLine(
      canvas,
      Offset(plotRect.left, markerY),
      Offset(plotRect.right, markerY),
      dashPaint,
    );
    canvas.drawCircle(
      Offset(markerX, markerY),
      4.5,
      Paint()..color = StoryColors.brandTeal,
    );

    for (final tick in supplyTicks) {
      final x = _xForSigned(tick, plotRect);
      _drawText(
        canvas,
        formatNumber(tick, 0),
        Offset(x, plotRect.bottom + 8),
        align: ui.TextAlign.center,
        color: mutedForegroundColor,
      );
    }

    _drawText(
      canvas,
      signedCountAxisLabel,
      Offset(plotRect.center.dx, size.height - 4),
      align: ui.TextAlign.center,
      color: mutedForegroundColor,
    );
  }

  double _xForSigned(int signed, Rect plotRect) =>
      plotRect.left + (signed / maxSupply) * plotRect.width;

  double _yForPrice(double price, Rect plotRect) {
    if (maxPrice <= 0) return plotRect.bottom;
    final ratio = (price / maxPrice).clamp(0.0, 1.0);
    return plotRect.bottom - ratio * plotRect.height;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    ui.TextAlign align = ui.TextAlign.left,
    bool centerVertically = false,
    Color color = StoryColors.darkMutedForeground,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, height: 1.2, color: color),
      ),
      textAlign: align,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    var dx = offset.dx;
    if (align == ui.TextAlign.center) {
      dx -= painter.width / 2;
    } else if (align == ui.TextAlign.right) {
      dx -= painter.width;
    }

    var dy = offset.dy;
    if (centerVertically) {
      dy -= painter.height / 2;
    }

    painter.paint(canvas, Offset(dx, dy));
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dash = 4,
    double gap = 4,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;
    var drawn = 0.0;
    while (drawn < distance) {
      final dashEnd = math.min(drawn + dash, distance);
      canvas.drawLine(
        Offset(start.dx + unitX * drawn, start.dy + unitY * drawn),
        Offset(start.dx + unitX * dashEnd, start.dy + unitY * dashEnd),
        paint,
      );
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ActorPriceCurveChartPainter oldDelegate) =>
      oldDelegate.signedCount != signedCount ||
      oldDelegate.currentPrice != currentPrice ||
      oldDelegate.maxSupply != maxSupply ||
      oldDelegate.maxPrice != maxPrice ||
      oldDelegate.gridLineColor != gridLineColor ||
      oldDelegate.mutedForegroundColor != mutedForegroundColor;
}
