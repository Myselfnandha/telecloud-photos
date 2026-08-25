import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tdlib/td_api.dart' as td;
import '../constants/app_constants.dart';
import '../database/daos/media_dao.dart';
import '../database/app_database.dart';
import '../database/tables/media_table.dart';
import '../utils/telecloud_logger.dart';
import 'metadata_encoder.dart';
import 'tdlib_client.dart';
import 'package:drift/drift.dart' hide Column;

class ChannelManager {
  final TdlibClient client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _channelKey = 'telecloud_backup_channel_id';
  int? _channelId;
  int? get channelId => _channelId;

  ChannelManager({required this.client});

  /// Initializes or fetches existing backup channel
  Future<int?> ensureBackupChannel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsSavedId = prefs.getInt(AppConstants.channelIdKey);
      if (prefsSavedId != null) {
        final chat = await _verifyChannelExists(prefsSavedId);
        if (chat != null) {
          _channelId = prefsSavedId;
          await _storage.write(
              key: _channelKey, value: prefsSavedId.toString());
          TeleCloudLogger.auth(
              'Verified existing backup channel from prefs: $prefsSavedId');
          return prefsSavedId;
        }
      }

      final saved = await _storage.read(key: _channelKey);
      if (saved != null) {
        final id = int.tryParse(saved);
        if (id != null) {
          TeleCloudLogger.auth('Verifying existing backup channel: $id');
          final chat = await _verifyChannelExists(id);
          if (chat != null) {
            _channelId = id;
            await prefs.setInt(AppConstants.channelIdKey, id);
            TeleCloudLogger.auth('Verified existing backup channel: $id');
            return id;
          }
        }
      }

      // Check if channel already exists in user's Telegram account before creating
      final existingId = await _findExistingBackupChannel();
      if (existingId != null) {
        _channelId = existingId;
        await _storage.write(key: _channelKey, value: existingId.toString());
        await prefs.setInt(AppConstants.channelIdKey, existingId);
        TeleCloudLogger.auth(
          'Discovered & reused existing backup channel: $existingId',
        );
        return existingId;
      }

      // Create new private forum channel only if none exists
      return await _createNewBackupChannel();
    } catch (e) {
      TeleCloudLogger.auth(
        'ChannelManager ensureBackupChannel error',
        error: e,
      );
      return null;
    }
  }

  Future<int?> _findExistingBackupChannel() async {
    TeleCloudLogger.auth(
      'Searching for existing "${AppConstants.telegramChannelTitle}" in user account...',
    );
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
      client.send(const td.SearchChats(query: 'TeleCloud', limit: 50));
      client.send(const td.SearchChats(query: 'Photos', limit: 50));

      await Future.delayed(const Duration(milliseconds: 1500));

      final targetTitle =
          AppConstants.telegramChannelTitle.trim().toLowerCase();
      for (final id in candidateChatIds) {
        final chat = await _verifyChannelExists(id);
        if (chat != null) {
          final title = chat.title.trim().toLowerCase();
          if (title == targetTitle || title.contains('telecloud')) {
            TeleCloudLogger.auth(
                'Found existing matching supergroup: "${chat.title}" ($id)');
            return id;
          }
        }
      }
    } catch (e) {
      TeleCloudLogger.auth('Error while searching existing chats: $e');
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

  Future<int?> _createNewBackupChannel() async {
    TeleCloudLogger.auth(
      'Creating private supergroup forum channel: "${AppConstants.telegramChannelTitle}"',
    );
    final completer = Completer<int?>();
    late StreamSubscription sub;
    final prefs = await SharedPreferences.getInstance();

    sub = client.events.listen((event) async {
      if (event is td.Chat) {
        if (event.title == AppConstants.telegramChannelTitle) {
          _channelId = event.id;
          await _storage.write(key: _channelKey, value: event.id.toString());
          await prefs.setInt(AppConstants.channelIdKey, event.id);
          TeleCloudLogger.auth('Channel created and stored: ${event.id}');
          completer.complete(event.id);
          sub.cancel();
        }
      } else if (event is td.TdError) {
        TeleCloudLogger.auth(
          'Create channel error: [${event.code}] ${event.message}',
        );
        completer.complete(null);
        sub.cancel();
      }
    });

    client.send(
      const td.CreateNewSupergroupChat(
        title: AppConstants.telegramChannelTitle,
        isForum: true,
        isChannel: false,
        description: 'TeleCloud Private Photo & Video Backup Storage',
        location: null,
        messageAutoDeleteTime: 0,
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

  /// Re-opens a closed forum topic thread in the supergroup
  Future<bool> reopenForumTopic(int chatId, int messageThreadId) async {
    TeleCloudLogger.tdlib(
      'Attempting to re-open closed forum topic (threadId: $messageThreadId, chatId: $chatId)...',
    );
    final completer = Completer<bool>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.Ok) {
        TeleCloudLogger.tdlib(
          'Successfully re-opened forum topic $messageThreadId',
        );
        completer.complete(true);
        sub.cancel();
      } else if (event is td.TdError) {
        TeleCloudLogger.tdlib(
          'Failed to re-open topic: [${event.code}] ${event.message}',
        );
        completer.complete(false);
        sub.cancel();
      }
    });

    client.send(
      td.ToggleForumTopicIsClosed(
        chatId: chatId,
        messageThreadId: messageThreadId,
        isClosed: false,
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        sub.cancel();
        return false;
      },
    );
  }

  /// Ensures a dedicated topic exists for the given album/folder name
  Future<int?> ensureAlbumTopic(String albumName) async {
    if (_channelId == null) {
      await ensureBackupChannel();
    }
    if (_channelId == null) return null;

    final cleanAlbumName = albumName.trim();

    // 1. Check user-defined folder-to-topic mapping first
    final mappedThreadId = await getFolderTopicMapping(cleanAlbumName);
    if (mappedThreadId != null) {
      TeleCloudLogger.tdlib(
        'Using custom user-mapped topic thread $mappedThreadId for "$cleanAlbumName"',
      );
      return mappedThreadId;
    }

    final topicStorageKey =
        'album_topic_${_channelId}_${cleanAlbumName.toLowerCase().replaceAll(' ', '_')}';
    final savedThreadIdStr = await _storage.read(key: topicStorageKey);

    if (savedThreadIdStr != null) {
      final savedThreadId = int.tryParse(savedThreadIdStr);
      if (savedThreadId != null) {
        TeleCloudLogger.tdlib(
          'Reusing cached topic thread $savedThreadId for "$cleanAlbumName"',
        );
        return savedThreadId;
      }
    }

    // Check online in Telegram supergroup if a forum topic with this name already exists
    final existingTopics = await _fetchForumTopics();
    for (final topic in existingTopics) {
      if (topic.info.name.trim().toLowerCase() ==
          cleanAlbumName.toLowerCase()) {
        final threadId = topic.info.messageThreadId;
        await _storage.write(key: topicStorageKey, value: threadId.toString());
        if (topic.info.isClosed) {
          await reopenForumTopic(_channelId!, threadId);
        }
        TeleCloudLogger.tdlib(
          'Found existing remote forum topic for "$cleanAlbumName" (thread $threadId). Reusing.',
        );
        return threadId;
      }
    }

    final newThreadId = await createAlbumTopic(cleanAlbumName);
    if (newThreadId != null) {
      await _storage.write(key: topicStorageKey, value: newThreadId.toString());
      TeleCloudLogger.tdlib(
        'Saved topic mapping: "$cleanAlbumName" -> $newThreadId',
      );
    }
    return newThreadId;
  }

  /// Updates or invalidates stored topic mapping when deleted
  Future<void> invalidateAlbumTopic(String albumName) async {
    if (_channelId == null) return;
    final topicStorageKey =
        'album_topic_${_channelId}_${albumName.toLowerCase().replaceAll(' ', '_')}';
    await _storage.delete(key: topicStorageKey);
    TeleCloudLogger.tdlib('Invalidated topic mapping for "$albumName"');
  }

  Future<int?> createAlbumTopic(String albumName) async {
    if (_channelId == null) return null;
    TeleCloudLogger.tdlib('Creating forum topic for album "$albumName"...');
    await Future.delayed(const Duration(milliseconds: 500));

    final completer = Completer<int?>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.ForumTopicInfo) {
        TeleCloudLogger.tdlib(
          'Forum topic created with thread ID: ${event.messageThreadId}',
        );
        completer.complete(event.messageThreadId);
        sub.cancel();
      } else if (event is td.TdError) {
        TeleCloudLogger.tdlib(
          'Create forum topic error: [${event.code}] ${event.message}',
        );
        completer.complete(null);
        sub.cancel();
      }
    });

    client.send(
      td.CreateForumTopic(
        chatId: _channelId!,
        name: albumName,
        icon: const td.ForumTopicIcon(color: 0x6FB9F0, customEmojiId: 0),
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        sub.cancel();
        return null;
      },
    );
  }

  /// Restores and deduplicates media from Telegram channel & all forum topics into local database
  Future<int> syncFromCloud(MediaDao mediaDao) async {
    if (_channelId == null) {
      await ensureBackupChannel();
    }
    if (_channelId == null) return 0;

    TeleCloudLogger.auth(
      'Starting comprehensive cloud deduplication & sync for channel $_channelId...',
    );
    int restoredCount = 0;
    final allCollectedMessages = <int, td.Message>{};

    // 1. Fetch from General Thread (0)
    final rootMessages = await _fetchChatHistory(threadId: 0);
    for (final msg in rootMessages) {
      allCollectedMessages[msg.id] = msg;
    }

    // 2. Fetch from All Forum Topics
    final forumTopics = await _fetchForumTopics();
    TeleCloudLogger.auth(
      'Discovered ${forumTopics.length} forum topics for sync: ${forumTopics.map((t) => t.info.name).toList()}',
    );
    for (final topic in forumTopics) {
      final topicMessages = await _fetchChatHistory(
        threadId: topic.info.messageThreadId,
      );
      for (final msg in topicMessages) {
        allCollectedMessages[msg.id] = msg;
      }
    }

    // 3. Search Chat Messages for Documents across all threads
    final searchDocs = await _searchMessages(
      filter: const td.SearchMessagesFilterDocument(),
    );
    for (final msg in searchDocs) {
      allCollectedMessages[msg.id] = msg;
    }

    TeleCloudLogger.auth(
      'Aggregated ${allCollectedMessages.length} total messages from Telegram Cloud. Processing deduplication...',
    );

    final companions = <MediaItemsCompanion>[];

    for (final msg in allCollectedMessages.values) {
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

      final targetName = meta?.filename ?? rawFilename;
      if (targetName != null && targetName.isNotEmpty) {
        // Mark local photo as backed up
        final matched = await mediaDao.markMediaAsBackedUp(
          filename: targetName,
          capturedAt: meta?.capturedAt,
          sizeBytes: meta?.fileSizeBytes ?? size,
          msgId: msg.id,
          fileId: remoteFileId,
        );

        if (matched) {
          TeleCloudLogger.auth(
            'Deduplicated local photo "$targetName" with Telegram Cloud message ${msg.id}',
          );
        }

        companions.add(
          MediaItemsCompanion.insert(
            localId: 'tg_${msg.id}',
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
        );
        restoredCount++;
      }
    }

    if (companions.isNotEmpty) {
      await mediaDao.insertOrIgnoreBatch(companions);
    }

    TeleCloudLogger.auth(
      'Completed cloud deduplication: $restoredCount cloud items indexed, local queue updated.',
    );
    return restoredCount;
  }

  Future<List<td.Message>> _fetchChatHistory({required int threadId}) async {
    final completer = Completer<List<td.Message>>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.Messages) {
        completer.complete(event.messages);
        sub.cancel();
      } else if (event is td.TdError) {
        completer.complete([]);
        sub.cancel();
      }
    });

    client.send(
      td.GetChatHistory(
        chatId: _channelId!,
        fromMessageId: 0,
        offset: 0,
        limit: 100,
        onlyLocal: false,
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        sub.cancel();
        return [];
      },
    );
  }

  Future<List<td.ForumTopic>> _fetchForumTopics() async {
    final completer = Completer<List<td.ForumTopic>>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.ForumTopics) {
        completer.complete(event.topics);
        sub.cancel();
      } else if (event is td.TdError) {
        completer.complete([]);
        sub.cancel();
      }
    });

    client.send(
      td.GetForumTopics(
        chatId: _channelId!,
        query: '',
        offsetDate: 0,
        offsetMessageId: 0,
        offsetMessageThreadId: 0,
        limit: 100,
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        sub.cancel();
        return [];
      },
    );
  }

  Future<List<td.Message>> _searchMessages({
    required td.SearchMessagesFilter filter,
  }) async {
    final completer = Completer<List<td.Message>>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.Messages) {
        completer.complete(event.messages);
        sub.cancel();
      } else if (event is td.TdError) {
        completer.complete([]);
        sub.cancel();
      }
    });

    client.send(
      td.SearchChatMessages(
        chatId: _channelId!,
        query: '',
        fromMessageId: 0,
        offset: 0,
        limit: 100,
        filter: filter,
        messageThreadId: 0,
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        sub.cancel();
        return [];
      },
    );
  }

  // ==========================================
  // TOPIC MANAGEMENT & FOLDER MAPPING METHODS
  // ==========================================

  /// Returns all forum topics in the active supergroup
  Future<List<td.ForumTopic>> getSupergroupTopics() async {
    if (_channelId == null) {
      await ensureBackupChannel();
    }
    if (_channelId == null) return [];
    return await _fetchForumTopics();
  }

  /// Creates a custom forum topic with custom title and color/emoji icon
  Future<int?> createCustomTopic(
    String title, {
    int iconColor = 0x6FB9F0,
    int iconCustomEmojiId = 0,
  }) async {
    if (_channelId == null) {
      await ensureBackupChannel();
    }
    if (_channelId == null) return null;

    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return null;

    final completer = Completer<int?>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.ForumTopicInfo) {
        TeleCloudLogger.tdlib(
          'Custom forum topic "${event.name}" created with thread ID: ${event.messageThreadId}',
        );
        completer.complete(event.messageThreadId);
        sub.cancel();
      } else if (event is td.TdError) {
        TeleCloudLogger.tdlib(
          'Create custom topic error: [${event.code}] ${event.message}',
        );
        completer.complete(null);
        sub.cancel();
      }
    });

    client.send(
      td.CreateForumTopic(
        chatId: _channelId!,
        name: cleanTitle,
        icon: td.ForumTopicIcon(
          color: iconColor,
          customEmojiId: iconCustomEmojiId,
        ),
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        sub.cancel();
        return null;
      },
    );
  }

  /// Edits/renames an existing forum topic
  Future<bool> editCustomTopic(
    int messageThreadId, {
    required String newTitle,
    int? iconCustomEmojiId,
  }) async {
    if (_channelId == null) return false;

    final completer = Completer<bool>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.Ok) {
        completer.complete(true);
        sub.cancel();
      } else if (event is td.TdError) {
        completer.complete(false);
        sub.cancel();
      }
    });

    client.send(
      td.EditForumTopic(
        chatId: _channelId!,
        messageThreadId: messageThreadId,
        name: newTitle.trim(),
        editIconCustomEmoji: iconCustomEmojiId != null,
        iconCustomEmojiId: iconCustomEmojiId ?? 0,
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        sub.cancel();
        return false;
      },
    );
  }

  /// Deletes/closes an existing forum topic
  Future<bool> deleteCustomTopic(int messageThreadId) async {
    if (_channelId == null) return false;

    final completer = Completer<bool>();
    late StreamSubscription sub;

    sub = client.events.listen((event) {
      if (event is td.Ok) {
        completer.complete(true);
        sub.cancel();
      } else if (event is td.TdError) {
        completer.complete(false);
        sub.cancel();
      }
    });

    client.send(
      td.DeleteForumTopic(
        chatId: _channelId!,
        messageThreadId: messageThreadId,
      ),
    );

    return await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        sub.cancel();
        return false;
      },
    );
  }

  /// Sets a manual mapping between a local folder/album name and a Telegram forum topic
  Future<void> setFolderTopicMapping(
    String folderName,
    int messageThreadId,
  ) async {
    if (_channelId == null) return;
    final key = 'custom_map_${_channelId}_${folderName.trim().toLowerCase()}';
    await _storage.write(key: key, value: messageThreadId.toString());
    TeleCloudLogger.tdlib(
      'Mapped folder "$folderName" -> Topic $messageThreadId',
    );
  }

  /// Gets manual topic ID mapped to the given folder/album name
  Future<int?> getFolderTopicMapping(String folderName) async {
    if (_channelId == null) return null;
    final key = 'custom_map_${_channelId}_${folderName.trim().toLowerCase()}';
    final saved = await _storage.read(key: key);
    if (saved != null) {
      return int.tryParse(saved);
    }
    return null;
  }

  /// Removes manual folder-to-topic mapping
  Future<void> removeFolderTopicMapping(String folderName) async {
    if (_channelId == null) return;
    final key = 'custom_map_${_channelId}_${folderName.trim().toLowerCase()}';
    await _storage.delete(key: key);
    TeleCloudLogger.tdlib('Removed custom topic mapping for "$folderName"');
  }

  /// Fetches all active custom folder-to-topic mappings for the active supergroup
  Future<Map<String, int>> getAllFolderTopicMappings() async {
    if (_channelId == null) return {};
    final allKeys = await _storage.readAll();
    final prefix = 'custom_map_${_channelId}_';
    final result = <String, int>{};

    for (final entry in allKeys.entries) {
      if (entry.key.startsWith(prefix)) {
        final folderName = entry.key.substring(prefix.length);
        final topicId = int.tryParse(entry.value);
        if (topicId != null) {
          result[folderName] = topicId;
        }
      }
    }
    return result;
  }
}
