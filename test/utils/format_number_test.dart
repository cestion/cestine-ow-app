import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/utils/format_number.dart';

void main() {
  group('formatNumber', () {
    test('empty / null returns "-"', () {
      expect(formatNumber(null), '-');
      expect(formatNumber(''), '-');
      expect(formatNumber('   '), '-');
    });

    test('zero returns "0"', () {
      expect(formatNumber(0), '0');
      expect(formatNumber('0'), '0');
      expect(formatNumber('0.000'), '0');
    });

    test('default precision 2 with ROUND_DOWN', () {
      expect(formatNumber('123456.789'), '123,456.78');
      expect(formatNumber('0.999'), '0.99');
      expect(formatNumber('1.005'), '1');
    });

    test('removes trailing zeros after decimal', () {
      expect(formatNumber('100.00'), '100');
      expect(formatNumber('100.10'), '100.1');
      expect(formatNumber('100.500'), '100.5');
    });

    test('threshold "<0.01" for tiny values', () {
      expect(formatNumber('0.005'), '<0.01');
      expect(formatNumber('0.001'), '<0.01');
      expect(formatNumber('0.0001'), '<0.01');
    });

    test('does NOT trigger threshold when value equals threshold', () {
      expect(formatNumber('0.01'), '0.01');
    });

    test('thousand separators on integer part', () {
      expect(formatNumber('1234567.89'), '1,234,567.89');
      expect(formatNumber('1000000'), '1,000,000');
      expect(formatNumber('999'), '999');
    });

    test('custom precision', () {
      expect(formatNumber('1.23456', 4), '1.2345');
      expect(formatNumber('1.23456', 0), '1');
      expect(formatNumber('0.0001', 4), '0.0001');
      expect(formatNumber('0.00001', 4), '<0.0001');
    });

    test('isRound=true uses HALF_EVEN rounding', () {
      expect(formatNumber('1.005', 2, true), '1');
      expect(formatNumber('1.015', 2, true), '1.02');
      expect(formatNumber('0.999', 2, true), '1');
    });

    test('accepts numeric types and strings', () {
      expect(formatNumber(123.456), '123.45');
      expect(formatNumber(0), '0');
      expect(formatNumber(0.005), '<0.01');
    });

    test('invalid input returns "-"', () {
      expect(formatNumber('abc'), '-');
      expect(formatNumber('NaN'), '-');
    });
  });

  group('formatStoryAmount', () {
    test('returns null for null/empty', () {
      expect(formatStoryAmount(null), isNull);
      expect(formatStoryAmount(''), isNull);
      expect(formatStoryAmount('   '), isNull);
    });

    test('returns formatted with STORY suffix', () {
      expect(formatStoryAmount('1234.567'), '1,234.56 STORY');
      expect(formatStoryAmount('0.005'), '<0.01 STORY');
    });

    test('returns null for invalid', () {
      expect(formatStoryAmount('abc'), isNull);
    });
  });
}
