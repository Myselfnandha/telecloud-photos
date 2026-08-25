import 'package:flutter/material.dart';

/// Centralized Icon and Touch Target tokens per Apple HIG and accessibility standards.
class AppIcons {
  // Icon Sizes
  static const double s = 16.0;
  static const double m = 20.0;
  static const double l = 24.0;
  static const double xl = 28.0;
  static const double xxl = 36.0;
  static const double hero = 48.0;

  // Accessibility Minimum Touch Target (44x44 logical pixels)
  static const double minTouchTarget = 44.0;
  static const BoxConstraints touchTargetConstraints = BoxConstraints(
    minWidth: minTouchTarget,
    minHeight: minTouchTarget,
  );
}
