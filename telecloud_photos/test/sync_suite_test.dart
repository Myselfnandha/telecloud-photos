import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecloud_photos/core/constants/app_constants.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/media_dao.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/core/backup/media_deduplicator.dart';
import 'package:telecloud_photos/core/backup/sync_policy_guard.dart';
import 'package:telecloud_photos/core/backup/folder_sync_manager.dart';
import 'package:telecloud_photos/core/backup/upload_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MediaDao dao;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = MediaDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MediaDeduplicator Tests', () {
    test(
        '1. Computes SHA-256 and skips re-upload when duplicate exists in Telegram Cloud',
        () async {
      final deduplicator = MediaDeduplicator(mediaDao: dao);

      // Create a temporary file
      final tempDir = await Directory.systemTemp.createTemp('dedup_test');
      final testFile = File('${tempDir.path}/test_photo.jpg');
      await testFile.writeAsString('Unique Photo Byte Content For SHA-256');

      // Compute hash
      final computedHash = await deduplicator.computeFileSha256(testFile);
      expect(computedHash.isNotEmpty, isTrue);

      // 1. Insert an existing backed-up photo with matching hash
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'cloud_orig_1',
          filename: 'Original.jpg',
          capturedAt: DateTime(2025, 1, 1),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          sha256Hash: Value(computedHash),
          telegramMsgId: const Value(7788),
          telegramFileId: const Value('tg_file_hash_123'),
        ),
      ]);

      // 2. Insert a new local pending item with same content
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'local_new_2',
          filename: 'Duplicate_Copy.jpg',
          capturedAt: DateTime(2026, 2, 2),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.pending,
        ),
      ]);

      final localItem = await dao.getMediaById('local_new_2');
      expect(localItem, isNotNull);

      // 3. Run checkAndDeduplicate
      final wasDeduplicated = await deduplicator.checkAndDeduplicate(
        localItem: localItem!,
        file: testFile,
      );

      expect(wasDeduplicated, isTrue);

      // 4. Verify localItem in SQLite is now done with copied cloud fileId
      final updatedItem = await dao.getMediaById('local_new_2');
      expect(updatedItem?.uploadStatus, UploadStatus.done);
      expect(updatedItem?.telegramMsgId, 7788);
      expect(updatedItem?.telegramFileId, 'tg_file_hash_123');
      expect(updatedItem?.sha256Hash, computedHash);

      await tempDir.delete(recursive: true);
    });

    test('2. Returns false when file is unique and not in cloud', () async {
      final deduplicator = MediaDeduplicator(mediaDao: dao);

      final tempDir = await Directory.systemTemp.createTemp('dedup_test_2');
      final uniqueFile = File('${tempDir.path}/unique.jpg');
      await uniqueFile.writeAsString('Unique Unique Unique');

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'unique_1',
          filename: 'Unique.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.pending,
        ),
      ]);

      final item = await dao.getMediaById('unique_1');
      final wasDeduplicated = await deduplicator.checkAndDeduplicate(
        localItem: item!,
        file: uniqueFile,
      );

      expect(wasDeduplicated, isFalse);
      final itemAfter = await dao.getMediaById('unique_1');
      expect(itemAfter?.uploadStatus, UploadStatus.pending);
      expect(itemAfter?.sha256Hash, isNotNull);

      await tempDir.delete(recursive: true);
    });
  });

  group('SyncPolicyGuard Tests', () {
    test('1. Allows sync on Wi-Fi connection', () async {
      final guard = SyncPolicyGuard();

      final result = await guard.evaluatePolicy(
        isChargingOverride: true,
        batteryLevelOverride: 80,
        connectivityOverride: [ConnectivityResult.wifi],
      );

      expect(result.canSync, isTrue);
      expect(result.reason, SyncBlockedReason.none);
    });

    test(
        '2. Blocks sync when cellular backup is disabled and on mobile network',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyWifiOnly, true);
      await prefs.setBool(AppConstants.keyAllowMobileData, false);

      final guard = SyncPolicyGuard();

      final result = await guard.evaluatePolicy(
        isChargingOverride: true,
        batteryLevelOverride: 80,
        connectivityOverride: [ConnectivityResult.mobile],
      );

      expect(result.canSync, isFalse);
      expect(result.reason, SyncBlockedReason.waitingForWifi);
    });

    test('3. Enforces daily cellular data cap on mobile network', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyWifiOnly, false);
      await prefs.setBool(AppConstants.keyAllowMobileData, true);
      await prefs.setInt(
          AppConstants.keyDailyCellularDataLimitMb, 50); // 50MB cap

      // Simulate 55MB already used today
      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setString(AppConstants.keyLastDataUsageResetDay, todayKey);
      await prefs.setInt(
          AppConstants.keyUsedCellularDataTodayBytes, 55 * 1024 * 1024);

      final guard = SyncPolicyGuard();

      final result = await guard.evaluatePolicy(
        isChargingOverride: false,
        batteryLevelOverride: 90,
        connectivityOverride: [ConnectivityResult.mobile],
      );

      expect(result.canSync, isFalse);
      expect(result.reason, SyncBlockedReason.cellularDataCapReached);
    });

    test('4. Blocks sync when battery is below threshold and not charging',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyChargingOnly, false);
      await prefs.setInt(AppConstants.keyBatteryThresholdPercent, 30);

      final guard = SyncPolicyGuard();

      final result = await guard.evaluatePolicy(
        isChargingOverride: false,
        batteryLevelOverride: 20, // 20% < 30% threshold
        connectivityOverride: [ConnectivityResult.wifi],
      );

      expect(result.canSync, isFalse);
      expect(result.reason, SyncBlockedReason.batteryTooLow);
    });

    test('5. Blocks sync when chargingOnly is true and device is unplugged',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyChargingOnly, true);

      final guard = SyncPolicyGuard();

      final result = await guard.evaluatePolicy(
        isChargingOverride: false, // Unplugged
        batteryLevelOverride: 100,
        connectivityOverride: [ConnectivityResult.wifi],
      );

      expect(result.canSync, isFalse);
      expect(result.reason, SyncBlockedReason.waitingForCharger);
    });
  });

  group('FolderSyncManager Tests', () {
    test('1. Saves per-folder auto-backup preferences and queries SQLite',
        () async {
      final manager = FolderSyncManager(mediaDao: dao);

      await dao.upsertFolderSyncSetting(
        const FolderSyncSettingsCompanion(
          folderId: Value('bucket_camera'),
          folderName: Value('Camera'),
          folderPath: Value('/storage/emulated/0/DCIM/Camera'),
          isAutoBackupEnabled: Value(true),
          mediaCount: Value(120),
        ),
      );

      await dao.upsertFolderSyncSetting(
        const FolderSyncSettingsCompanion(
          folderId: Value('bucket_screenshots'),
          folderName: Value('Screenshots'),
          folderPath: Value('/storage/emulated/0/Pictures/Screenshots'),
          isAutoBackupEnabled: Value(false),
          mediaCount: Value(45),
        ),
      );

      final allFolders = await dao.getAllFolderSyncSettings();
      expect(allFolders.length, 2);

      // Toggle Screenshots on
      await manager.setFolderBackupEnabled('bucket_screenshots', true);

      final updated = await dao.getFolderSyncSetting('bucket_screenshots');
      expect(updated?.isAutoBackupEnabled, isTrue);
    });

    test(
        '2. queueFolderHistoricalMedia queues all non-uploaded media in that folder',
        () async {
      final manager = FolderSyncManager(mediaDao: dao);

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'wa_1',
          filename: 'WA_001.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          folderName: const Value('WhatsApp Images'),
          uploadStatus: UploadStatus.failed,
        ),
        MediaItemsCompanion.insert(
          localId: 'wa_2',
          filename: 'WA_002.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          folderName: const Value('WhatsApp Images'),
          uploadStatus: UploadStatus.failed,
        ),
        MediaItemsCompanion.insert(
          localId: 'camera_1',
          filename: 'CAM_001.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          folderName: const Value('Camera'),
          uploadStatus: UploadStatus.failed,
        ),
      ]);

      final queued =
          await manager.queueFolderHistoricalMedia('WhatsApp Images');
      expect(queued, 2);

      final waItem1 = await dao.getMediaById('wa_1');
      final camItem = await dao.getMediaById('camera_1');
      expect(waItem1?.uploadStatus, UploadStatus.pending);
      expect(camItem?.uploadStatus, UploadStatus.failed); // Unchanged
    });
  });

  group('UploadQueue Concurrency & Turbo Mode Tests', () {
    test('1. UploadQueue supports Turbo Unlimited mode (concurrency = 0)',
        () async {
      final queue = UploadQueue(mediaDao: dao);
      queue.setConcurrency(0); // Turbo mode

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'turbo_1',
          filename: 'T1.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.pending,
        ),
        MediaItemsCompanion.insert(
          localId: 'turbo_2',
          filename: 'T2.jpg',
          capturedAt: DateTime.now().subtract(const Duration(seconds: 1)),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.pending,
        ),
        MediaItemsCompanion.insert(
          localId: 'turbo_3',
          filename: 'T3.jpg',
          capturedAt: DateTime.now().subtract(const Duration(seconds: 2)),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.pending,
        ),
      ]);

      final uploaded = <String>[];
      await queue.processQueue(
        uploadItem: (item, [index, total]) async {
          uploaded.add(item.localId);
          return true;
        },
      );

      expect(uploaded.length, 3);
      expect(queue.isProcessing, isFalse);

      final item1 = await dao.getMediaById('turbo_1');
      final item2 = await dao.getMediaById('turbo_2');
      final item3 = await dao.getMediaById('turbo_3');
      expect(item1?.uploadStatus, UploadStatus.done);
      expect(item2?.uploadStatus, UploadStatus.done);
      expect(item3?.uploadStatus, UploadStatus.done);
    });
  });
}
