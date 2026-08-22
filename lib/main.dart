import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workmanager/workmanager.dart';
import 'core/utils/telecloud_logger.dart';

import 'shared/theme/app_theme.dart';
import 'shared/theme/theme_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/api_setup_screen.dart';
import 'features/auth/screens/phone_input_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/password_screen.dart';
import 'features/timeline/screens/timeline_screen.dart';
import 'features/viewer/screens/media_viewer_screen.dart';
import 'features/uploads/screens/uploads_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/backup_folders_screen.dart';
import 'features/settings/screens/topic_manager_screen.dart';
import 'features/settings/screens/sub_screens/appearance_settings_screen.dart';
import 'features/settings/screens/sub_screens/cloud_migration_settings_screen.dart';
import 'features/settings/screens/sub_screens/backup_engine_settings_screen.dart';
import 'features/settings/screens/sub_screens/power_battery_settings_screen.dart';
import 'features/settings/screens/sub_screens/storage_maintenance_settings_screen.dart';
import 'features/albums/screens/albums_list_screen.dart';
import 'features/albums/screens/album_detail_screen.dart';
import 'features/albums/screens/favorites_screen.dart';
import 'features/albums/screens/trash_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/library/screens/library_screen.dart';
import 'features/library/screens/media_collection_screen.dart';
import 'features/google_photos/screens/google_photos_hub_screen.dart';
import 'features/google_photos/screens/google_photos_synced_screen.dart';
import 'shared/theme/app_colors.dart';
import 'core/di/providers.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/database/app_database.dart';
import 'core/constants/app_constants.dart';
import 'core/backup/backup_manager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    TeleCloudLogger.backup('[WorkManager] Background task triggered: $task');
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled =
          prefs.getBool(AppConstants.keyAutoBackupEnabled) ??
          AppConstants.defaultAutoBackupEnabled;

      if (!enabled) {
        TeleCloudLogger.backup(
          '[WorkManager] Auto-backup disabled. Terminating worker.',
        );
        return Future.value(true);
      }

      // Check network policy
      final wifiOnly =
          prefs.getBool(AppConstants.keyWifiOnly) ??
          AppConstants.defaultWifiOnly;
      final allowMobileData =
          prefs.getBool(AppConstants.keyAllowMobileData) ??
          AppConstants.defaultAllowMobileData;

      final connectivityResult = await Connectivity().checkConnectivity();
      final isWifi = connectivityResult.contains(ConnectivityResult.wifi);
      final isMobile = connectivityResult.contains(ConnectivityResult.mobile);

      if (wifiOnly && !isWifi) {
        TeleCloudLogger.backup(
          '[WorkManager] Wi-Fi only policy enabled but connected via mobile/other. Terminating.',
        );
        return Future.value(true);
      }

      if (!isWifi && isMobile && !allowMobileData) {
        TeleCloudLogger.backup(
          '[WorkManager] Mobile data backup disabled in settings. Terminating.',
        );
        return Future.value(true);
      }

      // Inspect SQLite Upload Queue
      final db = AppDatabase();
      final pending = await db.mediaDao.getPendingUploads();

      if (pending.isEmpty) {
        TeleCloudLogger.backup(
          '[WorkManager] Upload queue is clean (0 pending). Auto-killing background worker to preserve battery.',
        );
        await db.close();
        return Future.value(true);
      }

      TeleCloudLogger.backup(
        '[WorkManager] Found ${pending.length} pending items in queue. Dispatched for processing.',
      );
      await db.close();
      return Future.value(true);
    } catch (e) {
      TeleCloudLogger.backup(
        '[WorkManager] Background task execution error: $e',
      );
      return Future.value(false);
    }
  });
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final borderColor =
        theme.dividerTheme.color ?? Colors.grey.withValues(alpha: 0.2);

    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(top: BorderSide(color: borderColor, width: 0.5)),
          ),
          child: NavigationBar(
            height: 64,
            backgroundColor: bgColor,
            indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.2),
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.photo_outlined, color: Colors.grey),
                selectedIcon: Icon(Icons.photo, color: AppColors.primaryBlue),
                label: 'Photos',
              ),
              NavigationDestination(
                icon: Icon(Icons.photo_library_outlined, color: Colors.grey),
                selectedIcon: Icon(
                  Icons.photo_library,
                  color: AppColors.primaryBlue,
                ),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.cloud_sync_outlined, color: Colors.grey),
                selectedIcon: Icon(Icons.cloud_sync, color: AppColors.primaryBlue),
                label: 'Uploads',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined, color: Colors.grey),
                selectedIcon: Icon(Icons.settings, color: AppColors.primaryBlue),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const ApiSetupScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const PhoneInputScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) =>
          OtpScreen(phoneNumber: state.extra as String? ?? ''),
    ),
    GoRoute(
      path: '/password',
      builder: (context, state) => const PasswordScreen(),
    ),

    // StatefulShellRoute indexedStack for instant 0ms tab switching
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/timeline',
              builder: (context, state) => const TimelineScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/uploads',
              builder: (context, state) => const UploadsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/collection/:type',
      builder: (context, state) => MediaCollectionScreen(
        categoryKey: state.pathParameters['type'] ?? 'photos',
        categoryTitle: state.extra as String? ?? 'Media Collection',
      ),
    ),
    GoRoute(
      path: '/viewer/:id',
      builder: (context, state) =>
          MediaViewerScreen(mediaId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/albums',
      builder: (context, state) => const AlbumsListScreen(),
    ),
    GoRoute(
      path: '/albums/:id',
      builder: (context, state) => AlbumDetailScreen(
        albumId: int.parse(state.pathParameters['id']!),
        albumName: state.extra as String? ?? 'Album',
      ),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(path: '/trash', builder: (context, state) => const TrashScreen()),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/google-photos',
      builder: (context, state) => const GooglePhotosHubScreen(),
    ),
    GoRoute(
      path: '/google-photos/synced',
      builder: (context, state) => const GooglePhotosSyncedScreen(),
    ),
    GoRoute(
      path: '/settings/folders',
      builder: (context, state) => const BackupFoldersScreen(),
    ),
    GoRoute(
      path: '/backup-folders',
      redirect: (context, state) => '/settings/folders',
    ),
    GoRoute(
      path: '/settings/topics',
      builder: (context, state) => const TopicManagerScreen(),
    ),
    GoRoute(
      path: '/settings/appearance',
      builder: (context, state) => const AppearanceSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/cloud',
      builder: (context, state) => const CloudMigrationSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/backup',
      builder: (context, state) => const BackupEngineSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/power',
      builder: (context, state) => const PowerBatterySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/storage',
      builder: (context, state) => const StorageMaintenanceSettingsScreen(),
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TeleCloudLogger.log('App', 'Starting TeleCloud Photos Application...');

  // Unlock native 90Hz / 120Hz / 144Hz high refresh rate on Android
  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
      TeleCloudLogger.log(
        'DisplayMode',
        'Unlocked 120Hz/90Hz high refresh rate display mode.',
      );
    } catch (e) {
      TeleCloudLogger.log('DisplayMode', 'High refresh rate notice: $e');
    }
  }

  // Optimize image cache to prevent micro-stutters and evictions during fast scrolling
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      1024 * 1024 * 300; // 300MB
  PaintingBinding.instance.imageCache.maximumSize = 1000;

  try {
    await dotenv.load(fileName: ".env");
    TeleCloudLogger.log(
      'App',
      'Loaded .env environment variables successfully.',
    );
  } catch (e) {
    TeleCloudLogger.log(
      'App',
      'No custom .env file detected, using default configuration.',
    );
  }

  final prefs = await SharedPreferences.getInstance();

  try {
    final appDb = AppDatabase();
    await appDb.mediaDao.purgeMockData();
  } catch (e) {
    TeleCloudLogger.log('App', 'Mock data purge notice: $e');
  }

  try {
    await Workmanager().initialize(callbackDispatcher);
    BackupManager().initForegroundTask();
    await BackupManager().scheduleBackgroundWorker();
  } catch (e) {
    TeleCloudLogger.log('App', 'WorkManager init warning: $e');
  }
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
        activeTheme = AppTheme.lightTheme;
        activeDarkTheme = AppTheme.lightTheme;
        activeMaterialMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        activeTheme = AppTheme.darkTheme;
        activeDarkTheme = AppTheme.darkTheme;
        activeMaterialMode = ThemeMode.dark;
        break;
      case AppThemeMode.pureBlack:
        activeTheme = AppTheme.pureBlackTheme;
        activeDarkTheme = AppTheme.pureBlackTheme;
        activeMaterialMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        activeTheme = AppTheme.lightTheme;
        activeDarkTheme = AppTheme.pureBlackTheme;
        activeMaterialMode = ThemeMode.system;
        break;
    }

    return MaterialApp.router(
      title: 'TeleCloud Photos',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      darkTheme: activeDarkTheme,
      themeMode: activeMaterialMode,
      routerConfig: _router,
    );
  }
}
