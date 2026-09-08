import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/media_table.dart';
import '../../../core/di/providers.dart';
import '../controllers/timeline_zoom_controller.dart';
import '../widgets/memories_carousel.dart';
import '../widgets/timeline_date_header.dart';
import '../widgets/timeline_photo_grid.dart';

/// Screen 2: "Photos Timeline"
/// 100% Real Material 3 Expressive chronological gallery powered by SQLite & Telegram Cloud.
/// Real On This Day memories, chip filter group, fluid zoom grid, and dynamic date headers.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final String _selectedFilter = 'All Photos';
  TimelineTier _tier = TimelineTier.dailyGrid;
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;



  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      try {
        ref.read(mediaScannerProvider).scanCameraRoll();
      } catch (_) {}
    });
  }

  void _openViewer(String mediaId) {
    HapticFeedback.lightImpact();
    context.push('/viewer/$mediaId');
  }

  void _toggleSelection(MediaItem item) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(item.localId)) {
        _selectedIds.remove(item.localId);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(item.localId);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  void _cycleZoomTier() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_tier == TimelineTier.dailyGrid) {
        _tier = TimelineTier.monthlyGrid;
      } else if (_tier == TimelineTier.monthlyGrid) {
        _tier = TimelineTier.yearlyMosaic;
      } else {
        _tier = TimelineTier.dailyGrid;
      }
    });
  }

  List<MediaItem> _applyFilter(List<MediaItem> allItems) {
    switch (_selectedFilter) {
      case 'Cloud Synced':
        return allItems.where((i) => i.uploadStatus == UploadStatus.done).toList();
      case 'Motion Photos':
        return allItems.where((i) {
          final isVid = i.mimeType.startsWith('video');
          final fn = i.filename.toLowerCase();
          return isVid || fn.endsWith('.mp4') || fn.endsWith('.mov') || fn.endsWith('.mkv');
        }).toList();
      case 'Favorites':
        return allItems.where((i) => i.isFavorite).toList();
      case 'All Photos':
      default:
        return allItems;
    }
  }

  Map<DateTime, List<MediaItem>> _groupByDay(List<MediaItem> items) {
    final Map<DateTime, List<MediaItem>> grouped = {};
    for (final item in items) {
      final dt = item.capturedAt;
      final dayKey = DateTime(dt.year, dt.month, dt.day);
      grouped.putIfAbsent(dayKey, () => []).add(item);
    }
    return grouped;
  }

  String _formatDateHeader(DateTime dateKey) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (dateKey == today) {
      return 'Today';
    } else if (dateKey == yesterday) {
      return 'Yesterday';
    } else if (dateKey.year == now.year) {
      return DateFormat('MMMM d').format(dateKey);
    } else {
      return DateFormat('MMMM d, yyyy').format(dateKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final asyncMedia = ref.watch(allMediaStreamProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        title: _isSelectionMode
            ? Text('${_selectedIds.length} Selected')
            : const Text('TeleCloud Photos'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        actions: [
          if (!_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search Gallery',
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/search');
              },
            ),
            IconButton(
              icon: Icon(
                _tier == TimelineTier.dailyGrid
                    ? Icons.grid_view_rounded
                    : (_tier == TimelineTier.monthlyGrid
                        ? Icons.view_module_rounded
                        : Icons.view_comfy_alt_rounded),
              ),
              tooltip: 'Zoom: ${_tier.label}',
              onPressed: _cycleZoomTier,
            ),
            IconButton(
              icon: const Icon(Icons.account_circle, size: 28),
              tooltip: 'Settings & Account',
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/settings');
              },
            ),
          ],
        ],
      ),
      body: asyncMedia.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error loading gallery: $err', style: TextStyle(color: scheme.error)),
          ),
        ),
        data: (allItems) {
          final filteredItems = _applyFilter(allItems);
          final grouped = _groupByDay(filteredItems);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Real "On This Day" Memories Carousel (auto-hides if no memories exist)
              if (!_isSelectionMode)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: MemoriesCarousel(),
                  ),
                ),

              // Empty State or Grouped Photo Grid
              if (filteredItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 64, color: scheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == 'All Photos'
                                ? 'No Photos Yet'
                                : 'No $_selectedFilter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFilter == 'All Photos'
                                ? 'Your device camera roll will sync and display here.'
                                : 'Try selecting another filter chip above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          if (_selectedFilter == 'All Photos') ...[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                ref.read(mediaScannerProvider).scanCameraRoll();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Scan Camera Roll'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dayKey = grouped.keys.elementAt(index);
                      final dayItems = grouped[dayKey]!;
                      final dateLabel = _formatDateHeader(dayKey);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TimelineDateHeader(
                            dateLabel: dateLabel,
                            itemCount: dayItems.length,
                            isYearly: _tier == TimelineTier.yearlyMosaic,
                            isAllPhotos: _tier == TimelineTier.allPhotos,
                          ),
                          TimelinePhotoGrid(
                            items: dayItems,
                            tier: _tier,
                            isSelectionMode: _isSelectionMode,
                            selectedIds: _selectedIds,
                            showSyncBadges: true,
                            onItemTap: (item) {
                              if (_isSelectionMode) {
                                _toggleSelection(item);
                              } else {
                                _openViewer(item.localId);
                              }
                            },
                            onItemLongPress: (item) {
                              _toggleSelection(item);
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                    childCount: grouped.keys.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}
