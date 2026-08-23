import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tdlib/td_api.dart' as td;
import '../database/app_database.dart';
import '../database/daos/files_dao.dart';
import '../database/tables/media_table.dart';
import '../utils/telecloud_logger.dart';
import 'tdlib_client.dart';
import 'package:drift/drift.dart' hide Column;

class TelegramFilesManager {
  final TdlibClient client;
  final FilesDao filesDao;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String filesChannelTitle = 'TeleCloud Files [Private]';
  static const String _filesChannelKey = 'telecloud_files_channel_id';

  int? _filesChannelId;
  int? get filesChannelId => _filesChannelId;

  TelegramFilesManager({
    required this.client,
    required this.filesDao,
  });

  /// Ensures dedicated private files supergroup with forum topics exists
  Future<int?> ensureFilesChannel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsSavedId = prefs.getInt(_filesChannelKey);
      if (prefsSavedId != null) {
        final chat = await _verifyChannelExists(prefsSavedId);
        if (chat != null) {
          _filesChannelId = prefsSavedId;
          await _storage.write(key: _filesChannelKey, value: prefsSavedId.toString());
          TeleCloudLogger.auth('Verified existing Files supergroup from prefs: $prefsSavedId');
          return prefsSavedId;
        }
      }

      final saved = await _storage.read(key: _filesChannelKey);
      if (saved != null) {
        final id = int.tryParse(saved);
        if (id != null) {
          final chat = await _verifyChannelExists(id);
          if (chat != null) {
            _filesChannelId = id;
            await prefs.setInt(_filesChannelKey, id);
            TeleCloudLogger.auth('Verified existing Files supergroup: $id');
            return id;
          }
        }
      }

      // Search existing chats before creating a new one
      final existingId = await _findExistingFilesChannel();
      if (existingId != null) {
        _filesChannelId = existingId;
        await _storage.write(key: _filesChannelKey, value: existingId.toString());
        await prefs.setInt(_filesChannelKey, existingId);
        TeleCloudLogger.auth('Discovered & reused existing Files supergroup: $existingId');
        return existingId;
      }

      // Create new private forum supergroup for files
      return await _createNewFilesSupergroup();
    } catch (e) {
      TeleCloudLogger.auth('TelegramFilesManager ensureFilesChannel error: $e');
      return null;
    }
  }

  Future<int?> _findExistingFilesChannel() async {
    final candidateChatIds = <int>{};
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.Chats) {
        candidateChatIds.addAll(event.chatIds);
      }
    });

    try {
      client.send(const td.LoadChats(chatList: td.ChatListMain(), limit: 100));
      client.send(const td.GetChats(chatList: td.ChatListMain(), limit: 100));
      client.send(const td.SearchChats(query: 'TeleCloud Files', limit: 50));
      client.send(const td.SearchChats(query: 'Files', limit: 50));

      await Future.delayed(const Duration(milliseconds: 1500));

      for (final id in candidateChatIds) {
        final chat = await _verifyChannelExists(id);
        if (chat != null) {
          final title = chat.title.trim().toLowerCase();
          if (title == filesChannelTitle.toLowerCase() ||
              (title.contains('telecloud') && title.contains('file'))) {
            TeleCloudLogger.auth('Found existing matching Files supergroup: "${chat.title}" ($id)');
            return id;
          }
        }
      }
    } catch (e) {
      TeleCloudLogger.auth('Error while searching existing files chats: $e');
    } finally {
      sub.cancel();
    }

    return null;
  }

  Future<td.Chat?> _verifyChannelExists(int chatId) async {
    final completer = Completer<td.Chat?>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.Chat && event.id == chatId) {
        completer.complete(event);
        sub.cancel();
      } else if (event is td.TdError) {
        completer.complete(null);
        sub.cancel();
      }
    });

    client.send(td.GetChat(chatId: chatId));

    return await completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        sub.cancel();
        return null;
      },
    );
  }

  Future<int?> _createNewFilesSupergroup() async {
    TeleCloudLogger.auth('Creating new dedicated TeleCloud Files supergroup with topics...');
    final completer = Completer<int?>();
    late StreamSubscription sub;

    sub = client.events.listen((event) async {
      if (event is td.Chat) {
        final title = event.title.trim();
        if (title == filesChannelTitle || title.contains('TeleCloud Files')) {
          _filesChannelId = event.id;
          final prefs = await SharedPreferences.getInstance();
          await _storage.write(key: _filesChannelKey, value: event.id.toString());
          await prefs.setInt(_filesChannelKey, event.id);

          // Enable Forum Topics in the supergroup
          client.send(
            td.ToggleSupergroupIsForum(
              supergroupId: event.type is td.ChatTypeSupergroup
                  ? (event.type as td.ChatTypeSupergroup).supergroupId
                  : 0,
              isForum: true,
            ),
          );

          // Pre-create standard default topic folders
          unawaited(_createDefaultTopics(event.id));

          completer.complete(event.id);
          sub.cancel();
        }
      } else if (event is td.TdError) {
        TeleCloudLogger.auth('Failed to create Files supergroup: [${event.code}] ${event.message}');
        completer.complete(null);
        sub.cancel();
      }
    });

    client.send(
      const td.CreateNewSupergroupChat(
        title: filesChannelTitle,
        isChannel: false, // Supergroup with forum topics
        isForum: true,
        messageAutoDeleteTime: 0,
        description: 'TeleCloud Files — Unlimited Private Cloud Drive & Document Storage',
        location: null,
        forImport: false,
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        sub.cancel();
        return null;
      },
    );
  }

  Future<void> _createDefaultTopics(int chatId) async {
    final defaultFolders = ['Documents', 'Downloads', 'Archives', 'Backups'];

    for (final folder in defaultFolders) {
      await ensureFolderTopic(folder);
    }
  }

  /// Ensures a dedicated forum topic exists for the folder name
  Future<int?> ensureFolderTopic(String folderName) async {
    if (_filesChannelId == null) {
      await ensureFilesChannel();
    }
    if (_filesChannelId == null) return null;

    final cleanName = folderName.replaceAll('/', '').trim();
    if (cleanName.isEmpty) return null;

    final topicStorageKey = 'files_topic_${_filesChannelId}_${cleanName.toLowerCase().replaceAll(' ', '_')}';
    final savedThreadIdStr = await _storage.read(key: topicStorageKey);

    if (savedThreadIdStr != null) {
      final savedThreadId = int.tryParse(savedThreadIdStr);
      if (savedThreadId != null) {
        return savedThreadId;
      }
    }

    final completer = Completer<int?>();
    late StreamSubscription sub;

    sub = client.events.listen((event) async {
      if (event is td.ForumTopicInfo) {
        final threadId = event.messageThreadId;
        await _storage.write(key: topicStorageKey, value: threadId.toString());
        // Save folder entry in database
        await filesDao.insertFolder(
          CloudFoldersCompanion(
            id: Value('/$cleanName'),
            parentPath: const Value('/'),
            folderName: Value(cleanName),
            topicId: Value(threadId),
            createdAt: Value(DateTime.now()),
          ),
        );
        completer.complete(threadId);
        sub.cancel();
      } else if (event is td.TdError) {
        completer.complete(null);
        sub.cancel();
      }
    });

    client.send(
      td.CreateForumTopic(
        chatId: _filesChannelId!,
        name: cleanName,
        icon: const td.ForumTopicIcon(color: 0x6FB9F0, customEmojiId: 0),
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        sub.cancel();
        return null;
      },
    );
  }

  /// Uploads any document/file to Telegram Cloud
  Future<bool> uploadFile({
    required String localPath,
    required String fileName,
    String folderPath = '/',
    void Function(double progress)? onProgress,
  }) async {
    final channelId = _filesChannelId ?? await ensureFilesChannel();
    if (channelId == null) return false;

    final file = File(localPath);
    if (!await file.exists()) return false;

    final fileSizeBytes = await file.length();
    final mime = _getMimeType(fileName);

    // Resolve topic thread ID for folder
    int? topicId;
    if (folderPath != '/' && folderPath.isNotEmpty) {
      topicId = await ensureFolderTopic(folderPath.replaceAll('/', ''));
    }

    // Insert pending file record in DB
    final fileId = await filesDao.insertFile(
      CloudFilesCompanion(
        localPath: Value(localPath),
        fileName: Value(fileName),
        fileSizeBytes: Value(BigInt.from(fileSizeBytes)),
        mimeType: Value(mime),
        folderPath: Value(folderPath),
        topicId: Value(topicId),
        uploadStatus: const Value(UploadStatus.uploading),
        createdAt: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    final completer = Completer<bool>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.UpdateFile) {
        final f = event.file;
        if (f.local.path == localPath && f.size > 0) {
          final progress = f.remote.uploadedSize / f.size;
          onProgress?.call(progress);
        }
      } else if (event is td.Message) {
        final content = event.content;
        if (content is td.MessageDocument) {
          final doc = content.document;
          final remoteFileId = doc.document.remote.id;
          filesDao.updateFileStatus(
            fileId,
            UploadStatus.done,
            telegramMsgId: event.id,
            telegramFileId: remoteFileId,
          );
          completer.complete(true);
          sub.cancel();
        }
      } else if (event is td.TdError) {
        filesDao.updateFileStatus(fileId, UploadStatus.failed);
        completer.complete(false);
        sub.cancel();
      }
    });

    client.send(
      td.SendMessage(
        chatId: channelId,
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
        inputMessageContent: td.InputMessageDocument(
          document: td.InputFileLocal(path: localPath),
          thumbnail: null,
          disableContentTypeDetection: false,
          caption: td.FormattedText(text: fileName, entities: []),
        ),
      ),
    );

    return await completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () {
        sub.cancel();
        filesDao.updateFileStatus(fileId, UploadStatus.failed);
        return false;
      },
    );
  }

  /// Downloads a cloud file to local cache
  Future<String?> downloadFile({
    required int telegramFileId,
    required String fileName,
    bool isOfflinePin = false,
    void Function(double progress)? onProgress,
  }) async {
    final completer = Completer<String?>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.UpdateFile && event.file.id == telegramFileId) {
        final f = event.file;
        if (f.size > 0) {
          final progress = f.local.downloadedSize / f.size;
          onProgress?.call(progress);
        }
        if (f.local.isDownloadingCompleted && f.local.path.isNotEmpty) {
          completer.complete(f.local.path);
          sub.cancel();
        }
      } else if (event is td.TdError) {
        completer.complete(null);
        sub.cancel();
      }
    });

    client.send(
      td.DownloadFile(
        fileId: telegramFileId,
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

  String _getMimeType(String fileName) {
    final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return 'application/zip';
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
      case 'm4a':
        return 'audio/$ext';
      case 'mp4':
      case 'mkv':
      case 'mov':
      case 'avi':
      case 'webm':
        return 'video/$ext';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        return 'image/$ext';
      case 'txt':
      case 'md':
      case 'json':
      case 'dart':
      case 'py':
      case 'js':
      case 'html':
      case 'css':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
