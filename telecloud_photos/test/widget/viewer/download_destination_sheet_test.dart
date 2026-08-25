import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/features/viewer/widgets/download_destination_sheet.dart';

void main() {
  group('DownloadDestinationSheet Widget Tests', () {
    testWidgets(
        '1. Renders options and returns DownloadDestination.gallery on tap',
        (tester) async {
      DownloadDestination? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DownloadDestinationSheet.show(context);
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Save Downloaded Media'), findsOneWidget);
      expect(find.text('Save to Device Gallery'), findsOneWidget);
      expect(find.text('Save to Custom Folder'), findsOneWidget);

      await tester.tap(find.text('Save to Device Gallery'));
      await tester.pumpAndSettle();

      expect(result, DownloadDestination.gallery);
    });

    testWidgets(
        '2. Returns DownloadDestination.customFolder on custom folder tap',
        (tester) async {
      DownloadDestination? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DownloadDestinationSheet.show(context);
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to Custom Folder'));
      await tester.pumpAndSettle();

      expect(result, DownloadDestination.customFolder);
    });
  });
}
