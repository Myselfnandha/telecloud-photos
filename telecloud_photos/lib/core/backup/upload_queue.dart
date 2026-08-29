import 'dart:async';
import 'dart:io';
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../database/tables/media_table.dart';
import '../utils/telecloud_logger.dart';
import 'media_deduplicator.dart';
import 'sync_policy_guard.dart';

typedef UploadItemFunction = Future<bool> Function(
  MediaItem item, [
  int? itemIndex,
  int? totalBatchCount,
]);

typedef GetFileFunction = Future<File?> Function(String localId);

class UploadProgressState {
  final int completedCount;
  final int totalCount;
  final int activeWorkers;
  final double speedKBps;
  final String currentFileName;
  final int bytesTransferredTotal;
  final bool isPaused;

  const UploadProgressState({
    this.completedCount = 0,
    this.totalCount = 0,
    this.activeWorkers = 0,
    this.speedKBps = 0.0,
    this.currentFileName = '',
    this.bytesTransferredTotal = 0,
    this.isPaused = false,
  });

  double get progressPercentage =>
      totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

  String get speedFormatted {
    if (speedKBps >= 1024) {
      return '${(speedKBps / 1024).toStringAsFixed(1)} MB/s';
    }
    return '${speedKBps.toStringAsFixed(0)} KB/s';
  }
}

class UploadQueue {
  final MediaDao mediaDao;
  final MediaDeduplicator? deduplicator;
  bool _isProcessing = false;
  bool _isPaused = false;
  int _concurrency = 2;

  final _progressController = StreamController<UploadProgressState>.broadcast();
  Stream<UploadProgressState> get progressStream => _progressController.stream;

  UploadProgressState _lastState = const UploadProgressState();
  UploadProgressState get currentState => _lastState;

  bool get isProcessing => _isProcessing;
  bool get isPaused => _isPaused;
  int get concurrency => _concurrency;

  UploadQueue({required this.mediaDao, this.deduplicator});

  void setConcurrency(int level) {
    _concurrency = level;
    TeleCloudLogger.upload(
      'Upload concurrency set to: ${_concurrency <= 0 ? 'Unlimited (Turbo Mode)' : '$_concurrency workers'}',
    );
  }

  void pause() {
    _isPaused = true;
    _updateProgress(isPaused: true);
    TeleCloudLogger.upload('Upload queue paused by user.');
  }

  void resume() {
    _isPaused = false;
    _updateProgress(isPaused: false);
    TeleCloudLogger.upload('Upload queue resumed by user.');
  }

  void _updateProgress({
    int? completedCount,
    int? totalCount,
    int? activeWorkers,
    double? speedKBps,
    String? currentFileName,
    int? bytesTransferredTotal,
    bool? isPaused,
  }) {
    _lastState = UploadProgressState(
      completedCount: completedCount ?? _lastState.completedCount,
      totalCount: totalCount ?? _lastState.totalCount,
      activeWorkers: activeWorkers ?? _lastState.activeWorkers,
      speedKBps: speedKBps ?? _lastState.speedKBps,
      currentFileName: currentFileName ?? _lastState.currentFileName,
      bytesTransferredTotal:
          bytesTransferredTotal ?? _lastState.bytesTransferredTotal,
      isPaused: isPaused ?? _lastState.isPaused,
    );
    if (!_progressController.isClosed) {
      _progressController.add(_lastState);
    }
  }

  Future<void> processQueue({
    required UploadItemFunction uploadItem,
    GetFileFunction? getFileForLocalId,
    void Function(int totalItems)? onBatchStart,
    void Function(MediaItem item)? onItemSuccess,
    void Function(UploadProgressState progress)? onProgress,
    void Function()? onBatchFinish,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _isPaused = false;
    TeleCloudLogger.upload(
      'Upload queue processor started (concurrency: $_concurrency workers).',
    );

    try {
      final pendingStream = mediaDao.watchPendingUploads();
      await for (final items in pendingStream) {
        if (items.isEmpty) {
          TeleCloudLogger.upload('All pending uploads completed. Queue idle.');
          _isProcessing = false;
          _updateProgress(
            completedCount: 0,
            totalCount: 0,
            activeWorkers: 0,
            speedKBps: 0.0,
            currentFileName: '',
          );
          onBatchFinish?.call();
          break;
        }

        final totalCount = items.length;
        TeleCloudLogger.upload('$totalCount items currently pending upload.');
        onBatchStart?.call(totalCount);

        int completedSoFar = 0;
        final startTime = DateTime.now();
        int totalBytesThisBatch = 0;

        _updateProgress(
          completedCount: 0,
          totalCount: totalCount,
          activeWorkers: 0,
        );

        // Process with bounded concurrency
        final queueList = List<MediaItem>.from(items);
        int currentIndex = 0;

        while (currentIndex < queueList.length) {
          if (!_isProcessing) {
            TeleCloudLogger.upload(
              'Upload queue processing stopped by user/power policy.',
            );
            break;
          }

          // Handle pause loop
          while (_isPaused && _isProcessing) {
            await Future.delayed(const Duration(milliseconds: 500));
          }

          // Gather batch up to concurrency limit (or turbo limit)
          final workerBatch = <MediaItem>[];
          final workerIndices = <int>[];
          final effectiveBatchSize = _concurrency <= 0 ? 32 : _concurrency;

          while (workerBatch.length < effectiveBatchSize &&
              currentIndex < queueList.length) {
            workerBatch.add(queueList[currentIndex]);
            workerIndices.add(currentIndex + 1);
            currentIndex++;
          }

          if (workerBatch.isEmpty) break;

          _updateProgress(
            activeWorkers: workerBatch.length,
            currentFileName: workerBatch.first.filename,
          );

          // Run worker batch concurrently
          await Future.wait(
            List.generate(workerBatch.length, (workerIdx) async {
              final item = workerBatch[workerIdx];
              final itemDisplayIndex = workerIndices[workerIdx];

              // 1. Smart Deduplication Check before network transfer
              if (deduplicator != null && getFileForLocalId != null) {
                try {
                  final file = await getFileForLocalId(item.localId);
                  if (file != null && await file.exists()) {
                    final deduplicated =
                        await deduplicator!.checkAndDeduplicate(
                      localItem: item,
                      file: file,
                    );
                    if (deduplicated) {
                      completedSoFar++;
                      _updateProgress(
                        completedCount: completedSoFar,
                        currentFileName: item.filename,
                      );
                      onItemSuccess?.call(item);
                      return;
                    }
                  }
                } catch (_) {}
              }

              // 2. Perform upload with exponential retry
              int attempts = 0;
              bool success = false;

              while (attempts < 3 && !success && _isProcessing) {
                while (_isPaused && _isProcessing) {
                  await Future.delayed(const Duration(milliseconds: 500));
                }

                attempts++;
                TeleCloudLogger.upload(
                  'Uploading "${item.filename}" (attempt $attempts of 3)...',
                );
                await mediaDao.updateUploadStatus(
                  item.localId,
                  UploadStatus.uploading,
                );

                success = await uploadItem(
                  item,
                  itemDisplayIndex,
                  totalCount,
                );

                if (success) {
                  final itemBytes = item.fileSizeBytes ?? 1500000; // ~1.5MB est
                  totalBytesThisBatch += itemBytes;

                  // Record for daily cellular cap tracking
                  await SyncPolicyGuard.recordDataUsage(itemBytes);

                  final totalElapsed =
                      DateTime.now().difference(startTime).inMilliseconds /
                          1000.0;
                  final currentSpeedKBps = totalElapsed > 0
                      ? (totalBytesThisBatch / 1024.0) / totalElapsed
                      : 0.0;

                  completedSoFar++;
                  _updateProgress(
                    completedCount: completedSoFar,
                    speedKBps: currentSpeedKBps,
                    currentFileName: item.filename,
                    bytesTransferredTotal: totalBytesThisBatch,
                  );
                } else {
                  final delaySecs = (1 << attempts); // 2s, 4s, 8s backoff
                  final jitterMs = DateTime.now().microsecondsSinceEpoch % 400;
                  TeleCloudLogger.upload(
                    'Upload failed for "${item.filename}". Retrying in ${delaySecs}s...',
                  );
                  await Future.delayed(
                    Duration(seconds: delaySecs, milliseconds: jitterMs),
                  );
                }
              }

              if (success) {
                TeleCloudLogger.upload(
                  'Successfully backed up "${item.filename}" to Telegram Cloud.',
                );
                await mediaDao.updateUploadStatus(
                  item.localId,
                  UploadStatus.done,
                );
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
            }),
          );

          _updateProgress(activeWorkers: 0);
          onProgress?.call(_lastState);
        }
      }
    } catch (e) {
      TeleCloudLogger.upload('UploadQueue exception', error: e);
    } finally {
      _isProcessing = false;
      _updateProgress(activeWorkers: 0);
      onBatchFinish?.call();
    }
  }

  void stop() {
    TeleCloudLogger.upload('Stopping upload queue...');
    _isProcessing = false;
    _isPaused = false;
    _updateProgress(isPaused: false, activeWorkers: 0);
  }

  void dispose() {
    _progressController.close();
  }
}
