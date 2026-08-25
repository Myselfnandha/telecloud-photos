import 'package:go_router/go_router.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/api_setup_screen.dart';
import '../../features/auth/screens/auth_method_screen.dart';
import '../../features/auth/screens/phone_input_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/password_screen.dart';
import '../../features/auth/screens/quick_settings_guide_screen.dart';
import '../../features/auth/screens/login_hub_screen.dart';
import '../../features/auth/screens/qr_login_screen.dart';
import '../../features/auth/screens/oauth_login_screen.dart';
import '../../features/timeline/screens/timeline_screen.dart';
import '../../features/viewer/screens/media_viewer_screen.dart';
import '../../features/uploads/screens/uploads_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/backup_folders_screen.dart';
import '../../features/settings/screens/topic_manager_screen.dart';
import '../../features/settings/screens/sub_screens/appearance_settings_screen.dart';
import '../../features/settings/screens/sub_screens/cloud_migration_settings_screen.dart';
import '../../features/settings/screens/sub_screens/backup_engine_settings_screen.dart';
import '../../features/settings/screens/sub_screens/power_battery_settings_screen.dart';
import '../../features/settings/screens/sub_screens/storage_maintenance_settings_screen.dart';
import '../../features/albums/screens/albums_list_screen.dart';
import '../../features/albums/screens/album_detail_screen.dart';
import '../../features/albums/screens/favorites_screen.dart';
import '../../features/albums/screens/trash_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/library/screens/library_screen.dart';
import '../../features/library/screens/media_collection_screen.dart';
import '../../features/google_photos/screens/google_photos_hub_screen.dart';
import 'page_transitions.dart';
import 'scaffold_with_nav.dart';

final appRouter = GoRouter(
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
