import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../model/actor_collection_model.dart';
import '../model/mining_actor_model.dart';
import 'format_number.dart';

/// IP 算力构成，对齐 web `ActorIpPowerBreakdown`。
class ActorIpPowerBreakdown {
  final double priceCoefficient;
  final double heatCoefficient;
  final double trust1;
  final double ipPower;

  const ActorIpPowerBreakdown({
    required this.priceCoefficient,
    required this.heatCoefficient,
    required this.trust1,
    required this.ipPower,
  });
}

/// 角色/演员算力构成，对齐 web `ActorMiningPowerBreakdown`。
class ActorMiningPowerBreakdown extends ActorIpPowerBreakdown {
  final double miningCoefficient;
  final double cpCoefficient;
  final double trust2;
  final double actorPower;

  const ActorMiningPowerBreakdown({
    required super.priceCoefficient,
    required super.heatCoefficient,
    required super.trust1,
    required super.ipPower,
    required this.miningCoefficient,
    required this.cpCoefficient,
    required this.trust2,
    required this.actorPower,
  });

  /// V2 经纪人场景中的每小时角色片酬（STORY/h）。
  ///
  /// `actorPower` 是旧版「角色算力」命名；两者数值语义一致。
  double get hourlySalary => actorPower;
}

Decimal _toDec(num value) => Decimal.parse(value.toString());

/// 向下截断到 [precision] 位小数，对齐 web `truncate(..., ROUND_DOWN)`。
double truncatePower(num value, int precision) {
  if (!value.isFinite) return 0;
  return _toDec(value).truncate(scale: precision).toDouble();
}

/// 合集层 IP 片酬：价格系数 × 热度系数 × Trust1。
///
/// Trust1 仅参与计算，对外 UI 不单独展示。
double calculateActorIpPower({
  required double priceCoefficient,
  required double heatCoefficient,
  required double trust1,
}) {
  return truncatePower(
    (_toDec(priceCoefficient) * _toDec(heatCoefficient) * _toDec(trust1))
        .toDouble(),
    10,
  );
}

/// 由发行初始价 P0 计算价格系数（前端预览；后端会版本锁定）。
///
/// - P0 ≤ 10：`P0 / 10`
/// - P0 > 10：`1.6 × r^1.3 / (r^1.3 + 0.6)`，其中 `r = P0/10`，渐近上限 1.6
double calculateActorPriceCoefficient(double initialPrice) {
  if (!initialPrice.isFinite || initialPrice <= 0) return 0;

  final p0 = _toDec(initialPrice);
  final base = Decimal.fromInt(10);
  if (p0 <= base) {
    final ratio = p0 / base;
    final dec = ratio.hasFinitePrecision
        ? ratio.toDecimal()
        : ratio.toDecimal(scaleOnInfinitePrecision: 20);
    return dec.truncate(scale: 10).toDouble();
  }

  final ratio = (p0 / base).toDouble();
  final ratioPow = math.pow(ratio, 1.3).toDouble();
  if (!ratioPow.isFinite || ratioPow <= 0) return 0;

  final coefficient = 1.6 * ratioPow / (ratioPow + 0.6);
  return truncatePower(coefficient, 10);
}

String formatPowerValue(double? value) {
  if (value == null || !value.isFinite) return '-';
  return formatNumber(value, 4);
}

String formatPowerFactor(double? value) {
  if (value == null || !value.isFinite) return '-';
  return truncatePower(value, 4).toStringAsFixed(4);
}

String formatHeatFactor(double? value) {
  if (value == null || !value.isFinite) return '-';
  return truncatePower(value, 2).toStringAsFixed(2);
}

/// Trust1 / Trust2 展示：截断到 2 位小数并固定两位。
String formatTrustFactor(double? value) {
  if (value == null || !value.isFinite) return '-';
  return truncatePower(value, 2).toStringAsFixed(2);
}

/// 合集层 IP 算力：优先 API `computingPower` / 锁定 `initialPriceMultiplier`。
ActorIpPowerBreakdown getActorIpPowerBreakdown(ActorCollection actor) {
  final priceCoefficient =
      actor.initialPriceMultiplier ??
      calculateActorPriceCoefficient(actor.initialPriceUsdc ?? 0);
  final heatCoefficient = actor.heatValue ?? 0;
  final trust1 = actor.trust ?? 1;
  final ipPower =
      actor.computingPower ??
      calculateActorIpPower(
        priceCoefficient: priceCoefficient,
        heatCoefficient: heatCoefficient,
        trust1: trust1,
      );

  return ActorIpPowerBreakdown(
    priceCoefficient: priceCoefficient,
    heatCoefficient: heatCoefficient,
    trust1: trust1,
    ipPower: ipPower,
  );
}

/// 持卡挖矿层角色算力：优先 API `computingPower`。
///
/// 拆解字段优先 OpenAPI `memo`（p0 / heat / trust1 / trust2 / CP / MC），
/// 再回退扁平 legacy。
ActorMiningPowerBreakdown getMiningActorPowerBreakdown(MiningActor actor) {
  final memo = actor.memo;
  final priceCoefficient = memo?.p0 ?? actor.priceCoefficient ?? 1;
  final heatCoefficient = memo?.heat ?? actor.heat ?? 0;
  final trust1 = memo?.trust1 ?? actor.trust1 ?? 1;
  final ipPower =
      actor.ipPower ??
      calculateActorIpPower(
        priceCoefficient: priceCoefficient,
        heatCoefficient: heatCoefficient,
        trust1: trust1,
      );
  final miningCoefficient = memo?.mc ?? actor.miningCoefficient ?? 0;
  final cpCoefficient = memo?.cp ?? actor.cpCoefficient ?? 1;
  final trust2 = memo?.trust2 ?? actor.trust2 ?? actor.trust ?? 1;
  final actorPower =
      actor.computingPower ??
      truncatePower(
        (_toDec(ipPower) *
                _toDec(miningCoefficient) *
                _toDec(cpCoefficient) *
                _toDec(trust2))
            .toDouble(),
        10,
      );

  return ActorMiningPowerBreakdown(
    priceCoefficient: priceCoefficient,
    heatCoefficient: heatCoefficient,
    trust1: trust1,
    ipPower: ipPower,
    miningCoefficient: miningCoefficient,
    cpCoefficient: cpCoefficient,
    trust2: trust2,
    actorPower: actorPower,
  );
}

/// 角色每小时片酬：IP 片酬 × 片酬系数 × CP 系数 × Trust2。
///
/// 计算明细及后端锁定值的优先级统一由 [getMiningActorPowerBreakdown] 维护，
/// 候选角色和正在挖矿角色必须共用此入口，避免两个列表展示不一致。
double getMiningActorHourlySalary(MiningActor actor) =>
    getMiningActorPowerBreakdown(actor).hourlySalary;
