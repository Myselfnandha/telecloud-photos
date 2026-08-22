import 'package:flutter/material.dart';

class AppColors {
  // Apple Photo style color palette (NO PURPLE)
  static const Color primaryBlue = Color(0xFF0A84FF);
  static const Color primaryBlueDark = Color(0xFF0066CC);
  static const Color primaryBlueLight = Color(0xFF5AC8FA);

  // OLED Pure Black
  static const Color oledBackground = Color(0xFF000000);
  static const Color oledSurface = Color(0xFF0D0D0E);
  static const Color oledCard = Color(0xFF161618);
  static const Color oledBorder = Color(0xFF242426);
  static const Color oledTextPrimary = Color(0xFFFFFFFF);
  static const Color oledTextSecondary = Color(0xFF8E8E93);
  static const Color oledTextTertiary = Color(0xFF48484A);

  // Standard Dark
  static const Color darkBackground = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkCard = Color(0xFF2C2C2E);
  static const Color darkBorder = Color(0xFF38383A);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextTertiary = Color(0xFF636366);

  // Light
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5EA);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightTextTertiary = Color(0xFFC7C7CC);

  // Accent & Status
  static const Color successGreen = Color(0xFF30D158);
  static const Color warningOrange = Color(0xFFFF9F0A);
  static const Color errorRed = Color(0xFFFF453A);
  static const Color infoBlue = Color(0xFF0A84FF);

  static const Color systemGreen = successGreen;
  static const Color systemOrange = warningOrange;
  static const Color systemRed = errorRed;
  static const Color systemBlue = primaryBlue;

  // Glassmorphic & Overlay Tokens
  static const Color glassBackgroundDark = Color(0xCC1C1C1E);
  static const Color glassBackgroundLight = Color(0xCCFFFFFF);
  static const Color glassBorderDark = Color(0x33FFFFFF);
  static const Color glassBorderLight = Color(0x33000000);
  static const Color overlayDim = Color(0x99000000);

  // Shimmer Skeleton Tokens
  static const Color shimmerBaseLight = Color(0xFFE5E5EA);
  static const Color shimmerHighlightLight = Color(0xFFF2F2F7);
  static const Color shimmerBaseDark = Color(0xFF1C1C1E);
  static const Color shimmerHighlightDark = Color(0xFF2C2C2E);
}
