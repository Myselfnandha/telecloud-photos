import 'package:drift/drift.dart';
import '../tables/media_table.dart';
import '../tables/albums_table.dart';
import '../tables/folder_sync_table.dart';
import '../app_database.dart';

part 'media_dao.g.dart';

@DriftAccessor(tables: [MediaItems, Albums, FolderSyncSettings])
class MediaDao extends DatabaseAccessor<AppDatabase> with _$MediaDaoMixin {
  MediaDao(super.db);

  Stream<List<MediaItem>> watchAllMedia() {
    return (select(mediaItems)
          ..where((t) => t.isTrashed.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .watch();
  }

  Stream<List<MediaItem>> watchFavorites() {
    return (select(mediaItems)
          ..where((t) => t.isFavorite.equals(true) & t.isTrashed.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .watch();
  }

  Stream<List<MediaItem>> watchTrash() {
    return (select(mediaItems)
          ..where((t) => t.isTrashed.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.trashedAt)]))
        .watch();
  }

  Stream<List<MediaItem>> watchCloudOnlyMedia() {
    return (select(mediaItems)
          ..where(
            (t) =>
                t.uploadStatus.equals(UploadStatus.done.index) &
                t.localId.like('tg_%') &
                t.isTrashed.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .watch();
  }

  Stream<List<MediaItem>> watchGooglePhotosMedia() {
    return (select(mediaItems)
          ..where((t) => t.localId.like('gp_%') & t.isTrashed.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .watch();
  }

  Stream<List<MediaItem>> watchPendingUploads() {
    return (select(mediaItems)
          ..where(
            (t) =>
                t.uploadStatus.equals(UploadStatus.pending.index) &
                t.isTrashed.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.capturedAt)]))
        .watch();
  }

  /// Streams active queue items: pending, currently uploading, or failed retries.
  Stream<List<MediaItem>> watchActiveUploadQueue() {
    return (select(mediaItems)
          ..where(
            (t) =>
                (t.uploadStatus.equals(UploadStatus.pending.index) |
                    t.uploadStatus.equals(UploadStatus.uploading.index) |
                    t.uploadStatus.equals(UploadStatus.failed.index)) &
                t.isTrashed.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.capturedAt)]))
        .watch();
  }

  Future<List<MediaItem>> getPendingUploads() {
    return (select(mediaItems)
          ..where(
            (t) =>
                t.uploadStatus.equals(UploadStatus.pending.index) &
                t.isTrashed.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.capturedAt)]))
        .get();
  }

  Stream<List<MediaItem>> watchUploadedMedia() {
    return (select(mediaItems)
          ..where(
            (t) =>
                t.uploadStatus.equals(UploadStatus.done.index) &
                t.isTrashed.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .watch();
  }

  Future<MediaItem?> getMediaById(String localId) {
    return (select(
      mediaItems,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
  }

  Stream<List<MediaItem>> watchMediaInAlbum(int albumId) {
    return (select(mediaItems)
          ..where((t) => t.albumId.equals(albumId) & t.isTrashed.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .watch();
  }

  Future<void> insertOrIgnoreBatch(List<MediaItemsCompanion> items) async {
    await batch((b) {
      b.insertAll(mediaItems, items, mode: InsertMode.insertOrIgnore);
    });
  }

  Future<bool> updateUploadStatus(
    String localId,
    UploadStatus status, {
    int? msgId,
    String? fileId,
  }) async {
    final count =
        await (update(
          mediaItems,
        )..where((t) => t.localId.equals(localId))).write(
          MediaItemsCompanion(
            uploadStatus: Value(status),
            telegramMsgId: msgId != null ? Value(msgId) : const Value.absent(),
            telegramFileId: fileId != null
                ? Value(fileId)
                : const Value.absent(),
          ),
        );
    return count > 0;
  }

  Future<bool> toggleFavorite(String localId, bool isFavorite) async {
    final count =
        await (update(mediaItems)..where((t) => t.localId.equals(localId)))
            .write(MediaItemsCompanion(isFavorite: Value(isFavorite)));
    return count > 0;
  }

  Future<int> moveToTrash(List<String> localIds) async {
    final now = DateTime.now();
    return (update(mediaItems)..where((t) => t.localId.isIn(localIds))).write(
      MediaItemsCompanion(isTrashed: const Value(true), trashedAt: Value(now)),
    );
  }

  Future<int> restoreFromTrash(List<String> localIds) async {
    return (update(mediaItems)..where((t) => t.localId.isIn(localIds))).write(
      const MediaItemsCompanion(
        isTrashed: Value(false),
        trashedAt: Value(null),
      ),
    );
  }

  Future<int> purgeTrashItems(List<String> localIds) async {
    return (delete(mediaItems)..where((t) => t.localId.isIn(localIds))).go();
  }

  Future<List<MediaItem>> getBackedUpLocalMedia() {
    return (select(mediaItems)..where(
          (t) =>
              t.uploadStatus.equals(UploadStatus.done.index) &
              t.telegramFileId.isNotNull() &
              t.isTrashed.equals(false) &
              t.localId.like('tg_%').not(),
        ))
        .get();
  }

  Future<List<MediaItem>> getMemoriesForDate(int month, int day) async {
    final all = await (select(
      mediaItems,
    )..where((t) => t.isTrashed.equals(false))).get();
    final now = DateTime.now();
    return all.where((item) {
      final dt = item.capturedAt;
      return dt.month == month && dt.day == day && dt.year < now.year;
    }).toList();
  }

  Future<List<MediaItem>> getAllMedia() {
    return (select(mediaItems)
          ..where((t) => t.isTrashed.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .get();
  }

  Future<void> updateThumbnailPath(String localId, String thumbPath) async {
    await (update(mediaItems)..where((t) => t.localId.equals(localId))).write(
      MediaItemsCompanion(thumbnailPath: Value(thumbPath)),
    );
  }

  Future<bool> markMediaAsBackedUp({
    required String filename,
    DateTime? capturedAt,
    int? sizeBytes,
    int? msgId,
    String? fileId,
  }) async {
    final cleanName = filename.trim().toLowerCase();
    // 1. Direct case-insensitive match
    var count =
        await (update(
          mediaItems,
        )..where((t) => t.filename.lower().equals(cleanName))).write(
          MediaItemsCompanion(
            uploadStatus: const Value(UploadStatus.done),
            telegramMsgId: msgId != null ? Value(msgId) : const Value.absent(),
            telegramFileId: fileId != null
                ? Value(fileId)
                : const Value.absent(),
          ),
        );
    if (count > 0) return true;

    // 2. Base name match (e.g. viewer_detail vs viewer_detail.png)
    final baseName = cleanName.contains('.')
        ? cleanName.split('.').first
        : cleanName;
    if (baseName.length >= 4) {
      count =
          await (update(
            mediaItems,
          )..where((t) => t.filename.lower().like('%$baseName%'))).write(
            MediaItemsCompanion(
              uploadStatus: const Value(UploadStatus.done),
              telegramMsgId: msgId != null
                  ? Value(msgId)
                  : const Value.absent(),
              telegramFileId: fileId != null
                  ? Value(fileId)
                  : const Value.absent(),
            ),
          );
      if (count > 0) return true;
    }

    return false;
  }

  Stream<List<MediaItem>> searchMedia(String query) {
    final cleanQuery = '%${query.trim().toLowerCase()}%';
    return (select(mediaItems)
          ..where(
            (t) =>
                (t.filename.lower().like(cleanQuery) |
                    t.mimeType.lower().like(cleanQuery)) &
                t.isTrashed.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .watch();
  }

  /// Sets pending upload status for items in enabled folders and removes pending status for items outside enabled folders.
  Future<void> syncPendingQueueScope(Set<String> enabledLocalIds) async {
    // 1. For items not in enabledLocalIds (and not external cloud items like tg_% or gp_%), mark them as done/not pending
    await (update(mediaItems)..where(
          (t) =>
              t.uploadStatus.equals(UploadStatus.pending.index) &
              t.localId.isIn(enabledLocalIds).not() &
              t.localId.like('tg_%').not() &
              t.localId.like('gp_%').not(),
        ))
        .write(
          const MediaItemsCompanion(uploadStatus: Value(UploadStatus.done)),
        );

    // 2. For items that are in enabledLocalIds and haven't been uploaded yet (no telegramFileId), ensure they are marked pending
    if (enabledLocalIds.isNotEmpty) {
      await (update(mediaItems)..where(
            (t) =>
                t.localId.isIn(enabledLocalIds) &
                t.telegramFileId.isNull() &
                t.telegramMsgId.isNull() &
                t.isTrashed.equals(false),
          ))
          .write(
            const MediaItemsCompanion(
              uploadStatus: Value(UploadStatus.pending),
            ),
          );
    }
  }

  // Albums operations
  Stream<List<Album>> watchAllAlbums() {
    return (select(
      albums,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<List<Album>> getAllAlbums() {
    return (select(
      albums,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<Album?> getAlbumById(int id) {
    return (select(albums)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Album> getOrCreateAlbum(String name, {int? topicId}) async {
    final existing = await (select(
      albums,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
    if (existing != null) {
      if (topicId != null && existing.telegramTopicId == null) {
        await (update(albums)..where((t) => t.id.equals(existing.id))).write(
          AlbumsCompanion(telegramTopicId: Value(topicId)),
        );
      }
      return existing;
    }
    final id = await createAlbum(name, topicId: topicId);
    return (select(albums)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<int> createAlbum(String name, {int? topicId}) {
    return into(albums).insert(
      AlbumsCompanion.insert(
        name: name,
        telegramTopicId: topicId != null
            ? Value(topicId)
            : const Value.absent(),
      ),
    );
  }

  Future<void> assignMediaToAlbum(String localId, int albumId) {
    return (update(mediaItems)..where((t) => t.localId.equals(localId))).write(
      MediaItemsCompanion(albumId: Value(albumId)),
    );
  }

  Future<int> queueLocalIdsForUpload(List<String> localIds) async {
    if (localIds.isEmpty) return 0;
    return (update(mediaItems)
          ..where((t) => t.localId.isIn(localIds) & t.isTrashed.equals(false)))
        .write(
          const MediaItemsCompanion(uploadStatus: Value(UploadStatus.pending)),
        );
  }

  Future<int> queueAlbumForUpload(int albumId) async {
    return (update(mediaItems)..where(
          (t) =>
              t.albumId.equals(albumId) &
              t.telegramFileId.isNull() &
              t.isTrashed.equals(false),
        ))
        .write(
          const MediaItemsCompanion(uploadStatus: Value(UploadStatus.pending)),
        );
  }

  Future<int> deleteAlbum(int albumId) async {
    await (update(mediaItems)..where((t) => t.albumId.equals(albumId))).write(
      const MediaItemsCompanion(albumId: Value(null)),
    );
    return (delete(albums)..where((t) => t.id.equals(albumId))).go();
  }

  /// Purges all mock Google Photos items and sample albums from SQLite.
  Future<void> purgeMockData() async {
    // 1. Delete mock media items (e.g. gp_sample_...)
    await (delete(mediaItems)
          ..where((t) => t.localId.like('gp_sample_%') | t.localId.like('mock_%')))
        .go();

    // 2. Delete mock predefined albums
    final mockAlbumNames = [
      'Summer Vacation 2024',
      'Family Memories',
      'Europe Tour',
      'Mock Album',
      'Sample Album',
    ];
    for (final name in mockAlbumNames) {
      final found = await (select(albums)..where((t) => t.name.equals(name))).get();
      for (final a in found) {
        await deleteAlbum(a.id);
      }
    }
  }

  // --- Smart Hash Deduplication Queries ---

  /// Finds an already backed-up media item with matching SHA-256 hash.
  Future<MediaItem?> getBackedUpMediaBySha256(String hash) {
    return (select(mediaItems)
          ..where(
            (t) =>
                t.sha256Hash.equals(hash) &
                t.telegramFileId.isNotNull() &
                t.uploadStatus.equals(UploadStatus.done.index) &
                t.isTrashed.equals(false),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  /// Updates the computed SHA-256 hash for a media item.
  Future<bool> updateMediaHash(String localId, String hash) async {
    final count = await (update(mediaItems)
          ..where((t) => t.localId.equals(localId)))
        .write(MediaItemsCompanion(sha256Hash: Value(hash)));
    return count > 0;
  }

  /// Retrieves local items without a computed hash.
  Future<List<MediaItem>> getUncomputedHashLocalMedia({int limit = 50}) {
    return (select(mediaItems)
          ..where(
            (t) =>
                t.sha256Hash.isNull() &
                t.isTrashed.equals(false) &
                t.localId.like('tg_%').not() &
                t.localId.like('gp_%').not(),
          )
          ..limit(limit))
        .get();
  }

  // --- Selective Folder Sync Queries ---

  /// Streams all folder sync settings ordered by folder name.
  Stream<List<FolderSyncSetting>> watchFolderSyncSettings() {
    return (select(folderSyncSettings)
          ..orderBy([(t) => OrderingTerm.asc(t.folderName)]))
        .watch();
  }

  /// Gets all folder sync settings.
  Future<List<FolderSyncSetting>> getAllFolderSyncSettings() {
    return (select(folderSyncSettings)
          ..orderBy([(t) => OrderingTerm.asc(t.folderName)]))
        .get();
  }

  /// Gets a specific folder sync setting by folderId.
  Future<FolderSyncSetting?> getFolderSyncSetting(String folderId) {
    return (select(folderSyncSettings)
          ..where((t) => t.folderId.equals(folderId)))
        .getSingleOrNull();
  }

  /// Inserts or updates folder sync setting.
  Future<void> upsertFolderSyncSetting(
    FolderSyncSettingsCompanion setting,
  ) async {
    await into(folderSyncSettings).insertOnConflictUpdate(setting);
  }

  /// Enables or disables auto-backup for a folder.
  Future<bool> setFolderAutoBackup(String folderId, bool isEnabled) async {
    final count = await (update(folderSyncSettings)
          ..where((t) => t.folderId.equals(folderId)))
        .write(FolderSyncSettingsCompanion(isAutoBackupEnabled: Value(isEnabled)));
    return count > 0;
  }

  /// Queues all non-uploaded media in a specific folder for backup.
  Future<int> queueFolderMediaForUpload(String folderName) async {
    return (update(mediaItems)
          ..where(
            (t) =>
                t.folderName.equals(folderName) &
                t.telegramFileId.isNull() &
                t.isTrashed.equals(false),
          ))
        .write(
          const MediaItemsCompanion(uploadStatus: Value(UploadStatus.pending)),
        );
  }

  /// Streams all media items belonging to a specific device folder.
  Stream<List<MediaItem>> watchMediaByFolder(String folderName) {
    return (select(mediaItems)
          ..where(
            (t) => t.folderName.equals(folderName) & t.isTrashed.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .watch();
  }
}


