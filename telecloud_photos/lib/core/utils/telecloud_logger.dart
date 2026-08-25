import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class TeleCloudLogger {
  static void log(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logMessage = '[$tag] $message';
    dev.log(
      logMessage,
      name: 'TeleCloud',
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
    if (kDebugMode) {
      debugPrint('[TeleCloud:$tag] $message');
      if (error != null) {
        debugPrint('[TeleCloud:$tag:ERROR] $error');
      }
    }
  }

  static void tdlib(String message, {Object? error}) =>
      log('TDLib', message, error: error);
  static void auth(String message, {Object? error}) =>
      log('Auth', message, error: error);
  static void scanner(String message, {Object? error}) =>
      log('Scanner', message, error: error);
  static void upload(String message, {Object? error}) =>
      log('UploadQueue', message, error: error);
  static void backup(String message, {Object? error}) =>
      log('BackupManager', message, error: error);
  static void db(String message, {Object? error}) =>
      log('Database', message, error: error);
}
