import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'backup/background_worker.dart';
import 'backup/backup_manager.dart';
import 'constants/app_constants.dart';
import 'database/app_database.dart';
import 'utils/telecloud_logger.dart';

class AppInitializer {
  static Future<SharedPreferences> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    TeleCloudLogger.log('App', 'Starting TeleCloud Photos Application...');

    // Unlock native 90Hz / 120Hz / 144Hz high refresh rate on Android
    if (Platform.isAndroid) {
      try {
        await FlutterDisplayMode.setHighRefreshRate();
        TeleCloudLogger.log(
          'DisplayMode',
          'Unlocked 120Hz/90Hz high refresh rate display mode.',
        );
      } catch (e) {
        TeleCloudLogger.log('DisplayMode', 'High refresh rate notice: $e');
      }
    }

    // Optimize image cache to prevent micro-stutters and evictions during fast scrolling
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        1024 * 1024 * 300; // 300MB
    PaintingBinding.instance.imageCache.maximumSize = 1000;

    try {
      await dotenv.load(fileName: ".env");
      TeleCloudLogger.log(
        'App',
        'Loaded .env environment variables successfully.',
      );
    } catch (e) {
      TeleCloudLogger.log(
        'App',
        'No custom .env file detected, using default configuration.',
      );
    }

    // Load saved custom credentials from secure storage / .env
    await AppConstants.hasSavedCredentials();

    final prefs = await SharedPreferences.getInstance();

    try {
      final appDb = AppDatabase();
      await appDb.mediaDao.purgeMockData();
    } catch (e) {
      TeleCloudLogger.log('App', 'Mock data purge notice: $e');
    }

    try {
      await Workmanager().initialize(callbackDispatcher);
      final manager = BackupManager();
      manager.initForegroundTask();
      await manager.scheduleBackgroundWorker();
    } catch (e) {
      TeleCloudLogger.log('App', 'WorkManager init warning: $e');
    }

    return prefs;
  }
}
