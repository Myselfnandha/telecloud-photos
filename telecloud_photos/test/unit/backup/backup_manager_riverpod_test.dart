import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecloud_photos/core/backup/backup_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupManager Riverpod StateNotifier Tests', () {
    late BackupManager backupManager;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'telecloud_backup_charging_only': true,
        'telecloud_auto_backup_enabled': true,
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_foreground_task/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'isRunningService') {
            return false;
          }
          return true;
        },
      );

      backupManager = BackupManager();
    });

    test('1. Initial state of BackupManager is BackupState.idle', () {
      expect(backupManager.state, BackupState.idle);
      expect(backupManager.currentState, BackupState.idle);
    });

    test('2. onPowerConnected sets state to waitingToUpload when charging-only',
        () async {
      await backupManager.onPowerConnected();
      expect(backupManager.state, BackupState.waitingToUpload);
    });

    test('3. onPowerDisconnected transitions to waitingForReconnect', () async {
      await backupManager.onPowerConnected();
      expect(backupManager.state, BackupState.waitingToUpload);

      backupManager.onAppLifecycleChanged(false);
      await backupManager.onPowerDisconnected();
      expect(backupManager.state, BackupState.waitingForReconnect);
    });

    test('4. onAppLifecycleChanged updates internal foreground tracking',
        () async {
      backupManager.onAppLifecycleChanged(false);
      expect(backupManager.isInForeground, isFalse);
      backupManager.onAppLifecycleChanged(true);
      expect(backupManager.isInForeground, isTrue);
    });

    test('5. onUploadsFinished resets state to idle', () async {
      await backupManager.onPowerConnected();
      expect(backupManager.state, BackupState.waitingToUpload);

      await backupManager.onUploadsFinished();
      expect(backupManager.state, BackupState.idle);
    });
  });
}
