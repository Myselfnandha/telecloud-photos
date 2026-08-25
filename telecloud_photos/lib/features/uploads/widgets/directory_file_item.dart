import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';

class DirectoryFileItem extends StatelessWidget {
  final MediaItem item;
  final bool isUploading;
  final bool isDone;
  final bool isFailed;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback? onRetry;

  const DirectoryFileItem({
    super.key,
    required this.item,
    required this.isUploading,
    required this.isDone,
    required this.isFailed,
    required this.isLast,
    required this.onTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryTextColor = AppColors.textPrimary(context);
    final secondaryTextColor = AppColors.textSecondary(context);

    final thumbPath = item.thumbnailPath;
    final hasThumb = thumbPath != null && thumbPath.isNotEmpty;
    final sizeMb = item.fileSizeBytes != null
        ? (item.fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)
        : '0.0';

    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Tree Branch Connector
          Text(
            isLast ? '└─ ' : '├─ ',
            style: TextStyle(
              color: isLight ? Colors.grey.shade400 : Colors.grey.shade600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Hero(
              tag: 'media_${item.localId}',
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isLight ? Colors.grey.shade200 : Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: hasThumb
                      ? Image.file(
                          File(thumbPath),
                          fit: BoxFit.cover,
                          cacheWidth: 80,
                          cacheHeight: 80,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image,
                            size: 18,
                            color: isLight
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        )
                      : Icon(
                          Icons.image,
                          size: 18,
                          color: isLight
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.filename,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$sizeMb MB • ${item.capturedAt.toLocal().toString().split('.')[0]}',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isDone)
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppColors.successGreen,
            )
          else if (isUploading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryBlue,
              ),
            )
          else if (isFailed)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onRetry != null)
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: AppColors.errorRed,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Retry upload',
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onRetry!();
                    },
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: AppColors.errorRed,
                ),
              ],
            )
          else
            Text(
              'Pending',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );

    if (isFailed && onRetry != null) {
      return Dismissible(
        key: Key('retry_${item.localId}'),
        direction: DismissDirection.startToEnd,
        background: Container(
          color: AppColors.primaryBlue.withValues(alpha: 0.2),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 12),
          child: const Row(
            children: [
              Icon(Icons.refresh_rounded,
                  color: AppColors.primaryBlue, size: 16),
              SizedBox(width: 4),
              Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          onRetry!();
          return false;
        },
        child: rowContent,
      );
    }

    return rowContent;
  }
}
