import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/backup/upload_queue.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import '../../../shared/widgets/m3e/m3e_connected_button_group.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';
import '../../../shared/widgets/m3e/m3e_wavy_progress_indicator.dart';

/// Screen 4: "Uploads & Telemetry"
/// 100% Real Futuristic OLED Minimalist operational backup telemetry hub reporting live transfer throughput,
/// progress, connected button group, and live SQLite transfer queue.
class UploadsScreen extends ConsumerStatefulWidget {
  const UploadsScreen({super.key});

  @override
  ConsumerState<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends ConsumerState<UploadsScreen>
    with SingleTickerProviderStateMixin {
  bool _isPaused = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // Auto-run sync on screen mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(backupManagerProvider.notifier).triggerSync();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _togglePause() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPaused = !_isPaused;
    });
    try {
      final queue = ref.read(uploadQueueProvider);
      if (_isPaused) {
        queue.pause();
      } else {
        queue.resume();
        ref.read(backupManagerProvider.notifier).triggerSync();
      }
    } catch (_) {}
  }

  void _forceScan() {
    HapticFeedback.mediumImpact();
    try {
      ref.read(mediaScannerProvider).scanCameraRoll();
      ref.read(backupManagerProvider.notifier).triggerSync();
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scanning camera roll & triggering cloud sync...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final progressAsync = ref.watch(uploadProgressStreamProvider);
    final progress = progressAsync.value ?? const UploadProgressState();
    final isPaused = progress.isPaused || _isPaused;

    final mediaDao = ref.watch(mediaDaoProvider);
    final foldersAsync = ref.watch(folderSyncListStreamProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.cloud_upload_outlined),
          tooltip: 'Uploads',
          onPressed: () {},
        ),
        title: const Text(
          'Uploads & Telemetry',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh & Scan',
            onPressed: _forceScan,
          ),
        ],
      ),
      body: StreamBuilder<List<MediaItem>>(
        stream: mediaDao.watchPendingUploads(),
        builder: (context, snapshot) {
          final pendingItems = snapshot.data ?? [];
          final totalPending = pendingItems.length;

          final isUploading = progress.activeWorkers > 0 && !isPaused;

          // Progress calculation
          final progressValue = totalPending > 0
              ? (progress.totalCount > 0
                  ? progress.progressPercentage
                  : (isUploading ? 0.2 : 0.05))
              : 1.0;

          // Live telemetry status text & accent color
          final Color statusAccentColor;
          final String statusLabel;
          if (isPaused) {
            statusAccentColor = const Color(0xFFFFB300); // Amber
            statusLabel = 'TRANSMISSION PAUSED';
          } else if (isUploading) {
            statusAccentColor = const Color(0xFF00E676); // Emerald pulse
            statusLabel = 'UPLINK ACTIVE';
          } else if (totalPending > 0) {
            statusAccentColor = const Color(0xFF00E5FF); // Cyan
            statusLabel = 'QUEUE READY';
          } else {
            statusAccentColor = const Color(0xFF00E5FF); // Cyan
            statusLabel = 'CLOUD SYNCHRONIZED';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========================================================
                // UNIQUE OLED MINIMALIST TELEMETRY HUB
                // ========================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: statusAccentColor.withValues(alpha: isDark ? 0.35 : 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusAccentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                        blurRadius: 20,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Status Pill with live animated pulse dot + Supergroup badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusAccentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusAccentColor.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    final double glowRadius = isUploading
                                        ? 3.0 + (_pulseAnimation.value * 5.0)
                                        : 2.0;
                                    return Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: statusAccentColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: statusAccentColor.withValues(
                                              alpha: isUploading ? 0.8 : 0.4,
                                            ),
                                            blurRadius: glowRadius,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: statusAccentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.telegram,
                                size: 16,
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Cloud Supergroup',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Hero Speed Gauge Readout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            isPaused
                                ? '0.0 KB/s'
                                : (isUploading
                                    ? progress.speedFormatted
                                    : (totalPending > 0 ? 'Ready' : 'Synced')),
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: isPaused
                                  ? const Color(0xFFFFB300)
                                  : (isUploading
                                      ? const Color(0xFF00E5FF)
                                      : scheme.onSurface),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isUploading ? 'THROUGHPUT' : (isPaused ? 'PAUSED' : 'STATUS'),
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

                      // Subtitle telemetry info
                      Text(
                        isPaused
                            ? '$totalPending items held in SQLite queue. Tap Resume to restart MTProto pipeline.'
                            : (isUploading
                                ? 'Uploading: ${progress.currentFileName.isNotEmpty ? progress.currentFileName : "Batch streaming..."}'
                                : (totalPending > 0
                                    ? '$totalPending media items queued for automatic Telegram backup.'
                                    : 'All photos and videos are safe in your Telegram Cloud Supergroup.')),
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 18),

                      // Telemetry Micro-Sensors Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTelemetrySensor(
                              icon: Icons.queue,
                              label: 'QUEUED',
                              value: '$totalPending items',
                              valueColor: scheme.onSurface,
                            ),
                            Container(
                              height: 24,
                              width: 1,
                              color: scheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                            _buildTelemetrySensor(
                              icon: Icons.bolt,
                              label: 'WORKERS',
                              value: progress.activeWorkers > 0
                                  ? '${progress.activeWorkers} Active'
                                  : 'Standby',
                              valueColor: progress.activeWorkers > 0
                                  ? const Color(0xFF00E676)
                                  : scheme.onSurfaceVariant,
                            ),
                            Container(
                              height: 24,
                              width: 1,
                              color: scheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                            _buildTelemetrySensor(
                              icon: Icons.cloud_done_outlined,
                              label: 'SYNCED',
                              value: '${progress.completedCount}',
                              valueColor: const Color(0xFF00E5FF),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Wavy Progress Indicator
                      M3EWavyProgressIndicator(
                        progress: progressValue,
                        height: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Connected Button Group: Pause/Resume, Force Scan, Settings
                M3EConnectedButtonGroup(
                  items: [
                    M3EConnectedButtonItem(
                      label: isPaused ? 'Resume' : 'Pause',
                      icon: isPaused ? Icons.play_arrow : Icons.pause,
                      onPressed: _togglePause,
                    ),
                    M3EConnectedButtonItem(
                      label: 'Scan Now',
                      icon: Icons.sync,
                      onPressed: _forceScan,
                    ),
                    M3EConnectedButtonItem(
                      label: 'Engine',
                      icon: Icons.tune,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push('/settings/backup-engine');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Monitored Folders Section
                Text(
                  'Monitored Backup Folders',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                // Dynamic folder chips
                foldersAsync.when(
                  data: (folders) {
                    final displayFolders = folders.isEmpty
                        ? [
                            (name: '📷 Camera Roll', count: totalPending),
                          ]
                        : folders.map((f) => (name: '📁 ${f.folderName}', count: 0)).toList();

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: displayFolders.map((f) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text('${f.name} ($totalPending queued)'),
                              selected: true,
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                context.push('/settings/backup-folders');
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 32),
                  error: (_, __) => const SizedBox(height: 32),
                ),
                const SizedBox(height: 24),

                // Active Transfer Queue Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Transfer Queue ($totalPending)',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (totalPending > 0)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(uploadQueueProvider).resume();
                          ref.read(backupManagerProvider.notifier).triggerSync();
                        },
                        child: const Text('Start All'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Real Pending Queue Stacked List
                if (pendingItems.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00E676).withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              size: 44,
                              color: Color(0xFF00E676),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Transfer queue is empty',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Any newly captured media will queue and upload automatically.',
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  M3EStackedList(
                    items: pendingItems.take(8).map((item) {
                      final isVideo = item.mimeType.startsWith('video');
                      final sizeMB = ((item.fileSizeBytes ?? 0) / (1024 * 1024)).toStringAsFixed(1);

                      return M3EListItemData(
                        title: item.filename,
                        subtitle: '$sizeMB MB • Queued for Telegram Supergroup',
                        leadingIcon: isVideo ? Icons.videocam : Icons.photo,
                        trailing: Icon(
                          Icons.cloud_upload_outlined,
                          color: scheme.primary,
                          size: 20,
                        ),
                        onTap: () => context.push('/viewer/${item.localId}'),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTelemetrySensor({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: valueColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: valueColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
