import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_colors.dart';

enum DownloadDestination { gallery, customFolder }

class DownloadDestinationSheet extends StatelessWidget {
  const DownloadDestinationSheet({super.key});

  static Future<DownloadDestination?> show(BuildContext context) {
    return showModalBottomSheet<DownloadDestination>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const DownloadDestinationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = AppColors.textPrimary(context);
    final secondaryTextColor = AppColors.textSecondary(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Save Downloaded Media',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose where to restore this uncompressed file on your device',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: AppColors.card(context),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.primaryBlue,
                size: 22,
              ),
            ),
            title: Text(
              'Save to Device Gallery',
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              'Visible immediately in system Photos / Gallery app',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
              ),
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context, DownloadDestination.gallery);
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: AppColors.card(context),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_copy_rounded,
                color: AppColors.successGreen,
                size: 22,
              ),
            ),
            title: Text(
              'Save to Custom Folder',
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              'Saved to device storage in "TeleCloud Restored/" folder',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
              ),
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context, DownloadDestination.customFolder);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
