import 'package:flutter/material.dart';

/// Centralized motion tokens for intentional animations.
class AppMotion {
  // Durations
  static const Duration durationInstant = Duration(milliseconds: 50);
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 260);
  static const Duration durationPage = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 450);
  static const Duration durationBadgeFade = Duration(milliseconds: 1200);

  // Curves
  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveSnappy = Curves.easeOutQuad;
  static const Curve curveEmphasized = Curves.easeInOutCubic;
  static const Curve curveDecelerate = Curves.decelerate;
  static const Curve curveSpring = Curves.elasticOut;
}
