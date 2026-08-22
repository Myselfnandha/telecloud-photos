import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class ShimmerGrid extends StatelessWidget {
  final int itemCount;

  const ShimmerGrid({super.key, this.itemCount = 18});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Shimmer.fromColors(
      baseColor: isLight
          ? AppColors.shimmerBaseLight
          : AppColors.shimmerBaseDark,
      highlightColor: isLight
          ? AppColors.shimmerHighlightLight
          : AppColors.shimmerHighlightDark,
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
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.borderS,
            ),
          );
        },
      ),
    );
  }
}
