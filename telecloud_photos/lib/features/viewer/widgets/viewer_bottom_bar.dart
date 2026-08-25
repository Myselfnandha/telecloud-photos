import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_icons.dart';

class ViewerBottomBar extends StatelessWidget {
  final MediaItem? currentItem;
  final VoidCallback onShare;
  final VoidCallback onRotate;
  final VoidCallback onDownload;
  final VoidCallback onAddToAlbum;
  final VoidCallback onDelete;

  const ViewerBottomBar({
    super.key,
    required this.currentItem,
    required this.onShare,
    required this.onRotate,
    required this.onDownload,
    required this.onAddToAlbum,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCloudMedia = currentItem != null &&
        (currentItem!.localId.startsWith('tg_') ||
            currentItem!.telegramFileId != null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        border: const Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Share
            IconButton(
              tooltip: 'Share',
              icon: const Icon(
                Icons.ios_share_rounded,
                color: Colors.white,
                size: AppIcons.m,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                onShare();
              },
            ),

            // Rotate 90° Lossless
            IconButton(
              tooltip: 'Rotate 90°',
              icon: const Icon(
                Icons.rotate_90_degrees_cw_rounded,
                color: Colors.white,
                size: AppIcons.m,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                onRotate();
              },
            ),

            // Download original from Telegram Cloud (Feature 4)
            if (isCloudMedia)
              IconButton(
                tooltip: 'Download Original',
                icon: const Icon(
                  Icons.cloud_download_rounded,
                  color: AppColors.primaryBlue,
                  size: AppIcons.m,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onDownload();
                },
              ),

            // Add to Album
            IconButton(
              tooltip: 'Add to Album',
              icon: const Icon(
                Icons.add_to_photos_rounded,
                color: Colors.white,
                size: AppIcons.m,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                onAddToAlbum();
              },
            ),

            // Move to Trash
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.systemRed,
                size: AppIcons.m,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
