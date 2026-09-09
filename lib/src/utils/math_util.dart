import 'package:decimal/decimal.dart';

/// 精确十进制算术工具，与 web 端 `src/utils/mathUtil.ts` (decimal.js) 行为对齐。
///
/// 所有算术函数返回字符串；比较函数返回 bool；[toNumber] 返回 double 仅供 UI 数值比较。

bool isNumeric(dynamic value) {
  if (value == null) return false;
  final s = value.toString().trim();
  if (s.isEmpty) return false;
  final parsed = double.tryParse(s);
  if (parsed == null) return false;
  return parsed.isFinite && !parsed.isNaN;
}

Decimal _toDec(dynamic value) {
  if (value is Decimal) return value;
  if (value is num) return Decimal.parse(value.toString());
  return Decimal.parse(value.toString());
}

String plus(dynamic v1, dynamic v2) {
  if (!isNumeric(v1) || !isNumeric(v2)) return '0';
  return (_toDec(v1) + _toDec(v2)).toString();
}

String minus(dynamic v1, dynamic v2) {
  if (!isNumeric(v1) || !isNumeric(v2)) return '0';
  return (_toDec(v1) - _toDec(v2)).toString();
}

String multipliedBy(dynamic v1, dynamic v2) {
  if (!isNumeric(v1) || !isNumeric(v2)) return '0';
  return (_toDec(v1) * _toDec(v2)).toString();
}

String div(dynamic v1, dynamic v2) {
  if (!isNumeric(v1) || !isNumeric(v2)) return '0';
  final divisor = _toDec(v2);
  if (divisor == Decimal.zero) return '0';
  final rational = _toDec(v1) / divisor;
  if (rational.hasFinitePrecision) {
    return rational.toDecimal().toString();
  }
  return rational.toDecimal(scaleOnInfinitePrecision: 20).toString();
}

String absValue(dynamic value) {
  if (!isNumeric(value)) return '0';
  return _toDec(value).abs().toString();
}

String neg(dynamic value) {
  if (!isNumeric(value)) return '0';
  return (-_toDec(value)).toString();
}

String trunc(dynamic value) {
  if (!isNumeric(value)) return '0';
  return _toDec(value).truncate().toString();
}

String mod(dynamic v1, dynamic v2) {
  if (!isNumeric(v1) || !isNumeric(v2)) return '0';
  final divisor = _toDec(v2);
  if (divisor == Decimal.zero) return '0';
  return _toDec(v1).remainder(divisor).toString();
}

double toNumber(dynamic value) {
  if (!isNumeric(value)) return 0;
  return _toDec(value).toDouble();
}

bool isGreaterThan(dynamic v1, dynamic v2) {
  if (!isNumeric(v1) || !isNumeric(v2)) return false;
  return _toDec(v1) > _toDec(v2);
}

bool isGreaterThanOrEqual(dynamic v1, dynamic v2) {
  if (!isNumeric(v1) || !isNumeric(v2)) return false;
  return _toDec(v1) >= _toDec(v2);
}

bool isLessThan(dynamic v1, dynamic v2) {
  if (!isNumeric(v1) || !isNumeric(v2)) return false;
  return _toDec(v1) < _toDec(v2);
}

bool isLessThanOrEqualTo(dynamic v1, dynamic v2) {
  if (!isNumeric(v1) || !isNumeric(v2)) return false;
  return _toDec(v1) <= _toDec(v2);
}

bool isEqualTo(dynamic v1, dynamic v2) {
  if (!isNumeric(v1) || !isNumeric(v2)) return false;
  return _toDec(v1) == _toDec(v2);
}

bool isZero(dynamic value) {
  if (value == null) return false;
  if (!isNumeric(value)) return false;
  return _toDec(value) == Decimal.zero;
}

bool isPositive(dynamic value) {
  if (value == null) return false;
  if (!isNumeric(value)) return false;
  return _toDec(value) > Decimal.zero;
}

bool isNegative(dynamic value) {
  if (value == null) return false;
  if (!isNumeric(value)) return false;
  return _toDec(value) < Decimal.zero;
}
