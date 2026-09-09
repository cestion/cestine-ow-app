import 'package:equatable/equatable.dart';

class PageDto<T> extends Equatable {
  final int? pageSize;
  final String? mark;
  final List<T>? list;
  final bool? hasMore;
  final int? total;

  const PageDto({
    this.pageSize,
    this.mark,
    this.list,
    this.hasMore,
    this.total,
  });

  /// Parses the API's polymorphic `total` value while keeping the model field
  /// strongly typed as [int].
  ///
  /// Some endpoints return an integer, while others return a numeric string.
  static int? parseTotal(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : int.tryParse(trimmed);
    }
    return null;
  }

  @override
  List<Object?> get props => [pageSize, mark, list, hasMore, total];
}
