import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';

/// Shared geometry for drama cards and their loading placeholders.
class DramaManagementGridLayout {
  static const coverAspectRatio = 232 / 310;
  static const gridPadding = EdgeInsets.fromLTRB(8, 8, 8, 24);
  static const spacing = 8.0;
  static const contentPadding = 12.0;
  static const actionHorizontalPadding = 16.0;
  static const titleMaxLines = 1;
  static const titleStyle = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
  );
  static const metadataStyle = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.04,
  );
  static const actionStyle = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
  );

  final int columnCount;
  final double cardWidth;
  final double titleHeight;
  final double metadataHeight;
  final double actionHeight;

  const DramaManagementGridLayout._({
    required this.columnCount,
    required this.cardWidth,
    required this.titleHeight,
    required this.metadataHeight,
    required this.actionHeight,
  });

  /// [availableWidth] includes the grid's horizontal padding.
  factory DramaManagementGridLayout.of(
    BuildContext context,
    double availableWidth,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    final width = math.max(1.0, availableWidth - gridPadding.horizontal);
    // Preserve readable cards on narrow screens and with accessibility fonts.
    final minCardWidth = 160 * math.max(1.0, scaler.scale(16) / 16);
    final columns = math.max(
      1,
      ((width + spacing) / (minCardWidth + spacing)).floor(),
    );
    final cardWidth = (width - spacing * (columns - 1)) / columns;
    final textWidth = math.max(1.0, cardWidth - contentPadding * 2);
    final defaultStyle = DefaultTextStyle.of(context).style;

    double measure(String text, TextStyle style, double maxWidth) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: defaultStyle.merge(style)),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        locale: Localizations.localeOf(context),
      )..layout(maxWidth: maxWidth);
      final height = painter.height.ceilToDouble();
      painter.dispose();
      return height;
    }

    final l10n = context.l10n;
    final actionTextWidth = math.max(
      1.0,
      textWidth - actionHorizontalPadding * 2,
    );
    final actionTextHeight =
        [
              l10n.creatorDramaEdit,
              l10n.creatorDramaStatusPendingReview,
              l10n.creatorDramaStatusOffline,
            ]
            .map((label) => measure(label, actionStyle, actionTextWidth))
            .reduce(math.max);

    return DramaManagementGridLayout._(
      columnCount: columns,
      cardWidth: cardWidth,
      titleHeight: measure('Ag国', titleStyle, double.infinity),
      metadataHeight: measure('Ag国', metadataStyle, double.infinity),
      actionHeight: math.max(44, actionTextHeight + 24),
    );
  }

  double get cardHeight =>
      cardWidth / coverAspectRatio +
      contentPadding * 2 +
      titleHeight +
      spacing * 2 +
      metadataHeight +
      actionHeight;

  SliverGridDelegateWithFixedCrossAxisCount get gridDelegate =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent: cardHeight,
      );
}
