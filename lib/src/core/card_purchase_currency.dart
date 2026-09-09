/// Card-purchase currency presentation. This never changes the API or
/// on-chain payment currency, which remains USDC.
enum CardPurchaseCurrencyMode {
  points,
  usdc;

  String label({required String pointsLabel}) => switch (this) {
    CardPurchaseCurrencyMode.points => pointsLabel,
    CardPurchaseCurrencyMode.usdc => 'USDC',
  };
}

abstract final class CardPurchaseCurrencyDisplay {
  /// Set `--dart-define=CARD_PURCHASE_USE_USDC=true` to switch the purchase
  /// sheets back to the USDC label and icon in one place.
  static const bool useUsdc = bool.fromEnvironment(
    'CARD_PURCHASE_USE_USDC',
  );

  static const CardPurchaseCurrencyMode mode = useUsdc
      ? CardPurchaseCurrencyMode.usdc
      : CardPurchaseCurrencyMode.points;
}
