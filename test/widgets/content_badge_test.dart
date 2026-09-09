import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/components/badge/content_badge.dart';
import 'package:story_app/src/l10n/app_localizations.dart';

Widget _wrap({
  required Locale locale,
  required double parentWidth,
  ContentBadgeStyle style = ContentBadgeStyle.cardCorner,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(
      body: SizedBox(
        width: parentWidth,
        height: 150,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            ContentBadge.positionedCardCorner(badge: 'COMMUNITY', style: style),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('short cardCorner badge hugs the label instead of filling 2/3', (
    tester,
  ) async {
    const parentWidth = 180.0;
    await tester.pumpWidget(
      _wrap(locale: const Locale('zh'), parentWidth: parentWidth),
    );
    await tester.pump();

    final badgeSize = tester.getSize(find.byType(ContentBadge));
    expect(badgeSize.width, lessThan(parentWidth * 2 / 3 - 8));
    expect(find.text('社区发行'), findsOneWidget);
  });

  testWidgets('long cardCorner badge caps at two thirds and ellipsizes', (
    tester,
  ) async {
    const parentWidth = 180.0;
    await tester.pumpWidget(
      _wrap(locale: const Locale('vi'), parentWidth: parentWidth),
    );
    await tester.pump();

    final badgeSize = tester.getSize(find.byType(ContentBadge));
    expect(badgeSize.width, closeTo(parentWidth * 2 / 3, 0.5));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('IP compact badge hugs short zh copy at 20px / 10r', (
    tester,
  ) async {
    const parentWidth = 175.5;
    await tester.pumpWidget(
      _wrap(
        locale: const Locale('zh'),
        parentWidth: parentWidth,
        style: ContentBadgeStyle.profileCardCorner,
      ),
    );
    await tester.pump();

    final badgeSize = tester.getSize(find.byType(ContentBadge));
    expect(badgeSize.height, 20);
    expect(badgeSize.width, lessThan(parentWidth * 2 / 3 - 8));
    expect(find.text('社区发行'), findsOneWidget);
  });

  testWidgets('IP compact badge caps long vi copy at two thirds', (
    tester,
  ) async {
    const parentWidth = 175.5;
    await tester.pumpWidget(
      _wrap(
        locale: const Locale('vi'),
        parentWidth: parentWidth,
        style: ContentBadgeStyle.profileCardCorner,
      ),
    );
    await tester.pump();

    final badgeSize = tester.getSize(find.byType(ContentBadge));
    expect(badgeSize.height, 20);
    expect(badgeSize.width, closeTo(parentWidth * 2 / 3, 0.5));
  });
}
