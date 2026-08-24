import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../core/di/providers.dart';
import '../../../shared/widgets/google_photos_badge.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_elevation.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/grid_density_provider.dart';

class GooglePhotosSyncedScreen extends ConsumerStatefulWidget {
  const GooglePhotosSyncedScreen({super.key});

  @override
  ConsumerState<GooglePhotosSyncedScreen> createState() =>
      _GooglePhotosSyncedScreenState();
}

class _GooglePhotosSyncedScreenState
    extends ConsumerState<GooglePhotosSyncedScreen> {
  String _filterType = 'all'; // 'all', 'photos', 'videos'
  double _pinchScale = 1.0;
  bool _isPinching = false;

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2) {
      setState(() {
        _isPinching = true;
        _pinchScale = details.scale.clamp(0.5, 2.5);
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!_isPinching) return;
    if (_pinchScale > 1.25) {
      ref.read(gridDensityProvider.notifier).zoomIn();
      HapticFeedback.selectionClick();
    } else if (_pinchScale < 0.78) {
      ref.read(gridDensityProvider.notifier).zoomOut();
      HapticFeedback.selectionClick();
    }

    setState(() {
      _isPinching = false;
      _pinchScale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncMedia = ref.watch(googlePhotosMediaStreamProvider);
    final density = ref.watch(gridDensityProvider);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GooglePhotosBadge(compact: false),
            AppSpacing.gapHorizontalS,
            Text(
              'Synced',
              style: AppTypography.titleMedium(
                color: primaryTextColor,
              ).copyWith(fontWeight: AppTypography.bold),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<GridDensity>(
            icon: Icon(
              density.icon,
              color: const Color(0xFF4285F4),
              size: AppIcons.m,
            ),
            tooltip: 'Grid Density',
            color: isLight ? Colors.white : AppColors.darkSurface,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderL),
            onSelected: (d) {
              HapticFeedback.selectionClick();
              ref.read(gridDensityProvider.notifier).setDensity(d);
            },
            itemBuilder: (context) => [
              for (final d in GridDensity.values)
                PopupMenuItem(
                  value: d,
                  child: Row(
                    children: [
                      Icon(
                        d.icon,
                        color: density == d
                            ? const Color(0xFF4285F4)
                            : secondaryTextColor,
                        size: AppIcons.s + 2,
                      ),
                      AppSpacing.gapHorizontalM,
                      Text(
                        d.label,
                        style:
                            AppTypography.bodyMedium(
                              color: density == d
                                  ? const Color(0xFF4285F4)
                                  : primaryTextColor,
                            ).copyWith(
                              fontWeight: density == d
                                  ? AppTypography.bold
                                  : AppTypography.regular,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: asyncMedia.when(
        data: (items) {
          final filteredItems = items.where((item) {
            final isVideo =
                item.mimeType.startsWith('video') ||
                item.filename.toLowerCase().endsWith('.mp4') ||
                item.filename.toLowerCase().endsWith('.mov');
            if (_filterType == 'photos') return !isVideo;
            if (_filterType == 'videos') return isVideo;
            return true;
          }).toList();

          final totalBytes = items.fold<int>(
            0,
            (sum, i) => sum + (i.fileSizeBytes ?? 0),
          );
          final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

          final bodyContent = CustomScrollView(
            slivers: [
              // Summary Header Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: AppRadii.borderXL,
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding:
                                  AppSpacing.paddingS + const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF4285F4,
                                ).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_done_rounded,
                                color: Color(0xFF4285F4),
                                size: AppIcons.l,
                              ),
                            ),
                            AppSpacing.gapHorizontalM,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${items.length} Google Photos Synced',
                                    style: AppTypography.titleMedium(
                                      color: primaryTextColor,
                                    ).copyWith(fontWeight: AppTypography.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$totalMb MB backed up bit-for-bit to Telegram Cloud',
                                    style: AppTypography.labelMedium(
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapVerticalM,
                        Row(
                          children: [
                            _buildFilterChip('All (${items.length})', 'all'),
                            AppSpacing.gapHorizontalS,
                            _buildFilterChip('Photos', 'photos'),
                            AppSpacing.gapHorizontalS,
                            _buildFilterChip('Videos', 'videos'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Photos Grid
              if (filteredItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No synced Google Photos matching filter',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: density.crossAxisCount,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: density.childAspectRatio,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredItems[index];
                      final isVideo =
                          item.mimeType.startsWith('video') ||
                          item.filename.toLowerCase().endsWith('.mp4') ||
                          item.filename.toLowerCase().endsWith('.mov');

                      return _GooglePhotoSyncedTile(
                        item: item,
                        isVideo: isVideo,
                      );
                    }, childCount: filteredItems.length),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );

          return GestureDetector(
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            child: bodyContent,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4285F4)),
        ),
        error: (e, s) => Center(
          child: Text(
            'Error loading synced items: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4285F4)
              : const Color(0xFF4285F4).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4285F4),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GooglePhotoSyncedTile extends StatefulWidget {
  final dynamic item;
  final bool isVideo;

  const _GooglePhotoSyncedTile({required this.item, required this.isVideo});

  @override
  State<_GooglePhotoSyncedTile> createState() => _GooglePhotoSyncedTileState();
}

class _GooglePhotoSyncedTileState extends State<_GooglePhotoSyncedTile>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _bytes;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final cached = ThumbnailCacheService().getFromMemory(widget.item.localId);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _bytes = cached;
        });
      }
      return;
    }

    final bytes = await ThumbnailCacheService().getThumbnail(
      id: widget.item.localId,
      diskPath: widget.item.thumbnailPath,
      isVideo: widget.isVideo,
    );

    if (mounted) {
      setState(() {
        _bytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () => context.push('/viewer/${widget.item.localId}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'media_${widget.item.localId}',
            child: Container(
              color: const Color(0xFF1C1C1E),
              child: _bytes != null
                  ? Image.memory(
                      _bytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  : (widget.item.thumbnailPath != null &&
                            File(widget.item.thumbnailPath!).existsSync()
                        ? Image.file(
                            File(widget.item.thumbnailPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(),
                          )
                        : _buildPlaceholder()),
            ),
          ),
          const Positioned(
            top: 4,
            left: 4,
            child: GooglePhotosBadge(compact: true),
          ),
          if (widget.isVideo)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    final colors = [
      const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      const [Color(0xFF064E3B), Color(0xFF10B981)],
      const [Color(0xFF78350F), Color(0xFFF59E0B)],
      const [Color(0xFF7F1D1D), Color(0xFFEF4444)],
    ];
    final pair = colors[widget.item.localId.hashCode.abs() % colors.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: pair,
        ),
      ),
      child: Center(
        child: Icon(
          widget.isVideo ? Icons.movie_creation_outlined : Icons.photo_outlined,
          color: Colors.white.withValues(alpha: 0.3),
          size: 28,
        ),
      ),
    );
  }
}
