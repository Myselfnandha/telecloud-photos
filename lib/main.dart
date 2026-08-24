import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workmanager/workmanager.dart';
import 'core/utils/telecloud_logger.dart';

import 'shared/theme/app_theme.dart';
import 'shared/theme/theme_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_hub_screen.dart';
import 'features/auth/screens/qr_login_screen.dart';
import 'features/auth/screens/oauth_login_screen.dart';
import 'features/auth/screens/api_setup_screen.dart';
import 'features/auth/screens/auth_method_screen.dart';
import 'features/auth/screens/phone_input_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/password_screen.dart';
import 'features/auth/screens/quick_settings_guide_screen.dart';
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
import 'shared/widgets/app_bottom_nav.dart';
import 'shared/navigation/page_transitions.dart';
import 'features/auth/screens/onboarding_screen.dart';
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
        return true;
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
        return true;
      }

      if (!isWifi && isMobile && !allowMobileData) {
        TeleCloudLogger.backup(
          '[WorkManager] Mobile data backup disabled in settings. Terminating.',
        );
        return true;
      }

      // Inspect SQLite Upload Queue
      final db = AppDatabase();
      final pending = await db.mediaDao.getPendingUploads();

      if (pending.isEmpty) {
        TeleCloudLogger.backup(
          '[WorkManager] Upload queue is clean (0 pending). Auto-killing background worker to preserve battery.',
        );
        await db.close();
        return true;
      }

      TeleCloudLogger.backup(
        '[WorkManager] Found ${pending.length} pending items in queue. Dispatched for processing.',
      );
      await db.close();
      return true;
    } catch (e) {
      TeleCloudLogger.backup(
        '[WorkManager] Background task execution error: $e',
      );
      return false;
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
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: AppBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
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
      path: '/onboarding',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/setup',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const ApiSetupScreen(),
      ),
    ),
    GoRoute(
      path: '/auth-method',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const AuthMethodScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const PhoneInputScreen(),
      ),
    ),
    GoRoute(
      path: '/otp',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: OtpScreen(phoneNumber: state.extra as String? ?? ''),
      ),
    ),
    GoRoute(
      path: '/password',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const PasswordScreen(),
      ),
    ),
    GoRoute(
      path: '/quick-settings',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const QuickSettingsGuideScreen(),
      ),
    ),
    GoRoute(
      path: '/login-hub',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const LoginHubScreen(),
      ),
    ),
    GoRoute(
      path: '/login-qr',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const QrLoginScreen(),
      ),
    ),
    GoRoute(
      path: '/login-oauth',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const OAuthLoginScreen(),
      ),
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
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: MediaCollectionScreen(
          categoryKey: state.pathParameters['type'] ?? 'photos',
          categoryTitle: state.extra as String? ?? 'Media Collection',
        ),
      ),
    ),
    GoRoute(
      path: '/viewer/:id',
      pageBuilder: (context, state) => buildViewerTransitionPage(
        context: context,
        state: state,
        child: MediaViewerScreen(mediaId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/albums',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const AlbumsListScreen(),
      ),
    ),
    GoRoute(
      path: '/albums/:id',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: AlbumDetailScreen(
          albumId: int.parse(state.pathParameters['id']!),
          albumName: state.extra as String? ?? 'Album',
        ),
      ),
    ),
    GoRoute(
      path: '/favorites',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const FavoritesScreen(),
      ),
    ),
    GoRoute(
      path: '/trash',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const TrashScreen(),
      ),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const SearchScreen(),
      ),
    ),
    GoRoute(
      path: '/google-photos',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const GooglePhotosHubScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/folders',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const BackupFoldersScreen(),
      ),
    ),
    GoRoute(
      path: '/backup-folders',
      redirect: (context, state) => '/settings/folders',
    ),
    GoRoute(
      path: '/settings/topics',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const TopicManagerScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/appearance',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const AppearanceSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/cloud',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const CloudMigrationSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/backup',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const BackupEngineSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/power',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const PowerBatterySettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/storage',
      pageBuilder: (context, state) => buildTransitionPage(
        context: context,
        state: state,
        child: const StorageMaintenanceSettingsScreen(),
      ),
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
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

  // Load saved custom credentials from secure storage / .env
  await AppConstants.hasSavedCredentials();

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
