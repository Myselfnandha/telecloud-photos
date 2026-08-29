import 'dart:async';
import 'package:photo_manager/photo_manager.dart';

import '../cache/thumbnail_cache_service.dart';
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../utils/telecloud_logger.dart';

enum CleanStage {
  idle,
  cachingThumbnails,
  deletingLocalFiles,
  updatingDatabase,
  completed,
  failed,
}

class StorageCleanProgress {
  final CleanStage stage;
  final int totalItems;
  final int processedItems;
  final int totalBytes;
  final int reclaimedBytes;
  final String currentFileName;

  const StorageCleanProgress({
    this.stage = CleanStage.idle,
    this.totalItems = 0,
    this.processedItems = 0,
    this.totalBytes = 0,
    this.reclaimedBytes = 0,
    this.currentFileName = '',
  });

  double get progressPercentage =>
      totalItems > 0 ? (processedItems / totalItems).clamp(0.0, 1.0) : 0.0;

  String get formattedReclaimed => formatBytes(reclaimedBytes);
  String get formattedTotal => formatBytes(totalBytes);

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }
}

class StorageCleanSummary {
  final int totalItems;
  final int photoCount;
  final int videoCount;
  final int totalBytes;

  const StorageCleanSummary({
    this.totalItems = 0,
    this.photoCount = 0,
    this.videoCount = 0,
    this.totalBytes = 0,
  });

  String get formattedSize => StorageCleanProgress.formatBytes(totalBytes);
  bool get hasReclaimableSpace => totalItems > 0 && totalBytes > 0;
}

class StorageCleanResult {
  final bool success;
  final int cleanedItemCount;
  final int reclaimedBytes;
  final String formattedReclaimed;
  final String? errorMessage;
  final bool userCancelled;

  const StorageCleanResult({
    required this.success,
    this.cleanedItemCount = 0,
    this.reclaimedBytes = 0,
    this.formattedReclaimed = '0 B',
    this.errorMessage,
    this.userCancelled = false,
  });
}

typedef LocalAssetDeleter = Future<List<String>> Function(List<String> ids);

class StorageCleanerService {
  final MediaDao mediaDao;
  final ThumbnailCacheService thumbnailCacheService;

  final _progressController =
      StreamController<StorageCleanProgress>.broadcast();
  Stream<StorageCleanProgress> get progressStream => _progressController.stream;

  StorageCleanProgress _lastProgress = const StorageCleanProgress();
  StorageCleanProgress get currentProgress => _lastProgress;

  bool _isCleaning = false;
  bool get isCleaning => _isCleaning;

  StorageCleanerService({
    required this.mediaDao,
    ThumbnailCacheService? thumbnailCacheService,
  }) : thumbnailCacheService =
            thumbnailCacheService ?? ThumbnailCacheService();

  void _emitProgress({
    CleanStage? stage,
    int? totalItems,
    int? processedItems,
    int? totalBytes,
    int? reclaimedBytes,
    String? currentFileName,
  }) {
    _lastProgress = StorageCleanProgress(
      stage: stage ?? _lastProgress.stage,
      totalItems: totalItems ?? _lastProgress.totalItems,
      processedItems: processedItems ?? _lastProgress.processedItems,
      totalBytes: totalBytes ?? _lastProgress.totalBytes,
      reclaimedBytes: reclaimedBytes ?? _lastProgress.reclaimedBytes,
      currentFileName: currentFileName ?? _lastProgress.currentFileName,
    );
    if (!_progressController.isClosed) {
      _progressController.add(_lastProgress);
    }
  }

  /// Calculates real-time breakdown of reclaimable media.
  Future<StorageCleanSummary> getStorageSummary() async {
    final eligible = await mediaDao.getFreeUpSpaceEligibleItems();
    int photoCount = 0;
    int videoCount = 0;
    int totalBytes = 0;

    for (final item in eligible) {
      final isVideo = item.mimeType.startsWith('video') ||
          item.filename.toLowerCase().endsWith('.mp4') ||
          item.filename.toLowerCase().endsWith('.mov') ||
          item.filename.toLowerCase().endsWith('.mkv');

      if (isVideo) {
        videoCount++;
      } else {
        photoCount++;
      }
      totalBytes += item.fileSizeBytes ?? 0;
    }

    return StorageCleanSummary(
      totalItems: eligible.length,
      photoCount: photoCount,
      videoCount: videoCount,
      totalBytes: totalBytes,
    );
  }

  /// Executes the 5-stage cleaning pipeline to safely reclaim storage on device.
  Future<StorageCleanResult> freeUpSpace({
    List<MediaItem>? targetItems,
    LocalAssetDeleter? customDeleter,
  }) async {
    if (_isCleaning) {
      return const StorageCleanResult(
        success: false,
        errorMessage: 'Storage clean is already in progress.',
      );
    }

    _isCleaning = true;
    TeleCloudLogger.backup('StorageCleanerService: Starting Free Up Space...');

    try {
      final items = targetItems ?? await mediaDao.getFreeUpSpaceEligibleItems();

      if (items.isEmpty) {
        TeleCloudLogger.backup(
          'StorageCleanerService: No eligible backed-up items to free.',
        );
        _emitProgress(stage: CleanStage.completed);
        return const StorageCleanResult(
          success: true,
          cleanedItemCount: 0,
          reclaimedBytes: 0,
          formattedReclaimed: '0 B',
        );
      }

      final totalCount = items.length;
      final totalBytes =
          items.fold<int>(0, (sum, i) => sum + (i.fileSizeBytes ?? 0));

      _emitProgress(
        stage: CleanStage.cachingThumbnails,
        totalItems: totalCount,
        processedItems: 0,
        totalBytes: totalBytes,
        reclaimedBytes: 0,
        currentFileName: items.first.filename,
      );

      // Stage 1: Ensure all thumbnails are safely stored in persistent disk cache
      final updatedThumbnailPaths = <String, String>{};
      int cachedCount = 0;

      for (final item in items) {
        _emitProgress(
          stage: CleanStage.cachingThumbnails,
          processedItems: cachedCount,
          currentFileName: item.filename,
        );

        final isVideo = item.mimeType.startsWith('video') ||
            item.filename.toLowerCase().endsWith('.mp4');

        final diskPath = await thumbnailCacheService.ensureDiskThumbnailCached(
          item.localId,
          diskPath: item.thumbnailPath,
          isVideo: isVideo,
        );

        if (diskPath != null && diskPath.isNotEmpty) {
          updatedThumbnailPaths[item.localId] = diskPath;
        }
        cachedCount++;
      }

      // Stage 2: Batch delete local device files (requests Android MediaStore user consent)
      _emitProgress(
        stage: CleanStage.deletingLocalFiles,
        currentFileName: 'Requesting permission to delete...',
      );

      final localIdsToDelete = items.map((e) => e.localId).toList();
      List<String> successfullyDeletedIds = [];

      if (customDeleter != null) {
        successfullyDeletedIds = await customDeleter(localIdsToDelete);
      } else {
        try {
          successfullyDeletedIds = await PhotoManager.editor.deleteWithIds(
            localIdsToDelete,
          );
        } catch (e) {
          TeleCloudLogger.backup(
            'StorageCleanerService: MediaStore deletion error',
            error: e,
          );
          _emitProgress(stage: CleanStage.failed);
          return StorageCleanResult(
            success: false,
            errorMessage: 'MediaStore deletion failed: $e',
          );
        }
      }

      if (successfullyDeletedIds.isEmpty) {
        TeleCloudLogger.backup(
          'StorageCleanerService: User cancelled or 0 items deleted by MediaStore.',
        );
        _emitProgress(stage: CleanStage.idle);
        return const StorageCleanResult(
          success: false,
          userCancelled: true,
          errorMessage: 'User cancelled deletion request or no files removed.',
        );
      }

      // Stage 3: Update Drift database records with permanent disk thumbnail paths
      _emitProgress(
        stage: CleanStage.updatingDatabase,
        currentFileName: 'Updating local library index...',
      );

      await mediaDao.markAsCloudOnly(
        successfullyDeletedIds,
        updatedThumbnailPaths: updatedThumbnailPaths,
      );

      // Stage 4: Compute final stats
      final deletedSet = successfullyDeletedIds.toSet();
      final cleanedItems = items.where((i) => deletedSet.contains(i.localId));
      final actualReclaimedBytes =
          cleanedItems.fold<int>(0, (sum, i) => sum + (i.fileSizeBytes ?? 0));

      _emitProgress(
        stage: CleanStage.completed,
        processedItems: successfullyDeletedIds.length,
        reclaimedBytes: actualReclaimedBytes,
        currentFileName: 'Done',
      );

      TeleCloudLogger.backup(
        'StorageCleanerService: Successfully freed ${successfullyDeletedIds.length} items (${StorageCleanProgress.formatBytes(actualReclaimedBytes)})!',
      );

      return StorageCleanResult(
        success: true,
        cleanedItemCount: successfullyDeletedIds.length,
        reclaimedBytes: actualReclaimedBytes,
        formattedReclaimed:
            StorageCleanProgress.formatBytes(actualReclaimedBytes),
      );
    } catch (e) {
      TeleCloudLogger.backup('StorageCleanerService exception', error: e);
      _emitProgress(stage: CleanStage.failed);
      return StorageCleanResult(
        success: false,
        errorMessage: e.toString(),
      );
    } finally {
      _isCleaning = false;
    }
  }

  void dispose() {
    _progressController.close();
  }
}
