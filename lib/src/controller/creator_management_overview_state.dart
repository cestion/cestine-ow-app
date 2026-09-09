import 'package:equatable/equatable.dart';

import '../core/result.dart';

class CreatorManagementOverviewState extends Equatable {
  final bool isLoading;
  final int dramaCount;
  final int videoCount;
  final ApiError? lastError;

  const CreatorManagementOverviewState({
    this.isLoading = false,
    this.dramaCount = 0,
    this.videoCount = 0,
    this.lastError,
  });

  CreatorManagementOverviewState copyWith({
    bool? isLoading,
    int? dramaCount,
    int? videoCount,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return CreatorManagementOverviewState(
      isLoading: isLoading ?? this.isLoading,
      dramaCount: dramaCount ?? this.dramaCount,
      videoCount: videoCount ?? this.videoCount,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  List<Object?> get props => [isLoading, dramaCount, videoCount, lastError];
}
