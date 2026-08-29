import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/media_dao.dart';
import 'package:telecloud_photos/core/takeout/takeout_parser_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late MediaDao dao;
  late TakeoutParserService parserService;
  late Directory tempTestDir;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = MediaDao(db);
    parserService = TakeoutParserService(mediaDao: dao);
    tempTestDir = await Directory.systemTemp.createTemp('takeout_test_');
  });

  tearDown(() async {
    parserService.dispose();
    await db.close();
    if (tempTestDir.existsSync()) {
      tempTestDir.deleteSync(recursive: true);
    }
  });

  group('TakeoutMetadata — JSON Sidecar Parser', () {
    test('1. Parses Google Photos photoTakenTime and geoData correctly', () {
      final json = {
        'title': 'IMG_20220501_120000.jpg',
        'description': 'Family vacation at the beach',
        'photoTakenTime': {
          'timestamp': '1651406400', // 2022-05-01 12:00:00 UTC
          'formatted': 'May 1, 2022, 12:00:00 PM UTC',
        },
        'geoData': {
          'latitude': 37.7749,
          'longitude': -122.4194,
          'altitude': 15.5,
        },
      };

      final meta = TakeoutMetadata.fromJson(
        json,
        'fallback.jpg',
        DateTime.now(),
      );

      expect(meta.title, 'IMG_20220501_120000.jpg');
      expect(meta.description, 'Family vacation at the beach');
      expect(meta.capturedAt.millisecondsSinceEpoch, 1651406400000);
      expect(meta.latitude, 37.7749);
      expect(meta.longitude, -122.4194);
      expect(meta.altitude, 15.5);
    });

    test('2. Handles fallback creationTime and absent geoData gracefully', () {
      final json = {
        'title': 'SCREENSHOT.png',
        'creationTime': {
          'timestamp': '1600000000',
        },
      };

      final meta = TakeoutMetadata.fromJson(
        json,
        'SCREENSHOT.png',
        DateTime.now(),
      );

      expect(meta.title, 'SCREENSHOT.png');
      expect(meta.capturedAt.millisecondsSinceEpoch, 1600000000000);
      expect(meta.latitude, isNull);
      expect(meta.longitude, isNull);
    });
  });

  group('TakeoutParserService — Zip Archive Streaming Import', () {
    test('1. analyzeZipArchive accurately reports photo and metadata counts', () async {
      final zipPath = p.join(tempTestDir.path, 'sample_takeout.zip');

      // Create a test zip with 2 photos and 2 sidecar JSONs
      final archive = Archive();
      final photo1Bytes = utf8.encode('fake_photo_1_bytes');
      final photo2Bytes = utf8.encode('fake_photo_2_bytes');
      final json1Bytes = utf8.encode(jsonEncode({
        'title': 'photo1.jpg',
        'photoTakenTime': {'timestamp': '1610000000'},
      }));
      final json2Bytes = utf8.encode(jsonEncode({
        'title': 'photo2.jpg',
        'photoTakenTime': {'timestamp': '1620000000'},
      }));

      archive.addFile(ArchiveFile('Google Photos/2021/photo1.jpg', photo1Bytes.length, photo1Bytes));
      archive.addFile(ArchiveFile('Google Photos/2021/photo1.jpg.json', json1Bytes.length, json1Bytes));
      archive.addFile(ArchiveFile('Google Photos/2021/photo2.png', photo2Bytes.length, photo2Bytes));
      archive.addFile(ArchiveFile('Google Photos/2021/photo2.png.json', json2Bytes.length, json2Bytes));

      final zipData = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipData!);

      final summary = await parserService.analyzeZipArchive(zipPath);

      expect(summary.totalFiles, 4);
      expect(summary.photoCount, 2);
      expect(summary.metadataJsonCount, 2);
      expect(summary.videoCount, 0);
      expect(summary.totalBytes > 0, isTrue);
    });

    test('2. importFromZip extracts photos, applies sidecars, and inserts into DB', () async {
      final zipPath = p.join(tempTestDir.path, 'import_takeout.zip');

      final archive = Archive();
      final photoBytes = utf8.encode('test_photo_data');
      final sidecarJson = utf8.encode(jsonEncode({
        'title': 'sunset.jpg',
        'photoTakenTime': {'timestamp': '1650000000'},
        'geoData': {'latitude': 34.0522, 'longitude': -118.2437},
      }));

      archive.addFile(ArchiveFile('Takeout/Google Photos/sunset.jpg', photoBytes.length, photoBytes));
      archive.addFile(ArchiveFile('Takeout/Google Photos/sunset.jpg.json', sidecarJson.length, sidecarJson));

      final zipData = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipData!);

      final count = await parserService.importFromZip(
        zipFilePath: zipPath,
        uploadToTelegram: false,
      );

      expect(count, 1);

      final media = await dao.watchGooglePhotosMedia().first;
      expect(media.length, 1);
      expect(media.first.filename, 'sunset.jpg');
      expect(media.first.capturedAt.millisecondsSinceEpoch, 1650000000000);
      expect(media.first.latitude, 34.0522);
      expect(media.first.longitude, -118.2437);
    });
  });
}
