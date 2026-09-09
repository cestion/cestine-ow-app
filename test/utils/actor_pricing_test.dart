import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/l10n/app_localizations_en.dart';
import 'package:story_app/src/l10n/app_localizations_zh.dart';
import 'package:story_app/src/utils/actor_pricing.dart';

void main() {
  group('formatActorNftLabel', () {
    test('uses localized RoleNFT prefix', () {
      final en = AppLocalizationsEn();
      final zh = AppLocalizationsZh();
      expect(formatActorNftLabel(en, null), 'RoleNFT#Unknown');
      expect(formatActorNftLabel(en, ''), 'RoleNFT#Unknown');
      expect(formatActorNftLabel(en, 'abcdefghijklmnop'), 'RoleNFT#abcdefgh');
      expect(formatActorNftLabel(zh, null), '角色NFT#未知');
      expect(formatActorNftLabel(zh, 'abcdefghijklmnop'), '角色NFT#abcdefgh');
    });
  });

  group('formatActorPriceCeilDisplay', () {
    test('returns 0 for non-positive or non-finite values', () {
      expect(formatActorPriceCeilDisplay(0), '0');
      expect(formatActorPriceCeilDisplay(-1), '0');
      expect(formatActorPriceCeilDisplay(double.nan), '0');
      expect(formatActorPriceCeilDisplay(double.infinity), '0');
      expect(formatActorPriceCeilDisplay(double.negativeInfinity), '0');
    });

    test('keeps exact two-decimal boundary values without float ceil bump', () {
      // Regression: (1.1 * 100).ceil() / 100 used to yield 1.11 due to
      // IEEE double noise (1.1 * 100 == 110.00000000000001).
      expect(formatActorPriceCeilDisplay(1.1), '1.1');
      expect(formatActorPriceCeilDisplay(1.10), '1.1');
      expect(formatActorPriceCeilDisplay(0.1), '0.1');
      expect(formatActorPriceCeilDisplay(0.10), '0.1');
    });

    test('rounds up fractional cents to two decimals', () {
      expect(formatActorPriceCeilDisplay(1.101), '1.11');
      expect(formatActorPriceCeilDisplay(1.1000001), '1.11');
      expect(formatActorPriceCeilDisplay(1.105), '1.11');
      expect(formatActorPriceCeilDisplay(1.109), '1.11');
      expect(formatActorPriceCeilDisplay(0.001), '0.01');
    });

    test('strips trailing zeros via formatNumber', () {
      expect(formatActorPriceCeilDisplay(2.0), '2');
      expect(formatActorPriceCeilDisplay(2.50), '2.5');
      expect(formatActorPriceCeilDisplay(1000.1), '1,000.1');
    });
  });
}
