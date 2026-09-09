import 'dart:math' as math;

import '../core/story_constants.dart';

/// Parses a USDC amount string from API digests / configs.
///
/// Supports both human amounts (`"1"`, `"1.5"`) and integer minor units
/// (`"1000000"` for 1 USDC with 6 decimals). Returns null when unparsable.
double? parseUsdcAmount(String? raw, {int decimals = 6}) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final value = double.tryParse(trimmed);
  if (value == null || !value.isFinite || value < 0) return null;

  // Large integer-looking values are treated as token minor units.
  final looksLikeMinorUnits =
      value >= 1000 && !trimmed.contains('.') && value == value.roundToDouble();
  if (looksLikeMinorUnits) {
    return value / math.pow(10, decimals);
  }
  return value;
}

/// Resolves mint/issue fee from digest [feeAmount], falling back to
/// [StoryConstants.defaultMintFeeUsdc].
double resolveMintFeeUsdc(
  String? feeAmount, {
  double fallbackUsdc = StoryConstants.defaultMintFeeUsdc,
}) {
  return parseUsdcAmount(feeAmount) ?? fallbackUsdc;
}

/// Resolves actor-sign charge from mint digest, preferring slippage-inclusive
/// total then plain total, then [fallbackUsdc].
double resolveActorSignChargeUsdc({
  double? totalPriceWithSlippage,
  double? totalPrice,
  double? fallbackUsdc,
}) {
  return totalPriceWithSlippage ?? totalPrice ?? fallbackUsdc ?? 0;
}
