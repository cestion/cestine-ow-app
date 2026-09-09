import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// STORY 释放概览 Tab 二级导航下标。
class StoryReleaseTab {
  StoryReleaseTab._();

  /// STORY 总量分配（暂无设计稿/接口，占位展示）。
  static const int allocation = 0;

  /// 近期挖矿释放（Figma node 6312:98138）。
  static const int miningRelease = 1;
}

/// STORY 释放概览 Tab 状态。
///
/// [selectedTab] 对应二级导航 [StoryReleaseTab]，默认展示「近期挖矿释放」；
/// [recentReleases] 为该二级 Tab 下的预览列表（最多 5 条），完整列表见
/// `StoryReleaseHistoryPage`。
class StoryReleaseOverviewState extends Equatable {
  final int selectedTab;
  final bool isLoading;
  final ApiError? lastError;
  final List<WeeklyRewardItem> recentReleases;

  const StoryReleaseOverviewState({
    this.selectedTab = StoryReleaseTab.allocation,
    this.isLoading = false,
    this.lastError,
    this.recentReleases = const [],
  });

  StoryReleaseOverviewState copyWith({
    int? selectedTab,
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    List<WeeklyRewardItem>? recentReleases,
  }) => StoryReleaseOverviewState(
    selectedTab: selectedTab ?? this.selectedTab,
    isLoading: isLoading ?? this.isLoading,
    lastError: clearLastError ? null : (lastError ?? this.lastError),
    recentReleases: recentReleases ?? this.recentReleases,
  );

  @override
  List<Object?> get props => [
    selectedTab,
    isLoading,
    lastError,
    recentReleases,
  ];
}
