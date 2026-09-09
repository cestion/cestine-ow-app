import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/finance_dashboard_controller.dart';
import 'package:story_app/src/controller/finance_dashboard_state.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/view/widgets/finance_dashboard/story_allocation_section.dart';

void main() {
  testWidgets('formats allocation amount with thousands separators', (
    tester,
  ) async {
    const config = GlobalConfig(
      init: InitConfig(
        mining: InitMiningConfig(
          totalSupply: '10000000000',
          percents: InitMiningPercents(nftMiningPool: 20),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalConfigProvider.overrideWith(
            (ref) async => Result.success(config),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: Scaffold(
            body: SingleChildScrollView(child: StoryAllocationSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2,000.0M'), findsOneWidget);
    expect(find.text('总量 10,000M STORY'), findsOneWidget);
  });

  testWidgets('shows released amount and tiny NFT mining pool progress', (
    tester,
  ) async {
    const config = GlobalConfig(
      init: InitConfig(
        mining: InitMiningConfig(
          totalSupply: '10000000000',
          percents: InitMiningPercents(nftMiningPool: 20),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalConfigProvider.overrideWith(
            (ref) async => Result.success(config),
          ),
          financeDashboardControllerProvider.overrideWith(
            () => _TestFinanceDashboardController(
              const FinanceDashboardState(totalStoryReleased: 1000),
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: Scaffold(
            body: SingleChildScrollView(child: StoryAllocationSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1,000'), findsOneWidget);
    expect(find.text('<0.1%'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(5));
    expect(find.text('0%'), findsNWidgets(5));
  });
}

class _TestFinanceDashboardController extends FinanceDashboardController {
  final FinanceDashboardState initialState;

  _TestFinanceDashboardController(this.initialState);

  @override
  FinanceDashboardState build() => initialState;
}
