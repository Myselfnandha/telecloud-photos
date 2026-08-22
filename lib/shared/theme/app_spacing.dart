import 'package:flutter/material.dart';

/// Centralized Apple HIG spacing tokens.
/// Standard 8pt/4pt hybrid rhythm: xs(4), s(8), m(12), l(16), xl(20), xxl(28), xxxl(40).
class AppSpacing {
  // Base spacing values
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double xxxl = 40.0;

  // Pre-configured EdgeInsets for consistent padding across screens
  static const EdgeInsets paddingNone = EdgeInsets.zero;
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingS = EdgeInsets.all(s);
  static const EdgeInsets paddingM = EdgeInsets.all(m);
  static const EdgeInsets paddingL = EdgeInsets.all(l);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);

  // Horizontal Padding
  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(
    horizontal: s,
  );
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(
    horizontal: m,
  );
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(
    horizontal: l,
  );
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(
    horizontal: xl,
  );

  // Vertical Padding
  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: s);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: m);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: l);
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(
    vertical: xl,
  );

  // Screen Padding (Standard edge insets for sheets, cards, screens)
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: l,
    vertical: m,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(l);
  static const EdgeInsets dialogPadding = EdgeInsets.all(xxl);

  // Gap SizedBox helpers for vertical/horizontal spacing
  static const SizedBox gapXS = SizedBox(width: xs, height: xs);
  static const SizedBox gapS = SizedBox(width: s, height: s);
  static const SizedBox gapM = SizedBox(width: m, height: m);
  static const SizedBox gapL = SizedBox(width: l, height: l);
  static const SizedBox gapXL = SizedBox(width: xl, height: xl);
  static const SizedBox gapXXL = SizedBox(width: xxl, height: xxl);
  static const SizedBox gapXXXL = SizedBox(width: xxxl, height: xxxl);

  // Horizontal specific gaps
  static const SizedBox gapHorizontalXS = SizedBox(width: xs);
  static const SizedBox gapHorizontalS = SizedBox(width: s);
  static const SizedBox gapHorizontalM = SizedBox(width: m);
  static const SizedBox gapHorizontalL = SizedBox(width: l);
  static const SizedBox gapHorizontalXL = SizedBox(width: xl);

  // Vertical specific gaps
  static const SizedBox gapVerticalXS = SizedBox(height: xs);
  static const SizedBox gapVerticalS = SizedBox(height: s);
  static const SizedBox gapVerticalM = SizedBox(height: m);
  static const SizedBox gapVerticalL = SizedBox(height: l);
  static const SizedBox gapVerticalXL = SizedBox(height: xl);
  static const SizedBox gapVerticalXXL = SizedBox(height: xxl);
}
