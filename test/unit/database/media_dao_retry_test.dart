import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/media_dao.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';

void main() {
  group('MediaDao Retry & Failed Queries Unit Tests', () {
    late AppDatabase db;
    late MediaDao dao;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = MediaDao(db);

      final now = DateTime.now();
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'f_item_1',
          filename: 'fail1.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.failed,
          mimeType: 'image/jpeg',
        ),
        MediaItemsCompanion.insert(
          localId: 'f_item_2',
          filename: 'fail2.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.failed,
          mimeType: 'image/jpeg',
        ),
        MediaItemsCompanion.insert(
          localId: 'p_item_1',
          filename: 'pending1.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.pending,
          mimeType: 'image/jpeg',
        ),
      ]);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. watchFailedCount streams the active number of failed uploads',
        () async {
      final initialCount = await dao.watchFailedCount().first;
      expect(initialCount, 2);
    });

    test('2. retryFailedItem sets single failed item status to pending',
        () async {
      final updated = await dao.retryFailedItem('f_item_1');
      expect(updated, 1);

      final item1 = await dao.getMediaById('f_item_1');
      final item2 = await dao.getMediaById('f_item_2');

      expect(item1?.uploadStatus, UploadStatus.pending);
      expect(item2?.uploadStatus, UploadStatus.failed);

      final newCount = await dao.watchFailedCount().first;
      expect(newCount, 1);
    });

    test('3. retryAllFailed sets all failed items status to pending', () async {
      final updated = await dao.retryAllFailed();
      expect(updated, 2);

      final item1 = await dao.getMediaById('f_item_1');
      final item2 = await dao.getMediaById('f_item_2');

      expect(item1?.uploadStatus, UploadStatus.pending);
      expect(item2?.uploadStatus, UploadStatus.pending);

      final newCount = await dao.watchFailedCount().first;
      expect(newCount, 0);
    });
  });
}
