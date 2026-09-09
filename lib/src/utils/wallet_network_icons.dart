/// Local SVG icons for known deposit/withdraw networks.
///
/// Matched by substring against chain key / name (e.g. `arbitrum-sepolia`).
const kWalletNetworkAssetIcons = <String, String>{
  'arbitrum': 'assets/common/arbitrum-one.svg',
  'bsc': 'assets/common/binance-smart-chain.svg',
  'binance': 'assets/common/binance-smart-chain.svg',
  'ethereum': 'assets/common/eth.svg',
};

/// Resolves a local network icon asset from [chainKey] / [chainName].
String? resolveWalletNetworkAssetIcon(String chainKey, {String? chainName}) {
  final hay = '$chainKey ${chainName ?? ''}'.toLowerCase();
  for (final entry in kWalletNetworkAssetIcons.entries) {
    if (hay.contains(entry.key)) return entry.value;
  }
  return null;
}
