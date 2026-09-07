import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'm3e_colors.dart';

/// Material 3 Expressive Theme Generator
class M3ETheme {
  M3ETheme._();

  static ThemeData createTheme({
    required ColorScheme scheme,
    bool isAmoled = false,
  }) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      dialogBackgroundColor: scheme.surfaceContainerHigh,

      // App Bar Theme (64dp on surface, titleLarge, 48dp icon buttons)
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: scheme.surfaceContainer,
        centerTitle: false,
        toolbarHeight: 64,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: scheme.surfaceContainer,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: scheme.surfaceContainer,
              ),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(
          color: scheme.onSurface,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 24,
        ),
      ),

      // Navigation Bar (80dp on surfaceContainer, secondaryContainer 64x32 pill indicator)
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: scheme.surfaceContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
              letterSpacing: 0.5,
            );
          }
          return TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.5,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: scheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: scheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),

      // Card Theme (32dp corners, surfaceContainerHighest filled, surfaceContainerLow elevated)
      cardTheme: CardThemeData(
        elevation: 1,
        color: scheme.surfaceContainerLow,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Buttons Theme (Pill shaped, 56dp height where specified)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: const StadiumBorder(),
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          elevation: 0,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerLow,
          foregroundColor: scheme.primary,
          shape: const StadiumBorder(),
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 1,
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant, width: 1),
          shape: const StadiumBorder(),
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Chip Theme (32dp tall, 8dp corners, selected fills secondaryContainer)
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        disabledColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.secondaryContainer,
        secondarySelectedColor: scheme.secondaryContainer,
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: scheme.outlineVariant,
            width: 1,
          ),
        ),
        checkmarkColor: scheme.onSecondaryContainer,
      ),

      // Text Fields (56dp tall, 16dp rounded corners, 2dp primary border on focus)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        hintStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
          color: scheme.onSurfaceVariant,
        ),
        helperStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
      ),

      // Floating Action Button (56dp with 16dp corners, level 3 shadow)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom Sheet Theme (40dp top corners)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
      ),

      // Dialog Theme (40dp corners)
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: scheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: scheme.onInverseSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Roboto', fontSize: 57, fontWeight: FontWeight.w400, color: scheme.onSurface),
        displayMedium: TextStyle(fontFamily: 'Roboto', fontSize: 45, fontWeight: FontWeight.w400, color: scheme.onSurface),
        displaySmall: TextStyle(fontFamily: 'Roboto', fontSize: 36, fontWeight: FontWeight.w400, color: scheme.onSurface),
        headlineLarge: TextStyle(fontFamily: 'Roboto', fontSize: 32, fontWeight: FontWeight.w600, color: scheme.onSurface),
        headlineMedium: TextStyle(fontFamily: 'Roboto', fontSize: 28, fontWeight: FontWeight.w600, color: scheme.onSurface),
        headlineSmall: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w600, color: scheme.onSurface),
        titleLarge: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w600, color: scheme.onSurface),
        titleMedium: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface, letterSpacing: 0.15),
        titleSmall: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface, letterSpacing: 0.1),
        bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w400, color: scheme.onSurface, letterSpacing: 0.5),
        bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant, letterSpacing: 0.25),
        bodySmall: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant, letterSpacing: 0.4),
        labelLarge: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface, letterSpacing: 0.1),
        labelMedium: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant, letterSpacing: 0.5),
        labelSmall: TextStyle(fontFamily: 'Roboto', fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant, letterSpacing: 0.5),
      ),
    );
  }

  static ThemeData get lightTheme => createTheme(scheme: M3EColors.lightScheme);
  static ThemeData get darkTheme => createTheme(scheme: M3EColors.darkScheme);
  static ThemeData get amoledTheme => createTheme(scheme: M3EColors.amoledScheme, isAmoled: true);
}
