import 'dart:async';
import 'package:drift/drift.dart';
import 'package:tdlib/td_api.dart' as td;
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../database/tables/media_table.dart';
import '../telegram/channel_manager.dart';
import '../telegram/metadata_encoder.dart';
import '../telegram/tdlib_client.dart';
import '../utils/telecloud_logger.dart';

enum CloudSyncStatus { idle, syncing, completed, error }

class CloudSyncProgress {
  final CloudSyncStatus status;
  final int syncedCount;
  final String? message;

  const CloudSyncProgress({
    this.status = CloudSyncStatus.idle,
    this.syncedCount = 0,
    this.message,
  });
}

class CloudSyncService {
  final TdlibClient tdlibClient;
  final ChannelManager channelManager;
  final MediaDao mediaDao;

  StreamSubscription? _liveMessageSub;
  final _progressController = StreamController<CloudSyncProgress>.broadcast();
  Stream<CloudSyncProgress> get progressStream => _progressController.stream;

  CloudSyncService({
    required this.tdlibClient,
    required this.channelManager,
    required this.mediaDao,
  }) {
    _startLiveMessageListener();
  }

  /// Listens for real-time messages added to the Telegram channel from other devices
  void _startLiveMessageListener() {
    _liveMessageSub?.cancel();
    _liveMessageSub = tdlibClient.events.listen((event) async {
      final channelId = channelManager.channelId;
      if (channelId == null) return;

      if (event is td.UpdateNewMessage) {
        final msg = event.message;
        if (msg.chatId == channelId) {
          TeleCloudLogger.tdlib(
            'Received real-time cloud message from Telegram: ${msg.id}',
          );
          await _processIncomingCloudMessage(msg);
        }
      } else if (event is td.UpdateDeleteMessages) {
        if (event.chatId == channelId && event.isPermanent) {
          TeleCloudLogger.tdlib(
            'Received real-time remote deletion for messages: ${event.messageIds}',
          );
          await mediaDao.deleteByTelegramMsgIds(event.messageIds);
        }
      }
    });
  }

  Future<void> _processIncomingCloudMessage(td.Message msg) async {
    try {
      String? captionText;
      String? rawFilename;
      String? mime;
      int? width;
      int? height;
      int? size;
      String? remoteFileId;

      final content = msg.content;
      if (content is td.MessageDocument) {
        captionText = content.caption.text;
        rawFilename = content.document.fileName;
        mime = content.document.mimeType;
        size = content.document.document.size;
        remoteFileId = content.document.document.remote.id;
      } else if (content is td.MessagePhoto) {
        captionText = content.caption.text;
        mime = 'image/jpeg';
        if (content.photo.sizes.isNotEmpty) {
          final largest = content.photo.sizes.last;
          width = largest.width;
          height = largest.height;
          size = largest.photo.size;
          remoteFileId = largest.photo.remote.id;
        }
      } else if (content is td.MessageVideo) {
        captionText = content.caption.text;
        rawFilename = content.video.fileName;
        mime = content.video.mimeType;
        width = content.video.width;
        height = content.video.height;
        size = content.video.video.size;
        remoteFileId = content.video.video.remote.id;
      }

      MediaMetadata? meta;
      if (captionText != null && captionText.isNotEmpty) {
        meta = MediaMetadata.decode(captionText);
      }

      final targetName =
          meta?.filename ?? rawFilename ?? 'cloud_photo_${msg.id}.jpg';
      final localId = 'tg_${msg.id}';

      // Check if already in DB
      final existing = await mediaDao.getMediaById(localId);
      if (existing == null) {
        await mediaDao.insertOrIgnoreBatch([
          MediaItemsCompanion.insert(
            localId: localId,
            filename: targetName,
            capturedAt: meta?.capturedAt ??
                DateTime.fromMillisecondsSinceEpoch(msg.date * 1000),
            width: Value(meta?.width ?? width),
            height: Value(meta?.height ?? height),
            latitude: Value(meta?.latitude),
            longitude: Value(meta?.longitude),
            fileSizeBytes: Value(meta?.fileSizeBytes ?? size),
            mimeType: mime ?? 'image/jpeg',
            uploadStatus: UploadStatus.done,
            telegramMsgId: Value(msg.id),
            telegramFileId: Value(remoteFileId),
          ),
        ]);
        TeleCloudLogger.auth(
          'Live sync inserted incoming photo "$targetName" into timeline.',
        );
      }
    } catch (e) {
      TeleCloudLogger.auth('Error processing incoming cloud message: $e');
    }
  }

  /// Full Historical Import: Scans entire channel history and topics to rebuild timeline
  Future<int> rebuildTimelineFromCloud() async {
    if (!_progressController.isClosed) {
      _progressController.add(
        const CloudSyncProgress(
          status: CloudSyncStatus.syncing,
          message: 'Connecting to Telegram Cloud...',
        ),
      );
    }
    try {
      final restored = await channelManager.syncFromCloud(mediaDao);
      if (!_progressController.isClosed) {
        _progressController.add(
          CloudSyncProgress(
            status: CloudSyncStatus.completed,
            syncedCount: restored,
            message: 'Successfully synced $restored items from Telegram Cloud.',
          ),
        );
      }
      return restored;
    } catch (e) {
      if (!_progressController.isClosed) {
        _progressController.add(
          CloudSyncProgress(
            status: CloudSyncStatus.error,
            message: 'Sync error: $e',
          ),
        );
      }
      return 0;
    }
  }

  void dispose() {
    _liveMessageSub?.cancel();
    _progressController.close();
  }
}
