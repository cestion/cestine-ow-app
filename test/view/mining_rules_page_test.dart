import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/config_providers.dart';
import 'package:story_app/src/view/mining_rules_page.dart';

void main() {
  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        globalConfigProvider.overrideWith(
          (ref) async => Result.success(
            const GlobalConfig(
              init: InitConfig(
                actorNft: InitActorNftConfig(
                  staminaLimit: 168,
                  levels: {
                    '1': InitActorNftLevelConfig(
                      name: '群演',
                      miningCoefficient: 1,
                      upgrade: InitActorNftUpgradeConfig(
                        fee: 8,
                        toLevel: 2,
                        heatThreshold: 2,
                        requiredMaterialCount: 2,
                      ),
                    ),
                    '2': InitActorNftLevelConfig(
                      name: '配角',
                      miningCoefficient: 3,
                      upgrade: InitActorNftUpgradeConfig(
                        fee: 6,
                        toLevel: 3,
                        heatThreshold: 3,
                        requiredMaterialCount: 2,
                      ),
                    ),
                    '3': InitActorNftLevelConfig(
                      name: '主角',
                      miningCoefficient: 11,
                      upgrade: InitActorNftUpgradeConfig(
                        fee: 7,
                        toLevel: 4,
                        heatThreshold: 4,
                        requiredMaterialCount: 2,
                      ),
                    ),
                    '4': InitActorNftLevelConfig(
                      name: '巨星',
                      miningCoefficient: 27,
                      upgrade: InitActorNftUpgradeConfig(
                        fee: 8,
                        toLevel: 5,
                        heatThreshold: 5,
                        requiredMaterialCount: 2,
                      ),
                    ),
                    '5': InitActorNftLevelConfig(
                      name: '顶流',
                      miningCoefficient: 81,
                    ),
                  },
                ),
              ),
            ),
          ),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: MiningRulesPage(),
      ),
    );
  }

  testWidgets('MiningRulesPage renders all sections and content correctly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // AppBar title + summary card.
    expect(find.text('经营玩法'), findsOneWidget);
    expect(find.textContaining('签约角色、安排演出'), findsOneWidget);

    // Collapsed accordion titles.
    expect(find.text('怎么让角色开始赚钱？'), findsOneWidget);
    expect(find.text('体力怎么管理？'), findsOneWidget);
    expect(find.text('片酬怎么算？'), findsOneWidget);
    expect(find.text('什么时候结算？'), findsOneWidget);
    expect(find.text('怎么升级角色？'), findsNothing);

    // Expand the stamina accordion to reveal the status description.
    await tester.tap(find.text('体力怎么管理？'));
    await tester.pumpAndSettle();

    expect(find.textContaining('演出中：每小时消耗 1 点体力'), findsOneWidget);
    expect(find.textContaining('补充体力（付费）：瞬间回满 168'), findsOneWidget);

    // Expand the salary accordion to reveal the formula breakdown.
    await tester.tap(find.text('片酬怎么算？'));
    await tester.pumpAndSettle();

    expect(find.text('咖位越高、角色越贵、短剧越火，每小时片酬就越高。'), findsOneWidget);
    expect(find.text('角色片酬 = Lv.1 角色片酬 × 片酬系数'), findsOneWidget);
    expect(find.text('Lv.1 角色片酬 = 价格系数 × 热度系数'), findsOneWidget);
    expect(
      find.text('片酬系数：Lv1=1 · Lv2=3 · Lv3=9 · Lv4=27 · Lv5=81'),
      findsOneWidget,
    );
  });
}
