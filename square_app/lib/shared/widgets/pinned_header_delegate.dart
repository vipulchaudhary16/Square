import 'package:flutter/material.dart';

/// A pinned sliver header of fixed [extent] — used wherever a search bar,
/// filter chip, or similar control should stay reachable while scrolling
/// through a long list below it.
class PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  const PinnedHeaderDelegate({required this.child, required this.backgroundColor, required this.extent});

  final Widget child;
  final Color backgroundColor;
  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // A pinned header's paintExtent comes from the CHILD's own measured
    // height, while its layoutExtent/scrollExtent come from minExtent/
    // maxExtent above — if the child doesn't fill exactly `extent`, those
    // two disagree and the sliver layout throws. Force the child to fill
    // the declared extent so they always match.
    return SizedBox(height: extent, child: ColoredBox(color: backgroundColor, child: child));
  }

  @override
  bool shouldRebuild(covariant PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.backgroundColor != backgroundColor || oldDelegate.extent != extent;
  }
}
