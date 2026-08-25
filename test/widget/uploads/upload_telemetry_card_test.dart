import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/core/sync/upload_telemetry.dart';
import 'package:telecloud_photos/features/uploads/widgets/upload_telemetry_card.dart';

void main() {
  group('UploadTelemetryCard Widget Tests', () {
    testWidgets('1. Renders idle state with auto-backup toggle',
        (tester) async {
      bool toggled = false;
      const telemetry = UploadTelemetryState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UploadTelemetryCard(
              telemetry: telemetry,
              autoBackupEnabled: true,
              onToggleAutoBackup: (val) => toggled = val,
            ),
          ),
        ),
      );

      expect(find.text('Cloud Sync Idle'), findsOneWidget);
      expect(find.text('Auto Upload'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      await tester.tap(find.byType(Switch));
      expect(toggled, isFalse);
    });

    testWidgets('2. Renders active upload metrics when isUploading is true',
        (tester) async {
      final now = DateTime.now();
      final currentItem = MediaItem(
        localId: 'active_1',
        filename: 'IMG_9999.JPG',
        capturedAt: now,
        uploadStatus: UploadStatus.uploading,
        mimeType: 'image/jpeg',
        isFavorite: false,
        isTrashed: false,
      );

      final telemetry = UploadTelemetryState(
        isUploading: true,
        progress: 0.65,
        speedMBps: 3.2,
        estimatedTimeRemaining: const Duration(seconds: 15),
        pendingCount: 4,
        currentItem: currentItem,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UploadTelemetryCard(
              telemetry: telemetry,
              autoBackupEnabled: true,
              onToggleAutoBackup: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Uploading to Telegram Cloud...'), findsOneWidget);
      expect(find.textContaining('3.2 MB/s'), findsOneWidget);
      expect(find.text('IMG_9999.JPG'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
