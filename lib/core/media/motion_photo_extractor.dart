import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/telecloud_logger.dart';

class MotionPhotoExtractor {
  static final MotionPhotoExtractor _instance =
      MotionPhotoExtractor._internal();
  factory MotionPhotoExtractor() => _instance;
  MotionPhotoExtractor._internal();

  final Map<String, String> _extractedCache = {};

  /// Checks if a file is a Motion Photo and extracts its embedded micro-video track to a temporary MP4 file.
  /// Returns the file path of the extracted MP4, or null if the photo is not a motion photo.
  Future<String?> extractMotionVideo(String imagePath) async {
    if (_extractedCache.containsKey(imagePath)) {
      final cachedPath = _extractedCache[imagePath]!;
      if (await File(cachedPath).exists()) {
        return cachedPath;
      }
    }

    final file = File(imagePath);
    if (!await file.exists()) return null;

    try {
      final fileLength = await file.length();
      // Motion photos typically have an embedded MP4 of at least 100KB and at most ~30MB
      if (fileLength < 100 * 1024) return null;

      final raf = await file.open(mode: FileMode.read);

      // Step 1: Scan for standard MP4 ftyp signatures (ftypmp42, ftypisom, ftypqt, ftypMSNV)
      // Check last 25MB of file in 64KB blocks
      final searchWindow =
          fileLength > 25 * 1024 * 1024 ? 25 * 1024 * 1024 : fileLength;
      final startSearchPos = fileLength - searchWindow;

      await raf.setPosition(startSearchPos);
      final buffer = await raf.read(searchWindow);
      await raf.close();

      int mp4Offset = -1;

      // Look for 'ftyp' atom header (bytes: 0x66, 0x74, 0x79, 0x70) preceded by 4 length bytes
      for (int i = buffer.length - 8; i >= 0; i--) {
        if (buffer[i] == 0x66 && // 'f'
            buffer[i + 1] == 0x74 && // 't'
            buffer[i + 2] == 0x79 && // 'y'
            buffer[i + 3] == 0x70) {
          // 'p'
          if (i >= 4) {
            mp4Offset = startSearchPos + (i - 4);
            break;
          }
        }
      }

      if (mp4Offset == -1 || mp4Offset >= fileLength - 1024) {
        return null;
      }

      // Step 2: Extract MP4 slice to cache
      final tempDir = await getTemporaryDirectory();
      final motionDir = Directory('${tempDir.path}/motion_photos');
      if (!await motionDir.exists()) {
        await motionDir.create(recursive: true);
      }

      final fileName = file.uri.pathSegments.last;
      final outputVideoPath =
          '${motionDir.path}/motion_${fileLength}_$fileName.mp4';
      final outputFile = File(outputVideoPath);

      if (await outputFile.exists() && await outputFile.length() > 0) {
        _extractedCache[imagePath] = outputVideoPath;
        return outputVideoPath;
      }

      final readRaf = await file.open(mode: FileMode.read);
      await readRaf.setPosition(mp4Offset);

      final videoBytes = await readRaf.read(fileLength - mp4Offset);
      await readRaf.close();

      await outputFile.writeAsBytes(videoBytes, flush: true);
      TeleCloudLogger.log(
        'Media',
        'Extracted Motion Photo video track (${videoBytes.length} bytes) to $outputVideoPath',
      );

      _extractedCache[imagePath] = outputVideoPath;
      return outputVideoPath;
    } catch (e) {
      TeleCloudLogger.log('Media', 'Motion photo extraction error: $e');
      return null;
    }
  }
}
