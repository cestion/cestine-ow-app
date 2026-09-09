import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

class ReportState extends Equatable {
  final List<ReportTypeItem> reasons;
  final bool isLoading;
  final bool isSubmitting;
  final ApiError? lastError;

  const ReportState({
    this.reasons = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.lastError,
  });

  ReportState copyWith({
    List<ReportTypeItem>? reasons,
    bool? isLoading,
    bool? isSubmitting,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return ReportState(
      reasons: reasons ?? this.reasons,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  List<Object?> get props => [reasons, isLoading, isSubmitting, lastError];
}
