import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import 'app_theme.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
      return ThemeModeNotifier();
    });

final gridDisplayModeProvider =
    StateNotifierProvider<GridDisplayModeNotifier, GridDisplayMode>((ref) {
      return GridDisplayModeNotifier();
    });

class GridDisplayModeNotifier extends StateNotifier<GridDisplayMode> {
  GridDisplayModeNotifier() : super(GridDisplayMode.squareCropped) {
    _loadMode();
  }

  Future<void> _loadMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString('telecloud_grid_display_mode');
      state = GridDisplayModeExtension.fromString(modeStr);
    } catch (_) {}
  }

  Future<void> setMode(GridDisplayMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('telecloud_grid_display_mode', mode.nameString);
    } catch (_) {}
  }

  void toggleNext() {
    switch (state) {
      case GridDisplayMode.squareCropped:
        setMode(GridDisplayMode.aspectRatioFit);
        break;
      case GridDisplayMode.aspectRatioFit:
        setMode(GridDisplayMode.uncropped);
        break;
      case GridDisplayMode.uncropped:
        setMode(GridDisplayMode.squareCropped);
        break;
    }
  }
}

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.pureBlack) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeStr = prefs.getString(AppConstants.keyAppTheme);
      state = AppThemeModeExtension.fromString(themeStr);
    } catch (_) {}
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAppTheme, mode.nameString);
    } catch (_) {}
  }

  ThemeMode get materialThemeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.pureBlack:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  ThemeData get activeThemeData {
    switch (state) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.pureBlack:
        return AppTheme.pureBlackTheme;
      case AppThemeMode.system:
        return AppTheme.pureBlackTheme; // Default for system dark
    }
  }
}
