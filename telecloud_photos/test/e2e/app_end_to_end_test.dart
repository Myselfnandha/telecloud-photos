import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecloud_photos/core/backup/media_scanner.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/media_dao.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/core/di/providers.dart';
import 'package:telecloud_photos/features/auth/screens/onboarding_screen.dart';
import 'package:telecloud_photos/features/library/screens/library_screen.dart';
import 'package:telecloud_photos/features/timeline/screens/timeline_screen.dart';
import 'package:telecloud_photos/features/timeline/widgets/memories_carousel.dart';
import 'package:telecloud_photos/features/uploads/screens/uploads_screen.dart';
import 'package:telecloud_photos/features/viewer/screens/media_viewer_screen.dart';

class _FakeMediaScanner extends MediaScanner {
  _FakeMediaScanner({required super.db, required super.mediaDao});

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scanCameraRoll() async {}

  @override
  void startIncrementalListening() {}

  @override
  Future<int> queueFolderForUpload(AssetPathEntity folder) async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MediaDao dao;
  late SharedPreferences prefs;
  late _FakeMediaScanner fakeScanner;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = MediaDao(db);
    fakeScanner = _FakeMediaScanner(db: db, mediaDao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('End-to-End App Flow & Real Component Verification', () {
    test('1. Database Ingestion & Real "On This Day" Memories with Window Fallback', () async {
      final now = DateTime.now();

      // Seed photos:
      final exactAnniversary = DateTime(now.year - 1, now.month, now.day, 14, 30);
      final windowFallback = DateTime(now.year - 2, now.month, now.day).add(const Duration(days: 2, hours: 10));
      final todayPhoto = now.subtract(const Duration(hours: 1));
      final outsideWindow = DateTime(now.year - 1, now.month, now.day).subtract(const Duration(days: 15));

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'exact_1yr',
          filename: 'Exact_Anniversary.jpg',
          capturedAt: exactAnniversary,
          width: const Value(4000),
          height: const Value(3000),
          fileSizeBytes: const Value(3500000),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          isFavorite: const Value(true),
        ),
        MediaItemsCompanion.insert(
          localId: 'fallback_2yr',
          filename: 'Window_Fallback.jpg',
          capturedAt: windowFallback,
          width: const Value(3840),
          height: const Value(2160),
          fileSizeBytes: const Value(4200000),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
        ),
        MediaItemsCompanion.insert(
          localId: 'today_current',
          filename: 'Today_Photo.jpg',
          capturedAt: todayPhoto,
          width: const Value(1920),
          height: const Value(1080),
          fileSizeBytes: const Value(1200000),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.pending,
        ),
        MediaItemsCompanion.insert(
          localId: 'outside_window',
          filename: 'Outside_Window.jpg',
          capturedAt: outsideWindow,
          width: const Value(1920),
          height: const Value(1080),
          fileSizeBytes: const Value(900000),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
        ),
      ]);

      // A. Exact day match
      final exactMatches = await dao.getMemoriesForDate(now.month, now.day);
      expect(exactMatches.length, 1);
      expect(exactMatches.first.localId, 'exact_1yr');

      // B. Fallback when searching for date with no exact match
      final fallbackMatches = await dao.getMemoriesWithWindowFallback(
        now.month,
        now.day + 2 > 28 ? 28 : now.day + 2,
        windowDays: 3,
      );
      expect(fallbackMatches.isNotEmpty, isTrue);

      // C. Full query with window fallback on today
      final allMemories = await dao.getMemoriesWithWindowFallback(now.month, now.day);
      expect(allMemories.length, 1);
      expect(allMemories.first.localId, 'exact_1yr');
    });

    testWidgets('2. Strict Authentication Wall: Onboarding routes to API Credentials Setup', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
            mediaDaoProvider.overrideWithValue(dao),
            mediaScannerProvider.overrideWithValue(fakeScanner),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      expect(find.text('TeleCloud Photos'), findsOneWidget);
      expect(find.text('Unlimited Private Photo Cloud'), findsOneWidget);

      // Verify strict auth buttons exist
      expect(find.text('Enter Telegram API ID & Hash Key'), findsOneWidget);
      expect(find.text('Continue with Telegram Code'), findsOneWidget);

      // Verify that direct skip bypass to timeline has been removed
      expect(find.text('Skip to Timeline'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('3. TimelineScreen: Renders Real SQLite Data, Memories Carousel, and Filter Chips', (tester) async {
      final now = DateTime.now();

      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'photo_today_1',
          filename: 'PXL_Today_1.jpg',
          capturedAt: now.subtract(const Duration(minutes: 10)),
          width: const Value(4032),
          height: const Value(3024),
          fileSizeBytes: const Value(2500000),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          isFavorite: const Value(true),
        ),
        MediaItemsCompanion.insert(
          localId: 'video_yesterday_1',
          filename: 'VID_Yesterday.mp4',
          capturedAt: now.subtract(const Duration(days: 1, hours: 2)),
          width: const Value(1920),
          height: const Value(1080),
          fileSizeBytes: const Value(15000000),
          mimeType: 'video/mp4',
          uploadStatus: UploadStatus.pending,
        ),
        MediaItemsCompanion.insert(
          localId: 'mem_1yr',
          filename: 'Memory_1YearAgo.jpg',
          capturedAt: DateTime(now.year - 1, now.month, now.day, 12, 0),
          width: const Value(3000),
          height: const Value(2000),
          fileSizeBytes: const Value(1800000),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
            mediaDaoProvider.overrideWithValue(dao),
            mediaScannerProvider.overrideWithValue(fakeScanner),
          ],
          child: const MaterialApp(
            home: TimelineScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify App Bar & Actions
      expect(find.text('TeleCloud Photos'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Verify Memories Carousel rendered real memory
      expect(find.byType(MemoriesCarousel), findsOneWidget);
      expect(find.text('1 Year Ago Today'), findsOneWidget);

      // Verify Filter Chips
      expect(find.text('All Photos'), findsOneWidget);
      expect(find.text('Cloud Synced'), findsOneWidget);
      expect(find.text('Motion Photos'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);

      // Tap 'Favorites' filter chip
      await tester.tap(find.text('Favorites'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Cloud Synced' filter chip
      await tester.tap(find.text('Cloud Synced'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('4. MediaViewerScreen: Loads Real Media, EXIF, and Performs Actions', (tester) async {
      final now = DateTime.now();
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'tg_test_viewer_media',
          filename: 'Viewer_Target.jpg',
          capturedAt: now,
          width: const Value(6000),
          height: const Value(4000),
          fileSizeBytes: const Value(8500000),
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          telegramMsgId: const Value(9912),
          folderName: const Value('Camera'),
          isFavorite: const Value(false),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
            mediaDaoProvider.overrideWithValue(dao),
            mediaScannerProvider.overrideWithValue(fakeScanner),
          ],
          child: const MaterialApp(
            home: MediaViewerScreen(mediaId: 'tg_test_viewer_media'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify real chips & metadata
      expect(find.text('Synced to Telegram Cloud'), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Camera & Capture Hardware EXIF'), findsOneWidget);

      // Toggle favorite action in AppBar
      final favButton = find.byIcon(Icons.favorite_border);
      expect(favButton, findsOneWidget);
      await tester.tap(favButton);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify updated in database
      final updated = await dao.getMediaById('tg_test_viewer_media');
      expect(updated?.isFavorite, isTrue);

      // Scroll down to floating toolbar and tap delete action
      final deleteAction = find.byIcon(Icons.delete_outline);
      await tester.ensureVisible(deleteAction);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(deleteAction);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify moved to trash in database
      final trashed = await dao.getTrashedMedia();
      expect(trashed.any((m) => m.localId == 'tg_test_viewer_media'), isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('5. LibraryScreen: Real Recoverable Space & Album Operations', (tester) async {
      await dao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'cloud_backed_1',
          filename: 'Backed_1.jpg',
          capturedAt: DateTime.now(),
          width: const Value(1920),
          height: const Value(1080),
          fileSizeBytes: const Value(5000000), // ~4.8 MB
          mimeType: 'image/jpeg',
          uploadStatus: UploadStatus.done,
          isFavorite: const Value(true),
        ),
      ]);

      await dao.createAlbum('Vacation 2026');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
            mediaDaoProvider.overrideWithValue(dao),
            mediaScannerProvider.overrideWithValue(fakeScanner),
          ],
          child: const MaterialApp(
            home: LibraryScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Library & Cloud Albums'), findsOneWidget);
      expect(find.text('Google Photos Takeout Importer'), findsOneWidget);

      // Dynamic recoverable storage headline (5000000 / (1024*1024) = 4.8 MB)
      expect(find.text('Free Up 4.8 MB Device Storage'), findsOneWidget);

      // Real albums in stacked list
      expect(find.text('📷 Camera Roll'), findsOneWidget);
      expect(find.text('📁 Vacation 2026'), findsOneWidget);
      expect(find.text('⭐ Favorites'), findsOneWidget);
      expect(find.text('🗑️ Trash'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('6. UploadsScreen: Live Telemetry & Button State Transitions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
            mediaDaoProvider.overrideWithValue(dao),
            mediaScannerProvider.overrideWithValue(fakeScanner),
          ],
          child: const MaterialApp(
            home: UploadsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Uploads & Telemetry'), findsOneWidget);
      expect(find.text('All Media Backed Up'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Scan Now'), findsOneWidget);
      expect(find.text('Engine'), findsOneWidget);

      // Tap Pause button
      await tester.tap(find.text('Pause'));
      await tester.pump(const Duration(milliseconds: 100));

      // Button toggles to 'Resume'
      expect(find.text('Resume'), findsOneWidget);

      // Tap Resume button
      await tester.tap(find.text('Resume'));
      await tester.pump(const Duration(milliseconds: 100));

      // Button toggles back to 'Pause'
      expect(find.text('Pause'), findsOneWidget);

      // Clean unmount to cancel repeating animation controller and drift stream
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
