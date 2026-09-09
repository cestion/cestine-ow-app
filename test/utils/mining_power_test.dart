import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/actor_collection_model.dart';
import 'package:story_app/src/model/mining_actor_model.dart';
import 'package:story_app/src/utils/mining_power.dart';

void main() {
  group('calculateActorPriceCoefficient', () {
    test('returns 0 for non-positive prices', () {
      expect(calculateActorPriceCoefficient(0), 0);
      expect(calculateActorPriceCoefficient(-10), 0);
      expect(calculateActorPriceCoefficient(double.nan), 0);
    });

    test('linear growth when P0 <= 10', () {
      expect(calculateActorPriceCoefficient(10), 1);
      expect(calculateActorPriceCoefficient(5), 0.5);
      expect(calculateActorPriceCoefficient(1), 0.1);
    });

    test('asymptotic growth when P0 > 10 with cap near 1.6', () {
      // r = 12/10 = 1.2，与旧基准下 P0=120 同比例。
      final coef12 = calculateActorPriceCoefficient(12);
      expect(coef12, closeTo(1.0859, 0.002));
      expect(coef12, lessThan(1.6));

      final coef1000 = calculateActorPriceCoefficient(1000);
      expect(coef1000, lessThanOrEqualTo(1.6));
      expect(coef1000, greaterThan(1.5));
    });
  });

  group('getActorIpPowerBreakdown', () {
    test('prefers API computingPower and locked multiplier', () {
      const actor = ActorCollection(
        initialPriceUsdc: 120,
        initialPriceMultiplier: 1.1,
        heatValue: 3.5,
        trust: 1,
        computingPower: 42.5,
      );

      final breakdown = getActorIpPowerBreakdown(actor);
      expect(breakdown.priceCoefficient, 1.1);
      expect(breakdown.heatCoefficient, 3.5);
      expect(breakdown.trust1, 1);
      expect(breakdown.ipPower, 42.5);
    });

    test('falls back to local formula', () {
      const actor = ActorCollection(
        initialPriceUsdc: 10,
        heatValue: 3.5,
        trust: 1,
      );

      final breakdown = getActorIpPowerBreakdown(actor);
      expect(breakdown.priceCoefficient, 1);
      expect(breakdown.ipPower, 3.5);
    });

    test('local formula still multiplies hidden Trust1', () {
      const actor = ActorCollection(
        initialPriceUsdc: 10,
        heatValue: 3.5,
        trust: 0.8,
      );

      final breakdown = getActorIpPowerBreakdown(actor);
      expect(breakdown.trust1, 0.8);
      expect(breakdown.ipPower, closeTo(2.8, 0.0001));
      expect(
        calculateActorIpPower(
          priceCoefficient: 1,
          heatCoefficient: 3.5,
          trust1: 0.8,
        ),
        closeTo(2.8, 0.0001),
      );
    });
  });

  group('getMiningActorPowerBreakdown', () {
    test('prefers API computingPower as actor power', () {
      const actor = MiningActor(
        heat: 3.5,
        miningCoefficient: 5,
        computingPower: 19.0032,
      );

      final breakdown = getMiningActorPowerBreakdown(actor);
      expect(breakdown.actorPower, 19.0032);
    });

    test('falls back to IP × mining × CP × trust2', () {
      const actor = MiningActor(
        priceCoefficient: 1.0859,
        heat: 3.5,
        trust1: 1,
        miningCoefficient: 5,
        cpCoefficient: 1,
        trust2: 1,
      );

      final breakdown = getMiningActorPowerBreakdown(actor);
      expect(breakdown.ipPower, closeTo(3.80065, 0.0001));
      expect(breakdown.actorPower, closeTo(19.00325, 0.001));
    });

    test('reads breakdown factors from memo', () {
      const actor = MiningActor(
        heat: 3.5,
        miningCoefficient: 5,
        memo: MiningActorMemo(
          p0: 1.0859,
          heat: 3.5,
          trust1: 0.95,
          trust2: 0.92,
          cp: 0.85,
          mc: 1.2,
        ),
      );

      final breakdown = getMiningActorPowerBreakdown(actor);
      expect(breakdown.priceCoefficient, 1.0859);
      expect(breakdown.heatCoefficient, 3.5);
      expect(breakdown.trust1, 0.95);
      expect(breakdown.trust2, 0.92);
      expect(breakdown.cpCoefficient, 0.85);
      // memo.MC wins over root miningCoefficient.
      expect(breakdown.miningCoefficient, 1.2);
      expect(breakdown.ipPower, closeTo(3.6106175, 0.0001));
      expect(breakdown.actorPower, closeTo(3.3882, 0.001));
    });

    test('prefers memo over root heat/default trusts (QA screenshot case)', () {
      final actor = MiningActor.fromJson(const {
        'computingPower': 0.0601811871,
        'miningCoefficient': 1.0,
        'heat': 0.1,
        'memo': {
          'p0': 1.0048428881,
          'heat': 0.0623671155,
          'trust1': 0.97,
          'trust2': 0.99,
          'CP': 1.0,
          'MC': 1.0,
        },
      });

      final breakdown = getMiningActorPowerBreakdown(actor);
      expect(breakdown.priceCoefficient, closeTo(1.0048428881, 1e-9));
      expect(breakdown.heatCoefficient, closeTo(0.0623671155, 1e-9));
      expect(breakdown.trust1, 0.97);
      expect(breakdown.trust2, 0.99);
      expect(breakdown.cpCoefficient, 1.0);
      expect(breakdown.miningCoefficient, 1.0);
      expect(breakdown.ipPower, closeTo(0.06078, 0.0001));
      expect(breakdown.actorPower, 0.0601811871);
      expect(formatPowerFactor(breakdown.priceCoefficient), '1.0048');
      expect(formatHeatFactor(breakdown.heatCoefficient), '0.06');
      expect(formatTrustFactor(breakdown.trust1), '0.97');
      expect(formatTrustFactor(breakdown.trust2), '0.99');
    });
  });

  group('MiningActor memo json', () {
    test('parses nested memo trust and coefficients', () {
      final actor = MiningActor.fromJson(const {
        'actorName': 'Luna',
        'heat': 3.5,
        'miningCoefficient': 5,
        'computingPower': 19.0,
        'memo': {
          'p0': 1.5,
          'heat': 1.68,
          'trust1': 0.95,
          'trust2': 0.92,
          'CP': 0.85,
          'MC': 1.2,
        },
      });

      expect(actor.memo?.p0, 1.5);
      expect(actor.memo?.heat, 1.68);
      expect(actor.memo?.trust1, 0.95);
      expect(actor.memo?.trust2, 0.92);
      expect(actor.memo?.cp, 0.85);
      expect(actor.memo?.mc, 1.2);

      // Hive cache encodes via toJson — nested memo must be a Map, not a
      // MiningActorMemo instance (no TypeAdapter registered).
      final encoded = actor.toJson();
      final memoJson = encoded['memo'];
      expect(memoJson, isA<Map<String, dynamic>>());
      expect((memoJson as Map<String, dynamic>)['CP'], 0.85);

      final breakdown = getMiningActorPowerBreakdown(actor);
      expect(breakdown.trust1, 0.95);
      expect(breakdown.trust2, 0.92);
      expect(breakdown.priceCoefficient, 1.5);
      expect(breakdown.heatCoefficient, 1.68);
      expect(breakdown.cpCoefficient, 0.85);
      expect(breakdown.actorPower, 19.0);
    });
  });

  group('formatters', () {
    test('formatPowerFactor keeps 4 decimals', () {
      expect(formatPowerFactor(1.0859), '1.0859');
      expect(formatPowerFactor(0.5), '0.5000');
      expect(formatPowerFactor(null), '-');
    });

    test('formatTrustFactor truncates to 2 decimals', () {
      expect(formatTrustFactor(0.959), '0.95');
      expect(formatTrustFactor(0.955), '0.95');
      expect(formatTrustFactor(1), '1.00');
      expect(formatTrustFactor(null), '-');
    });
  });
}
