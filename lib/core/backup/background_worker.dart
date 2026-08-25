import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../constants/app_constants.dart';
import '../database/app_database.dart';
import '../utils/telecloud_logger.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    TeleCloudLogger.backup('[WorkManager] Background task triggered: $task');
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(AppConstants.keyAutoBackupEnabled) ??
          AppConstants.defaultAutoBackupEnabled;

      if (!enabled) {
        TeleCloudLogger.backup(
          '[WorkManager] Auto-backup disabled. Terminating worker.',
        );
        return true;
      }

      // Check network policy
      final wifiOnly = prefs.getBool(AppConstants.keyWifiOnly) ??
          AppConstants.defaultWifiOnly;
      final allowMobileData = prefs.getBool(AppConstants.keyAllowMobileData) ??
          AppConstants.defaultAllowMobileData;

      final connectivityResult = await Connectivity().checkConnectivity();
      final isWifi = connectivityResult.contains(ConnectivityResult.wifi);
      final isMobile = connectivityResult.contains(ConnectivityResult.mobile);

      if (wifiOnly && !isWifi) {
        TeleCloudLogger.backup(
          '[WorkManager] Wi-Fi only policy enabled but connected via mobile/other. Terminating.',
        );
        return true;
      }

      if (!isWifi && isMobile && !allowMobileData) {
        TeleCloudLogger.backup(
          '[WorkManager] Mobile data backup disabled in settings. Terminating.',
        );
        return true;
      }

      // Inspect SQLite Upload Queue
      final db = AppDatabase();
      final pending = await db.mediaDao.getPendingUploads();

      if (pending.isEmpty) {
        TeleCloudLogger.backup(
          '[WorkManager] Upload queue is clean (0 pending). Auto-killing background worker to preserve battery.',
        );
        await db.close();
        return true;
      }

      TeleCloudLogger.backup(
        '[WorkManager] Found ${pending.length} pending items in queue. Dispatched for processing.',
      );
      await db.close();
      return true;
    } catch (e) {
      TeleCloudLogger.backup(
        '[WorkManager] Background task execution error: $e',
      );
      return false;
    }
  });
}
