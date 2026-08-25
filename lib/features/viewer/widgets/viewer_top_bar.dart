import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class ViewerTopBar extends StatelessWidget implements PreferredSizeWidget {
  final MediaItem? currentItem;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShowInfo;

  const ViewerTopBar({
    super.key,
    required this.currentItem,
    required this.isFavorite,
    required this.onBack,
    required this.onToggleFavorite,
    required this.onShowInfo,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _getResolutionLabel(int? width, int? height) {
    if (width == null || height == null) return 'HD';
    final maxDim = width > height ? width : height;
    if (maxDim >= 3840) return '4K UHD';
    if (maxDim >= 2560) return '2K QHD';
    if (maxDim >= 1920) return '1080p FHD';
    if (maxDim >= 1280) return '720p HD';
    return '$width×$height';
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: currentItem != null
          ? Column(
              children: [
                Text(
                  currentItem!.capturedAt.toLocal().toString().split(' ')[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getResolutionLabel(
                    currentItem!.width,
                    currentItem!.height,
                  ),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            )
          : null,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: onBack,
      ),
      actions: [
        if (currentItem != null) ...[
          IconButton(
            icon: Icon(
              isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: isFavorite ? const Color(0xFFFFB800) : Colors.white,
            ),
            onPressed: onToggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: onShowInfo,
          ),
        ],
      ],
    );
  }
}
