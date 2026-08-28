import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/cache/thumbnail_cache_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/sync_status_badge.dart';
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

  static double getAspectRatio(MediaItem item) {
    final w = item.width ?? 0;
    final h = item.height ?? 0;
    if (w > 0 && h > 0) {
      // Keep natural photo aspect ratio clamped to safe bounds (0.5 to 2.0)
      return (w / h).clamp(0.5, 2.0);
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    if (tier == TimelineTier.singlePhoto) {
      return _buildSinglePhotoList(context);
    }

    if (tier == TimelineTier.yearlyMosaic || tier == TimelineTier.allPhotos) {
      // Ultra-dense 6-column continuous mosaic with 1px micro-spacing
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 1.0,
            crossAxisSpacing: 1.0,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, itemIdx) {
            final item = items[itemIdx];
            final isSelected = selectedIds.contains(item.localId);

            return RepaintBoundary(
              child: MediaTile(
                key: ValueKey(item.localId),
                item: item,
                boxFit: BoxFit.cover,
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

    // Adaptive column count based on available item count in this section
    final maxCols = tier == TimelineTier.monthlyGrid ? 4 : 3;
    final columns = items.length < maxCols ? items.length.clamp(1, maxCols) : maxCols;

    return _buildStaggeredGrid(context, columns);
  }

  Widget _buildSinglePhotoList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, itemIdx) {
        final item = items[itemIdx];
        final isSelected = selectedIds.contains(item.localId);
        final aspect = getAspectRatio(item);

        return AspectRatio(
          aspectRatio: aspect,
          child: RepaintBoundary(
            child: MediaTile(
              key: ValueKey(item.localId),
              item: item,
              boxFit: BoxFit.cover,
              tier: tier,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              showSyncBadges: showSyncBadges,
              onTap: () => onItemTap(item),
              onLongPress: () => onItemLongPress(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaggeredGrid(BuildContext context, int columns) {
    if (columns == 1) {
      final item = items.first;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: AspectRatio(
          aspectRatio: getAspectRatio(item),
          child: RepaintBoundary(
            child: MediaTile(
              key: ValueKey(item.localId),
              item: item,
              boxFit: BoxFit.cover,
              tier: tier,
              isSelectionMode: isSelectionMode,
              isSelected: selectedIds.contains(item.localId),
              showSyncBadges: showSyncBadges,
              onTap: () => onItemTap(item),
              onLongPress: () => onItemLongPress(item),
            ),
          ),
        ),
      );
    }

    final List<List<MediaItem>> columnItems = List.generate(columns, (_) => []);
    final List<double> columnHeights = List.filled(columns, 0.0);

    for (final item in items) {
      int minCol = 0;
      for (int i = 1; i < columns; i++) {
        if (columnHeights[i] < columnHeights[minCol]) {
          minCol = i;
        }
      }
      columnItems[minCol].add(item);
      final aspect = getAspectRatio(item);
      columnHeights[minCol] += (1.0 / aspect) + 0.02;
    }

    final double spacing = columns == 3 ? 2.5 : 1.5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < columns; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : spacing / 2,
                  right: i == columns - 1 ? 0 : spacing / 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in columnItems[i])
                      Padding(
                        padding: EdgeInsets.only(bottom: spacing),
                        child: AspectRatio(
                          aspectRatio: getAspectRatio(item),
                          child: RepaintBoundary(
                            child: MediaTile(
                              key: ValueKey(item.localId),
                              item: item,
                              boxFit: BoxFit.cover,
                              tier: tier,
                              isSelectionMode: isSelectionMode,
                              isSelected: selectedIds.contains(item.localId),
                              showSyncBadges: showSyncBadges,
                              onTap: () => onItemTap(item),
                              onLongPress: () => onItemLongPress(item),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
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

class _MediaTileState extends State<MediaTile> {
  Uint8List? _thumbBytes;
  bool _isLoading = false;

  bool get _isVideo =>
      widget.item.mimeType.startsWith('video') ||
      widget.item.filename.toLowerCase().endsWith('.mp4') ||
      widget.item.filename.toLowerCase().endsWith('.mov') ||
      widget.item.filename.toLowerCase().endsWith('.mkv');

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant MediaTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.localId != widget.item.localId ||
        oldWidget.item.thumbnailPath != widget.item.thumbnailPath) {
      _loadThumbnail();
    }
  }

  void _loadThumbnail() {
    final cached = ThumbnailCacheService().getFromMemory(widget.item.localId);
    if (cached != null) {
      _thumbBytes = cached;
      return;
    }

    if (_isLoading) return;
    _isLoading = true;

    ThumbnailCacheService()
        .getThumbnail(
          id: widget.item.localId,
          diskPath: widget.item.thumbnailPath,
          isVideo: _isVideo,
        )
        .then((bytes) {
          if (mounted && bytes != null) {
            setState(() {
              _thumbBytes = bytes;
              _isLoading = false;
            });
          } else {
            if (mounted) setState(() => _isLoading = false);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final isYearly = widget.tier == TimelineTier.yearlyMosaic;
    final isSinglePhoto = widget.tier == TimelineTier.singlePhoto;

    final int cacheDim = isYearly
        ? 100
        : (widget.tier == TimelineTier.monthlyGrid
            ? 250
            : (isSinglePhoto ? 1200 : 700));

    Widget imageWidget;
    if (_thumbBytes != null) {
      imageWidget = Image.memory(
        _thumbBytes!,
        fit: widget.boxFit,
        cacheWidth: cacheDim,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => const ShimmerLoading(),
      );
    } else if (widget.item.thumbnailPath != null &&
        widget.item.thumbnailPath!.isNotEmpty) {
      imageWidget = Image.file(
        File(widget.item.thumbnailPath!),
        fit: widget.boxFit,
        cacheWidth: cacheDim,
        filterQuality: FilterQuality.medium,
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
            flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
              return Material(
                color: Colors.transparent,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: toHeroContext.widget,
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  isSinglePhoto ? 12 : 0,
                ),
                border: widget.isSelected
                    ? Border.all(color: AppColors.primaryBlue, width: 3.5)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  isSinglePhoto ? 12 : (widget.isSelected ? 1 : 0),
                ),
                child: Container(
                  color: const Color(0xFF141416),
                  child: imageWidget,
                ),
              ),
            ),
          ),


          // Video duration pill
          if (_isVideo && !isYearly && !widget.isSelectionMode)
            Positioned(
              bottom: isSinglePhoto ? 10 : 4,
              right: isSinglePhoto ? 10 : 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Sync Status Badge (Only shown when Synced, Cloud-Only, or Uploading)
          if (widget.showSyncBadges && !isYearly && !widget.isSelectionMode) ...[
            Builder(
              builder: (context) {
                final status = SyncStatusBadge.fromMediaItem(widget.item);
                if (status == SyncStatus.localOnly) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  top: isSinglePhoto ? 10 : 4,
                  left: isSinglePhoto ? 10 : 4,
                  child: SyncStatusBadge(
                    status: status,
                    compact: true,
                  ),
                );
              },
            ),
          ],

          // Multi-Select Checkmark Overlay
          if (widget.isSelectionMode)
            Positioned(
              top: isSinglePhoto ? 10 : 6,
              right: isSinglePhoto ? 10 : 6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected
                      ? AppColors.primaryBlue
                      : Colors.black.withValues(alpha: 0.4),
                  border: Border.all(
                    color: widget.isSelected ? Colors.white : Colors.white70,
                    width: 1.5,
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
