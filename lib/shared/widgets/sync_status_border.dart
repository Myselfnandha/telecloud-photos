import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'sync_status_badge.dart';

class SyncStatusBorder extends StatelessWidget {
  final SyncStatus status;
  final Widget child;
  final double borderRadius;
  final bool enabled;

  const SyncStatusBorder({
    super.key,
    required this.status,
    required this.child,
    this.borderRadius = 3.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    Color borderColor;
    switch (status) {
      case SyncStatus.synced:
        borderColor = AppColors.syncedBadge.withValues(alpha: 0.4);
        break;
      case SyncStatus.cloudOnly:
        borderColor = AppColors.cloudOnlyBadge.withValues(alpha: 0.5);
        break;
      case SyncStatus.uploading:
        borderColor = AppColors.uploadingBadge;
        break;
      case SyncStatus.localOnly:
        borderColor = AppColors.localOnlyBadge.withValues(alpha: 0.35);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: status == SyncStatus.uploading ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((borderRadius - 1).clamp(0, 50)),
        child: child,
      ),
    );
  }
}
