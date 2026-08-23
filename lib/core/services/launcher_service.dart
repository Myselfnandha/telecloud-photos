import 'dart:async';
import 'package:flutter/services.dart';

class LauncherService {
  static const MethodChannel _channel = MethodChannel('com.telecloud/launcher');
  static final StreamController<String> _launchModeController =
      StreamController<String>.broadcast();

  static Stream<String> get onLaunchModeChanged => _launchModeController.stream;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewLaunchMode') {
        final mode = call.arguments as String? ?? 'photos';
        _launchModeController.add(mode);
      }
    });
  }

  /// Check if the secondary "TeleCloud Files" launcher icon is enabled
  static Future<bool> isFilesLauncherEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod('isFilesLauncherEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Enable or disable the secondary "TeleCloud Files" launcher icon
  static Future<bool> setFilesLauncherEnabled(bool enabled) async {
    try {
      final bool? result = await _channel.invokeMethod('setFilesLauncherEnabled', {
        'enabled': enabled,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Get initial launch mode ("files" vs "photos")
  static Future<String> getLaunchMode() async {
    try {
      final String? result = await _channel.invokeMethod('getLaunchMode');
      return result ?? 'photos';
    } catch (_) {
      return 'photos';
    }
  }

  /// Reset launch mode after handling navigation
  static Future<void> clearLaunchMode() async {
    try {
      await _channel.invokeMethod('clearLaunchMode');
    } catch (_) {}
  }
}
