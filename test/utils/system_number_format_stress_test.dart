import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/utils/system_number_format.dart';

void main() {
  final format = SystemNumberFormat.instance;
  tearDown(() => format.debugOverride());

  TextEditingValue apply(
    String oldText,
    String newText, {
    int? oldSel,
    int? newSel,
  }) {
    final formatter = SystemDecimalTextInputFormatter(maxFractionDigits: 2);
    return formatter.formatEditUpdate(
      TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldSel ?? oldText.length),
      ),
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newSel ?? newText.length),
      ),
    );
  }

  test('US: paste EU 1.234,56 must be 1234.56 not 1.23456', () {
    format.debugOverride(decimalSeparator: '.', groupingSeparator: ',');
    expect(format.parseDecimal('1.234,56'), 1234.56);
    expect(apply('', '1.234,56').text, '1,234.56');
  });

  test('EU: paste US 1,234.56 must be 1234.56 not 1.23456', () {
    format.debugOverride(decimalSeparator: ',', groupingSeparator: '.');
    expect(format.parseDecimal('1,234.56'), 1234.56);
    expect(apply('', '1,234.56').text, '1.234,56');
  });

  test('leading zeros collapse', () {
    format.debugOverride(decimalSeparator: '.', groupingSeparator: ',');
    expect(apply('0', '01').text, '1');
    expect(apply('', '0').text, '0');
    expect(apply('0', '0.').text, '0.');
  });

  test('space grouping format', () {
    format.debugOverride(decimalSeparator: '.', groupingSeparator: ' ');
    expect(apply('12345', '123456').text, '123 456');
    expect(format.parseDecimal('123 456.78'), 123456.78);
  });

  test('deleting digit from grouped integer does not become decimal', () {
    format.debugOverride(decimalSeparator: '.', groupingSeparator: ',');
    // 1,234 → delete last digit → 1,23 → must become 123, not 1.23
    final r = apply('1,234', '1,23', oldSel: 5, newSel: 4);
    expect(r.text, '123');
    expect(format.parseDecimal(r.text), 123);
  });

  test('backspace decimal leaves integer grouped', () {
    format.debugOverride(decimalSeparator: '.', groupingSeparator: ',');
    final r = apply('123,456.', '123,456', oldSel: 8, newSel: 7);
    expect(r.text, '123,456');
    expect(r.selection.baseOffset, 7);
  });

  test('keeps caret after decimal when typing decimal mark', () {
    format.debugOverride(decimalSeparator: '.', groupingSeparator: ',');
    final r = apply('123,456', '123,456.');
    expect(r.text, '123,456.');
    expect(r.selection.baseOffset, 8);
  });
}
