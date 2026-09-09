/// Pricing mode for actor IP collections.
///
/// Aligned with web `PrepareActorCollectionRequestPricingMode`.
enum ActorCollectionPricingMode {
  fixed('FIXED'),
  bondingCurve('BONDING_CURVE');

  const ActorCollectionPricingMode(this.apiValue);
  final String apiValue;

  static ActorCollectionPricingMode? fromApiValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final mode in ActorCollectionPricingMode.values) {
      if (mode.apiValue == value) return mode;
    }
    return null;
  }
}
