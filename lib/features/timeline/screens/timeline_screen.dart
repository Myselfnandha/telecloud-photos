import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../core/di/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables/media_table.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_elevation.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/app_motion.dart';
import '../../../shared/widgets/google_photos_badge.dart';
import '../../../shared/theme/theme_provider.dart';
import '../../../shared/widgets/shimmer_grid.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/fast_scroller.dart';
import '../controllers/timeline_zoom_controller.dart';
import '../widgets/memories_carousel.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ScrollController _scrollController;
  TimelineTier _currentTier = TimelineTier.dailyGrid;

  // Real-time gesture scaling variables
  bool _isPinching = false;
  double _pinchScale = 1.0;
  Offset _pinchFocalPoint = Offset.zero;
  TimelineTier _previewTier = TimelineTier.dailyGrid;

  // Floating Glassmorphic Badge visibility
  bool _showTierBadge = false;
  Timer? _badgeTimer;

  // Snap animation controller for smooth spring release
  late final AnimationController _snapAnimationController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _previewTier = _currentTier;

    _snapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _snapAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _snapAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.microtask(() {
      ref.read(mediaScannerProvider).scanCameraRoll();
    });
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _snapAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<MediaItem>? _cachedRawItems;
  Map<String, List<MediaItem>>? _cachedGrouped;

  Map<String, List<MediaItem>> _groupByDate(List<MediaItem> items) {
    if (identical(_cachedRawItems, items) && _cachedGrouped != null) {
      return _cachedGrouped!;
    }
    if (_cachedRawItems != null &&
        _cachedRawItems!.length == items.length &&
        _cachedRawItems!.firstOrNull?.localId == items.firstOrNull?.localId &&
        _cachedRawItems!.lastOrNull?.localId == items.lastOrNull?.localId) {
      return _cachedGrouped!;
    }

    final grouped = <String, List<MediaItem>>{};
    for (final item in items) {
      final header = _formatDateHeader(item.capturedAt);
      grouped.putIfAbsent(header, () => []).add(item);
    }
    _cachedRawItems = items;
    _cachedGrouped = grouped;
    return grouped;
  }

  String _formatDateHeader(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _triggerTierBadge(TimelineTier tier) {
    _badgeTimer?.cancel();
    setState(() {
      _showTierBadge = true;
      _previewTier = tier;
    });
    _badgeTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _showTierBadge = false;
        });
      }
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (details.pointerCount >= 2) {
      _snapAnimationController.stop();
      setState(() {
        _isPinching = true;
        _pinchScale = 1.0;
        _pinchFocalPoint = details.localFocalPoint;
        _previewTier = _currentTier;
        _showTierBadge = true;
      });
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2) {
      final scale = details.scale.clamp(0.4, 2.8);
      TimelineTier prospectiveTier = _currentTier;

      if (scale > 1.6) {
        prospectiveTier = _currentTier.nextZoomIn.nextZoomIn;
      } else if (scale > 1.18) {
        prospectiveTier = _currentTier.nextZoomIn;
      } else if (scale < 0.55) {
        prospectiveTier = _currentTier.nextZoomOut.nextZoomOut;
      } else if (scale < 0.82) {
        prospectiveTier = _currentTier.nextZoomOut;
      }

      if (prospectiveTier != _previewTier) {
        HapticFeedback.selectionClick();
      }

      setState(() {
        _isPinching = true;
        _pinchScale = scale;
        _pinchFocalPoint = details.localFocalPoint;
        _previewTier = prospectiveTier;
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!_isPinching) return;

    TimelineTier targetTier = _currentTier;
    if (_pinchScale > 1.6) {
      targetTier = _currentTier.nextZoomIn.nextZoomIn;
    } else if (_pinchScale > 1.18) {
      targetTier = _currentTier.nextZoomIn;
    } else if (_pinchScale < 0.55) {
      targetTier = _currentTier.nextZoomOut.nextZoomOut;
    } else if (_pinchScale < 0.82) {
      targetTier = _currentTier.nextZoomOut;
    }

    final hasChanged = targetTier != _currentTier;
    if (hasChanged) {
      HapticFeedback.mediumImpact();
    }

    // Animate scale back to 1.0
    _snapAnimation =
        Tween<double>(begin: _pinchScale, end: 1.0).animate(
          CurvedAnimation(
            parent: _snapAnimationController,
            curve: Curves.easeOutCubic,
          ),
        )..addListener(() {
          setState(() {
            _pinchScale = _snapAnimation.value;
          });
        });

    _snapAnimationController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isPinching = false;
          _pinchScale = 1.0;
          _currentTier = targetTier;
        });
        _triggerTierBadge(targetTier);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor = isLight ? Colors.black87 : Colors.white;
    final asyncMedia = ref.watch(allMediaStreamProvider);
    final gridMode = ref.watch(gridDisplayModeProvider);

    final childAspectRatio = _currentTier == TimelineTier.singlePhoto
        ? 0.95
        : (gridMode == GridDisplayMode.uncropped ? 0.82 : 1.0);
    final boxFit = gridMode == GridDisplayMode.aspectRatioFit
        ? BoxFit.contain
        : BoxFit.cover;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'TeleCloud',
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: isLight ? Colors.black87 : Colors.white70,
              size: 22,
            ),
            tooltip: 'Search Photos & Videos',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/search');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          asyncMedia.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 72,
                        color: isLight
                            ? Colors.grey.shade400
                            : Colors.grey.shade800,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No photos found on device',
                        style: TextStyle(
                          color: isLight
                              ? Colors.grey.shade700
                              : Colors.grey.shade500,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final grouped = _groupByDate(items);
              final dateLabels = grouped.keys.toList();
              final dateEntries = grouped.entries.toList();

              Widget scrollView = CustomScrollView(
                key: const PageStorageKey('timeline_scroll_view'),
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // iOS Native Rubber-Band Pull to Refresh Control
                  CupertinoSliverRefreshControl(
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      ref.invalidate(allMediaStreamProvider);
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                  ),

                  // Flashback Memories Carousel (in daily & single photo views)
                  if (_currentTier == TimelineTier.dailyGrid ||
                      _currentTier == TimelineTier.singlePhoto)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: MemoriesCarousel(),
                      ),
                    ),

                  // Virtualized Unified Sectioned Date List
                  SliverList.builder(
                    itemCount: dateEntries.length,
                    itemBuilder: (context, index) {
                      final entry = dateEntries[index];
                      final isYearly = _currentTier == TimelineTier.yearlyMosaic;
                      final isSingle = _currentTier == TimelineTier.singlePhoto;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              isYearly ? 10 : 20,
                              16,
                              isYearly ? 4 : 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: isYearly ? 14 : (isSingle ? 20 : 18),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  '${entry.value.length} ${entry.value.length == 1 ? 'item' : 'items'}',
                                  style: TextStyle(
                                    color: isLight
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade500,
                                    fontSize: isYearly ? 11 : 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSingle ? 12 : 2,
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entry.value.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _currentTier.columns,
                                mainAxisSpacing: isYearly
                                    ? 1.0
                                    : (_currentTier == TimelineTier.monthlyGrid
                                        ? 1.5
                                        : (isSingle ? 12.0 : 2.5)),
                                crossAxisSpacing: isYearly
                                    ? 1.0
                                    : (_currentTier == TimelineTier.monthlyGrid
                                        ? 1.5
                                        : (isSingle ? 12.0 : 2.5)),
                                childAspectRatio: childAspectRatio,
                              ),
                              itemBuilder: (context, itemIdx) {
                                final item = entry.value[itemIdx];
                                return RepaintBoundary(
                                  child: _MediaTile(
                                    key: ValueKey(item.localId),
                                    item: item,
                                    boxFit: boxFit,
                                    tier: _currentTier,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              );

              Widget body = scrollView;
              if (_isPinching) {
                body = Transform(
                  transform: Matrix4.identity()
                    ..translateByDouble(
                      _pinchFocalPoint.dx,
                      _pinchFocalPoint.dy,
                      0.0,
                      0.0,
                    )
                    ..scaleByDouble(_pinchScale, _pinchScale, 1.0, 1.0)
                    ..translateByDouble(
                      -_pinchFocalPoint.dx,
                      -_pinchFocalPoint.dy,
                      0.0,
                      0.0,
                    ),
                  alignment: Alignment.center,
                  child: body,
                );
              }

              return GestureDetector(
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onScaleEnd: _handleScaleEnd,
                child: FastScroller(
                  scrollController: _scrollController,
                  dateLabels: dateLabels,
                  isLight: isLight,
                  child: body,
                ),
              );
            },
            loading: () => const ShimmerGrid(itemCount: 24),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load timeline',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A84FF),
                    ),
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      ref.read(mediaScannerProvider).scanCameraRoll();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Floating Glassmorphic Tier Badge
          Positioned(
            top: AppSpacing.m,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showTierBadge ? 1.0 : 0.0,
              duration: AppMotion.durationMedium,
              curve: AppMotion.curveStandard,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.l,
                    vertical: AppSpacing.s,
                  ),
                  decoration: BoxDecoration(
                    color: isLight
                        ? const Color(0xF2FFFFFF)
                        : const Color(0xF01C1C1E),
                    borderRadius: AppRadii.borderFull,
                    border: Border.all(
                      color: isLight
                          ? AppColors.glassBorderLight
                          : AppColors.glassBorderDark,
                      width: 0.8,
                    ),
                    boxShadow: AppElevation.glassPillShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (_isPinching ? _previewTier : _currentTier).icon,
                        color: AppColors.primaryBlue,
                        size: AppIcons.s,
                      ),
                      AppSpacing.gapHorizontalS,
                      Text(
                        (_isPinching ? _previewTier : _currentTier).label,
                        style: AppTypography.labelLarge(
                          color: isLight
                              ? AppColors.lightTextPrimary
                              : AppColors.darkTextPrimary,
                        ).copyWith(
                          fontWeight: AppTypography.bold,
                          letterSpacing: -0.2,
                        ),
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
}

class _MediaTile extends StatefulWidget {
  final MediaItem item;
  final BoxFit boxFit;
  final TimelineTier tier;

  const _MediaTile({
    super.key,
    required this.item,
    required this.boxFit,
    required this.tier,
  });

  @override
  State<_MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<_MediaTile>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _bytes;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _MediaTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.localId != widget.item.localId) {
      _loadThumbnail();
    }
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

    final isVideo = widget.item.mimeType.startsWith('video');
    final bytes = await ThumbnailCacheService().getThumbnail(
      id: widget.item.localId,
      diskPath: widget.item.thumbnailPath,
      isVideo: isVideo,
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

    final isVideo = widget.item.mimeType.startsWith('video');
    final isSinglePhoto = widget.tier == TimelineTier.singlePhoto;
    final isYearly = widget.tier == TimelineTier.yearlyMosaic;
    final cacheDim = isSinglePhoto ? 600 : (isYearly ? 128 : 256);

    Widget imageWidget;
    if (_bytes != null) {
      imageWidget = Image.memory(
        _bytes!,
        fit: widget.boxFit,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        errorBuilder: (context, error, stackTrace) => const ShimmerLoading(),
      );
    } else if (widget.item.thumbnailPath != null &&
        widget.item.thumbnailPath!.isNotEmpty) {
      imageWidget = Image.file(
        File(widget.item.thumbnailPath!),
        fit: widget.boxFit,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        errorBuilder: (context, error, stackTrace) => const ShimmerLoading(),
      );
    } else {
      imageWidget = const ShimmerLoading();
    }

    return GestureDetector(
      onTap: () => context.push('/viewer/${widget.item.localId}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'media_${widget.item.localId}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                isSinglePhoto ? 14 : (isYearly ? 1 : 3),
              ),
              child: Container(
                color: const Color(0xFF141416),
                child: imageWidget,
              ),
            ),
          ),
          if (widget.item.isFavorite && !isYearly)
            Positioned(
              top: isSinglePhoto ? 10 : 4,
              right: isSinglePhoto ? 10 : 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: const Color(0xFFFF453A),
                  size: isSinglePhoto ? 16 : 12,
                ),
              ),
            ),
          if (widget.item.localId.startsWith('tg_') && !isYearly)
            Positioned(
              top: isSinglePhoto ? 10 : 4,
              left: isSinglePhoto ? 10 : 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_queue_rounded,
                  color: Colors.white,
                  size: isSinglePhoto ? 14 : 11,
                ),
              ),
            ),
          if (widget.item.localId.startsWith('gp_') && !isYearly)
            Positioned(
              top: isSinglePhoto ? 10 : 4,
              left: isSinglePhoto ? 10 : 4,
              child: GooglePhotosBadge(compact: !isSinglePhoto),
            ),
          if (isVideo && !isYearly)
            Positioned(
              bottom: isSinglePhoto ? 10 : 4,
              left: isSinglePhoto ? 10 : 4,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSinglePhoto ? 8 : 5,
                  vertical: isSinglePhoto ? 4 : 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(isSinglePhoto ? 6 : 4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: isSinglePhoto ? 16 : 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSinglePhoto ? 11 : 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.item.uploadStatus == UploadStatus.pending && !isYearly)
            Positioned(
              bottom: isSinglePhoto ? 10 : 4,
              right: isSinglePhoto ? 10 : 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white70,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
