import 'dart:io';
import 'package:photo_manager/photo_manager.dart';

import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../utils/telecloud_logger.dart';

class DeletedMediaDetector {
  final MediaDao mediaDao;

  DeletedMediaDetector({required this.mediaDao});

  /// Detects media items that are backed up to cloud but no longer present in local storage
  Future<List<MediaItem>> detectDeletedFromDevice() async {
    TeleCloudLogger.log(
      'DeletedMediaDetector',
      'Scanning for local media deleted from device...',
    );

    // Get all media with done upload status and valid Telegram cloud reference
    final backedUp = await mediaDao.getBackedUpLocalMedia();
    final deletedItems = <MediaItem>[];

    for (final item in backedUp) {
      bool exists = false;
      try {
        final asset = await AssetEntity.fromId(item.localId);
        if (asset != null) {
          final file = await asset.file;
          if (file != null && file.existsSync()) {
            exists = true;
          }
        }
        if (!exists &&
            item.thumbnailPath != null &&
            File(item.thumbnailPath!).existsSync()) {
          exists = true;
        }
      } catch (_) {
        exists = false;
      }

      if (!exists) {
        deletedItems.add(item);
      }
    }

    TeleCloudLogger.log(
      'DeletedMediaDetector',
      'Detected ${deletedItems.length} cloud-backed items deleted from device.',
    );
    return deletedItems;
  }

  /// Automatically reconciles items deleted from device so the timeline remains seamless
  Future<int> reconcileDeletedFromDevice() async {
    final deleted = await detectDeletedFromDevice();
    if (deleted.isEmpty) return 0;
    // Mark as cloud items or preserve thumbnail path
    final ids = deleted.map((e) => e.localId).toList();
    return await mediaDao.markAsCloudOnly(ids);
  }
}
