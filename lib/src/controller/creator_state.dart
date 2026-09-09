import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// Dialog kinds for the creator page (actor delete flow).
/// Drama delete flow lives in [DramaManagementDialog] now.
/// Drama NFT flow lives in [DramaNftState] now.
enum CreatorDialog { closed, deleteActorConfirm }

class CreatorState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final List<Actor> myActors;
  final int onlineDramaCount;
  final int ownedNftCount;
  final CreatorDialog activeDialog;
  final bool isDeleting;
  final String? actorToDelete;

  const CreatorState({
    this.isLoading = false,
    this.lastError,
    this.myActors = const [],
    this.onlineDramaCount = 0,
    this.ownedNftCount = 0,
    this.activeDialog = CreatorDialog.closed,
    this.isDeleting = false,
    this.actorToDelete,
  });

  String get errorMessage => lastError?.userMessage ?? '';

  CreatorState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    List<Actor>? myActors,
    int? onlineDramaCount,
    int? ownedNftCount,
    CreatorDialog? activeDialog,
    bool? isDeleting,
    String? actorToDelete,
  }) {
    return CreatorState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      myActors: myActors ?? this.myActors,
      onlineDramaCount: onlineDramaCount ?? this.onlineDramaCount,
      ownedNftCount: ownedNftCount ?? this.ownedNftCount,
      activeDialog: activeDialog ?? this.activeDialog,
      isDeleting: isDeleting ?? this.isDeleting,
      actorToDelete: actorToDelete ?? this.actorToDelete,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    lastError,
    myActors,
    onlineDramaCount,
    ownedNftCount,
    activeDialog,
    isDeleting,
    actorToDelete,
  ];
}
