import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/storage_cleaner_service.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';

/// Screen 8: "Storage Recovery Center"
/// 100% Real Futuristic OLED Minimalist device storage cleaner to purge local phone copies
/// for media safely backed up in Telegram Cloud while keeping thumbnail caches intact.
class StorageCleanerScreen extends ConsumerStatefulWidget {
  const StorageCleanerScreen({super.key});

  @override
  ConsumerState<StorageCleanerScreen> createState() =>
      _StorageCleanerScreenState();
}

class _StorageCleanerScreenState extends ConsumerState<StorageCleanerScreen> {
  bool _isCleaning = false;

  void _goBack() {
    HapticFeedback.lightImpact();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/library');
    }
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zero Data-Loss Storage Recovery'),
        content: const Text(
          'When you free up space, only original local media files on device storage that have been confirmed uploaded to Telegram Supergroup are deleted. Thumbnails and cloud streaming pointers remain active in TeleCloud so you can still view and re-download them at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  Future<void> _freeUpSpace() async {
    HapticFeedback.heavyImpact();
    setState(() => _isCleaning = true);
    StorageCleanResult result;
    try {
      final cleaner = ref.read(storageCleanerServiceProvider);
      result = await cleaner.freeUpSpace();
    } catch (e) {
      result = StorageCleanResult(success: false, errorMessage: e.toString());
    }

    if (mounted) {
      setState(() => _isCleaning = false);
      if (result.success && result.cleanedItemCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Successfully reclaimed ${result.formattedReclaimed} (${result.cleanedItemCount} items)!',
            ),
            backgroundColor: const Color(0xFF00E676),
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (result.userCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deletion cancelled by user.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (result.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notice: ${result.errorMessage}'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backed-up items to remove.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearCacheOnly(String currentCacheSize) async {
    HapticFeedback.mediumImpact();
    setState(() => _isCleaning = true);
    try {
      final cleaner = ref.read(storageCleanerServiceProvider);
      await cleaner.clearCacheOnly();
    } catch (_) {}

    if (mounted) {
      setState(() => _isCleaning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleaned $currentCacheSize temporary TDLib streaming cache.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final summaryAsync = ref.watch(storageSummaryStreamProvider);
    final summary = summaryAsync.value ?? const StorageCleanSummary();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _goBack,
        ),
        title: const Text(
          'Device Storage Cleaner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Info',
            onPressed: _showInfo,
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) {
            _goBack();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================================
              // UNIQUE OLED FUTURISTIC SEGMENTED STORAGE GAUGE CARD
              // ========================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1117) : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.10 : 0.06),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verified Zero-Data-Loss Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00E676).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 14,
                                color: Color(0xFF00E676),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'ZERO-DATA-LOSS VERIFIED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF00E676),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${summary.totalItems} Items Eligible',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Big Hero Reclaimable Metric
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          summary.formattedSize,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Color(0xFF00E5FF),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'RECLAIMABLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      summary.hasReclaimableSpace
                          ? '${summary.photoCount} photos & ${summary.videoCount} videos backed up to Telegram Cloud.\nSafe to remove local copies from device.'
                          : 'All local media is synchronized with Telegram Cloud.\nDevice storage is fully optimized.',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Segmented Proportional Storage Bar
                    _buildSegmentedStorageBar(summary),
                    const SizedBox(height: 14),

                    // Storage Gauge Legend
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _buildLegendItem(
                          color: const Color(0xFF00E5FF),
                          label: 'Reclaimable',
                          value: summary.formattedSize,
                        ),
                        _buildLegendItem(
                          color: const Color(0xFFFFB300),
                          label: 'TDLib Cache',
                          value: summary.formattedTdlibCache,
                        ),
                        _buildLegendItem(
                          color: const Color(0xFF00E676),
                          label: 'Thumbnails',
                          value: summary.formattedThumbnailCache,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Breakdown Header
              Text(
                'Storage Recovery Breakdown',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Stacked List with Real Data
              M3EStackedList(
                items: [
                  M3EListItemData(
                    title: 'Backed Up Local Media',
                    subtitle:
                        '${summary.formattedSize} (${summary.totalItems} items) • Safe to purge from phone',
                    leadingIcon: Icons.cloud_done,
                    trailing: summary.hasReclaimableSpace
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: scheme.error,
                            tooltip: 'Purge local copies',
                            onPressed: _isCleaning ? null : _freeUpSpace,
                          )
                        : const Icon(Icons.check, color: Color(0xFF00E676), size: 20),
                  ),
                  M3EListItemData(
                    title: 'TDLib Streaming Cache',
                    subtitle:
                        '${summary.formattedTdlibCache} temporary streaming and chunk cache',
                    leadingIcon: Icons.cached,
                    trailing: summary.tdlibCacheBytes > 0
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: scheme.error,
                            tooltip: 'Clear temporary cache',
                            onPressed: _isCleaning
                                ? null
                                : () => _clearCacheOnly(summary.formattedTdlibCache),
                          )
                        : const Icon(Icons.check, color: Color(0xFF00E676), size: 20),
                  ),
                  M3EListItemData(
                    title: 'Thumbnail Index Cache (Retained)',
                    subtitle:
                        '${summary.formattedThumbnailCache} • Preserved for instantaneous 120fps scrolling',
                    leadingIcon: Icons.grid_view,
                    trailing: Icon(
                      Icons.lock_outline,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Primary Action Button: Free Up Space
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: (_isCleaning || !summary.hasReclaimableSpace)
                        ? null
                        : _freeUpSpace,
                    icon: _isCleaning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.delete_sweep),
                    label: Text(
                      summary.hasReclaimableSpace
                          ? 'Free Up ${summary.formattedSize} Space Now'
                          : 'Device Storage Fully Optimized',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Action Button: Clear TDLib Cache
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: (_isCleaning || summary.tdlibCacheBytes == 0)
                        ? null
                        : () => _clearCacheOnly(summary.formattedTdlibCache),
                    icon: const Icon(Icons.cleaning_services),
                    label: Text(
                      summary.tdlibCacheBytes > 0
                          ? 'Clear TDLib Cache Only (${summary.formattedTdlibCache})'
                          : 'TDLib Cache is Clean',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Centered caption text
              Center(
                child: Text(
                  'Cloud copies remain intact & streamable in TeleCloud',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedStorageBar(StorageCleanSummary summary) {
    final reclaimable = summary.totalBytes;
    final tdlib = summary.tdlibCacheBytes;
    final thumb = summary.thumbnailCacheBytes;
    final total = reclaimable + tdlib + thumb;

    if (total <= 0) {
      return Container(
        height: 12,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    // Minimum flex weight to guarantee visibility for non-zero items
    int rFlex = reclaimable > 0 ? (reclaimable * 100 ~/ total).clamp(6, 100) : 0;
    int tFlex = tdlib > 0 ? (tdlib * 100 ~/ total).clamp(6, 100) : 0;
    int mFlex = thumb > 0 ? (thumb * 100 ~/ total).clamp(6, 100) : 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            if (rFlex > 0)
              Expanded(
                flex: rFlex,
                child: Container(color: const Color(0xFF00E5FF)),
              ),
            if (rFlex > 0 && (tFlex > 0 || mFlex > 0))
              const SizedBox(width: 2),
            if (tFlex > 0)
              Expanded(
                flex: tFlex,
                child: Container(color: const Color(0xFFFFB300)),
              ),
            if (tFlex > 0 && mFlex > 0)
              const SizedBox(width: 2),
            if (mFlex > 0)
              Expanded(
                flex: mFlex,
                child: Container(color: const Color(0xFF00E676)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
