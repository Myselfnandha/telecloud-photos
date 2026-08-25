import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../database/tables/media_table.dart';
import '../utils/telecloud_logger.dart';
import 'thumbnail_generator.dart';

class MediaScanner {
  final AppDatabase db;
  final MediaDao mediaDao;
  Future<void> Function()? onScanCompleted;
  Timer? _periodicTimer;
  bool _isScanning = false;

  MediaScanner({
    required this.db,
    required this.mediaDao,
    this.onScanCompleted,
  }) {
    startIncrementalListening();
  }

  Future<bool> requestPermissions() async {
    TeleCloudLogger.scanner('Requesting photo library permissions...');
    final state = await PhotoManager.requestPermissionExtend();
    final isAuth = state.isAuth || state.hasAccess;
    TeleCloudLogger.scanner('Photo library permission result: isAuth=$isAuth');
    return isAuth;
  }

  /// Instant batch metadata ingestion + asynchronous background thumbnail caching
  Future<void> scanCameraRoll() async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      final isGranted = await requestPermissions();
      if (!isGranted) {
        TeleCloudLogger.scanner(
          'Scan cancelled: photo permissions not granted.',
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final uploadMp4 = prefs.getBool(AppConstants.keyIncludeMp4Videos) ??
          prefs.getBool(AppConstants.keyIncludeVideos) ??
          AppConstants.defaultIncludeMp4Videos;
      final uploadMov = prefs.getBool(AppConstants.keyIncludeMovVideos) ??
          prefs.getBool(AppConstants.keyIncludeVideos) ??
          AppConstants.defaultIncludeMovVideos;
      final allowAnyVideos = uploadMp4 || uploadMov;

      final enabledFolderIds = prefs.getStringList(
        'telecloud_backup_folder_ids',
      );

      final requestType =
          allowAnyVideos ? RequestType.common : RequestType.image;
      final allAlbums = await PhotoManager.getAssetPathList(type: requestType);
      if (allAlbums.isEmpty) {
        TeleCloudLogger.scanner('No media albums found on device.');
        return;
      }

      // Check if user has explicitly configured folder whitelist or selected all
      final isAllExplicitlySelected = enabledFolderIds != null &&
          allAlbums.any(
            (a) =>
                a.isAll &&
                (enabledFolderIds.contains(a.id) ||
                    enabledFolderIds.contains(a.name)),
          );

      List<AssetPathEntity> targetAlbums;
      if (enabledFolderIds == null || isAllExplicitlySelected) {
        targetAlbums = allAlbums.where((a) => !a.isAll).toList();
        if (targetAlbums.isEmpty) {
          targetAlbums = allAlbums;
        }
      } else {
        targetAlbums = allAlbums.where((a) {
          if (a.isAll) return false;
          return enabledFolderIds.contains(a.id) ||
              enabledFolderIds.contains(a.name);
        }).toList();
      }

      final unthumbnailedAssets = <AssetEntity>[];
      final enabledAssetIds = <String>{};

      for (final album in targetAlbums) {
        final assetCount = await album.assetCountAsync;
        TeleCloudLogger.scanner(
          'Fast-scanning folder "${album.name}" ($assetCount items)...',
        );

        const pageSize = 80;
        final totalPages = (assetCount / pageSize).ceil();

        for (int page = 0; page < totalPages; page++) {
          final assets = await album.getAssetListPaged(
            page: page,
            size: pageSize,
          );
          final companions = <MediaItemsCompanion>[];

          for (final asset in assets) {
            if (asset.type == AssetType.video) {
              final title = (asset.title ?? '').toLowerCase();
              final isMov = title.endsWith('.mov');
              if (isMov && !uploadMov) continue;
              if (!isMov && !uploadMp4) continue;
            }

            unthumbnailedAssets.add(asset);
            enabledAssetIds.add(asset.id);

            final isMovVideo = asset.type == AssetType.video &&
                (asset.title?.toLowerCase().endsWith('.mov') ?? false);

            // Ingest device asset metadata without creating artificial albums
            companions.add(
              MediaItemsCompanion.insert(
                localId: asset.id,
                filename: asset.title ?? 'IMG_${asset.id}.jpg',
                capturedAt: asset.createDateTime.year > 1970
                    ? asset.createDateTime
                    : asset.modifiedDateTime,
                width: Value(asset.width),
                height: Value(asset.height),
                latitude: Value(asset.latitude),
                longitude: Value(asset.longitude),
                fileSizeBytes: const Value.absent(),
                mimeType: asset.type == AssetType.video
                    ? (isMovVideo ? 'video/quicktime' : 'video/mp4')
                    : 'image/jpeg',
                uploadStatus: UploadStatus.pending,
                albumId: const Value.absent(),
                thumbnailPath: const Value.absent(),
                folderName: Value(album.name),
                folderPath: Value(album.name),
              ),
            );
          }

          if (companions.isNotEmpty) {
            await mediaDao.insertOrIgnoreBatch(companions);
          }
        }
      }

      // Synchronize pending queue to strictly contain items from selected folders
      await mediaDao.syncPendingQueueScope(enabledAssetIds);

      TeleCloudLogger.scanner(
        'Fast metadata ingestion completed (${enabledAssetIds.length} items in backup scope). Starting background thumbnails & cloud sync...',
      );

      // Background unawaited thumbnail generation
      _processThumbnailsInBackground(unthumbnailedAssets);

      // Trigger cloud deduplication check
      onScanCompleted?.call();
    } catch (e) {
      TeleCloudLogger.scanner('Scan exception', error: e);
    } finally {
      _isScanning = false;
    }
  }

  void _processThumbnailsInBackground(List<AssetEntity> assets) {
    Future.microtask(() async {
      for (final asset in assets) {
        try {
          await ThumbnailGenerator.generateThumbnail(asset);
        } catch (_) {}
      }
    });
  }

  void startIncrementalListening() {
    TeleCloudLogger.scanner(
      'Starting incremental photo library change listener...',
    );
    PhotoManager.addChangeCallback((value) async {
      TeleCloudLogger.scanner(
        'Detected photo gallery change on device. Rescanning...',
      );
      await scanCameraRoll();
    });
    PhotoManager.startChangeNotify();
  }

  /// Manually scans a specific folder and queues all its items for immediate Telegram cloud upload.
  Future<int> queueFolderForUpload(AssetPathEntity folder) async {
    try {
      final isGranted = await requestPermissions();
      if (!isGranted) return 0;

      final assetCount = await folder.assetCountAsync;
      TeleCloudLogger.scanner(
        'Manually queueing folder "${folder.name}" ($assetCount items)...',
      );

      final unthumbnailedAssets = <AssetEntity>[];
      final assetIds = <String>[];

      const pageSize = 80;
      final totalPages = (assetCount / pageSize).ceil();

      for (int page = 0; page < totalPages; page++) {
        final assets = await folder.getAssetListPaged(
          page: page,
          size: pageSize,
        );
        final companions = <MediaItemsCompanion>[];

        for (final asset in assets) {
          unthumbnailedAssets.add(asset);
          assetIds.add(asset.id);

          final isMovVideo = asset.type == AssetType.video &&
              (asset.title?.toLowerCase().endsWith('.mov') ?? false);

          companions.add(
            MediaItemsCompanion.insert(
              localId: asset.id,
              filename: asset.title ?? 'IMG_${asset.id}.jpg',
              capturedAt: asset.createDateTime.year > 1970
                  ? asset.createDateTime
                  : asset.modifiedDateTime,
              width: Value(asset.width),
              height: Value(asset.height),
              latitude: Value(asset.latitude),
              longitude: Value(asset.longitude),
              fileSizeBytes: const Value.absent(),
              mimeType: asset.type == AssetType.video
                  ? (isMovVideo ? 'video/quicktime' : 'video/mp4')
                  : 'image/jpeg',
              uploadStatus: UploadStatus.pending,
              albumId: const Value.absent(),
              thumbnailPath: const Value.absent(),
              folderName: Value(folder.name),
              folderPath: Value(folder.name),
            ),
          );
        }

        if (companions.isNotEmpty) {
          await mediaDao.insertOrIgnoreBatch(companions);
        }
      }

      final queuedCount = await mediaDao.queueLocalIdsForUpload(assetIds);
      _processThumbnailsInBackground(unthumbnailedAssets);
      return queuedCount > 0 ? queuedCount : assetIds.length;
    } catch (e) {
      TeleCloudLogger.scanner('Manual queue folder exception', error: e);
      return 0;
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
  }
}
