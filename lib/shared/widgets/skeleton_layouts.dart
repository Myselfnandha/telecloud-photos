import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Base shimmer container wrapper using the design system's shimmer tokens.
class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Shimmer.fromColors(
      baseColor:
          isLight ? AppColors.shimmerBaseLight : AppColors.shimmerBaseDark,
      highlightColor: isLight
          ? AppColors.shimmerHighlightLight
          : AppColors.shimmerHighlightDark,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// Generic bone shape container with custom dimensions and border radius.
class SkeletonBone extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const SkeletonBone({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonBone.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : (borderRadius ?? AppRadii.borderS),
      ),
    );
  }
}

/// Content-aware skeleton for the main Timeline screen with date headers and grid tiles.
class TimelineSkeletonGrid extends StatelessWidget {
  final int sectionCount;

  const TimelineSkeletonGrid({super.key, this.sectionCount = 2});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sectionCount,
        itemBuilder: (context, sectionIndex) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header Bone + Location subtitle bone
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBone(
                          width: sectionIndex == 0 ? 140 : 110,
                          height: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        SkeletonBone(
                          width: 80,
                          height: 11,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                    SkeletonBone(
                      width: 50,
                      height: 12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),

              // 3-Column Grid matching daily grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 2.5,
                  crossAxisSpacing: 2.5,
                  childAspectRatio: 1.0,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return const SkeletonBone(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Content-aware skeleton for Album list and detail screens.
class AlbumListSkeleton extends StatelessWidget {
  final int itemCount;

  const AlbumListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover art bone
              const Expanded(
                child: SkeletonBone(
                  borderRadius: AppRadii.borderL,
                ),
              ),
              const SizedBox(height: 8),
              // Album title bone
              SkeletonBone(
                width: index.isEven ? 100 : 120,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              // Photo count bone
              SkeletonBone(
                width: 55,
                height: 11,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Content-aware skeleton for Search results and categorized collections.
class SearchResultsSkeleton extends StatelessWidget {
  const SearchResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Filter Chips Row Bone
          Row(
            children: [
              SkeletonBone(
                  width: 80, height: 32, borderRadius: AppRadii.borderPill),
              const SizedBox(width: 8),
              SkeletonBone(
                  width: 100, height: 32, borderRadius: AppRadii.borderPill),
              const SizedBox(width: 8),
              SkeletonBone(
                  width: 90, height: 32, borderRadius: AppRadii.borderPill),
            ],
          ),
          const SizedBox(height: 20),

          // Section Title Bone
          SkeletonBone(
              width: 130, height: 16, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),

          // Staggered Masonry-style Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemCount: 9,
            itemBuilder: (context, index) => const SkeletonBone(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
