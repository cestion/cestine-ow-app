import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/l10n/app_localizations_zh.dart';
import 'package:story_app/src/utils/create_actor_form_validator.dart';

void main() {
  final l10n = AppLocalizationsZh();

  group('validateCreateActorForm', () {
    test('returns field errors when required inputs are empty', () {
      final result = validateCreateActorForm(
        l10n: l10n,
        name: '',
        bio: '',
        totalSupplyText: '',
        priceText: '',
      );

      expect(result.isValid, isFalse);
      expect(result.errors.name, l10n.createActorValidationNameRequired);
      expect(result.errors.bio, l10n.createActorValidationBioRequired);
      expect(
        result.errors.totalSupply,
        l10n.createActorValidationTotalSupplyRequired,
      );
      expect(result.errors.price, l10n.createActorValidationPriceRequired);
    });

    test('rejects total supply outside 100-5000', () {
      final low = validateCreateActorForm(
        l10n: l10n,
        name: '演员',
        bio: '简介',
        totalSupplyText: '50',
        priceText: '10',
      );
      expect(low.isValid, isFalse);
      expect(
        low.errors.totalSupply,
        l10n.createActorValidationTotalSupplyRange,
      );

      final high = validateCreateActorForm(
        l10n: l10n,
        name: '演员',
        bio: '简介',
        totalSupplyText: '6000',
        priceText: '10',
      );
      expect(high.isValid, isFalse);
      expect(
        high.errors.totalSupply,
        l10n.createActorValidationTotalSupplyRange,
      );
    });

    test('rejects mint price outside 10-1000', () {
      final low = validateCreateActorForm(
        l10n: l10n,
        name: '演员',
        bio: '简介',
        totalSupplyText: '1000',
        priceText: '9.99',
      );
      expect(low.isValid, isFalse);
      expect(low.errors.price, l10n.createActorValidationPriceInvalid);

      final high = validateCreateActorForm(
        l10n: l10n,
        name: '演员',
        bio: '简介',
        totalSupplyText: '1000',
        priceText: '1000.01',
      );
      expect(high.isValid, isFalse);
      expect(high.errors.price, l10n.createActorValidationPriceInvalid);
    });

    test('accepts valid issuance parameters', () {
      final result = validateCreateActorForm(
        l10n: l10n,
        name: '演员',
        bio: '简介',
        totalSupplyText: '1000',
        priceText: '10.25',
      );

      expect(result.isValid, isTrue);
      expect(result.totalSupply, 1000);
      expect(result.price, 10.25);
    });
  });
}
