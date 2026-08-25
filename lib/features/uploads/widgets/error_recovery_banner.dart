import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_colors.dart';

class ErrorRecoveryBanner extends StatelessWidget {
  final int failedCount;
  final VoidCallback onRetryAll;
  final VoidCallback onDismiss;

  const ErrorRecoveryBanner({
    super.key,
    required this.failedCount,
    required this.onRetryAll,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (failedCount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.errorRed.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.errorRed,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$failedCount upload${failedCount == 1 ? '' : 's'} failed',
                    style: const TextStyle(
                      color: AppColors.errorRed,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Network or server issue occurred',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.errorRed.withValues(alpha: 0.15),
                foregroundColor: AppColors.errorRed,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text(
                'Retry All',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                onRetryAll();
              },
            ),
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close, color: Colors.grey, size: 16),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
