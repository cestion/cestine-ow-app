import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

class ProfileState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final UserProfile? user;
  final List<String> watchlist;

  const ProfileState({
    this.isLoading = false,
    this.lastError,
    this.user,
    this.watchlist = const [],
  });

  String get errorMessage => lastError?.userMessage ?? '';
  bool get isLoggedIn => user != null;

  ProfileState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    UserProfile? user,
    List<String>? watchlist,
    bool clearUser = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      user: clearUser ? null : (user ?? this.user),
      watchlist: watchlist ?? this.watchlist,
    );
  }

  @override
  List<Object?> get props => [isLoading, lastError, user, watchlist];
}
