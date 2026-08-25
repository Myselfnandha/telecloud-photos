import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/features/viewer/widgets/viewer_bottom_bar.dart';
import 'package:telecloud_photos/features/viewer/widgets/viewer_top_bar.dart';

void main() {
  group('Viewer Top & Bottom Bar Widget Tests', () {
    final now = DateTime(2026, 8, 25);
    final cloudItem = MediaItem(
      localId: 'tg_view_1',
      filename: 'cloud_pic.jpg',
      capturedAt: now,
      uploadStatus: UploadStatus.done,
      telegramFileId: '98765',
      mimeType: 'image/jpeg',
      width: 3840,
      height: 2160,
      isFavorite: true,
      isTrashed: false,
    );

    testWidgets('1. ViewerTopBar renders date, resolution and actions',
        (tester) async {
      bool backCalled = false;
      bool favCalled = false;
      bool infoCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ViewerTopBar(
              currentItem: cloudItem,
              isFavorite: true,
              onBack: () => backCalled = true,
              onToggleFavorite: () => favCalled = true,
              onShowInfo: () => infoCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('2026-08-25'), findsOneWidget);
      expect(find.text('4K UHD'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      expect(backCalled, isTrue);

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      expect(favCalled, isTrue);

      await tester.tap(find.byIcon(Icons.info_outline));
      expect(infoCalled, isTrue);
    });

    testWidgets(
        '2. ViewerBottomBar renders action buttons including cloud download',
        (tester) async {
      bool rotateCalled = false;
      bool downloadCalled = false;
      bool deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ViewerBottomBar(
              currentItem: cloudItem,
              onShare: () {},
              onRotate: () => rotateCalled = true,
              onDownload: () => downloadCalled = true,
              onAddToAlbum: () {},
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.rotate_90_degrees_cw_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cloud_download_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_to_photos_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.rotate_90_degrees_cw_rounded));
      expect(rotateCalled, isTrue);

      await tester.tap(find.byIcon(Icons.cloud_download_rounded));
      expect(downloadCalled, isTrue);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleteCalled, isTrue);
    });
  });
}
