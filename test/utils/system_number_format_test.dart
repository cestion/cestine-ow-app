import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/l10n/app_localizations_zh.dart';
import 'package:story_app/src/utils/create_actor_form_validator.dart';
import 'package:story_app/src/utils/system_number_format.dart';

void main() {
  final format = SystemNumberFormat.instance;
  final l10n = AppLocalizationsZh();

  tearDown(() {
    format.debugOverride();
  });

  group('SystemNumberFormat.parseDecimal', () {
    test('parses US-style decimals and grouping', () {
      format.debugOverride(decimalSeparator: '.', groupingSeparator: ',');
      expect(format.parseDecimal('12.5'), 12.5);
      expect(format.parseDecimal('1,234.56'), 1234.56);
      expect(format.parseDecimal('123,456'), 123456);
      expect(format.parseDecimal('10'), 10);
    });

    test('parses EU-style decimals (iOS Number Format comma)', () {
      format.debugOverride(decimalSeparator: ',', groupingSeparator: '.');
      expect(format.parseDecimal('12,5'), 12.5);
      expect(format.parseDecimal('1.234,56'), 1234.56);
      expect(format.parseDecimal('123.456'), 123456);
      expect(format.parseDecimal('12.5'), 12.5); // alternate decimal
    });

    test('US heuristic: single comma with ≤2 fraction digits is decimal', () {
      format.debugOverride(decimalSeparator: '.', groupingSeparator: ',');
      expect(format.parseDecimal('12,5'), 12.5);
      expect(format.parseDecimal('12,50'), 12.5);
    });

    test('rejects empty / garbage', () {
      format.debugOverride(decimalSeparator: ',', groupingSeparator: '.');
      expect(format.parseDecimal(''), isNull);
      expect(format.parseDecimal('abc'), isNull);
    });
  });

  group('SystemDecimalTextInputFormatter', () {
    TextEditingValue apply(String oldText, String newText) {
      final formatter = SystemDecimalTextInputFormatter(maxFractionDigits: 2);
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: oldText.length),
        ),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        ),
      );
    }

    test('inserts US thousand separators while typing', () {
      format.debugOverride(decimalSeparator: '.', groupingSeparator: ',');
      expect(apply('12345', '123456').text, '123,456');
      expect(apply('123,456', '123,4567').text, '1,234,567');
    });

    test('inserts EU thousand separators while typing', () {
      format.debugOverride(decimalSeparator: ',', groupingSeparator: '.');
      expect(apply('12345', '123456').text, '123.456');
      expect(apply('12', '12,5').text, '12,5');
    });

    test('rewrites alternate decimal to system comma', () {
      format.debugOverride(decimalSeparator: ',', groupingSeparator: '.');
      final value = apply('12', '12.5');
      expect(value.text, '12,5');
    });

    test('blocks more than 2 fraction digits', () {
      format.debugOverride(decimalSeparator: ',', groupingSeparator: '.');
      final value = apply('12,50', '12,501');
      expect(value.text, '12,50');
    });

    test('keeps caret after decimal when typing decimal mark', () {
      format.debugOverride(decimalSeparator: '.', groupingSeparator: ',');
      final formatter = SystemDecimalTextInputFormatter(maxFractionDigits: 2);
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '123,456',
          selection: TextSelection.collapsed(offset: 7),
        ),
        const TextEditingValue(
          text: '123,456.',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );
      expect(result.text, '123,456.');
      expect(result.selection.baseOffset, 8);
    });

    test('keeps system dot decimals', () {
      format.debugOverride(decimalSeparator: '.', groupingSeparator: ',');
      final value = apply('12', '12.5');
      expect(value.text, '12.5');
    });
  });

  group('validateCreateActorForm with locale decimals', () {
    test('accepts comma decimal when system separator is comma', () {
      format.debugOverride(decimalSeparator: ',', groupingSeparator: '.');
      final result = validateCreateActorForm(
        l10n: l10n,
        name: '演员',
        bio: '简介',
        totalSupplyText: '1000',
        priceText: '10,25',
      );
      expect(result.isValid, isTrue);
      expect(result.price, 10.25);
    });

    test('accepts US grouped integer price within range', () {
      format.debugOverride(decimalSeparator: '.', groupingSeparator: ',');
      final result = validateCreateActorForm(
        l10n: l10n,
        name: '演员',
        bio: '简介',
        totalSupplyText: '1000',
        priceText: '1,000',
      );
      expect(result.isValid, isTrue);
      expect(result.price, 1000);
    });

    test('rejects too many fraction digits with comma', () {
      format.debugOverride(decimalSeparator: ',', groupingSeparator: '.');
      final result = validateCreateActorForm(
        l10n: l10n,
        name: '演员',
        bio: '简介',
        totalSupplyText: '1000',
        priceText: '10,251',
      );
      expect(result.isValid, isFalse);
      expect(result.errors.price, l10n.createActorValidationPriceMaxDecimals);
    });
  });
}
