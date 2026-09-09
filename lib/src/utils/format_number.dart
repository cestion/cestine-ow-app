import 'package:decimal/decimal.dart';

import 'math_util.dart';

/// 数字格式化工具，与 web 端 `src/utils/formatNumber.ts` 行为完全对齐。
///
/// 规则：
/// - 空值返回 '-'
/// - 零值返回 '0'
/// - 默认精度 2，默认向下取整（ROUND_DOWN）；[isRound]=true 时四舍六入五成双
/// - 去除小数末尾的 0
/// - 原始值小于 10^-precision 时显示 `<0.01` 形式
/// - 整数部分加千分位分隔符

enum _RoundingMode { down, halfEven }

String _applyRounding(Decimal value, int precision, _RoundingMode mode) {
  switch (mode) {
    case _RoundingMode.down:
      return value.truncate(scale: precision).toString();
    case _RoundingMode.halfEven:
      return _roundHalfEven(value, precision).toString();
  }
}

Decimal _roundHalfEven(Decimal value, int precision) {
  if (precision == 0) {
    final intPart = value.truncate();
    final frac = value - intPart;
    final absFrac = frac.abs();
    final half = Decimal.parse('0.5');
    if (absFrac < half) return intPart;
    if (absFrac > half) {
      return value < Decimal.zero
          ? intPart - Decimal.one
          : intPart + Decimal.one;
    }
    final bigInt = intPart.toBigInt();
    if (bigInt.isEven) return intPart;
    return value < Decimal.zero ? intPart - Decimal.one : intPart + Decimal.one;
  }
  final scaleFactor = _tenPow(precision);
  final scaled = value * scaleFactor;
  final intPart = scaled.truncate();
  final frac = scaled - intPart;
  final absFrac = frac.abs();
  final half = Decimal.parse('0.5');
  Decimal roundedInt;
  if (absFrac < half) {
    roundedInt = intPart;
  } else if (absFrac > half) {
    roundedInt = value < Decimal.zero
        ? intPart - Decimal.one
        : intPart + Decimal.one;
  } else {
    final bigInt = intPart.toBigInt();
    if (bigInt.isEven) {
      roundedInt = intPart;
    } else {
      roundedInt = value < Decimal.zero
          ? intPart - Decimal.one
          : intPart + Decimal.one;
    }
  }
  final rational = roundedInt / scaleFactor;
  if (rational.hasFinitePrecision) {
    return rational.toDecimal();
  }
  return rational.toDecimal(scaleOnInfinitePrecision: precision);
}

String _insertThousandSeparators(String n) {
  final dot = n.indexOf('.');
  final intPart = dot < 0 ? n : n.substring(0, dot);
  final decPart = dot < 0 ? '' : n.substring(dot);

  final isNeg = intPart.startsWith('-');
  final digits = isNeg ? intPart.substring(1) : intPart;
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buf.write(',');
    }
    buf.write(digits[i]);
  }
  return (isNeg ? '-' : '') + buf.toString() + decPart;
}

Decimal _tenPow(int p) => Decimal.parse('1${'0' * p}');

String formatNumber(dynamic value, [int precision = 2, bool isRound = false]) {
  final s = value?.toString();
  if (s == null || s.trim().isEmpty) return '-';
  if (!isNumeric(s)) return '-';
  if (isEqualTo(s, '0')) return '0';

  final p = precision < 0 ? 0 : precision;
  final original = Decimal.parse(s);
  final rounded = _applyRounding(
    original,
    p,
    isRound ? _RoundingMode.halfEven : _RoundingMode.down,
  );
  var n = rounded;
  final dotPos = n.indexOf('.');
  if (dotPos >= 0) {
    n = n.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  final threshold = Decimal.one / _tenPow(p);
  final thresholdDecimal = threshold.hasFinitePrecision
      ? threshold.toDecimal()
      : threshold.toDecimal(scaleOnInfinitePrecision: 20);
  if (original.abs().compareTo(thresholdDecimal) < 0) {
    return '<${thresholdDecimal.toStringAsFixed(p)}';
  }

  return _insertThousandSeparators(n);
}

/// 与 web `formatMiningStoryAmount` 对齐：formatNumber(amount, 2) + ' STORY'
String? formatStoryAmount(dynamic amount) {
  final s = amount?.toString();
  if (s == null || s.trim().isEmpty) return null;
  final formatted = formatNumber(s);
  if (formatted == '-') return null;
  return '$formatted STORY';
}

/// 热度值展示（剧集卡片等）：无小数位；>=1 万缩写为整数 `w`。
/// 空值 / 非数字返回 null。
String? formatHeatValue(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  final n = double.tryParse(s);
  if (n == null || !n.isFinite) return null;
  final rounded = n.round();
  if (rounded >= 10000) {
    return '${(rounded / 10000).round()}w';
  }
  return rounded.toString();
}
