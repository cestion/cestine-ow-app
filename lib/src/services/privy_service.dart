import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:privy_flutter/privy_flutter.dart';

import '../core/story_logger.dart';
import '../core/story_sdk_config.dart';
import '../data/repository/story_local_repository.dart';
import '../utils/validators.dart';

/// Outcome of probing the native Privy session.
///
/// Distinguishes a definitive logout from transient/offline failures so cold
/// start does not wipe a still-valid platform JWT.
enum PrivySessionStatus {
  /// Privy reports an authenticated user.
  authenticated,

  /// Privy definitively reports no user (logged out / session expired).
  unauthenticated,

  /// Cannot decide yet (SDK not ready, init failed, transport/offline error).
  unknown,
}

class PrivyService {
  Privy? _privy;
  bool _initialized = false;
  String? _lastError;
  Future<void>? _initFuture;
  StorySdkConfig? _config;
  StoryLocalRepository? _localRepo;
  Future<({bool success, String? error})>? _ensureSignersFuture;
  final Set<String> _provisionedSignerKeys = <String>{};

  static const _signerHivePrefix = 'privy_signer_';

  /// Marker returned in [verifyEmailCode.error] / [getCurrentAccessToken.error]
  /// when access-token retrieval fails. The UI maps this via `AppLocalizations`.
  static const getTokenFailedErrorKey = 'loginGetTokenFailed';

  /// Marker returned in [verifyEmailCode.error] when OTP verification fails
  /// with HTTP 422 / `invalid_credentials`. The UI layer maps this constant
  /// to the localized "Verification failed" string via `AppLocalizations`.
  static const invalidCredentialsErrorKey = 'loginVerificationFailed';

  /// Marker for transport / TLS / connectivity failures. UI maps to
  /// [AppLocalizations.errorNetwork].
  static const networkErrorKey = 'errorNetwork';

  /// Marker when Privy native session is missing/expired while the app may
  /// still hold a platform JWT. UI maps to [AppLocalizations.authSessionExpired].
  static const sessionExpiredErrorKey = 'authSessionExpired';

  /// Marker when Privy SDK is not initialized / unavailable. UI maps to
  /// [AppLocalizations.loginPrivyUnavailable].
  static const unavailableErrorKey = 'loginPrivyUnavailable';

  /// Marker when sending an email OTP fails with a non-network Privy error
  /// (e.g. Android "Something went wrong"). UI maps to
  /// [AppLocalizations.loginSendCodeFailed].
  static const sendCodeFailedErrorKey = 'loginSendCodeFailed';

  /// Marker when Privy rate-limits OTP send/verify. UI maps to
  /// [AppLocalizations.loginTooManyRequests].
  static const tooManyRequestsErrorKey = 'loginTooManyRequests';

  /// Whether [message] looks like a raw transport/TLS failure unsuitable for UI.
  static bool looksLikeTransportFailure(String message) {
    final m = message.toLowerCase();
    return m.contains('handshakeexception') ||
        m.contains('socketexception') ||
        m.contains('tlsexception') ||
        m.contains('certificate_verify_failed') ||
        m.contains('hostname mismatch') ||
        m.contains('failed host lookup') ||
        m.contains('network is unreachable') ||
        m.contains('connection refused') ||
        m.contains('connection reset') ||
        m.contains('clientexception') ||
        m.contains('an unknown error occurred') ||
        (m.contains('timeout') && m.contains('exception'));
  }

  /// Whether [message] indicates Privy has no authenticated user.
  ///
  /// Android `getUser()` throws `PrivyException: User is not authenticated`
  /// instead of returning null; iOS typically returns null → [sessionExpiredErrorKey].
  static bool looksLikeUnauthenticated(String message) {
    final m = message.toLowerCase();
    return m.contains('not authenticated') ||
        m.contains('user_not_found') ||
        m.contains('unauthenticated') ||
        message == '未登录' ||
        message == sessionExpiredErrorKey;
  }

  Privy? get privy => _privy;
  bool get isInitialized => _initialized;
  bool get isAvailable => _initialized && _privy != null;
  String? get lastError => _lastError;

  Future<void> initialize(
    StorySdkConfig config, {
    StoryLocalRepository? localRepository,
  }) {
    // Coalesce concurrent callers onto the same init future so the SDK can
    // kick this off in the background without blocking cold start; auth
    // methods below await it before use.
    _localRepo ??= localRepository;
    return _initFuture ??= _initializeImpl(config);
  }

  Future<void> _initializeImpl(StorySdkConfig config) async {
    if (_initialized) return;
    final sdkConfig = config;
    _config = sdkConfig;
    try {
      _privy = Privy.init(
        config: PrivyConfig(
          appId: sdkConfig.effectivePrivyAppId,
          appClientId: sdkConfig.effectivePrivyAppClientId,
        ),
      );
      await _privy!.getAuthState();
      _initialized = true;
      StoryLogger.i(
        'PrivyService initialized (appId=${sdkConfig.effectivePrivyAppId})',
        tag: 'Privy',
      );
    } on MissingPluginException catch (_) {
      // Keep detailed cause in logs; return a stable l10n key to the UI.
      _lastError = unavailableErrorKey;
      StoryLogger.w(
        'Privy native plugin missing — rebuild the app '
        '(flutter clean && flutter run)',
        tag: 'Privy',
      );
      _privy = null;
    } catch (e, st) {
      _lastError = unavailableErrorKey;
      StoryLogger.e(
        'Privy init failed',
        error: e,
        stackTrace: st,
        tag: 'Privy',
      );
      _privy = null;
    }
  }

  Future<({bool success, String? error})> sendEmailCode(String email) async {
    if (!await _ensureReadyAsync()) {
      return (success: false, error: _lastError ?? unavailableErrorKey);
    }
    final result = await _privy!.email.sendCode(email);
    var ok = false;
    String? err;
    switch (result) {
      case Success():
        ok = true;
      case Failure(:final error):
        err = _mapSendCodeError(error.message);
    }
    return (success: ok, error: err);
  }

  Future<({bool success, String? privyToken, String? error})> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    if (!await _ensureReadyAsync()) {
      return (
        success: false,
        privyToken: null,
        error: _lastError ?? unavailableErrorKey,
      );
    }
    final loginResult = await _privy!.email.loginWithCode(
      code: code,
      email: email,
    );
    var ok = false;
    String? token;
    String? err;
    switch (loginResult) {
      case Success(:final value):
        final tokenResult = await value.getAccessToken();
        switch (tokenResult) {
          case Success(:final value):
            ok = true;
            token = value;
          case Failure(:final error):
            StoryLogger.w(
              'getAccessToken after loginWithCode failed: ${error.message}',
              tag: 'Privy',
            );
            err = getTokenFailedErrorKey;
        }
      case Failure(:final error):
        err = _mapVerifyError(error.message);
    }
    return (success: ok, privyToken: token, error: err);
  }

  /// Resolves the native Privy session without treating "unreachable" as logout.
  ///
  /// Aligns with web's split: platform JWT owns page login; Privy gates chain ops.
  Future<PrivySessionStatus> resolveSessionStatus() async {
    if (!await _ensureReadyAsync()) {
      // Init / plugin failure — not proof the user signed out.
      return PrivySessionStatus.unknown;
    }
    try {
      final authState = await _privy!.getAuthState();
      return switch (authState) {
        Authenticated() => PrivySessionStatus.authenticated,
        Unauthenticated() => PrivySessionStatus.unauthenticated,
        // NotReady / AuthenticatedUnverified: wait — do not clear JWT.
        _ => PrivySessionStatus.unknown,
      };
    } catch (e, st) {
      StoryLogger.w(
        'getAuthState failed while checking session',
        error: e,
        stackTrace: st,
        tag: 'Privy',
      );
      try {
        final user = await _privy!.getUser();
        return user != null
            ? PrivySessionStatus.authenticated
            : PrivySessionStatus.unauthenticated;
      } catch (e2) {
        final message = e2.toString();
        if (looksLikeUnauthenticated(message)) {
          return PrivySessionStatus.unauthenticated;
        }
        StoryLogger.w(
          'getUser fallback failed while checking session',
          error: e2,
          tag: 'Privy',
        );
        // Transport / unknown errors → keep local session.
        return PrivySessionStatus.unknown;
      }
    }
  }

  /// Whether the Privy SDK currently has an authenticated user session.
  ///
  /// Prefer [resolveSessionStatus] when offline/unknown must be distinguished.
  /// Returns `false` for both [PrivySessionStatus.unauthenticated] and
  /// [PrivySessionStatus.unknown].
  Future<bool> isSessionAuthenticated() async {
    return await resolveSessionStatus() == PrivySessionStatus.authenticated;
  }

  /// Returns a fresh access token for the current Privy session.
  Future<({bool success, String? privyToken, String? error})>
  getCurrentAccessToken() async {
    if (!await _ensureReadyAsync()) {
      return (
        success: false,
        privyToken: null,
        error: _lastError ?? unavailableErrorKey,
      );
    }
    try {
      final user = await _privy!.getUser();
      if (user == null) {
        return (
          success: false,
          privyToken: null,
          error: sessionExpiredErrorKey,
        );
      }
      final tokenResult = await user.getAccessToken();
      switch (tokenResult) {
        case Success(:final value):
          return (success: true, privyToken: value, error: null);
        case Failure(:final error):
          StoryLogger.w(
            'getCurrentAccessToken failed: ${error.message}',
            tag: 'Privy',
          );
          return (
            success: false,
            privyToken: null,
            error: getTokenFailedErrorKey,
          );
      }
    } catch (e) {
      final message = e.toString();
      return (
        success: false,
        privyToken: null,
        error: looksLikeUnauthenticated(message)
            ? sessionExpiredErrorKey
            : (looksLikeTransportFailure(message) ? networkErrorKey : message),
      );
    }
  }

  /// Whether [message] looks like a Privy OTP / email-code rejection.
  ///
  /// Privy Flutter often flattens errors to either structured snippets
  /// (`httpCode: 422`, `errorCode: invalid_credentials`) or plain English
  /// (`Invalid email and code combination`). Match both so the UI can show
  /// [AppLocalizations.loginVerificationFailed] instead of raw English.
  static bool looksLikeInvalidOtpCredentials(String message) {
    final m = message.toLowerCase();
    return m.contains('httpcode: 422') ||
        m.contains('invalid_credentials') ||
        m.contains('invalid email and code') ||
        m.contains('invalid email or code') ||
        m.contains('invalid code') ||
        m.contains('incorrect code') ||
        m.contains('wrong code') ||
        m.contains('code has expired') ||
        m.contains('expired code') ||
        m.contains('verification code is invalid') ||
        m.contains('otp is invalid');
  }

  /// Whether [message] is a generic Privy failure (common on Android sendCode).
  static bool looksLikeGenericPrivyFailure(String message) {
    final m = message.toLowerCase().trim();
    return m == 'something went wrong' ||
        m.contains('something went wrong') ||
        m.contains('an unknown error occurred') ||
        m.contains('unknown error') ||
        m.contains('internal error');
  }

  /// Whether [message] is a Privy OTP rate-limit / 429 style rejection.
  static bool looksLikeTooManyRequests(String message) {
    final m = message.toLowerCase();
    return m.contains('too many requests') ||
        m.contains('httpcode: 429') ||
        m.contains('status code of 429') ||
        m.contains('rate limit') ||
        m.contains('rate_limit') ||
        m.contains('please wait to try again') ||
        m.contains('wait before trying again');
  }

  /// Maps a raw Privy [message] for email sendCode failures.
  String _mapSendCodeError(String message) {
    if (looksLikeTransportFailure(message)) {
      return networkErrorKey;
    }
    if (looksLikeTooManyRequests(message)) {
      return tooManyRequestsErrorKey;
    }
    if (looksLikeGenericPrivyFailure(message)) {
      return sendCodeFailedErrorKey;
    }
    // Leave unknown text intact so QA / logs can drive new mappings.
    return message;
  }

  /// Maps a raw Privy [message] to a stable error key for OTP verify failures.
  String _mapVerifyError(String message) {
    if (looksLikeInvalidOtpCredentials(message)) {
      return invalidCredentialsErrorKey;
    }
    if (looksLikeTransportFailure(message)) {
      return networkErrorKey;
    }
    if (looksLikeTooManyRequests(message)) {
      return tooManyRequestsErrorKey;
    }
    if (looksLikeGenericPrivyFailure(message)) {
      return invalidCredentialsErrorKey;
    }
    // Leave unknown text intact so QA / logs can drive new mappings.
    return message;
  }

  Future<({bool success, String? address, String? error})>
  ensureSolanaWallet() async {
    if (!await _ensureReadyAsync()) {
      return (
        success: false,
        address: null,
        error: _lastError ?? unavailableErrorKey,
      );
    }
    try {
      final u = await _privy!.getUser();
      if (u == null) {
        return (success: false, address: null, error: sessionExpiredErrorKey);
      }
      if (u.embeddedSolanaWallets.isEmpty) {
        final createResult = await u.createSolanaWallet();
        var addr2 = '';
        var ok2 = false;
        var err2 = '';
        createResult.fold(
          onSuccess: (w) {
            ok2 = true;
            addr2 = w.address;
          },
          onFailure: (e) {
            err2 = looksLikeUnauthenticated(e.message)
                ? sessionExpiredErrorKey
                : (looksLikeTransportFailure(e.message)
                      ? networkErrorKey
                      : e.message);
          },
        );
        return (
          success: ok2,
          address: ok2 ? addr2 : null,
          error: ok2 ? null : err2,
        );
      }
      final addr = u.embeddedSolanaWallets.first.address;
      return (success: true, address: addr, error: null);
    } catch (e) {
      final message = e.toString();
      return (
        success: false,
        address: null,
        error: looksLikeUnauthenticated(message)
            ? sessionExpiredErrorKey
            : (looksLikeTransportFailure(message) ? networkErrorKey : message),
      );
    }
  }

  Future<({bool success, String? address, String? error})>
  ensureEthereumWallet() async {
    if (!await _ensureReadyAsync()) {
      return (
        success: false,
        address: null,
        error: _lastError ?? unavailableErrorKey,
      );
    }
    try {
      final u = await _privy!.getUser();
      if (u == null) {
        return (success: false, address: null, error: sessionExpiredErrorKey);
      }

      // Some accounts expose a non-0x address under ethereumWallet (e.g. a
      // Solana pubkey). Never treat those as EVM deposit addresses.
      final existing = _firstValidEthereumWallet(u.embeddedEthereumWallets);
      if (existing != null) {
        return (success: true, address: existing.address, error: null);
      }

      final malformed = u.embeddedEthereumWallets
          .map((w) => w.address)
          .where((a) => a.trim().isNotEmpty)
          .toList();
      if (malformed.isNotEmpty) {
        StoryLogger.w(
          'embeddedEthereumWallets has no valid 0x address '
          '(found: ${malformed.join(", ")}); creating additional Ethereum wallet',
          tag: 'Privy',
        );
      }

      final createResult = await u.createEthereumWallet(
        allowAdditional: malformed.isNotEmpty,
      );
      var addr2 = '';
      var ok2 = false;
      var err2 = '';
      createResult.fold(
        onSuccess: (w) {
          ok2 = true;
          addr2 = w.address;
        },
        onFailure: (e) {
          err2 = looksLikeUnauthenticated(e.message)
              ? sessionExpiredErrorKey
              : (looksLikeTransportFailure(e.message)
                    ? networkErrorKey
                    : e.message);
        },
      );
      if (!ok2) {
        return (success: false, address: null, error: err2);
      }
      if (!isValidEthereumAddress(addr2)) {
        StoryLogger.w(
          'createEthereumWallet returned non-0x address: $addr2',
          tag: 'Privy',
        );
        return (
          success: false,
          address: null,
          error: 'invalid ethereum wallet address',
        );
      }
      return (success: true, address: addr2, error: null);
    } catch (e) {
      final message = e.toString();
      return (
        success: false,
        address: null,
        error: looksLikeUnauthenticated(message)
            ? sessionExpiredErrorKey
            : (looksLikeTransportFailure(message) ? networkErrorKey : message),
      );
    }
  }

  /// First embedded Ethereum wallet whose address is a valid `0x` EOA.
  static EmbeddedEthereumWallet? _firstValidEthereumWallet(
    List<EmbeddedEthereumWallet> wallets,
  ) {
    for (final w in wallets) {
      if (isValidEthereumAddress(w.address)) return w;
    }
    return null;
  }

  /// Adds Privy session signers (ID1 + chain policy ID2) on Solana / EVM wallets.
  ///
  /// Called when entering deposit / withdraw so the backend can execute
  /// delegated transactions. See:
  /// https://docs.privy.io/wallets/using-wallets/signers/add-signers
  Future<({bool success, String? error})> ensureWalletSigners() {
    return _ensureSignersFuture ??= _ensureWalletSignersImpl().whenComplete(() {
      _ensureSignersFuture = null;
    });
  }

  Future<({bool success, String? error})> _ensureWalletSignersImpl() async {
    if (!await _ensureReadyAsync()) {
      return (success: false, error: _lastError ?? unavailableErrorKey);
    }
    final env = _config?.env;
    if (env == null) {
      return (success: false, error: unavailableErrorKey);
    }

    final svm = await ensureSolanaWallet();
    if (!svm.success) {
      return (success: false, error: svm.error ?? sessionExpiredErrorKey);
    }
    final evm = await ensureEthereumWallet();
    if (!evm.success) {
      return (success: false, error: evm.error ?? sessionExpiredErrorKey);
    }

    try {
      final user = await _privy!.getUser();
      if (user == null) {
        return (success: false, error: sessionExpiredErrorKey);
      }

      String? lastError;
      var anyOk = false;

      if (user.embeddedSolanaWallets.isNotEmpty) {
        final ok = await _addSignerWithRetry(
          label: 'SVM',
          wallet: user.embeddedSolanaWallets.first,
          signer: SignerInput(
            signerId: env.privySignerId,
            policyIds: [env.privySvmPolicyId],
          ),
        );
        if (ok.success) {
          anyOk = true;
        } else {
          lastError = ok.error;
        }
      }

      // Privy rate-limits consecutive addSigner calls (429). Space EVM out.
      final evmWallet = _firstValidEthereumWallet(user.embeddedEthereumWallets);
      if (evmWallet != null) {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        final ok = await _addSignerWithRetry(
          label: 'EVM',
          wallet: evmWallet,
          signer: SignerInput(
            signerId: env.privySignerId,
            policyIds: [env.privyEvmPolicyId],
          ),
          // Dashboard EVM policy must be chain_type=ethereum. If the configured
          // ID2 is wrong/mismatched, still attach the key quorum without policy.
          allowSignerOnlyFallback: true,
        );
        if (ok.success) {
          anyOk = true;
        } else {
          lastError = ok.error;
        }
      } else if (user.embeddedEthereumWallets.isNotEmpty) {
        StoryLogger.w(
          'Skipping EVM addSigner: no valid 0x wallet '
          '(found: ${user.embeddedEthereumWallets.map((w) => w.address).join(", ")})',
          tag: 'Privy',
        );
      }

      if (anyOk && lastError == null) return (success: true, error: null);
      if (anyOk) {
        // Partial success (e.g. SVM ok, EVM still rate-limited after retries).
        StoryLogger.w(
          'Wallet signers partially applied: $lastError',
          tag: 'Privy',
        );
        return (success: true, error: lastError);
      }
      return (success: false, error: lastError ?? 'addSigners failed');
    } catch (e, st) {
      final message = e.toString();
      StoryLogger.e(
        'ensureWalletSigners failed',
        error: e,
        stackTrace: st,
        tag: 'Privy',
      );
      return (
        success: false,
        error: looksLikeUnauthenticated(message)
            ? sessionExpiredErrorKey
            : (looksLikeTransportFailure(message) ? networkErrorKey : message),
      );
    }
  }

  Future<({bool success, String? error})> _addSignerWithRetry({
    required String label,
    required EmbeddedWallet wallet,
    required SignerInput signer,
    int maxAttempts = 4,
    bool allowSignerOnlyFallback = false,
  }) async {
    final cacheKey = _signerCacheKey(
      wallet.address,
      signer.signerId,
      signer.policyIds?.isNotEmpty == true ? signer.policyIds!.first : null,
    );
    if (_isSignerProvisioned(cacheKey)) {
      StoryLogger.d(
        '$label signers already provisioned (cached)',
        tag: 'Privy',
      );
      return (success: true, error: null);
    }

    String? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final result = await wallet.addSigner(signer);
      switch (result) {
        case Success():
          _markSignerProvisioned(cacheKey);
          StoryLogger.i('Added $label wallet signers', tag: 'Privy');
          return (success: true, error: null);
        case Failure(:final error):
          final message = error.message;
          if (_isAlreadyAddedSignerError(message)) {
            _markSignerProvisioned(cacheKey);
            StoryLogger.d('$label signers already present', tag: 'Privy');
            return (success: true, error: null);
          }
          lastError = message;
          if (looksLikeTooManyRequests(message) && attempt < maxAttempts) {
            final delayMs = 1500 * attempt;
            StoryLogger.w(
              '$label addSigner rate-limited (attempt $attempt/$maxAttempts), '
              'retry in ${delayMs}ms',
              tag: 'Privy',
            );
            await Future<void>.delayed(Duration(milliseconds: delayMs));
            continue;
          }
          // Policy chain_type mismatch → retry with signerId only (policy optional).
          if (allowSignerOnlyFallback &&
              signer.policyIds?.isNotEmpty == true &&
              _looksLikePolicyChainMismatch(message)) {
            StoryLogger.w(
              '$label policy chain_type mismatch for '
              '${signer.policyIds!.first}; retrying signer-only '
              '(check Dashboard: EVM policy must use chain_type=ethereum)',
              tag: 'Privy',
            );
            return _addSignerWithRetry(
              label: label,
              wallet: wallet,
              signer: SignerInput(signerId: signer.signerId),
              maxAttempts: maxAttempts,
            );
          }
          StoryLogger.w('Failed to add $label signers: $message', tag: 'Privy');
          return (success: false, error: message);
      }
    }
    return (success: false, error: lastError ?? 'addSigners failed');
  }

  static bool _looksLikePolicyChainMismatch(String message) {
    final lower = message.toLowerCase();
    return lower.contains('chain_type') &&
        (lower.contains('does not match') || lower.contains('mismatch'));
  }

  static String _signerCacheKey(
    String address,
    String signerId,
    String? policyId,
  ) => '${address.toLowerCase()}|$signerId|${policyId ?? ''}';

  bool _isSignerProvisioned(String cacheKey) {
    if (_provisionedSignerKeys.contains(cacheKey)) return true;
    final local = _localRepo;
    if (local == null) return false;
    try {
      final cached = local.cacheBox.get('$_signerHivePrefix$cacheKey') == true;
      if (cached) _provisionedSignerKeys.add(cacheKey);
      return cached;
    } catch (_) {
      return false;
    }
  }

  void _markSignerProvisioned(String cacheKey) {
    _provisionedSignerKeys.add(cacheKey);
    final local = _localRepo;
    if (local == null) return;
    try {
      local.cacheBox.put('$_signerHivePrefix$cacheKey', true);
    } catch (_) {
      // Memory cache still avoids repeat calls this session.
    }
  }

  static bool _isAlreadyAddedSignerError(String message) {
    final m = message.toLowerCase();
    return m.contains('duplicate signer') ||
        m.contains('already been added') ||
        m.contains('already added') ||
        (m.contains('invalid_data') && m.contains('duplicate'));
  }

  Future<({bool success, String? txHash, String? error})>
  sendEthereumTransaction({
    required String from,
    required String to,
    required String data,
    required int chainId,
    String value = '0x0',
  }) async {
    if (!await _ensureReadyAsync()) {
      return (
        success: false,
        txHash: null,
        error: _lastError ?? unavailableErrorKey,
      );
    }
    try {
      final u = await _privy!.getUser();
      if (u == null) {
        return (success: false, txHash: null, error: sessionExpiredErrorKey);
      }
      if (u.embeddedEthereumWallets.isEmpty) {
        return (success: false, txHash: null, error: sessionExpiredErrorKey);
      }
      final wallet = u.embeddedEthereumWallets.first;
      final txJson = jsonEncode({
        'from': from,
        'to': to,
        'data': data,
        'value': value,
        'chainId': '0x${chainId.toRadixString(16)}',
      });
      final rpcResult = await wallet.provider.request(
        EthereumRpcRequest.ethSendTransaction(txJson),
      );
      String? hash;
      String? err;
      rpcResult.fold(
        onSuccess: (resp) => hash = resp.data,
        onFailure: (e) {
          err = looksLikeUnauthenticated(e.message)
              ? sessionExpiredErrorKey
              : (looksLikeTransportFailure(e.message)
                    ? networkErrorKey
                    : e.message);
        },
      );
      if (hash != null && hash!.isNotEmpty) {
        return (success: true, txHash: hash, error: null);
      }
      return (
        success: false,
        txHash: null,
        error: err ?? 'eth_sendTransaction failed',
      );
    } catch (e) {
      final message = e.toString();
      return (
        success: false,
        txHash: null,
        error: looksLikeUnauthenticated(message)
            ? sessionExpiredErrorKey
            : (looksLikeTransportFailure(message) ? networkErrorKey : message),
      );
    }
  }

  Future<void> logout() async {
    _provisionedSignerKeys.clear();
    if (!await _ensureReadyAsync()) return;
    try {
      await _privy!.logout();
    } catch (e, st) {
      StoryLogger.w(
        'Privy logout failed',
        error: e,
        stackTrace: st,
        tag: 'Privy',
      );
    }
  }

  bool _ensureReady() {
    if (_initialized && _privy != null) return true;
    _lastError ??= unavailableErrorKey;
    return false;
  }

  /// Await background initialization (if any) before checking readiness.
  Future<bool> _ensureReadyAsync() async {
    final init = _initFuture;
    if (init != null) {
      try {
        await init;
      } catch (_) {
        // _initializeImpl already recorded _lastError.
      }
    }
    return _ensureReady();
  }
}
