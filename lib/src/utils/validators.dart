final _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
);

bool isValidEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return false;
  return _emailRegex.hasMatch(trimmed);
}

bool isValidSolanaAddress(String address) {
  final trimmed = address.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.length < 32 || trimmed.length > 44) return false;
  return RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$').hasMatch(trimmed);
}

bool isValidEthereumAddress(String address) {
  final trimmed = address.trim();
  return RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(trimmed);
}

String truncateAddress(String address, {int prefixLen = 6, int suffixLen = 4}) {
  if (address.length <= prefixLen + suffixLen) return address;
  return '${address.substring(0, prefixLen)}...${address.substring(address.length - suffixLen)}';
}

/// Pulls a wallet address out of raw QR / paste content.
///
/// Handles bare addresses and common URI schemes (`solana:`, `ethereum:` /
/// EIP-681). Prefers a match for [preferEvm]; falls back to the other family
/// so the caller can still show an inline chain-mismatch error.
String? parseWalletAddressFromScan(String raw, {required bool preferEvm}) {
  var text = raw.trim();
  if (text.isEmpty) return null;

  // Strip zero-width / BOM noise from some wallet apps.
  text = text.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

  final lower = text.toLowerCase();
  if (lower.startsWith('solana:')) {
    text = text.substring('solana:'.length);
    final q = text.indexOf('?');
    if (q >= 0) text = text.substring(0, q);
    text = text.trim();
  } else if (lower.startsWith('ethereum:')) {
    text = text.substring('ethereum:'.length);
    // ethereum:0xabc…@1?value=…  or  ethereum:pay-0x…
    if (text.toLowerCase().startsWith('pay-')) {
      text = text.substring(4);
    }
    final at = text.indexOf('@');
    final q = text.indexOf('?');
    var end = text.length;
    if (at >= 0) end = at;
    if (q >= 0 && q < end) end = q;
    text = text.substring(0, end).trim();
  }

  String? evm;
  if (isValidEthereumAddress(text)) {
    evm = text;
  } else {
    final match = RegExp(r'0x[0-9a-fA-F]{40}').firstMatch(text);
    if (match != null) evm = match.group(0);
  }

  String? svm;
  if (isValidSolanaAddress(text)) {
    svm = text;
  } else {
    // Avoid matching inside longer URI leftovers; only accept a clean token.
    final match = RegExp(r'[1-9A-HJ-NP-Za-km-z]{32,44}').firstMatch(text);
    if (match != null && isValidSolanaAddress(match.group(0)!)) {
      svm = match.group(0);
    }
  }

  if (preferEvm) {
    return evm ?? svm;
  }
  return svm ?? evm;
}
