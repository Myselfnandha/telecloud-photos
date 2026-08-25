import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radii.dart';
import 'app_elevation.dart';

enum AppThemeMode { light, dark, system, pureBlack }

enum GridDisplayMode {
  squareCropped, // Square 1:1 with BoxFit.cover
  aspectRatioFit, // Square 1:1 with BoxFit.contain (letterboxed)
  uncropped, // Adaptive original aspect ratio (masonry / uncropped tiles)
}

extension GridDisplayModeExtension on GridDisplayMode {
  String get nameString {
    switch (this) {
      case GridDisplayMode.squareCropped:
        return 'square_cropped';
      case GridDisplayMode.aspectRatioFit:
        return 'aspect_ratio_fit';
      case GridDisplayMode.uncropped:
        return 'uncropped';
    }
  }

  String get displayName {
    switch (this) {
      case GridDisplayMode.squareCropped:
        return 'Square Cropped (1:1 Fill)';
      case GridDisplayMode.aspectRatioFit:
        return 'Uncropped Fit (Letterbox)';
      case GridDisplayMode.uncropped:
        return 'Original Ratio (Masonry)';
    }
  }

  static GridDisplayMode fromString(String? val) {
    switch (val) {
      case 'aspect_ratio_fit':
        return GridDisplayMode.aspectRatioFit;
      case 'uncropped':
        return GridDisplayMode.uncropped;
      case 'square_cropped':
      default:
        return GridDisplayMode.squareCropped;
    }
  }
}

extension AppThemeModeExtension on AppThemeMode {
  String get nameString {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
      case AppThemeMode.pureBlack:
        return 'pure_black';
    }
  }

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'Follow System';
      case AppThemeMode.pureBlack:
        return 'Pure Black (OLED)';
    }
  }

  static AppThemeMode fromString(String? val) {
    switch (val) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
        return AppThemeMode.system;
      case 'pure_black':
      default:
        return AppThemeMode.pureBlack;
    }
  }
}

class AppTheme {
  // 1. OLED Pure Black (Pitch Black #000000)
  static ThemeData get pureBlackTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.oledBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        surface: AppColors.oledSurface,
        error: AppColors.errorRed,
        outline: AppColors.oledBorder,
      ),
      textTheme: AppTypography.createTextTheme(
        AppColors.oledTextPrimary,
        AppColors.oledTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.oledBackground,
        elevation: AppElevation.none,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.oledTextPrimary),
        titleTextStyle: AppTypography.headlineMedium(
          color: AppColors.oledTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.oledCard,
        elevation: AppElevation.none,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderL,
          side: const BorderSide(color: AppColors.oledBorder, width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.oledBackground,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.oledTextSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.oledBorder,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C1C1E),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        dismissDirection: DismissDirection.down,
        showCloseIcon: true,
        closeIconColor: Colors.white70,
      ),
    );
  }

  // 2. Standard Dark Mode
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        surface: AppColors.darkSurface,
        error: AppColors.errorRed,
        outline: AppColors.darkBorder,
      ),
      textTheme: AppTypography.createTextTheme(
        AppColors.darkTextPrimary,
        AppColors.darkTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: AppElevation.none,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: AppTypography.headlineMedium(
          color: AppColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: AppElevation.none,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderL,
          side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBackground,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.darkTextSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2C2C2E),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        dismissDirection: DismissDirection.down,
        showCloseIcon: true,
        closeIconColor: Colors.white70,
      ),
    );
  }

  // 3. Clean Light Mode
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        surface: AppColors.lightSurface,
        error: AppColors.errorRed,
        outline: AppColors.lightBorder,
      ),
      textTheme: AppTypography.createTextTheme(
        AppColors.lightTextPrimary,
        AppColors.lightTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: AppElevation.none,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: AppTypography.headlineMedium(
          color: AppColors.lightTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: AppElevation.subtle,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderL,
          side: const BorderSide(color: AppColors.lightBorder, width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.lightTextSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF333333),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        dismissDirection: DismissDirection.down,
        showCloseIcon: true,
        closeIconColor: Colors.white70,
      ),
    );
  }
}
