import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_initializer.dart';
import 'core/di/providers.dart';
import 'shared/navigation/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/m3e/m3e_theme.dart';
import 'shared/theme/theme_provider.dart';

void main() async {
  final prefs = await AppInitializer.init();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TeleCloudApp(),
    ),
  );
}

class TeleCloudApp extends ConsumerWidget {
  const TeleCloudApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeState = ref.watch(themeModeProvider);

    ThemeData activeTheme;
    ThemeData activeDarkTheme;
    ThemeMode activeMaterialMode;

    switch (themeModeState) {
      case AppThemeMode.light:
        activeTheme = M3ETheme.lightTheme;
        activeDarkTheme = M3ETheme.lightTheme;
        activeMaterialMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        activeTheme = M3ETheme.darkTheme;
        activeDarkTheme = M3ETheme.darkTheme;
        activeMaterialMode = ThemeMode.dark;
        break;
      case AppThemeMode.pureBlack:
        activeTheme = M3ETheme.amoledTheme;
        activeDarkTheme = M3ETheme.amoledTheme;
        activeMaterialMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        activeTheme = M3ETheme.lightTheme;
        activeDarkTheme = M3ETheme.darkTheme;
        activeMaterialMode = ThemeMode.system;
        break;
    }

    return MaterialApp.router(
      title: 'TeleCloud Photos',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      darkTheme: activeDarkTheme,
      themeMode: activeMaterialMode,
      routerConfig: appRouter,
    );
  }
}
