import 'package:equatable/equatable.dart';

/// Per-user follow state shared by the player rail (and later profile).
class FollowState extends Equatable {
  /// `null` until the relation request settles (or the viewer is a guest).
  final bool? isFollowing;
  final bool isMutating;

  const FollowState({this.isFollowing, this.isMutating = false});

  FollowState copyWith({bool? isFollowing, bool? isMutating}) {
    return FollowState(
      isFollowing: isFollowing ?? this.isFollowing,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [isFollowing, isMutating];
}
