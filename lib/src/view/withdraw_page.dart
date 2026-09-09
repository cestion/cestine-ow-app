import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../components/components.dart';
import '../core/story_env.dart';
import '../core/story_logger.dart';
import '../l10n/app_localizations.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../services/evm/evm_abi.dart';
import '../services/privy_service.dart';
import '../services/sponsor_service.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../utils/validators.dart';
import '../utils/wallet_balance_gate.dart';
import '../widgets/widgets.dart';
import 'qr_scanner_page.dart';

/// Available-balance display / Max-fill precision (all withdraw tokens).
@visibleForTesting
const int withdrawBalanceFractionDigits = 2;

/// Floors [value] to [decimals] places so formatting never rounds above balance.
@visibleForTesting
double floorWithdrawAmount(
  double value, {
  int decimals = withdrawBalanceFractionDigits,
}) {
  if (!value.isFinite || value <= 0) return 0;
  final factor = math.pow(10, decimals).toDouble();
  return (value * factor).floorToDouble() / factor;
}

/// Max fraction digits allowed in the withdraw amount field.
@visibleForTesting
int withdrawInputFractionDigits(String token) {
  switch (token.trim().toUpperCase()) {
    case 'STORY':
      return 2;
    case 'USDT':
    case 'USDC':
      return 5;
    default:
      return 5;
  }
}

/// Digits + optional `.`, capped at [maxFractionDigits] after the decimal.
class _WithdrawAmountInputFormatter extends TextInputFormatter {
  _WithdrawAmountInputFormatter({required this.maxFractionDigits});

  final int maxFractionDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;
    final dot = text.indexOf('.');
    if (dot >= 0) {
      final fracLen = text.length - dot - 1;
      if (fracLen > maxFractionDigits) return oldValue;
    }
    return newValue;
  }
}

/// Floored Max-fill text using [inputScale] (or [withdrawInputFractionDigits]).
/// Trailing zeros after the decimal (and a bare trailing `.`) are omitted.
@visibleForTesting
String formatWithdrawMaxFill(double balance, String token, {int? inputScale}) {
  final decimals = inputScale ?? withdrawInputFractionDigits(token);
  var text = floorWithdrawAmount(
    balance,
    decimals: decimals,
  ).toStringAsFixed(decimals);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}

class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  final _addressCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedToken = ''; // initialized from config when loaded
  String _selectedChainKey = '';
  double? _selectedEvmBalance;
  bool _isLoadingEvmBalance = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedToken = widget.initialToken?.trim().toUpperCase() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(privyServiceProvider).ensureWalletSigners();
      ref.read(incomeControllerProvider.notifier).refresh();
      ref.read(onChainWalletBalanceProvider.notifier).refreshSilently();
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  WalletNetworkOption? _selectedNetwork(WithdrawConfigState configState) {
    if (configState.networks.isEmpty) return null;
    return configState.byKey(_selectedChainKey) ?? configState.networks.first;
  }

  String? _getTokenIconUrl(WalletNetworkOption? network, String symbol) {
    final tokensMap = network?.chain.tokens;
    if (tokensMap == null) return null;
    for (final entry in tokensMap.entries) {
      final s = (entry.value.symbol ?? entry.key).toUpperCase();
      if (s == symbol.toUpperCase()) return entry.value.icon;
    }
    return tokensMap[symbol.toLowerCase()]?.icon;
  }

  List<WalletToken> _chainTokens(WalletNetworkOption? network) {
    return network?.withdrawTokens() ?? const [];
  }

  // ─── Config helpers ──────────────────────────────────────────────────────

  /// Find the withdraw token config matching _selectedToken from backend config.
  InitWithdrawTokenConfig? _getTokenConfig(WalletNetworkOption? network) {
    return network?.withdrawTokenConfig(_selectedToken);
  }

  double _getMinAmount(WalletNetworkOption? network) {
    final tokenCfg = _getTokenConfig(network);
    if (tokenCfg?.min != null) {
      return double.tryParse(tokenCfg!.min!) ?? 10.0;
    }
    return 10.0;
  }

  /// Per-tx max from withdraw config, or null when unset.
  double? _getConfiguredMaxAmount(WalletNetworkOption? network) {
    final raw = _getTokenConfig(network)?.max?.trim();
    if (raw == null || raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  /// Max fill = floored available balance (not config `max`, which is a
  /// per-tx metadata cap and would incorrectly leave large balances at e.g. 10000).
  void _fillMaxAmount(double balance, WalletNetworkOption? network) {
    final text = formatWithdrawMaxFill(
      balance,
      _selectedToken,
      inputScale: network?.withdrawTokenInputScale(_selectedToken),
    );
    _amountCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  bool _isValid(double balance, WalletNetworkOption? network) {
    final address = _addressCtrl.text.trim();
    final amountStr = _amountCtrl.text.trim();
    if (address.isEmpty || amountStr.isEmpty) return false;
    final isEvm = network?.isEvm ?? false;
    if (isEvm
        ? !isValidEthereumAddress(address)
        : !isValidSolanaAddress(address)) {
      return false;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null) return false;
    final minAmt = _getMinAmount(network);
    if (amount < minAmt) return false;
    if (amount > balance + 1e-9) return false;
    final maxAmt = _getConfiguredMaxAmount(network);
    if (maxAmt != null && amount > maxAmt + 1e-9) return false;
    return true;
  }

  /// Inline tip under the address field. Empty input shows no error.
  String? _addressInlineError({
    required bool isEvm,
    required AppLocalizations l10n,
  }) {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) return null;
    if (isEvm) {
      return isValidEthereumAddress(address)
          ? null
          : l10n.withdrawInvalidEvmAddress;
    }
    return isValidSolanaAddress(address)
        ? null
        : l10n.withdrawInvalidSolanaAddress;
  }

  /// Inline tip under available balance for over-balance / over-max amount.
  String _insufficientBalanceMessage(AppLocalizations l10n) {
    return switch (_selectedToken.trim().toUpperCase()) {
      'USDC' => l10n.gameInsufficientUsdc('USDC'),
      'STORY' => l10n.walletInsufficientStory,
      _ => l10n.withdrawExceedBalanceError,
    };
  }

  String? _amountInlineError({
    required double balance,
    required WalletNetworkOption? network,
    required AppLocalizations l10n,
  }) {
    final amountStr = _amountCtrl.text.trim();
    if (amountStr.isEmpty) return null;
    final amount = double.tryParse(amountStr);
    if (amount == null) return null;
    if (amount > balance + 1e-9) {
      return _insufficientBalanceMessage(l10n);
    }
    final maxAmt = _getConfiguredMaxAmount(network);
    if (maxAmt != null && amount > maxAmt + 1e-9) {
      final maxLabel = maxAmt == maxAmt.roundToDouble()
          ? maxAmt.toStringAsFixed(0)
          : maxAmt.toStringAsFixed(2);
      return l10n.withdrawMaxAmount(maxLabel, _selectedToken);
    }
    return null;
  }

  bool _isOwnWalletAddress(String address, {required bool isEvm}) {
    final auth = ref.read(authControllerProvider);
    if (isEvm) {
      final mine = auth.ethereumAddress.trim();
      if (mine.isEmpty) return false;
      return address.toLowerCase() == mine.toLowerCase();
    }
    final mine = auth.effectiveSolanaAddress.trim();
    if (mine.isEmpty) return false;
    return address == mine;
  }

  Future<void> _refreshSelectedEvmBalance(WalletNetworkOption? network) async {
    if (network == null || !network.isEvm) {
      if (mounted) {
        setState(() {
          _selectedEvmBalance = null;
          _isLoadingEvmBalance = false;
        });
      }
      return;
    }
    final tokenSymbol = _selectedToken.toUpperCase();
    if (tokenSymbol.isEmpty) return;

    WalletToken? walletToken;
    for (final t in network.withdrawTokens()) {
      if ((t.symbol ?? '').toUpperCase() == tokenSymbol) {
        walletToken = t;
        break;
      }
    }
    final rpcUrl = network.chain.rpc?.http?.trim();
    final tokenAddress = walletToken?.address;
    final fromAddress = ref.read(authControllerProvider).ethereumAddress;
    if (rpcUrl == null ||
        rpcUrl.isEmpty ||
        tokenAddress == null ||
        tokenAddress.isEmpty ||
        fromAddress.isEmpty) {
      if (mounted) {
        setState(() {
          _selectedEvmBalance = 0;
          _isLoadingEvmBalance = false;
        });
      }
      return;
    }

    setState(() => _isLoadingEvmBalance = true);
    final balance = await ref
        .read(evmTokenBalanceServiceProvider)
        .getTokenBalance(
          rpcHttpUrl: rpcUrl,
          ownerAddress: fromAddress,
          tokenAddress: tokenAddress,
          decimals: walletToken?.decimals ?? 6,
        );
    if (!mounted) return;
    setState(() {
      _selectedEvmBalance = balance ?? 0;
      _isLoadingEvmBalance = false;
    });
  }

  // ─── Sponsor withdraw flow ───────────────────────────────────────────────

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _toastError(String message) {
    _dismissKeyboard();
    if (!mounted) return;
    StoryToast.error(context, message);
  }

  void _toastSuccess(String message) {
    _dismissKeyboard();
    if (!mounted) return;
    StoryToast.success(context, message);
  }

  Future<void> _handleWithdraw(
    double balance,
    WithdrawConfigState configState,
  ) async {
    _dismissKeyboard();
    final l10n = context.l10n;
    final network = _selectedNetwork(configState);
    final isEvm = network?.isEvm ?? false;
    final address = _addressCtrl.text.trim();
    final amountStr = _amountCtrl.text.trim();

    if (address.isEmpty) {
      _toastError(l10n.withdrawAddressHint);
      return;
    }

    if (isEvm
        ? !isValidEthereumAddress(address)
        : !isValidSolanaAddress(address)) {
      // Inline error under the field is enough; avoid a second toast.
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      _toastError(l10n.withdrawAmountHint);
      return;
    }

    final minAmt = _getMinAmount(network);
    if (amount < minAmt) {
      _toastError(
        l10n.withdrawMinAmountError(minAmt.toStringAsFixed(0), _selectedToken),
      );
      return;
    }

    if (amount > balance + 1e-9) {
      _toastError(_insufficientBalanceMessage(l10n));
      return;
    }

    final maxAmt = _getConfiguredMaxAmount(network);
    if (maxAmt != null && amount > maxAmt + 1e-9) {
      return;
    }

    // Show confirmation dialog. Platform withdraw fee is config-only metadata —
    // the on-chain transfer sends [amount] as-is, so do not show a fee line.
    StoryDialog.confirm(
      context: context,
      title: l10n.withdrawConfirmTitle,
      message: l10n.withdrawConfirmMessage(
        amount.toString(),
        _selectedToken,
        address,
      ),
      confirmLabel: l10n.withdrawConfirm,
      onConfirm: () {
        if (_isOwnWalletAddress(address, isEvm: isEvm)) {
          _toastError(l10n.withdrawSameAsWalletError);
          return;
        }
        _amountCtrl.clear();
        if (isEvm) {
          _executeEvmWithdraw(amount, amountStr, address, network!);
        } else {
          _executeSponsorWithdraw(amount, amountStr, address, configState);
        }
      },
    );
  }

  Future<void> _executeEvmWithdraw(
    double amount,
    String amountStr,
    String toAddress,
    WalletNetworkOption network,
  ) async {
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);

    try {
      final evmChain = network.chain;
      final chainId = evmChain.chainId;
      final tokensMap = evmChain.tokens;
      if (chainId == null || tokensMap == null) {
        _toastError(l10n.withdrawEvmFailed);
        return;
      }

      WalletToken? walletToken;
      for (final entry in tokensMap.entries) {
        final symbol =
            entry.value.symbol?.toUpperCase() ?? entry.key.toUpperCase();
        if (symbol == _selectedToken.toUpperCase()) {
          walletToken = entry.value;
          break;
        }
      }
      final tokenAddress = walletToken?.address;
      if (tokenAddress == null || tokenAddress.isEmpty) {
        _toastError(l10n.withdrawEvmFailed);
        return;
      }

      final fromAddress = ref.read(authControllerProvider).ethereumAddress;
      if (fromAddress.isEmpty) {
        _toastError(l10n.withdrawEvmFailed);
        return;
      }

      final decimals = walletToken?.decimals ?? 18;
      final amountRaw = parseTokenAmount(amountStr, decimals);
      if (amountRaw <= BigInt.zero) {
        _toastError(l10n.withdrawAmountHint);
        return;
      }

      final privy = ref.read(privyServiceProvider);
      final result = await privy.sendEthereumTransaction(
        from: fromAddress,
        to: tokenAddress,
        data: encodeErc20Transfer(toAddress, amountRaw),
        chainId: chainId,
      );
      if (!mounted) return;
      if (!result.success) {
        final err = result.error;
        final message = switch (err) {
          PrivyService.networkErrorKey => l10n.errorNetwork,
          PrivyService.sessionExpiredErrorKey => l10n.authSessionExpired,
          PrivyService.unavailableErrorKey => l10n.loginPrivyUnavailable,
          _ => (err == null || err.isEmpty) ? l10n.withdrawEvmFailed : err,
        };
        _toastError(message);
        return;
      }

      if (mounted) {
        setState(() {
          _selectedEvmBalance = ((_selectedEvmBalance ?? 0) - amount).clamp(
            0.0,
            double.infinity,
          );
        });
      }
      // Keep primary EVM cache in sync when withdrawing from the first chain.
      final primaryEvm = ref.read(withdrawConfigProvider).evmChainInfo;
      if (identical(primaryEvm, evmChain) || primaryEvm?.chainId == chainId) {
        final isUsd = _selectedToken.toUpperCase().startsWith('USD');
        ref
            .read(onChainWalletBalanceProvider.notifier)
            .deductEvm(usdc: isUsd ? amount : 0, story: isUsd ? 0 : amount);
      }
      final balances = ref.read(onChainWalletBalanceProvider.notifier);
      // Success UX first — do not keep the button spinning during RPC refresh.
      if (mounted) {
        setState(() => _isSubmitting = false);
        _toastSuccess(l10n.withdrawSponsorSuccess);
        Navigator.of(context).pop();
      }
      unawaited(balances.refreshSilently());
    } catch (_) {
      if (mounted) {
        _toastError(l10n.withdrawEvmFailed);
      }
    } finally {
      if (mounted && _isSubmitting) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _executeSponsorWithdraw(
    double amount,
    String amountStr,
    String toAddress,
    WithdrawConfigState configState,
  ) async {
    final l10n = context.l10n;

    setState(() => _isSubmitting = true);

    try {
      // Build and sign Solana transaction via sponsor
      if (configState.svmChainInfo == null ||
          configState.sponsorApiUrl == null) {
        StoryLogger.w(
          'Withdraw blocked: svmChain=${configState.svmChainInfo != null} '
          'sponsorApiUrl=${configState.sponsorApiUrl}',
          tag: 'Withdraw',
        );
        _toastError(l10n.withdrawSponsorFailed);
        return;
      }

      StoryLogger.d(
        'Sponsor withdraw using api=${configState.sponsorApiUrl}',
        tag: 'Withdraw',
      );

      final svmChain = configState.svmChainInfo!;

      // Find token mint address from chain tokens map
      final tokensMap = svmChain.tokens;
      WalletToken? walletToken;
      if (tokensMap != null) {
        for (final entry in tokensMap.entries) {
          if (entry.value.symbol?.toUpperCase() ==
              _selectedToken.toUpperCase()) {
            walletToken = entry.value;
            break;
          }
        }
      }

      if (walletToken?.address == null || walletToken?.decimals == null) {
        _toastError(l10n.withdrawSponsorFailed);
        return;
      }

      final userAddress = ref.read(authControllerProvider).solanaAddress;
      final rpcUrl = svmChain.rpc?.http;
      final spenderAddress = svmChain.contracts?.spender;

      if (rpcUrl == null || spenderAddress == null) {
        _toastError(l10n.withdrawSponsorFailed);
        return;
      }

      // Convert human-readable amount to token unit (BigInt with decimals)
      final decimals = walletToken!.decimals!;
      final multiplier = math.pow(10, decimals).toInt();
      final amountBigInt = BigInt.from(
        (double.parse(amountStr) * multiplier).toInt(),
      );

      final sponsorParams = SponsorWithdrawParams(
        userSolanaAddress: userAddress,
        toAddress: toAddress,
        tokenMint: walletToken.address!,
        tokenDecimals: decimals,
        amount: amountBigInt,
        rpcHttpUrl: rpcUrl,
        spenderAddress: spenderAddress,
        sponsorApiUrl: configState.sponsorApiUrl!,
        authToken: ref.read(localRepositoryProvider).cachedToken,
      );

      // Fresh on-chain check before optimistic deduct + sponsor submit
      final isStory = _selectedToken.toUpperCase() == 'STORY';
      final ticket = isStory
          ? await prepareStorySpend(ref, context, amount, reason: 'withdraw')
          : await prepareUsdcSpend(ref, context, amount, reason: 'withdraw');
      if (ticket == null || !mounted) return;
      final ledger = ref.read(walletLedgerProvider);

      // Progress is shown via the submit button loading state — avoid a second
      // toast that would stack with the final success/error toast.
      final sponsorResult = await ref
          .read(sponsorServiceProvider)
          .submitSponsorWithdraw(sponsorParams);

      if (!mounted) {
        if (ticket.didDeduct) {
          await ledger.reconcile(ticket);
        }
        return;
      }

      if (sponsorResult.isFailure) {
        if (ticket.didDeduct) {
          await ledger.reconcile(ticket);
        }
        if (!mounted) return;
        _toastError(
          sponsorResult.errorOrNull?.userMessage ?? l10n.withdrawSponsorFailed,
        );
        return;
      }

      // Success UX first — do not keep the button spinning during RPC refresh.
      if (mounted) {
        setState(() => _isSubmitting = false);
        _toastSuccess(l10n.withdrawSponsorSuccess);
        Navigator.of(context).pop();
      }
      unawaited(ledger.commitSpend(ticket));
    } catch (e) {
      await ref.read(walletLedgerProvider).refresh();
      if (mounted) {
        _toastError(l10n.withdrawErrorToast(e.toString()));
      }
    } finally {
      if (mounted && _isSubmitting) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final walletBalanceState = ref.watch(onChainWalletBalanceProvider);
    final sdkConfig = ref.watch(storySdkConfigProvider);
    final withdrawConfigState = ref.watch(withdrawConfigProvider);
    final networks = withdrawConfigState.networks;

    if (networks.isNotEmpty &&
        !networks.any((n) => n.key == _selectedChainKey)) {
      _selectedChainKey = networks.first.key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshSelectedEvmBalance(_selectedNetwork(withdrawConfigState));
      });
    }

    final selectedNetwork = _selectedNetwork(withdrawConfigState);
    final isEvm = selectedNetwork?.isEvm ?? false;
    final networkName =
        selectedNetwork?.displayName ??
        (sdkConfig.env == StoryEnv.production
            ? 'Solana Mainnet'
            : 'Solana Devnet');

    final chainTokens = _chainTokens(selectedNetwork);
    final tokenSymbols = chainTokens.isNotEmpty
        ? chainTokens.map((t) => t.symbol!.toUpperCase()).toSet().toList()
        : (selectedNetwork?.isSvm == true
              ? (withdrawConfigState.tokens ?? [])
                    .where((t) => t.symbol != null && t.symbol!.isNotEmpty)
                    .map((t) => t.symbol!.toUpperCase())
                    .toList()
              : <String>[]);
    tokenSymbols.sort((a, b) {
      int rank(String s) {
        if (s == 'USDC') return 0;
        if (s == 'STORY') return 1;
        return 2;
      }

      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.compareTo(b);
    });
    if (tokenSymbols.isNotEmpty &&
        (_selectedToken.isEmpty || !tokenSymbols.contains(_selectedToken))) {
      _selectedToken = tokenSymbols.first;
      if (isEvm) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshSelectedEvmBalance(selectedNetwork);
        });
      }
    }

    final isUsd = _selectedToken.toUpperCase().startsWith('USD');
    final double balance;
    if (isEvm) {
      balance = _selectedEvmBalance ?? 0.0;
    } else {
      balance = isUsd
          ? walletBalanceState.usdcBalance
          : walletBalanceState.storyBalance;
    }

    final textMutedColor = StoryColors.mutedForegroundOf(theme.brightness);
    final foreground = StoryColors.foregroundOf(theme.brightness);
    final cardBgColor = isDark
        ? StoryColors.darkBackground
        : StoryColors.lightCard;
    final inputBgColor = isDark
        ? StoryColors.darkMuted
        : const Color(0xFFF6F6F6);
    final borderColor = isDark
        ? StoryColors.darkFillSecondary
        : StoryColors.lightInputBorder;
    final labelStyle = StoryTextStyles.titleLarge(
      color: StoryColors.contentTextOf(theme.brightness),
    ).copyWith(fontWeight: FontWeight.w700);
    final filledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    final configLoaded = networks.isNotEmpty;
    final minAmt = configLoaded ? _getMinAmount(selectedNetwork) : 10.0;

    return AppScaffold(
      title: l10n.withdrawTitle,
      backgroundColor: isDark ? null : Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.screenHorizontal,
          vertical: StorySpacing.lg,
        ),
        children: [
          Text(l10n.withdrawAddress, style: labelStyle),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: _addressCtrl,
            builder: (context, _) {
              final addressError = _addressInlineError(
                isEvm: isEvm,
                l10n: l10n,
              );
              final fieldBorder = addressError != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: StoryColors.destructive,
                      ),
                    )
                  : filledBorder;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _addressCtrl,
                    style: theme.textTheme.bodyMedium,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    ],
                    decoration: InputDecoration(
                      hintText: l10n.withdrawAddressHintWithToken(
                        _selectedToken,
                      ),
                      hintStyle: StoryTextStyles.bodyMedium(
                        color: textMutedColor,
                      ),
                      filled: true,
                      fillColor: inputBgColor,
                      border: fieldBorder,
                      enabledBorder: fieldBorder,
                      focusedBorder: fieldBorder,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: SvgPicture.asset(
                          'assets/wallet/scan.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            foreground,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: () async {
                          StoryLogger.d(
                            'Open QR scanner preferEvm=$isEvm',
                            tag: 'Withdraw',
                          );
                          final result = await Navigator.of(context)
                              .push<String>(
                                MaterialPageRoute(
                                  builder: (_) => const QrScannerPage(),
                                ),
                              );
                          if (!context.mounted) {
                            StoryLogger.w(
                              'Scan result ignored: withdraw unmounted',
                              tag: 'Withdraw',
                            );
                            return;
                          }
                          if (result == null || result.isEmpty) {
                            StoryLogger.d(
                              'Scan cancelled or empty',
                              tag: 'Withdraw',
                            );
                            return;
                          }
                          StoryLogger.d(
                            'Scan raw len=${result.length} '
                            'snippet=${truncateAddress(result)} '
                            'preferEvm=$isEvm',
                            tag: 'Withdraw',
                          );
                          final parsed = parseWalletAddressFromScan(
                            result,
                            preferEvm: isEvm,
                          );
                          if (parsed == null) {
                            StoryLogger.w(
                              'Scan parse failed preferEvm=$isEvm '
                              'snippet=${truncateAddress(result)}',
                              tag: 'Withdraw',
                            );
                            StoryToast.error(
                              context,
                              isEvm
                                  ? l10n.withdrawInvalidEvmAddress
                                  : l10n.withdrawInvalidSolanaAddress,
                            );
                            return;
                          }
                          StoryLogger.i(
                            'Scan address filled '
                            '${truncateAddress(parsed)} preferEvm=$isEvm',
                            tag: 'Withdraw',
                          );
                          _addressCtrl.value = TextEditingValue(
                            text: parsed,
                            selection: TextSelection.collapsed(
                              offset: parsed.length,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    addressError ?? l10n.withdrawAddressNote,
                    style: StoryTextStyles.caption(
                      color: addressError != null
                          ? StoryColors.destructive
                          : textMutedColor,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          Text(l10n.withdrawToken, style: labelStyle),
          const SizedBox(height: 8),
          PopupMenuButton<String>(
            enabled: tokenSymbols.length > 1,
            offset: const Offset(0, 52),
            elevation: 4,
            color: cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor),
            ),
            onSelected: (value) {
              setState(() {
                _selectedToken = value;
                _amountCtrl.clear();
              });
              if (isEvm) {
                _refreshSelectedEvmBalance(selectedNetwork);
              }
            },
            itemBuilder: (context) {
              if (tokenSymbols.isEmpty) {
                return <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    enabled: false,
                    child: Text('No tokens available'),
                  ),
                ];
              }
              return tokenSymbols.map((symbol) {
                return PopupMenuItem<String>(
                  value: symbol,
                  child: Row(
                    children: [
                      StoryTokenLogo(
                        token: symbol,
                        imageUrl: _getTokenIconUrl(selectedNetwork, symbol),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        symbol,
                        style: StoryTextStyles.bodyMedium(color: foreground),
                      ),
                      const Spacer(),
                      if (_selectedToken == symbol)
                        Icon(Icons.check_rounded, color: foreground, size: 18),
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? StoryColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  StoryTokenLogo(
                    token: _selectedToken.isEmpty ? 'USDC' : _selectedToken,
                    imageUrl: _getTokenIconUrl(
                      selectedNetwork,
                      _selectedToken.isEmpty ? 'USDC' : _selectedToken,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedToken.isEmpty ? 'USDC' : _selectedToken,
                    style: StoryTextStyles.bodyMedium(
                      color: foreground,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (tokenSymbols.length > 1) ...[
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: textMutedColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(l10n.withdrawNetwork, style: labelStyle),
          const SizedBox(height: 8),
          PopupMenuButton<String>(
            enabled: networks.length > 1,
            offset: const Offset(0, 52),
            elevation: 4,
            color: cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor),
            ),
            onSelected: (value) {
              setState(() {
                _selectedChainKey = value;
                _selectedToken = '';
                _selectedEvmBalance = null;
                _addressCtrl.clear();
                _amountCtrl.clear();
              });
              final next = withdrawConfigState.byKey(value);
              _refreshSelectedEvmBalance(next);
            },
            itemBuilder: (context) {
              return networks.map((network) {
                return PopupMenuItem<String>(
                  value: network.key,
                  child: Row(
                    children: [
                      StoryTokenLogo(
                        token: network.logoToken,
                        assetPath: network.assetIcon,
                        imageUrl: network.assetIcon == null
                            ? network.chain.icon
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        network.displayName,
                        style: StoryTextStyles.bodyMedium(color: foreground),
                      ),
                      const Spacer(),
                      if (_selectedChainKey == network.key)
                        Icon(Icons.check_rounded, color: foreground, size: 18),
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? StoryColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  StoryTokenLogo(
                    token:
                        selectedNetwork?.logoToken ?? (isEvm ? 'ETH' : 'SOL'),
                    assetPath: selectedNetwork?.assetIcon,
                    imageUrl: selectedNetwork?.assetIcon == null
                        ? selectedNetwork?.chain.icon
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    networkName,
                    style: StoryTextStyles.bodyMedium(
                      color: foreground,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (networks.length > 1) ...[
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: textMutedColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(l10n.withdrawAmount, style: labelStyle),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (context, _) {
              final amountError = _amountInlineError(
                balance: balance,
                network: selectedNetwork,
                l10n: l10n,
              );
              final amountBorder = amountError != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: StoryColors.destructive,
                      ),
                    )
                  : filledBorder;
              final tokenSymbol = _selectedToken.isEmpty
                  ? 'USDC'
                  : _selectedToken;
              final inputScale =
                  selectedNetwork?.withdrawTokenInputScale(tokenSymbol) ??
                  withdrawInputFractionDigits(tokenSymbol);
              final balanceScale =
                  selectedNetwork?.withdrawTokenScale(_selectedToken) ??
                  withdrawBalanceFractionDigits;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: ValueKey('withdraw-amount-$_selectedToken'),
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    inputFormatters: [
                      _WithdrawAmountInputFormatter(
                        maxFractionDigits: inputScale,
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: l10n.withdrawAmountHint,
                      hintStyle: StoryTextStyles.bodyMedium(
                        color: textMutedColor,
                      ),
                      filled: true,
                      fillColor: inputBgColor,
                      border: amountBorder,
                      enabledBorder: amountBorder,
                      focusedBorder: amountBorder,
                      contentPadding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedToken.isEmpty ? 'USDC' : _selectedToken,
                              style: StoryTextStyles.bodyMedium(
                                color: foreground,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () =>
                                  _fillMaxAmount(balance, selectedNetwork),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? StoryColors.darkCard
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Text(
                                  l10n.withdrawMax,
                                  style: StoryTextStyles.bodySmall(
                                    color: foreground,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.withdrawAvailableBalance(
                      floorWithdrawAmount(
                        balance,
                        decimals: balanceScale,
                      ).toStringAsFixed(balanceScale),
                      _selectedToken,
                    ),
                    style: StoryTextStyles.caption(color: textMutedColor),
                  ),
                  if (amountError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      amountError,
                      style: StoryTextStyles.caption(
                        color: StoryColors.destructive,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          ListenableBuilder(
            listenable: Listenable.merge([_addressCtrl, _amountCtrl]),
            builder: (context, _) => StoryButton(
              label: l10n.withdrawConfirm,
              block: true,
              height: 48,
              borderRadius: BorderRadius.circular(12),
              style: StoryButtonStyle.privy,
              loading: _isSubmitting,
              onPressed:
                  (_isSubmitting ||
                      _isLoadingEvmBalance ||
                      !_isValid(balance, selectedNetwork))
                  ? null
                  : () => _handleWithdraw(balance, withdrawConfigState),
            ),
          ),
          const SizedBox(height: 16),
          StoryWarningBullets(
            text: l10n.withdrawMinWarning(
              minAmt.toStringAsFixed(0),
              _selectedToken,
            ),
          ),
        ],
      ),
    );
  }
}
