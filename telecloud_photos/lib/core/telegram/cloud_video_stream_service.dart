import 'dart:async';
import 'dart:io';
import 'package:tdlib/td_api.dart' as td;
import 'tdlib_client.dart';
import '../utils/telecloud_logger.dart';

class CloudVideoStreamService {
  final TdlibClient _client;
  final Map<int, Completer<String?>> _activeDownloads = {};

  CloudVideoStreamService(this._client);

  /// Requests high-priority streaming/download of a Telegram cloud video file.
  /// Returns the local downloaded file path once accessible, or null if failed.
  Future<String?> getStreamableVideoPath({
    required int telegramFileId,
    String? fallbackLocalPath,
  }) async {
    // 1. If local original file exists and is readable, return it immediately
    if (fallbackLocalPath != null) {
      final localFile = File(fallbackLocalPath);
      if (await localFile.exists() && await localFile.length() > 0) {
        return fallbackLocalPath;
      }
    }

    // 2. Check if already downloading
    if (_activeDownloads.containsKey(telegramFileId)) {
      return _activeDownloads[telegramFileId]!.future;
    }

    final completer = Completer<String?>();
    _activeDownloads[telegramFileId] = completer;

    try {
      TeleCloudLogger.log(
        'CloudStream',
        'Initiating high-priority download for video fileId: $telegramFileId',
      );

      // Start high-priority download (priority 32 = highest)
      _client.send(
        td.DownloadFile(
          fileId: telegramFileId,
          priority: 32,
          offset: 0,
          limit: 0,
          synchronous: false,
        ),
      );

      // Listen for download completion
      late final StreamSubscription sub;
      sub = _client.events.listen((event) {
        if (event is td.UpdateFile && event.file.id == telegramFileId) {
          final file = event.file;
          if (file.local.isDownloadingCompleted && file.local.path.isNotEmpty) {
            TeleCloudLogger.log(
              'CloudStream',
              'Video download completed: ${file.local.path}',
            );
            sub.cancel();
            _activeDownloads.remove(telegramFileId);
            if (!completer.isCompleted) completer.complete(file.local.path);
          }
        }
      });

      // Timeout after 45 seconds if network stalled
      Future.delayed(const Duration(seconds: 45), () {
        if (!completer.isCompleted) {
          sub.cancel();
          _activeDownloads.remove(telegramFileId);
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      TeleCloudLogger.log('CloudStream', 'Cloud video stream error: $e');
      _activeDownloads.remove(telegramFileId);
      return null;
    }
  }
}
