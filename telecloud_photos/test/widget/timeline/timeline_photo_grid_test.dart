import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/features/timeline/controllers/timeline_zoom_controller.dart';
import 'package:telecloud_photos/features/timeline/widgets/timeline_photo_grid.dart';

void main() {
  group('TimelinePhotoGrid Widget Tests', () {
    testWidgets('1. Renders items and triggers onTap & onLongPress',
        (tester) async {
      final now = DateTime.now();
      final items = [
        MediaItem(
          localId: 'tg_grid_1',
          filename: 'p1.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.done,
          mimeType: 'image/jpeg',
          isFavorite: false,
          isTrashed: false,
        ),
        MediaItem(
          localId: 'local_grid_2',
          filename: 'p2.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.pending,
          mimeType: 'image/jpeg',
          isFavorite: true,
          isTrashed: false,
        ),
      ];

      MediaItem? tappedItem;
      MediaItem? longPressedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TimelinePhotoGrid(
                items: items,
                tier: TimelineTier.dailyGrid,
                isSelectionMode: false,
                selectedIds: const {},
                onItemTap: (item) => tappedItem = item,
                onItemLongPress: (item) => longPressedItem = item,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MediaTile), findsNWidgets(2));

      await tester.tap(find.byType(MediaTile).first);
      expect(tappedItem?.localId, 'tg_grid_1');

      await tester.longPress(find.byType(MediaTile).last);
      expect(longPressedItem?.localId, 'local_grid_2');
    });

    testWidgets('2. Displays selection checkmarks when isSelectionMode is true',
        (tester) async {
      final now = DateTime.now();
      final items = [
        MediaItem(
          localId: 'item_sel_1',
          filename: 'sel1.jpg',
          capturedAt: now,
          uploadStatus: UploadStatus.done,
          mimeType: 'image/jpeg',
          isFavorite: false,
          isTrashed: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TimelinePhotoGrid(
                items: items,
                tier: TimelineTier.dailyGrid,
                isSelectionMode: true,
                selectedIds: const {'item_sel_1'},
                onItemTap: (_) {},
                onItemLongPress: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
