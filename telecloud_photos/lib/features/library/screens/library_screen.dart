import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
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
import '../../../shared/widgets/skeleton_layouts.dart';

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

                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Album "$name" created in TeleCloud!'),
                    backgroundColor: const Color(0xFF30D158),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
        title: Text(
          'Library',
          style: AppTypography.displayMedium(color: primaryTextColor),
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
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // 0. Device Folders Section (Above My Albums)
          _DeviceFoldersSection(
            isLight: isLight,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            cardBg: cardBg,
            cardBorder: cardBorder,
          ),

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
            ],
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<Album>>(
            stream: mediaDao.watchAllAlbums(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const AlbumListSkeleton(itemCount: 2);
              }
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
                            color:
                                const Color(0xFF0A84FF).withValues(alpha: 0.12),
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

          // 2. Media Collections (Single Stream - Performance Optimized)
          Text(
            'MEDIA COLLECTIONS',
            style: AppTypography.labelSmall(
              color: secondaryTextColor,
            ).copyWith(fontWeight: AppTypography.bold, letterSpacing: 0.8),
          ),
          AppSpacing.gapVerticalS,
          StreamBuilder<Map<String, int>>(
            stream: mediaDao.watchMediaCollectionCounts(),
            builder: (context, countSnap) {
              final counts = countSnap.data ?? {};
              return Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  children: [
                    _buildStaticCountRow(
                      title: 'Photos',
                      icon: Icons.photo_outlined,
                      iconColor: const Color(0xFF0A84FF),
                      count: counts['photos'] ?? 0,
                      onTap: () =>
                          context.push('/collection/photos', extra: 'Photos'),
                      isLight: isLight,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _buildDivider(isLight),
                    _buildStaticCountRow(
                      title: 'Videos',
                      icon: Icons.videocam_outlined,
                      iconColor: const Color(0xFF30D158),
                      count: counts['videos'] ?? 0,
                      onTap: () =>
                          context.push('/collection/videos', extra: 'Videos'),
                      isLight: isLight,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _buildDivider(isLight),
                    _buildStaticCountRow(
                      title: 'Live Photos',
                      icon: Icons.motion_photos_on_outlined,
                      iconColor: const Color(0xFFFF9F0A),
                      count: counts['livePhotos'] ?? 0,
                      onTap: () => context.push('/collection/live_photos',
                          extra: 'Live Photos'),
                      isLight: isLight,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _buildDivider(isLight),
                    _buildStaticCountRow(
                      title: 'Screenshots',
                      icon: Icons.screenshot_outlined,
                      iconColor: const Color(0xFF64D2FF),
                      count: counts['screenshots'] ?? 0,
                      onTap: () => context.push('/collection/screenshots',
                          extra: 'Screenshots'),
                      isLight: isLight,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _buildDivider(isLight),
                    _buildMediaTypeRow(
                      title: 'Favorites',
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFFFB800),
                      streamCount:
                          mediaDao.watchFavorites().map((l) => l.length),
                      onTap: () => context.push('/favorites'),
                      isLight: isLight,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _buildDivider(isLight),
                    _buildStaticCountRow(
                      title: 'Selfies & Portraits',
                      icon: Icons.portrait_rounded,
                      iconColor: const Color(0xFFFF375F),
                      count: counts['selfies'] ?? 0,
                      onTap: () => context.push('/collection/selfies',
                          extra: 'Selfies & Portraits'),
                      isLight: isLight,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _buildDivider(isLight),
                    _buildStaticCountRow(
                      title: 'Panoramas',
                      icon: Icons.panorama_horizontal_rounded,
                      iconColor: const Color(0xFFBF5AF2),
                      count: counts['panoramas'] ?? 0,
                      onTap: () => context.push('/collection/panoramas',
                          extra: 'Panoramas'),
                      isLight: isLight,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _buildDivider(isLight),
                    _buildStaticCountRow(
                      title: 'RAW',
                      icon: Icons.camera_rounded,
                      iconColor: const Color(0xFFFFD60A),
                      count: counts['raw'] ?? 0,
                      onTap: () =>
                          context.push('/collection/raw', extra: 'RAW'),
                      isLight: isLight,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ],
                ),
              );
            },
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
                  title: 'Free Up Space',
                  icon: Icons.cleaning_services_rounded,
                  iconColor: const Color(0xFF0A84FF),
                  subtitle: 'Delete backed-up device copies safely',
                  streamCount: mediaDao
                      .watchFreeUpSpaceEligibleItems()
                      .map((l) => l.length),
                  onTap: () => context.push('/storage-cleaner'),
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildMediaTypeRow(
                  title: 'Device Folders & Sync',
                  icon: Icons.sync_rounded,
                  iconColor: const Color(0xFF30D158),
                  subtitle: 'Manage selective device folder auto-sync',
                  streamCount: mediaDao
                      .watchFolderSyncSettings()
                      .map((l) => l.where((f) => f.isAutoBackupEnabled).length),
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
                  streamCount:
                      mediaDao.watchGooglePhotosMedia().map((l) => l.length),
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

  Widget _buildStaticCountRow({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required int count,
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
          ? Text(
              subtitle,
              style: TextStyle(color: secondaryTextColor, fontSize: 11),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
            ),
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
          ? Text(subtitle,
              style: TextStyle(color: secondaryTextColor, fontSize: 11))
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
      color: isLight
          ? const Color(0xFFF2F2F7)
          : Colors.white.withValues(alpha: 0.05),
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
                      ? _AlbumCoverThumbnail(
                          item: firstItem, fallbackGradient: pair)
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

class _DeviceFolderThumbnail extends StatefulWidget {
  final AssetPathEntity folder;
  final Color fallbackColor;

  const _DeviceFolderThumbnail({
    required this.folder,
    required this.fallbackColor,
  });

  @override
  State<_DeviceFolderThumbnail> createState() => _DeviceFolderThumbnailState();
}

class _DeviceFolderThumbnailState extends State<_DeviceFolderThumbnail> {
  Uint8List? _thumbBytes;

  @override
  void initState() {
    super.initState();
    _fetchThumbnail();
  }

  Future<void> _fetchThumbnail() async {
    try {
      final assets = await widget.folder.getAssetListRange(start: 0, end: 1);
      if (assets.isNotEmpty && mounted) {
        final bytes = await assets.first.thumbnailDataWithSize(
          const ThumbnailSize.square(200),
        );
        if (mounted) {
          setState(() {
            _thumbBytes = bytes;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbBytes != null) {
      return Image.memory(
        _thumbBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.folder_rounded, color: widget.fallbackColor, size: 36),
      );
    }
    return Center(
      child: Icon(Icons.folder_rounded, color: widget.fallbackColor, size: 36),
    );
  }
}

class _DeviceFoldersSection extends ConsumerStatefulWidget {
  final bool isLight;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color cardBg;
  final Color cardBorder;

  const _DeviceFoldersSection({
    required this.isLight,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  ConsumerState<_DeviceFoldersSection> createState() =>
      _DeviceFoldersSectionState();
}

class _DeviceFoldersSectionState extends ConsumerState<_DeviceFoldersSection> {
  List<({AssetPathEntity folder, int count})> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final rawFolders = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      final List<({AssetPathEntity folder, int count})> loaded = [];
      for (final f in rawFolders) {
        final nameLower = f.name.trim().toLowerCase();
        if (f.isAll ||
            nameLower == 'recent' ||
            nameLower == 'all' ||
            nameLower == 'recent photos' ||
            nameLower.isEmpty) {
          continue;
        }
        final count = await f.assetCountAsync;
        if (count > 0) {
          loaded.add((folder: f, count: count));
        }
      }
      if (mounted) {
        setState(() {
          _folders = loaded;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_folders.isEmpty) return const SizedBox.shrink();

    final displayFolders =
        _folders.length > 4 ? _folders.sublist(0, 4) : _folders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DEVICE FOLDERS',
              style: TextStyle(
                color: widget.isLight
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.push('/settings/folders');
              },
              child: const Text(
                'Manage',
                style: TextStyle(
                  color: Color(0xFF0A84FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: displayFolders.length,
          itemBuilder: (context, index) {
            final item = displayFolders[index];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.push(
                  '/library/collection',
                  extra: {
                    'categoryKey': item.folder.name,
                    'categoryTitle': item.folder.name,
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isLight
                      ? widget.cardBg
                      : const Color(0xFF161618),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isLight
                        ? widget.cardBorder
                        : const Color(0xFF2C2C2E),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13),
                        ),
                        child: _DeviceFolderThumbnail(
                          folder: item.folder,
                          fallbackColor: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${item.count} items',
                            style: TextStyle(
                              color: widget.secondaryTextColor,
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
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
