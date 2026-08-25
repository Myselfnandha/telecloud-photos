import 'package:flutter/material.dart';

import '../../core/telegram/telegram_download_service.dart';
import '../theme/app_colors.dart';

class DownloadProgressOverlay extends StatelessWidget {
  final DownloadProgress progress;
  final VoidCallback? onCancel;

  const DownloadProgressOverlay({
    super.key,
    required this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress.progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_download_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.isCompleted
                      ? 'Download Complete'
                      : (progress.error != null
                          ? 'Download Error'
                          : 'Downloading Original ($percent%)'),
                  style: TextStyle(
                    color: progress.error != null
                        ? AppColors.errorRed
                        : (progress.isCompleted
                            ? AppColors.successGreen
                            : Colors.white),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (onCancel != null && !progress.isCompleted)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onCancel,
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.isCompleted ? 1.0 : progress.progress,
              minHeight: 5,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress.isCompleted
                    ? AppColors.successGreen
                    : (progress.error != null
                        ? AppColors.errorRed
                        : AppColors.primaryBlue),
              ),
            ),
          ),
          if (progress.speedMBps > 0 && !progress.isCompleted) ...[
            const SizedBox(height: 4),
            Text(
              '${progress.speedMBps.toStringAsFixed(1)} MB/s • ${progress.filename}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
