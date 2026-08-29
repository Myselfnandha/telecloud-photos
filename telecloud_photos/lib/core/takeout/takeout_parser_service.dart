import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../database/tables/media_table.dart';
import '../telegram/channel_manager.dart';
import '../telegram/telegram_upload_service.dart';
import '../utils/telecloud_logger.dart';

enum TakeoutImportStage {
  idle,
  analyzing,
  extracting,
  uploading,
  completed,
  failed,
}

class TakeoutMetadata {
  final String title;
  final String description;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final double? altitude;

  const TakeoutMetadata({
    required this.title,
    this.description = '',
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.altitude,
  });

  factory TakeoutMetadata.fromJson(Map<String, dynamic> json, String fallbackFilename, DateTime fallbackDate) {
    String title = json['title'] as String? ?? fallbackFilename;
    String desc = json['description'] as String? ?? '';
    DateTime capturedAt = fallbackDate;

    if (json.containsKey('photoTakenTime')) {
      final timeMap = json['photoTakenTime'];
      if (timeMap is Map) {
        final tsStr = timeMap['timestamp']?.toString();
        if (tsStr != null) {
          final ts = int.tryParse(tsStr);
          if (ts != null && ts > 0) {
            capturedAt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
          }
        }
      }
    } else if (json.containsKey('creationTime')) {
      final timeMap = json['creationTime'];
      if (timeMap is Map) {
        final tsStr = timeMap['timestamp']?.toString();
        if (tsStr != null) {
          final ts = int.tryParse(tsStr);
          if (ts != null && ts > 0) {
            capturedAt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
          }
        }
      }
    }

    double? lat;
    double? lon;
    double? alt;

    if (json.containsKey('geoData')) {
      final geo = json['geoData'];
      if (geo is Map) {
        final l = geo['latitude'];
        final ln = geo['longitude'];
        final a = geo['altitude'];
        if (l is num && l != 0.0) lat = l.toDouble();
        if (ln is num && ln != 0.0) lon = ln.toDouble();
        if (a is num && a != 0.0) alt = a.toDouble();
      }
    }

    return TakeoutMetadata(
      title: title,
      description: desc,
      capturedAt: capturedAt,
      latitude: lat,
      longitude: lon,
      altitude: alt,
    );
  }
}

class TakeoutZipSummary {
  final int totalFiles;
  final int photoCount;
  final int videoCount;
  final int metadataJsonCount;
  final int totalBytes;

  const TakeoutZipSummary({
    this.totalFiles = 0,
    this.photoCount = 0,
    this.videoCount = 0,
    this.metadataJsonCount = 0,
    this.totalBytes = 0,
  });

  String get formattedSize {
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

class TakeoutImportProgress {
  final TakeoutImportStage stage;
  final int totalItems;
  final int processedItems;
  final int importedCount;
  final String currentFilename;
  final String? error;

  const TakeoutImportProgress({
    this.stage = TakeoutImportStage.idle,
    this.totalItems = 0,
    this.processedItems = 0,
    this.importedCount = 0,
    this.currentFilename = '',
    this.error,
  });

  double get progressPercentage =>
      totalItems > 0 ? (processedItems / totalItems).clamp(0.0, 1.0) : 0.0;
}

class TakeoutParserService {
  final MediaDao mediaDao;
  final TelegramUploadService? uploadService;
  final ChannelManager? channelManager;

  final _progressController =
      StreamController<TakeoutImportProgress>.broadcast();
  Stream<TakeoutImportProgress> get progressStream =>
      _progressController.stream;

  TakeoutImportProgress _lastProgress = const TakeoutImportProgress();
  TakeoutImportProgress get currentProgress => _lastProgress;

  bool _isCancelled = false;

  TakeoutParserService({
    required this.mediaDao,
    this.uploadService,
    this.channelManager,
  });

  void cancelImport() {
    _isCancelled = true;
  }

  void _emitProgress({
    TakeoutImportStage? stage,
    int? totalItems,
    int? processedItems,
    int? importedCount,
    String? currentFilename,
    String? error,
  }) {
    _lastProgress = TakeoutImportProgress(
      stage: stage ?? _lastProgress.stage,
      totalItems: totalItems ?? _lastProgress.totalItems,
      processedItems: processedItems ?? _lastProgress.processedItems,
      importedCount: importedCount ?? _lastProgress.importedCount,
      currentFilename: currentFilename ?? _lastProgress.currentFilename,
      error: error ?? _lastProgress.error,
    );
    if (!_progressController.isClosed) {
      _progressController.add(_lastProgress);
    }
  }

  /// Quickly inspects a Google Takeout .zip archive and summarizes its contents
  Future<TakeoutZipSummary> analyzeZipArchive(String zipFilePath) async {
    final file = File(zipFilePath);
    if (!await file.exists()) {
      return const TakeoutZipSummary();
    }

    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);

      int photoCount = 0;
      int videoCount = 0;
      int jsonCount = 0;
      int totalBytes = 0;

      final photoExts = {'.jpg', '.jpeg', '.png', '.webp', '.heic', '.gif', '.raw'};
      final videoExts = {'.mp4', '.mov', '.mkv', '.avi', '.3gp'};

      for (final entry in archive.files) {
        if (entry.isFile) {
          totalBytes += entry.size;
          final ext = p.extension(entry.name).toLowerCase();
          if (photoExts.contains(ext)) {
            photoCount++;
          } else if (videoExts.contains(ext)) {
            videoCount++;
          } else if (ext == '.json') {
            jsonCount++;
          }
        }
      }

      return TakeoutZipSummary(
        totalFiles: archive.files.where((f) => f.isFile).length,
        photoCount: photoCount,
        videoCount: videoCount,
        metadataJsonCount: jsonCount,
        totalBytes: totalBytes,
      );
    } catch (e) {
      TeleCloudLogger.backup('Error analyzing Takeout zip: $e');
      return const TakeoutZipSummary();
    }
  }

  /// Parses and streams media items from a Google Takeout .zip archive directly into Telegram Cloud and Drift DB
  Future<int> importFromZip({
    required String zipFilePath,
    bool uploadToTelegram = true,
    String topicName = 'Google Photos Import',
  }) async {
    _isCancelled = false;
    final file = File(zipFilePath);
    if (!await file.exists()) {
      _emitProgress(stage: TakeoutImportStage.failed, error: 'Zip file not found');
      return 0;
    }

    _emitProgress(
      stage: TakeoutImportStage.analyzing,
      currentFilename: p.basename(zipFilePath),
    );

    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Index all metadata JSON sidecars in memory by base filename
      final Map<String, Map<String, dynamic>> jsonMetadataMap = {};
      final photoExts = {'.jpg', '.jpeg', '.png', '.webp', '.heic', '.gif', '.raw'};
      final videoExts = {'.mp4', '.mov', '.mkv', '.avi', '.3gp'};

      final List<ArchiveFile> mediaFiles = [];

      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        final name = entry.name;
        if (name.toLowerCase().endsWith('.json')) {
          try {
            final contentStr = utf8.decode(entry.content as List<int>);
            final decoded = jsonDecode(contentStr);
            if (decoded is Map<String, dynamic>) {
              // Standard Takeout format: IMG_1234.jpg.json -> key: IMG_1234.jpg
              final baseKey = p.basename(name).replaceAll('.json', '');
              jsonMetadataMap[baseKey.toLowerCase()] = decoded;
              // Also map without suffix e.g. IMG_1234(1).json -> IMG_1234.jpg
              jsonMetadataMap[p.basename(name).toLowerCase()] = decoded;
            }
          } catch (_) {}
        } else {
          final ext = p.extension(name).toLowerCase();
          if (photoExts.contains(ext) || videoExts.contains(ext)) {
            mediaFiles.add(entry);
          }
        }
      }

      if (mediaFiles.isEmpty) {
        _emitProgress(
          stage: TakeoutImportStage.completed,
          totalItems: 0,
          processedItems: 0,
          importedCount: 0,
          currentFilename: 'No media found in archive',
        );
        return 0;
      }

      // 2. Resolve or create Google Photos topic in Telegram Supergroup
      int? targetTopicId;
      int? targetChatId = channelManager?.channelId;

      if (uploadToTelegram && channelManager != null && targetChatId != null) {
        targetTopicId = await channelManager!.ensureAlbumTopic(topicName);
      }

      _emitProgress(
        stage: TakeoutImportStage.extracting,
        totalItems: mediaFiles.length,
        processedItems: 0,
        importedCount: 0,
      );

      Directory stagingDir;
      try {
        final tempDir = await getTemporaryDirectory();
        stagingDir = Directory(p.join(tempDir.path, 'takeout_staging'));
      } catch (_) {
        stagingDir = Directory(p.join(Directory.systemTemp.path, 'takeout_staging'));
      }
      if (!await stagingDir.exists()) {
        await stagingDir.create(recursive: true);
      }

      int successfullyImported = 0;

      for (int i = 0; i < mediaFiles.length; i++) {
        if (_isCancelled) {
          TeleCloudLogger.backup('Takeout import cancelled by user.');
          break;
        }

        final entry = mediaFiles[i];
        final filename = p.basename(entry.name);
        final ext = p.extension(filename).toLowerCase();
        final isVideo = videoExts.contains(ext);

        _emitProgress(
          stage: TakeoutImportStage.uploading,
          processedItems: i + 1,
          currentFilename: filename,
        );

        // Find companion sidecar JSON
        final baseNameLower = filename.toLowerCase();
        final sidecar = jsonMetadataMap[baseNameLower] ??
            jsonMetadataMap['$baseNameLower.json'] ??
            jsonMetadataMap[p.withoutExtension(baseNameLower)];

        final metadata = sidecar != null
            ? TakeoutMetadata.fromJson(sidecar, filename, DateTime.now())
            : TakeoutMetadata(
                title: filename,
                capturedAt: DateTime.now(),
              );

        // Write temporarily to disk for transmission
        final tempFilePath = p.join(stagingDir.path, '${DateTime.now().millisecondsSinceEpoch}_$filename');
        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(entry.content as List<int>);

        int? telegramMsgId;

        if (uploadToTelegram && uploadService != null && targetChatId != null) {
          telegramMsgId = await uploadService!.uploadDirectFile(
            file: tempFile,
            filename: filename,
            capturedAt: metadata.capturedAt,
            targetChatId: targetChatId,
            topicId: targetTopicId,
            albumName: topicName,
            latitude: metadata.latitude,
            longitude: metadata.longitude,
          );
        }

        // Insert into Drift Database
        final uniqueLocalId = 'gp_${metadata.capturedAt.millisecondsSinceEpoch}_$filename';
        await mediaDao.insertOrIgnoreBatch([
          MediaItemsCompanion.insert(
            localId: uniqueLocalId,
            filename: filename,
            mimeType: isVideo ? 'video/mp4' : 'image/jpeg',
            capturedAt: metadata.capturedAt,
            uploadStatus: telegramMsgId != null ? UploadStatus.done : UploadStatus.pending,
            telegramMsgId: telegramMsgId != null ? drift.Value(telegramMsgId) : const drift.Value.absent(),
            fileSizeBytes: drift.Value(tempFile.lengthSync()),
            latitude: metadata.latitude != null ? drift.Value(metadata.latitude!) : const drift.Value.absent(),
            longitude: metadata.longitude != null ? drift.Value(metadata.longitude!) : const drift.Value.absent(),
          ),
        ]);

        successfullyImported++;

        // Clean up temporary file to keep device storage clean
        try {
          if (tempFile.existsSync()) {
            tempFile.deleteSync();
          }
        } catch (_) {}

        _emitProgress(
          importedCount: successfullyImported,
        );
      }

      // Cleanup staging directory
      try {
        if (stagingDir.existsSync()) {
          stagingDir.deleteSync(recursive: true);
        }
      } catch (_) {}

      _emitProgress(
        stage: TakeoutImportStage.completed,
        processedItems: mediaFiles.length,
        importedCount: successfullyImported,
        currentFilename: 'Completed',
      );

      return successfullyImported;
    } catch (e) {
      TeleCloudLogger.backup('Takeout import failed with error: $e');
      _emitProgress(
        stage: TakeoutImportStage.failed,
        error: e.toString(),
      );
      return 0;
    }
  }

  void dispose() {
    _progressController.close();
  }
}
