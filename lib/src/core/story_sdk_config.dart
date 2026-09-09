import 'story_env.dart';

class StorySdkConfig {
  final StoryEnv env;
  final String? apiBaseUrl;
  final String? miningApiBaseUrl;
  final String? cdnBaseUrl;
  final String? privyAppId;
  final String? privyAppClientId;
  final String? initialToken;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableApiRetry;
  final int apiMaxRetries;

  const StorySdkConfig({
    this.env = StoryEnv.test,
    this.apiBaseUrl,
    this.miningApiBaseUrl,
    this.cdnBaseUrl,
    this.privyAppId,
    this.privyAppClientId,
    this.initialToken,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
    this.enableApiRetry = true,
    this.apiMaxRetries = 3,
  });

  String get effectiveApiBaseUrl => apiBaseUrl ?? env.apiBaseUrl;
  String get effectiveMiningApiBaseUrl =>
      miningApiBaseUrl ?? env.miningApiBaseUrl;
  String get effectiveCdnBaseUrl => cdnBaseUrl ?? env.cdnBaseUrl;
  String get effectivePrivyAppId => privyAppId ?? env.privyAppId;
  String get effectivePrivyAppClientId =>
      privyAppClientId ?? env.privyAppClientId;
  String? get effectiveInitialToken => initialToken ?? env.initialToken;

  StorySdkConfig copyWith({
    StoryEnv? env,
    String? apiBaseUrl,
    String? miningApiBaseUrl,
    String? cdnBaseUrl,
    String? privyAppId,
    String? privyAppClientId,
    String? initialToken,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool? enableApiRetry,
    int? apiMaxRetries,
  }) => StorySdkConfig(
    env: env ?? this.env,
    apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
    miningApiBaseUrl: miningApiBaseUrl ?? this.miningApiBaseUrl,
    cdnBaseUrl: cdnBaseUrl ?? this.cdnBaseUrl,
    privyAppId: privyAppId ?? this.privyAppId,
    privyAppClientId: privyAppClientId ?? this.privyAppClientId,
    initialToken: initialToken ?? this.initialToken,
    connectTimeout: connectTimeout ?? this.connectTimeout,
    receiveTimeout: receiveTimeout ?? this.receiveTimeout,
    enableApiRetry: enableApiRetry ?? this.enableApiRetry,
    apiMaxRetries: apiMaxRetries ?? this.apiMaxRetries,
  );

  static const StorySdkConfig development = StorySdkConfig(
    env: StoryEnv.development,
  );
  // ignore: avoid_redundant_argument_values — explicit env: test for clarity
  static const StorySdkConfig test = StorySdkConfig(env: StoryEnv.test);
  static const StorySdkConfig production = StorySdkConfig(
    env: StoryEnv.production,
  );
}
