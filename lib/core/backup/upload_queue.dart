import 'dart:async';
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../database/tables/media_table.dart';
import '../utils/telecloud_logger.dart';

typedef UploadItemFunction =
    Future<bool> Function(
      MediaItem item, [
      int? itemIndex,
      int? totalBatchCount,
    ]);

class UploadQueue {
  final MediaDao mediaDao;
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  UploadQueue({required this.mediaDao});

  Future<void> processQueue({
    required UploadItemFunction uploadItem,
    void Function(int totalItems)? onBatchStart,
    void Function(MediaItem item)? onItemSuccess,
    void Function()? onBatchFinish,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;
    TeleCloudLogger.upload('Upload queue processor started.');

    try {
      final pendingStream = mediaDao.watchPendingUploads();
      await for (final items in pendingStream) {
        if (items.isEmpty) {
          TeleCloudLogger.upload('All pending uploads completed. Queue idle.');
          _isProcessing = false;
          onBatchFinish?.call();
          break;
        }

        final totalCount = items.length;
        TeleCloudLogger.upload('$totalCount items currently pending upload.');
        onBatchStart?.call(totalCount);

        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          if (!_isProcessing) {
            TeleCloudLogger.upload(
              'Upload queue processing stopped by user/power policy.',
            );
            break;
          }

          int attempts = 0;
          bool success = false;

          while (attempts < 3 && !success) {
            attempts++;
            TeleCloudLogger.upload(
              'Uploading "${item.filename}" (attempt $attempts of 3)...',
            );
            await mediaDao.updateUploadStatus(
              item.localId,
              UploadStatus.uploading,
            );
            success = await uploadItem(item, i + 1, totalCount);

            if (!success) {
              final delaySecs = (1 << attempts); // 2s, 4s, 8s backoff
              TeleCloudLogger.upload(
                'Upload failed for "${item.filename}". Retrying in ${delaySecs}s...',
              );
              await Future.delayed(Duration(seconds: delaySecs));
            }
          }

          if (success) {
            TeleCloudLogger.upload(
              'Successfully backed up "${item.filename}" to Telegram Cloud.',
            );
            await mediaDao.updateUploadStatus(item.localId, UploadStatus.done);
            onItemSuccess?.call(item);
          } else {
            TeleCloudLogger.upload(
              'Failed to back up "${item.filename}" after 3 attempts.',
            );
            await mediaDao.updateUploadStatus(
              item.localId,
              UploadStatus.failed,
            );
          }
        }
      }
    } catch (e) {
      TeleCloudLogger.upload('UploadQueue exception', error: e);
    } finally {
      _isProcessing = false;
      onBatchFinish?.call();
    }
  }

  void stop() {
    TeleCloudLogger.upload('Stopping upload queue...');
    _isProcessing = false;
  }
}
