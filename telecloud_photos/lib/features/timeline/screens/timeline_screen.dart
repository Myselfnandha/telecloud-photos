import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/fast_scroller.dart';
import '../../../shared/widgets/selection_action_bar.dart';
import '../../../shared/widgets/shimmer_grid.dart';
import '../../viewer/widgets/add_to_album_sheet.dart';
import '../controllers/timeline_zoom_controller.dart';
import '../widgets/memories_carousel.dart';
import '../widgets/tier_badge_overlay.dart';
import '../widgets/timeline_date_header.dart';
import '../widgets/timeline_photo_grid.dart';

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
  int _activePointers = 0;

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<String> _selectedLocalIds = {};

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

    if (_currentTier == TimelineTier.yearlyMosaic) {
      return '${dt.year}';
    }
    if (_currentTier == TimelineTier.monthlyGrid) {
      return '${months[dt.month - 1]} ${dt.year}';
    }

    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final weekday = weekdays[dt.weekday - 1];
    return '$weekday, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _triggerTierBadge(TimelineTier tier) {
    _badgeTimer?.cancel();
    setState(() {
      _showTierBadge = true;
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
    if (details.pointerCount >= 2 || _activePointers >= 2) {
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
    if (details.pointerCount >= 2 || _isPinching) {
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
    _snapAnimation = Tween<double>(begin: _pinchScale, end: 1.0).animate(
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

  void _performBatchDelete(List<MediaItem> allItems) async {
    final count = _selectedLocalIds.length;
    final batchOps = ref.read(batchOperationsServiceProvider);
    await batchOps.batchDelete(_selectedLocalIds.toList());
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = false;
      _selectedLocalIds.clear();
    });
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Moved $count items to Trash'),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _performBatchShare(List<MediaItem> allItems) {
    final count = _selectedLocalIds.length;
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Sharing $count items...'),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _performBatchAddToAlbum(List<MediaItem> allItems) {
    final selectedItems =
        allItems.where((i) => _selectedLocalIds.contains(i.localId)).toList();
    if (selectedItems.isNotEmpty) {
      AddToAlbumSheet.show(context, selectedItems.first);
    }
  }

  void _performBatchDownload(List<MediaItem> allItems) {
    final count = _selectedLocalIds.length;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Queued $count items for original download'),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {
      _isSelectionMode = false;
      _selectedLocalIds.clear();
    });
  }

  void _performBatchToggleFavorite(List<MediaItem> allItems) async {
    final selectedItems =
        allItems.where((i) => _selectedLocalIds.contains(i.localId)).toList();
    final anyNotFavorite = selectedItems.any((i) => !i.isFavorite);
    final batchOps = ref.read(batchOperationsServiceProvider);
    await batchOps.batchToggleFavorite(
      _selectedLocalIds.toList(),
      isFavorite: anyNotFavorite,
    );
    setState(() {
      _isSelectionMode = false;
      _selectedLocalIds.clear();
    });
  }

  void _performBatchExport(List<MediaItem> allItems) async {
    final selectedItems =
        allItems.where((i) => _selectedLocalIds.contains(i.localId)).toList();
    final batchOps = ref.read(batchOperationsServiceProvider);
    final count = await batchOps.batchExport(selectedItems);
    setState(() {
      _isSelectionMode = false;
      _selectedLocalIds.clear();
    });
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Exported $count items to device storage'),
          backgroundColor: AppColors.successGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor = AppColors.textPrimary(context);
    final asyncMedia = ref.watch(allMediaStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                color: primaryTextColor,
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedLocalIds.clear();
                  });
                },
              )
            : null,
        title: _isSelectionMode
            ? Text(
                '${_selectedLocalIds.length} Selected',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : Row(
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
          if (_isSelectionMode)
            asyncMedia.maybeWhen(
              data: (items) => TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (_selectedLocalIds.length == items.length) {
                      _selectedLocalIds.clear();
                    } else {
                      _selectedLocalIds.addAll(items.map((i) => i.localId));
                    }
                  });
                },
                child: Text(
                  _selectedLocalIds.length == items.length
                      ? 'Deselect All'
                      : 'Select All',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
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
                          color: AppColors.textSecondary(context),
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
                key: const PageStorageKey('timeline_custom_scroll_view'),
                controller: _scrollController,
                physics: _isPinching
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(
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
                  if (!_isSelectionMode &&
                      (_currentTier == TimelineTier.dailyGrid ||
                          _currentTier == TimelineTier.singlePhoto))
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
                      final isYearly =
                          _currentTier == TimelineTier.yearlyMosaic;
                      final isSingle = _currentTier == TimelineTier.singlePhoto;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TimelineDateHeader(
                            dateLabel: entry.key,
                            itemCount: entry.value.length,
                            isYearly: isYearly,
                            isSingle: isSingle,
                          ),
                          TimelinePhotoGrid(
                            items: entry.value,
                            tier: _currentTier,
                            isSelectionMode: _isSelectionMode,
                            selectedIds: _selectedLocalIds,
                            onItemTap: (item) {
                              if (_isSelectionMode) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (_selectedLocalIds
                                      .contains(item.localId)) {
                                    _selectedLocalIds.remove(item.localId);
                                    if (_selectedLocalIds.isEmpty) {
                                      _isSelectionMode = false;
                                    }
                                  } else {
                                    _selectedLocalIds.add(item.localId);
                                  }
                                });
                              } else {
                                context.push('/viewer/${item.localId}');
                              }
                            },
                            onItemLongPress: (item) {
                              HapticFeedback.heavyImpact();
                              setState(() {
                                _isSelectionMode = true;
                                _selectedLocalIds.add(item.localId);
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
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

              return Listener(
                onPointerDown: (event) {
                  _activePointers++;
                  if (_activePointers >= 2 && !_isPinching) {
                    setState(() {
                      _isPinching = true;
                      _pinchScale = 1.0;
                      _pinchFocalPoint = event.localPosition;
                      _previewTier = _currentTier;
                      _showTierBadge = true;
                    });
                  }
                },
                onPointerUp: (event) {
                  _activePointers = (_activePointers - 1).clamp(0, 10);
                },
                onPointerCancel: (event) {
                  _activePointers = 0;
                },
                child: GestureDetector(
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onScaleEnd: _handleScaleEnd,
                  child: FastScroller(
                    scrollController: _scrollController,
                    dateLabels: dateLabels,
                    isLight: isLight,
                    child: body,
                  ),
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
                      backgroundColor: AppColors.primaryBlue,
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
          TierBadgeOverlay(
            activeTier: _isPinching ? _previewTier : _currentTier,
            isVisible: _showTierBadge,
          ),

          // Floating Selection Action Bar (Feature 5)
          if (_isSelectionMode)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: asyncMedia.maybeWhen(
                data: (items) => SelectionActionBar(
                  selectedCount: _selectedLocalIds.length,
                  onShare: () => _performBatchShare(items),
                  onAddToAlbum: () => _performBatchAddToAlbum(items),
                  onDownload: () => _performBatchDownload(items),
                  onToggleFavorite: () => _performBatchToggleFavorite(items),
                  onExport: () => _performBatchExport(items),
                  onDelete: () => _performBatchDelete(items),
                  onCancel: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedLocalIds.clear();
                    });
                  },
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
