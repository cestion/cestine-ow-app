import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/view/widgets/finance_dashboard/weekly_reward_list_item.dart';

void main() {
  Future<void> pumpItem(WidgetTester tester, {required WeeklyRewardItem item}) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: WeeklyRewardListItem(item: item)),
      ),
    );
  }

  testWidgets('shows less than 0.1% for a tiny positive usage rate', (
    tester,
  ) async {
    await pumpItem(
      tester,
      item: const WeeklyRewardItem(hardLimit: 1000000, miningRewards: 0.00001),
    );

    expect(find.text('<0.1%'), findsOneWidget);
    expect(find.text('0.0%'), findsNothing);
  });

  testWidgets('keeps zero usage as 0.0%', (tester) async {
    await pumpItem(
      tester,
      item: const WeeklyRewardItem(hardLimit: 1000000, miningRewards: 0),
    );

    expect(find.text('0.0%'), findsOneWidget);
    expect(find.text('<0.1%'), findsNothing);
  });

  testWidgets('formats usage rates at or above 0.1% normally', (tester) async {
    await pumpItem(
      tester,
      item: const WeeklyRewardItem(hardLimit: 1000, miningRewards: 1),
    );

    expect(find.text('0.1%'), findsOneWidget);
  });

  testWidgets('rolls an end-of-day reward period into the next date', (
    tester,
  ) async {
    await pumpItem(
      tester,
      item: const WeeklyRewardItem(
        rewardPeriodStart: '2026-07-26T00:00:00Z',
        rewardPeriodEnd: '2026-07-26T23:59:59Z',
      ),
    );

    expect(find.text('07/26 - 07/27'), findsOneWidget);
  });

  testWidgets('keeps a non-end-of-day reward period on its original date', (
    tester,
  ) async {
    await pumpItem(
      tester,
      item: const WeeklyRewardItem(
        rewardPeriodStart: '2026-07-26T00:00:00Z',
        rewardPeriodEnd: '2026-07-26T12:00:00Z',
      ),
    );

    expect(find.text('07/26 - 07/26'), findsOneWidget);
  });
}
