import 'package:flutter/material.dart';
import 'skeleton_layouts.dart';

export 'skeleton_layouts.dart';

class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final bool contentAware;

  const ShimmerGrid({
    super.key,
    this.itemCount = 18,
    this.contentAware = true,
  });

  @override
  Widget build(BuildContext context) {
    if (contentAware) {
      return const TimelineSkeletonGrid();
    }

    return SkeletonShimmer(
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2.5,
          crossAxisSpacing: 2.5,
          childAspectRatio: 1.0,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const SkeletonBone(
            borderRadius: BorderRadius.all(Radius.circular(3)),
          );
        },
      ),
    );
  }
}
