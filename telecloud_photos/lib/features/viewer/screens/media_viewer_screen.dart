import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import '../../../core/telegram/telegram_download_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_motion.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/widgets/download_progress_overlay.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../widgets/add_to_album_sheet.dart';
import '../widgets/download_destination_sheet.dart';
import '../widgets/drag_dismiss_wrapper.dart';
import '../widgets/exif_info_sheet.dart';
import '../widgets/viewer_bottom_bar.dart';
import '../widgets/viewer_top_bar.dart';
import '../widgets/viewer_video_player.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  final String mediaId;

  const MediaViewerScreen({super.key, required this.mediaId});

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  List<MediaItem> _items = [];
  bool _initialized = false;
  bool _showUiOverlays = true;
  double _dragOffsetY = 0.0;
  bool _isDragging = false;
  int _rotationQuarterTurns = 0;

  // Telegram Cloud Download Progress (Feature 4)
  DownloadProgress? _downloadProgress;
  StreamSubscription<DownloadProgress>? _downloadSub;

  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _snapController = AnimationController(
      vsync: this,
      duration: AppMotion.durationDismiss,
    )..addListener(() {
        if (_snapAnimation != null && mounted) {
          setState(() {
            _dragOffsetY = _snapAnimation!.value;
          });
        }
      });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _snapController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _snapBack(double fromOffset) {
    _snapAnimation = Tween<double>(begin: fromOffset, end: 0.0).animate(
      CurvedAnimation(
        parent: _snapController,
        curve: AppMotion.curveSwipeDismiss,
      ),
    );

    _snapController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffsetY = 0.0;
          _isDragging = false;
        });
      }
    });
  }

  void _toggleUiOverlays() {
    setState(() {
      _showUiOverlays = !_showUiOverlays;
      if (_showUiOverlays) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });
  }

  void _showInfoSheet(BuildContext context, MediaItem item) async {
    AssetEntity? asset;
    try {
      asset = await AssetEntity.fromId(item.localId);
    } catch (_) {}

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ExifInfoSheet(item: item, asset: asset),
    );
  }

  Future<void> _deleteCurrentItem() async {
    if (_items.isEmpty || _currentIndex >= _items.length) return;
    final item = _items[_currentIndex];
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderXL),
        title: const Text(
          'Move to Trash?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This photo will be moved to Trash. You can restore it within 30 days.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.systemRed,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.borderM,
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Move to Trash',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(mediaDaoProvider).moveToTrash([item.localId]);
      navigator.pop();
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Moved to Trash'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.primaryBlue,
            onPressed: () {
              ref.read(mediaDaoProvider).restoreFromTrash([item.localId]);
            },
          ),
          backgroundColor: const Color(0xFF1C1C1E),
        ),
      );
    }
  }

  void _toggleFavorite() async {
    if (_items.isEmpty || _currentIndex >= _items.length) return;
    final item = _items[_currentIndex];
    final newFav = !item.isFavorite;
    await ref.read(mediaDaoProvider).toggleFavorite(item.localId, newFav);
    setState(() {
      _items[_currentIndex] = item.copyWith(isFavorite: newFav);
    });
    HapticFeedback.lightImpact();
  }

  // Feature 4: Cloud Download trigger
  Future<void> _startDownloadFlow() async {
    if (_items.isEmpty || _currentIndex >= _items.length) return;
    final item = _items[_currentIndex];

    final destination = await DownloadDestinationSheet.show(context);
    if (destination == null || !mounted) return;

    final downloadService = ref.read(telegramDownloadServiceProvider);
    _downloadSub?.cancel();

    _downloadSub = downloadService.downloadMediaItem(item).listen(
      (progress) async {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress;
        });

        if (progress.isCompleted && progress.savedPath != null) {
          final saveToGallery = destination == DownloadDestination.gallery;
          final saved = await downloadService.saveDownloadedFile(
            progress.savedPath!,
            filename: item.filename,
            saveToGallery: saveToGallery,
          );

          if (mounted) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  saveToGallery
                      ? 'Saved "${item.filename}" to device Gallery'
                      : 'Saved to ${saved ?? 'TeleCloud Restored'}',
                ),
                backgroundColor: AppColors.successGreen,
                duration: const Duration(seconds: 3),
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() => _downloadProgress = null);
              }
            });
          }
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _downloadProgress = DownloadProgress(
              progress: 0.0,
              filename: item.filename,
              error: err.toString(),
            );
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncMedia = ref.watch(allMediaStreamProvider);
    final bgOpacity = (1.0 - (_dragOffsetY.abs() / 360)).clamp(0.0, 1.0);
    final currentScale = (1.0 - (_dragOffsetY.abs() / 1500)).clamp(0.80, 1.0);
    final currentItem = _items.isNotEmpty && _currentIndex < _items.length
        ? _items[_currentIndex]
        : null;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: (_showUiOverlays && !_isDragging)
          ? ViewerTopBar(
              currentItem: currentItem,
              isFavorite: currentItem?.isFavorite ?? false,
              onBack: () => context.pop(),
              onToggleFavorite: _toggleFavorite,
              onShowInfo: () {
                if (currentItem != null) _showInfoSheet(context, currentItem);
              },
            )
          : null,
      bottomNavigationBar:
          (_showUiOverlays && !_isDragging && currentItem != null)
              ? ViewerBottomBar(
                  currentItem: currentItem,
                  onShare: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing photo...'),
                        backgroundColor: AppColors.primaryBlue,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  onRotate: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
                    });
                  },
                  onDownload: _startDownloadFlow,
                  onAddToAlbum: () {
                    HapticFeedback.lightImpact();
                    AddToAlbumSheet.show(context, currentItem);
                  },
                  onDelete: _deleteCurrentItem,
                )
              : null,
      body: Stack(
        children: [
          asyncMedia.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'No media found',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              _items = items;
              if (!_initialized) {
                final initialIdx = items.indexWhere(
                  (i) => i.localId == widget.mediaId,
                );
                _currentIndex = initialIdx != -1 ? initialIdx : 0;
                _pageController = PageController(initialPage: _currentIndex);
                _initialized = true;
              }

              return DragDismissWrapper(
                dragOffsetY: _dragOffsetY,
                currentScale: currentScale,
                onDragUpdate: (details) {
                  if (details.delta.dy > 0 || _dragOffsetY > 0) {
                    setState(() {
                      _isDragging = true;
                      _dragOffsetY = (_dragOffsetY + details.delta.dy).clamp(
                        0.0,
                        400.0,
                      );
                    });
                  }
                },
                onDragEnd: (details) {
                  if (_dragOffsetY > 60 ||
                      (details.primaryVelocity != null &&
                          details.primaryVelocity! > 400)) {
                    HapticFeedback.lightImpact();
                    if (context.mounted) {
                      context.pop();
                    }
                  } else if (_dragOffsetY > 0) {
                    _snapBack(_dragOffsetY);
                  } else {
                    setState(() {
                      _dragOffsetY = 0.0;
                      _isDragging = false;
                    });
                  }
                },
                onDragCancel: () {
                  if (_dragOffsetY > 0) {
                    _snapBack(_dragOffsetY);
                  } else {
                    setState(() {
                      _dragOffsetY = 0.0;
                      _isDragging = false;
                    });
                  }
                },
                child: PageView.builder(
                  controller: _pageController,
                  physics: _isDragging
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  itemCount: items.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _rotationQuarterTurns = 0;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MediaItemViewer(
                      item: item,
                      onTap: _toggleUiOverlays,
                      showControls: _showUiOverlays && !_isDragging,
                      rotationQuarterTurns:
                          _currentIndex == index ? _rotationQuarterTurns : 0,
                      onHideControls: () {
                        if (mounted && _showUiOverlays) {
                          setState(() => _showUiOverlays = false);
                        }
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, s) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          // Download Progress Floating Overlay (Feature 4)
          if (_downloadProgress != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: DownloadProgressOverlay(
                progress: _downloadProgress!,
                onCancel: () {
                  _downloadSub?.cancel();
                  setState(() => _downloadProgress = null);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaItemViewer extends ConsumerStatefulWidget {
  final MediaItem item;
  final VoidCallback onTap;
  final bool showControls;
  final int rotationQuarterTurns;
  final VoidCallback onHideControls;

  const _MediaItemViewer({
    required this.item,
    required this.onTap,
    required this.showControls,
    required this.rotationQuarterTurns,
    required this.onHideControls,
  });

  @override
  ConsumerState<_MediaItemViewer> createState() => _MediaItemViewerState();
}

class _MediaItemViewerState extends ConsumerState<_MediaItemViewer> {
  String? _motionVideoPath;
  bool _isCheckingMotion = false;
  bool _isPlayingLive = false;
  VideoPlayerController? _liveController;

  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _isLoadingCloudStream = false;
  double _playbackSpeed = 1.0;
  bool _isMuted = false;
  bool _isLooping = true;
  bool _showCenterPlayIndicator = false;
  Timer? _centerIndicatorTimer;
  Timer? _autoHideTimer;

  File? _fullResFile;
  Uint8List? _thumbBytes;
  bool _isLoadingFullRes = true;

  late final TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;

  bool get _isVideo =>
      widget.item.mimeType.startsWith('video') ||
      widget.item.filename.toLowerCase().endsWith('.mp4') ||
      widget.item.filename.toLowerCase().endsWith('.mov') ||
      widget.item.filename.toLowerCase().endsWith('.mkv');

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    if (_isVideo) {
      _initVideoPlayer();
    } else {
      _loadPhotoData();
      _checkMotionPhoto();
    }
  }

  Future<void> _loadPhotoData() async {
    final cached = ThumbnailCacheService().getFromMemory(widget.item.localId);
    if (cached != null) {
      if (mounted) setState(() => _thumbBytes = cached);
    } else {
      ThumbnailCacheService()
          .getThumbnail(
        id: widget.item.localId,
        diskPath: widget.item.thumbnailPath,
        isVideo: false,
      )
          .then((bytes) {
        if (mounted && bytes != null) setState(() => _thumbBytes = bytes);
      });
    }

    if (!widget.item.localId.startsWith('tg_') &&
        !widget.item.localId.startsWith('gp_')) {
      try {
        final asset = await AssetEntity.fromId(widget.item.localId);
        final file = await asset?.file;
        if (mounted) {
          setState(() {
            _fullResFile = file;
            _isLoadingFullRes = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingFullRes = false);
      }
    } else if (widget.item.thumbnailPath != null &&
        File(widget.item.thumbnailPath!).existsSync()) {
      if (mounted) {
        setState(() {
          _fullResFile = File(widget.item.thumbnailPath!);
          _isLoadingFullRes = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingFullRes = false);
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _centerIndicatorTimer?.cancel();
    _transformationController.dispose();
    _liveController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final matrix = Matrix4.identity()
        ..setEntry(0, 0, 2.2)
        ..setEntry(1, 1, 2.2)
        ..setEntry(0, 3, -position.dx * 1.2)
        ..setEntry(1, 3, -position.dy * 1.2);
      _transformationController.value = matrix;
    }
    HapticFeedback.selectionClick();
  }

  Future<void> _checkMotionPhoto() async {
    if (_isCheckingMotion) return;
    _isCheckingMotion = true;

    try {
      final asset = await AssetEntity.fromId(widget.item.localId);
      final file = await asset?.file;
      if (file != null && await file.exists()) {
        final motionExtractor = ref.read(motionPhotoExtractorProvider);
        final motionPath = await motionExtractor.extractMotionVideo(file.path);
        if (mounted && motionPath != null) {
          setState(() => _motionVideoPath = motionPath);
        }
      }
    } catch (_) {}
  }

  Future<void> _initVideoPlayer() async {
    setState(() => _isLoadingCloudStream = true);
    try {
      final asset = await AssetEntity.fromId(widget.item.localId);
      File? videoFile = await asset?.file;

      if (videoFile == null || !await videoFile.exists()) {
        final streamService = ref.read(cloudVideoStreamServiceProvider);
        final cloudPath = await streamService.getStreamableVideoPath(
          telegramFileId: widget.item.telegramMsgId ?? 0,
          fallbackLocalPath: widget.item.localId,
        );
        if (cloudPath != null) {
          videoFile = File(cloudPath);
        }
      }

      if (videoFile != null && await videoFile.exists()) {
        _videoPlayerController = VideoPlayerController.file(videoFile)
          ..initialize().then((_) async {
            if (mounted) {
              await _videoPlayerController!.setLooping(true);
              await _videoPlayerController!.setVolume(1.0);
              await _videoPlayerController!.play();
              _resetAutoHideTimer();
              setState(() {
                _isVideoInitialized = true;
                _isLoadingCloudStream = false;
              });
            }
          });
      } else {
        if (mounted) setState(() => _isLoadingCloudStream = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCloudStream = false);
    }
  }

  bool _isLiveMuted = false;

  void _startLivePlayback() async {
    if (_motionVideoPath == null) return;
    HapticFeedback.mediumImpact();

    _liveController?.dispose();
    _liveController = VideoPlayerController.file(File(_motionVideoPath!));
    await _liveController!.initialize();
    await _liveController!.setVolume(_isLiveMuted ? 0.0 : 1.0);
    await _liveController!.setLooping(true);
    await _liveController!.play();

    if (mounted) {
      setState(() => _isPlayingLive = true);
    }
  }

  void _stopLivePlayback() {
    if (!_isPlayingLive) return;
    HapticFeedback.lightImpact();
    _liveController?.pause();
    if (mounted) {
      setState(() => _isPlayingLive = false);
    }
  }

  void _resetAutoHideTimer() {
    _autoHideTimer?.cancel();
    if (_isVideoInitialized &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isPlaying) {
      _autoHideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted &&
            _videoPlayerController != null &&
            _videoPlayerController!.value.isPlaying) {
          widget.onHideControls();
        }
      });
    }
  }

  void _togglePlayPause() {
    if (_videoPlayerController == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        _autoHideTimer?.cancel();
      } else {
        _videoPlayerController!.play();
        _resetAutoHideTimer();
      }
      _showCenterPlayIndicator = true;
    });
    _centerIndicatorTimer?.cancel();
    _centerIndicatorTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showCenterPlayIndicator = false);
    });
  }

  void _toggleMute() {
    if (_videoPlayerController == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isMuted = !_isMuted;
      _videoPlayerController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _resetAutoHideTimer();
  }

  void _toggleLoop() {
    if (_videoPlayerController == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isLooping = !_isLooping;
      _videoPlayerController!.setLooping(_isLooping);
    });
    _resetAutoHideTimer();
  }

  void _cyclePlaybackSpeed() {
    if (_videoPlayerController == null) return;
    final speeds = [0.5, 1.0, 1.5, 2.0];
    final nextIdx = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    final newSpeed = speeds[nextIdx];
    setState(() => _playbackSpeed = newSpeed);
    _videoPlayerController!.setPlaybackSpeed(newSpeed);
  }

  void _seekRelative(Duration delta) {
    if (_videoPlayerController == null) return;
    HapticFeedback.lightImpact();
    final current = _videoPlayerController!.value.position;
    final duration = _videoPlayerController!.value.duration;
    final target = current + delta;
    if (target < Duration.zero) {
      _videoPlayerController!.seekTo(Duration.zero);
    } else if (target > duration) {
      _videoPlayerController!.seekTo(duration);
    } else {
      _videoPlayerController!.seekTo(target);
    }
    _resetAutoHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final thumbPath = widget.item.thumbnailPath;
    final hasThumb = thumbPath != null &&
        thumbPath.isNotEmpty &&
        File(thumbPath).existsSync();

    if (_isVideo) {
      return ViewerVideoPlayer(
        controller: _videoPlayerController,
        isInitialized: _isVideoInitialized,
        isLoadingStream: _isLoadingCloudStream,
        showControls: widget.showControls,
        rotationQuarterTurns: widget.rotationQuarterTurns,
        playbackSpeed: _playbackSpeed,
        isMuted: _isMuted,
        isLooping: _isLooping,
        showCenterPlayIndicator: _showCenterPlayIndicator,
        fallbackThumbnailPath: widget.item.thumbnailPath,
        onTap: () {
          widget.onTap();
          if (!widget.showControls) {
            _resetAutoHideTimer();
          }
        },
        onTogglePlayPause: _togglePlayPause,
        onToggleMute: _toggleMute,
        onToggleLoop: _toggleLoop,
        onCycleSpeed: _cyclePlaybackSpeed,
        onSeekRelative: _seekRelative,
      );
    }

    // Photo / Live Motion Photo Viewer
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          onDoubleTapDown: (details) => _doubleTapDetails = details,
          onDoubleTap: _handleDoubleTap,
          onLongPressStart: (_) => _startLivePlayback(),
          onLongPressEnd: (_) => _stopLivePlayback(),
          child: Hero(
            tag: 'media_${widget.item.localId}',
            flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
              return Material(
                color: Colors.transparent,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: toHeroContext.widget,
                ),
              );
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: RotatedBox(
                  quarterTurns: widget.rotationQuarterTurns,
                  child: _isPlayingLive &&
                          _liveController != null &&
                          _liveController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _liveController!.value.aspectRatio,
                          child: VideoPlayer(_liveController!),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_thumbBytes != null)
                              Image.memory(_thumbBytes!, fit: BoxFit.contain)
                            else if (hasThumb)
                              Image.file(
                                File(widget.item.thumbnailPath!),
                                fit: BoxFit.contain,
                              )
                            else
                              const ShimmerLoading(
                                width: double.infinity,
                                height: 380,
                              ),
                            if (_fullResFile != null &&
                                _fullResFile!.existsSync())
                              Image.file(_fullResFile!, fit: BoxFit.contain),
                            if (_isLoadingFullRes &&
                                _fullResFile == null &&
                                _thumbBytes == null &&
                                !hasThumb)
                              const ShimmerLoading(
                                width: double.infinity,
                                height: 380,
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),

        // Live Photo Pill Badge
        if (_motionVideoPath != null) ...[
          Positioned(
            top: 100,
            left: 20,
            child: AnimatedOpacity(
              opacity: widget.showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _isPlayingLive
                      ? AppColors.systemGreen.withValues(alpha: 0.85)
                      : Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isPlayingLive
                        ? AppColors.systemGreen
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.motion_photos_on_rounded,
                      size: 14,
                      color: _isPlayingLive ? Colors.black : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: _isPlayingLive ? Colors.black : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: 20,
            child: AnimatedOpacity(
              opacity: widget.showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isLiveMuted = !_isLiveMuted;
                    _liveController?.setVolume(_isLiveMuted ? 0.0 : 1.0);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isLiveMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
