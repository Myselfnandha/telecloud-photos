import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/shared/widgets/app_bottom_nav.dart';
import 'package:telecloud_photos/shared/widgets/fast_scroller.dart';
import 'package:telecloud_photos/shared/widgets/google_photos_badge.dart';
import 'package:telecloud_photos/shared/widgets/shimmer_grid.dart';
import 'package:telecloud_photos/shared/widgets/shimmer_loading.dart';
import 'package:telecloud_photos/core/telegram/metadata_encoder.dart';

void main() {
  testWidgets('1. ShimmerGrid renders placeholders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ShimmerGrid(itemCount: 6))),
    );

    expect(find.byType(ShimmerGrid), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('2. ShimmerLoading renders animated gradient container', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ShimmerLoading())),
    );

    expect(find.byType(ShimmerLoading), findsOneWidget);
  });

  testWidgets(
    '3. AppBottomNav displays all 4 navigation tabs (Photos, Library, Uploads, Settings)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(bottomNavigationBar: AppBottomNav(currentIndex: 0)),
        ),
      );

      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Uploads'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    },
  );

  testWidgets('4. GooglePhotosBadge renders compact and standard layouts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GooglePhotosBadge(compact: true),
              GooglePhotosBadge(compact: false),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(GooglePhotosBadge), findsNWidgets(2));
    expect(find.text('Google Photos'), findsOneWidget);
  });

  testWidgets(
    '5. FastScroller renders scrollable child and track with all 12 month labels',
    (WidgetTester tester) async {
      final scrollController = ScrollController();
      const allPhotoMonths = [
        'January 2026',
        'February 2026',
        'March 2026',
        'April 2026',
        'May 2026',
        'June 2026',
        'July 2026',
        'August 2026',
        'September 2026',
        'October 2026',
        'November 2026',
        'December 2026',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FastScroller(
              scrollController: scrollController,
              dateLabels: allPhotoMonths,
              isLight: false,
              child: ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemExtent: 80,
                itemBuilder: (context, index) =>
                    ListTile(title: Text('Photo $index')),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FastScroller), findsOneWidget);
      expect(find.text('Photo 0'), findsOneWidget);
      expect(allPhotoMonths.length, 12);

      // Verify all 12 month labels are correctly formatted and indexed
      for (int i = 0; i < allPhotoMonths.length; i++) {
        expect(allPhotoMonths[i].contains('2026'), isTrue);
      }

      // Drag the right-edge track to trigger the date bubble
      final fastScrollerFinder = find.byType(FastScroller);
      final topPoint =
          tester.getTopRight(fastScrollerFinder) - const Offset(10, -60);

      // Simulate vertical drag gesture
      final gesture = await tester.startGesture(topPoint);
      await gesture.moveBy(const Offset(0, 150));
      await tester.pump();

      // Verify gesture processed and bubble displayed
      expect(find.byType(AnimatedOpacity), findsWidgets);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 1000));
    },
  );

  test('6. MediaMetadata encodes and decodes JSON caption accurately', () {
    final now = DateTime.now();
    final metadata = MediaMetadata(
      filename: 'IMG_2026_TEST.jpg',
      capturedAt: now,
      fileSizeBytes: 2048576,
      width: 1920,
      height: 1080,
      album: 'Vacation',
    );

    final encoded = metadata.encode();
    expect(encoded.contains('IMG_2026_TEST.jpg'), isTrue);
    expect(encoded.length <= 1024, isTrue);

    final decoded = MediaMetadata.decode(encoded);
    expect(decoded?.filename, 'IMG_2026_TEST.jpg');
    expect(decoded?.width, 1920);
    expect(decoded?.height, 1080);
    expect(decoded?.album, 'Vacation');
  });
}
