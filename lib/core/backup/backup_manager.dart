import 'dart:async';
import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../constants/app_constants.dart';
import '../utils/telecloud_logger.dart';

enum BackupState { idle, waitingToUpload, uploading, waitingForReconnect }

class BackupManager {
  static final BackupManager _instance = BackupManager._internal();
  factory BackupManager() => _instance;
  BackupManager._internal();

  static const String backgroundTaskName = 'telecloud_background_auto_sync';
  static const String backgroundUniqueName =
      'com.telecloud.telecloud_photos.background_sync';

  Timer? _stateTimer;
  bool _isCharging = false;
  bool _isInForeground = true;
  BackupState _currentState = BackupState.idle;

  bool get isInForeground => _isInForeground;
  BackupState get currentState => _currentState;

  void Function()? onStartUploading;
  void Function()? onStopUploading;

  void initForegroundTask() {
    TeleCloudLogger.backup('Initializing Android foreground task options...');
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'telecloud_backup_channel',
        channelName: 'TeleCloud Backup Service',
        channelDescription: 'Monitors battery & uploads photo backups',
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Schedules or reschedules Workmanager periodic background worker based on current Settings
  Future<void> scheduleBackgroundWorker({bool forceReschedule = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(AppConstants.keyAutoBackupEnabled) ??
        AppConstants.defaultAutoBackupEnabled;

    if (!enabled) {
      TeleCloudLogger.backup(
        'Background auto-backup is disabled in settings. Cancelling worker.',
      );
      await cancelBackgroundWorker();
      return;
    }

    final wifiOnly =
        prefs.getBool(AppConstants.keyWifiOnly) ?? AppConstants.defaultWifiOnly;
    final allowMobileData =
        prefs.getBool(AppConstants.keyAllowMobileData) ??
        AppConstants.defaultAllowMobileData;
    final chargingOnly =
        prefs.getBool(AppConstants.keyChargingOnly) ??
        AppConstants.defaultChargingOnly;
    final batteryNotLow =
        prefs.getBool(AppConstants.keyBatteryNotLow) ??
        AppConstants.defaultBatteryNotLow;
    final freqMins =
        prefs.getInt(AppConstants.keySyncFrequencyMins) ??
        AppConstants.defaultSyncFrequencyMins;

    final networkType = wifiOnly
        ? NetworkType.unmetered
        : (allowMobileData ? NetworkType.connected : NetworkType.unmetered);

    TeleCloudLogger.backup(
      'Scheduling WorkManager background task: freq=${freqMins}m, chargingOnly=$chargingOnly, wifiOnly=$wifiOnly, batteryNotLow=$batteryNotLow',
    );

    try {
      await Workmanager().registerPeriodicTask(
        backgroundUniqueName,
        backgroundTaskName,
        frequency: Duration(minutes: freqMins >= 15 ? freqMins : 15),
        constraints: Constraints(
          networkType: networkType,
          requiresCharging: chargingOnly,
          requiresBatteryNotLow: batteryNotLow,
          requiresDeviceIdle: false,
        ),
        existingWorkPolicy: forceReschedule
            ? ExistingPeriodicWorkPolicy.update
            : ExistingPeriodicWorkPolicy.keep,
        backoffPolicy: BackoffPolicy.exponential,
        initialDelay: const Duration(seconds: 10),
      );
      TeleCloudLogger.backup(
        'WorkManager background task successfully registered.',
      );
    } catch (e) {
      TeleCloudLogger.backup('WorkManager schedule warning: $e');
    }
  }

  /// Cancels WorkManager background tasks
  Future<void> cancelBackgroundWorker() async {
    try {
      await Workmanager().cancelByUniqueName(backgroundUniqueName);
      TeleCloudLogger.backup('WorkManager background task cancelled.');
    } catch (e) {
      TeleCloudLogger.backup('WorkManager cancel error: $e');
    }
  }

  void onAppLifecycleChanged(bool isInForeground) {
    TeleCloudLogger.backup(
      'App lifecycle changed: isInForeground=$isInForeground',
    );
    _isInForeground = isInForeground;
    _evaluateState();
  }

  Future<void> onPowerConnected() async {
    TeleCloudLogger.backup('Power CONNECTED (Device on AC/USB charger).');
    _isCharging = true;
    await _evaluateState();
  }

  Future<void> onPowerDisconnected() async {
    TeleCloudLogger.backup('Power DISCONNECTED (Device on Battery power).');
    _isCharging = false;
    await _evaluateState();
  }

  /// Call this when the upload queue is empty so we can dismiss the notification and auto-kill lingering tasks
  Future<void> onUploadsFinished() async {
    TeleCloudLogger.backup('All queued uploads finished.');
    final prefs = await SharedPreferences.getInstance();
    final autoKill =
        prefs.getBool(AppConstants.keyAutoKillWhenDone) ??
        AppConstants.defaultAutoKillWhenDone;

    if (autoKill) {
      TeleCloudLogger.backup(
        'Auto-Kill policy active: Terminating foreground task and releasing background locks.',
      );
      await stopService();
    } else {
      if (_currentState == BackupState.uploading ||
          _currentState == BackupState.waitingToUpload) {
        await _transitionTo(BackupState.idle);
      }
    }
  }

  Future<void> _evaluateState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(AppConstants.keyAutoBackupEnabled) ??
        AppConstants.defaultAutoBackupEnabled;
    final chargingOnly =
        prefs.getBool(AppConstants.keyChargingOnly) ??
        AppConstants.defaultChargingOnly;

    if (!enabled) {
      await stopService();
      return;
    }

    bool canUpload = _isInForeground || (!chargingOnly || _isCharging);
    TeleCloudLogger.backup(
      'Evaluating backup policy: canUpload=$canUpload (foreground=$_isInForeground, charging=$_isCharging, chargingOnly=$chargingOnly, state=$_currentState)',
    );

    if (canUpload) {
      if (_currentState == BackupState.idle) {
        await _transitionTo(BackupState.waitingToUpload);
      } else if (_currentState == BackupState.waitingForReconnect) {
        // Reconnected during grace period! Resume immediately
        await _transitionTo(BackupState.uploading);
      }
    } else {
      // Cannot upload (background + battery while chargingOnly is true)
      if (_currentState == BackupState.uploading ||
          _currentState == BackupState.waitingToUpload) {
        await _transitionTo(BackupState.waitingForReconnect);
      }
    }
  }

  Future<void> _transitionTo(BackupState newState) async {
    TeleCloudLogger.backup('State Transition: $_currentState -> $newState');
    _stateTimer?.cancel();
    _currentState = newState;
    final prefs = await SharedPreferences.getInstance();

    switch (newState) {
      case BackupState.idle:
        onStopUploading?.call();
        await stopService();
        break;

      case BackupState.waitingToUpload:
        onStopUploading?.call();
        final dwellMins =
            prefs.getInt(AppConstants.keyChargingDwellMins) ??
            AppConstants.defaultChargingDwellMins;
        TeleCloudLogger.backup(
          'Entering charging stabilization dwell delay ($dwellMins minutes)...',
        );

        if (dwellMins <= 0) {
          // Instant start without delay
          await _transitionTo(BackupState.uploading);
          return;
        }

        if (!await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.startService(
            serviceId: 256,
            notificationTitle: 'TeleCloud Backup',
            notificationText: 'Stabilizing power ($dwellMins min dwell)...',
          );
        } else {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'TeleCloud Backup',
            notificationText: 'Stabilizing power ($dwellMins min dwell)...',
          );
        }

        _stateTimer = Timer(Duration(minutes: dwellMins), () {
          if (_currentState == BackupState.waitingToUpload) {
            _transitionTo(BackupState.uploading);
          }
        });
        break;

      case BackupState.uploading:
        TeleCloudLogger.backup('Transitioned to active uploading state.');
        if (!await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.startService(
            serviceId: 256,
            notificationTitle: 'TeleCloud Backup',
            notificationText: 'Uploading photos to Telegram Cloud...',
          );
        } else {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'TeleCloud Backup',
            notificationText: 'Uploading photos to Telegram Cloud...',
          );
        }
        onStartUploading?.call();
        break;

      case BackupState.waitingForReconnect:
        onStopUploading?.call();
        final waitMins =
            prefs.getInt(AppConstants.keyWaitDisconnectMins) ??
            AppConstants.defaultWaitDisconnectMins;
        TeleCloudLogger.backup(
          'Charger disconnected. Waiting grace period ($waitMins minutes)...',
        );
        if (await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'TeleCloud Backup',
            notificationText:
                'Upload paused. Waiting $waitMins mins for charger...',
          );
        }
        _stateTimer = Timer(Duration(minutes: waitMins), () {
          if (_currentState == BackupState.waitingForReconnect) {
            _transitionTo(BackupState.idle);
          }
        });
        break;
    }
  }

  Future<void> stopService() async {
    TeleCloudLogger.backup('Stopping foreground service.');
    onStopUploading?.call();
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    _currentState = BackupState.idle;
  }

  /// Deep Kill: Stops all uploads, cancels all background workers, stops foreground services, and terminates the application process.
  Future<void> deepKillEverything() async {
    TeleCloudLogger.backup(
      'EMERGENCY DEEP KILL INITIATED: Stopping all tasks, cancelling Workmanager, and exiting.',
    );
    _stateTimer?.cancel();
    onStopUploading?.call();
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}
    try {
      await Workmanager().cancelAll();
      TeleCloudLogger.backup('All WorkManager background tasks cancelled.');
    } catch (_) {}
    _currentState = BackupState.idle;
    await Future.delayed(const Duration(milliseconds: 300));
    exit(0);
  }
}
