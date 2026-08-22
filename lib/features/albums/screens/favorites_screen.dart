import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_elevation.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/grid_density_provider.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  double _pinchScale = 1.0;
  bool _isPinching = false;

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2) {
      setState(() {
        _isPinching = true;
        _pinchScale = details.scale.clamp(0.5, 2.5);
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!_isPinching) return;
    if (_pinchScale > 1.25) {
      ref.read(gridDensityProvider.notifier).zoomIn();
      HapticFeedback.selectionClick();
    } else if (_pinchScale < 0.78) {
      ref.read(gridDensityProvider.notifier).zoomOut();
      HapticFeedback.selectionClick();
    }

    setState(() {
      _isPinching = false;
      _pinchScale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaDao = ref.watch(mediaDaoProvider);
    final density = ref.watch(gridDensityProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final secondaryTextColor = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: AppElevation.none,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryTextColor,
            size: AppIcons.m,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppColors.systemRed,
              size: AppIcons.l,
            ),
            AppSpacing.gapHorizontalS,
            Text(
              'Favorites',
              style: AppTypography.titleLarge(
                color: primaryTextColor,
              ).copyWith(fontWeight: AppTypography.bold),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<GridDensity>(
            icon: Icon(
              density.icon,
              color: AppColors.primaryBlue,
              size: AppIcons.m,
            ),
            tooltip: 'Grid Density',
            color: isLight ? Colors.white : AppColors.darkSurface,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderL),
            onSelected: (d) {
              HapticFeedback.selectionClick();
              ref.read(gridDensityProvider.notifier).setDensity(d);
            },
            itemBuilder: (context) => [
              for (final d in GridDensity.values)
                PopupMenuItem(
                  value: d,
                  child: Row(
                    children: [
                      Icon(
                        d.icon,
                        color: density == d
                            ? AppColors.primaryBlue
                            : secondaryTextColor,
                        size: AppIcons.s + 2,
                      ),
                      AppSpacing.gapHorizontalM,
                      Text(
                        d.label,
                        style:
                            AppTypography.bodyMedium(
                              color: density == d
                                  ? AppColors.primaryBlue
                                  : primaryTextColor,
                            ).copyWith(
                              fontWeight: density == d
                                  ? AppTypography.bold
                                  : AppTypography.regular,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<MediaItem>>(
        stream: mediaDao.watchFavorites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: AppSpacing.paddingXL,
                      decoration: BoxDecoration(
                        color: AppColors.systemRed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 54,
                        color: AppColors.systemRed,
                      ),
                    ),
                    AppSpacing.gapVerticalL,
                    Text(
                      'No Favorites Yet',
                      style: AppTypography.headlineSmall(
                        color: primaryTextColor,
                      ).copyWith(fontWeight: AppTypography.bold),
                    ),
                    AppSpacing.gapVerticalS,
                    Text(
                      'Tap the heart icon on any photo to add it here',
                      style: AppTypography.bodyMedium(
                        color: secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return GestureDetector(
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: GridView.builder(
                key: ValueKey('fav_grid_${density.crossAxisCount}'),
                padding: const EdgeInsets.all(4),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: density.crossAxisCount,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                  childAspectRatio: density.childAspectRatio,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _FavoriteTile(key: ValueKey(item.localId), item: item);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteTile extends StatefulWidget {
  final MediaItem item;

  const _FavoriteTile({super.key, required this.item});

  @override
  State<_FavoriteTile> createState() => _FavoriteTileState();
}

class _FavoriteTileState extends State<_FavoriteTile>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _bytes;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final cached = ThumbnailCacheService().getFromMemory(widget.item.localId);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _bytes = cached;
        });
      }
      return;
    }

    final bytes = await ThumbnailCacheService().getThumbnail(
      id: widget.item.localId,
      diskPath: widget.item.thumbnailPath,
      isVideo: widget.item.mimeType.startsWith('video'),
    );

    if (mounted) {
      setState(() {
        _bytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final thumbPath = widget.item.thumbnailPath;
    final hasValidDiskThumb =
        thumbPath != null &&
        thumbPath.isNotEmpty &&
        File(thumbPath).existsSync();

    return GestureDetector(
      onTap: () => context.push('/viewer/${widget.item.localId}'),
      child: ClipRRect(
        borderRadius: AppRadii.borderS,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: const Color(0xFF141416),
              child: _bytes != null
                  ? Image.memory(
                      _bytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ShimmerLoading(),
                    )
                  : (hasValidDiskThumb
                        ? Image.file(
                            File(thumbPath),
                            fit: BoxFit.cover,
                            cacheWidth: 256,
                            cacheHeight: 256,
                            errorBuilder: (context, error, stackTrace) =>
                                const ShimmerLoading(),
                          )
                        : const ShimmerLoading()),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.systemRed,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
