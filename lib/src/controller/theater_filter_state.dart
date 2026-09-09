import 'package:equatable/equatable.dart';

/// Theater sort mode keys (language-independent).
enum TheaterSort { hottest, completedView, newest, topRated }

/// Theater page filter state — immutable, created by [TheaterFilterController].
class TheaterFilterState extends Equatable {
  /// Selected tag ID for API filtering. `null` means "all" (no filter).
  final String? selectedTagId;

  /// Selected tag name for display purposes.
  final String? selectedTagName;

  final TheaterSort sort;

  const TheaterFilterState({
    this.selectedTagId,
    this.selectedTagName,
    this.sort = TheaterSort.hottest,
  });

  TheaterFilterState copyWith({
    String? selectedTagId,
    String? selectedTagName,
    bool clearTag = false,
    TheaterSort? sort,
  }) {
    return TheaterFilterState(
      selectedTagId: clearTag ? null : (selectedTagId ?? this.selectedTagId),
      selectedTagName: clearTag
          ? null
          : (selectedTagName ?? this.selectedTagName),
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [selectedTagId, selectedTagName, sort];
}
