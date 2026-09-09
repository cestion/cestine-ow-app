import 'package:flutter_test/flutter_test.dart'
    hide isZero, isPositive, isNegative;
import 'package:story_app/src/utils/math_util.dart';

void main() {
  group('isNumeric', () {
    test('accepts numbers and numeric strings', () {
      expect(isNumeric(0), isTrue);
      expect(isNumeric(1.5), isTrue);
      expect(isNumeric('123'), isTrue);
      expect(isNumeric('1.23'), isTrue);
      expect(isNumeric('-1.23'), isTrue);
    });

    test('rejects null/empty/non-numeric', () {
      expect(isNumeric(null), isFalse);
      expect(isNumeric(''), isFalse);
      expect(isNumeric('abc'), isFalse);
      expect(isNumeric('   '), isFalse);
    });
  });

  group('arithmetic', () {
    test('plus returns sum as string', () {
      expect(plus('1.234', '2.345'), '3.579');
      expect(plus(1, 2), '3');
    });

    test('plus returns 0 on invalid input', () {
      expect(plus('abc', '2'), '0');
    });

    test('minus returns difference', () {
      expect(minus('5', '2'), '3');
      expect(minus('2', '5'), '-3');
    });

    test('multipliedBy returns product', () {
      expect(multipliedBy('2.5', '4'), '10');
    });

    test('div returns quotient', () {
      expect(div('10', '2'), '5');
      expect(div('1', '3'), startsWith('0.333'));
    });

    test('div by zero returns 0', () {
      expect(div('10', '0'), '0');
    });

    test('trunc truncates toward zero', () {
      expect(trunc('1.999'), '1');
      expect(trunc('-1.999'), '-1');
    });

    test('absValue returns absolute', () {
      expect(absValue('-1.5'), '1.5');
      expect(absValue('1.5'), '1.5');
    });

    test('mod returns remainder', () {
      expect(mod('10', '3'), '1');
    });
  });

  group('comparisons', () {
    test('isGreaterThan', () {
      expect(isGreaterThan('2', '1'), isTrue);
      expect(isGreaterThan('1', '2'), isFalse);
      expect(isGreaterThan('1', '1'), isFalse);
    });

    test('isLessThan', () {
      expect(isLessThan('1', '2'), isTrue);
      expect(isLessThan('2', '1'), isFalse);
    });

    test('isEqualTo', () {
      expect(isEqualTo('1.5', '1.5'), isTrue);
      expect(isEqualTo('1.50', '1.5'), isTrue);
      expect(isEqualTo('1.51', '1.5'), isFalse);
    });

    test('isZero', () {
      expect(isZero('0'), isTrue);
      expect(isZero('0.000'), isTrue);
      expect(isZero('1'), isFalse);
      expect(isZero(null), isFalse);
    });

    test('isPositive', () {
      expect(isPositive('1'), isTrue);
      expect(isPositive('0.5'), isTrue);
      expect(isPositive('0'), isFalse);
      expect(isPositive('-1'), isFalse);
      expect(isPositive(null), isFalse);
    });

    test('isNegative', () {
      expect(isNegative('-1'), isTrue);
      expect(isNegative('0'), isFalse);
      expect(isNegative('1'), isFalse);
    });
  });

  group('toNumber', () {
    test('returns double for numeric', () {
      expect(toNumber('1.5'), 1.5);
      expect(toNumber('1'), 1.0);
    });

    test('returns 0 for invalid', () {
      expect(toNumber('abc'), 0);
      expect(toNumber(null), 0);
    });
  });
}
