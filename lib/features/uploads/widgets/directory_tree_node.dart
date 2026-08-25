import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/media_table.dart';
import '../../../../core/sync/upload_telemetry.dart';
import '../../../../shared/theme/app_colors.dart';
import 'directory_file_item.dart';

class DirectoryTreeNode extends StatelessWidget {
  final String dirPath;
  final String leafFolderName;
  final List<MediaItem> dirItems;
  final bool isExpanded;
  final bool isDirActive;
  final bool isDirAllDone;
  final int pendingInDir;
  final int failedInDir;
  final String dirTotalMb;
  final UploadTelemetryState telemetry;
  final VoidCallback onToggleExpand;
  final VoidCallback onUploadFolder;
  final void Function(MediaItem item) onItemTap;
  final void Function(MediaItem item)? onItemRetry;

  const DirectoryTreeNode({
    super.key,
    required this.dirPath,
    required this.leafFolderName,
    required this.dirItems,
    required this.isExpanded,
    required this.isDirActive,
    required this.isDirAllDone,
    required this.pendingInDir,
    required this.failedInDir,
    required this.dirTotalMb,
    required this.telemetry,
    required this.onToggleExpand,
    required this.onUploadFolder,
    required this.onItemTap,
    this.onItemRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryTextColor = AppColors.textPrimary(context);
    final secondaryTextColor = AppColors.textSecondary(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isDirActive ? AppColors.primaryBlue : AppColors.border(context),
          width: isDirActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folder Directory Tree Node Header
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.selectionClick();
              onToggleExpand();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: secondaryTextColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.folder_open_rounded
                        : Icons.folder_rounded,
                    color: isDirActive
                        ? AppColors.primaryBlue
                        : (isDirAllDone
                            ? AppColors.successGreen
                            : AppColors.primaryBlue),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leafFolderName,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dirPath • ${dirItems.length} items • $dirTotalMb MB',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isDirAllDone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 11,
                            color: AppColors.successGreen,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Synced',
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isDirActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Uploading',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.grey.shade200
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            failedInDir > 0
                                ? '$failedInDir Failed • $pendingInDir Pending'
                                : '$pendingInDir Pending',
                            style: TextStyle(
                              color: failedInDir > 0
                                  ? AppColors.errorRed
                                  : secondaryTextColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 13,
                          ),
                          label: const Text(
                            'Upload',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onUploadFolder();
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Active progress indicator on directory node
          if (isDirActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: telemetry.progress > 0 ? telemetry.progress : null,
                  minHeight: 3,
                  backgroundColor: isLight
                      ? Colors.black12
                      : Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
            ),

          // Indented Media Items in Tree View
          if (isExpanded) ...[
            Divider(
              height: 1,
              color: AppColors.border(context),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 12, 10),
              itemCount: dirItems.length,
              separatorBuilder: (context, idx) => Divider(
                height: 1,
                indent: 28,
                color: isLight
                    ? AppColors.lightBackground
                    : Colors.white.withValues(alpha: 0.03),
              ),
              itemBuilder: (context, itemIdx) {
                final item = dirItems[itemIdx];
                final isUploading =
                    item.uploadStatus == UploadStatus.uploading ||
                        (telemetry.currentItem?.localId == item.localId &&
                            telemetry.isUploading);
                final isDone = item.uploadStatus == UploadStatus.done;
                final isFailed = item.uploadStatus == UploadStatus.failed;
                final isLast = itemIdx == dirItems.length - 1;

                return DirectoryFileItem(
                  item: item,
                  isUploading: isUploading,
                  isDone: isDone,
                  isFailed: isFailed,
                  isLast: isLast,
                  onTap: () => onItemTap(item),
                  onRetry: isFailed && onItemRetry != null
                      ? () => onItemRetry!(item)
                      : null,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
