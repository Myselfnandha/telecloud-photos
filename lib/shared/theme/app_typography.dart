import 'package:flutter/material.dart';

/// Centralized Apple HIG typography scale using SF Pro Display.
class AppTypography {
  static const String fontFamily = 'SFProDisplay';

  // Font Weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Base TextStyle builder
  static TextStyle _baseStyle({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // Display Styles (Large hero headers)
  static TextStyle displayLarge({Color? color}) => _baseStyle(
    fontSize: 34,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: 0.37,
    color: color,
  );

  static TextStyle displayMedium({Color? color}) => _baseStyle(
    fontSize: 28,
    fontWeight: bold,
    height: 1.25,
    letterSpacing: 0.36,
    color: color,
  );

  // Headline Styles (Section headers)
  static TextStyle headlineLarge({Color? color}) => _baseStyle(
    fontSize: 22,
    fontWeight: bold,
    height: 1.3,
    letterSpacing: 0.35,
    color: color,
  );

  static TextStyle headlineMedium({Color? color}) => _baseStyle(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: 0.38,
    color: color,
  );

  static TextStyle headlineSmall({Color? color}) => _baseStyle(
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: 0.35,
    color: color,
  );

  // Title Styles (Card titles, AppBar titles)
  static TextStyle titleLarge({Color? color}) => _baseStyle(
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.35,
    letterSpacing: -0.4,
    color: color,
  );

  static TextStyle titleMedium({Color? color}) => _baseStyle(
    fontSize: 16,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: -0.3,
    color: color,
  );

  static TextStyle titleSmall({Color? color}) => _baseStyle(
    fontSize: 15,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: -0.2,
    color: color,
  );

  // Body Styles (Main content, descriptions)
  static TextStyle bodyLarge({Color? color}) => _baseStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.45,
    letterSpacing: -0.3,
    color: color,
  );

  static TextStyle bodyMedium({Color? color}) => _baseStyle(
    fontSize: 14,
    fontWeight: regular,
    height: 1.4,
    letterSpacing: -0.2,
    color: color,
  );

  static TextStyle bodySmall({Color? color}) => _baseStyle(
    fontSize: 13,
    fontWeight: regular,
    height: 1.35,
    letterSpacing: -0.1,
    color: color,
  );

  // Label / Caption Styles (Subtitles, metadata badges, timestamps)
  static TextStyle labelLarge({Color? color}) => _baseStyle(
    fontSize: 13,
    fontWeight: medium,
    height: 1.3,
    letterSpacing: 0.0,
    color: color,
  );

  static TextStyle labelMedium({Color? color}) => _baseStyle(
    fontSize: 12,
    fontWeight: medium,
    height: 1.3,
    letterSpacing: 0.1,
    color: color,
  );

  static TextStyle labelSmall({Color? color}) => _baseStyle(
    fontSize: 11,
    fontWeight: regular,
    height: 1.25,
    letterSpacing: 0.2,
    color: color,
  );

  // Generates complete Material 3 TextTheme
  static TextTheme createTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: displayLarge(color: primaryColor),
      displayMedium: displayMedium(color: primaryColor),
      headlineLarge: headlineLarge(color: primaryColor),
      headlineMedium: headlineMedium(color: primaryColor),
      titleLarge: titleLarge(color: primaryColor),
      titleMedium: titleMedium(color: primaryColor),
      titleSmall: titleSmall(color: primaryColor),
      bodyLarge: bodyLarge(color: primaryColor),
      bodyMedium: bodyMedium(color: primaryColor),
      bodySmall: bodySmall(color: secondaryColor),
      labelLarge: labelLarge(color: primaryColor),
      labelMedium: labelMedium(color: secondaryColor),
      labelSmall: labelSmall(color: secondaryColor),
    );
  }
}
