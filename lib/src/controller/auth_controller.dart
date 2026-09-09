import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode, visibleForTesting;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_logger.dart';
import '../data/repository/story_local_repository.dart';
import '../foundation/auth_provider.dart';
import '../model/models.dart';
import '../repositories/user_repository.dart';
import '../services/privy_service.dart';
import '../utils/validators.dart';
import 'auth_state.dart';
import 'follow_action_controller.dart';
import 'provider/auth_repository_provider.dart';
import 'feed_tracking_service.dart';

/// Result of gating a chain op on Privy + platform JWT.
enum PrivySessionGate {
  /// Platform JWT and Privy session are both ready.
  ready,

  /// Privy is definitively gone; local session was cleared — re-login required.
  needsReauth,

  /// Privy could not be verified (offline / not ready). JWT was kept.
  temporarilyUnavailable,
}

/// Riverpod Notifier managing authentication state.
///
/// Replaces the legacy ChangeNotifier-based AuthController with a modern
/// immutable-state Notifier that integrates cleanly with Riverpod's lifecycle.
class AuthController extends Notifier<AuthState> implements StoryAuthProvider {
  /// Marker when OTP is submitted before [sendOtp]. UI maps via AppLocalizations.
  static const needCodeFirstErrorKey = 'loginNeedCodeFirst';

  /// Marker when Privy embedded wallet creation fails. UI maps via AppLocalizations.
  static const createWalletFailedErrorKey = 'loginCreateWalletFailed';

  @override
  AuthState build() {
    final config = ref.read(storySdkConfigProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final localRepo = ref.read(localRepositoryProvider);
    final privy = ref.read(privyServiceProvider);

    _userRepo = userRepo;
    _localRepo = localRepo;
    _privy = privy;
    _initialToken = config.effectiveInitialToken;

    // Optimistic session from local cache (token warmed in StorySdk.init).
    // Drawer / avatar can show logged-in UI immediately; Privy is verified in
    // [_restore]. Only a definitive Privy unauthenticated clears the session.
    final optimistic = _optimisticSessionFromCache();

    // Start token restoration asynchronously.
    // The `ready` field in state allows callers to await restoration.
    Future.microtask(() async {
      if (optimistic != null && !_authChanges.isClosed) {
        _authChanges.add(true);
      }
      await _restore();
    });

    ref.onDispose(() {
      _authChanges.close();
    });

    return optimistic ?? const AuthState();
  }

  late final UserRepository _userRepo;
  late final StoryLocalRepository _localRepo;
  late final PrivyService _privy;
  late final String? _initialToken;

  final StreamController<bool> _authChanges =
      StreamController<bool>.broadcast();

  // ─── StoryAuthProvider interface ─────────────────────────────────────────

  @override
  String? get accessToken => state.token;

  @override
  String? get userId => state.userId;

  @override
  Stream<bool> get authStateChanges => _authChanges.stream;

  @override
  bool get isLoggedIn => state.isLoggedIn;

  // ─── Convenience getters (backward-compatible) ──────────────────────────

  /// Whether a login/OTP operation is in progress.
  bool get isLogging => state.isLogging;

  /// Whether a logout operation is in progress.
  bool get isLoggingOut => state.isLoggingOut;

  /// Currently logged-in user profile, or null.
  UserProfile? get profile => state.profile;

  /// Email used for the current OTP verification flow.
  String get pendingEmail => state.pendingEmail;

  /// Connected Solana wallet address.
  String get solanaAddress => state.effectiveSolanaAddress;

  /// Connected EVM (Ethereum) wallet address.
  String get ethereumAddress => state.ethereumAddress;

  /// Completes when the initial token restoration is finished.
  /// Awaiting this ensures the in-memory token is available before making
  /// authenticated requests.
  Future<void> get ready => _readyCompleter.future;
  final Completer<void> _readyCompleter = Completer<void>();

  /// Manually complete the ready future for testing purposes.
  ///
  /// In tests, subclasses override [build] without calling [_restore], so
  /// [_readyCompleter] is never completed. This method allows test mocks
  /// to unblock code that awaits [ready] (e.g. [ensureLoggedInOrRedirect]).
  @visibleForTesting
  void completeReady() {
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  /// Provisional logged-in state from local JWT + Hive profile (no Privy yet).
  AuthState? _optimisticSessionFromCache() {
    final token = _localRepo.cachedToken;
    if (token == null || token.isEmpty) return null;
    return AuthState(
      isLoggedIn: true,
      token: token,
      profile: _localRepo.getUser(),
    );
  }

  // ─── Token restoration ──────────────────────────────────────────────────

  Future<void> _restore() async {
    try {
      // User session wins over config.initialToken. The latter is only a dev
      // fallback when nothing has been persisted (e.g. first install).
      final persisted = await _localRepo.getTokenAsync();
      if (!ref.mounted) return;

      final hasPersisted = persisted != null && persisted.isNotEmpty;
      final t = hasPersisted ? persisted : _initialToken;

      UserProfile? profile;
      if (t != null && t.isNotEmpty) {
        // Real user sessions prefer a live Privy session for chain ops (sign,
        // pay, mint). Platform JWT alone still keeps the user logged in for
        // browsing — only clear when Privy definitively reports logged out.
        // Dev `initialToken` bypasses Privy intentionally and is skipped.
        if (hasPersisted) {
          // Ensure provisional UI even if [build] had no warmed token yet.
          if (!state.isLoggedIn || state.token != persisted) {
            state = state.copyWith(
              ready: false,
              isLoggedIn: true,
              token: persisted,
              profile: _localRepo.getUser(),
            );
            if (!_authChanges.isClosed) _authChanges.add(true);
          }

          final privyStatus = await _privy.resolveSessionStatus();
          if (!ref.mounted) return;
          switch (privyStatus) {
            case PrivySessionStatus.unauthenticated:
              StoryLogger.w(
                'Platform JWT restored but Privy session is unauthenticated; '
                'clearing local session so the user must sign in again',
                tag: 'Auth',
              );
              await _clearPersistedSession();
              if (!ref.mounted) return;
              state = const AuthState(ready: true);
              if (!_authChanges.isClosed) _authChanges.add(false);
            case PrivySessionStatus.unknown:
              // Offline / NotReady / transport — keep JWT; chain ops re-check.
              StoryLogger.w(
                'Platform JWT restored but Privy session status is unknown; '
                'keeping local session until Privy can be verified',
                tag: 'Auth',
              );
              profile = _localRepo.getUser();
              state = state.copyWith(
                ready: true,
                isLoggedIn: true,
                token: t,
                profile: profile,
              );
            case PrivySessionStatus.authenticated:
              final alreadyAnnounced = state.isLoggedIn;
              profile = _localRepo.getUser();
              state = state.copyWith(
                ready: true,
                isLoggedIn: true,
                token: t,
                profile: profile,
              );
              if (!alreadyAnnounced && !_authChanges.isClosed) {
                _authChanges.add(true);
              }
          }
        } else {
          profile = _localRepo.getUser();
          state = state.copyWith(
            ready: true,
            isLoggedIn: true,
            token: t,
            profile: profile,
          );
          _authChanges.add(true);
          // Seed storage only when falling back to initialToken.
          if (_initialToken != null && t == _initialToken) {
            await _localRepo.saveToken(_initialToken);
            if (!ref.mounted) return;
          }
        }
      }
      // Prefer freshly ensured Privy address (mirrors login path). Storage may
      // be empty after reinstall / migration while Privy session still exists.
      if (state.isLoggedIn) {
        await _ensureWallet();
        if (!ref.mounted) return;
        if (state.solanaAddress.isEmpty) {
          final w = await _localRepo.getSolanaWalletAddressAsync();
          if (!ref.mounted) return;
          if (w != null && w.isNotEmpty) {
            state = state.copyWith(solanaAddress: w);
          }
        }
        if (state.ethereumAddress.isEmpty) {
          final w = await _localRepo.getEthereumWalletAddressAsync();
          if (!ref.mounted) return;
          if (w != null && w.isNotEmpty) {
            if (isValidEthereumAddress(w)) {
              state = state.copyWith(ethereumAddress: w);
            } else {
              await _localRepo.clearEthereumWalletAddress();
            }
          }
        }
        // Fire-and-forget: wallet balance can populate after the first frame.
        // Avoids blocking auth restore with RPC calls (200-500ms).
        unawaited(_refreshWalletBalance());
      }
    } catch (e, st) {
      StoryLogger.e(
        'Restore auth state failed',
        error: e,
        stackTrace: st,
        tag: 'Auth',
      );
    } finally {
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      // Ensure ready is set even on error path
      if (ref.mounted && !state.ready) {
        state = state.copyWith(ready: true);
      }
    }
  }

  /// Drops locally persisted platform auth when Privy session is missing.
  /// Does not call backend logout (token may already be invalid for Privy).
  Future<void> _clearPersistedSession() async {
    await _localRepo.clearToken();
    await _localRepo.clearUser();
    await _localRepo.clearSolanaWalletAddress();
    await _localRepo.clearEthereumWalletAddress();
    try {
      await _privy.logout();
    } catch (_) {
      // Best-effort; native session is already absent.
    }
  }

  /// Gates chain ops on a live Privy session.
  ///
  /// - [PrivySessionGate.ready]: JWT + Privy OK
  /// - [PrivySessionGate.temporarilyUnavailable]: offline/unknown — JWT kept
  /// - [PrivySessionGate.needsReauth]: Privy gone — local session cleared
  Future<PrivySessionGate> ensurePrivySessionReady() async {
    await ready;
    if (!state.isLoggedIn) return PrivySessionGate.needsReauth;

    final status = await _privy.resolveSessionStatus();
    if (!ref.mounted) return PrivySessionGate.temporarilyUnavailable;

    switch (status) {
      case PrivySessionStatus.authenticated:
        return PrivySessionGate.ready;
      case PrivySessionStatus.unknown:
        StoryLogger.w(
          'ensurePrivySessionReady: Privy status unknown; keeping session',
          tag: 'Auth',
        );
        return PrivySessionGate.temporarilyUnavailable;
      case PrivySessionStatus.unauthenticated:
        StoryLogger.w(
          'ensurePrivySessionReady: platform logged in but Privy unauthenticated',
          tag: 'Auth',
        );
        await logout();
        return PrivySessionGate.needsReauth;
    }
  }

  // ─── OTP flow ───────────────────────────────────────────────────────────

  Future<({bool ok, String? err})> sendOtp(String email) async {
    state = state.copyWith(isLogging: true);
    try {
      final r = await _privy.sendEmailCode(email);
      if (r.success) {
        state = state.copyWith(pendingEmail: email);
      }
      return (ok: r.success, err: r.error);
    } finally {
      state = state.copyWith(isLogging: false);
    }
  }

  Future<({bool ok, String? err})> verifyOtp(String code) async {
    if (state.pendingEmail.isEmpty) {
      return (ok: false, err: needCodeFirstErrorKey);
    }
    state = state.copyWith(isLogging: true);
    try {
      final r = await _privy.verifyEmailCode(
        email: state.pendingEmail,
        code: code,
      );
      if (!r.success || r.privyToken == null) {
        return (
          ok: false,
          err: r.error ?? PrivyService.invalidCredentialsErrorKey,
        );
      }

      // Critical path: Solana only (required before platform /login).
      // Do NOT Future.wait Solana+EVM — Privy native concurrency hangs OTP UI.
      // Do NOT await EVM create here — createEthereumWallet has hung before.
      final wallet = await _privy.ensureSolanaWallet();
      if (!wallet.success ||
          wallet.address == null ||
          wallet.address!.isEmpty) {
        return (ok: false, err: wallet.error ?? createWalletFailedErrorKey);
      }
      await _localRepo.saveSolanaWalletAddress(wallet.address!);
      state = state.copyWith(solanaAddress: wallet.address!);

      final login = await _userRepo.login(
        LoginRequest(
          privyToken: r.privyToken!,
          deviceType: LoginDeviceType.app,
        ),
      );
      if (login.isFailure) {
        return (ok: false, err: _mapLoginApiError(login.errorOrNull));
      }
      await _persist(login.dataOrNull!);

      // EVM + balances off critical path (sequential EVM only; deposit still
      // calls ensureWallets / ensureUsdc as needed).
      unawaited(_ensureEvmWalletInBackground());
      unawaited(_refreshWalletBalance());
      return (ok: true, err: null);
    } catch (e, st) {
      StoryLogger.e('verifyOtp crashed', error: e, stackTrace: st, tag: 'Auth');
      return (ok: false, err: PrivyService.networkErrorKey);
    } finally {
      state = state.copyWith(isLogging: false);
    }
  }

  /// Optional EVM ensure after login. Must stay sequential / single-flight —
  /// never run in parallel with [ensureSolanaWallet] on the OTP path.
  Future<void> _ensureEvmWalletInBackground() async {
    try {
      final evm = await _privy.ensureEthereumWallet();
      if (!ref.mounted) return;
      final evmAddr = evm.address?.trim() ?? '';
      if (evm.success &&
          evmAddr.isNotEmpty &&
          isValidEthereumAddress(evmAddr)) {
        await _localRepo.saveEthereumWalletAddress(evmAddr);
        if (!ref.mounted) return;
        state = state.copyWith(ethereumAddress: evmAddr);
      } else {
        StoryLogger.w(
          'Background EVM ensure skipped '
          '(success=${evm.success}, addr=$evmAddr, err=${evm.error})',
          tag: 'Auth',
        );
      }
    } catch (e, st) {
      StoryLogger.w(
        'Background EVM ensure failed (non-fatal)',
        error: e,
        stackTrace: st,
        tag: 'Auth',
      );
    }
  }

  Future<void> _persist(LoginResponse r) async {
    if (r.token != null && r.token!.isNotEmpty) {
      // Clear profile cache before seeding so a later async wipe cannot race
      // and drop the just-written current user.
      await _userRepo.clearProfileCache();
      await _localRepo.saveToken(r.token!);
      if (r.userProfile != null) {
        await _localRepo.saveUser(r.userProfile!);
        await _userRepo.seedCurrentProfile(r.userProfile!);
      }
      state = state.copyWith(
        isLoggedIn: true,
        token: r.token,
        profile: r.userProfile,
      );
      _authChanges.add(true);
      // Drama/actor/mining/notification Hive clears stay off the OTP critical path.
      unawaited(_clearUserScopedCachesAfterPersist());
    }
  }

  /// Clears repository caches whose keys are not scoped by user id.
  ///
  /// Prefer [_clearUserScopedCachesAfterPersist] on the login path so profile
  /// seed is not wiped by an async clear.
  Future<void> _clearUserScopedCaches() async {
    try {
      ref.read(requestCoalescerProvider).invalidateAll();
      await Future.wait([
        ref.read(dramaRepositoryProvider).clearUserScopedCaches(),
        ref.read(actorRepositoryProvider).clearUserScopedCaches(),
        ref.read(miningRepositoryProvider).clearUserScopedCaches(),
        ref.read(notificationRepositoryProvider).clearCachedFirstPages(),
        _userRepo.clearProfileCache(),
      ]);
      FollowRelationActions.clearSessionCaches(ref.container);
    } catch (e, st) {
      StoryLogger.e(
        'Clear user-scoped caches failed',
        error: e,
        stackTrace: st,
        tag: 'Auth',
      );
    }
  }

  /// Like [_clearUserScopedCaches] but skips profile (already cleared + seeded).
  Future<void> _clearUserScopedCachesAfterPersist() async {
    try {
      ref.read(requestCoalescerProvider).invalidateAll();
      await Future.wait([
        ref.read(dramaRepositoryProvider).clearUserScopedCaches(),
        ref.read(actorRepositoryProvider).clearUserScopedCaches(),
        ref.read(miningRepositoryProvider).clearUserScopedCaches(),
        ref.read(notificationRepositoryProvider).clearCachedFirstPages(),
      ]);
      FollowRelationActions.clearSessionCaches(ref.container);
    } catch (e, st) {
      StoryLogger.e(
        'Clear user-scoped caches after persist failed',
        error: e,
        stackTrace: st,
        tag: 'Auth',
      );
    }
  }

  Future<void> _ensureWallet() async {
    final r = await _privy.ensureSolanaWallet();
    if (r.success && r.address != null && r.address!.isNotEmpty) {
      await _localRepo.saveSolanaWalletAddress(r.address!);
      state = state.copyWith(solanaAddress: r.address!);
    } else {
      StoryLogger.w(
        'ensureWallet failed or returned empty address '
        '(success=${r.success}, err=${r.error})',
        tag: 'Auth',
      );
    }

    final evm = await _privy.ensureEthereumWallet();
    if (!ref.mounted) return;
    final evmAddr = evm.address?.trim() ?? '';
    if (evm.success && evmAddr.isNotEmpty && isValidEthereumAddress(evmAddr)) {
      await _localRepo.saveEthereumWalletAddress(evmAddr);
      if (!ref.mounted) return;
      state = state.copyWith(ethereumAddress: evmAddr);
    } else {
      // Drop stale non-0x values (e.g. Solana pubkey written under EVM key).
      final stored = await _localRepo.getEthereumWalletAddressAsync();
      if (!ref.mounted) return;
      if (stored != null &&
          stored.isNotEmpty &&
          !isValidEthereumAddress(stored)) {
        await _localRepo.clearEthereumWalletAddress();
        if (!ref.mounted) return;
      }
      if (state.ethereumAddress.isNotEmpty &&
          !isValidEthereumAddress(state.ethereumAddress)) {
        state = state.copyWith(clearEthereumAddress: true);
      }
      StoryLogger.w(
        'ensureEthereumWallet failed or returned invalid address '
        '(success=${evm.success}, addr=$evmAddr, err=${evm.error})',
        tag: 'Auth',
      );
    }
  }

  /// Ensures Solana + EVM embedded wallets exist and syncs addresses into state.
  ///
  /// Call from deposit/withdraw entry so UI addresses stay in sync with Privy
  /// even when only [PrivyService.ensureWalletSigners] ran earlier.
  Future<void> ensureWallets() => _ensureWallet();

  /// Reloads wallet addresses from secure storage into [state].
  ///
  /// Use after Privy ensure calls or when UI must refresh addresses without
  /// creating wallets again (storage may be ahead of in-memory state).
  Future<void> syncWalletAddressesFromStorage() async {
    final sol = await _localRepo.getSolanaWalletAddressAsync();
    final evm = await _localRepo.getEthereumWalletAddressAsync();
    if (!ref.mounted) return;
    var next = state;
    if (sol != null && sol.isNotEmpty && sol != state.solanaAddress) {
      next = next.copyWith(solanaAddress: sol);
    }
    if (evm != null && evm.isNotEmpty) {
      if (isValidEthereumAddress(evm)) {
        if (evm != state.ethereumAddress) {
          next = next.copyWith(ethereumAddress: evm);
        }
      } else {
        // Corrupt / wrong-chain value under EVM key — clear so UI can recover.
        await _localRepo.clearEthereumWalletAddress();
        if (!ref.mounted) return;
        if (state.ethereumAddress.isNotEmpty) {
          next = next.copyWith(clearEthereumAddress: true);
        }
      }
    }
    if (next != state) {
      state = next;
    }
  }

  /// Refresh on-chain balances without registering Auth → WalletBalance as a
  /// Riverpod dependency (`ref.read` asserts that in debug and throws
  /// [CircularDependencyError] if WalletBalance ever listened to Auth).
  Future<void> _refreshWalletBalance() async {
    if (!ref.mounted) return;
    await ref.container.read(onChainWalletBalanceProvider.notifier).refresh();
  }

  void _clearWalletBalance() {
    if (!ref.mounted) return;
    ref.container.read(onChainWalletBalanceProvider.notifier).clear();
  }

  // ─── Logout ─────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    // Re-entrancy guard: concurrent 401s or repeated taps must not run the
    // logout chain (Privy + API + local wipes) more than once.
    if (state.isLoggingOut) return;
    state = state.copyWith(isLoggingOut: true);
    try {
      await _privy.logout();
      await _userRepo.logout();
    } catch (e, st) {
      StoryLogger.e('Logout error', error: e, stackTrace: st, tag: 'Auth');
    }
    await _localRepo.clearToken();
    await _localRepo.clearUser();
    await _localRepo.clearSolanaWalletAddress();
    await _localRepo.clearEthereumWalletAddress();
    await _clearUserScopedCaches();
    state = state.copyWith(
      isLoggedIn: false,
      clearToken: true,
      clearProfile: true,
      clearPendingEmail: true,
      clearSolanaAddress: true,
      clearEthereumAddress: true,
      isLoggingOut: false,
    );
    _authChanges.add(false);
    // Clear/reset wallet balance on logout
    _clearWalletBalance();
    FeedTrackingService.clearTrackingHistory();
  }

  // ─── Profile updates ────────────────────────────────────────────────────

  void updateProfile(UserProfile newProfile) {
    _localRepo.saveUser(newProfile);
    state = state.copyWith(profile: newProfile);
  }

  /// Updates nickname and optional intro via `POST /api/userWallet/nickname`.
  ///
  /// Request body uses `profile` for the intro text. On success the local
  /// profile is patched and [Result.success] is returned.
  Future<Result<void>> updateNickname({
    required String nickname,
    String? profile,
  }) async {
    final result = await _userRepo.updateNickname(
      nickname: nickname,
      profile: profile,
    );
    if (result.isFailure) return result;
    final current = state.profile;
    if (current != null) {
      final updated = current.copyWith(nickname: nickname, bio: profile);
      await _localRepo.saveUser(updated);
      if (!ref.mounted) return Result.success(null);
      state = state.copyWith(profile: updated);
    }
    return Result.success(null);
  }

  /// Updates the current user's avatar on the server.
  ///
  /// On success the local profile is refreshed (cache cleared by the repo
  /// and the in-memory profile patched with the new avatar URL). Returns
  /// [Result.success] on success, otherwise [Result.failure] carrying the
  /// [ApiError] so callers can localize it via [context.l10nError].
  Future<Result<void>> updateAvatar(String avatarUrl) async {
    final result = await _userRepo.updateAvatar(avatarUrl);
    if (result.isFailure) return result;
    final current = state.profile;
    if (current != null) {
      final updated = current.copyWith(avatarUrl: avatarUrl);
      await _localRepo.saveUser(updated);
      if (!ref.mounted) return Result.success(null);
      state = state.copyWith(profile: updated);
    }
    return Result.success(null);
  }

  /// Soft-deletes the account via `POST /api/userWallet/updateDeleted`
  /// (`isDeleted: 1`), then logs out on success.
  Future<Result<void>> deleteAccount() async {
    final result = await _userRepo.updateDeleted(isDeleted: 1);
    if (result.isFailure) return result;
    await logout();
    return Result.success(null);
  }

  /// Cancels pending account deletion via `updateDeleted` (`isDeleted: 0`).
  Future<Result<void>> cancelAccountDeletion() async {
    final result = await _userRepo.updateDeleted(isDeleted: 0);
    if (result.isFailure) return result;
    final current = state.profile;
    if (current != null) {
      final updated = current.copyWith(isDeleted: '0');
      await _localRepo.saveUser(updated);
      if (!ref.mounted) return Result.success(null);
      state = state.copyWith(profile: updated);
    }
    return Result.success(null);
  }

  // ─── StoryAuthProvider implementation ───────────────────────────────────

  @override
  Future<String?> getAccessToken() async => state.token;

  /// Maps platform `/login` [ApiError] to a UI-safe marker or backend message.
  /// Transport failures become [PrivyService.networkErrorKey] so the login page
  /// never shows raw `HandshakeException` / `userMessage` dumps.
  String _mapLoginApiError(ApiError? error) {
    if (error == null) return PrivyService.networkErrorKey;
    return switch (error) {
      NetworkError() || TimeoutError() => PrivyService.networkErrorKey,
      UnknownError(:final message)
          when PrivyService.looksLikeTransportFailure(message) ||
              PrivyService.looksLikeTransportFailure(error.userMessage) =>
        PrivyService.networkErrorKey,
      BusinessError(:final message) when message.isNotEmpty => message,
      UnauthorizedError() => PrivyService.networkErrorKey,
      _ =>
        PrivyService.looksLikeTransportFailure(error.userMessage)
            ? PrivyService.networkErrorKey
            : error.userMessage,
    };
  }

  // ─── Dev helper ─────────────────────────────────────────────────────────

  /// Set token directly, bypassing OTP flow.
  /// Used for development / pre-configured login.
  Future<void> setToken(String token) async {
    assert(!kReleaseMode, 'setToken bypass should only be used in dev/test');
    await _localRepo.saveToken(token);
    state = state.copyWith(isLoggedIn: true, token: token);
    _authChanges.add(true);
    // Fetch/refresh wallet balance
    await _refreshWalletBalance();
  }
}
