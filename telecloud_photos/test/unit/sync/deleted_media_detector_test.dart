import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/media_dao.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/core/sync/deleted_media_detector.dart';

void main() {
  group('DeletedMediaDetector Unit Tests', () {
    late AppDatabase db;
    late MediaDao dao;
    late DeletedMediaDetector detector;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = MediaDao(db);
      detector = DeletedMediaDetector(mediaDao: dao);
    });

    tearDown(() async {
      await db.close();
    });

    test(
        '1. detectDeletedFromDevice identifies cloud-backed items without local files',
        () async {
      final now = DateTime.now();
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'cloud_backed_missing',
          filename: 'missing.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.done,
          telegramFileId: const Value('12345'),
          thumbnailPath: const Value('/nonexistent/path/missing.jpg'),
          mimeType: 'image/jpeg',
        ),
      ]);

      final deleted = await detector.detectDeletedFromDevice();
      expect(deleted.length, 1);
      expect(deleted.first.localId, 'cloud_backed_missing');
    });

    test('2. detectDeletedFromDevice ignores items that are not backed up',
        () async {
      final now = DateTime.now();
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'local_pending_item',
          filename: 'pending.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.pending,
          mimeType: 'image/jpeg',
        ),
      ]);

      final deleted = await detector.detectDeletedFromDevice();
      expect(deleted.isEmpty, isTrue);
    });
  });
}
