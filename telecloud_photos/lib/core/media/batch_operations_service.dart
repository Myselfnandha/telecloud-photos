import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../utils/telecloud_logger.dart';

class BatchOperationsService {
  final MediaDao mediaDao;

  BatchOperationsService({required this.mediaDao});

  /// Move selected media items to trash
  Future<int> batchDelete(List<String> localIds) async {
    if (localIds.isEmpty) return 0;
    TeleCloudLogger.log('BatchOps', 'Moving ${localIds.length} items to trash');
    return await mediaDao.moveToTrash(localIds);
  }

  /// Restore selected media items from trash
  Future<int> batchRestore(List<String> localIds) async {
    if (localIds.isEmpty) return 0;
    TeleCloudLogger.log(
        'BatchOps', 'Restoring ${localIds.length} items from trash');
    return await mediaDao.restoreFromTrash(localIds);
  }

  /// Permanently purge selected media items
  Future<int> batchPurge(List<String> localIds) async {
    if (localIds.isEmpty) return 0;
    TeleCloudLogger.log(
        'BatchOps', 'Purging ${localIds.length} items permanently');
    return await mediaDao.purgeTrashItems(localIds);
  }

  /// Toggle favorite for multiple items
  Future<int> batchToggleFavorite(
    List<String> localIds, {
    required bool isFavorite,
  }) async {
    int count = 0;
    for (final id in localIds) {
      final ok = await mediaDao.toggleFavorite(id, isFavorite);
      if (ok) count++;
    }
    TeleCloudLogger.log(
      'BatchOps',
      'Toggled favorite ($isFavorite) for $count items',
    );
    return count;
  }

  /// Assign multiple items to an album
  Future<void> batchAddToAlbum(List<String> localIds, int albumId) async {
    for (final id in localIds) {
      await mediaDao.assignMediaToAlbum(id, albumId);
    }
    TeleCloudLogger.log(
      'BatchOps',
      'Added ${localIds.length} items to album ID $albumId',
    );
  }

  /// Export original media files to a designated folder on device
  Future<int> batchExport(
    List<MediaItem> items, {
    String? destinationFolderPath,
  }) async {
    int exportedCount = 0;
    Directory targetDir;

    if (destinationFolderPath != null && destinationFolderPath.isNotEmpty) {
      targetDir = Directory(destinationFolderPath);
    } else {
      try {
        final extDir = await getExternalStorageDirectory();
        final basePath = extDir?.path ?? (await getApplicationDocumentsDirectory()).path;
        targetDir = Directory('$basePath/TeleCloud_Export');
      } catch (_) {
        targetDir = Directory('${Directory.systemTemp.path}/TeleCloud_Export');
      }
    }

    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    for (final item in items) {
      try {
        final asset = await AssetEntity.fromId(item.localId);
        final file = await asset?.file;
        final sourcePath = file?.path ?? item.thumbnailPath;

        if (sourcePath != null && File(sourcePath).existsSync()) {
          final destFile = File('${targetDir.path}/${item.filename}');
          await File(sourcePath).copy(destFile.path);
          exportedCount++;
        }
      } catch (e) {
        TeleCloudLogger.log(
            'BatchOps', 'Export error for ${item.filename}: $e');
      }
    }

    TeleCloudLogger.log(
      'BatchOps',
      'Exported $exportedCount of ${items.length} items to ${targetDir.path}',
    );
    return exportedCount;
  }
}
