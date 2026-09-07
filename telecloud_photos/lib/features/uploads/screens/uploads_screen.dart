import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../shared/widgets/m3e/m3e_card.dart';
import '../../../shared/widgets/m3e/m3e_connected_button_group.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';
import '../../../shared/widgets/m3e/m3e_wavy_progress_indicator.dart';

/// Screen 4: "Uploads & Telemetry"
/// Material 3 Expressive operational backup telemetry hub reporting transfer throughput,
/// ETA, wavy linear progress, connected button group, and live transfer queue.
class UploadsScreen extends ConsumerStatefulWidget {
  const UploadsScreen({super.key});

  @override
  ConsumerState<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends ConsumerState<UploadsScreen> {
  bool _isPaused = false;
  final Set<String> _monitoredSelections = {
    '📷 Camera (32 queued)',
    '💬 WhatsApp (12 queued)',
  };

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
      }
    } catch (_) {}
  }

  void _forceScan() {
    HapticFeedback.mediumImpact();
    try {
      ref.read(mediaScannerProvider).scanCameraRoll();
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scanning camera roll & refreshing queue...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.cloud_upload),
          tooltip: 'Uploads',
          onPressed: () {},
        ),
        title: const Text('Uploads & Telemetry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _forceScan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filled card (160dp tall) with speed icon placeholder
            M3ECard(
              height: 160,
              variant: M3ECardVariant.filled,
              placeholderIcon: Icons.speed,
              headline: _isPaused
                  ? 'Backup Paused (0.0 MB/s)'
                  : 'Backing Up Camera Roll (8.4 MB/s)',
              body:
                  'Uploaded 142 of 380 items • 2.4 GB / 6.1 GB • ETA: 7m 14s\nActive file: DSC_0492_RAW.dng (61 MB)',
            ),
            const SizedBox(height: 16),

            // Wavy Linear Progress Indicator (38%)
            const M3EWavyProgressIndicator(
              progress: 0.38,
              height: 16,
              strokeWidth: 4,
            ),
            const SizedBox(height: 16),

            // Connected button group of 2 buttons: "Pause Backup" (tonal), "Force Scan" (filled)
            M3EConnectedButtonGroup(
              items: [
                M3EConnectedButtonItem(
                  label: _isPaused ? 'Resume Backup' : 'Pause Backup',
                  icon: _isPaused ? Icons.play_arrow : Icons.pause,
                  isFilled: false, // tonal
                  onPressed: _togglePause,
                ),
                M3EConnectedButtonItem(
                  label: 'Force Scan',
                  icon: Icons.sync,
                  isFilled: true, // filled
                  onPressed: _forceScan,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bold text "Monitored Folders" at 18sp
            Text(
              'Monitored Folders',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Chip Group: 📷 Camera (32 queued), 📸 Screenshots (Clean), 💬 WhatsApp (12 queued)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFolderChip('📷 Camera (32 queued)', scheme),
                  const SizedBox(width: 8),
                  _buildFolderChip('📸 Screenshots (Clean)', scheme),
                  const SizedBox(width: 8),
                  _buildFolderChip('💬 WhatsApp (12 queued)', scheme),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bold text "Active Transfer Queue" at 18sp
            Text(
              'Active Transfer Queue',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Stacked list of 3 items
            M3EStackedList(
              items: [
                M3EListItemData(
                  title: 'DSC_0492_RAW.dng',
                  subtitle: '61 MB • Uploading chunk 4/8 • 8.4 MB/s',
                  leadingIcon: Icons.upload,
                  trailing: Icon(
                    Icons.pending,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
                M3EListItemData(
                  title: 'IMG_20260907_190012.jpg',
                  subtitle: '12 MB • Queued • Priority High',
                  leadingIcon: Icons.image,
                  trailing: Icon(
                    Icons.schedule,
                    color: scheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                M3EListItemData(
                  title: 'PXL_20260907_164501.mp4',
                  subtitle: '145 MB • Waiting for Wi-Fi',
                  leadingIcon: Icons.videocam,
                  trailing: Icon(
                    Icons.wifi,
                    color: scheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderChip(String label, ColorScheme scheme) {
    final isSelected = _monitoredSelections.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        HapticFeedback.selectionClick();
        setState(() {
          if (val) {
            _monitoredSelections.add(label);
          } else {
            _monitoredSelections.remove(label);
          }
        });
      },
    );
  }
}
