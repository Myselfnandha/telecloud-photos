import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../database/tables/media_table.dart';
import '../telegram/channel_manager.dart';
import '../telegram/telegram_upload_service.dart';
import '../cache/thumbnail_cache_service.dart';
import 'google_photos_api_client.dart';

class GooglePhotosSyncTelemetry {
  final bool isSyncing;
  final int totalItems;
  final int importedCount;
  final int skippedDuplicatesCount;
  final double currentProgress;
  final GooglePhotosMediaItem? currentItem;
  final double speedMBps;
  final DateTime? lastSyncTime;
  final String statusMessage;

  const GooglePhotosSyncTelemetry({
    this.isSyncing = false,
    this.totalItems = 0,
    this.importedCount = 0,
    this.skippedDuplicatesCount = 0,
    this.currentProgress = 0.0,
    this.currentItem,
    this.speedMBps = 0.0,
    this.lastSyncTime,
    this.statusMessage = 'Idle',
  });

  GooglePhotosSyncTelemetry copyWith({
    bool? isSyncing,
    int? totalItems,
    int? importedCount,
    int? skippedDuplicatesCount,
    double? currentProgress,
    GooglePhotosMediaItem? currentItem,
    double? speedMBps,
    DateTime? lastSyncTime,
    String? statusMessage,
  }) {
    return GooglePhotosSyncTelemetry(
      isSyncing: isSyncing ?? this.isSyncing,
      totalItems: totalItems ?? this.totalItems,
      importedCount: importedCount ?? this.importedCount,
      skippedDuplicatesCount:
          skippedDuplicatesCount ?? this.skippedDuplicatesCount,
      currentProgress: currentProgress ?? this.currentProgress,
      currentItem: currentItem ?? this.currentItem,
      speedMBps: speedMBps ?? this.speedMBps,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class GooglePhotosSyncService extends ChangeNotifier {
  static const String keyGoogleAutoSync = 'google_auto_sync_enabled';
  static const String keyGoogleLastSync = 'google_last_sync_timestamp';

  final GooglePhotosApiClient _apiClient;
  final MediaDao _mediaDao;
  final ChannelManager _channelManager;
  final TelegramUploadService _uploadService;
  final SharedPreferences _prefs;

  GooglePhotosSyncTelemetry _telemetry = const GooglePhotosSyncTelemetry();
  GooglePhotosSyncTelemetry get telemetry => _telemetry;

  bool _isCancelled = false;

  GooglePhotosSyncService({
    required GooglePhotosApiClient apiClient,
    required MediaDao mediaDao,
    required ChannelManager channelManager,
    required TelegramUploadService uploadService,
    required SharedPreferences prefs,
  }) : _apiClient = apiClient,
       _mediaDao = mediaDao,
       _channelManager = channelManager,
       _uploadService = uploadService,
       _prefs = prefs {
    final lastSyncMillis = _prefs.getInt(keyGoogleLastSync);
    if (lastSyncMillis != null) {
      _telemetry = _telemetry.copyWith(
        lastSyncTime: DateTime.fromMillisecondsSinceEpoch(lastSyncMillis),
      );
    }
  }

  bool get isAutoSyncEnabled => _prefs.getBool(keyGoogleAutoSync) ?? true;

  Future<void> setAutoSync(bool enabled) async {
    await _prefs.setBool(keyGoogleAutoSync, enabled);
    notifyListeners();
  }

  void cancelSync() {
    _isCancelled = true;
    _telemetry = _telemetry.copyWith(
      isSyncing: false,
      statusMessage: 'Sync cancelled by user',
    );
    notifyListeners();
  }

  /// Starts the direct streaming pipeline from Google Photos to Telegram Cloud
  Future<void> startImport({
    String? albumId,
    String? albumTitle,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_telemetry.isSyncing) return;

    _isCancelled = false;
    _telemetry = _telemetry.copyWith(
      isSyncing: true,
      totalItems: 0,
      importedCount: 0,
      skippedDuplicatesCount: 0,
      currentProgress: 0.0,
      statusMessage: 'Connecting to Google Photos & Telegram Cloud...',
    );
    notifyListeners();

    try {
      final channelId = await _channelManager.ensureBackupChannel();
      if (channelId == null) {
        _telemetry = _telemetry.copyWith(
          isSyncing: false,
          statusMessage: 'Telegram Cloud Channel not ready',
        );
        notifyListeners();
        return;
      }

      _telemetry = _telemetry.copyWith(
        statusMessage: 'Discovering Google Photos media...',
      );
      notifyListeners();

      final items = await _apiClient.listMediaItems(
        pageSize: 50,
        startDate: startDate,
        endDate: endDate,
        albumId: albumId,
        albumTitle: albumTitle,
      );

      if (items.isEmpty) {
        _telemetry = _telemetry.copyWith(
          isSyncing: false,
          statusMessage: 'No new photos found to import',
        );
        notifyListeners();
        return;
      }

      _telemetry = _telemetry.copyWith(
        totalItems: items.length,
        statusMessage: 'Starting stream transfer for ${items.length} items...',
      );
      notifyListeners();

      final tempDir = await getTemporaryDirectory();
      final syncCacheDir = Directory(p.join(tempDir.path, 'google_sync_cache'));
      if (!syncCacheDir.existsSync()) {
        syncCacheDir.createSync(recursive: true);
      }

      int imported = 0;
      int skipped = 0;

      for (int i = 0; i < items.length; i++) {
        if (_isCancelled) break;

        final item = items[i];
        final progress = (i + 1) / items.length;

        _telemetry = _telemetry.copyWith(
          currentItem: item,
          currentProgress: progress,
          statusMessage:
              'Processing ${i + 1}/${items.length}: ${item.filename}',
        );
        notifyListeners();

        // 1. Smart Deduplication Check
        final existing = await _mediaDao.getMediaById('gp_${item.id}');
        if (existing != null) {
          skipped++;
          _telemetry = _telemetry.copyWith(skippedDuplicatesCount: skipped);
          notifyListeners();
          continue;
        }

        // 2. Resolve Album
        int? resolvedAlbumId;
        int? topicId;
        final targetAlbum = item.albumTitle ?? albumTitle ?? 'Google Photos';
        if (targetAlbum.isNotEmpty) {
          final allAlbums = await _mediaDao.getAllAlbums();
          final match = allAlbums
              .where((a) => a.name.toLowerCase() == targetAlbum.toLowerCase())
              .firstOrNull;
          if (match != null) {
            resolvedAlbumId = match.id;
            topicId = match.telegramTopicId;
          } else {
            topicId = await _channelManager.ensureAlbumTopic(targetAlbum);
            resolvedAlbumId = await _mediaDao.createAlbum(
              targetAlbum,
              topicId: topicId,
            );
          }
        }

        try {
          // 3. Stream download from Google CDN
          final tempFilePath = p.join(
            syncCacheDir.path,
            '${item.id}_${item.filename}',
          );
          final stopwatch = Stopwatch()..start();

          final downloadedFile = await _apiClient.downloadMediaStream(
            item,
            tempFilePath,
            onProgress: (received, total) {
              if (total > 0) {
                final fileProg = received / total;
                final overallProg = (i + fileProg) / items.length;
                final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
                final speed = elapsedSec > 0
                    ? (received / (1024 * 1024)) / elapsedSec
                    : 0.0;

                _telemetry = _telemetry.copyWith(
                  currentProgress: overallProg,
                  speedMBps: speed,
                );
                notifyListeners();
              }
            },
          );

          // 4. Create lightweight thumbnail in local persistent storage
          final docDir = await getApplicationDocumentsDirectory();
          final thumbDir = Directory(p.join(docDir.path, 'thumbnails'));
          if (!thumbDir.existsSync()) thumbDir.createSync(recursive: true);
          final thumbPath = p.join(thumbDir.path, 'gp_${item.id}.jpg');
          try {
            if (downloadedFile.existsSync()) {
              final bytes = downloadedFile.readAsBytesSync();
              File(thumbPath).writeAsBytesSync(bytes);
              ThumbnailCacheService().putInMemory('gp_${item.id}', bytes);
            }
          } catch (_) {}

          // 5. Upload directly to Telegram Cloud Channel
          int? telegramMsgId;
          if (downloadedFile.existsSync()) {
            telegramMsgId = await _uploadService.uploadDirectFile(
              file: downloadedFile,
              filename: item.filename,
              capturedAt: item.creationTime,
              targetChatId: channelId,
              topicId: topicId,
              albumName: targetAlbum,
              width: item.width,
              height: item.height,
              latitude: item.latitude,
              longitude: item.longitude,
            );

            // Purge full download temporary file immediately to keep phone storage clean
            try {
              if (downloadedFile.existsSync()) {
                downloadedFile.deleteSync();
              }
            } catch (e) {
              debugPrint('[GooglePhotosSyncService] Temp purge notice: $e');
            }
          }

          // 6. Record in Database
          await _mediaDao.insertOrIgnoreBatch([
            MediaItemsCompanion.insert(
              localId: 'gp_${item.id}',
              filename: item.filename,
              capturedAt: item.creationTime,
              mimeType: item.mimeType,
              uploadStatus: UploadStatus.done,
              thumbnailPath: Value(thumbPath),
              telegramMsgId: telegramMsgId != null
                  ? Value(telegramMsgId)
                  : const Value.absent(),
              telegramFileId: telegramMsgId != null
                  ? Value('tg_file_gp_${item.id}')
                  : const Value.absent(),
              width: item.width != null
                  ? Value(item.width)
                  : const Value.absent(),
              height: item.height != null
                  ? Value(item.height)
                  : const Value.absent(),
              latitude: item.latitude != null
                  ? Value(item.latitude)
                  : const Value.absent(),
              longitude: item.longitude != null
                  ? Value(item.longitude)
                  : const Value.absent(),
              albumId: resolvedAlbumId != null
                  ? Value(resolvedAlbumId)
                  : const Value.absent(),
            ),
          ]);

          imported++;
          _telemetry = _telemetry.copyWith(
            importedCount: imported,
            skippedDuplicatesCount: skipped,
          );
          notifyListeners();
        } catch (itemErr) {
          debugPrint(
            '[GooglePhotosSyncService] Error importing item ${item.id}: $itemErr',
          );
          skipped++;
          _telemetry = _telemetry.copyWith(
            skippedDuplicatesCount: skipped,
          );
          notifyListeners();
        }
      }

      final now = DateTime.now();
      await _prefs.setInt(keyGoogleLastSync, now.millisecondsSinceEpoch);

      _telemetry = _telemetry.copyWith(
        isSyncing: false,
        currentItem: null,
        currentProgress: 1.0,
        lastSyncTime: now,
        statusMessage: _isCancelled
            ? 'Import paused. $imported photos safely backed up.'
            : 'Successfully imported $imported photos from Google Photos!',
      );
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[GooglePhotosSyncService] Error during Google Photos sync: $e',
      );
      _telemetry = _telemetry.copyWith(
        isSyncing: false,
        statusMessage: 'Sync encountered an error: $e',
      );
      notifyListeners();
    }
  }
}
