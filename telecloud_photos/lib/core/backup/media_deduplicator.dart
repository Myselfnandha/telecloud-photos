import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../database/tables/media_table.dart';
import '../utils/telecloud_logger.dart';

class MediaDeduplicator {
  final MediaDao mediaDao;

  MediaDeduplicator({required this.mediaDao});

  /// Computes SHA-256 hash for a file using streaming chunks to minimize memory footprint.
  Future<String> computeFileSha256(File file) async {
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  }

  /// Checks if a local media item has a cloud duplicate.
  /// If found, copies Telegram cloud references directly to SQLite, bypassing network upload.
  /// Returns `true` if deduplicated (cloud reference reused), `false` if unique (requires upload).
  Future<bool> checkAndDeduplicate({
    required MediaItem localItem,
    required File file,
  }) async {
    try {
      // 1. Get or compute SHA-256 hash
      String? hash = localItem.sha256Hash;
      if (hash == null || hash.isEmpty) {
        hash = await computeFileSha256(file);
        await mediaDao.updateMediaHash(localItem.localId, hash);
      }

      // 2. Check if identical content exists in Telegram Cloud
      final cloudDuplicate = await mediaDao.getBackedUpMediaBySha256(hash);

      if (cloudDuplicate != null &&
          cloudDuplicate.localId != localItem.localId &&
          cloudDuplicate.telegramFileId != null) {
        TeleCloudLogger.upload(
          'Deduplication match! "${localItem.filename}" is identical to backed-up item "${cloudDuplicate.filename}" (SHA: ${hash.substring(0, 8)}...). Linking Telegram Cloud reference.',
        );

        // Instant cloud link in local database
        await mediaDao.updateUploadStatus(
          localItem.localId,
          UploadStatus.done,
          msgId: cloudDuplicate.telegramMsgId,
          fileId: cloudDuplicate.telegramFileId,
        );
        return true;
      }
    } catch (e) {
      TeleCloudLogger.upload(
        'Deduplication check error for ${localItem.filename}: $e',
      );
    }
    return false;
  }

  /// Bulk background job to compute hashes for historical items
  Future<int> computeMissingHashes({
    required Future<File?> Function(String localId) getFileForLocalId,
    int batchSize = 30,
  }) async {
    int processed = 0;
    try {
      final unhashed =
          await mediaDao.getUncomputedHashLocalMedia(limit: batchSize);
      for (final item in unhashed) {
        final file = await getFileForLocalId(item.localId);
        if (file != null && await file.exists()) {
          final hash = await computeFileSha256(file);
          await mediaDao.updateMediaHash(item.localId, hash);
          processed++;
        }
      }
    } catch (e) {
      TeleCloudLogger.upload('Background hash computation error: $e');
    }
    return processed;
  }
}
