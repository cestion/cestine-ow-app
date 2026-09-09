import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// Result tab / entry deep-link for the global search page.
enum SearchType { dramas, works, actors, users }

/// Search state — immutable, created by [SearchController].
class SearchState extends Equatable {
  final String keyword;
  final SearchType activeTab;
  final List<FeedItem> dramas;
  final List<FeedItem> works;
  final List<ActorCollection> actors;
  final List<UserSearchItem> users;
  final bool hasSearched;
  final bool isLoading;
  final bool isPageLoading;
  final ApiError? lastError;

  /// Keyword that produced the cached result for [activeTab] (empty = miss).
  final String dramasQuery;
  final String worksQuery;
  final String actorsQuery;
  final String usersQuery;

  /// Cursor / mark for next page (`-1` or empty + [hasMore]=false ⇒ done).
  final String dramasCursor;
  final String worksCursor;
  final String actorsMark;
  final String usersMark;

  final bool dramasHasMore;
  final bool worksHasMore;
  final bool actorsHasMore;
  final bool usersHasMore;

  const SearchState({
    this.keyword = '',
    this.activeTab = SearchType.dramas,
    this.dramas = const [],
    this.works = const [],
    this.actors = const [],
    this.users = const [],
    this.hasSearched = false,
    this.isLoading = false,
    this.isPageLoading = false,
    this.lastError,
    this.dramasQuery = '',
    this.worksQuery = '',
    this.actorsQuery = '',
    this.usersQuery = '',
    this.dramasCursor = '',
    this.worksCursor = '',
    this.actorsMark = '',
    this.usersMark = '',
    this.dramasHasMore = false,
    this.worksHasMore = false,
    this.actorsHasMore = false,
    this.usersHasMore = false,
  });

  String get errorMessage => lastError?.userMessage ?? '';

  bool hasCacheFor(SearchType tab, String keyword) {
    final q = keyword.trim();
    if (q.isEmpty) return false;
    return switch (tab) {
      SearchType.dramas => dramasQuery == q,
      SearchType.works => worksQuery == q,
      SearchType.actors => actorsQuery == q,
      SearchType.users => usersQuery == q,
    };
  }

  bool hasMoreFor(SearchType tab) => switch (tab) {
    SearchType.dramas => dramasHasMore,
    SearchType.works => worksHasMore,
    SearchType.actors => actorsHasMore,
    SearchType.users => usersHasMore,
  };

  String cursorFor(SearchType tab) => switch (tab) {
    SearchType.dramas => dramasCursor,
    SearchType.works => worksCursor,
    SearchType.actors => actorsMark,
    SearchType.users => usersMark,
  };

  SearchState copyWith({
    String? keyword,
    SearchType? activeTab,
    List<FeedItem>? dramas,
    List<FeedItem>? works,
    List<ActorCollection>? actors,
    List<UserSearchItem>? users,
    bool? hasSearched,
    bool? isLoading,
    bool? isPageLoading,
    ApiError? lastError,
    bool clearLastError = false,
    bool clearResults = false,
    String? dramasQuery,
    String? worksQuery,
    String? actorsQuery,
    String? usersQuery,
    String? dramasCursor,
    String? worksCursor,
    String? actorsMark,
    String? usersMark,
    bool? dramasHasMore,
    bool? worksHasMore,
    bool? actorsHasMore,
    bool? usersHasMore,
  }) {
    return SearchState(
      keyword: keyword ?? this.keyword,
      activeTab: activeTab ?? this.activeTab,
      dramas: clearResults ? const [] : (dramas ?? this.dramas),
      works: clearResults ? const [] : (works ?? this.works),
      actors: clearResults ? const [] : (actors ?? this.actors),
      users: clearResults ? const [] : (users ?? this.users),
      hasSearched: hasSearched ?? this.hasSearched,
      isLoading: isLoading ?? this.isLoading,
      isPageLoading: isPageLoading ?? this.isPageLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      dramasQuery: clearResults ? '' : (dramasQuery ?? this.dramasQuery),
      worksQuery: clearResults ? '' : (worksQuery ?? this.worksQuery),
      actorsQuery: clearResults ? '' : (actorsQuery ?? this.actorsQuery),
      usersQuery: clearResults ? '' : (usersQuery ?? this.usersQuery),
      dramasCursor: clearResults ? '' : (dramasCursor ?? this.dramasCursor),
      worksCursor: clearResults ? '' : (worksCursor ?? this.worksCursor),
      actorsMark: clearResults ? '' : (actorsMark ?? this.actorsMark),
      usersMark: clearResults ? '' : (usersMark ?? this.usersMark),
      dramasHasMore: clearResults
          ? false
          : (dramasHasMore ?? this.dramasHasMore),
      worksHasMore: clearResults ? false : (worksHasMore ?? this.worksHasMore),
      actorsHasMore: clearResults
          ? false
          : (actorsHasMore ?? this.actorsHasMore),
      usersHasMore: clearResults ? false : (usersHasMore ?? this.usersHasMore),
    );
  }

  @override
  List<Object?> get props => [
    keyword,
    activeTab,
    dramas,
    works,
    actors,
    users,
    hasSearched,
    isLoading,
    isPageLoading,
    lastError,
    dramasQuery,
    worksQuery,
    actorsQuery,
    usersQuery,
    dramasCursor,
    worksCursor,
    actorsMark,
    usersMark,
    dramasHasMore,
    worksHasMore,
    actorsHasMore,
    usersHasMore,
  ];
}
