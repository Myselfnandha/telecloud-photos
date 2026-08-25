import 'package:flutter/material.dart';

/// Centralized Apple HIG corner radius tokens.
/// Standard: S(6), M(10), L(14 - cards), XL(22 - modal sheets), full(999 - pills/badges).
class AppRadii {
  // Raw numeric values
  static const double none = 0.0;
  static const double s = 6.0;
  static const double m = 10.0;
  static const double l = 14.0;
  static const double xl = 22.0;
  static const double full = 999.0;

  // Radius objects
  static const Radius radiusNone = Radius.zero;
  static const Radius radiusS = Radius.circular(s);
  static const Radius radiusM = Radius.circular(m);
  static const Radius radiusL = Radius.circular(l);
  static const Radius radiusXL = Radius.circular(xl);
  static const Radius radiusFull = Radius.circular(full);

  // BorderRadius pre-built objects
  static const BorderRadius borderNone = BorderRadius.zero;
  static const BorderRadius borderS = BorderRadius.all(radiusS);
  static const BorderRadius borderM = BorderRadius.all(radiusM);
  static const BorderRadius borderL = BorderRadius.all(radiusL);
  static const BorderRadius borderXL = BorderRadius.all(radiusXL);
  static const BorderRadius borderFull = BorderRadius.all(radiusFull);
  static const BorderRadius borderPill = BorderRadius.all(radiusFull);

  // Top-only (BottomSheet / Dialog)
  static const BorderRadius borderTopM = BorderRadius.vertical(top: radiusM);
  static const BorderRadius borderTopL = BorderRadius.vertical(top: radiusL);
  static const BorderRadius borderTopXL = BorderRadius.vertical(top: radiusXL);
}
