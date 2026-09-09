import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../repositories/actor_repository.dart';
import 'pagination_state.dart';

class NftState extends Equatable {
  final bool isLoading;
  final ApiError? lastError;
  final PaginationState<ActorCollection> pagination;
  final ActorCollectionSort sort;
  final String searchQuery;

  const NftState({
    this.isLoading = false,
    this.lastError,
    this.pagination = const PaginationState<ActorCollection>(),
    this.sort = ActorCollectionSort.computingPower,
    this.searchQuery = '',
  });

  String get errorMessage => lastError?.userMessage ?? '';

  List<ActorCollection> get items => pagination.items;

  /// Plaza list order aligned with web `ActorPlazaView.sortedListItems`.
  ///
  /// Price sorts re-order by [ActorCollection.displayCurrentPriceUsdc]; Lv.1
  /// keeps the API `computing_power` cursor order.
  List<ActorCollection> get displayItems {
    final raw = pagination.items;
    if (!sort.isPrice) return raw;
    final sorted = List<ActorCollection>.from(raw);
    sorted.sort((a, b) {
      final cmp = a.displayCurrentPriceUsdc.compareTo(
        b.displayCurrentPriceUsdc,
      );
      return sort == ActorCollectionSort.priceAsc ? cmp : -cmp;
    });
    return sorted;
  }

  bool get hasMore => pagination.hasMore;
  String get mark => pagination.mark;
  bool get isPageLoading => pagination.isPageLoading;

  NftState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    PaginationState<ActorCollection>? pagination,
    ActorCollectionSort? sort,
    String? searchQuery,
  }) {
    return NftState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      pagination: pagination ?? this.pagination,
      sort: sort ?? this.sort,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    lastError,
    pagination,
    sort,
    searchQuery,
  ];
}
