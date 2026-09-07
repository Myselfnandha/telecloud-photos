import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/tables/media_table.dart';
import '../../../core/di/providers.dart';
import '../../../shared/widgets/m3e/m3e_card.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';

/// Screen 2: "Photos Timeline"
/// Material 3 Expressive main chronological gallery with On This Day memories,
/// chip filter group, sticky date headers, and stacked list items.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  String _selectedFilter = 'All Photos';
  final List<String> _filters = [
    'All Photos',
    'Cloud Synced',
    'Motion Photos',
    'Favorites',
  ];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final asyncMedia = ref.watch(allMediaStreamProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        title: const Text('TeleCloud Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            tooltip: 'Settings & Account',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bold text "Memories • On This Day" at 18sp
            Text(
              'Memories • On This Day',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Elevated card with auto_awesome icon placeholder
            M3ECard(
              variant: M3ECardVariant.elevated,
              placeholderIcon: Icons.auto_awesome,
              headline: '1 Year Ago Today',
              body: 'August 28, 2025 • Summer Road Trip (24 photos)',
              onTap: () => _openViewer('memory_road_trip_2025'),
            ),
            const SizedBox(height: 16),

            // Chip Group: "All Photos" (selected), "Cloud Synced", "Motion Photos", "Favorites"
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (val) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Bold text "Today • 14 photos" at 16sp
            Text(
              'Today • 14 photos',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            // Stacked List of 3 items for Today
            M3EStackedList(
              items: [
                M3EListItemData(
                  title: 'DSC_0492_RAW.dng',
                  subtitle: 'Sony A7IV • 61 MP RAW • Synced to 📷 Camera',
                  leadingIcon: Icons.camera_alt,
                  trailing: Icon(
                    Icons.cloud_done,
                    color: const Color(0xFF30D158),
                    size: 20,
                  ),
                  onTap: () => _openViewer('DSC_0492_RAW.dng'),
                ),
                M3EListItemData(
                  title: 'MVIMG_20260907_174012.mp4',
                  subtitle: 'Motion Photo • 1080p60 • Synced',
                  leadingIcon: Icons.motion_photos_on,
                  trailing: Icon(
                    Icons.cloud_done,
                    color: const Color(0xFF30D158),
                    size: 20,
                  ),
                  onTap: () => _openViewer('MVIMG_20260907_174012.mp4'),
                ),
                M3EListItemData(
                  title: 'Screenshot_20260907.png',
                  subtitle: '1080x2400 • Queued for Upload (4.2 MB)',
                  leadingIcon: Icons.screenshot,
                  trailing: Icon(
                    Icons.cloud_upload,
                    color: scheme.primary,
                    size: 20,
                  ),
                  onTap: () => _openViewer('Screenshot_20260907.png'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bold text "Yesterday • 8 photos" at 16sp
            Text(
              'Yesterday • 8 photos',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            // Stacked List for Yesterday
            M3EStackedList(
              items: [
                M3EListItemData(
                  title: 'PXL_20260906_181420.jpg',
                  subtitle: 'Pixel 9 Pro • 50 MP • Synced',
                  leadingIcon: Icons.image,
                  trailing: Icon(
                    Icons.cloud_done,
                    color: const Color(0xFF30D158),
                    size: 20,
                  ),
                  onTap: () => _openViewer('PXL_20260906_181420.jpg'),
                ),
              ],
            ),

            // Live items from Drift SQLite (if user has real scanned camera roll items)
            asyncMedia.maybeWhen(
              data: (items) {
                if (items.isEmpty) return const SizedBox(height: 32);
                final realExtraItems = items
                    .where((i) =>
                        i.filename != 'DSC_0492_RAW.dng' &&
                        i.filename != 'MVIMG_20260907_174012.mp4' &&
                        i.filename != 'Screenshot_20260907.png' &&
                        i.filename != 'PXL_20260906_181420.jpg')
                    .take(6)
                    .toList();

                if (realExtraItems.isEmpty) return const SizedBox(height: 32);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Camera Roll • ${items.length} Local Photos',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    M3EStackedList(
                      items: realExtraItems.map((item) {
                        final isUploaded = item.uploadStatus == UploadStatus.done;
                        final isVideo = item.mimeType.startsWith('video');
                        final sizeMB = (item.fileSizeBytes ?? 0) / (1024 * 1024);
                        return M3EListItemData(
                          title: item.filename,
                          subtitle:
                              '${sizeMB.toStringAsFixed(1)} MB • ${isUploaded ? "Synced" : "Local"}',
                          leadingIcon: isVideo ? Icons.videocam : Icons.photo,
                          trailing: Icon(
                            isUploaded ? Icons.cloud_done : Icons.cloud_upload_outlined,
                            color: isUploaded ? const Color(0xFF30D158) : scheme.primary,
                            size: 20,
                          ),
                          onTap: () => _openViewer(item.localId),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
              orElse: () => const SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}
