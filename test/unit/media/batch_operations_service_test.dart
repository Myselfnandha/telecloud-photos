import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/media_dao.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/core/media/batch_operations_service.dart';

void main() {
  group('BatchOperationsService Unit Tests', () {
    late AppDatabase db;
    late MediaDao dao;
    late BatchOperationsService service;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = MediaDao(db);
      service = BatchOperationsService(mediaDao: dao);

      final now = DateTime.now();
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'b_item_1',
          filename: 'photo1.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.done,
          mimeType: 'image/jpeg',
        ),
        MediaItemsCompanion.insert(
          localId: 'b_item_2',
          filename: 'photo2.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.done,
          mimeType: 'image/jpeg',
        ),
        MediaItemsCompanion.insert(
          localId: 'b_item_3',
          filename: 'photo3.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.done,
          mimeType: 'image/jpeg',
        ),
      ]);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. batchDelete moves specified items to trash', () async {
      final affected = await service.batchDelete(['b_item_1', 'b_item_2']);
      expect(affected, 2);

      final item1 = await dao.getMediaById('b_item_1');
      final item2 = await dao.getMediaById('b_item_2');
      final item3 = await dao.getMediaById('b_item_3');

      expect(item1?.isTrashed, isTrue);
      expect(item2?.isTrashed, isTrue);
      expect(item3?.isTrashed, isFalse);
    });

    test('2. batchRestore restores specified items from trash', () async {
      await service.batchDelete(['b_item_1', 'b_item_2']);
      final restored = await service.batchRestore(['b_item_1']);
      expect(restored, 1);

      final item1 = await dao.getMediaById('b_item_1');
      final item2 = await dao.getMediaById('b_item_2');

      expect(item1?.isTrashed, isFalse);
      expect(item2?.isTrashed, isTrue);
    });

    test('3. batchPurge permanently removes items from database', () async {
      await service.batchDelete(['b_item_1', 'b_item_2']);
      final purged = await service.batchPurge(['b_item_1']);
      expect(purged, 1);

      final item1 = await dao.getMediaById('b_item_1');
      final item2 = await dao.getMediaById('b_item_2');

      expect(item1, isNull);
      expect(item2, isNotNull);
    });

    test('4. batchToggleFavorite updates favorite status on multiple items',
        () async {
      final toggled = await service.batchToggleFavorite(
        ['b_item_1', 'b_item_2'],
        isFavorite: true,
      );
      expect(toggled, 2);

      final item1 = await dao.getMediaById('b_item_1');
      final item2 = await dao.getMediaById('b_item_2');
      final item3 = await dao.getMediaById('b_item_3');

      expect(item1?.isFavorite, isTrue);
      expect(item2?.isFavorite, isTrue);
      expect(item3?.isFavorite, isFalse);
    });

    test('5. batchAddToAlbum assigns media items to target album', () async {
      final album = await dao.getOrCreateAlbum('Vacation');
      await service.batchAddToAlbum(['b_item_1', 'b_item_2'], album.id);

      final item1 = await dao.getMediaById('b_item_1');
      final item2 = await dao.getMediaById('b_item_2');

      expect(item1?.albumId, album.id);
      expect(item2?.albumId, album.id);
    });
  });
}
