import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../data/repository/story_local_repository.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/user_repository.dart';
import 'profile_state.dart';
import 'story_controller_mixin.dart';

class ProfileController extends Notifier<ProfileState>
    with StoryControllerMixin<ProfileState> {
  UserRepository get _user => ref.read(userRepositoryProvider);
  StoryLocalRepository get _local => ref.read(localRepositoryProvider);

  @override
  ProfileState build() {
    final authState = ref.read(authControllerProvider);

    // React to auth changes (login/logout) so profile stays in sync.
    // Without this, ProfileController shows stale data after login until
    // refresh() is called manually.
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.profile != next.profile) {
        state = next.profile == null
            ? const ProfileState()
            : state.copyWith(user: next.profile, clearLastError: true);
      }
    });

    return ProfileState(
      user: authState.profile,
      watchlist: _local.getWatchlist(),
    );
  }

  @override
  ProfileState copyWithLoadingState({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return state.copyWith(
      isLoading: isLoading,
      lastError: lastError,
      clearLastError: clearLastError,
    );
  }

  UserProfile? get user => state.user;
  List<String> get watchlist => state.watchlist;
  bool get isLoggedIn => user != null;
  bool get isLoading => state.isLoading;
  String get errorMessage => state.errorMessage;

  Future<void> refresh({bool force = false}) async {
    if (!ref.mounted) return;
    if (!ref.read(authControllerProvider).isLoggedIn) return;

    final profile = await withLoadingResult<UserProfile>(
      () => _user.getProfile(forceRefresh: force),
    );
    if (!ref.mounted) return;
    if (profile != null) {
      ref.read(authControllerProvider.notifier).updateProfile(profile);
      state = state.copyWith(user: profile);
    }
  }

  /// Persist profile edits (nickname / intro / avatar). Nickname and intro are
  /// saved together via [AuthController.updateNickname] (`profile` API field).
  /// Only the provided fields are updated. Avatar is a separate endpoint.
  ///
  /// Returns the first failure encountered, otherwise success.
  Future<Result<void>> saveProfile({
    String? nickname,
    String? avatarUrl,
    String? bio,
  }) async {
    final auth = ref.read(authControllerProvider.notifier);
    if (nickname != null || bio != null) {
      final current = ref.read(authControllerProvider).profile;
      final result = await auth.updateNickname(
        nickname: nickname ?? current?.nickname ?? '',
        profile: bio ?? current?.bio,
      );
      if (result.isFailure) return result;
    }
    if (avatarUrl != null) {
      final result = await auth.updateAvatar(avatarUrl);
      if (result.isFailure) return result;
    }
    if (!ref.mounted) return Result.success(null);
    // Sync ProfileState from the optimistically-updated auth profile so
    // widgets watching profileControllerProvider also rebuild promptly.
    final user = ref.read(authControllerProvider).profile;
    if (user != null) {
      state = state.copyWith(user: user, clearLastError: true);
    }
    // Re-fetch canonical server data (e.g. updatedAt). Failure is non-fatal
    // because the optimistic patch already reflects the user's edits.
    await refresh();
    return Result.success(null);
  }

  Future<void> logout() async =>
      ref.read(authControllerProvider.notifier).logout();
}
