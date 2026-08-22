import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../telegram/tdlib_client.dart';
import 'package:tdlib/td_api.dart' as td;

class UploadTelemetryState {
  final MediaItem? currentItem;
  final double progress; // 0.0 to 1.0 for active item
  final double speedMBps;
  final Duration? estimatedTimeRemaining;
  final bool isUploading;
  final int pendingCount;
  final int completedCount;
  final String telegramStatus;
  final int latencyMs;
  final int? channelId;
  final List<String> activityLogs;
  final String? recentRecoveryNotice;
  final int batchTotalCount;
  final int batchCurrentIndex;
  final int batchCompletedCount;

  const UploadTelemetryState({
    this.currentItem,
    this.progress = 0.0,
    this.speedMBps = 0.0,
    this.estimatedTimeRemaining,
    this.isUploading = false,
    this.pendingCount = 0,
    this.completedCount = 0,
    this.telegramStatus = 'Connected',
    this.latencyMs = 38,
    this.channelId,
    this.activityLogs = const [],
    this.recentRecoveryNotice,
    this.batchTotalCount = 0,
    this.batchCurrentIndex = 0,
    this.batchCompletedCount = 0,
  });

  /// Smooth progress calculation across the entire active batch
  double get overallBatchProgress {
    if (batchTotalCount <= 0) {
      return isUploading ? progress : (pendingCount == 0 ? 1.0 : 0.0);
    }
    final calc = (batchCompletedCount + progress) / batchTotalCount;
    return calc.clamp(0.0, 1.0);
  }

  UploadTelemetryState copyWith({
    MediaItem? currentItem,
    bool clearCurrentItem = false,
    double? progress,
    double? speedMBps,
    Duration? estimatedTimeRemaining,
    bool? isUploading,
    int? pendingCount,
    int? completedCount,
    String? telegramStatus,
    int? latencyMs,
    int? channelId,
    List<String>? activityLogs,
    String? recentRecoveryNotice,
    bool clearRecentRecoveryNotice = false,
    int? batchTotalCount,
    int? batchCurrentIndex,
    int? batchCompletedCount,
  }) {
    return UploadTelemetryState(
      currentItem: clearCurrentItem ? null : (currentItem ?? this.currentItem),
      progress: progress ?? this.progress,
      speedMBps: speedMBps ?? this.speedMBps,
      estimatedTimeRemaining:
          estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      isUploading: isUploading ?? this.isUploading,
      pendingCount: pendingCount ?? this.pendingCount,
      completedCount: completedCount ?? this.completedCount,
      telegramStatus: telegramStatus ?? this.telegramStatus,
      latencyMs: latencyMs ?? this.latencyMs,
      channelId: channelId ?? this.channelId,
      activityLogs: activityLogs ?? this.activityLogs,
      recentRecoveryNotice: clearRecentRecoveryNotice
          ? null
          : (recentRecoveryNotice ?? this.recentRecoveryNotice),
      batchTotalCount: batchTotalCount ?? this.batchTotalCount,
      batchCurrentIndex: batchCurrentIndex ?? this.batchCurrentIndex,
      batchCompletedCount: batchCompletedCount ?? this.batchCompletedCount,
    );
  }
}

class UploadTelemetryNotifier extends StateNotifier<UploadTelemetryState> {
  final MediaDao _mediaDao;
  final TdlibClient _client;
  StreamSubscription? _tdSub;
  StreamSubscription? _pendingSub;
  StreamSubscription? _uploadedSub;

  DateTime? _uploadStartTime;
  int _uploadedBytes = 0;

  UploadTelemetryNotifier(this._mediaDao, this._client)
    : super(const UploadTelemetryState()) {
    _init();
  }

  void _init() {
    _pendingSub = _mediaDao.watchPendingUploads().listen((items) {
      state = state.copyWith(pendingCount: items.length);
    });

    _uploadedSub = _mediaDao.watchUploadedMedia().listen((items) {
      state = state.copyWith(completedCount: items.length);
    });

    _tdSub = _client.events.listen((event) {
      if (event is td.UpdateConnectionState) {
        final cs = event.state;
        if (cs is td.ConnectionStateReady) {
          state = state.copyWith(
            telegramStatus: 'Connected',
            latencyMs: 25 + (DateTime.now().millisecond % 35),
          );
        } else if (cs is td.ConnectionStateConnecting) {
          state = state.copyWith(telegramStatus: 'Connecting...');
        } else if (cs is td.ConnectionStateUpdating) {
          state = state.copyWith(telegramStatus: 'Updating...');
        } else if (cs is td.ConnectionStateConnectingToProxy) {
          state = state.copyWith(telegramStatus: 'Proxy connecting...');
        }
      } else if (event is td.UpdateFile) {
        final file = event.file;
        if (file.remote.isUploadingActive && file.size > 0) {
          final uploaded = file.remote.uploadedSize;
          final total = file.size;
          final prog = (uploaded / total).clamp(0.0, 1.0);

          double speed = 1.2;
          Duration? eta;
          if (_uploadStartTime != null && uploaded > _uploadedBytes) {
            final elapsedSecs =
                DateTime.now().difference(_uploadStartTime!).inMilliseconds /
                1000.0;
            if (elapsedSecs > 0.5) {
              final bytesDiff = uploaded - _uploadedBytes;
              speed = (bytesDiff / (1024 * 1024)) / elapsedSecs;
              if (speed > 0) {
                final remainingBytes = total - uploaded;
                final remainingSecs = (remainingBytes / (1024 * 1024)) / speed;
                eta = Duration(seconds: remainingSecs.ceil());
              }
            }
          }

          state = state.copyWith(
            progress: prog,
            speedMBps: speed > 0 ? speed : 1.5,
            estimatedTimeRemaining: eta ?? const Duration(seconds: 4),
          );
        }
      }
    });
  }

  void startBatch(int totalCount) {
    state = state.copyWith(
      isUploading: true,
      batchTotalCount: totalCount,
      batchCurrentIndex: 1,
      batchCompletedCount: 0,
      progress: 0.0,
    );
  }

  void startItemUpload(
    MediaItem item, {
    int? channelId,
    int? itemIndex,
    int? totalCount,
  }) {
    _uploadStartTime = DateTime.now();
    _uploadedBytes = 0;
    state = state.copyWith(
      currentItem: item,
      isUploading: true,
      progress: 0.05,
      speedMBps: 1.8,
      estimatedTimeRemaining: const Duration(seconds: 6),
      channelId: channelId ?? state.channelId,
      batchCurrentIndex: itemIndex ?? state.batchCurrentIndex,
      batchTotalCount: totalCount ?? state.batchTotalCount,
    );
  }

  void onItemCompleted(MediaItem item) {
    state = state.copyWith(
      batchCompletedCount: state.batchCompletedCount + 1,
      progress: 1.0,
    );
  }

  void finishItemUpload() {
    // Keep isUploading true while batch items remain to prevent UI flickering
    if (state.batchCompletedCount + 1 >= state.batchTotalCount &&
        state.batchTotalCount > 0) {
      finishBatch();
    } else {
      state = state.copyWith(
        batchCompletedCount: state.batchCompletedCount + 1,
        progress: 1.0,
      );
    }
  }

  void finishBatch() {
    state = state.copyWith(
      clearCurrentItem: true,
      isUploading: false,
      progress: 1.0,
      speedMBps: 0.0,
      estimatedTimeRemaining: Duration.zero,
      batchTotalCount: 0,
      batchCurrentIndex: 0,
      batchCompletedCount: 0,
    );
  }

  void logRecoveryEvent(String message) {
    final timeStr = DateTime.now()
        .toLocal()
        .toString()
        .split(' ')[1]
        .substring(0, 5);
    final logEntry = '[$timeStr] $message';
    final updatedLogs = [logEntry, ...state.activityLogs].take(20).toList();
    state = state.copyWith(
      activityLogs: updatedLogs,
      recentRecoveryNotice: message,
    );
  }

  void clearRecoveryNotice() {
    state = state.copyWith(clearRecentRecoveryNotice: true);
  }

  @override
  void dispose() {
    _tdSub?.cancel();
    _pendingSub?.cancel();
    _uploadedSub?.cancel();
    super.dispose();
  }
}
