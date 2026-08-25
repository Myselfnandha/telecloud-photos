import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_icons.dart';

class AddToAlbumSheet extends ConsumerWidget {
  final MediaItem item;

  const AddToAlbumSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, MediaItem item) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AddToAlbumSheet(item: item),
    );
  }

  void _showCreateAlbumDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor =
        isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;
    final secondaryTextColor =
        isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary;
    final dialogBg = isLight ? Colors.white : AppColors.darkSurface;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderXL),
        title: Text(
          'New Album',
          style: AppTypography.headlineSmall(
            color: primaryTextColor,
          ).copyWith(fontWeight: AppTypography.bold),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: AppTypography.bodyLarge(color: primaryTextColor),
          decoration: InputDecoration(
            hintText: 'Album Title',
            hintStyle: AppTypography.bodyMedium(color: secondaryTextColor),
            filled: true,
            fillColor: isLight ? Colors.grey.shade100 : Colors.black26,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadii.borderM,
              borderSide: BorderSide(
                color: isLight ? Colors.grey.shade300 : Colors.white12,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadii.borderM,
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge(color: secondaryTextColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.borderM,
              ),
            ),
            onPressed: () async {
              final title = textController.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(ctx);
                final mediaDao = ref.read(mediaDaoProvider);
                final album = await mediaDao.getOrCreateAlbum(title);
                await mediaDao.assignMediaToAlbum(item.localId, album.id);
                HapticFeedback.lightImpact();

                if (context.mounted) {
                  Navigator.pop(context); // Close sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to "$title"'),
                      backgroundColor: AppColors.successGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Create',
              style: AppTypography.labelLarge(
                color: Colors.white,
              ).copyWith(fontWeight: AppTypography.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaDao = ref.watch(mediaDaoProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor =
        isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;
    final secondaryTextColor =
        isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary;
    final sheetBg = isLight ? Colors.white : AppColors.darkSurface;
    final itemBg = isLight ? Colors.grey.shade100 : const Color(0xFF1C1C1E);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: AppRadii.borderTopXL,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isLight ? Colors.grey.shade300 : Colors.white24,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add to Album',
                    style: AppTypography.titleLarge(
                      color: primaryTextColor,
                    ).copyWith(fontWeight: AppTypography.bold),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: AppIcons.s + 2),
                    label: Text(
                      'New Album',
                      style: AppTypography.labelLarge(
                        color: AppColors.primaryBlue,
                      ).copyWith(fontWeight: AppTypography.bold),
                    ),
                    onPressed: () => _showCreateAlbumDialog(context, ref),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Albums List
            Expanded(
              child: StreamBuilder<List<Album>>(
                stream: mediaDao.watchAllAlbums(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    );
                  }

                  final albums = snapshot.data!;
                  if (albums.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: AppSpacing.screenPadding,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_album_outlined,
                              size: 54,
                              color: secondaryTextColor,
                            ),
                            AppSpacing.gapVerticalM,
                            Text(
                              'No albums yet',
                              style: AppTypography.titleMedium(
                                color: secondaryTextColor,
                              ),
                            ),
                            AppSpacing.gapVerticalS,
                            Text(
                              'Tap "New Album" to create your first album',
                              style: AppTypography.bodyMedium(
                                color: secondaryTextColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      final isCurrentAlbum = item.albumId == album.id;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrentAlbum
                              ? AppColors.primaryBlue.withValues(alpha: 0.12)
                              : itemBg,
                          borderRadius: AppRadii.borderL,
                          border: Border.all(
                            color: isCurrentAlbum
                                ? AppColors.primaryBlue
                                : Colors.transparent,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: AppRadii.borderM,
                            ),
                            child: const Icon(
                              Icons.photo_library_rounded,
                              color: AppColors.primaryBlue,
                              size: AppIcons.m,
                            ),
                          ),
                          title: Text(
                            album.name,
                            style: AppTypography.bodyLarge(
                              color: primaryTextColor,
                            ).copyWith(
                              fontWeight: isCurrentAlbum
                                  ? AppTypography.bold
                                  : AppTypography.medium,
                            ),
                          ),
                          subtitle: Text(
                            'Created ${album.createdAt.toLocal().toString().split(' ')[0]}',
                            style: AppTypography.labelSmall(
                              color: secondaryTextColor,
                            ),
                          ),
                          trailing: isCurrentAlbum
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primaryBlue,
                                  size: AppIcons.m,
                                )
                              : Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: secondaryTextColor,
                                  size: AppIcons.m,
                                ),
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            await mediaDao.assignMediaToAlbum(
                              item.localId,
                              album.id,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to "${album.name}"'),
                                  backgroundColor: AppColors.successGreen,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
