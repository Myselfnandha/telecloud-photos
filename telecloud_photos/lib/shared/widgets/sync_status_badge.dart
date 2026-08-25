import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/database/tables/media_table.dart';
import '../theme/app_colors.dart';

enum SyncStatus { localOnly, synced, cloudOnly, uploading }

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;
  final double size;
  final bool compact;

  const SyncStatusBadge({
    super.key,
    required this.status,
    this.size = 14,
    this.compact = true,
  });

  static SyncStatus fromMediaItem(
    MediaItem item, {
    bool isActivelyUploading = false,
  }) {
    if (isActivelyUploading || item.uploadStatus == UploadStatus.uploading) {
      return SyncStatus.uploading;
    }
    if (item.uploadStatus == UploadStatus.done) {
      if (item.localId.startsWith('tg_')) {
        return SyncStatus.cloudOnly;
      }
      return SyncStatus.synced;
    }
    return SyncStatus.localOnly;
  }

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData iconData;
    String label;

    switch (status) {
      case SyncStatus.synced:
        badgeColor = AppColors.syncedBadge;
        iconData = Icons.cloud_done_rounded;
        label = 'Synced';
        break;
      case SyncStatus.cloudOnly:
        badgeColor = AppColors.cloudOnlyBadge;
        iconData = Icons.cloud_queue_rounded;
        label = 'Cloud Only';
        break;
      case SyncStatus.uploading:
        badgeColor = AppColors.uploadingBadge;
        iconData = Icons.cloud_upload_rounded;
        label = 'Uploading';
        break;
      case SyncStatus.localOnly:
        badgeColor = AppColors.localOnlyBadge;
        iconData = Icons.phone_android_rounded;
        label = 'On Device';
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: status == SyncStatus.uploading
            ? SizedBox(
                width: size * 0.8,
                height: size * 0.8,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: badgeColor,
                ),
              )
            : Icon(
                iconData,
                color: badgeColor,
                size: size,
              ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: badgeColor, size: size),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
