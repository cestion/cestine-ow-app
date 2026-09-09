import 'package:equatable/equatable.dart';

import '../model/models.dart';

/// Immutable state for [AuthController].
class AuthState extends Equatable {
  final bool ready;
  final bool isLoggedIn;
  final bool isLogging;
  final bool isLoggingOut;
  final UserProfile? profile;
  final String? token;
  final String pendingEmail;
  final String solanaAddress;
  final String ethereumAddress;

  const AuthState({
    this.ready = false,
    this.isLoggedIn = false,
    this.isLogging = false,
    this.isLoggingOut = false,
    this.profile,
    this.token,
    this.pendingEmail = '',
    this.solanaAddress = '',
    this.ethereumAddress = '',
  });

  AuthState copyWith({
    bool? ready,
    bool? isLoggedIn,
    bool? isLogging,
    bool? isLoggingOut,
    UserProfile? profile,
    bool clearProfile = false,
    String? token,
    bool clearToken = false,
    String? pendingEmail,
    bool clearPendingEmail = false,
    String? solanaAddress,
    bool clearSolanaAddress = false,
    String? ethereumAddress,
    bool clearEthereumAddress = false,
  }) => AuthState(
    ready: ready ?? this.ready,
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    isLogging: isLogging ?? this.isLogging,
    isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    profile: clearProfile ? null : (profile ?? this.profile),
    token: clearToken ? null : (token ?? this.token),
    pendingEmail: clearPendingEmail ? '' : (pendingEmail ?? this.pendingEmail),
    solanaAddress: clearSolanaAddress
        ? ''
        : (solanaAddress ?? this.solanaAddress),
    ethereumAddress: clearEthereumAddress
        ? ''
        : (ethereumAddress ?? this.ethereumAddress),
  );

  /// Convenience: the effective Solana address (wallet or profile fallback).
  String get effectiveSolanaAddress =>
      solanaAddress.isNotEmpty ? solanaAddress : (profile?.walletAddress ?? '');

  /// Convenience: the user ID from profile.
  String? get userId => profile?.userId ?? profile?.id;

  @override
  List<Object?> get props => [
    ready,
    isLoggedIn,
    isLogging,
    isLoggingOut,
    profile,
    token,
    pendingEmail,
    solanaAddress,
    ethereumAddress,
  ];
}
