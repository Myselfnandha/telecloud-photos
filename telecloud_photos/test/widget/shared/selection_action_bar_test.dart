import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/shared/widgets/selection_action_bar.dart';

void main() {
  group('SelectionActionBar Widget Tests', () {
    testWidgets('1. Renders selected count and all 6 action buttons',
        (tester) async {
      bool deleteCalled = false;
      bool shareCalled = false;
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionActionBar(
              selectedCount: 5,
              onShare: () => shareCalled = true,
              onAddToAlbum: () {},
              onDownload: () {},
              onToggleFavorite: () {},
              onExport: () {},
              onDelete: () => deleteCalled = true,
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_to_photos_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cloud_download_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.drive_folder_upload_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleteCalled, isTrue);

      await tester.tap(find.byIcon(Icons.ios_share_rounded));
      expect(shareCalled, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(cancelCalled, isTrue);
    });
  });
}
