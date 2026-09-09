import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../components/components.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../widgets/widgets.dart';

class DepositPage extends ConsumerStatefulWidget {
  const DepositPage({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends ConsumerState<DepositPage> {
  String _selectedDepositToken = '';
  String _selectedChainKey = '';

  @override
  void initState() {
    super.initState();
    _selectedDepositToken = widget.initialToken?.trim().toUpperCase() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _onEnter());
  }

  Future<void> _onEnter() async {
    if (!mounted) return;
    // Capture services while mounted — do not call ref after awaits.
    // Do not touch autoDispose incomeController here: nothing on this page
    // watches it, so a bare read would dispose mid-flight and crash refresh().
    final auth = ref.read(authControllerProvider.notifier);
    final privy = ref.read(privyServiceProvider);
    final balances = ref.read(onChainWalletBalanceProvider.notifier);

    // Sync Privy wallet addresses into AuthState before showing QR / address.
    await auth.ensureWallets();
    if (!mounted) return;
    await auth.syncWalletAddressesFromStorage();
    if (!mounted) return;
    await privy.ensureWalletSigners();
    if (!mounted) return;
    await balances.refreshSilently();
  }

  Future<void> _refreshBalance() async {
    if (!mounted) return;
    final balances = ref.read(onChainWalletBalanceProvider.notifier);
    await balances.refresh();
  }

  Future<void> _onNetworkSelected(String key) async {
    setState(() {
      _selectedChainKey = key;
      // Keep token if this network supports it; otherwise pick first available.
      final networks = ref.read(depositNetworksProvider);
      WalletNetworkOption? network;
      for (final n in networks) {
        if (n.key == key) {
          network = n;
          break;
        }
      }
      final symbols =
          network
              ?.depositTokens()
              .map((t) => (t.symbol ?? '').toUpperCase())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];
      if (_selectedDepositToken.isEmpty ||
          !symbols.contains(_selectedDepositToken)) {
        _selectedDepositToken = symbols.isNotEmpty ? symbols.first : '';
      }
    });
    if (!mounted) return;
    final auth = ref.read(authControllerProvider.notifier);
    // Always re-sync so EVM/Solana address matches the newly selected network.
    await auth.ensureWallets();
    if (!mounted) return;
    await auth.syncWalletAddressesFromStorage();
  }

  Future<void> _onTokenSelected(String symbol) async {
    final networks = ref.read(depositNetworksProvider);
    final compatible = networks
        .where((n) => n.supportsDepositToken(symbol))
        .toList(growable: false);
    final needsNetworkSwitch =
        compatible.isNotEmpty &&
        !compatible.any((n) => n.key == _selectedChainKey);
    setState(() {
      _selectedDepositToken = symbol;
      if (needsNetworkSwitch) {
        _selectedChainKey = compatible.first.key;
      }
    });
    if (!needsNetworkSwitch || !mounted) return;
    final auth = ref.read(authControllerProvider.notifier);
    await auth.ensureWallets();
    if (!mounted) return;
    await auth.syncWalletAddressesFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    final authAddresses = ref.watch(
      authControllerProvider.select(
        (s) => (s.effectiveSolanaAddress, s.ethereumAddress),
      ),
    );
    final networks = ref.watch(depositNetworksProvider);
    final withdrawConfig = ref.watch(withdrawConfigProvider);

    // Token list = union across all deposit networks.
    final allDepositTokens = collectAllDepositTokens(networks);
    final allDepositTokenSymbols = allDepositTokens
        .map((t) => (t.symbol ?? '').toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();

    if (_selectedDepositToken.isEmpty ||
        !allDepositTokenSymbols.contains(_selectedDepositToken)) {
      _selectedDepositToken = allDepositTokenSymbols.isNotEmpty
          ? allDepositTokenSymbols.first
          : 'USDC';
    }
    final depositToken = _selectedDepositToken;

    // Networks that support the selected token (fallback to all if none).
    final tokenNetworks = networks
        .where((n) => n.supportsDepositToken(depositToken))
        .toList(growable: false);
    final selectableNetworks = tokenNetworks.isNotEmpty
        ? tokenNetworks
        : networks;

    if (selectableNetworks.isNotEmpty &&
        !selectableNetworks.any((n) => n.key == _selectedChainKey)) {
      _selectedChainKey = selectableNetworks.first.key;
    }
    WalletNetworkOption? selectedNetwork;
    for (final network in selectableNetworks) {
      if (network.key == _selectedChainKey) {
        selectedNetwork = network;
        break;
      }
    }
    selectedNetwork ??= selectableNetworks.isNotEmpty
        ? selectableNetworks.first
        : null;
    final isEvm = selectedNetwork?.isEvm ?? false;
    final depositAddress =
        selectedNetwork?.depositAddress(
          solanaAddress: authAddresses.$1,
          ethereumAddress: authAddresses.$2,
        ) ??
        (isEvm ? authAddresses.$2 : authAddresses.$1);
    final networkName =
        selectedNetwork?.displayName ?? l10n.walletNetworkSolana;
    final addressLabel = depositAddress.isNotEmpty
        ? depositAddress
        : (isEvm ? l10n.profileWalletCreating : '--');

    WalletToken? selectedTokenMeta;
    for (final t in allDepositTokens) {
      if ((t.symbol ?? '').toUpperCase() == depositToken) {
        selectedTokenMeta = t;
        break;
      }
    }
    // Prefer icon from the selected network when available.
    for (final t in selectedNetwork?.depositTokens() ?? const <WalletToken>[]) {
      if ((t.symbol ?? '').toUpperCase() == depositToken) {
        selectedTokenMeta = t;
        break;
      }
    }
    final depositTokenIconUrl = selectedTokenMeta?.icon;
    final chainTokensMap = selectedNetwork?.chain.tokens;
    final solanaChainIcon = withdrawConfig.svmChainInfo?.icon;

    final minAmount = selectedNetwork?.minDepositAmount(depositToken) ?? '5';
    // Solana STORY deposits: no minimum-amount tip (product requirement).
    final showMinNote =
        (double.tryParse(minAmount) ?? 0) > 0 &&
        !(selectedNetwork?.isSvm == true && depositToken == 'STORY');
    // Convert tip only for tokens that bridge into USDC (e.g. USDT).
    final showConvertNote = depositToken != 'USDC' && depositToken != 'STORY';
    // Solana USDC/STORY: same asset in & out — hide send/receive flow.
    final showSendReceiveFlow =
        !(selectedNetwork?.isSvm == true &&
            (depositToken == 'USDC' || depositToken == 'STORY'));
    final warningLines = <String>[
      if (showConvertNote) l10n.depositConvertNote,
      if (showMinNote) l10n.depositMinNote(minAmount, depositToken),
      l10n.depositNetworkNote,
    ];
    final receiveToken = depositToken == 'STORY' ? 'STORY' : 'USDC';
    final sendAmountLabel = depositToken;
    final receiveAmountLabel = receiveToken;

    final textMutedColor = StoryColors.mutedForegroundOf(brightness);
    final labelStyle = StoryTextStyles.titleLarge(
      color: StoryColors.contentTextOf(brightness),
    ).copyWith(fontWeight: FontWeight.w700);
    final cardBgColor = isDark
        ? StoryColors.darkBackground
        : StoryColors.lightCard;
    final borderColor = isDark
        ? StoryColors.darkFillSecondary
        : StoryColors.lightInputBorder;
    final foreground = StoryColors.foregroundOf(brightness);
    final pageBg = isDark ? null : Colors.white;

    return AppScaffold(
      title: l10n.depositTitle,
      backgroundColor: pageBg,
      body: RefreshIndicator(
        onRefresh: _refreshBalance,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: StorySpacing.screenHorizontal,
            vertical: StorySpacing.lg,
          ),
          children: [
            Text(l10n.depositToken, style: labelStyle),
            const SizedBox(height: 8),
            PopupMenuButton<String>(
              offset: const Offset(0, 52),
              elevation: 4,
              color: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
              onSelected: _onTokenSelected,
              itemBuilder: (context) {
                return allDepositTokenSymbols.map((symbol) {
                  String? iconUrl;
                  for (final t in allDepositTokens) {
                    if ((t.symbol ?? '').toUpperCase() == symbol) {
                      iconUrl = t.icon;
                      break;
                    }
                  }
                  return PopupMenuItem<String>(
                    value: symbol,
                    child: Row(
                      children: [
                        StoryTokenLogo(token: symbol, imageUrl: iconUrl),
                        const SizedBox(width: 12),
                        Text(
                          symbol,
                          style: StoryTextStyles.bodyMedium(color: foreground),
                        ),
                        const Spacer(),
                        if (_selectedDepositToken == symbol)
                          Icon(
                            Icons.check_rounded,
                            color: StoryColors.foregroundOf(brightness),
                            size: 18,
                          ),
                      ],
                    ),
                  );
                }).toList();
              },
              child: _OutlineBox(
                borderColor: borderColor,
                child: Row(
                  children: [
                    StoryTokenLogo(
                      token: depositToken,
                      imageUrl: depositTokenIconUrl,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      depositToken,
                      style: StoryTextStyles.bodyMedium(
                        color: foreground,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: textMutedColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(l10n.depositNetwork, style: labelStyle),
            const SizedBox(height: 8),
            PopupMenuButton<String>(
              enabled: selectableNetworks.length > 1,
              offset: const Offset(0, 52),
              elevation: 4,
              color: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
              onSelected: _onNetworkSelected,
              itemBuilder: (context) {
                return selectableNetworks.map((network) {
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
                          Icon(
                            Icons.check_rounded,
                            color: foreground,
                            size: 18,
                          ),
                      ],
                    ),
                  );
                }).toList();
              },
              child: _OutlineBox(
                borderColor: borderColor,
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
                    const Spacer(),
                    if (selectableNetworks.length > 1)
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: textMutedColor,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            if (depositAddress.isNotEmpty)
              Center(
                child: Container(
                  key: ValueKey('deposit_qr_$_selectedChainKey'),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isDark ? StoryColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.08,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    key: ValueKey(depositAddress),
                    data: depositAddress,
                    size: 160,
                    gapless: false,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            Text(l10n.depositAddress, style: labelStyle),
            const SizedBox(height: 8),
            _OutlineBox(
              key: ValueKey('deposit_addr_$_selectedChainKey$depositAddress'),
              borderColor: borderColor,
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      addressLabel,
                      style: StoryTextStyles.bodyMedium(
                        color: foreground,
                      ).copyWith(height: 1.4),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.copy_rounded,
                      color: textMutedColor,
                      size: 20,
                    ),
                    onPressed: depositAddress.isEmpty
                        ? null
                        : () {
                            Clipboard.setData(
                              ClipboardData(text: depositAddress),
                            );
                            StoryToast.success(
                              context,
                              l10n.depositAddressCopied,
                            );
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            if (showSendReceiveFlow) ...[
              _DepositTokenFlow(
                sendLabel: l10n.depositSend,
                receiveLabel: l10n.depositReceive,
                sendToken: depositToken,
                sendAmountLabel: sendAmountLabel,
                sendTokenIconUrl: depositTokenIconUrl,
                receiveToken: receiveToken,
                receiveAmountLabel: receiveAmountLabel,
                receiveTokenIconUrl:
                    chainTokensMap?[receiveToken.toLowerCase()]?.icon ??
                    withdrawConfig
                        .svmChainInfo
                        ?.tokens?[receiveToken.toLowerCase()]
                        ?.icon ??
                    depositTokenIconUrl,
                networkBadgeToken:
                    selectedNetwork?.logoToken ?? (isEvm ? 'ETH' : 'SOL'),
                networkBadgeIconUrl: selectedNetwork?.assetIcon == null
                    ? selectedNetwork?.chain.icon
                    : null,
                networkBadgeAssetPath: selectedNetwork?.assetIcon,
                receiveBadgeToken: 'SOL',
                receiveBadgeIconUrl: solanaChainIcon,
                mutedColor: textMutedColor,
                foreground: foreground,
              ),
              if (warningLines.isNotEmpty) const SizedBox(height: 28),
            ],
            if (warningLines.isNotEmpty)
              StoryWarningBullets(text: warningLines.join('\n')),
          ],
        ),
      ),
    );
  }
}

class _OutlineBox extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  const _OutlineBox({
    super.key,
    required this.child,
    required this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _DepositTokenFlow extends StatelessWidget {
  final String sendLabel;
  final String receiveLabel;
  final String sendToken;
  final String sendAmountLabel;
  final String? sendTokenIconUrl;
  final String receiveToken;
  final String receiveAmountLabel;
  final String? receiveTokenIconUrl;
  final String networkBadgeToken;
  final String? networkBadgeIconUrl;
  final String? networkBadgeAssetPath;
  final String receiveBadgeToken;
  final String? receiveBadgeIconUrl;
  final Color mutedColor;
  final Color foreground;

  const _DepositTokenFlow({
    required this.sendLabel,
    required this.receiveLabel,
    required this.sendToken,
    required this.sendAmountLabel,
    required this.sendTokenIconUrl,
    required this.receiveToken,
    required this.receiveAmountLabel,
    required this.receiveTokenIconUrl,
    required this.networkBadgeToken,
    required this.networkBadgeIconUrl,
    this.networkBadgeAssetPath,
    required this.receiveBadgeToken,
    required this.receiveBadgeIconUrl,
    required this.mutedColor,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: _FlowSide(
              caption: sendLabel,
              token: sendToken,
              amountLabel: sendAmountLabel,
              tokenIconUrl: sendTokenIconUrl,
              badgeToken: networkBadgeToken,
              badgeIconUrl: networkBadgeIconUrl,
              badgeAssetPath: networkBadgeAssetPath,
              mutedColor: mutedColor,
              foreground: foreground,
            ),
          ),
        ),
        Icon(Icons.arrow_forward_rounded, size: 16, color: mutedColor),
        Expanded(
          child: Center(
            child: _FlowSide(
              caption: receiveLabel,
              token: receiveToken,
              amountLabel: receiveAmountLabel,
              tokenIconUrl: receiveTokenIconUrl,
              badgeToken: receiveBadgeToken,
              badgeIconUrl: receiveBadgeIconUrl,
              mutedColor: mutedColor,
              foreground: foreground,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlowSide extends StatelessWidget {
  final String caption;
  final String token;
  final String amountLabel;
  final String? tokenIconUrl;
  final String badgeToken;
  final String? badgeIconUrl;
  final String? badgeAssetPath;
  final Color mutedColor;
  final Color foreground;

  const _FlowSide({
    required this.caption,
    required this.token,
    required this.amountLabel,
    required this.tokenIconUrl,
    required this.badgeToken,
    required this.badgeIconUrl,
    this.badgeAssetPath,
    required this.mutedColor,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final badgeRingColor = brightness == Brightness.dark
        ? StoryColors.darkBackground
        : Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              StoryTokenLogo(token: token, imageUrl: tokenIconUrl, size: 32),
              Positioned(
                // 贴着大图标右下内侧，避免悬在边缘外
                right: 1,
                bottom: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: badgeRingColor),
                  ),
                  child: StoryTokenLogo(
                    token: badgeToken,
                    imageUrl: badgeIconUrl,
                    assetPath: badgeAssetPath,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(caption, style: StoryTextStyles.caption(color: mutedColor)),
              Text(
                amountLabel,
                style: StoryTextStyles.bodyMedium(
                  color: foreground,
                ).copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
