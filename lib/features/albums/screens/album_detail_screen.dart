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

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final int albumId;
  final String albumName;

  const AlbumDetailScreen({
    super.key,
    required this.albumId,
    required this.albumName,
  });

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
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
        title: Text(
          widget.albumName,
          style: AppTypography.titleLarge(
            color: primaryTextColor,
          ).copyWith(fontWeight: AppTypography.bold),
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
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: primaryTextColor,
              size: AppIcons.m,
            ),
            color: isLight ? Colors.white : AppColors.darkSurface,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderL),
            onSelected: (val) async {
              if (val == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isLight ? Colors.white : AppColors.darkSurface,
                    shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderL),
                    title: Text(
                      'Delete Album "${widget.albumName}"?',
                      style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'This removes the album organisation. Photos inside the album will remain safe in your photo library and cloud.',
                      style: TextStyle(color: secondaryTextColor, fontSize: 13),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorRed,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await mediaDao.deleteAlbum(widget.albumId);
                  if (context.mounted) {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Album "${widget.albumName}" deleted'),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 18),
                    SizedBox(width: 8),
                    Text('Delete Album', style: TextStyle(color: AppColors.errorRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<MediaItem>>(
        stream: mediaDao.watchMediaInAlbum(widget.albumId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          final mediaList = snapshot.data!;
          if (mediaList.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_album_outlined,
                      size: 64,
                      color: secondaryTextColor,
                    ),
                    AppSpacing.gapVerticalL,
                    Text(
                      'No photos in this album yet',
                      style: AppTypography.bodyLarge(color: secondaryTextColor),
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
                key: ValueKey('grid_${density.crossAxisCount}'),
                padding: const EdgeInsets.all(4),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: density.crossAxisCount,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                  childAspectRatio: density.childAspectRatio,
                ),
                itemCount: mediaList.length,
                itemBuilder: (context, index) {
                  final item = mediaList[index];
                  return _AlbumMediaTile(
                    key: ValueKey(item.localId),
                    item: item,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AlbumMediaTile extends StatefulWidget {
  final MediaItem item;

  const _AlbumMediaTile({super.key, required this.item});

  @override
  State<_AlbumMediaTile> createState() => _AlbumMediaTileState();
}

class _AlbumMediaTileState extends State<_AlbumMediaTile>
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
        child: Container(
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
      ),
    );
  }
}
