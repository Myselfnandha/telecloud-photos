import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as p;

class ThumbnailGenerator {
  static Future<String?> generateThumbnail(AssetEntity asset) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final thumbsDir = Directory(p.join(docDir.path, 'thumbnails'));
      if (!await thumbsDir.exists()) {
        await thumbsDir.create(recursive: true);
      }

      final safeId = asset.id.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final thumbFile = File(p.join(thumbsDir.path, '$safeId.jpg'));
      if (await thumbFile.exists()) {
        return thumbFile.path;
      }

      final bytes = await asset.thumbnailDataWithSize(
        const ThumbnailSize(256, 256),
      );
      if (bytes != null) {
        await thumbFile.writeAsBytes(bytes);
        return thumbFile.path;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Thumbnail error] $e');
    }
    return null;
  }
}
