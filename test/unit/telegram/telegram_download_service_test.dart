import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/media_dao.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/core/telegram/tdlib_client.dart';
import 'package:telecloud_photos/core/telegram/telegram_download_service.dart';

void main() {
  group('TelegramDownloadService Unit Tests', () {
    late AppDatabase db;
    late MediaDao dao;
    late TdlibClient client;
    late TelegramDownloadService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = MediaDao(db);
      client = TdlibClient();
      service = TelegramDownloadService(client: client, mediaDao: dao);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. DownloadProgress object models download state accurately', () {
      const prog = DownloadProgress(
        progress: 0.5,
        speedMBps: 2.4,
        filename: 'test.jpg',
        bytesDownloaded: 5000,
        totalBytes: 10000,
        isCompleted: false,
      );

      expect(prog.progress, 0.5);
      expect(prog.speedMBps, 2.4);
      expect(prog.filename, 'test.jpg');
      expect(prog.bytesDownloaded, 5000);
      expect(prog.totalBytes, 10000);
      expect(prog.isCompleted, isFalse);
      expect(prog.error, isNull);
    });

    test('2. downloadMediaItem yields error when item has no telegramFileId',
        () async {
      final now = DateTime.now();
      final item = MediaItem(
        localId: 'local_no_tg',
        filename: 'no_tg.jpg',
        capturedAt: now,
        uploadStatus: UploadStatus.pending,
        mimeType: 'image/jpeg',
        isFavorite: false,
        isTrashed: false,
      );

      final stream = service.downloadMediaItem(item);
      final first = await stream.first;

      expect(first.progress, 0.0);
      expect(first.error, contains('No Telegram File ID found'));
    });

    test(
        '3. downloadMediaItem yields error when telegramFileId is invalid integer',
        () async {
      final now = DateTime.now();
      final item = MediaItem(
        localId: 'local_bad_tg',
        filename: 'bad_tg.jpg',
        capturedAt: now,
        uploadStatus: UploadStatus.done,
        telegramFileId: 'invalid_non_int_id',
        mimeType: 'image/jpeg',
        isFavorite: false,
        isTrashed: false,
      );

      final stream = service.downloadMediaItem(item);
      final first = await stream.first;

      expect(first.progress, 0.0);
      expect(first.error, contains('Invalid Telegram File ID'));
    });
  });
}
