import '../model/init_config_model.dart';
import 'format_number.dart';

/// 片酬升级一档：到达该咖位所需完播 + 该等级片酬系数。
///
/// 对齐 web `listPlazaPayUpgradeRules`：完播门槛取 **上一档**
/// `upgrade.heatThreshold`，Lv.1 为 0。
class ActorPayUpgradeTier {
  final int level;
  final int completionThreshold;
  final double multiplier;

  const ActorPayUpgradeTier({
    required this.level,
    required this.completionThreshold,
    required this.multiplier,
  });
}

/// 规则页「升级路径」一行：从 from→to 的完播门槛与合成费。
///
/// 取自 `levels[from].upgrade`（heatThreshold / fee）。
class ActorPayUpgradePath {
  final int fromLevel;
  final int toLevel;
  final int heatThreshold;
  final double fee;

  const ActorPayUpgradePath({
    required this.fromLevel,
    required this.toLevel,
    required this.heatThreshold,
    required this.fee,
  });

  String get pathLabel => 'Lv$fromLevel → Lv$toLevel';

  String get heatLabel => '≥ ${formatNumber(heatThreshold, 0)}';

  String feeLabel([String currency = 'USDC']) {
    final precision = fee == fee.roundToDouble() ? 0 : 2;
    return '${formatNumber(fee, precision)} $currency';
  }
}

/// 配置缺失时的兜底档位（旧静态规则），避免广场卡在 config 未就绪时空白。
const kActorPayUpgradeTiersFallback = <ActorPayUpgradeTier>[
  ActorPayUpgradeTier(level: 1, completionThreshold: 0, multiplier: 1.0),
  ActorPayUpgradeTier(level: 2, completionThreshold: 10000, multiplier: 2.2),
  ActorPayUpgradeTier(level: 3, completionThreshold: 50000, multiplier: 5.0),
  ActorPayUpgradeTier(level: 4, completionThreshold: 200000, multiplier: 11.0),
  ActorPayUpgradeTier(level: 5, completionThreshold: 1000000, multiplier: 24.0),
];

/// Alias for older call sites / tests.
const kActorPayUpgradeTiers = kActorPayUpgradeTiersFallback;

List<({int level, InitActorNftLevelConfig config})> _sortedLevels(
  InitActorNftConfig? actorNft,
) {
  final levels = actorNft?.levels;
  if (levels == null || levels.isEmpty) return const [];

  final entries = <({int level, InitActorNftLevelConfig config})>[];
  for (final entry in levels.entries) {
    final level = int.tryParse(entry.key.trim());
    if (level == null) continue;
    entries.add((level: level, config: entry.value));
  }
  entries.sort((a, b) => a.level.compareTo(b.level));
  return entries;
}

/// 广场「最高」弹窗 / 最高片酬计算用的档位表。
List<ActorPayUpgradeTier> listPayUpgradeTiers(InitActorNftConfig? actorNft) {
  final levels = _sortedLevels(actorNft);
  if (levels.isEmpty) return kActorPayUpgradeTiersFallback;

  return [
    for (var i = 0; i < levels.length; i++)
      ActorPayUpgradeTier(
        level: levels[i].level,
        completionThreshold: i == 0
            ? 0
            : (levels[i - 1].config.upgrade?.heatThreshold ?? 0),
        multiplier: levels[i].config.miningCoefficient ?? 0,
      ),
  ];
}

/// 规则页「怎么升级角色」表格行。
List<ActorPayUpgradePath> listPayUpgradePaths(InitActorNftConfig? actorNft) {
  final levels = _sortedLevels(actorNft);
  if (levels.isEmpty) return const [];

  final paths = <ActorPayUpgradePath>[];
  for (final entry in levels) {
    final upgrade = entry.config.upgrade;
    if (upgrade == null) continue;
    final toLevel = upgrade.toLevel ?? (entry.level + 1);
    paths.add(
      ActorPayUpgradePath(
        fromLevel: entry.level,
        toLevel: toLevel,
        heatThreshold: upgrade.heatThreshold ?? 0,
        fee: upgrade.fee ?? 0,
      ),
    );
  }
  return paths;
}

/// 当前完播数能支持升到的最高等级。
int reachablePayLevel(
  int completedViewCount, {
  InitActorNftConfig? actorNft,
  List<ActorPayUpgradeTier>? tiers,
}) {
  final rows = tiers ?? listPayUpgradeTiers(actorNft);
  if (rows.isEmpty) return 1;
  var reachable = rows.first.level;
  for (final tier in rows) {
    if (completedViewCount >= tier.completionThreshold) {
      reachable = tier.level;
    }
  }
  return reachable;
}

double payMultiplierForLevel(
  int level, {
  InitActorNftConfig? actorNft,
  List<ActorPayUpgradeTier>? tiers,
}) {
  final rows = tiers ?? listPayUpgradeTiers(actorNft);
  for (final tier in rows) {
    if (tier.level == level) return tier.multiplier;
  }
  return rows.isEmpty ? 1.0 : rows.first.multiplier;
}

/// 最高片酬 = Lv.1 片酬 × 可达等级的片酬系数。
double? maxReachablePay({
  required double? lv1Pay,
  required int completedViewCount,
  InitActorNftConfig? actorNft,
  List<ActorPayUpgradeTier>? tiers,
}) {
  if (lv1Pay == null || !lv1Pay.isFinite) return null;
  final rows = tiers ?? listPayUpgradeTiers(actorNft);
  return lv1Pay *
      payMultiplierForLevel(
        reachablePayLevel(completedViewCount, tiers: rows),
        tiers: rows,
      );
}

String formatPayUpgradeMultiplier(double value) {
  if (!value.isFinite) return '-';
  return value.toStringAsFixed(1);
}

/// 完播门槛展示：中日用「万」，韩语用「만」，其余千分位。
String formatPayUpgradeCompletionCount(int count, {required String locale}) {
  if (count <= 0) return '0';
  final lang = locale.split(RegExp('[-_]')).first.toLowerCase();
  if (count >= 10000 && count % 10000 == 0) {
    final wan = count ~/ 10000;
    if (lang == 'zh' || lang == 'ja') return '$wan万';
    if (lang == 'ko') return '$wan만';
  }
  return formatNumber(count, 0);
}
