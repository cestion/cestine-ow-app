import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/common/story_toast.dart';
import '../l10n/story_l10n.dart';
import '../provider/wallet_providers.dart';
import '../services/wallet_ledger.dart';
import '../components/common/insufficient_balance_dialog.dart';

/// Soft affordability check (no deduct). Shows toast and returns false on fail.
Future<bool> ensureUsdcBalance(
  WidgetRef ref,
  BuildContext context,
  double required, {
  String? insufficientMessage,
}) async {
  if (required <= 0) return true;
  final result = await ref
      .read(walletLedgerProvider)
      .ensureAffordable(SpendAsset.usdc, required);
  if (!context.mounted) return false;
  if (result.isFailure) {
    StoryToast.error(
      context,
      insufficientMessage ?? context.l10nError(result.errorOrNull!),
    );
    return false;
  }
  return true;
}

/// Soft affordability check (no deduct) that pops the
/// [InsufficientBalanceDialog] instead of a toast when the balance is
/// insufficient.
///
/// The dialog's `amount` is the shortfall (`required - available`) passed
/// without rounding; `currency` defaults to the channel currency
/// (官网包 USDC / 商店包点数). Returns `false` after the dialog is shown so
/// the caller aborts the action.
Future<bool> ensureUsdcBalanceOrShowDialog(
  WidgetRef ref,
  BuildContext context,
  double required, {
  String? currency,
}) async {
  if (required <= 0) return true;
  final result = await ref
      .read(walletLedgerProvider)
      .ensureAffordable(SpendAsset.usdc, required);
  if (!context.mounted) return false;
  if (result.isFailure) {
    final shortfall =
        required - ref.read(onChainWalletBalanceProvider).usdcBalance;
    await InsufficientBalanceDialog.show(
      context: context,
      currency: currency ?? context.l10n.currency,
      amount: _formatBalance(shortfall),
      ref: ref,
    );
    return false;
  }
  return true;
}

String _formatBalance(double value) {
  final s = value.toStringAsFixed(6);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Soft affordability check for STORY (no deduct).
Future<bool> ensureStoryBalance(
  WidgetRef ref,
  BuildContext context,
  double required, {
  String? insufficientMessage,
}) async {
  if (required <= 0) return true;
  final result = await ref
      .read(walletLedgerProvider)
      .ensureAffordable(SpendAsset.story, required);
  if (!context.mounted) return false;
  if (result.isFailure) {
    StoryToast.error(
      context,
      insufficientMessage ?? context.l10nError(result.errorOrNull!),
    );
    return false;
  }
  return true;
}

/// Ensures + optimistic deduct. Returns ticket on success, null after toast.
///
/// Call [WalletLedger.commitSpend] on chain success or
/// [WalletLedger.reconcile] on failure.
Future<SpendTicket?> prepareUsdcSpend(
  WidgetRef ref,
  BuildContext context,
  double amount, {
  required String reason,
  double? softEstimate,
  String? insufficientMessage,
}) async {
  final result = await ref
      .read(walletLedgerProvider)
      .prepareSpend(
        SpendQuote(
          asset: SpendAsset.usdc,
          amount: amount,
          softEstimate: softEstimate,
          reason: reason,
        ),
      );
  if (!context.mounted) return null;
  if (result.isFailure) {
    StoryToast.error(
      context,
      insufficientMessage ?? context.l10nError(result.errorOrNull!),
    );
    return null;
  }
  return result.dataOrNull;
}

/// Same as [prepareUsdcSpend] for STORY.
Future<SpendTicket?> prepareStorySpend(
  WidgetRef ref,
  BuildContext context,
  double amount, {
  required String reason,
  double? softEstimate,
  String? insufficientMessage,
}) async {
  final result = await ref
      .read(walletLedgerProvider)
      .prepareSpend(
        SpendQuote(
          asset: SpendAsset.story,
          amount: amount,
          softEstimate: softEstimate,
          reason: reason,
        ),
      );
  if (!context.mounted) return null;
  if (result.isFailure) {
    StoryToast.error(
      context,
      insufficientMessage ?? context.l10nError(result.errorOrNull!),
    );
    return null;
  }
  return result.dataOrNull;
}
