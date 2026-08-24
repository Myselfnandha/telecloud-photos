import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/media_dao.dart';
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_elevation.dart';
import '../../../shared/theme/app_icons.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _albumNameController = TextEditingController();

  void _showCreateAlbumDialog() {
    _albumNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'New Album',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _albumNameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Album Name',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF),
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

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Album "$name" created in TeleCloud!'),
                    backgroundColor: const Color(0xFF30D158),
                  ),
                );
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
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
    final primaryTextColor = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final secondaryTextColor = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;
    final cardBg = isLight ? AppColors.lightCard : AppColors.darkSurface;
    final cardBorder = isLight ? AppColors.lightBorder : AppColors.darkBorder;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: AppElevation.none,
        title: Text(
          'Library & Collections',
          style: AppTypography.headlineMedium(
            color: primaryTextColor,
          ).copyWith(fontWeight: AppTypography.bold, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.primaryBlue,
              size: AppIcons.l,
            ),
            tooltip: 'Search Library',
            onPressed: () => context.push('/search'),
          ),
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
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // 1. User Albums Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MY ALBUMS',
                style: TextStyle(
                  color: isLight ? Colors.grey.shade600 : Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: _showCreateAlbumDialog,
                child: const Text(
                  '+ Add Album',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<Album>>(
            stream: mediaDao.watchAllAlbums(),
            builder: (context, snapshot) {
              final albums = snapshot.data ?? [];
              if (albums.isEmpty) {
                return GestureDetector(
                  onTap: _showCreateAlbumDialog,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A84FF).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color(0xFF0A84FF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Your First Album',
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Albums sync as Telegram topics for unlimited storage',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.86,
                ),
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return _buildAlbumTile(
                    album: album,
                    mediaDao: mediaDao,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  );
                },
              );
            },
          ),

          const SizedBox(height: 28),

          // 2. Media Collections (Clean Full-Width Grid Cards Layout)
          Text(
            'MEDIA COLLECTIONS',
            style: AppTypography.labelSmall(
              color: secondaryTextColor,
            ).copyWith(fontWeight: AppTypography.bold, letterSpacing: 0.8),
          ),
          AppSpacing.gapVerticalS,
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                _buildMediaTypeRow(
                  title: 'Photos',
                  icon: Icons.photo_outlined,
                  iconColor: const Color(0xFF0A84FF),
                  streamCount: mediaDao.watchAllMedia().map((l) => l.where((i) {
                    if (i.isTrashed) return false;
                    final fn = i.filename.toUpperCase();
                    final isMotion = fn.startsWith('MVIMG_') ||
                        fn.contains('MOTION') ||
                        fn.contains('LIVE');
                    final isImg = i.mimeType.startsWith('image') ||
                        fn.endsWith('.JPG') ||
                        fn.endsWith('.JPEG') ||
                        fn.endsWith('.PNG') ||
                        fn.endsWith('.WEBP') ||
                        fn.endsWith('.HEIC');
                    return isImg && !isMotion;
                  }).length),
                  onTap: () => context.push('/collection/photos', extra: 'Photos'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildMediaTypeRow(
                  title: 'Videos',
                  icon: Icons.videocam_outlined,
                  iconColor: const Color(0xFF30D158),
                  streamCount: mediaDao.watchAllMedia().map(
                    (l) => l.where((i) {
                      if (i.isTrashed) return false;
                      final fn = i.filename.toUpperCase();
                      return i.mimeType.startsWith('video') ||
                          fn.endsWith('.MP4') ||
                          fn.endsWith('.MOV') ||
                          fn.endsWith('.MKV') ||
                          fn.endsWith('.AVI') ||
                          fn.endsWith('.WEBM');
                    }).length,
                  ),
                  onTap: () => context.push('/collection/videos', extra: 'Videos'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildMediaTypeRow(
                  title: 'Live Photos',
                  icon: Icons.motion_photos_on_outlined,
                  iconColor: const Color(0xFFFF9F0A),
                  streamCount: mediaDao.watchAllMedia().map((l) => l.where((i) {
                    if (i.isTrashed) return false;
                    final fn = i.filename.toUpperCase();
                    return fn.startsWith('MVIMG_') ||
                        fn.startsWith('LIVE_') ||
                        fn.contains('_MOTION_PHOTO') ||
                        fn.contains('_LIVEPHOTO') ||
                        i.mimeType == 'image/x-motion-photo';
                  }).length),
                  onTap: () => context.push('/collection/live_photos', extra: 'Live Photos'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildMediaTypeRow(
                  title: 'Screenshots',
                  icon: Icons.screenshot_outlined,
                  iconColor: const Color(0xFF64D2FF),
                  streamCount: mediaDao.watchAllMedia().map((l) => l.where((i) {
                    if (i.isTrashed) return false;
                    final fn = i.filename.toLowerCase();
                    return fn.contains('screenshot') ||
                        fn.contains('screen_shot');
                  }).length),
                  onTap: () => context.push('/collection/screenshots', extra: 'Screenshots'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildMediaTypeRow(
                  title: 'Favorites',
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFFF453A),
                  streamCount: mediaDao.watchFavorites().map((l) => l.length),
                  onTap: () => context.push('/favorites'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildMediaTypeRow(
                  title: 'Selfies & Portraits',
                  icon: Icons.portrait_rounded,
                  iconColor: const Color(0xFFFF375F),
                  streamCount: mediaDao.watchAllMedia().map((l) => l.where((i) {
                    if (i.isTrashed) return false;
                    final fn = i.filename.toLowerCase();
                    return fn.startsWith('selfie_') ||
                        fn.contains('_selfie_') ||
                        fn.contains('_portrait_');
                  }).length),
                  onTap: () => context.push('/collection/selfies', extra: 'Selfies & Portraits'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildMediaTypeRow(
                  title: 'Panoramas',
                  icon: Icons.panorama_horizontal_rounded,
                  iconColor: const Color(0xFFBF5AF2),
                  streamCount: mediaDao.watchAllMedia().map((l) => l.where((i) {
                    if (i.isTrashed) return false;
                    final fn = i.filename.toUpperCase();
                    final isPanoAspect = i.width != null &&
                        i.height != null &&
                        i.height! > 0 &&
                        (i.width! / i.height! >= 2.4 || i.height! / i.width! >= 2.4);
                    return fn.startsWith('PANO_') ||
                        fn.contains('_PANO_') ||
                        fn.contains('_PANORAMA') ||
                        isPanoAspect;
                  }).length),
                  onTap: () => context.push('/collection/panoramas', extra: 'Panoramas'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildMediaTypeRow(
                  title: 'RAW',
                  icon: Icons.camera_rounded,
                  iconColor: const Color(0xFFFFD60A),
                  streamCount: mediaDao.watchAllMedia().map((l) => l.where((i) {
                    if (i.isTrashed) return false;
                    final fn = i.filename.toLowerCase();
                    return fn.endsWith('.dng') ||
                        fn.endsWith('.cr2') ||
                        fn.endsWith('.arw') ||
                        fn.endsWith('.nef') ||
                        fn.endsWith('.raw') ||
                        fn.endsWith('.orf') ||
                        fn.endsWith('.rw2');
                  }).length),
                  onTap: () => context.push('/collection/raw', extra: 'RAW'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 3. Utilities Section
          Text(
            'UTILITIES',
            style: AppTypography.labelSmall(
              color: secondaryTextColor,
            ).copyWith(fontWeight: AppTypography.bold, letterSpacing: 0.8),
          ),
          AppSpacing.gapVerticalS,
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                _buildMediaTypeRow(
                  title: 'Device Folders & Sync',
                  icon: Icons.sync_rounded,
                  iconColor: const Color(0xFF30D158),
                  subtitle: 'Manage selective device folder auto-sync',
                  streamCount: mediaDao.watchFolderSyncSettings().map((l) => l.where((f) => f.isAutoBackupEnabled).length),
                  onTap: () => context.push('/settings/folders'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildMediaTypeRow(
                  title: 'Imports',
                  icon: Icons.cloud_download_outlined,
                  iconColor: const Color(0xFF4285F4),
                  subtitle: 'Google Photos & Cloud Synced Media',
                  streamCount: mediaDao.watchGooglePhotosMedia().map((l) => l.length),
                  onTap: () => context.push('/google-photos/synced'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildMediaTypeRow(
                  title: 'Recently Deleted',
                  icon: Icons.delete_outline_rounded,
                  iconColor: const Color(0xFFFF453A),
                  streamCount: mediaDao.watchTrash().map((l) => l.length),
                  onTap: () => context.push('/trash'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMediaTypeRow({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required Stream<int> streamCount,
    required VoidCallback onTap,
    required bool isLight,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: primaryTextColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: secondaryTextColor, fontSize: 11))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<int>(
            stream: streamCount,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Text(
                '$count',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: isLight ? Colors.grey.shade400 : Colors.grey.shade600,
            size: 20,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isLight) {
    return Divider(
      height: 1,
      indent: 52,
      color: isLight ? const Color(0xFFF2F2F7) : Colors.white.withValues(alpha: 0.05),
    );
  }

  Widget _buildAlbumTile({
    required Album album,
    required MediaDao mediaDao,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final colors = const [
      [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      [Color(0xFF064E3B), Color(0xFF10B981)],
      [Color(0xFF78350F), Color(0xFFF59E0B)],
      [Color(0xFF7F1D1D), Color(0xFFEF4444)],
    ];
    final rawName = album.name.trim();
    final albumTitle = rawName.isEmpty ? 'Main Gallery' : rawName;
    final pair = colors[albumTitle.hashCode.abs() % colors.length];

    return GestureDetector(
      onTap: () => context.push('/albums/${album.id}', extra: albumTitle),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppRadii.borderXL,
          border: Border.all(color: cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: StreamBuilder<List<MediaItem>>(
          stream: mediaDao.watchMediaInAlbum(album.id),
          builder: (context, snapshot) {
            final media = snapshot.data ?? [];
            final count = media.length;
            final firstItem = media.isNotEmpty ? media.first : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: firstItem != null
                      ? _AlbumCoverThumbnail(item: firstItem, fallbackGradient: pair)
                      : _buildAlbumGradientPlaceholder(pair),
                ),
                Padding(
                  padding: AppSpacing.paddingS + const EdgeInsets.all(2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        albumTitle,
                        style: AppTypography.labelLarge(
                          color: primaryTextColor,
                        ).copyWith(fontWeight: AppTypography.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count ${count == 1 ? 'photo' : 'photos'}',
                        style: AppTypography.labelSmall(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlbumGradientPlaceholder(List<Color> pair) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: pair,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.photo_library_rounded,
          size: 36,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _AlbumCoverThumbnail extends StatefulWidget {
  final MediaItem item;
  final List<Color> fallbackGradient;

  const _AlbumCoverThumbnail({
    required this.item,
    required this.fallbackGradient,
  });

  @override
  State<_AlbumCoverThumbnail> createState() => _AlbumCoverThumbnailState();
}

class _AlbumCoverThumbnailState extends State<_AlbumCoverThumbnail> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  Future<void> _loadThumb() async {
    final cached = ThumbnailCacheService().getFromMemory(widget.item.localId);
    if (cached != null) {
      if (mounted) setState(() => _bytes = cached);
      return;
    }

    final isVideo = widget.item.mimeType.startsWith('video');
    final bytes = await ThumbnailCacheService().getThumbnail(
      id: widget.item.localId,
      diskPath: widget.item.thumbnailPath,
      isVideo: isVideo,
    );

    if (mounted && bytes != null) {
      setState(() => _bytes = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return SizedBox.expand(
        child: Image.memory(
          _bytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: 256,
          cacheHeight: 256,
        ),
      );
    }

    if (widget.item.thumbnailPath != null &&
        widget.item.thumbnailPath!.isNotEmpty &&
        File(widget.item.thumbnailPath!).existsSync()) {
      return SizedBox.expand(
        child: Image.file(
          File(widget.item.thumbnailPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: 256,
          cacheHeight: 256,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.fallbackGradient,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.photo_library_rounded,
          size: 36,
          color: Colors.white70,
        ),
      ),
    );
  }
}
