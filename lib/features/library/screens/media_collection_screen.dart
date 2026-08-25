import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_elevation.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/widgets/shimmer_loading.dart';

class MediaCollectionScreen extends ConsumerStatefulWidget {
  final String categoryKey;
  final String categoryTitle;

  const MediaCollectionScreen({
    super.key,
    required this.categoryKey,
    required this.categoryTitle,
  });

  @override
  ConsumerState<MediaCollectionScreen> createState() =>
      _MediaCollectionScreenState();
}

class _MediaCollectionScreenState extends ConsumerState<MediaCollectionScreen> {
  int _crossAxisCount = 3;
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
    if (_pinchScale > 1.25 && _crossAxisCount > 2) {
      setState(() {
        _crossAxisCount--;
      });
      HapticFeedback.selectionClick();
    } else if (_pinchScale < 0.78 && _crossAxisCount < 5) {
      setState(() {
        _crossAxisCount++;
      });
      HapticFeedback.selectionClick();
    }

    setState(() {
      _isPinching = false;
      _pinchScale = 1.0;
    });
  }

  List<MediaItem> _filterItems(List<MediaItem> allItems) {
    final key = widget.categoryKey.toLowerCase().trim();
    switch (key) {
      case 'photos':
        return allItems.where((i) {
          if (i.isTrashed) return false;
          final fn = i.filename.toUpperCase();
          final isMotion = fn.startsWith('MVIMG_') ||
              fn.startsWith('LIVE_') ||
              fn.contains('_MOTION_PHOTO') ||
              fn.contains('_LIVEPHOTO') ||
              fn.contains('_MP.JPG') ||
              fn.contains('_MP.JPEG') ||
              fn.contains('.MOTION.') ||
              i.mimeType == 'image/x-motion-photo' ||
              i.mimeType == 'image/x-livephoto';
          final isImage = i.mimeType.startsWith('image') ||
              fn.endsWith('.JPG') ||
              fn.endsWith('.JPEG') ||
              fn.endsWith('.PNG') ||
              fn.endsWith('.WEBP') ||
              fn.endsWith('.HEIC');
          return isImage && !isMotion;
        }).toList();
      case 'videos':
        return allItems.where((i) {
          if (i.isTrashed) return false;
          final fn = i.filename.toUpperCase();
          return i.mimeType.startsWith('video') ||
              fn.endsWith('.MP4') ||
              fn.endsWith('.MOV') ||
              fn.endsWith('.MKV') ||
              fn.endsWith('.AVI') ||
              fn.endsWith('.WEBM');
        }).toList();
      case 'live_photos':
      case 'livephotos':
      case 'motion_photos':
        return allItems.where((i) {
          if (i.isTrashed) return false;
          final fn = i.filename.toUpperCase();
          final isMotionName = fn.startsWith('MVIMG_') ||
              fn.startsWith('LIVE_') ||
              fn.contains('_MOTION_PHOTO') ||
              fn.contains('_LIVEPHOTO') ||
              fn.contains('_MP.JPG') ||
              fn.contains('_MP.JPEG') ||
              fn.contains('.MOTION.');
          final isMotionMime = i.mimeType == 'image/x-motion-photo' ||
              i.mimeType == 'image/x-livephoto';
          return isMotionName || isMotionMime;
        }).toList();
      case 'screenshots':
        return allItems.where((i) {
          if (i.isTrashed) return false;
          final fn = i.filename.toLowerCase();
          final fName = i.folderName?.toLowerCase() ?? '';
          return fn.contains('screenshot') ||
              fn.contains('screen_shot') ||
              fName.contains('screenshot');
        }).toList();
      case 'favorites':
        return allItems.where((i) => i.isFavorite && !i.isTrashed).toList();
      case 'selfies':
        return allItems.where((i) {
          if (i.isTrashed) return false;
          final fn = i.filename.toLowerCase();
          return fn.startsWith('selfie_') ||
              fn.contains('_selfie_') ||
              fn.contains('_portrait_');
        }).toList();
      case 'panoramas':
        return allItems.where((i) {
          if (i.isTrashed) return false;
          final fn = i.filename.toUpperCase();
          final isPanoAspect = i.width != null &&
              i.height != null &&
              i.height! > 0 &&
              (i.width! / i.height! >= 2.4 || i.height! / i.width! >= 2.4);
          return fn.startsWith('PANO_') ||
              fn.contains('_PANO_') ||
              fn.contains('_PANORAMA') ||
              isPanoAspect;
        }).toList();
      case 'raw':
        return allItems.where((i) {
          if (i.isTrashed) return false;
          final fn = i.filename.toLowerCase();
          return fn.endsWith('.dng') ||
              fn.endsWith('.cr2') ||
              fn.endsWith('.arw') ||
              fn.endsWith('.nef') ||
              fn.endsWith('.raw') ||
              fn.endsWith('.orf') ||
              fn.endsWith('.rw2');
        }).toList();
      case 'imports':
        return allItems.where((i) {
          if (i.isTrashed) return false;
          final fName = i.folderName?.toLowerCase() ?? '';
          return i.localId.startsWith('gp_') ||
              fName == 'imports' ||
              fName.contains('import') ||
              fName.contains('google photos') ||
              i.telegramFileId != null;
        }).toList();
      default:
        // Match custom device folder name or path
        return allItems.where((i) {
          if (i.isTrashed) return false;
          final fName = i.folderName?.toLowerCase() ?? '';
          final fPath = i.folderPath?.toLowerCase() ?? '';
          return fName == key ||
              fName.contains(key) ||
              key.contains(fName) && fName.isNotEmpty ||
              fPath.toLowerCase().contains('/$key') ||
              fPath.toLowerCase().endsWith(key);
        }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMedia = ref.watch(allMediaStreamProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor =
        isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;
    final secondaryTextColor =
        isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.categoryTitle,
              style: AppTypography.titleLarge(
                color: primaryTextColor,
              ).copyWith(fontWeight: AppTypography.bold),
            ),
            asyncMedia.maybeWhen(
              data: (items) {
                final filtered = _filterItems(items);
                return Text(
                  '${filtered.length} ${filtered.length == 1 ? 'item' : 'items'}',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: asyncMedia.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
        error: (err, st) => Center(
          child: Text(
            'Error loading media',
            style: TextStyle(color: secondaryTextColor),
          ),
        ),
        data: (allItems) {
          final items = _filterItems(allItems);

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: secondaryTextColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.categoryTitle}',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Photos matching this category will appear here',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return GestureDetector(
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            child: GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                childAspectRatio: 1.0,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _CollectionMediaTile(
                  key: ValueKey(item.localId),
                  item: item,
                  isLight: isLight,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CollectionMediaTile extends StatefulWidget {
  final MediaItem item;
  final bool isLight;

  const _CollectionMediaTile({
    super.key,
    required this.item,
    required this.isLight,
  });

  @override
  State<_CollectionMediaTile> createState() => _CollectionMediaTileState();
}

class _CollectionMediaTileState extends State<_CollectionMediaTile>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _bytes;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _CollectionMediaTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.localId != widget.item.localId) {
      _loadThumbnail();
    }
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

    final isVideo = widget.item.mimeType.startsWith('video');
    final bytes = await ThumbnailCacheService().getThumbnail(
      id: widget.item.localId,
      diskPath: widget.item.thumbnailPath,
      isVideo: isVideo,
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

    final item = widget.item;
    final isVideo = item.mimeType.startsWith('video') ||
        item.filename.toLowerCase().endsWith('.mp4') ||
        item.filename.toLowerCase().endsWith('.mov');
    final isMotion = item.filename.toUpperCase().startsWith('MVIMG_') ||
        item.filename.toUpperCase().contains('MOTION') ||
        item.filename.toUpperCase().contains('LIVE');

    Widget thumbnailWidget;
    if (_bytes != null) {
      thumbnailWidget = Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        cacheWidth: 256,
        cacheHeight: 256,
        errorBuilder: (context, error, stackTrace) => const ShimmerLoading(),
      );
    } else if (item.thumbnailPath != null &&
        item.thumbnailPath!.isNotEmpty &&
        File(item.thumbnailPath!).existsSync()) {
      thumbnailWidget = Image.file(
        File(item.thumbnailPath!),
        fit: BoxFit.cover,
        cacheWidth: 256,
        cacheHeight: 256,
        errorBuilder: (context, error, stackTrace) => const ShimmerLoading(),
      );
    } else {
      thumbnailWidget = const ShimmerLoading();
    }

    return GestureDetector(
      onTap: () => context.push('/viewer/${item.localId}'),
      child: Hero(
        tag: 'media_${item.localId}',
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              thumbnailWidget,
              if (isVideo)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              if (isMotion)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.motion_photos_on_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
