import 'dart:async';
import 'package:drift/drift.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../utils/telecloud_logger.dart';

class FolderSyncManager {
  final MediaDao mediaDao;

  FolderSyncManager({required this.mediaDao});

  /// Streams active folder sync settings with live status
  Stream<List<FolderSyncSetting>> watchFolders() {
    return mediaDao.watchFolderSyncSettings();
  }

  /// Discovers all device albums/folders and synchronizes their configurations with SQLite
  Future<List<FolderSyncSetting>> discoverAndSyncDeviceFolders() async {
    try {
      final state = await PhotoManager.requestPermissionExtend();
      if (!state.isAuth && !state.hasAccess) {
        return await mediaDao.getAllFolderSyncSettings();
      }

      final prefs = await SharedPreferences.getInstance();
      final savedEnabledIds =
          prefs.getStringList(AppConstants.keyEnabledBackupFolders) ?? [];

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );

      for (final album in albums) {
        if (album.isAll) continue; // Skip artificial "Recent / All" folder

        final count = await album.assetCountAsync;
        final folderId = album.id;
        final folderName = album.name;

        final existing = await mediaDao.getFolderSyncSetting(folderId);

        // Determine if enabled:
        // 1. If exists in DB, keep existing setting
        // 2. If present in saved SharedPreferences list, true
        // 3. If Camera / DCIM, default to true
        // 4. Otherwise default to true for seamless first-run
        bool isEnabled;
        if (existing != null) {
          isEnabled = existing.isAutoBackupEnabled;
        } else if (savedEnabledIds.isNotEmpty) {
          isEnabled = savedEnabledIds.contains(folderId) ||
              savedEnabledIds.contains(folderName);
        } else {
          isEnabled = true; // Default enable all discovered device albums
        }

        await mediaDao.upsertFolderSyncSetting(
          FolderSyncSettingsCompanion(
            folderId: Value(folderId),
            folderName: Value(folderName),
            folderPath: Value(album.name),
            isAutoBackupEnabled: Value(isEnabled),
            mediaCount: Value(count),
            lastSyncedAt: Value(DateTime.now()),
          ),
        );
      }

      await _persistEnabledFolderIdsToPrefs();
    } catch (e) {
      TeleCloudLogger.scanner('Error discovering device folders: $e');
    }

    return await mediaDao.getAllFolderSyncSettings();
  }

  /// Toggles backup status for a specific folder
  Future<void> setFolderBackupEnabled(String folderId, bool isEnabled) async {
    await mediaDao.setFolderAutoBackup(folderId, isEnabled);
    await _persistEnabledFolderIdsToPrefs();
    TeleCloudLogger.backup(
      'Folder "$folderId" backup set to: $isEnabled',
    );
  }

  /// Queues all historical items in a folder for cloud backup
  Future<int> queueFolderHistoricalMedia(String folderName) async {
    final queued = await mediaDao.queueFolderMediaForUpload(folderName);
    TeleCloudLogger.backup(
      'Queued $queued historical items for backup in folder "$folderName".',
    );
    return queued;
  }

  /// Synchronizes enabled folder IDs from DB into SharedPreferences for background worker
  Future<void> _persistEnabledFolderIdsToPrefs() async {
    try {
      final allSettings = await mediaDao.getAllFolderSyncSettings();
      final enabledIds = allSettings
          .where((f) => f.isAutoBackupEnabled)
          .map((f) => f.folderId)
          .toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        AppConstants.keyEnabledBackupFolders,
        enabledIds,
      );
    } catch (e) {
      TeleCloudLogger.backup('Failed to persist folder IDs to prefs: $e');
    }
  }
}
