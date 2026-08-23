import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConstants {
  static const String appName = 'TeleCloud Photos';
  static const String telegramChannelTitle = 'TeleCloud Photos 📸';
  static const String channelIdKey = 'telecloud_channel_id';

  // Storage Keys for User Credentials
  static const String keyApiId = 'telecloud_api_id';
  static const String keyApiHash = 'telecloud_api_hash';

  static int? _customApiId;
  static String? _customApiHash;

  static void setCredentials(int apiId, String apiHash) {
    _customApiId = apiId;
    _customApiHash = apiHash;
  }

  // Telegram API Credentials
  static int get telegramApiId {
    if (_customApiId != null && _customApiId! > 0) return _customApiId!;
    if (dotenv.isInitialized) {
      final envId = int.tryParse(dotenv.env['TELEGRAM_API_ID'] ?? '');
      if (envId != null && envId > 0) return envId;
    }
    const defineId = int.fromEnvironment('TELEGRAM_API_ID', defaultValue: 0);
    if (defineId > 0) return defineId;
    // Official Telegram production public API ID (Telegram Desktop / Android)
    return 2496;
  }

  static String get telegramApiHash {
    if (_customApiHash != null && _customApiHash!.isNotEmpty) return _customApiHash!;
    if (dotenv.isInitialized) {
      final envHash = dotenv.env['TELEGRAM_API_HASH'];
      if (envHash != null && envHash.isNotEmpty) return envHash;
    }
    const defineHash = String.fromEnvironment('TELEGRAM_API_HASH', defaultValue: '');
    if (defineHash.isNotEmpty) return defineHash;
    // Official Telegram production public API Hash
    return '8da85b0d5b1652522bc46057082da478';
  }

  static Future<bool> hasSavedCredentials() async {
    try {
      const storage = FlutterSecureStorage();
      final id = await storage
          .read(key: keyApiId)
          .timeout(const Duration(milliseconds: 800), onTimeout: () => null);
      final hash = await storage
          .read(key: keyApiHash)
          .timeout(const Duration(milliseconds: 800), onTimeout: () => null);
      if (id != null && id.isNotEmpty && hash != null && hash.isNotEmpty) {
        final parsedId = int.tryParse(id);
        if (parsedId != null) {
          setCredentials(parsedId, hash);
          return true;
        }
      }
    } catch (_) {}

    // Also check if .env has valid non-empty credentials
    try {
      if (dotenv.isInitialized) {
        final envId = int.tryParse(dotenv.env['TELEGRAM_API_ID'] ?? '');
        final envHash = dotenv.env['TELEGRAM_API_HASH'];
        if (envId != null && envId > 0 && envHash != null && envHash.isNotEmpty) {
          setCredentials(envId, envHash);
          return true;
        }
      }
    } catch (_) {}

    // Fallback to built-in default credentials
    if (telegramApiId > 0 && telegramApiHash.isNotEmpty) {
      return true;
    }
    return false;
  }

  static Future<void> saveCredentials(int apiId, String apiHash) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: keyApiId, value: apiId.toString());
    await storage.write(key: keyApiHash, value: apiHash);
    setCredentials(apiId, apiHash);
  }

  // Settings keys
  static const String keyAutoBackupEnabled = 'auto_backup_enabled';
  static const String keyWifiOnly = 'wifi_only';
  static const String keyAllowMobileData = 'allow_mobile_data';
  static const String keyMobileDataLimitMb = 'mobile_data_limit_mb';
  static const String keyChargingOnly = 'charging_only';
  static const String keyChargingDwellMins = 'charging_dwell_mins';
  static const String keyBatteryNotLow = 'battery_not_low';
  static const String keyAutoKillWhenDone = 'auto_kill_when_done';
  static const String keySyncFrequencyMins = 'sync_frequency_mins';
  static const String keyIncludeVideos = 'include_videos';
  static const String keyIncludeMp4Videos = 'include_mp4_videos';
  static const String keyIncludeMovVideos = 'include_mov_videos';
  static const String keyIncludeScreenshots = 'include_screenshots';

  static const String keyWaitConnectMins = 'wait_connect_mins';
  static const String keyWaitDisconnectMins = 'wait_disconnect_mins';
  static const String keyAppTheme =
      'app_theme_mode'; // 'light', 'dark', 'system', 'pure_black'

  // Defaults
  static const bool defaultAutoBackupEnabled = true;
  static const bool defaultWifiOnly = true;
  static const bool defaultAllowMobileData = false;
  static const int defaultMobileDataLimitMb = 0; // 0 = unlimited
  static const bool defaultChargingOnly = true;
  static const int defaultChargingDwellMins = 30; // 30 mins stabilization
  static const bool defaultBatteryNotLow = true;
  static const bool defaultAutoKillWhenDone = true;
  static const int defaultSyncFrequencyMins = 30;
  static const bool defaultIncludeVideos = true;
  static const bool defaultIncludeMp4Videos = true;
  static const bool defaultIncludeMovVideos = true;
  static const bool defaultIncludeScreenshots = true;

  static const int defaultWaitConnectMins = 5;
  static const int defaultWaitDisconnectMins = 5;
}
