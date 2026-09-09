import 'package:equatable/equatable.dart';

import 'json_converters.dart';

/// Shared STORY/h for banner, theater cards, and the recommend actor rail.
///
/// Display order: [storyPerHour] → [unitPrice] → [computingPower].
/// A placeholder `0` is skipped so a real fallback can show; if every source
/// is missing or zero, an explicit `0` is kept so the UI can still paint it.
class ActorHourlyRate extends Equatable {
  final num? storyPerHour;
  final double? unitPrice;
  final double? computingPower;

  const ActorHourlyRate({
    this.storyPerHour,
    this.unitPrice,
    this.computingPower,
  });

  static const none = ActorHourlyRate();

  /// Resolved value for STORY/h UI. Null only when every source is missing.
  num? get value => _prefer(storyPerHour, _prefer(unitPrice, computingPower));

  /// IP 片酬 in STORY/h. Skips [unitPrice] (NFT list price, often USDC).
  num? get payValue => _prefer(storyPerHour, computingPower);

  ActorHourlyRate overlay(ActorHourlyRate? fallback) {
    if (fallback == null) return this;
    return ActorHourlyRate(
      storyPerHour: _prefer(storyPerHour, fallback.storyPerHour),
      unitPrice: _prefer(unitPrice, fallback.unitPrice)?.toDouble(),
      computingPower: _prefer(
        computingPower,
        fallback.computingPower,
      )?.toDouble(),
    );
  }

  /// Reads flat fields, nested `nft`, and `boundActorCollection`.
  factory ActorHourlyRate.fromJson(Map<String, dynamic>? json) {
    if (json == null) return none;
    final bound = _asMap(json['boundActorCollection'] ?? json['boundActor']);
    final nft = _asMap(json['nft']) ?? _asMap(bound?['nft']);
    return ActorHourlyRate(
      storyPerHour:
          asDouble(json['storyPerHour']) ?? asDouble(bound?['storyPerHour']),
      unitPrice:
          asDouble(json['unitPrice']) ??
          asDouble(nft?['unitPrice']) ??
          asDouble(bound?['unitPrice']),
      computingPower:
          asDouble(json['computingPower']) ??
          asDouble(bound?['computingPower']) ??
          asDouble(nft?['computingPower']),
    );
  }

  /// Thousands grouping (`6,344`); fractions keep up to 2 decimals (`0.01`).
  /// Values below `0.01` (but not zero) display as `< 0.01`.
  static String? format(num? value) {
    if (value == null) return null;
    if (value != 0 && value.abs() < 0.01) return '< 0.01';
    final negative = value < 0;
    final absVal = value.abs();
    final whole = absVal.truncate();
    final grouped = _groupThousands(whole);
    final String body;
    if (absVal == whole) {
      body = grouped;
    } else {
      var frac = (absVal - whole).toStringAsFixed(2);
      frac = frac.substring(frac.indexOf('.'));
      frac = frac.replaceFirst(RegExp(r'0+$'), '');
      if (frac == '.') frac = '';
      body = '$grouped$frac';
    }
    return negative ? '-$body' : body;
  }

  /// Prefer a non-zero [a], else a non-zero [b], else an explicit `0`.
  static num? _prefer(num? a, num? b) {
    if (a != null && a != 0) return a;
    if (b != null && b != 0) return b;
    return a ?? b;
  }

  static String _groupThousands(int n) {
    final digits = n.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    return null;
  }

  @override
  List<Object?> get props => [storyPerHour, unitPrice, computingPower];
}
