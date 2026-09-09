import '../core/result.dart';

/// Asset that can be spent from the on-chain wallet ledger.
enum SpendAsset { usdc, story }

/// Authoritative spend request. [softEstimate] is an optional early gate
/// (e.g. display price / default mint fee) before [amount] is known or when
/// both are provided in one shot.
class SpendQuote {
  final SpendAsset asset;
  final double amount;
  final double? softEstimate;
  final String reason;

  const SpendQuote({
    required this.asset,
    required this.amount,
    this.softEstimate,
    required this.reason,
  });
}

/// Opaque handle returned by [WalletLedger.prepareSpend].
class SpendTicket {
  final SpendAsset asset;
  final double amount;
  final String reason;
  final bool didDeduct;

  const SpendTicket({
    required this.asset,
    required this.amount,
    required this.reason,
    required this.didDeduct,
  });
}

/// Minimal surface the ledger needs from [WalletBalanceNotifier].
/// Kept as a typedef/callback set so this file does not import providers
/// (avoids circular imports with [walletLedgerProvider]).
class WalletSpendPort {
  final Future<Result<void>> Function(double required) ensureUsdc;
  final Future<Result<void>> Function(double required) ensureStory;
  final void Function({double usdc, double story}) deduct;
  final Future<void> Function() refresh;

  const WalletSpendPort({
    required this.ensureUsdc,
    required this.ensureStory,
    required this.deduct,
    required this.refresh,
  });
}

/// Orchestrates on-chain spendable balance checks and optimistic deducts.
///
/// Call sites should not hand-roll `ensure → deduct → refresh`; go through
/// [prepareSpend] then [commitSpend] / [reconcile].
///
/// Claimable platform balances ([IncomeController] / `/assets`) stay outside
/// this ledger.
class WalletLedger {
  WalletLedger(this._port);

  final WalletSpendPort _port;

  /// Soft affordability check without deducting (digest/order not ready yet).
  Future<Result<void>> ensureAffordable(SpendAsset asset, double amount) {
    if (amount <= 0) return Future.value(Result.success(null));
    return switch (asset) {
      SpendAsset.usdc => _port.ensureUsdc(amount),
      SpendAsset.story => _port.ensureStory(amount),
    };
  }

  /// Ensures coverage (optional [SpendQuote.softEstimate] first), then
  /// optimistically deducts [SpendQuote.amount].
  Future<Result<SpendTicket>> prepareSpend(SpendQuote quote) async {
    final soft = quote.softEstimate;
    if (soft != null && soft > 0) {
      // Skip duplicate ensure when soft equals the authoritative amount.
      final skipSoft = quote.amount > 0 && (soft - quote.amount).abs() < 1e-9;
      if (!skipSoft) {
        final softGate = await ensureAffordable(quote.asset, soft);
        if (softGate.isFailure) {
          return Result.failure(softGate.errorOrNull!);
        }
      }
    }

    if (quote.amount <= 0) {
      return Result.success(
        SpendTicket(
          asset: quote.asset,
          amount: 0,
          reason: quote.reason,
          didDeduct: false,
        ),
      );
    }

    final gate = await ensureAffordable(quote.asset, quote.amount);
    if (gate.isFailure) {
      return Result.failure(gate.errorOrNull!);
    }

    switch (quote.asset) {
      case SpendAsset.usdc:
        _port.deduct(usdc: quote.amount, story: 0);
      case SpendAsset.story:
        _port.deduct(usdc: 0, story: quote.amount);
    }

    return Result.success(
      SpendTicket(
        asset: quote.asset,
        amount: quote.amount,
        reason: quote.reason,
        didDeduct: true,
      ),
    );
  }

  /// Success path: refresh to reconcile optimistic deduct with chain truth.
  Future<void> commitSpend(SpendTicket ticket) => reconcile(ticket);

  /// Failure / dispose path: refresh to restore authoritative balances.
  Future<void> reconcile([SpendTicket? ticket]) => _port.refresh();

  Future<void> refresh() => _port.refresh();
}
