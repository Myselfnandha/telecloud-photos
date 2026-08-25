import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class SelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onShare;
  final VoidCallback onAddToAlbum;
  final VoidCallback onDownload;
  final VoidCallback onToggleFavorite;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const SelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.onShare,
    required this.onAddToAlbum,
    required this.onDownload,
    required this.onToggleFavorite,
    required this.onExport,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.96)
            : const Color(0xFF1C1C1E).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLight ? Colors.black12 : Colors.white12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Selected count indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            color: AppColors.primaryBlue,
            iconSize: 21,
            tooltip: 'Share',
            onPressed: () {
              HapticFeedback.selectionClick();
              onShare();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_to_photos_rounded),
            color: AppColors.primaryBlue,
            iconSize: 21,
            tooltip: 'Add to Album',
            onPressed: () {
              HapticFeedback.selectionClick();
              onAddToAlbum();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download_rounded),
            color: AppColors.primaryBlue,
            iconSize: 21,
            tooltip: 'Download Original',
            onPressed: () {
              HapticFeedback.selectionClick();
              onDownload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_outline_rounded),
            color: AppColors.primaryBlue,
            iconSize: 21,
            tooltip: 'Favorite / Unfavorite',
            onPressed: () {
              HapticFeedback.selectionClick();
              onToggleFavorite();
            },
          ),
          IconButton(
            icon: const Icon(Icons.drive_folder_upload_rounded),
            color: AppColors.primaryBlue,
            iconSize: 21,
            tooltip: 'Export to Folder',
            onPressed: () {
              HapticFeedback.selectionClick();
              onExport();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.errorRed,
            iconSize: 21,
            tooltip: 'Delete',
            onPressed: () {
              HapticFeedback.heavyImpact();
              onDelete();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: Colors.grey,
            iconSize: 20,
            tooltip: 'Cancel',
            onPressed: () {
              HapticFeedback.selectionClick();
              onCancel();
            },
          ),
        ],
      ),
    );
  }
}
