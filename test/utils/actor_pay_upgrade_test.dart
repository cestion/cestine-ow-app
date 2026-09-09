import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/init_config_model.dart';
import 'package:story_app/src/utils/actor_pay_upgrade.dart';

InitActorNftConfig _sampleActorNft() {
  return const InitActorNftConfig(
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
      '5': InitActorNftLevelConfig(name: '顶流', miningCoefficient: 81),
    },
  );
}

void main() {
  group('listPayUpgradeTiers', () {
    test('maps previous-level heatThreshold as completion gate', () {
      final tiers = listPayUpgradeTiers(_sampleActorNft());
      expect(tiers, hasLength(5));
      expect(tiers[0].completionThreshold, 0);
      expect(tiers[0].multiplier, 1);
      expect(tiers[1].completionThreshold, 2);
      expect(tiers[1].multiplier, 3);
      expect(tiers[4].completionThreshold, 5);
      expect(tiers[4].multiplier, 81);
    });

    test('falls back when config is missing', () {
      expect(listPayUpgradeTiers(null), kActorPayUpgradeTiersFallback);
    });
  });

  group('listPayUpgradePaths', () {
    test('reads heatThreshold and fee from upgrade config', () {
      final paths = listPayUpgradePaths(_sampleActorNft());
      expect(paths, hasLength(4));
      expect(paths[0].pathLabel, 'Lv1 → Lv2');
      expect(paths[0].heatThreshold, 2);
      expect(paths[0].fee, 8);
      expect(paths[0].heatLabel, '≥ 2');
      expect(paths[0].feeLabel(), '8 USDC');
      expect(paths[0].feeLabel('点数'), '8 点数');
      expect(paths[3].pathLabel, 'Lv4 → Lv5');
      expect(paths[3].heatThreshold, 5);
      expect(paths[3].fee, 8);
    });
  });

  group('reachablePayLevel', () {
    test('defaults to Lv.1 with no completions on fallback tiers', () {
      expect(reachablePayLevel(0), 1);
      expect(reachablePayLevel(9999), 1);
    });

    test('uses config thresholds when provided', () {
      final actorNft = _sampleActorNft();
      expect(reachablePayLevel(0, actorNft: actorNft), 1);
      expect(reachablePayLevel(2, actorNft: actorNft), 2);
      expect(reachablePayLevel(5, actorNft: actorNft), 5);
    });

    test('uses fallback 怎么变强 thresholds through Lv.5', () {
      expect(reachablePayLevel(10000), 2);
      expect(reachablePayLevel(49999), 2);
      expect(reachablePayLevel(50000), 3);
      expect(reachablePayLevel(200000), 4);
      expect(reachablePayLevel(999999), 4);
      expect(reachablePayLevel(1000000), 5);
    });
  });

  group('maxReachablePay', () {
    test('multiplies Lv.1 pay by the reachable-level coefficient', () {
      expect(
        maxReachablePay(lv1Pay: 10, completedViewCount: 0),
        closeTo(10, 0.0001),
      );
      expect(
        maxReachablePay(lv1Pay: 10, completedViewCount: 10000),
        closeTo(22, 0.0001),
      );
      expect(
        maxReachablePay(
          lv1Pay: 10,
          completedViewCount: 3,
          actorNft: _sampleActorNft(),
        ),
        closeTo(110, 0.0001),
      );
    });

    test('returns null when Lv.1 pay is missing', () {
      expect(maxReachablePay(lv1Pay: null, completedViewCount: 0), isNull);
    });
  });

  group('formatPayUpgradeCompletionCount', () {
    test('uses 万 for zh/ja multiples of 10k', () {
      expect(formatPayUpgradeCompletionCount(10000, locale: 'zh'), '1万');
      expect(formatPayUpgradeCompletionCount(1000000, locale: 'ja'), '100万');
    });

    test('uses thousands separators otherwise', () {
      expect(formatPayUpgradeCompletionCount(10000, locale: 'en'), '10,000');
      expect(formatPayUpgradeCompletionCount(0, locale: 'zh'), '0');
    });
  });
}
