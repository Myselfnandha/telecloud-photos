import 'dart:async';
import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:tdlib/td_api.dart' as td;
import '../database/app_database.dart';
import '../utils/telecloud_logger.dart';
import 'tdlib_client.dart';
import 'metadata_encoder.dart';
import 'channel_manager.dart';

class TelegramUploadService {
  final TdlibClient client;
  final ChannelManager? channelManager;

  TelegramUploadService({required this.client, this.channelManager});

  /// Uploads media as uncompressed Document preserving 100% original quality, EXIF, and raw bytes
  Future<bool> uploadMediaItem(
    MediaItem item, {
    required int targetChatId,
    int? topicId,
    String? albumName,
    void Function(String recoveryMessage)? onRecoveryEvent,
  }) async {
    try {
      TeleCloudLogger.upload(
        'Starting uncompressed document upload for: "${item.filename}" (${item.localId}) to chat $targetChatId topic $topicId',
      );

      final metadataStr = MediaMetadata(
        filename: item.filename,
        capturedAt: item.capturedAt,
        fileSizeBytes: item.fileSizeBytes,
        width: item.width,
        height: item.height,
        latitude: item.latitude,
        longitude: item.longitude,
      ).encode();

      final caption = td.FormattedText(text: metadataStr, entities: []);

      final asset = await AssetEntity.fromId(item.localId);
      final file = await asset?.file;
      final localFilePath = file?.path ?? item.thumbnailPath;

      if (localFilePath == null ||
          localFilePath.isEmpty ||
          !File(localFilePath).existsSync()) {
        TeleCloudLogger.upload(
          'File not found on disk for localId: ${item.localId}',
        );
        return false;
      }

      td.InputThumbnail? inputThumb;
      if (item.thumbnailPath != null &&
          File(item.thumbnailPath!).existsSync()) {
        inputThumb = td.InputThumbnail(
          thumbnail: td.InputFileLocal(path: item.thumbnailPath!),
          width: 256,
          height: 256,
        );
      }

      // Bit-for-bit uncompressed document transmission
      final content = td.InputMessageDocument(
        document: td.InputFileLocal(path: localFilePath),
        thumbnail: inputThumb,
        disableContentTypeDetection: false,
        caption: caption,
      );

      return await _sendWithTopicRecovery(
        targetChatId: targetChatId,
        topicId: topicId ?? 0,
        albumName: albumName ?? 'Camera',
        content: content,
        item: item,
        onRecoveryEvent: onRecoveryEvent,
      );
    } catch (e) {
      TeleCloudLogger.upload('TelegramUploadService exception', error: e);
      return false;
    }
  }

  /// Sends message with automated closed topic reopening and deleted topic re-creation
  Future<bool> _sendWithTopicRecovery({
    required int targetChatId,
    required int topicId,
    required String albumName,
    required td.InputMessageContent content,
    required MediaItem item,
    void Function(String recoveryMessage)? onRecoveryEvent,
  }) async {
    int currentTopicId = topicId;
    int recoveryAttempts = 0;

    while (recoveryAttempts < 2) {
      final completer = Completer<dynamic>();
      final requestId =
          DateTime.now().millisecondsSinceEpoch + recoveryAttempts;

      late StreamSubscription sub;
      sub = client.events.listen((event) {
        if (event is td.Message) {
          TeleCloudLogger.upload(
            'Upload successful! Telegram Message ID: ${event.id}',
          );
          completer.complete(true);
          sub.cancel();
        } else if (event is td.TdError) {
          TeleCloudLogger.upload(
            'Upload response error: [${event.code}] ${event.message}',
          );
          completer.complete(event);
          sub.cancel();
        }
      });

      client.send(
        td.SendMessage(
          chatId: targetChatId,
          messageThreadId: currentTopicId,
          replyTo: null,
          options: const td.MessageSendOptions(
            disableNotification: true,
            fromBackground: true,
            protectContent: false,
            updateOrderOfInstalledStickerSets: false,
            schedulingState: null,
            sendingId: 0,
          ),
          replyMarkup: null,
          inputMessageContent: content,
        ),
        requestId,
      );

      final result = await completer.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          TeleCloudLogger.upload(
            'Upload timed out after 10 minutes for ${item.filename}',
          );
          sub.cancel();
          return false;
        },
      );

      if (result == true) {
        return true;
      }

      if (result is td.TdError) {
        final errorMsg = result.message.toLowerCase();
        recoveryAttempts++;

        // Self-Healing Case 1: Topic was closed by user in Telegram
        if (currentTopicId > 0 &&
            (errorMsg.contains('topic is closed') ||
                errorMsg.contains('topic_closed') ||
                errorMsg.contains('forum_topic_closed'))) {
          TeleCloudLogger.upload(
            'Self-healing: Topic $currentTopicId for "$albumName" was closed in Telegram. Auto-reopening...',
          );
          final notice = '🔄 Auto-reopened "$albumName" topic in Telegram';
          onRecoveryEvent?.call(notice);

          if (channelManager != null) {
            await channelManager!.reopenForumTopic(
              targetChatId,
              currentTopicId,
            );
            await Future.delayed(const Duration(milliseconds: 600));
            // Loop and retry upload immediately
            continue;
          }
        }

        // Self-Healing Case 2: Topic was permanently deleted by user in Telegram
        if (currentTopicId > 0 &&
            (errorMsg.contains('message thread not found') ||
                errorMsg.contains('thread_not_found') ||
                errorMsg.contains('topic_deleted') ||
                errorMsg.contains('forum_topic_deleted'))) {
          TeleCloudLogger.upload(
            'Self-healing: Topic $currentTopicId for "$albumName" was deleted in Telegram. Auto-recreating...',
          );
          final notice = '🆕 Auto-recreated "$albumName" topic in Telegram';
          onRecoveryEvent?.call(notice);

          if (channelManager != null) {
            await channelManager!.invalidateAlbumTopic(albumName);
            final newTopic = await channelManager!.createAlbumTopic(albumName);
            if (newTopic != null) {
              currentTopicId = newTopic;
              await Future.delayed(const Duration(milliseconds: 600));
              // Loop and retry upload to new topic ID
              continue;
            }
          }
        }

        return false;
      }
    }

    return false;
  }

  /// Downloads file from Telegram cloud on demand
  Future<String?> downloadFile(int fileId) async {
    TeleCloudLogger.upload('Requesting download for Telegram File ID: $fileId');
    final completer = Completer<String?>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.UpdateFile) {
        if (event.file.id == fileId &&
            event.file.local.isDownloadingCompleted) {
          TeleCloudLogger.upload(
            'File download completed: ${event.file.local.path}',
          );
          completer.complete(event.file.local.path);
          sub.cancel();
        }
      } else if (event is td.TdError) {
        TeleCloudLogger.upload(
          'File download failed: [${event.code}] ${event.message}',
        );
        completer.complete(null);
        sub.cancel();
      }
    });

    client.send(
      td.DownloadFile(
        fileId: fileId,
        priority: 32,
        offset: 0,
        limit: 0,
        synchronous: false,
      ),
    );

    return await completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        sub.cancel();
        return null;
      },
    );
  }

  /// Direct uncompressed upload for stream-downloaded files (e.g. from Google Photos)
  Future<int?> uploadDirectFile({
    required File file,
    required String filename,
    required DateTime capturedAt,
    required int targetChatId,
    int? topicId,
    String? albumName,
    int? width,
    int? height,
    double? latitude,
    double? longitude,
  }) async {
    try {
      if (!file.existsSync()) return null;

      final metadataStr = MediaMetadata(
        filename: filename,
        capturedAt: capturedAt,
        fileSizeBytes: file.lengthSync(),
        width: width,
        height: height,
        latitude: latitude,
        longitude: longitude,
      ).encode();

      final caption = td.FormattedText(text: metadataStr, entities: []);

      final content = td.InputMessageDocument(
        document: td.InputFileLocal(path: file.path),
        thumbnail: null,
        disableContentTypeDetection: false,
        caption: caption,
      );

      final completer = Completer<int?>();
      late StreamSubscription sub;

      sub = client.events.listen((event) {
        if (event is td.Message) {
          completer.complete(event.id);
          sub.cancel();
        } else if (event is td.TdError) {
          TeleCloudLogger.upload(
            'uploadDirectFile error: [${event.code}] ${event.message}',
          );
          completer.complete(null);
          sub.cancel();
        }
      });

      client.send(
        td.SendMessage(
          chatId: targetChatId,
          messageThreadId: topicId ?? 0,
          replyTo: null,
          options: const td.MessageSendOptions(
            disableNotification: true,
            fromBackground: true,
            protectContent: false,
            updateOrderOfInstalledStickerSets: false,
            schedulingState: null,
            sendingId: 0,
          ),
          replyMarkup: null,
          inputMessageContent: content,
        ),
      );

      return await completer.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          sub.cancel();
          return null;
        },
      );
    } catch (e) {
      TeleCloudLogger.upload('uploadDirectFile exception: $e');
      return null;
    }
  }
}
