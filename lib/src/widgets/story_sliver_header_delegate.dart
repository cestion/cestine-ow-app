import 'package:flutter/material.dart';

/// A pinned [SliverPersistentHeaderDelegate] that wraps a fixed-height [child].
///
/// Replaces the private `_SliverAppBarDelegate` pattern duplicated across
/// multiple pages with a single shared implementation.
class StorySliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const StorySliverHeaderDelegate({required this.child, this.height = 49.0});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(StorySliverHeaderDelegate oldDelegate) => false;
}
