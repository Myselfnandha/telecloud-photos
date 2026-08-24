import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import '../../../core/di/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../widgets/add_to_album_sheet.dart';
import '../widgets/exif_info_sheet.dart';
import '../widgets/video_gesture_overlay.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  final String mediaId;

  const MediaViewerScreen({super.key, required this.mediaId});

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<MediaItem> _items = [];
  bool _initialized = false;
  bool _showUiOverlays = true;
  double _dragOffsetY = 0.0;
  bool _isDragging = false;
  int _rotationQuarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
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

  String _getResolutionLabel(int? width, int? height) {
    if (width == null || height == null) return 'HD';
    final maxDim = width > height ? width : height;
    if (maxDim >= 3840) return '4K UHD';
    if (maxDim >= 2560) return '2K QHD';
    if (maxDim >= 1920) return '1080p FHD';
    if (maxDim >= 1280) return '720p HD';
    return '$width×$height';
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
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Moved to Trash'),
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

  @override
  Widget build(BuildContext context) {
    final asyncMedia = ref.watch(allMediaStreamProvider);
    final bgOpacity = (1.0 - (_dragOffsetY.abs() / 360)).clamp(0.0, 1.0);
    final currentScale = (1.0 - (_dragOffsetY.abs() / 1500)).clamp(0.80, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity),
      extendBodyBehindAppBar: true,
      appBar: (_showUiOverlays && !_isDragging)
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: _items.isNotEmpty && _currentIndex < _items.length
                  ? Column(
                      children: [
                        Text(
                          _items[_currentIndex].capturedAt
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getResolutionLabel(
                            _items[_currentIndex].width,
                            _items[_currentIndex].height,
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
              actions: [
                if (_items.isNotEmpty && _currentIndex < _items.length) ...[
                  IconButton(
                    icon: Icon(
                      _items[_currentIndex].isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _items[_currentIndex].isFavorite
                          ? AppColors.systemRed
                          : Colors.white,
                    ),
                    onPressed: () async {
                      final item = _items[_currentIndex];
                      final newFav = !item.isFavorite;
                      await ref
                          .read(mediaDaoProvider)
                          .toggleFavorite(item.localId, newFav);
                      setState(() {
                        _items[_currentIndex] = item.copyWith(
                          isFavorite: newFav,
                        );
                      });
                      HapticFeedback.lightImpact();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: () {
                      _showInfoSheet(context, _items[_currentIndex]);
                    },
                  ),
                ],
              ],
            )
          : null,
      bottomNavigationBar:
          (_showUiOverlays &&
              !_isDragging &&
              _items.isNotEmpty &&
              _currentIndex < _items.length)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                border: const Border(top: BorderSide(color: Colors.white12)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Share
                    IconButton(
                      tooltip: 'Share',
                      icon: const Icon(
                        Icons.ios_share_rounded,
                        color: Colors.white,
                        size: AppIcons.m,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sharing photo...'),
                            backgroundColor: AppColors.primaryBlue,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),

                    // Rotate 90° Lossless
                    IconButton(
                      tooltip: 'Rotate 90°',
                      icon: const Icon(
                        Icons.rotate_90_degrees_cw_rounded,
                        color: Colors.white,
                        size: AppIcons.m,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _rotationQuarterTurns =
                              (_rotationQuarterTurns + 1) % 4;
                        });
                      },
                    ),

                    // Add to Album
                    IconButton(
                      tooltip: 'Add to Album',
                      icon: const Icon(
                        Icons.add_to_photos_rounded,
                        color: Colors.white,
                        size: AppIcons.m,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        AddToAlbumSheet.show(context, _items[_currentIndex]);
                      },
                    ),

                    // Info Sheet
                    IconButton(
                      tooltip: 'Details',
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: AppIcons.m,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showInfoSheet(context, _items[_currentIndex]);
                      },
                    ),

                    // Move to Trash
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.systemRed,
                        size: AppIcons.m,
                      ),
                      onPressed: _deleteCurrentItem,
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: asyncMedia.when(
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

          return GestureDetector(
            onVerticalDragUpdate: (details) {
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
            onVerticalDragEnd: (details) {
              if (_dragOffsetY > 110 ||
                  (details.primaryVelocity != null &&
                      details.primaryVelocity! > 600)) {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              } else {
                setState(() {
                  _dragOffsetY = 0.0;
                  _isDragging = false;
                });
              }
            },
            onVerticalDragCancel: () {
              setState(() {
                _dragOffsetY = 0.0;
                _isDragging = false;
              });
            },
            child: Transform.translate(
              offset: Offset(0, _dragOffsetY),
              child: Transform.scale(
                scale: currentScale,
                child: PageView.builder(
                  controller: _pageController,
                  physics: _isDragging
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  itemCount: items.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _rotationQuarterTurns = 0; // Reset rotation on swipe
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MediaItemViewer(
                      item: item,
                      onTap: _toggleUiOverlays,
                      showControls: _showUiOverlays && !_isDragging,
                      rotationQuarterTurns: _currentIndex == index
                          ? _rotationQuarterTurns
                          : 0,
                      onHideControls: () {
                        if (mounted && _showUiOverlays) {
                          setState(() => _showUiOverlays = false);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, s) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
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

  void _startLivePlayback() async {
    if (_motionVideoPath == null) return;
    HapticFeedback.mediumImpact();

    _liveController?.dispose();
    _liveController = VideoPlayerController.file(File(_motionVideoPath!));
    await _liveController!.initialize();
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

  bool _isMuted = false;
  bool _isLooping = true;
  bool _showCenterPlayIndicator = false;
  Timer? _centerIndicatorTimer;
  Timer? _autoHideTimer;

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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final thumbPath = widget.item.thumbnailPath;
    final hasThumb =
        thumbPath != null &&
        thumbPath.isNotEmpty &&
        File(thumbPath).existsSync();

    // 1. Apple Photos Video Player
    if (_isVideo) {
      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isVideoInitialized && _videoPlayerController != null)
              VideoGestureOverlay(
                controller: _videoPlayerController!,
                onTap: () {
                  widget.onTap();
                  if (!widget.showControls) {
                    _resetAutoHideTimer();
                  }
                },
                child: Center(
                  child: RotatedBox(
                    quarterTurns: widget.rotationQuarterTurns,
                    child: AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController!),
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  widget.onTap();
                  if (!widget.showControls) {
                    _resetAutoHideTimer();
                  }
                },
                child: Center(
                  child: RotatedBox(
                    quarterTurns: widget.rotationQuarterTurns,
                    child: hasThumb
                        ? Image.file(File(thumbPath), fit: BoxFit.contain)
                        : const ShimmerLoading(
                            width: double.infinity,
                            height: 380,
                          ),
                  ),
                ),
              ),

            // Loading Spinner
            if (_isLoadingCloudStream || (!_isVideoInitialized && !_isVideo))
              const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              ),

            // Play Indicator Overlay
            if (_showCenterPlayIndicator && _videoPlayerController != null)
              AnimatedOpacity(
                opacity: _showCenterPlayIndicator ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _videoPlayerController!.value.isPlaying
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),

            // Bottom Floating Apple Player Controls
            if (_isVideoInitialized && _videoPlayerController != null)
              Positioned(
                bottom: 30,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: widget.showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 240),
                  child: IgnorePointer(
                    ignoring: !widget.showControls,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: AppRadii.borderXL,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Scrubber Slider
                          ValueListenableBuilder(
                            valueListenable: _videoPlayerController!,
                            builder: (context, VideoPlayerValue val, _) {
                              final pos = val.position;
                              final dur = val.duration;
                              final posMs = pos.inMilliseconds.toDouble();
                              final durMs = dur.inMilliseconds > 0
                                  ? dur.inMilliseconds.toDouble()
                                  : 1.0;

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3.5,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 14,
                                          ),
                                      activeTrackColor: AppColors.primaryBlue,
                                      inactiveTrackColor: Colors.white24,
                                      thumbColor: Colors.white,
                                    ),
                                    child: Slider(
                                      value: posMs.clamp(0.0, durMs),
                                      min: 0.0,
                                      max: durMs,
                                      onChanged: (newPos) {
                                        _videoPlayerController!.seekTo(
                                          Duration(
                                            milliseconds: newPos.toInt(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(pos),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '-${_formatDuration(dur > pos ? dur - pos : Duration.zero)}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 2),

                          // Controls Bar: 10s back, Play/Pause, 10s fwd, Mute, Loop, Speed
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 10s Backward
                              IconButton(
                                icon: const Icon(
                                  Icons.replay_10_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () =>
                                    _seekRelative(const Duration(seconds: -10)),
                              ),

                              // Play / Pause
                              IconButton(
                                icon: Icon(
                                  _videoPlayerController!.value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _togglePlayPause,
                              ),

                              // 10s Forward
                              IconButton(
                                icon: const Icon(
                                  Icons.forward_10_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () =>
                                    _seekRelative(const Duration(seconds: 10)),
                              ),

                              // Mute Toggle
                              IconButton(
                                icon: Icon(
                                  _isMuted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  color: _isMuted
                                      ? AppColors.systemRed
                                      : Colors.white,
                                  size: 22,
                                ),
                                onPressed: _toggleMute,
                              ),

                              // Loop Toggle
                              IconButton(
                                icon: Icon(
                                  Icons.repeat_rounded,
                                  color: _isLooping
                                      ? AppColors.primaryBlue
                                      : Colors.white38,
                                  size: 22,
                                ),
                                onPressed: _toggleLoop,
                              ),

                              // Speed Chip
                              TextButton(
                                onPressed: _cyclePlaybackSpeed,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  backgroundColor: AppColors.primaryBlue
                                      .withValues(alpha: 0.15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  '${_playbackSpeed}x',
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // 2. Photo / Live Motion Photo Viewer
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
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: RotatedBox(
                  quarterTurns: widget.rotationQuarterTurns,
                  child:
                      _isPlayingLive &&
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
        if (_motionVideoPath != null)
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
      ],
    );
  }
}
