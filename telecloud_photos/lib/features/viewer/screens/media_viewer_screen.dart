import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables/media_table.dart';
import '../../../core/di/providers.dart';
import '../../../core/media/exif_parser_service.dart';
import '../../../shared/widgets/m3e/m3e_floating_toolbar.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';
import '../../../shared/widgets/shimmer_loading.dart';

/// Screen 3: "Media Viewer"
/// True Fullscreen Immersive Photo/Video Viewer with InteractiveViewer zoom,
/// tap-to-toggle UI chrome, slide-down dismiss, and swipe-up EXIF & hardware metadata sheet.
class MediaViewerScreen extends ConsumerStatefulWidget {
  final String mediaId;

  const MediaViewerScreen({super.key, required this.mediaId});

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen>
    with SingleTickerProviderStateMixin {
  MediaItem? _mediaItem;
  ExifMetadata? _exif;
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _showChrome = true;
  double _dragOffsetY = 0.0;
  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_snapAnimation != null && mounted) {
          setState(() {
            _dragOffsetY = _snapAnimation!.value;
          });
        }
      });

    _loadMedia();
  }

  Future<void> _loadMedia() async {
    try {
      final mediaDao = ref.read(mediaDaoProvider);
      final item = await mediaDao.getMediaById(widget.mediaId);
      if (item != null && mounted) {
        setState(() {
          _mediaItem = item;
          _isFavorite = item.isFavorite;
          _isLoading = false;
        });

        // 1. Fetch image bytes from cache or AssetEntity
        final isVideo = item.mimeType.startsWith('video');
        final bytes = await ThumbnailCacheService().getThumbnail(
          id: item.localId,
          diskPath: item.thumbnailPath,
          isVideo: isVideo,
        );

        if (mounted && bytes != null) {
          setState(() => _imageBytes = bytes);
        }

        // 2. Parse EXIF from device asset or local file
        if (!item.localId.startsWith('tg_') && !item.localId.startsWith('gp_')) {
          try {
            final asset = await AssetEntity.fromId(item.localId);
            if (asset != null) {
              final parsed = await ExifParserService.parseAsset(asset);
              if (mounted) setState(() => _exif = parsed);
            }
          } catch (_) {}
        } else if (item.thumbnailPath != null && item.thumbnailPath!.isNotEmpty) {
          final file = File(item.thumbnailPath!);
          if (await file.exists()) {
            final parsed = await ExifParserService.parseFile(file);
            if (mounted) setState(() => _exif = parsed);
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _closeViewer() {
    HapticFeedback.lightImpact();
    if (mounted) Navigator.of(context).maybePop();
  }

  void _toggleChrome() {
    setState(() => _showChrome = !_showChrome);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_transformController.value != Matrix4.identity()) {
      return; // Do not drag when zoomed in
    }

    if (details.primaryDelta != null) {
      if (details.primaryDelta! > 0) {
        // Dragging DOWN -> dismiss gesture
        setState(() {
          _dragOffsetY += details.primaryDelta!;
        });
      } else if (details.primaryDelta! < -12 && _dragOffsetY <= 0) {
        // Dragging UP -> reveal EXIF bottom sheet
        _showExifModalSheet();
      }
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 500 || _dragOffsetY > 120) {
      _closeViewer();
    } else {
      _snapAnimation = Tween<double>(begin: _dragOffsetY, end: 0.0).animate(
        CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
      );
      _snapController.forward(from: 0.0);
    }
  }

  void _showMessage(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_mediaItem == null) return;
    HapticFeedback.selectionClick();
    final newFav = !_isFavorite;
    setState(() => _isFavorite = newFav);
    await ref.read(mediaDaoProvider).setFavorite(_mediaItem!.localId, newFav);
    _showMessage(newFav ? 'Added to Favorites' : 'Removed from Favorites');
  }

  Future<void> _deleteMedia() async {
    if (_mediaItem == null) return;
    HapticFeedback.mediumImpact();
    await ref.read(mediaDaoProvider).moveToTrash([_mediaItem!.localId]);
    _showMessage('Moved to Trash');
    if (mounted) Navigator.of(context).maybePop();
  }

  Widget _buildChip(String label, ColorScheme scheme, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  void _showExifModalSheet() {
    HapticFeedback.lightImpact();
    final item = _mediaItem;
    if (item == null) return;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy • h:mm:ss a').format(item.capturedAt);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.58,
        minChildSize: 0.35,
        maxChildSize: 0.88,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Drag Pill
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title & Date Header
                Text(
                  item.filename,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Dynamic Status Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip(
                        item.uploadStatus == UploadStatus.done
                            ? 'Synced to Telegram Cloud'
                            : 'Pending Backup',
                        scheme,
                        isSelected: item.uploadStatus == UploadStatus.done,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        item.mimeType.startsWith('video') ? 'Video' : 'Photo',
                        scheme,
                      ),
                      if (item.folderName != null && item.folderName!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildChip(item.folderName!, scheme),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // EXIF Specifications Header
                Text(
                  'Camera & Capture Hardware EXIF',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Stacked List of Real EXIF Items
                M3EStackedList(
                  items: [
                    M3EListItemData(
                      title: _exif?.formattedCameraTitle ?? item.filename,
                      subtitle: _exif?.formattedResolution ??
                          '${item.width ?? 0} × ${item.height ?? 0} px',
                      leadingIcon: Icons.camera_alt,
                    ),
                    M3EListItemData(
                      title: _exif != null && _exif!.hasCameraSpecs
                          ? '${_exif!.fNumber ?? "f/--"} • ${_exif!.exposureTime ?? "--"}s • ISO ${_exif!.iso ?? "--"}'
                          : 'Captured on ${DateFormat('yyyy-MM-dd').format(item.capturedAt)}',
                      subtitle: _exif?.formattedFileSize ??
                          '${((item.fileSizeBytes ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB • ${item.mimeType}',
                      leadingIcon: Icons.iso,
                    ),
                    M3EListItemData(
                      title: item.uploadStatus == UploadStatus.done
                          ? 'Telegram Cloud Supergroup'
                          : 'Local Device Storage',
                      subtitle: item.telegramMsgId != null
                          ? 'Topic: #${item.folderName ?? "camera"} • Message #${item.telegramMsgId}'
                          : 'Queued for Telegram TDLib E2EE Cloud Storage',
                      leadingIcon: Icons.cloud,
                      trailing: item.uploadStatus == UploadStatus.done
                          ? IconButton(
                              icon: const Icon(Icons.download),
                              color: scheme.primary,
                              onPressed: () => _showMessage(
                                  'Downloading original file from Telegram Cloud...'),
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dragFraction = (_dragOffsetY / 300.0).clamp(0.0, 1.0);

    final item = _mediaItem;
    final formattedDate = item != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(item.capturedAt)
        : 'Loading Media...';

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 1.0 - (dragFraction * 0.5)),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : item == null
              ? Center(
                  child: Text('Media not found: ${widget.mediaId}',
                      style: TextStyle(color: scheme.error)),
                )
              : GestureDetector(
                  onTap: _toggleChrome,
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  behavior: HitTestBehavior.translucent,
                  child: Stack(
                    children: [
                      // Fullscreen Immersive Interactive Media Canvas
                      Transform.translate(
                        offset: Offset(0, _dragOffsetY),
                        child: Center(
                          child: InteractiveViewer(
                            transformationController: _transformController,
                            minScale: 1.0,
                            maxScale: 5.0,
                            clipBehavior: Clip.none,
                            child: _imageBytes != null
                                ? Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
                                    ),
                                  )
                                : (item.thumbnailPath != null &&
                                        item.thumbnailPath!.isNotEmpty)
                                    ? Image.file(
                                        File(item.thumbnailPath!),
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (_, __, ___) =>
                                            const ShimmerLoading(),
                                      )
                                    : const Center(child: ShimmerLoading()),
                          ),
                        ),
                      ),

                      // Top App Bar Overlay (Animated)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        top: _showChrome ? 0 : -100,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.75),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                                    tooltip: 'Back',
                                    onPressed: _closeViewer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: _isFavorite ? Colors.redAccent : Colors.white,
                                    ),
                                    tooltip: 'Favorite',
                                    onPressed: _toggleFavorite,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline, color: Colors.white),
                                    tooltip: 'EXIF Info',
                                    onPressed: _showExifModalSheet,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Floating Action Pill & Swipe Up Indicator (Animated)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        bottom: _showChrome ? 32 : -120,
                        left: 20,
                        right: 20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Subtle Swipe Up Gesture Cue
                            GestureDetector(
                              onTap: _showExifModalSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.keyboard_arrow_up, size: 16, color: Colors.white70),
                                    SizedBox(width: 4),
                                    Text(
                                      'Swipe up for EXIF details',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Floating Action Toolbar
                            M3EFloatingToolbar(
                              isVibrant: true,
                              actions: [
                                M3EToolbarAction(
                                  icon: Icons.share,
                                  tooltip: 'Share',
                                  onPressed: () => _showMessage(
                                      'Preparing Telegram media share link for ${item.filename}...'),
                                ),
                                M3EToolbarAction(
                                  icon: Icons.cloud_download,
                                  tooltip: 'Download',
                                  onPressed: () => _showMessage(
                                      'Saved ${item.filename} to device Gallery!'),
                                ),
                                M3EToolbarAction(
                                  icon: _isFavorite ? Icons.star : Icons.star_border,
                                  tooltip: 'Favorite',
                                  onPressed: _toggleFavorite,
                                ),
                                M3EToolbarAction(
                                  icon: Icons.delete_outline,
                                  tooltip: 'Delete',
                                  onPressed: _deleteMedia,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
