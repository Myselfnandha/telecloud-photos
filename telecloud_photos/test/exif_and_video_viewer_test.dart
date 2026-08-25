import 'dart:io';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/media_dao.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/core/media/exif_parser_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MediaDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = MediaDao(db);
    ExifParserService.clearCache();
  });

  tearDown(() async {
    await db.close();
  });

  group('ExifParserService Binary Parsing Tests', () {
    test('1. Handles non-JPEG or empty files gracefully without throwing',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('exif_test');
      final emptyFile = File('${tempDir.path}/empty.png');
      await emptyFile
          .writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

      final metadata = await ExifParserService.parseFile(emptyFile);
      expect(metadata, isNotNull);
      expect(metadata.cameraModel, isNull);
      expect(metadata.formattedCameraTitle, 'Unknown Camera');
      expect(metadata.hasCameraSpecs, isFalse);

      await tempDir.delete(recursive: true);
    });

    test('2. Formats camera title, resolution, and file size correctly', () {
      const meta1 = ExifMetadata(
        cameraMake: 'Apple',
        cameraModel: 'iPhone 15 Pro',
        width: 4032,
        height: 3024,
        megapixels: 12.19,
        fileSizeBytes: 3500000,
      );

      expect(meta1.formattedCameraTitle, 'Apple iPhone 15 Pro');
      expect(meta1.formattedResolution, '12.2 MP • 4032 × 3024');
      expect(meta1.formattedFileSize, '3.34 MB');
      expect(meta1.hasCameraSpecs, isTrue);

      const meta2 = ExifMetadata(
        cameraMake: 'Sony',
        cameraModel: 'ILCE-7M4',
        fNumber: 'f/2.8',
        exposureTime: '1/500s',
        iso: 'ISO 100',
      );

      expect(meta2.formattedCameraTitle, 'Sony ILCE-7M4');
      expect(meta2.hasCameraSpecs, isTrue);
    });

    test(
        '3. Parses synthesized JPEG EXIF APP1 header with camera and exposure tags',
        () async {
      // Build a minimal valid JPEG with APP1 EXIF segment (Little Endian 'II')
      final buffer = BytesBuilder();

      // JPEG SOI marker
      buffer.add([0xFF, 0xD8]);

      // APP1 Marker
      final app1Data = BytesBuilder();
      // 'Exif\0\0'
      app1Data.add([0x45, 0x78, 0x69, 0x66, 0x00, 0x00]);

      // TIFF Header: 'II' (0x49, 0x49), 42 (0x2A, 0x00), offset to IFD0 = 8 (0x08, 0x00, 0x00, 0x00)
      final tiffData = BytesBuilder();
      tiffData.add([0x49, 0x49, 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00]);

      // IFD0: 2 entries
      // Entry 1: Make (0x010F), ASCII (2), count 6, offset 38
      // Entry 2: Model (0x0110), ASCII (2), count 7, offset 44
      tiffData.add([0x02, 0x00]); // 2 entries
      // Make entry
      tiffData.add([
        0x0F,
        0x01,
        0x02,
        0x00,
        0x06,
        0x00,
        0x00,
        0x00,
        0x26,
        0x00,
        0x00,
        0x00
      ]);
      // Model entry
      tiffData.add([
        0x10,
        0x01,
        0x02,
        0x00,
        0x07,
        0x00,
        0x00,
        0x00,
        0x2C,
        0x00,
        0x00,
        0x00
      ]);
      // Next IFD offset = 0
      tiffData.add([0x00, 0x00, 0x00, 0x00]);

      // String data at offset 38 (0x26): "Apple\0"
      tiffData.add([0x41, 0x70, 0x70, 0x6C, 0x65, 0x00]);
      // String data at offset 44 (0x2C): "Pixel7\0"
      tiffData.add([0x50, 0x69, 0x78, 0x65, 0x6C, 0x37, 0x00]);

      final tiffBytes = tiffData.toBytes();
      app1Data.add(tiffBytes);

      final app1Bytes = app1Data.toBytes();
      final app1Length = app1Bytes.length + 2;
      buffer.add([0xFF, 0xE1, (app1Length >> 8) & 0xFF, app1Length & 0xFF]);
      buffer.add(app1Bytes);

      // JPEG EOI marker
      buffer.add([0xFF, 0xD9]);

      final tempDir = await Directory.systemTemp.createTemp('exif_test_header');
      final jpegFile = File('${tempDir.path}/photo.jpg');
      await jpegFile.writeAsBytes(buffer.toBytes());

      final meta = await ExifParserService.parseFile(jpegFile);
      expect(meta.cameraMake, 'Apple');
      expect(meta.cameraModel, 'Pixel7');
      expect(meta.formattedCameraTitle, 'Apple Pixel7');

      // Verify cached call returns same object instantly
      final metaCached = await ExifParserService.parseFile(jpegFile);
      expect(identical(meta, metaCached), isTrue);

      await tempDir.delete(recursive: true);
    });
  });

  group('MediaDao Timestamp and GPS Updates Tests', () {
    test('1. updateMediaCapturedAt updates timestamp in SQLite', () async {
      final initialDate = DateTime(2025, 5, 10, 14, 30);
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'exif_media_1',
          filename: 'Sunset.jpg',
          capturedAt: initialDate,
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
        ),
      ]);

      final itemBefore = await dao.getMediaById('exif_media_1');
      expect(itemBefore?.capturedAt, initialDate);

      final newDate = DateTime(2026, 8, 24, 19, 00);
      await dao.updateMediaCapturedAt('exif_media_1', newDate);

      final itemAfter = await dao.getMediaById('exif_media_1');
      expect(itemAfter?.capturedAt, newDate);
    });

    test('2. updateMediaGpsCoordinates updates latitude and longitude',
        () async {
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'exif_media_2',
          filename: 'EiffelTower.jpg',
          capturedAt: DateTime.now(),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
        ),
      ]);

      await dao.updateMediaGpsCoordinates('exif_media_2', 48.8584, 2.2945);

      final item = await dao.getMediaById('exif_media_2');
      expect(item?.latitude, 48.8584);
      expect(item?.longitude, 2.2945);
    });
  });
}
