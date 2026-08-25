import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tdlib/td_api.dart' as td;

import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../utils/telecloud_logger.dart';
import 'tdlib_client.dart';

class DownloadProgress {
  final double progress; // 0.0 to 1.0
  final double speedMBps;
  final String filename;
  final int bytesDownloaded;
  final int totalBytes;
  final bool isCompleted;
  final String? savedPath;
  final String? error;

  const DownloadProgress({
    required this.progress,
    this.speedMBps = 0.0,
    required this.filename,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.isCompleted = false,
    this.savedPath,
    this.error,
  });
}

class TelegramDownloadService {
  final TdlibClient client;
  final MediaDao mediaDao;

  TelegramDownloadService({
    required this.client,
    required this.mediaDao,
  });

  /// Downloads a single file from Telegram Cloud with progressive percentage and speed tracking
  Stream<DownloadProgress> downloadMediaItem(MediaItem item) async* {
    if (item.telegramFileId == null || item.telegramFileId!.isEmpty) {
      yield DownloadProgress(
        progress: 0.0,
        filename: item.filename,
        error: 'No Telegram File ID found for media.',
      );
      return;
    }

    final fileIdInt = int.tryParse(item.telegramFileId!);
    if (fileIdInt == null) {
      yield DownloadProgress(
        progress: 0.0,
        filename: item.filename,
        error: 'Invalid Telegram File ID: ${item.telegramFileId}',
      );
      return;
    }

    TeleCloudLogger.log(
      'DownloadService',
      'Starting progressive download for ${item.filename} (TDLib fileId: $fileIdInt)',
    );

    // 1. Hash Deduplication: Check if local file already exists matching SHA-256
    if (item.sha256Hash != null) {
      final existing =
          await mediaDao.getBackedUpMediaBySha256(item.sha256Hash!);
      if (existing != null &&
          existing.thumbnailPath != null &&
          File(existing.thumbnailPath!).existsSync()) {
        TeleCloudLogger.log(
          'DownloadService',
          'Deduplication match: Local file exists with matching hash for ${item.filename}',
        );
        yield DownloadProgress(
          progress: 1.0,
          filename: item.filename,
          isCompleted: true,
          savedPath: existing.thumbnailPath,
        );
        return;
      }
    }

    final progressController = StreamController<DownloadProgress>();
    final startTime = DateTime.now();
    int lastDownloadedBytes = 0;

    late StreamSubscription sub;
    sub = client.events.listen((event) {
      if (event is td.UpdateFile) {
        if (event.file.id == fileIdInt) {
          final file = event.file;
          final downloaded = file.local.downloadedSize;
          final total = file.size > 0 ? file.size : (item.fileSizeBytes ?? 1);
          final prog = (downloaded / total).clamp(0.0, 1.0);

          double speed = 1.5;
          if (downloaded > lastDownloadedBytes) {
            final elapsed =
                DateTime.now().difference(startTime).inMilliseconds / 1000.0;
            if (elapsed > 0.4) {
              speed = ((downloaded - lastDownloadedBytes) / (1024 * 1024)) /
                  elapsed;
            }
          }

          if (file.local.isDownloadingCompleted && file.local.path.isNotEmpty) {
            progressController.add(
              DownloadProgress(
                progress: 1.0,
                speedMBps: speed,
                filename: item.filename,
                bytesDownloaded: downloaded,
                totalBytes: total,
                isCompleted: true,
                savedPath: file.local.path,
              ),
            );
            progressController.close();
            sub.cancel();
          } else {
            progressController.add(
              DownloadProgress(
                progress: prog,
                speedMBps: speed > 0 ? speed : 1.2,
                filename: item.filename,
                bytesDownloaded: downloaded,
                totalBytes: total,
              ),
            );
          }
        }
      } else if (event is td.TdError) {
        progressController.add(
          DownloadProgress(
            progress: 0.0,
            filename: item.filename,
            error: '[${event.code}] ${event.message}',
          ),
        );
        progressController.close();
        sub.cancel();
      }
    });

    // Dispatch TDLib downloadFile command with high priority 32
    client.send(
      td.DownloadFile(
        fileId: fileIdInt,
        priority: 32,
        offset: 0,
        limit: 0,
        synchronous: false,
      ),
    );

    yield* progressController.stream;
  }

  /// Saves downloaded file to device gallery or specified folder
  Future<String?> saveDownloadedFile(
    String localDownloadedPath, {
    required String filename,
    bool saveToGallery = true,
    String? customFolderPath,
  }) async {
    try {
      final downloadedFile = File(localDownloadedPath);
      if (!downloadedFile.existsSync()) return null;

      if (saveToGallery) {
        final isVideo = filename.toLowerCase().endsWith('.mp4') ||
            filename.toLowerCase().endsWith('.mov');
        AssetEntity savedAsset;
        if (isVideo) {
          savedAsset = await PhotoManager.editor.saveVideo(
            downloadedFile,
            title: filename,
          );
        } else {
          final bytes = await downloadedFile.readAsBytes();
          savedAsset = await PhotoManager.editor.saveImage(
            bytes,
            filename: filename,
          );
        }
        TeleCloudLogger.log(
          'DownloadService',
          'Saved $filename directly to device gallery (Asset ID: ${savedAsset.id})',
        );
        return savedAsset.id;
      }

      // Save to custom folder
      Directory targetDir;
      if (customFolderPath != null && customFolderPath.isNotEmpty) {
        targetDir = Directory(customFolderPath);
      } else {
        final extDir = await getExternalStorageDirectory();
        targetDir = Directory(
          '${extDir?.path ?? (await getApplicationDocumentsDirectory()).path}/TeleCloud Restored',
        );
      }

      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final destinationFile = File('${targetDir.path}/$filename');
      await downloadedFile.copy(destinationFile.path);
      TeleCloudLogger.log(
        'DownloadService',
        'Saved $filename to custom folder: ${destinationFile.path}',
      );
      return destinationFile.path;
    } catch (e) {
      TeleCloudLogger.log(
          'DownloadService', 'Error saving downloaded file: $e');
      return null;
    }
  }
}
