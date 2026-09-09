import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/components/iap/iap_purchase_result_dialog.dart';
import 'package:story_app/src/l10n/app_localizations.dart';

Widget _host({bool dark = false, bool success = true, String? reason}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    theme: ThemeData(brightness: Brightness.light),
    darkTheme: ThemeData(brightness: Brightness.dark),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showIapPurchaseResultDialog(
              context,
              grantedAmount: '9.000000',
              status: success
                  ? IapPurchaseDialogStatus.success
                  : IapPurchaseDialogStatus.failure,
              failureReason: reason,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('purchase success dialog renders title, points and buttons', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('购买成功'), findsOneWidget);
    expect(find.text('+9.000000'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
  });

  testWidgets('confirm closes the dialog', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('购买成功'), findsNothing);
  });

  testWidgets('dark mode uses dark card background', (tester) async {
    await tester.pumpWidget(_host(dark: true));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final card = find.byWidgetPredicate(
      (w) =>
          w is Dialog &&
          w.backgroundColor == const Color(0xFF111113),
    );
    expect(card, findsOneWidget);
  });

  testWidgets('failure state shows 购买失败 title and plain reason text', (
    tester,
  ) async {
    await tester.pumpWidget(_host(success: false, reason: '订单已过期'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('购买失败'), findsOneWidget);
    expect(find.text('订单已过期'), findsOneWidget);
    // 成功态的点数行不再展示
    expect(find.text('+9'), findsNothing);
    expect(find.text('确定'), findsOneWidget);
  });
}
