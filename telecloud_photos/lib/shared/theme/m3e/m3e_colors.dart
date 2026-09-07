import 'package:flutter/material.dart';

/// Material 3 Expressive Color Palette (Blue Theme)
/// Reference: Google Material 3 Expressive Design System
class M3EColors {
  M3EColors._();

  // ==========================================
  // Light Color Scheme Tokens
  // ==========================================
  static const Color lightPrimary = Color(0xFF0B57D0);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFD3E3FD);
  static const Color lightOnPrimaryContainer = Color(0xFF041E49);

  static const Color lightSecondary = Color(0xFF5A5C7C);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFDCE2F9);
  static const Color lightOnSecondaryContainer = Color(0xFF131C2B);

  static const Color lightTertiary = Color(0xFF7D5260);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFFFFD8EE);
  static const Color lightOnTertiaryContainer = Color(0xFF2E1125);

  static const Color lightSurface = Color(0xFFFAF9FD);
  static const Color lightSurfaceContainerLow = Color(0xFFF3F3FA);
  static const Color lightSurfaceContainer = Color(0xFFEEEDF3);
  static const Color lightSurfaceContainerHigh = Color(0xFFE9E8EF);
  static const Color lightSurfaceContainerHighest = Color(0xFFE3E2E6);

  static const Color lightOnSurface = Color(0xFF1B1B1F);
  static const Color lightOnSurfaceVariant = Color(0xFF44474E);
  static const Color lightOutline = Color(0xFF74777F);
  static const Color lightOutlineVariant = Color(0xFFC4C6D0);

  static const Color lightInverseSurface = Color(0xFF303034);
  static const Color lightInverseOnSurface = Color(0xFFF2F0F4);
  static const Color lightInversePrimary = Color(0xFFA8C7FA);

  static const Color lightError = Color(0xFFB3261E);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFF9DEDC);
  static const Color lightOnErrorContainer = Color(0xFF410E0B);

  // ==========================================
  // Dark Color Scheme Tokens
  // ==========================================
  static const Color darkPrimary = Color(0xFFC0C2FD);
  static const Color darkOnPrimary = Color(0xFF042C71);
  static const Color darkPrimaryContainer = Color(0xFF04409F);
  static const Color darkOnPrimaryContainer = Color(0xFFE0E0FC);

  static const Color darkSecondary = Color(0xFFC3C3E9);
  static const Color darkOnSecondary = Color(0xFF2C2E4B);
  static const Color darkSecondaryContainer = Color(0xFF424463);
  static const Color darkOnSecondaryContainer = Color(0xFFE0E0FE);

  static const Color darkTertiary = Color(0xFFEFB8C8);
  static const Color darkOnTertiary = Color(0xFF492532);
  static const Color darkTertiaryContainer = Color(0xFF6E334E);
  static const Color darkOnTertiaryContainer = Color(0xFFFFD8E7);

  static const Color darkSurface = Color(0xFF131317);
  static const Color amoledSurface = Color(0xFF000000);
  static const Color darkSurfaceContainerLow = Color(0xFF1B1B1F);
  static const Color darkSurfaceContainer = Color(0xFF1F1F23);
  static const Color darkSurfaceContainerHigh = Color(0xFF2A2A2E);
  static const Color darkSurfaceContainerHighest = Color(0xFF343439);

  static const Color darkOnSurface = Color(0xFFE2E2E8);
  static const Color darkOnSurfaceVariant = Color(0xFFC6C5D2);
  static const Color darkOutline = Color(0xFF90909C);
  static const Color darkOutlineVariant = Color(0xFF464651);

  static const Color darkInverseSurface = Color(0xFFE2E2E8);
  static const Color darkInverseOnSurface = Color(0xFF303034);
  static const Color darkInversePrimary = Color(0xFF3757BA);

  static const Color darkError = Color(0xFFF2B8B5);
  static const Color darkOnError = Color(0xFF601410);
  static const Color darkErrorContainer = Color(0xFF8C1D18);
  static const Color darkOnErrorContainer = Color(0xFFF9DEDC);

  // ==========================================
  // Scheme Builders
  // ==========================================
  static ColorScheme get lightScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: lightPrimary,
        onPrimary: lightOnPrimary,
        primaryContainer: lightPrimaryContainer,
        onPrimaryContainer: lightOnPrimaryContainer,
        secondary: lightSecondary,
        onSecondary: lightOnSecondary,
        secondaryContainer: lightSecondaryContainer,
        onSecondaryContainer: lightOnSecondaryContainer,
        tertiary: lightTertiary,
        onTertiary: lightOnTertiary,
        tertiaryContainer: lightTertiaryContainer,
        onTertiaryContainer: lightOnTertiaryContainer,
        error: lightError,
        onError: lightOnError,
        errorContainer: lightErrorContainer,
        onErrorContainer: lightOnErrorContainer,
        surface: lightSurface,
        onSurface: lightOnSurface,
        onSurfaceVariant: lightOnSurfaceVariant,
        outline: lightOutline,
        outlineVariant: lightOutlineVariant,
        surfaceContainerLow: lightSurfaceContainerLow,
        surfaceContainer: lightSurfaceContainer,
        surfaceContainerHigh: lightSurfaceContainerHigh,
        surfaceContainerHighest: lightSurfaceContainerHighest,
        inverseSurface: lightInverseSurface,
        onInverseSurface: lightInverseOnSurface,
        inversePrimary: lightInversePrimary,
      );

  static ColorScheme get darkScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        primaryContainer: darkPrimaryContainer,
        onPrimaryContainer: darkOnPrimaryContainer,
        secondary: darkSecondary,
        onSecondary: darkOnSecondary,
        secondaryContainer: darkSecondaryContainer,
        onSecondaryContainer: darkOnSecondaryContainer,
        tertiary: darkTertiary,
        onTertiary: darkOnTertiary,
        tertiaryContainer: darkTertiaryContainer,
        onTertiaryContainer: darkOnTertiaryContainer,
        error: darkError,
        onError: darkOnError,
        errorContainer: darkErrorContainer,
        onErrorContainer: darkOnErrorContainer,
        surface: darkSurface,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
        outline: darkOutline,
        outlineVariant: darkOutlineVariant,
        surfaceContainerLow: darkSurfaceContainerLow,
        surfaceContainer: darkSurfaceContainer,
        surfaceContainerHigh: darkSurfaceContainerHigh,
        surfaceContainerHighest: darkSurfaceContainerHighest,
        inverseSurface: darkInverseSurface,
        onInverseSurface: darkInverseOnSurface,
        inversePrimary: darkInversePrimary,
      );

  static ColorScheme get amoledScheme => darkScheme.copyWith(
        surface: amoledSurface,
        surfaceContainerLow: const Color(0xFF0D0D11),
        surfaceContainer: const Color(0xFF141418),
        surfaceContainerHigh: const Color(0xFF1C1C22),
        surfaceContainerHighest: const Color(0xFF26262D),
      );
}
