import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../l10n/app_localizations.dart';
import '../model/actor_collection_pricing_mode.dart';
import 'format_number.dart';

/// Bonding curve base multiplier, aligned with web `ACTOR_BONDING_CURVE_BASE`.
const actorBondingCurveBase = 5;

ActorCollectionPricingMode normalizeActorPricingMode(String? pricingMode) {
  if (pricingMode == ActorCollectionPricingMode.fixed.apiValue) {
    return ActorCollectionPricingMode.fixed;
  }
  return ActorCollectionPricingMode.bondingCurve;
}

bool isFixedActorPricingMode(String? pricingMode) =>
    normalizeActorPricingMode(pricingMode) == ActorCollectionPricingMode.fixed;

const _actorNftTokenStandardLabels = <String, String>{
  'CORE_ASSET': 'Core Asset',
  'CORE_COLLECTION': 'Core Collection',
};

/// Actor IP short label, aligned with web `formatActorIpDisplay`.
String formatActorIpDisplay(String? actorId) {
  final text = actorId?.trim();
  if (text == null || text.isEmpty) return '-';
  if (text.length <= 8) return text;
  return '${text.substring(0, 4)}...${text.substring(text.length - 4)}';
}

/// NFT contract short label, aligned with web `formatActorNftLabel`.
///
/// Format: localized `RoleNFT#` / `角色NFT#` + first 8 chars of mint address.
String formatActorNftLabel(AppLocalizations l10n, String? nftContractAddress) {
  final prefix = nftContractAddress?.trim();
  if (prefix == null || prefix.isEmpty) return l10n.roleNftLabelUnknown;
  final head = prefix.length <= 8 ? prefix : prefix.substring(0, 8);
  return l10n.roleNftLabel(head);
}

/// Token standard display, aligned with web `formatActorNftTokenStandard`.
String formatActorNftTokenStandard(String? nftTokenStandard) {
  final raw = nftTokenStandard?.trim();
  if (raw == null || raw.isEmpty) return '-';
  return _actorNftTokenStandardLabels[raw] ?? raw;
}

String actorPricingModeLabel(AppLocalizations l10n, String? pricingMode) =>
    isFixedActorPricingMode(pricingMode)
    ? l10n.actorPricingFixed
    : l10n.actorPricingCurve;

/// Price display with 2-decimal round-up, aligned with web
/// `formatActorPriceCeilDisplay`.
///
/// Uses [Decimal] (not `* 100` + [num.ceil]) so values like `1.1` do not
/// become `1.11` from IEEE float noise (`1.1 * 100 == 110.00000000000001`).
String formatActorPriceCeilDisplay(double priceUsdc) {
  if (!priceUsdc.isFinite || priceUsdc <= 0) return '0';
  final roundedUp = Decimal.parse(priceUsdc.toString()).ceil(scale: 2);
  return formatNumber(roundedUp);
}

/// Vault amount label without suffix, aligned with web
/// `ActorDetailIssueSection.formatVaultAmountDisplay`.
///
/// - loading / empty / invalid → `--`
/// - amount `< 0.01` → `0`
/// - otherwise → ROUND_DOWN to 2 decimals, fixed 2 places (e.g. `1.20`)
String formatActorVaultAmountDisplay({
  required String? vaultAmountRaw,
  required bool isLoading,
}) {
  if (isLoading) return '--';

  final text = vaultAmountRaw?.trim();
  if (text == null || text.isEmpty) return '--';

  try {
    final amount = Decimal.parse(text);
    if (amount < Decimal.parse('0.01')) return '0';
    return amount.truncate(scale: 2).toStringAsFixed(2);
  } catch (_) {
    return '--';
  }
}

/// Secondary-market floor price, aligned with web `resolveActorFloorPriceUsdc`.
double? resolveActorFloorPriceUsdc({
  double? floorPriceUsdc,
  double? floorPrice,
  double? lowestListingPriceUsdc,
}) {
  for (final value in [floorPriceUsdc, floorPrice, lowestListingPriceUsdc]) {
    if (value != null && value.isFinite && value > 0) return value;
  }
  return null;
}

/// Floor price label, aligned with web `formatActorFloorPriceDisplay`.
String formatActorFloorPriceDisplay(
  double? floorPriceUsdc, [
  String currency = 'USDC',
]) {
  if (floorPriceUsdc == null || floorPriceUsdc <= 0) return '--';
  return '${formatNumber(floorPriceUsdc)} $currency';
}

double _truncateActorPrice(double price) =>
    (price * 1000000).truncateToDouble() / 1000000;

/// Bonding curve price, aligned with web `getActorBondingCurvePrice`.
double getActorBondingCurvePrice(
  double initialPrice,
  int signedCount,
  int maxSupply,
) {
  if (initialPrice <= 0 || maxSupply <= 0) return 0;

  final normalizedSignedCount = math.min(math.max(0, signedCount), maxSupply);
  final stepMultiplier = math.pow(actorBondingCurveBase, 1 / maxSupply);
  var price = initialPrice;
  for (var index = 0; index < normalizedSignedCount; index++) {
    price = _truncateActorPrice(price * stepMultiplier);
  }
  return price;
}

/// Sold-out curve price, aligned with web `getActorBondingCurveTailPrice`.
double getActorBondingCurveTailPrice(double initialPrice, int maxSupply) =>
    getActorBondingCurvePrice(
      initialPrice,
      math.max(0, maxSupply - 1),
      maxSupply,
    );

/// Display price for actor cards / sign sheet, aligned with web
/// `resolveActorDisplayCurrentPrice`.
double resolveActorDisplayCurrentPrice({
  required String? pricingMode,
  required double initialPrice,
  double? currentPrice,
  required int signedCount,
  required int maxSupply,
}) {
  if (currentPrice != null && currentPrice > 0) return currentPrice;
  if (isFixedActorPricingMode(pricingMode)) return initialPrice;
  return getActorBondingCurvePrice(initialPrice, signedCount, maxSupply);
}
