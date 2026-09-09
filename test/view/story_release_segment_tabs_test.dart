import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/view/widgets/finance_dashboard/story_release_segment_tabs.dart';

void main() {
  testWidgets('matches pill styling and scrolls horizontally for long labels', (
    tester,
  ) async {
    int? changedIndex;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 160,
              child: StoryReleaseSegmentTabs(
                selectedIndex: 0,
                onChanged: (index) => changedIndex = index,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(tester.takeException(), isNull);

    final selected = tester.widget<Text>(find.text('STORY Allocation'));
    final unselected = tester.widget<Text>(find.text('Recent Mining Release'));
    expect(selected.style?.fontWeight, FontWeight.w500);
    expect(unselected.style?.fontWeight, FontWeight.w400);

    await tester.ensureVisible(find.text('Recent Mining Release'));
    await tester.tap(find.text('Recent Mining Release'));
    expect(changedIndex, 1);
  });
}
