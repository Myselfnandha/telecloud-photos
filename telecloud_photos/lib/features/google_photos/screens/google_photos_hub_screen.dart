import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/m3e/m3e_card.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';
import '../../../shared/widgets/m3e/m3e_wavy_progress_indicator.dart';

/// Screen 7: "Takeout"
/// Material 3 Expressive zero-staging streaming importer for Google Takeout zip archives,
/// parsing JSON sidecars directly into Telegram topics without disk bloat.
class GooglePhotosHubScreen extends StatefulWidget {
  const GooglePhotosHubScreen({super.key});

  @override
  State<GooglePhotosHubScreen> createState() => _GooglePhotosHubScreenState();
}

class _GooglePhotosHubScreenState extends State<GooglePhotosHubScreen> {
  void _goBack() {
    HapticFeedback.lightImpact();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/library');
    }
  }

  void _viewInTimeline() {
    HapticFeedback.lightImpact();
    context.go('/timeline');
  }

  void _selectZip() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening system file picker for .zip archives...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Takeout Streaming'),
        content: const Text(
          'TeleCloud decodes your Takeout .zip archive directly in RAM, extracts companion JSON metadata (GPS coords, camera timestamps, album tags), and streams media to Telegram without storing extra gigabytes on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
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
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _goBack,
        ),
        title: const Text('Takeout Import'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: _showHelp,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Filled card (160dp tall) with folder_zip icon
              M3ECard(
                height: 160,
                variant: M3ECardVariant.filled,
                placeholderIcon: Icons.folder_zip,
                headline: 'takeout-20260824-001.zip',
                body:
                    'Found in Downloads • 18.4 GB Archive\nEstimated: 2,410 Photos, 180 Videos, 2,590 JSON sidecars',
              ),
              const SizedBox(height: 16),

              // Wavy linear progress indicator (64%)
              const M3EWavyProgressIndicator(
                progress: 0.64,
                height: 16,
                strokeWidth: 4,
              ),
              const SizedBox(height: 12),

              // Centered bold text at 15sp
              Text(
                'Stage: Streaming to Cloud (1,542 / 2,410 items)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // Stacked List of 3 items
              M3EStackedList(
                items: [
                  M3EListItemData(
                    title: 'Zero-Staging RAM Buffer',
                    subtitle:
                        'Extracts in RAM -> Uploads directly to Telegram (Zero disk bloat)',
                    leadingIcon: Icons.memory,
                  ),
                  M3EListItemData(
                    title: 'JSON Sidecar Metadata Engine',
                    subtitle:
                        'Re-attaches original EXIF capture dates, GPS coords & descriptions',
                    leadingIcon: Icons.pin_drop,
                  ),
                  M3EListItemData(
                    title: 'Target Cloud Topic: 📦 Takeout',
                    subtitle:
                        'Organized into dedicated Telegram forum topic (#takeout_archive)',
                    leadingIcon: Icons.forum,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Outlined Button (380dp wide): "Select Another Zip Archive"
              SizedBox(
                width: 380,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _selectZip,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Select Another Zip Archive'),
                ),
              ),
              const SizedBox(height: 12),

              // Filled Button (380dp wide): "View Imported Photos in Timeline"
              SizedBox(
                width: 380,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _viewInTimeline,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('View Imported Photos in Timeline'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
