import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/google/google_photos_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Photos Models & Client Tests', () {
    test(
      '1. GooglePhotosMediaItem parses creationTime and dimensions from JSON correctly',
      () {
        final json = {
          'id': 'test_gp_id_101',
          'filename': 'IMG_20230815_153000.JPG',
          'description': 'Family vacation in Hawaii',
          'baseUrl': 'https://lh3.googleusercontent.com/lr/test',
          'mimeType': 'image/jpeg',
          'mediaMetadata': {
            'creationTime': '2023-08-15T15:30:00Z',
            'width': '4032',
            'height': '3024',
          },
        };

        final item = GooglePhotosMediaItem.fromJson(
          json,
          albumId: 'album_hawaii',
          albumTitle: 'Hawaii Trip',
        );

        expect(item.id, 'test_gp_id_101');
        expect(item.filename, 'IMG_20230815_153000.JPG');
        expect(item.description, 'Family vacation in Hawaii');
        expect(item.baseUrl, 'https://lh3.googleusercontent.com/lr/test');
        expect(item.mimeType, 'image/jpeg');
        expect(item.creationTime.year, 2023);
        expect(item.creationTime.month, 8);
        expect(item.creationTime.day, 15);
        expect(item.width, 4032);
        expect(item.height, 3024);
        expect(item.albumId, 'album_hawaii');
        expect(item.albumTitle, 'Hawaii Trip');
        expect(item.isVideo, isFalse);
      },
    );

    test('2. GooglePhotosMediaItem identifies video mimeTypes properly', () {
      final json = {
        'id': 'test_video_202',
        'filename': 'VID_20231225.mp4',
        'baseUrl': 'https://lh3.googleusercontent.com/lr/video',
        'mimeType': 'video/mp4',
        'mediaMetadata': {'creationTime': '2023-12-25T18:00:00Z'},
      };

      final item = GooglePhotosMediaItem.fromJson(json);
      expect(item.isVideo, isTrue);
      expect(item.mimeType, 'video/mp4');
    });

    test('3. GooglePhotosAlbum parses title and mediaItemsCount from JSON', () {
      final json = {
        'id': 'album_303',
        'title': 'Summer 2023 Roadtrip',
        'mediaItemsCount': '142',
        'coverPhotoBaseUrl': 'https://lh3.googleusercontent.com/lr/cover',
      };

      final album = GooglePhotosAlbum.fromJson(json);
      expect(album.id, 'album_303');
      expect(album.title, 'Summer 2023 Roadtrip');
      expect(album.itemCount, 142);
      expect(
        album.coverPhotoBaseUrl,
        'https://lh3.googleusercontent.com/lr/cover',
      );
    });

    test('4. Leaf folder parsing correctly extracts folder names', () {
      String parseLeaf(String path) {
        if (path.startsWith('Google Photos')) return 'Google Photos';
        if (path.startsWith('Telegram Cloud')) return 'Telegram Cloud';
        final parts = path.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (parts.isEmpty) return 'Camera';
        return parts.last;
      }

      expect(parseLeaf('/storage/emulated/0/DCIM/Camera'), 'Camera');
      expect(parseLeaf('/storage/emulated/0/Pictures/Screenshots'), 'Screenshots');
      expect(parseLeaf('/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images'), 'WhatsApp Images');
      expect(parseLeaf('/storage/emulated/0/Download'), 'Download');
      expect(parseLeaf('Google Photos (Cloud Sync)'), 'Google Photos');
      expect(parseLeaf('Telegram Cloud (Remote)'), 'Telegram Cloud');
    });
  });
}
