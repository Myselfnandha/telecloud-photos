import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../database/tables/media_table.dart';
import '../telegram/tdlib_client.dart';
import '../telegram/telegram_auth_manager.dart';
import '../telegram/telegram_account_service.dart';
import '../telegram/models/telegram_account.dart';
import '../telegram/channel_manager.dart';
import 'package:tdlib/td_api.dart' as td;
import '../telegram/telegram_upload_service.dart';
import '../backup/media_scanner.dart';
import '../backup/upload_queue.dart';
import '../backup/backup_manager.dart';
import '../sync/upload_telemetry.dart';
import '../media/motion_photo_extractor.dart';
import '../telegram/cloud_video_stream_service.dart';
import '../storage/storage_cleanup_service.dart';
import '../sync/cloud_sync_service.dart';
import '../backup/thumbnail_generator.dart';
import '../backup/media_deduplicator.dart';
import '../backup/sync_policy_guard.dart';
import '../backup/folder_sync_manager.dart';
import '../constants/app_constants.dart';
import '../media/batch_operations_service.dart';
import '../telegram/telegram_download_service.dart';
import '../sync/deleted_media_detector.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Initialize sharedPreferencesProvider in ProviderScope overrides',
  );
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final thumbnailGeneratorProvider = Provider<ThumbnailGenerator>((ref) {
  return ThumbnailGenerator();
});

final storageCleanupServiceProvider = Provider<StorageCleanupService>((ref) {
  final dao = ref.watch(mediaDaoProvider);
  return StorageCleanupService(mediaDao: dao);
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final client = ref.watch(tdlibClientProvider);
  final channelMgr = ref.watch(channelManagerProvider);
  final dao = ref.watch(mediaDaoProvider);
  final service = CloudSyncService(
    tdlibClient: client,
    channelManager: channelMgr,
    mediaDao: dao,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final motionPhotoExtractorProvider = Provider<MotionPhotoExtractor>((ref) {
  return MotionPhotoExtractor();
});

final cloudVideoStreamServiceProvider = Provider<CloudVideoStreamService>((
  ref,
) {
  final client = ref.watch(tdlibClientProvider);
  return CloudVideoStreamService(client);
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final mediaDaoProvider = Provider<MediaDao>((ref) {
  final db = ref.watch(databaseProvider);
  return MediaDao(db);
});

final allMediaStreamProvider = StreamProvider<List<MediaItem>>((ref) {
  final dao = ref.watch(mediaDaoProvider);
  return dao.watchAllMedia().distinct((prev, curr) {
    if (prev.length != curr.length) return false;
    if (prev.isEmpty && curr.isEmpty) return true;
    return prev.first.localId == curr.first.localId &&
        prev.last.localId == curr.last.localId &&
        prev.first.uploadStatus == curr.first.uploadStatus &&
        prev.last.uploadStatus == curr.last.uploadStatus &&
        prev.first.isFavorite == curr.first.isFavorite &&
        prev.last.isFavorite == curr.last.isFavorite;
  });
});

final googlePhotosMediaStreamProvider = StreamProvider<List<MediaItem>>((ref) {
  final dao = ref.watch(mediaDaoProvider);
  return dao.watchGooglePhotosMedia();
});

final tdlibClientProvider = Provider<TdlibClient>((ref) {
  final client = TdlibClient();
  ref.onDispose(() => client.dispose());
  return client;
});

final channelManagerProvider = Provider<ChannelManager>((ref) {
  final client = ref.watch(tdlibClientProvider);
  return ChannelManager(client: client);
});

final telegramUploadServiceProvider = Provider<TelegramUploadService>((ref) {
  final client = ref.watch(tdlibClientProvider);
  final channelManager = ref.watch(channelManagerProvider);
  return TelegramUploadService(client: client, channelManager: channelManager);
});

final mediaScannerProvider = Provider<MediaScanner>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(mediaDaoProvider);
  final channelManager = ref.watch(channelManagerProvider);
  return MediaScanner(
    db: db,
    mediaDao: dao,
    onScanCompleted: () async {
      await channelManager.syncFromCloud(dao);
    },
  );
});

final mediaDeduplicatorProvider = Provider<MediaDeduplicator>((ref) {
  final dao = ref.watch(mediaDaoProvider);
  return MediaDeduplicator(mediaDao: dao);
});

final syncPolicyGuardProvider = Provider<SyncPolicyGuard>((ref) {
  return SyncPolicyGuard();
});

final folderSyncManagerProvider = Provider<FolderSyncManager>((ref) {
  final dao = ref.watch(mediaDaoProvider);
  return FolderSyncManager(mediaDao: dao);
});

final folderSyncListStreamProvider =
    StreamProvider<List<FolderSyncSetting>>((ref) {
  final manager = ref.watch(folderSyncManagerProvider);
  return manager.watchFolders();
});

final uploadQueueProvider = Provider<UploadQueue>((ref) {
  final dao = ref.watch(mediaDaoProvider);
  final deduplicator = ref.watch(mediaDeduplicatorProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final concurrency = prefs.getInt(AppConstants.keyMaxConcurrentUploads) ??
      AppConstants.defaultMaxConcurrentUploads;
  final queue = UploadQueue(mediaDao: dao, deduplicator: deduplicator);
  queue.setConcurrency(concurrency);
  return queue;
});

final uploadProgressStreamProvider = StreamProvider<UploadProgressState>((ref) {
  final queue = ref.watch(uploadQueueProvider);
  return queue.progressStream;
});

final uploadTelemetryProvider =
    StateNotifierProvider<UploadTelemetryNotifier, UploadTelemetryState>((ref) {
  final dao = ref.watch(mediaDaoProvider);
  final client = ref.watch(tdlibClientProvider);
  return UploadTelemetryNotifier(dao, client);
});

final backupManagerProvider =
    StateNotifierProvider<BackupManager, BackupState>((ref) {
  final manager = BackupManager();
  final queue = ref.watch(uploadQueueProvider);
  final uploadService = ref.watch(telegramUploadServiceProvider);
  final channelManager = ref.watch(channelManagerProvider);
  final mediaDao = ref.watch(mediaDaoProvider);
  final telemetryNotifier = ref.watch(uploadTelemetryProvider.notifier);

  manager.onStartUploading = () async {
    final channelId = await channelManager.ensureBackupChannel();
    if (channelId != null) {
      queue.processQueue(
        onBatchStart: (total) {
          telemetryNotifier.startBatch(total);
        },
        onProgress: (progress) {
          manager.updateUploadProgressNotification(progress);
        },
        uploadItem: (item, [int? index, int? total]) async {
          telemetryNotifier.startItemUpload(
            item,
            channelId: channelId,
            itemIndex: index,
            totalCount: total,
          );

          // Resolve album name from item's folderName, albumId, or filename
          String albumName = 'Camera';
          if (item.folderName != null && item.folderName!.isNotEmpty) {
            albumName = item.folderName!;
          } else if (item.albumId != null) {
            final album = await mediaDao.getAlbumById(item.albumId!);
            if (album != null && album.name.isNotEmpty) {
              albumName = album.name;
            }
          } else if (item.filename.toLowerCase().contains('screenshot')) {
            albumName = 'Screenshots';
          }

          final topicId = await channelManager.ensureAlbumTopic(albumName);

          final res = await uploadService.uploadMediaItem(
            item,
            targetChatId: channelId,
            topicId: topicId,
            albumName: albumName,
            onRecoveryEvent: (notice) {
              telemetryNotifier.logRecoveryEvent(notice);
            },
            onUploaded: (msgId, fileId) async {
              await mediaDao.updateUploadStatus(
                item.localId,
                UploadStatus.done,
                msgId: msgId,
                fileId: fileId,
              );
            },
          );
          return res;
        },
        onItemSuccess: (item) {
          telemetryNotifier.onItemCompleted(item);
        },
        onBatchFinish: () {
          telemetryNotifier.finishBatch();
        },
      );
    }
  };

  manager.onStopUploading = () {
    queue.stop();
    telemetryNotifier.stopUploading();
    manager.stopService();
  };

  return manager;
});

final telegramAccountServiceProvider =
    ChangeNotifierProvider<TelegramAccountService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return TelegramAccountService(storage: secureStorage);
});

final activeTelegramAccountProvider = Provider<TelegramAccount?>((ref) {
  final service = ref.watch(telegramAccountServiceProvider);
  return service.activeAccount;
});

final telegramAuthManagerProvider = ChangeNotifierProvider<TelegramAuthManager>(
  (ref) {
    final client = ref.watch(tdlibClientProvider);
    final accountService = ref.watch(telegramAccountServiceProvider);
    final channelManager = ref.watch(channelManagerProvider);
    return TelegramAuthManager(
      client: client,
      accountService: accountService,
      channelManager: channelManager,
    );
  },
);

final supergroupTopicsProvider =
    FutureProvider.autoDispose<List<td.ForumTopic>>((ref) async {
  final channelMgr = ref.watch(channelManagerProvider);
  return await channelMgr.getSupergroupTopics();
});

final folderTopicMappingsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final channelMgr = ref.watch(channelManagerProvider);
  return await channelMgr.getAllFolderTopicMappings();
});

final batchOperationsServiceProvider = Provider<BatchOperationsService>((ref) {
  final mediaDao = ref.watch(mediaDaoProvider);
  return BatchOperationsService(mediaDao: mediaDao);
});

final telegramDownloadServiceProvider =
    Provider<TelegramDownloadService>((ref) {
  final client = ref.watch(tdlibClientProvider);
  final mediaDao = ref.watch(mediaDaoProvider);
  return TelegramDownloadService(client: client, mediaDao: mediaDao);
});

final deletedMediaDetectorProvider = Provider<DeletedMediaDetector>((ref) {
  final mediaDao = ref.watch(mediaDaoProvider);
  return DeletedMediaDetector(mediaDao: mediaDao);
});
