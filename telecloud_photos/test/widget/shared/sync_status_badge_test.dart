import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';
import 'package:telecloud_photos/shared/widgets/sync_status_badge.dart';

void main() {
  group('SyncStatusBadge Widget Tests', () {
    test('1. SyncStatusBadge.fromMediaItem correctly resolves 4 sync states',
        () {
      final now = DateTime.now();

      final localItem = MediaItem(
        localId: 'local_1',
        filename: 'local.jpg',
        capturedAt: now,
        uploadStatus: UploadStatus.pending,
        mimeType: 'image/jpeg',
        isFavorite: false,
        isTrashed: false,
      );
      expect(
        SyncStatusBadge.fromMediaItem(localItem),
        SyncStatus.localOnly,
      );

      final syncedItem = MediaItem(
        localId: 'synced_1',
        filename: 'synced.jpg',
        capturedAt: now,
        uploadStatus: UploadStatus.done,
        telegramFileId: '123',
        mimeType: 'image/jpeg',
        isFavorite: false,
        isTrashed: false,
      );
      expect(
        SyncStatusBadge.fromMediaItem(syncedItem),
        SyncStatus.synced,
      );

      final cloudItem = MediaItem(
        localId: 'tg_cloud_1',
        filename: 'cloud.jpg',
        capturedAt: now,
        uploadStatus: UploadStatus.done,
        telegramFileId: '456',
        mimeType: 'image/jpeg',
        isFavorite: false,
        isTrashed: false,
      );
      expect(
        SyncStatusBadge.fromMediaItem(cloudItem),
        SyncStatus.cloudOnly,
      );

      expect(
        SyncStatusBadge.fromMediaItem(localItem, isActivelyUploading: true),
        SyncStatus.uploading,
      );
    });

    testWidgets('2. SyncStatusBadge renders in compact mode without error',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusBadge(status: SyncStatus.synced, compact: true),
          ),
        ),
      );

      expect(find.byType(SyncStatusBadge), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('3. SyncStatusBadge renders in non-compact mode with label',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncStatusBadge(status: SyncStatus.localOnly, compact: false),
          ),
        ),
      );

      expect(find.text('On Device'), findsOneWidget);
      expect(find.byIcon(Icons.phone_android_rounded), findsOneWidget);
    });
  });
}
