import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/media_dao.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/core/backup/upload_queue.dart';
import 'package:telecloud_photos/core/backup/backup_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MediaDao dao;
  late UploadQueue queue;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    // Mock flutter_foreground_task method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_foreground_task/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'isRunningService') {
          return false;
        }
        return true;
      },
    );

    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = MediaDao(db);
    queue = UploadQueue(mediaDao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('UploadQueue — Execution & Retry Functions', () {
    test(
      '1. processQueue uploads pending items sequentially and updates status to done',
      () async {
        final now = DateTime.now();
        final items = [
          MediaItemsCompanion.insert(
            localId: 'queue_1',
            filename: 'Q1.jpg',
            capturedAt: now,
            uploadStatus: UploadStatus.pending,
            mimeType: 'image/jpeg',
          ),
          MediaItemsCompanion.insert(
            localId: 'queue_2',
            filename: 'Q2.jpg',
            capturedAt: now.subtract(const Duration(minutes: 1)),
            uploadStatus: UploadStatus.pending,
            mimeType: 'image/jpeg',
          ),
        ];

        await dao.insertOrIgnoreBatch(items);

        final uploaded = <String>[];
        await queue.processQueue(
          uploadItem: (item, [index, total]) async {
            uploaded.add(item.localId);
            return true;
          },
        );

        expect(uploaded, ['queue_2', 'queue_1']);

        final item1 = await dao.getMediaById('queue_1');
        final item2 = await dao.getMediaById('queue_2');
        expect(item1?.uploadStatus, UploadStatus.done);
        expect(item2?.uploadStatus, UploadStatus.done);
        expect(queue.isProcessing, isFalse);
      },
    );

    test(
      '2. processQueue sets status to failed when upload attempts fail',
      () async {
        await dao.insertOrIgnoreBatch([
          MediaItemsCompanion.insert(
            localId: 'fail_item',
            filename: 'FAIL.jpg',
            capturedAt: DateTime.now(),
            uploadStatus: UploadStatus.pending,
            mimeType: 'image/jpeg',
          ),
        ]);

        int attempts = 0;
        await queue.processQueue(
          uploadItem: (item, [index, total]) async {
            attempts++;
            return false; // Simulation of network error
          },
        );

        expect(attempts, 3);
        final item = await dao.getMediaById('fail_item');
        expect(item?.uploadStatus, UploadStatus.failed);
      },
    );

    test('3. stop() stops processing queue gracefully', () {
      queue.stop();
      expect(queue.isProcessing, isFalse);
    });
  });

  group('BackupManager — Power & State Machine Functions', () {
    test('1. onPowerConnected and onPowerDisconnected update state', () async {
      final manager = BackupManager();
      expect(manager.currentState, BackupState.idle);

      await manager.onPowerConnected();
      expect(manager.currentState, BackupState.waitingToUpload);

      // In background on battery -> enters waitingForReconnect
      manager.onAppLifecycleChanged(false);
      await manager.onPowerDisconnected();
      expect(manager.currentState, BackupState.waitingForReconnect);

      await manager.stopService();
      expect(manager.currentState, BackupState.idle);
    });

    test('2. onAppLifecycleChanged updates foreground tracking', () {
      final manager = BackupManager();
      manager.onAppLifecycleChanged(false);
      expect(manager.isInForeground, isFalse);

      manager.onAppLifecycleChanged(true);
      expect(manager.isInForeground, isTrue);
    });

    test(
      '3. onUploadsFinished resets to idle when finished uploading',
      () async {
        final manager = BackupManager();
        await manager.onUploadsFinished();
        expect(manager.currentState, BackupState.idle);
      },
    );
  });

  group('MediaDao — Queue Isolation & Manual Queueing Functions', () {
    test(
      '1. watchActiveUploadQueue only returns pending, uploading, and failed items',
      () async {
        final now = DateTime.now();
        await dao.insertOrIgnoreBatch([
          MediaItemsCompanion.insert(
            localId: 'item_done',
            filename: 'done.jpg',
            capturedAt: now,
            uploadStatus: UploadStatus.done,
            mimeType: 'image/jpeg',
          ),
          MediaItemsCompanion.insert(
            localId: 'item_pending',
            filename: 'pending.jpg',
            capturedAt: now,
            uploadStatus: UploadStatus.pending,
            mimeType: 'image/jpeg',
          ),
          MediaItemsCompanion.insert(
            localId: 'item_uploading',
            filename: 'uploading.jpg',
            capturedAt: now,
            uploadStatus: UploadStatus.uploading,
            mimeType: 'image/jpeg',
          ),
          MediaItemsCompanion.insert(
            localId: 'item_failed',
            filename: 'failed.jpg',
            capturedAt: now,
            uploadStatus: UploadStatus.failed,
            mimeType: 'image/jpeg',
          ),
        ]);

        final activeQueue = await dao.watchActiveUploadQueue().first;
        expect(activeQueue.length, 3);
        final ids = activeQueue.map((i) => i.localId).toSet();
        expect(ids.contains('item_done'), isFalse);
        expect(ids.contains('item_pending'), isTrue);
        expect(ids.contains('item_uploading'), isTrue);
        expect(ids.contains('item_failed'), isTrue);
      },
    );

    test('2. queueLocalIdsForUpload updates target items to pending', () async {
      final now = DateTime.now();
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'manual_1',
          filename: 'm1.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.done,
          mimeType: 'image/jpeg',
        ),
        MediaItemsCompanion.insert(
          localId: 'manual_2',
          filename: 'm2.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.done,
          mimeType: 'image/jpeg',
        ),
      ]);

      final count = await dao.queueLocalIdsForUpload(['manual_1', 'manual_2']);
      expect(count, 2);

      final item1 = await dao.getMediaById('manual_1');
      final item2 = await dao.getMediaById('manual_2');
      expect(item1?.uploadStatus, UploadStatus.pending);
      expect(item2?.uploadStatus, UploadStatus.pending);
    });

    test('3. queueAlbumForUpload queues all unbacked items in album', () async {
      final album = await dao.getOrCreateAlbum('Holiday');
      final now = DateTime.now();

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'album_item_1',
          filename: 'a1.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.done,
          albumId: Value(album.id),
          mimeType: 'image/jpeg',
        ),
      ]);

      final queued = await dao.queueAlbumForUpload(album.id);
      expect(queued, 1);

      final item = await dao.getMediaById('album_item_1');
      expect(item?.uploadStatus, UploadStatus.pending);
    });
  });
}
