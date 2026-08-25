import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../utils/telecloud_logger.dart';

enum SyncBlockedReason {
  none,
  disabled,
  waitingForWifi,
  roamingBlocked,
  cellularDataCapReached,
  waitingForCharger,
  batteryTooLow,
  noNetwork,
}

class SyncPolicyEvaluation {
  final bool canSync;
  final SyncBlockedReason reason;
  final String humanMessage;
  final int? batteryLevel;
  final bool isCharging;
  final int usedDataTodayBytes;
  final int dailyDataLimitMb;

  const SyncPolicyEvaluation({
    required this.canSync,
    required this.reason,
    required this.humanMessage,
    this.batteryLevel,
    this.isCharging = false,
    this.usedDataTodayBytes = 0,
    this.dailyDataLimitMb = 0,
  });
}

class SyncPolicyGuard {
  final Connectivity _connectivity;
  final Battery _battery;

  SyncPolicyGuard({
    Connectivity? connectivity,
    Battery? battery,
  })  : _connectivity = connectivity ?? Connectivity(),
        _battery = battery ?? Battery();

  /// Evaluates all network, power, and cellular data constraints
  Future<SyncPolicyEvaluation> evaluatePolicy({
    bool? isChargingOverride,
    int? batteryLevelOverride,
    List<ConnectivityResult>? connectivityOverride,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final autoBackupEnabled =
        prefs.getBool(AppConstants.keyAutoBackupEnabled) ??
            AppConstants.defaultAutoBackupEnabled;
    if (!autoBackupEnabled) {
      return const SyncPolicyEvaluation(
        canSync: false,
        reason: SyncBlockedReason.disabled,
        humanMessage: 'Auto-backup is turned off in Settings',
      );
    }

    // 1. Check Network Connectivity
    List<ConnectivityResult> connectivityResults;
    if (connectivityOverride != null) {
      connectivityResults = connectivityOverride;
    } else {
      try {
        connectivityResults = await _connectivity.checkConnectivity();
      } catch (_) {
        connectivityResults = [ConnectivityResult.other];
      }
    }

    final hasNone = connectivityResults.contains(ConnectivityResult.none);
    if (hasNone || connectivityResults.isEmpty) {
      return const SyncPolicyEvaluation(
        canSync: false,
        reason: SyncBlockedReason.noNetwork,
        humanMessage: 'No internet connection',
      );
    }

    final isWifi = connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.ethernet);

    final wifiOnly =
        prefs.getBool(AppConstants.keyWifiOnly) ?? AppConstants.defaultWifiOnly;
    final allowMobileData = prefs.getBool(AppConstants.keyAllowMobileData) ??
        AppConstants.defaultAllowMobileData;

    if (!isWifi) {
      if (wifiOnly && !allowMobileData) {
        return const SyncPolicyEvaluation(
          canSync: false,
          reason: SyncBlockedReason.waitingForWifi,
          humanMessage: 'Waiting for Wi-Fi (Cellular backup disabled)',
        );
      }

      // Check daily cellular data cap
      final dailyLimitMb =
          prefs.getInt(AppConstants.keyDailyCellularDataLimitMb) ??
              prefs.getInt(AppConstants.keyMobileDataLimitMb) ??
              AppConstants.defaultDailyCellularDataLimitMb;

      final usedTodayBytes = await getUsedCellularDataToday(prefs);

      if (dailyLimitMb > 0) {
        final limitBytes = dailyLimitMb * 1024 * 1024;
        if (usedTodayBytes >= limitBytes) {
          final usedMb = (usedTodayBytes / (1024 * 1024)).toStringAsFixed(1);
          return SyncPolicyEvaluation(
            canSync: false,
            reason: SyncBlockedReason.cellularDataCapReached,
            humanMessage:
                'Daily cellular limit reached ($usedMb / $dailyLimitMb MB)',
            usedDataTodayBytes: usedTodayBytes,
            dailyDataLimitMb: dailyLimitMb,
          );
        }
      }
    }

    // 2. Check Power & Battery Constraints
    int batteryLevel = 100;
    bool isCharging = false;
    try {
      if (batteryLevelOverride != null) {
        batteryLevel = batteryLevelOverride;
      } else {
        batteryLevel = await _battery.batteryLevel;
      }
      if (isChargingOverride != null) {
        isCharging = isChargingOverride;
      } else {
        final state = await _battery.batteryState;
        isCharging =
            state == BatteryState.charging || state == BatteryState.full;
      }
    } catch (_) {
      batteryLevel = batteryLevelOverride ?? 100;
      isCharging = isChargingOverride ?? true;
    }

    final chargingOnly = prefs.getBool(AppConstants.keyChargingOnly) ??
        AppConstants.defaultChargingOnly;
    if (chargingOnly && !isCharging) {
      return SyncPolicyEvaluation(
        canSync: false,
        reason: SyncBlockedReason.waitingForCharger,
        humanMessage: 'Waiting for charger (Charging-only mode active)',
        batteryLevel: batteryLevel,
        isCharging: isCharging,
      );
    }

    final batteryThreshold =
        prefs.getInt(AppConstants.keyBatteryThresholdPercent) ??
            AppConstants.defaultBatteryThresholdPercent;
    if (!isCharging && batteryLevel < batteryThreshold) {
      return SyncPolicyEvaluation(
        canSync: false,
        reason: SyncBlockedReason.batteryTooLow,
        humanMessage:
            'Battery below threshold ($batteryLevel% < $batteryThreshold%)',
        batteryLevel: batteryLevel,
        isCharging: isCharging,
      );
    }

    final usedToday = await getUsedCellularDataToday(prefs);
    final limitMb = prefs.getInt(AppConstants.keyDailyCellularDataLimitMb) ?? 0;

    return SyncPolicyEvaluation(
      canSync: true,
      reason: SyncBlockedReason.none,
      humanMessage: isWifi ? 'Connected to Wi-Fi' : 'Connected to Cellular',
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      usedDataTodayBytes: usedToday,
      dailyDataLimitMb: limitMb,
    );
  }

  /// Gets today's cellular data usage in bytes, resetting automatically at midnight.
  static Future<int> getUsedCellularDataToday(SharedPreferences prefs) async {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastResetDay = prefs.getString(AppConstants.keyLastDataUsageResetDay);

    if (lastResetDay != todayKey) {
      await prefs.setString(AppConstants.keyLastDataUsageResetDay, todayKey);
      await prefs.setInt(AppConstants.keyUsedCellularDataTodayBytes, 0);
      return 0;
    }

    return prefs.getInt(AppConstants.keyUsedCellularDataTodayBytes) ?? 0;
  }

  /// Records additional cellular bytes transferred
  static Future<void> recordDataUsage(int bytes) async {
    if (bytes <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getUsedCellularDataToday(prefs);
      await prefs.setInt(
        AppConstants.keyUsedCellularDataTodayBytes,
        current + bytes,
      );
    } catch (e) {
      TeleCloudLogger.backup('Failed to record cellular data usage: $e');
    }
  }
}
