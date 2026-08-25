import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_elevation.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/widgets/skeleton_layouts.dart';

class AlbumsListScreen extends ConsumerStatefulWidget {
  const AlbumsListScreen({super.key});

  @override
  ConsumerState<AlbumsListScreen> createState() => _AlbumsListScreenState();
}

class _AlbumsListScreenState extends ConsumerState<AlbumsListScreen> {
  final TextEditingController _albumNameController = TextEditingController();

  void _showCreateAlbumDialog() {
    _albumNameController.clear();
    final isLight = Theme.of(context).brightness == Brightness.light;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isLight ? AppColors.lightCard : AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderXL),
        title: Text(
          'New Album',
          style: AppTypography.titleLarge(
            color: isLight
                ? AppColors.lightTextPrimary
                : AppColors.darkTextPrimary,
          ).copyWith(fontWeight: AppTypography.bold),
        ),
        content: TextField(
          controller: _albumNameController,
          autofocus: true,
          style: AppTypography.bodyMedium(
            color: isLight
                ? AppColors.lightTextPrimary
                : AppColors.darkTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Album Name',
            hintStyle: TextStyle(
              color: isLight ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
            filled: true,
            fillColor:
                isLight ? const Color(0xFFE5E5EA) : const Color(0xFF2C2C2E),
            border: OutlineInputBorder(
              borderRadius: AppRadii.borderM,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge(
                color: isLight ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.borderM),
            ),
            onPressed: () async {
              final name = _albumNameController.text.trim();
              if (name.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final channelMgr = ref.read(channelManagerProvider);
                final mediaDao = ref.read(mediaDaoProvider);

                final topicId = await channelMgr.createAlbumTopic(name);
                await mediaDao.createAlbum(name, topicId: topicId);

                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Album "$name" created in TeleCloud!'),
                    backgroundColor: AppColors.systemGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
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
  void dispose() {
    _albumNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaDao = ref.watch(mediaDaoProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor =
        isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;
    final secondaryTextColor =
        isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary;
    final cardBg = isLight ? AppColors.lightCard : AppColors.darkSurface;
    final cardBorder = isLight ? AppColors.lightBorder : AppColors.darkBorder;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: AppElevation.none,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: primaryTextColor,
                  size: AppIcons.m,
                ),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          'Albums',
          style: AppTypography.headlineMedium(
            color: primaryTextColor,
          ).copyWith(fontWeight: AppTypography.bold, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primaryBlue,
              size: AppIcons.xl,
            ),
            tooltip: 'New Album',
            onPressed: _showCreateAlbumDialog,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Smart Collections
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COLLECTIONS',
                    style: AppTypography.labelSmall(color: secondaryTextColor)
                        .copyWith(
                      fontWeight: AppTypography.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  AppSpacing.gapVerticalS,
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<List<MediaItem>>(
                          stream: mediaDao.watchFavorites(),
                          builder: (context, snap) {
                            final count = snap.data?.length ?? 0;
                            return _smartCollectionCard(
                              title: 'Favorites',
                              count: count,
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFFFB800),
                              bgColor: const Color(0xFFFFB800).withValues(
                                alpha: 0.15,
                              ),
                              onTap: () => context.push('/favorites'),
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                            );
                          },
                        ),
                      ),
                      AppSpacing.gapHorizontalM,
                      Expanded(
                        child: StreamBuilder<List<MediaItem>>(
                          stream: mediaDao.watchTrash(),
                          builder: (context, snap) {
                            final count = snap.data?.length ?? 0;
                            return _smartCollectionCard(
                              title: 'Trash',
                              count: count,
                              icon: Icons.delete_outline_rounded,
                              iconColor: secondaryTextColor,
                              bgColor: isLight
                                  ? Colors.grey.shade200
                                  : const Color(0xFF2C2C2E),
                              onTap: () => context.push('/trash'),
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalL,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MY ALBUMS',
                        style: AppTypography.labelSmall(
                          color: secondaryTextColor,
                        ).copyWith(
                          fontWeight: AppTypography.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showCreateAlbumDialog,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primaryBlue,
                          size: AppIcons.s,
                        ),
                        label: Text(
                          'New',
                          style: AppTypography.labelLarge(
                            color: AppColors.primaryBlue,
                          ).copyWith(fontWeight: AppTypography.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Albums Grid
          StreamBuilder<List<Album>>(
            stream: mediaDao.watchAllAlbums(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: AlbumListSkeleton(itemCount: 4),
                );
              }

              final albums = snapshot.data!;
              if (albums.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 56,
                            color: secondaryTextColor,
                          ),
                          AppSpacing.gapVerticalM,
                          Text(
                            'No Custom Albums',
                            style: AppTypography.titleMedium(
                              color: primaryTextColor,
                            ).copyWith(fontWeight: AppTypography.bold),
                          ),
                          AppSpacing.gapVerticalXS,
                          Text(
                            'Create an album to organize backups into Telegram topics',
                            style: AppTypography.bodySmall(
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final album = albums[index];
                    return StreamBuilder<List<MediaItem>>(
                      stream: mediaDao.watchMediaInAlbum(album.id),
                      builder: (context, mediaSnap) {
                        final items = mediaSnap.data ?? [];
                        final coverPath =
                            items.isNotEmpty ? items.first.thumbnailPath : null;

                        return GestureDetector(
                          onTap: () {
                            context.push(
                              '/albums/${album.id}',
                              extra: album.name,
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: AppRadii.borderXL,
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: AppRadii.borderXL,
                                    child: coverPath != null &&
                                            coverPath.isNotEmpty
                                        ? Image.file(
                                            File(coverPath),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            cacheWidth: 300,
                                            cacheHeight: 300,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Center(
                                              child: Icon(
                                                Icons.photo_album,
                                                size: 40,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Icon(
                                              Icons.photo_album,
                                              size: 40,
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              AppSpacing.gapVerticalXS,
                              Text(
                                album.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelLarge(
                                  color: primaryTextColor,
                                ).copyWith(fontWeight: AppTypography.bold),
                              ),
                              Text(
                                '${items.length} items',
                                style: AppTypography.labelSmall(
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }, childCount: albums.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _smartCollectionCard({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingM,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppRadii.borderXL,
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: AppSpacing.paddingS,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppRadii.borderM,
              ),
              child: Icon(icon, color: iconColor, size: AppIcons.m),
            ),
            AppSpacing.gapHorizontalS,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge(
                      color: primaryTextColor,
                    ).copyWith(fontWeight: AppTypography.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count items',
                    style: AppTypography.labelSmall(color: secondaryTextColor),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: secondaryTextColor,
              size: AppIcons.s,
            ),
          ],
        ),
      ),
    );
  }
}
