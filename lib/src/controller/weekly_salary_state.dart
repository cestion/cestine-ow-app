import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

class WeeklySalaryState extends Equatable {
  final MiningWeeklyStats? stats;
  final DateTime? lastUpdatedAt;
  final bool isRefreshing;
  final bool isDirty;
  final ApiError? lastError;

  const WeeklySalaryState({
    this.stats,
    this.lastUpdatedAt,
    this.isRefreshing = false,
    this.isDirty = true,
    this.lastError,
  });

  WeeklySalaryState copyWith({
    MiningWeeklyStats? stats,
    DateTime? lastUpdatedAt,
    bool? isRefreshing,
    bool? isDirty,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return WeeklySalaryState(
      stats: stats ?? this.stats,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isDirty: isDirty ?? this.isDirty,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  List<Object?> get props => [
    stats,
    lastUpdatedAt,
    isRefreshing,
    isDirty,
    lastError,
  ];
}
