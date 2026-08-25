import 'package:flutter/material.dart';

/// Centralized subtle elevation tokens per specification (no excessive shadows).
class AppElevation {
  static const double none = 0.0;
  static const double subtle = 0.5;
  static const double low = 1.0;
  static const double medium = 2.0;
  static const double high = 4.0;
  static const double modal = 8.0;

  // Subtle soft shadows for light mode cards and floating badges
  static List<BoxShadow> softShadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  // Subtle soft shadows for dark mode
  static List<BoxShadow> softShadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Glassmorphic pill badge shadow
  static List<BoxShadow> glassPillShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.20),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
