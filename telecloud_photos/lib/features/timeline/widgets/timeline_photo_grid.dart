import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/cache/thumbnail_cache_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/google_photos_badge.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/sync_status_badge.dart';
import '../../../../shared/widgets/sync_status_border.dart';
import '../controllers/timeline_zoom_controller.dart';

class TimelinePhotoGrid extends StatelessWidget {
  final List<MediaItem> items;
  final TimelineTier tier;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final void Function(MediaItem item) onItemTap;
  final void Function(MediaItem item) onItemLongPress;
  final bool showSyncBadges;

  const TimelinePhotoGrid({
    super.key,
    required this.items,
    required this.tier,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onItemTap,
    required this.onItemLongPress,
    this.showSyncBadges = true,
  });

  @override
  Widget build(BuildContext context) {
    final isYearly = tier == TimelineTier.yearlyMosaic;
    final isSingle = tier == TimelineTier.singlePhoto;

    final boxFit = isSingle ? BoxFit.fitWidth : BoxFit.cover;

    final childAspectRatio =
        isSingle ? 1.25 : (tier == TimelineTier.monthlyGrid ? 1.0 : 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSingle ? 12 : 2,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: tier.columns,
          mainAxisSpacing: isYearly
              ? 1.0
              : (tier == TimelineTier.monthlyGrid
                  ? 1.5
                  : (isSingle ? 12.0 : 2.5)),
          crossAxisSpacing: isYearly
              ? 1.0
              : (tier == TimelineTier.monthlyGrid
                  ? 1.5
                  : (isSingle ? 12.0 : 2.5)),
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, itemIdx) {
          final item = items[itemIdx];
          final isSelected = selectedIds.contains(item.localId);

          return RepaintBoundary(
            child: MediaTile(
              key: ValueKey(item.localId),
              item: item,
              boxFit: boxFit,
              tier: tier,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              showSyncBadges: showSyncBadges,
              onTap: () => onItemTap(item),
              onLongPress: () => onItemLongPress(item),
            ),
          );
        },
      ),
    );
  }
}

class MediaTile extends StatefulWidget {
  final MediaItem item;
  final BoxFit boxFit;
  final TimelineTier tier;
  final bool isSelectionMode;
  final bool isSelected;
  final bool showSyncBadges;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MediaTile({
    super.key,
    required this.item,
    required this.boxFit,
    required this.tier,
    required this.isSelectionMode,
    required this.isSelected,
    this.showSyncBadges = true,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<MediaTile>
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
  void didUpdateWidget(covariant MediaTile oldWidget) {
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

    final isVideo = widget.item.mimeType.startsWith('video');
    final isSinglePhoto = widget.tier == TimelineTier.singlePhoto;
    final isYearly = widget.tier == TimelineTier.yearlyMosaic;
    final cacheDim = isSinglePhoto ? 600 : (isYearly ? 128 : 256);
    final syncStatus = SyncStatusBadge.fromMediaItem(widget.item);

    Widget imageWidget;
    if (_bytes != null) {
      imageWidget = Image.memory(
        _bytes!,
        fit: widget.boxFit,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        errorBuilder: (context, error, stackTrace) => const ShimmerLoading(),
      );
    } else if (widget.item.thumbnailPath != null &&
        widget.item.thumbnailPath!.isNotEmpty) {
      imageWidget = Image.file(
        File(widget.item.thumbnailPath!),
        fit: widget.boxFit,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        errorBuilder: (context, error, stackTrace) => const ShimmerLoading(),
      );
    } else {
      imageWidget = const ShimmerLoading();
    }

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'media_${widget.item.localId}',
            child: SyncStatusBorder(
              status: syncStatus,
              enabled: widget.showSyncBadges && !widget.isSelectionMode,
              borderRadius: isSinglePhoto ? 14 : (isYearly ? 1 : 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    isSinglePhoto ? 14 : (isYearly ? 1 : 3),
                  ),
                  border: widget.isSelected
                      ? Border.all(color: AppColors.primaryBlue, width: 3.5)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    isSinglePhoto
                        ? 12
                        : (isYearly ? 1 : (widget.isSelected ? 1 : 3)),
                  ),
                  child: Container(
                    color: const Color(0xFF141416),
                    child: imageWidget,
                  ),
                ),
              ),
            ),
          ),

          // Favorite badge
          if (widget.item.isFavorite && !isYearly && !widget.isSelectionMode)
            Positioned(
              top: isSinglePhoto ? 10 : 4,
              right: isSinglePhoto ? 10 : 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.errorRed,
                  size: isSinglePhoto ? 16 : 12,
                ),
              ),
            ),

          // 4-State Sync Status Badge (Feature 8)
          if (widget.showSyncBadges &&
              !isYearly &&
              !widget.isSelectionMode &&
              !widget.item.localId.startsWith('gp_'))
            Positioned(
              top: isSinglePhoto ? 10 : 4,
              left: isSinglePhoto ? 10 : 4,
              child: SyncStatusBadge(
                status: syncStatus,
                size: isSinglePhoto ? 14 : 11,
              ),
            ),

          // Google photos badge
          if (widget.item.localId.startsWith('gp_') &&
              !isYearly &&
              !widget.isSelectionMode)
            Positioned(
              top: isSinglePhoto ? 10 : 4,
              left: isSinglePhoto ? 10 : 4,
              child: GooglePhotosBadge(compact: !isSinglePhoto),
            ),

          // Video indicator
          if (isVideo && !isYearly)
            Positioned(
              bottom: isSinglePhoto ? 10 : 4,
              left: isSinglePhoto ? 10 : 4,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSinglePhoto ? 8 : 5,
                  vertical: isSinglePhoto ? 4 : 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(isSinglePhoto ? 6 : 4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: isSinglePhoto ? 16 : 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSinglePhoto ? 11 : 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Selection indicator checkbox overlay (Feature 5)
          if (widget.isSelectionMode)
            Positioned(
              top: isSinglePhoto ? 10 : 6,
              right: isSinglePhoto ? 10 : 6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.primaryBlue
                      : Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColors.primaryBlue
                        : Colors.white.withValues(alpha: 0.8),
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
