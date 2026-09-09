import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/components/creator/creator_status_badges.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/styles/story_colors.dart';

void main() {
  Widget buildBadge({required String status, required String auditReason}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: RejectedStatusBadge(
              status: status,
              auditReason: auditReason,
              l10n: AppLocalizations.of(context),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('offline status shows audit reason as bold dialog content', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBadge(status: 'OFFLINE', auditReason: '内容不符合平台规范'),
    );

    await tester.tap(find.text('已下架'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('其他原因'), findsNothing);
    final reason = tester.widget<Text>(find.text('内容不符合平台规范'));
    expect(reason.style?.fontWeight, FontWeight.w700);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('offline badge text and icon use pending orange', (tester) async {
    await tester.pumpWidget(
      buildBadge(status: 'OFFLINE', auditReason: '内容不符合平台规范'),
    );

    final label = tester.widget<Text>(find.text('已下架'));
    final icon = tester.widget<Icon>(find.byIcon(Icons.help_outline));
    expect(label.style?.color, StoryColors.pending);
    expect(icon.color, StoryColors.pending);
  });

  testWidgets('rejected status shows audit reason as bold dialog content', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBadge(status: 'REVIEW_REJECTED', auditReason: '缺少版权证明'),
    );

    await tester.tap(find.text('未通过'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('其他原因'), findsNothing);
    final details = tester.widget<Text>(find.text('缺少版权证明'));
    expect(details.style?.fontWeight, FontWeight.w700);
  });
}
