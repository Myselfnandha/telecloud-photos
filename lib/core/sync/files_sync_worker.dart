import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/daos/files_dao.dart';
import '../telegram/telegram_files_manager.dart';
import '../utils/telecloud_logger.dart';

class FilesSyncWorker {
  final FilesDao filesDao;
  final TelegramFilesManager filesManager;

  static const String monitoredFoldersKey = 'telecloud_files_monitored_folders';

  FilesSyncWorker({
    required this.filesDao,
    required this.filesManager,
  });

  /// Get list of configured local folder paths to monitor
  static Future<List<String>> getMonitoredFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(monitoredFoldersKey);
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    // Defaults: Standard Android Download and Documents directories
    final defaults = <String>[];
    final downloadDir = Directory('/storage/emulated/0/Download');
    if (downloadDir.existsSync()) defaults.add(downloadDir.path);
    final docDir = Directory('/storage/emulated/0/Documents');
    if (docDir.existsSync()) defaults.add(docDir.path);

    return defaults;
  }

  /// Save updated monitored folders list
  static Future<void> saveMonitoredFolders(List<String> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(monitoredFoldersKey, folders);
  }

  /// Scans all configured folders and queues new un-synced files
  Future<int> scanAndSyncMonitoredFolders() async {
    final folders = await getMonitoredFolders();
    int newFilesQueued = 0;

    TeleCloudLogger.log('FilesSync', 'Starting FilesSyncWorker scan across ${folders.length} folders...');

    for (final folderPath in folders) {
      final dir = Directory(folderPath);
      if (!dir.existsSync()) continue;

      final folderName = p.basename(folderPath);
      final targetCloudFolder = '/$folderName';

      try {
        final entities = dir.listSync(recursive: false, followLinks: false);
        for (final entity in entities) {
          if (entity is File) {
            final fileName = p.basename(entity.path);
            // Ignore hidden and temporary files
            if (fileName.startsWith('.') || fileName.endsWith('.tmp') || fileName.endsWith('.crdownload')) {
              continue;
            }

            // Check if already registered
            final existing = await filesDao.searchFiles(fileName).first;
            final match = existing.where((f) => f.localPath == entity.path || f.fileName == fileName);

            if (match.isEmpty) {
              await filesManager.uploadFile(
                localPath: entity.path,
                fileName: fileName,
                folderPath: targetCloudFolder,
              );
              newFilesQueued++;
            }
          }
        }
      } catch (e) {
        TeleCloudLogger.log('FilesSync', 'Error scanning folder $folderPath: $e');
      }
    }

    TeleCloudLogger.log('FilesSync', 'FilesSyncWorker completed. Queued $newFilesQueued new files.');
    return newFilesQueued;
  }
}
