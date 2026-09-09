/// Minimal ERC-20 calldata helpers (no web3 package dependency).
String stripHexPrefix(String value) {
  if (value.startsWith('0x') || value.startsWith('0X')) {
    return value.substring(2);
  }
  return value;
}

String encodeBalanceOf(String ownerAddress) {
  final owner = stripHexPrefix(ownerAddress).toLowerCase().padLeft(64, '0');
  return '0x70a08231$owner';
}

String encodeErc20Transfer(String toAddress, BigInt amount) {
  final to = stripHexPrefix(toAddress).toLowerCase().padLeft(64, '0');
  final value = amount.toRadixString(16).padLeft(64, '0');
  return '0xa9059cbb$to$value';
}

/// Parses a human-readable token amount into the on-chain integer.
BigInt parseTokenAmount(String amountStr, int decimals) {
  final trimmed = amountStr.trim();
  if (trimmed.isEmpty) return BigInt.zero;
  final negative = trimmed.startsWith('-');
  final unsigned = negative ? trimmed.substring(1) : trimmed;
  final parts = unsigned.split('.');
  final whole = parts.first.isEmpty ? '0' : parts.first;
  var frac = parts.length > 1 ? parts[1] : '';
  if (frac.length > decimals) {
    frac = frac.substring(0, decimals);
  } else {
    frac = frac.padRight(decimals, '0');
  }
  final raw = BigInt.parse('$whole$frac');
  return negative ? -raw : raw;
}

double? decodeTokenBalance(String hexResult, int decimals) {
  final hex = stripHexPrefix(hexResult);
  if (hex.isEmpty) return 0;
  final raw = BigInt.parse(hex, radix: 16);
  if (decimals <= 0) return raw.toDouble();
  final divisor = BigInt.from(10).pow(decimals);
  final whole = raw ~/ divisor;
  final frac = raw.remainder(divisor).abs();
  final fracStr = frac.toString().padLeft(decimals, '0');
  return double.parse('$whole.$fracStr');
}
