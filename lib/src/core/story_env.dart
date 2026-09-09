enum StoryEnv {
  development(
    apiBaseUrl: 'https://dev-api-gateway.actqa.com',
    miningApiBaseUrl: 'https://dev-api-gateway.actqa.com',
    cdnBaseUrl: 'https://story.fun',
    webBaseUrl: 'https://onestory-web-test.actqa.com',
    buyStoryUrl: 'https://dev.plato.xyz/trade/spot/01-USDC',
    dreamOsUrl: 'https://www.dreamos.xyz/',
    privyAppId: 'cmpqcyxm100fb0cjxahlg2uer',
    privyAppClientId: 'client-WY6ZaRNKYcmXgRP7MWn9E3bGFWZmbG2RLn3zJ1XSXMGAe',
    privySignerId: 'et3oqten1ix1qn7dzbam4kn2',
    privyEvmPolicyId: 'j3ww1q6itgfyytk4cf8zsv7c',
    privySvmPolicyId: 'g057gi70ijipc9bv460kxage',
    privySuiPolicyId: 'joo2u9o15wdv1xnwe5y7szlm',
    privyTronPolicyId: 'oraj1xsi8qbrg37ltoulkl50',
  ),
  test(
    apiBaseUrl: 'https://test-api-gateway.actqa.com',
    miningApiBaseUrl: 'https://test-api-gateway.actqa.com',
    cdnBaseUrl: 'https://story.fun',
    webBaseUrl: 'https://onestory-web-test.actqa.com',
    buyStoryUrl: 'https://dev.plato.xyz/trade/spot/01-USDC',
    dreamOsUrl: 'https://www.dreamos.xyz/',
    privyAppId: 'cmo0v8iz1002p0djop1bwyfhr',
    privyAppClientId: 'client-WY6YU7g57TvFSysMpZrRzTy5vd7ctTeyMHv26xsY1fyYm',
    initialToken: '',
    privySignerId: 'et3oqten1ix1qn7dzbam4kn2',
    privyEvmPolicyId: 'j3ww1q6itgfyytk4cf8zsv7c',
    privySvmPolicyId: 'g057gi70ijipc9bv460kxage',
    privySuiPolicyId: 'joo2u9o15wdv1xnwe5y7szlm',
    privyTronPolicyId: 'oraj1xsi8qbrg37ltoulkl50',
  ),
  production(
    apiBaseUrl: 'https://api-gateway.story.fun',
    miningApiBaseUrl: 'https://api-gateway.story.fun',
    cdnBaseUrl: 'https://story.fun',
    webBaseUrl: 'https://story.fun',
    buyStoryUrl: 'https://app.plato.xyz/trade/spot/01-USDC',
    dreamOsUrl: 'https://www.dreamos.xyz/',
    privyAppId: 'cmpqttg5q00fp0cjv77r7n750',
    privyAppClientId: 'client-WY6ZaS92gpujKy9E6RucxV8SwRffkQquYytU4cg3PndRB',
    privySignerId: 'vppnblwevdv8z4s96b7wox3a',
    privyEvmPolicyId: 'tun0fx75h9mv6gmu4jr39zhl',
    privySvmPolicyId: 'qtlisg094efjjhtdw28uomgb',
    privySuiPolicyId: 'nuec610z9542yyasuqcfysm9',
    privyTronPolicyId: 'tvb69za6orpp62k9eaig2q20',
  );

  final String apiBaseUrl;
  final String miningApiBaseUrl;
  final String cdnBaseUrl;
  final String webBaseUrl;

  /// 侧边栏「交易 STORY」外链（Plato）。
  final String buyStoryUrl;

  /// DreamOS 创作者平台外链。
  final String dreamOsUrl;
  final String privyAppId;
  final String privyAppClientId;
  final String? initialToken;

  /// Privy session signer / key quorum (ID1 → [SignerInput.signerId]).
  final String privySignerId;

  /// Chain-scoped Privy policy (ID2 → [SignerInput.policyIds]).
  final String privyEvmPolicyId;
  final String privySvmPolicyId;
  final String privySuiPolicyId;
  final String privyTronPolicyId;

  const StoryEnv({
    required this.apiBaseUrl,
    required this.miningApiBaseUrl,
    required this.cdnBaseUrl,
    required this.webBaseUrl,
    required this.buyStoryUrl,
    required this.dreamOsUrl,
    required this.privyAppId,
    required this.privyAppClientId,
    this.initialToken,
    required this.privySignerId,
    required this.privyEvmPolicyId,
    required this.privySvmPolicyId,
    required this.privySuiPolicyId,
    required this.privyTronPolicyId,
  });

  bool get isProduction => this == StoryEnv.production;
  bool get isDevelopment => this == StoryEnv.development;
  bool get isTest => this == StoryEnv.test;

  /// 白皮书页面地址。
  String get whitepaperUrl => '$webBaseUrl/whitepaper';

  /// 法律文档固定站点（任意环境均走官网）。
  static const String legalSiteBaseUrl = 'https://story.fun';

  /// 服务条款公开页。任意环境均为 `https://story.fun/terms?lang=…`。
  String termsOfServiceUrl({String lang = 'en'}) =>
      '$legalSiteBaseUrl/terms?lang=$lang';

  /// 隐私政策公开页。任意环境均为 `https://story.fun/privacy?lang=…`。
  String privacyPolicyUrl({String lang = 'en'}) =>
      '$legalSiteBaseUrl/privacy?lang=$lang';

  /// 短剧分享页地址（与 Web `/play/:id` 路由对齐）。
  String dramaShareUrl(String dramaId) => '$webBaseUrl/play/$dramaId';

  /// Solscan explorer base URL.
  static const String solscanBaseUrl = 'https://solscan.io/account';

  /// Solscan 交易 explorer 基础 URL。
  static const String solscanTxBaseUrl = 'https://solscan.io/tx';

  /// 交易 explorer 链接。生产环境链接 devnet 时自动追加 `?cluster=devnet`。
  String txExplorerUrl(String txHash) {
    final cluster = isProduction ? '' : '?cluster=devnet';
    return '$solscanTxBaseUrl/$txHash$cluster';
  }

  /// Stamp avatar CDN base URL.
  static const String stampCdnBaseUrl = 'https://cdn.stamp.fyi/avatar';

  /// Invite link base URL.
  static const String inviteBaseUrl = 'https://onestory.io/invite';
}
