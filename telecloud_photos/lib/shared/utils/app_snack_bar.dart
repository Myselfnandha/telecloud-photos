import 'package:flutter/material.dart';

/// Centralized SnackBar utility ensuring all notifications across all screens
/// auto-dismiss within 2 seconds, clear previous stacked snackbars, and provide
/// a consistent premium floating aesthetic.
class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF2C2C2E),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, backgroundColor: const Color(0xFF30D158));
  }

  static void showError(BuildContext context, String message) {
    show(context, message, backgroundColor: const Color(0xFFFF453A));
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message, backgroundColor: const Color(0xFF0A84FF));
  }
}
