import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/media_dao.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';

void main() {
  late AppDatabase db;
  late MediaDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = MediaDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MediaDao — Complete CRUD & Streaming Functions', () {
    test(
      '1. insertOrIgnoreBatch & watchAllMedia (ordering descending)',
      () async {
        final now = DateTime.now();
        final companions = List.generate(
          100,
          (i) => MediaItemsCompanion.insert(
            localId: 'asset_$i',
            filename: 'IMG_$i.jpg',
            capturedAt: now.subtract(Duration(minutes: i * 5)),
            width: const Value(1920),
            height: const Value(1080),
            fileSizeBytes: const Value(1024000),
            mimeType: 'image/jpeg',
            uploadStatus: UploadStatus.pending,
          ),
        );

        await dao.insertOrIgnoreBatch(companions);

        final mediaList = await dao.watchAllMedia().first;
        expect(mediaList.length, 100);

        // Verify ordering
        for (int i = 0; i < mediaList.length - 1; i++) {
          expect(
            mediaList[i].capturedAt.isAfter(mediaList[i + 1].capturedAt) ||
                mediaList[i].capturedAt.isAtSameMomentAs(
                      mediaList[i + 1].capturedAt,
                    ),
            isTrue,
          );
        }
      },
    );

    test('2. updateUploadStatus & getMediaById & watchUploadedMedia', () async {
      final now = DateTime.now();
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'asset_target',
          filename: 'TARGET.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.pending,
        ),
      ]);

      final updated = await dao.updateUploadStatus(
        'asset_target',
        UploadStatus.done,
        msgId: 777,
        fileId: 'tg_file_777',
      );
      expect(updated, isTrue);

      final item = await dao.getMediaById('asset_target');
      expect(item?.uploadStatus, UploadStatus.done);
      expect(item?.telegramMsgId, 777);
      expect(item?.telegramFileId, 'tg_file_777');

      final uploadedList = await dao.watchUploadedMedia().first;
      expect(uploadedList.any((m) => m.localId == 'asset_target'), isTrue);
    });

    test('3. watchPendingUploads filters only pending media', () async {
      final now = DateTime.now();
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'pending_1',
          filename: 'P1.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.pending,
        ),
        MediaItemsCompanion.insert(
          localId: 'done_1',
          filename: 'D1.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
        ),
      ]);

      final pending = await dao.watchPendingUploads().first;
      expect(pending.length, 1);
      expect(pending.first.localId, 'pending_1');
    });

    test('4. searchMedia finds items by filename and date', () async {
      final now = DateTime(2026, 8, 15, 14, 30);
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'vacation_photo',
          filename: 'Eiffel_Tower.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.pending,
        ),
        MediaItemsCompanion.insert(
          localId: 'document_scan',
          filename: 'Passport_Copy.pdf',
          capturedAt: now,
          mimeType: 'application/pdf',
          uploadStatus: UploadStatus.pending,
        ),
      ]);

      final resultsTower = await dao.searchMedia('Eiffel').first;
      expect(resultsTower.length, 1);
      expect(resultsTower.first.localId, 'vacation_photo');

      final resultsPdf = await dao.searchMedia('pdf').first;
      expect(resultsPdf.length, 1);
      expect(resultsPdf.first.localId, 'document_scan');
    });

    test(
      '5. createAlbum, getAllAlbums, watchAllAlbums, watchMediaInAlbum & assignMediaToAlbum',
      () async {
        final albumId = await dao.createAlbum('Summer Trip', topicId: 42);
        expect(albumId, isPositive);

        final albums = await dao.getAllAlbums();
        expect(albums.length, 1);
        expect(albums.first.name, 'Summer Trip');
        expect(albums.first.telegramTopicId, 42);

        final albumsStream = await dao.watchAllAlbums().first;
        expect(albumsStream.length, 1);

        // Add media and assign to album
        await dao.insertOrIgnoreBatch([
          MediaItemsCompanion.insert(
            localId: 'trip_photo',
            filename: 'Beach.jpg',
            capturedAt: DateTime.now(),
            mimeType: 'image/jpeg',
            uploadStatus: UploadStatus.pending,
          ),
        ]);

        await dao.assignMediaToAlbum('trip_photo', albumId);

        final albumMedia = await dao.watchMediaInAlbum(albumId).first;
        expect(albumMedia.length, 1);
        expect(albumMedia.first.localId, 'trip_photo');
        expect(albumMedia.first.albumId, albumId);
      },
    );

    test('6. Favorites (toggleFavorite & watchFavorites)', () async {
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'photo_fav_1',
          filename: 'Fav1.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          isFavorite: const Value(true),
        ),
        MediaItemsCompanion.insert(
          localId: 'photo_regular',
          filename: 'Regular.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          isFavorite: const Value(false),
        ),
      ]);

      final favs = await dao.watchFavorites().first;
      expect(favs.length, 1);
      expect(favs.first.localId, 'photo_fav_1');

      // Toggle regular photo to favorite
      await dao.toggleFavorite('photo_regular', true);
      final updatedFavs = await dao.watchFavorites().first;
      expect(updatedFavs.length, 2);

      // Untoggle first favorite
      await dao.toggleFavorite('photo_fav_1', false);
      final finalFavs = await dao.watchFavorites().first;
      expect(finalFavs.length, 1);
      expect(finalFavs.first.localId, 'photo_regular');
    });

    test(
      '7. Trash lifecycle (moveToTrash, watchTrash, restoreFromTrash, purgeTrashItems)',
      () async {
        await dao.insertOrIgnoreBatch([
          MediaItemsCompanion.insert(
            localId: 'photo_to_trash',
            filename: 'TrashMe.jpg',
            capturedAt: DateTime.now(),
            mimeType: 'image/jpeg',
            uploadStatus: UploadStatus.done,
          ),
        ]);

        expect((await dao.watchAllMedia().first).length, 1);
        expect((await dao.watchTrash().first).length, 0);

        // Move to trash
        await dao.moveToTrash(['photo_to_trash']);
        expect((await dao.watchAllMedia().first).length, 0);
        expect((await dao.watchTrash().first).length, 1);

        // Restore from trash
        await dao.restoreFromTrash(['photo_to_trash']);
        expect((await dao.watchAllMedia().first).length, 1);
        expect((await dao.watchTrash().first).length, 0);

        // Move to trash and permanently purge
        await dao.moveToTrash(['photo_to_trash']);
        await dao.purgeTrashItems(['photo_to_trash']);
        expect((await dao.watchAllMedia().first).length, 0);
        expect((await dao.watchTrash().first).length, 0);
      },
    );

    test('8. Storage Cleanup (getBackedUpLocalMedia)', () async {
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'local_backed_up',
          filename: 'LocalUploaded.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramFileId: const Value('remote_file_123'),
        ),
        MediaItemsCompanion.insert(
          localId: 'tg_remote_only',
          filename: 'RemoteOnly.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramFileId: const Value('remote_file_456'),
        ),
        MediaItemsCompanion.insert(
          localId: 'local_pending',
          filename: 'Pending.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.pending,
        ),
      ]);

      final cleanupCandidates = await dao.getBackedUpLocalMedia();
      expect(cleanupCandidates.length, 1);
      expect(cleanupCandidates.first.localId, 'local_backed_up');
    });

    test('9. Memories (getMemoriesForDate)', () async {
      final now = DateTime.now();
      final oneYearAgo = DateTime(now.year - 1, now.month, now.day, 14, 30);
      final twoYearsAgo = DateTime(now.year - 2, now.month, now.day, 10, 15);
      final yesterday = now.subtract(const Duration(days: 1));

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'memory_1',
          filename: '1YearAgo.jpg',
          capturedAt: oneYearAgo,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
        ),
        MediaItemsCompanion.insert(
          localId: 'memory_2',
          filename: '2YearsAgo.jpg',
          capturedAt: twoYearsAgo,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
        ),
        MediaItemsCompanion.insert(
          localId: 'not_memory',
          filename: 'Yesterday.jpg',
          capturedAt: yesterday,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
        ),
      ]);

      final memories = await dao.getMemoriesForDate(now.month, now.day);
      expect(memories.length, 2);
      expect(memories.map((e) => e.localId).toSet(), {'memory_1', 'memory_2'});
    });

    test('10. Album creation, deleteAlbum unlinking, and queue operations',
        () async {
      final albumId = await dao.createAlbum('Vacation 2024', topicId: 888);
      expect(albumId, isPositive);

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'album_item_1',
          filename: 'Vacation1.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.failed,
          albumId: Value(albumId),
        ),
        MediaItemsCompanion.insert(
          localId: 'album_item_2',
          filename: 'Vacation2.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.failed,
          albumId: Value(albumId),
        ),
      ]);

      // Queue specific album items
      final queued = await dao.queueAlbumForUpload(albumId);
      expect(queued, 2);

      final item1 = await dao.getMediaById('album_item_1');
      expect(item1?.uploadStatus, UploadStatus.pending);
      expect(item1?.albumId, albumId);

      // Delete album and verify media is unlinked but preserved
      final deleted = await dao.deleteAlbum(albumId);
      expect(deleted, 1);

      final album = await dao.getAlbumById(albumId);
      expect(album, isNull);

      final unlinkedItem = await dao.getMediaById('album_item_1');
      expect(unlinkedItem, isNotNull);
      expect(unlinkedItem?.albumId, isNull);
    });
  });
}
