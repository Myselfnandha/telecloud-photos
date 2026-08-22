import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../utils/telecloud_logger.dart';
import '../backup/thumbnail_generator.dart';

class ReclaimableStorageInfo {
  final int totalCount;
  final int totalBytes;
  final List<MediaItem> items;

  const ReclaimableStorageInfo({
    required this.totalCount,
    required this.totalBytes,
    required this.items,
  });

  String get formattedSize {
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

class StorageCleanupService {
  final MediaDao mediaDao;

  StorageCleanupService({required this.mediaDao});

  /// Scans for backed up items that still occupy local device storage
  Future<ReclaimableStorageInfo> calculateReclaimableSpace() async {
    try {
      final backedUpItems = await mediaDao.getBackedUpLocalMedia();
      int totalBytes = 0;
      final eligibleItems = <MediaItem>[];

      for (final item in backedUpItems) {
        // Skip items that are already cloud-only placeholders
        if (item.localId.startsWith('tg_')) continue;

        final asset = await AssetEntity.fromId(item.localId);
        if (asset != null) {
          final size =
              item.fileSizeBytes ?? (await asset.file)?.lengthSync() ?? 0;
          totalBytes += size;
          eligibleItems.add(item);
        }
      }

      return ReclaimableStorageInfo(
        totalCount: eligibleItems.length,
        totalBytes: totalBytes,
        items: eligibleItems,
      );
    } catch (e) {
      TeleCloudLogger.backup('Error calculating reclaimable space: $e');
      return const ReclaimableStorageInfo(
        totalCount: 0,
        totalBytes: 0,
        items: [],
      );
    }
  }

  /// Safely removes backed-up photos from local Android storage while keeping cached thumbnails & cloud sync intact
  Future<int> freeUpDeviceSpace({
    required List<MediaItem> itemsToClean,
    void Function(int processed, int total)? onProgress,
  }) async {
    TeleCloudLogger.backup(
      'Starting Free Up Space for ${itemsToClean.length} items...',
    );
    int cleanedCount = 0;
    final assetIdsToDelete = <String>[];

    for (int i = 0; i < itemsToClean.length; i++) {
      final item = itemsToClean[i];
      try {
        // 1. Ensure a local thumbnail is generated and cached so the gallery remains fast & visible
        if (item.thumbnailPath == null ||
            !File(item.thumbnailPath!).existsSync()) {
          final asset = await AssetEntity.fromId(item.localId);
          if (asset != null) {
            final thumb = await ThumbnailGenerator.generateThumbnail(asset);
            if (thumb != null) {
              await mediaDao.updateThumbnailPath(item.localId, thumb);
            }
          }
        }

        assetIdsToDelete.add(item.localId);
      } catch (e) {
        TeleCloudLogger.backup(
          'Warning ensuring thumbnail for ${item.localId}: $e',
        );
      }

      onProgress?.call(i + 1, itemsToClean.length);
    }

    if (assetIdsToDelete.isNotEmpty) {
      try {
        // 2. Request Android OS deletion via PhotoManager
        final result = await PhotoManager.editor.deleteWithIds(
          assetIdsToDelete,
        );
        cleanedCount = result.length;
        TeleCloudLogger.backup(
          'Free Up Space completed: $cleanedCount local files removed from device.',
        );
      } catch (e) {
        TeleCloudLogger.backup('Error deleting local assets: $e');
      }
    }

    return cleanedCount;
  }
}
