import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../utils/wallet_network_icons.dart';
import 'core_providers.dart';
import 'repository_providers.dart';

/// Tags for the theater category filter (fetched once, rarely changes, but resets when language changes).
final FutureProvider<List<DramaTag>> dramaTagsProvider =
    FutureProvider<List<DramaTag>>((ref) async {
      ref.watch(localeCodeProvider);

      final repo = ref.read(tagRepositoryProvider);
      final result = await repo.listTags();
      return result.isSuccess ? (result.dataOrNull ?? []) : [];
    });

/// Banner items for the theater hero carousel, extracted from global config.
///
/// Reuses [globalConfigProvider] to avoid a duplicate network request on
/// cold start (both providers previously called `getGlobalConfig()` independently,
/// hitting the API twice before the in-memory cache was populated).
///
/// Uses `.future` (not `whenOrNull`) so this provider stays loading until the
/// shared config resolves — otherwise pull-to-refresh briefly completes as [].
final FutureProvider<List<BannerItem>> theaterBannerProvider =
    FutureProvider<List<BannerItem>>((ref) async {
      final result = await ref.watch(globalConfigProvider.future);
      return result.when(
        success: (config) {
          final bannerConfig = config.banner;
          if (bannerConfig?.enabled == false) return <BannerItem>[];
          final items = bannerConfig?.items;
          if (items != null && items.isNotEmpty) {
            final sorted = List<BannerItem>.from(items)
              ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
            // Cap carousel size for performance (native preview players).
            if (sorted.length > 10) return sorted.sublist(0, 10);
            return sorted;
          }
          return <BannerItem>[];
        },
        failure: (_) => <BannerItem>[],
      );
    });

final globalConfigProvider = FutureProvider<Result<GlobalConfig>>((ref) async {
  final repo = ref.read(configRepositoryProvider);
  return repo.getGlobalConfig();
});

/// V3 升级弹窗专用的配置校准。
///
/// 每次弹窗建立监听都会跳过进程内 TTL，先请求网络并覆盖内存/Hive；网络
/// 失败时 [ConfigRepository] 仍会返回最后一次可用的 Hive 快照供 UI 降级。
final agentV3UpgradeConfigCalibrationProvider =
    FutureProvider.autoDispose<Result<GlobalConfig>>((ref) async {
      final repo = ref.read(configRepositoryProvider);
      return repo.getGlobalConfig(forceRefresh: true);
    });

/// A selectable wallet network resolved from `chainlinks` + init deposit/withdraw.
class WalletNetworkOption extends Equatable {
  final String key;
  final ChainInfo chain;
  final InitDepositConfig? deposit;
  final InitWithdrawConfig? withdraw;

  const WalletNetworkOption({
    required this.key,
    required this.chain,
    this.deposit,
    this.withdraw,
  });

  /// Resolved chain family. Blank `chainType` from API is treated as missing
  /// so we fall through to deposit config / key heuristics (empty string must
  /// not win over `??` fallbacks).
  String get chainType {
    final fromChain = chain.chainType?.trim();
    if (fromChain != null && fromChain.isNotEmpty) return fromChain;
    final fromDeposit = deposit?.chainType?.trim();
    if (fromDeposit != null && fromDeposit.isNotEmpty) return fromDeposit;
    return isLikelySvmKey ? 'svm' : 'evm';
  }

  /// Key / name is the strongest signal. Network icons already key off this —
  /// address selection must match, even if API `chainType` is wrong/stale.
  bool get isLikelySvmKey {
    final hay = '$key ${chain.name ?? ''}'.toLowerCase();
    return hay.contains('solana') ||
        RegExp(r'(^|[^a-z])svm([^a-z]|$)').hasMatch(hay);
  }

  bool get isLikelyEvmKey {
    final hay = '$key ${chain.name ?? ''}'.toLowerCase();
    return hay.contains('ethereum') ||
        hay.contains('arbitrum') ||
        hay.contains('bsc') ||
        hay.contains('binance') ||
        hay.contains('base') ||
        hay.contains('polygon') ||
        hay.contains('optimism') ||
        hay.contains('sepolia') ||
        hay.contains('goerli') ||
        RegExp(r'(^|[^a-z])evm([^a-z]|$)').hasMatch(hay);
  }

  /// SVM vs EVM are mutually exclusive. Prefer key heuristics over `chainType`
  /// so a mislabeled chainlinks entry cannot show Solana address on Arbitrum.
  bool get isSvm {
    if (isLikelySvmKey) return true;
    if (isLikelyEvmKey) return false;
    final t = chainType.toLowerCase();
    if (t == 'svm' || t == 'solana') return true;
    if (t == 'evm' || t == 'eip155') return false;
    return false;
  }

  bool get isEvm => !isSvm;

  /// Personal wallet address to show for deposits on this network.
  /// Never returns a Solana address for EVM networks (and vice versa).
  String depositAddress({
    required String solanaAddress,
    required String ethereumAddress,
  }) {
    if (isEvm) {
      final eth = ethereumAddress.trim();
      // Guard: stale storage may hold a Solana pubkey under the EVM key.
      if (eth.startsWith('0x') || eth.startsWith('0X')) return eth;
      return '';
    }
    return solanaAddress.trim();
  }

  String get displayName {
    final name = chain.name?.trim() ?? '';
    final lower = name.toLowerCase();
    if (lower.contains('solana') && !lower.contains('devnet')) {
      return 'Solana';
    }
    if (lower.contains('ethereum') &&
        !lower.contains('sepolia') &&
        !lower.contains('goerli')) {
      return 'Ethereum';
    }
    if (name.isNotEmpty) return name;
    return key;
  }

  /// Fallback glyph when [chain.icon] is missing.
  String get logoToken {
    if (isSvm) return 'SOL';
    final lower = key.toLowerCase();
    if (lower.contains('bsc') || lower.contains('binance')) return 'BNB';
    if (lower.contains('arbitrum')) return 'ARB';
    return 'ETH';
  }

  /// Local SVG for known EVM networks; null for Solana (uses token fallback).
  String? get assetIcon =>
      resolveWalletNetworkAssetIcon(key, chainName: chain.name);

  /// Tokens available for deposit on this network.
  List<WalletToken> depositTokens({bool hideUsdt = false}) {
    final map = chain.tokens;
    if (map == null || map.isEmpty) return const [];
    final depositSymbols = deposit?.tokens
        ?.map((t) => t.symbol?.toUpperCase())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet();
    final out = <WalletToken>[];
    for (final entry in map.entries) {
      final token = entry.value;
      final symbol = (token.symbol ?? entry.key).toUpperCase();
      if (symbol.isEmpty) continue;
      if (hideUsdt && symbol == 'USDT') continue;
      if (depositSymbols != null &&
          depositSymbols.isNotEmpty &&
          !depositSymbols.contains(symbol)) {
        continue;
      }
      out.add(token);
    }
    return out;
  }

  bool supportsDepositToken(String symbol) {
    final target = symbol.toUpperCase();
    if (target.isEmpty) return false;
    for (final t in depositTokens()) {
      if ((t.symbol ?? '').toUpperCase() == target) return true;
    }
    return false;
  }

  /// Tokens available for withdraw on this network (USDT hidden).
  /// Prefers symbols listed in [withdraw]; falls back to chain tokens.
  List<WalletToken> withdrawTokens() {
    final map = chain.tokens;
    if (map == null || map.isEmpty) return const [];

    final preferred = <String>{};
    final withdrawCfg = withdraw?.tokens;
    if (withdrawCfg != null) {
      for (final t in withdrawCfg) {
        final s = t.symbol?.toUpperCase();
        if (s != null && s.isNotEmpty && s != 'USDT') preferred.add(s);
      }
    }
    // SVM sponsor path also allows STORY from chainlinks even if withdraw
    // config only lists USDC.
    if (isSvm && map.keys.any((k) => k.toUpperCase() == 'STORY')) {
      preferred.add('STORY');
    }

    final out = <WalletToken>[];
    for (final entry in map.entries) {
      final token = entry.value;
      final symbol = (token.symbol ?? entry.key).toUpperCase();
      if (symbol.isEmpty || symbol == 'USDT') continue;
      if (preferred.isNotEmpty && !preferred.contains(symbol)) continue;
      out.add(token);
    }
    return out;
  }

  InitDepositTokenConfig? depositTokenConfig(String symbol) {
    final tokens = deposit?.tokens;
    if (tokens == null) return null;
    final target = symbol.toUpperCase();
    for (final t in tokens) {
      if (t.symbol?.toUpperCase() == target) return t;
    }
    return null;
  }

  InitWithdrawTokenConfig? withdrawTokenConfig(String symbol) {
    final tokens = withdraw?.tokens;
    if (tokens == null) return null;
    final target = symbol.toUpperCase();
    for (final t in tokens) {
      if (t.symbol?.toUpperCase() == target) return t;
    }
    return null;
  }

  String minDepositAmount(String symbol) {
    final cfg = depositTokenConfig(symbol);
    final min = cfg?.min?.trim();
    if (min != null && min.isNotEmpty) return min;
    final tokens = deposit?.tokens;
    if (tokens != null) {
      for (final t in tokens) {
        final m = t.min?.trim();
        if (m != null && m.isNotEmpty) return m;
      }
    }
    return '5';
  }

  /// Effective deposit exchange rate. Missing or `0` → `1` (no haircut).
  double depositExchangeRate(String symbol) {
    final rate = depositTokenConfig(symbol)?.exchangeRate;
    if (rate == null || rate == 0) return 1;
    return rate;
  }

  /// Platform credited amount after applying [depositExchangeRate].
  double creditedDepositAmount(String symbol, double sendAmount) {
    return sendAmount * depositExchangeRate(symbol);
  }

  int depositTokenScale(String symbol) {
    final scale = depositTokenConfig(symbol)?.scale;
    if (scale == null || scale < 0) return 2;
    return scale;
  }

  /// Available-balance display precision from `init.withdraw[].tokens[].scale`.
  /// Falls back to `2` when unset (matches current withdraw UI default).
  int withdrawTokenScale(String symbol) {
    final scale = withdrawTokenConfig(symbol)?.scale;
    if (scale == null || scale < 0) return 2;
    return scale;
  }

  /// Amount-field / Max-fill precision from
  /// `init.withdraw[].tokens[].inputScale`. Falls back to USDC/USDT=5,
  /// STORY=2 when unset.
  int withdrawTokenInputScale(String symbol) {
    final scale = withdrawTokenConfig(symbol)?.inputScale;
    if (scale == null || scale < 0) {
      switch (symbol.trim().toUpperCase()) {
        case 'STORY':
          return 2;
        case 'USDT':
        case 'USDC':
          return 5;
        default:
          return 5;
      }
    }
    return scale;
  }

  @override
  List<Object?> get props => [key, chain, deposit, withdraw];
}

/// Bundles withdraw networks + sponsor API URL for the WithdrawPage.
class WithdrawConfigState extends Equatable {
  final List<WalletNetworkOption> networks;
  final String? sponsorApiUrl;

  const WithdrawConfigState({this.networks = const [], this.sponsorApiUrl});

  ChainInfo? get svmChainInfo {
    for (final n in networks) {
      if (n.isSvm) return n.chain;
    }
    return null;
  }

  /// First EVM chain (legacy consumers / default wallet balance target).
  ChainInfo? get evmChainInfo {
    for (final n in networks) {
      if (n.isEvm) return n.chain;
    }
    return null;
  }

  /// Merged SVM withdraw token configs (USDC / STORY), for legacy helpers.
  List<InitWithdrawTokenConfig>? get tokens {
    WalletNetworkOption? svm;
    for (final n in networks) {
      if (n.isSvm) {
        svm = n;
        break;
      }
    }
    if (svm == null) return null;
    final merged = <InitWithdrawTokenConfig>[];
    final existing = <String>{};
    final cfgTokens = svm.withdraw?.tokens;
    if (cfgTokens != null) {
      for (final t in cfgTokens) {
        final s = t.symbol?.toUpperCase();
        if (s == null || s.isEmpty || s == 'USDT') continue;
        merged.add(t);
        existing.add(s);
      }
    }
    final chainTokens = svm.chain.tokens;
    if (chainTokens != null) {
      for (final entry in chainTokens.entries) {
        final symbol = (entry.value.symbol ?? entry.key).toUpperCase();
        if (symbol.isEmpty || symbol == 'USDT' || existing.contains(symbol)) {
          continue;
        }
        merged.add(InitWithdrawTokenConfig(symbol: entry.key));
        existing.add(symbol);
      }
    }
    return merged.isNotEmpty ? merged : null;
  }

  WalletNetworkOption? byKey(String key) {
    for (final n in networks) {
      if (n.key == key) return n;
    }
    return null;
  }

  @override
  List<Object?> get props => [networks, sponsorApiUrl];
}

InitDepositConfig? _depositForKey(GlobalConfig config, String key) {
  final deposits = config.init?.deposit;
  if (deposits == null) return null;
  for (final d in deposits) {
    if (d.chain == key) return d;
  }
  return null;
}

List<WalletNetworkOption> resolveDepositNetworks(GlobalConfig config) {
  final chainlinks = config.chainlinks;
  final deposits = config.init?.deposit;
  if (chainlinks == null || deposits == null) return const [];
  final out = <WalletNetworkOption>[];
  for (final dep in deposits) {
    final key = dep.chain?.trim();
    if (key == null || key.isEmpty) continue;
    final chain = chainlinks[key];
    if (chain == null) continue;
    out.add(
      WalletNetworkOption(
        key: key,
        chain: chain,
        deposit: dep,
        withdraw: _withdrawForKey(config, key),
      ),
    );
  }
  // Prefer Solana / SVM first regardless of init.deposit array order.
  return [...out.where((n) => n.isSvm), ...out.where((n) => !n.isSvm)];
}

/// Union of deposit tokens across all networks (first-seen icon wins).
List<WalletToken> collectAllDepositTokens(List<WalletNetworkOption> networks) {
  final seen = <String>{};
  final out = <WalletToken>[];
  for (final network in networks) {
    for (final token in network.depositTokens()) {
      final symbol = (token.symbol ?? '').toUpperCase();
      if (symbol.isEmpty || seen.contains(symbol)) continue;
      seen.add(symbol);
      out.add(token);
    }
  }
  return out;
}

InitWithdrawConfig? _withdrawForKey(GlobalConfig config, String key) {
  final list = config.init?.withdraw;
  if (list == null) return null;
  for (final w in list) {
    if (w.chain == key) return w;
  }
  return null;
}

/// Resolves sponsor POST URL from `init.deposit[].api`, falling back to the
/// documented path `/api/nfp/v1/sponsor/{svmChainKey}` when config omits `api`.
String? resolveSponsorApiUrl(GlobalConfig config) {
  final chainlinks = config.chainlinks;
  final deposits = config.init?.deposit;

  String? svmChainKey;
  if (chainlinks != null) {
    for (final entry in chainlinks.entries) {
      if (entry.value.chainType == 'svm') {
        svmChainKey = entry.key;
        break;
      }
    }
  }

  if (deposits != null) {
    for (final dep in deposits) {
      final api = dep.api?.trim();
      if (api == null || api.isEmpty) continue;
      final key = dep.chain;
      if (svmChainKey != null && key == svmChainKey) return api;
      if (dep.chainType == 'svm') return api;
    }
    // Any explicit api (legacy single-entry deposit configs).
    for (final dep in deposits) {
      final api = dep.api?.trim();
      if (api != null && api.isNotEmpty) return api;
    }
  }

  if (svmChainKey != null && svmChainKey.isNotEmpty) {
    return '/api/nfp/v1/sponsor/$svmChainKey';
  }
  return null;
}

List<WalletNetworkOption> resolveWithdrawNetworks(GlobalConfig config) {
  final chainlinks = config.chainlinks;
  final withdrawList = config.init?.withdraw;
  if (chainlinks == null || withdrawList == null) return const [];
  final out = <WalletNetworkOption>[];
  for (final w in withdrawList) {
    final key = w.chain?.trim();
    if (key == null || key.isEmpty) continue;
    final chain = chainlinks[key];
    if (chain == null) continue;
    out.add(
      WalletNetworkOption(
        key: key,
        chain: chain,
        deposit: _depositForKey(config, key),
        withdraw: w,
      ),
    );
  }
  return out;
}

final depositNetworksProvider = Provider.autoDispose<List<WalletNetworkOption>>(
  (ref) {
    final configAsync = ref.watch(globalConfigProvider);
    return configAsync.whenOrNull(
          data: (result) => result.when(
            success: resolveDepositNetworks,
            failure: (_) => const <WalletNetworkOption>[],
          ),
        ) ??
        const [];
  },
);

final withdrawConfigProvider = Provider.autoDispose<WithdrawConfigState>((ref) {
  final configAsync = ref.watch(globalConfigProvider);
  const defaultState = WithdrawConfigState();
  return configAsync.whenOrNull(
        data: (result) => result.when(
          success: (GlobalConfig config) {
            final networks = resolveWithdrawNetworks(config);
            return WithdrawConfigState(
              networks: networks,
              sponsorApiUrl: resolveSponsorApiUrl(config),
            );
          },
          failure: (_) => defaultState,
        ),
      ) ??
      defaultState;
});

/// First deposit config entry (legacy). Prefer [depositNetworksProvider].
final depositConfigProvider = Provider.autoDispose<InitDepositConfig?>((ref) {
  final networks = ref.watch(depositNetworksProvider);
  return networks.isNotEmpty ? networks.first.deposit : null;
});

/// Resolves the SVM chain info (RPC URL + token mint addresses) from the
/// global config, shared by [onChainWalletBalanceProvider].
final svmChainProvider = Provider.autoDispose<ChainInfo?>((ref) {
  final configAsync = ref.watch(globalConfigProvider);
  return configAsync.whenOrNull(
    data: (result) => result.when(
      success: (GlobalConfig config) {
        final chainlinks = config.chainlinks;
        if (chainlinks == null) return null;
        for (final chain in chainlinks.values) {
          if (chain.chainType == 'svm') return chain;
        }
        return null;
      },
      failure: (_) => null,
    ),
  );
});

/// Resolves the first EVM chain from global config chainlinks.
final evmChainProvider = Provider.autoDispose<ChainInfo?>((ref) {
  final configAsync = ref.watch(globalConfigProvider);
  return configAsync.whenOrNull(
    data: (result) => result.when(
      success: (GlobalConfig config) {
        final chainlinks = config.chainlinks;
        if (chainlinks == null) return null;
        for (final chain in chainlinks.values) {
          if (chain.chainType == 'evm') return chain;
        }
        return null;
      },
      failure: (_) => null,
    ),
  );
});
