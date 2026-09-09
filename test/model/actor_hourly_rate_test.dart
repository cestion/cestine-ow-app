import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/model/actor_hourly_rate.dart';

void main() {
  test('resolves storyPerHour then unitPrice then computingPower', () {
    expect(
      const ActorHourlyRate(storyPerHour: 6344, unitPrice: 0.01).value,
      6344,
    );
    expect(
      const ActorHourlyRate(unitPrice: 0.01, computingPower: 19).value,
      0.01,
    );
    expect(const ActorHourlyRate(computingPower: 19.0032).value, 19.0032);
    expect(ActorHourlyRate.none.value, isNull);
    expect(const ActorHourlyRate(storyPerHour: 0).value, 0);
  });

  test('payValue uses storyPerHour then computingPower, never unitPrice', () {
    expect(
      const ActorHourlyRate(
        storyPerHour: 26.3,
        unitPrice: 0.01,
        computingPower: 19,
      ).payValue,
      26.3,
    );
    expect(
      const ActorHourlyRate(unitPrice: 0.01, computingPower: 19).payValue,
      19,
    );
    expect(const ActorHourlyRate(unitPrice: 0.01).payValue, isNull);
    expect(
      const ActorHourlyRate(storyPerHour: 0, computingPower: 19).payValue,
      19,
    );
  });

  test('skips zero storyPerHour so unitPrice can show', () {
    expect(const ActorHourlyRate(storyPerHour: 0, unitPrice: 0.01).value, 0.01);
  });

  test('keeps explicit zero when there is no fallback', () {
    expect(const ActorHourlyRate(storyPerHour: 0).overlay(null).value, 0);
    expect(
      const ActorHourlyRate(
        storyPerHour: 0,
      ).overlay(ActorHourlyRate.none).value,
      0,
    );
  });

  test('fromJson reads nested nft and boundActorCollection', () {
    final rates = ActorHourlyRate.fromJson(const {
      'storyPerHour': 0,
      'boundActorCollection': {
        'computingPower': 19.0032,
        'nft': {'unitPrice': 0.01},
      },
    });
    expect(rates.unitPrice, 0.01);
    expect(rates.computingPower, 19.0032);
    expect(rates.value, 0.01);
  });

  test('overlay prefers non-zero self then fallback', () {
    const feed = ActorHourlyRate(storyPerHour: 0);
    const role = ActorHourlyRate(unitPrice: 0.01, computingPower: 19);
    expect(feed.overlay(role).value, 0.01);
  });

  test('format groups thousands and keeps decimals', () {
    expect(ActorHourlyRate.format(null), isNull);
    expect(ActorHourlyRate.format(6344), '6,344');
    expect(ActorHourlyRate.format(0), '0');
    expect(ActorHourlyRate.format(0.01), '0.01');
    expect(ActorHourlyRate.format(10.5), '10.5');
    expect(ActorHourlyRate.format(0.001), '< 0.01');
    expect(ActorHourlyRate.format(0.009), '< 0.01');
  });
}
