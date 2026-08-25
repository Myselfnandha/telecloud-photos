import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/sync/upload_telemetry.dart';
import '../../../../shared/theme/app_colors.dart';

class UploadTelemetryCard extends StatelessWidget {
  final UploadTelemetryState telemetry;
  final bool autoBackupEnabled;
  final ValueChanged<bool> onToggleAutoBackup;

  const UploadTelemetryCard({
    super.key,
    required this.telemetry,
    required this.autoBackupEnabled,
    required this.onToggleAutoBackup,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryTextColor = AppColors.textPrimary(context);
    final secondaryTextColor = AppColors.textSecondary(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
        ),
        gradient: isLight
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.darkCard, AppColors.darkSurface],
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  telemetry.isUploading
                      ? Icons.cloud_upload
                      : Icons.cloud_done_rounded,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      telemetry.isUploading
                          ? (telemetry.batchTotalCount > 0
                              ? 'Uploading ${telemetry.batchCurrentIndex} of ${telemetry.batchTotalCount} items...'
                              : 'Uploading to Telegram Cloud...')
                          : !autoBackupEnabled
                              ? 'Auto-Upload Paused'
                              : telemetry.pendingCount > 0
                                  ? '${telemetry.pendingCount} Items in Queue'
                                  : 'Cloud Sync Idle',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      telemetry.isUploading
                          ? '${(telemetry.speedMBps).toStringAsFixed(1)} MB/s • ${(telemetry.overallBatchProgress * 100).toInt()}% overall${telemetry.estimatedTimeRemaining != null ? ' • ${telemetry.estimatedTimeRemaining!.inSeconds}s remaining' : ''}'
                          : '${telemetry.completedCount} photos safely backed up',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Auto Upload Toggle Switch
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch.adaptive(
                    value: autoBackupEnabled,
                    activeTrackColor: AppColors.successGreen,
                    onChanged: onToggleAutoBackup,
                  ),
                  Text(
                    'Auto Upload',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Overall Batch Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: telemetry.isUploading
                  ? telemetry.overallBatchProgress
                  : (telemetry.pendingCount == 0 ? 1.0 : 0.0),
              minHeight: 8,
              backgroundColor: isLight
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                telemetry.isUploading
                    ? AppColors.primaryBlue
                    : AppColors.successGreen,
              ),
            ),
          ),

          if (telemetry.currentItem != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isLight ? AppColors.lightBackground : AppColors.darkCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  if (telemetry.currentItem!.thumbnailPath != null &&
                      File(telemetry.currentItem!.thumbnailPath!).existsSync())
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(telemetry.currentItem!.thumbnailPath!),
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          telemetry.currentItem!.filename,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current file: ${(telemetry.progress * 100).toInt()}% • Original Uncompressed',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      value: telemetry.progress > 0 ? telemetry.progress : null,
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
