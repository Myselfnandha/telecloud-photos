import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/media_dao.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/core/storage/storage_cleaner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late MediaDao dao;
  late StorageCleanerService cleanerService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = MediaDao(db);
    cleanerService = StorageCleanerService(mediaDao: dao);
  });

  tearDown(() async {
    cleanerService.dispose();
    await db.close();
  });

  group('MediaDao — Free Up Space Queries', () {
    test('1. getFreeUpSpaceEligibleItems filters accurately', () async {
      final now = DateTime.now();

      await dao.insertOrIgnoreBatch([
        // Eligible: local device item, done, has telegramMsgId, not trashed
        MediaItemsCompanion.insert(
          localId: 'local_photo_1',
          filename: 'DCIM_001.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(101),
          fileSizeBytes: const Value(2500000), // 2.5 MB
        ),
        // Eligible: local device video, done, has telegramFileId, not trashed
        MediaItemsCompanion.insert(
          localId: 'local_video_1',
          filename: 'VID_001.mp4',
          capturedAt: now,
          mimeType: 'video/mp4',
          uploadStatus: UploadStatus.done,
          telegramFileId: const Value('file_999'),
          fileSizeBytes: const Value(50000000), // 50 MB
        ),
        // Ineligible: pending upload
        MediaItemsCompanion.insert(
          localId: 'local_pending',
          filename: 'PENDING.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.pending,
          fileSizeBytes: const Value(1000000),
        ),
        // Ineligible: failed upload
        MediaItemsCompanion.insert(
          localId: 'local_failed',
          filename: 'FAILED.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.failed,
          fileSizeBytes: const Value(1000000),
        ),
        // Ineligible: trashed
        MediaItemsCompanion.insert(
          localId: 'local_trashed',
          filename: 'TRASHED.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(102),
          isTrashed: const Value(true),
          fileSizeBytes: const Value(1000000),
        ),
        // Ineligible: already cloud-only (starts with tg_)
        MediaItemsCompanion.insert(
          localId: 'tg_103',
          filename: 'CLOUD_ONLY.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(103),
          fileSizeBytes: const Value(1000000),
        ),
        // Ineligible: Google Photos cloud item (starts with gp_)
        MediaItemsCompanion.insert(
          localId: 'gp_104',
          filename: 'GP_PHOTO.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          fileSizeBytes: const Value(1000000),
        ),
      ]);

      final eligible = await dao.getFreeUpSpaceEligibleItems();
      expect(eligible.length, 2);
      expect(eligible.map((e) => e.localId), containsAll(['local_photo_1', 'local_video_1']));
    });

    test('2. watchReclaimableStorageBytes streams correct sum', () async {
      final now = DateTime.now();

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'item_a',
          filename: 'A.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(201),
          fileSizeBytes: const Value(3000000), // 3 MB
        ),
        MediaItemsCompanion.insert(
          localId: 'item_b',
          filename: 'B.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(202),
          fileSizeBytes: const Value(7000000), // 7 MB
        ),
      ]);

      final initialBytes = await dao.watchReclaimableStorageBytes().first;
      expect(initialBytes, 10000000); // 10 MB total
    });
  });

  group('StorageCleanerService — Execution & Telemetry', () {
    test('1. getStorageSummary returns photo/video counts and bytes', () async {
      final now = DateTime.now();

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'photo_1',
          filename: 'IMG_1.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(301),
          fileSizeBytes: const Value(2000000),
        ),
        MediaItemsCompanion.insert(
          localId: 'photo_2',
          filename: 'IMG_2.png',
          capturedAt: now,
          mimeType: 'image/png',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(302),
          fileSizeBytes: const Value(3000000),
        ),
        MediaItemsCompanion.insert(
          localId: 'video_1',
          filename: 'CLIP_1.mp4',
          capturedAt: now,
          mimeType: 'video/mp4',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(303),
          fileSizeBytes: const Value(25000000),
        ),
      ]);

      final summary = await cleanerService.getStorageSummary();
      expect(summary.totalItems, 3);
      expect(summary.photoCount, 2);
      expect(summary.videoCount, 1);
      expect(summary.totalBytes, 30000000);
      expect(summary.hasReclaimableSpace, isTrue);
    });

    test('2. freeUpSpace deletes local files and updates database', () async {
      final now = DateTime.now();

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'clean_1',
          filename: 'PHOTO_1.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(401),
          fileSizeBytes: const Value(5000000),
        ),
        MediaItemsCompanion.insert(
          localId: 'clean_2',
          filename: 'PHOTO_2.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(402),
          fileSizeBytes: const Value(7000000),
        ),
      ]);

      final progressUpdates = <StorageCleanProgress>[];
      final sub = cleanerService.progressStream.listen(progressUpdates.add);

      final result = await cleanerService.freeUpSpace(
        customDeleter: (ids) async {
          // Simulate successful Android MediaStore deletion of all IDs
          return ids;
        },
      );

      await Future.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(result.success, isTrue);
      expect(result.cleanedItemCount, 2);
      expect(result.reclaimedBytes, 12000000);
      expect(progressUpdates.isNotEmpty, isTrue);
      expect(cleanerService.currentProgress.stage, CleanStage.completed);
      expect(progressUpdates.any((p) => p.stage == CleanStage.completed), isTrue);
    });

    test('3. freeUpSpace handles user cancellation gracefully', () async {
      final now = DateTime.now();

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'cancel_1',
          filename: 'PHOTO_CANCEL.jpg',
          capturedAt: now,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(501),
          fileSizeBytes: const Value(4000000),
        ),
      ]);

      final result = await cleanerService.freeUpSpace(
        customDeleter: (ids) async {
          // User tapped "Deny" or "Cancel" on the Android MediaStore dialog
          return [];
        },
      );

      expect(result.success, isFalse);
      expect(result.userCancelled, isTrue);
      expect(result.cleanedItemCount, 0);
    });
  });
}
