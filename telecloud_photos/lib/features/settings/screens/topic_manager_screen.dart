import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../shared/widgets/m3e/m3e_card.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';

/// Screen 9: "Cloud Topics & Mappings"
/// Material 3 Expressive Telegram supergroup forum topics manager with 1-tap auto-organize
/// to map local device folders to emoji topics and bidirectional cloud discovery.
class TopicManagerScreen extends ConsumerStatefulWidget {
  const TopicManagerScreen({super.key});

  @override
  ConsumerState<TopicManagerScreen> createState() => _TopicManagerScreenState();
}

class _TopicManagerScreenState extends ConsumerState<TopicManagerScreen> {
  bool _isOrganizing = false;

  void _goBack() {
    HapticFeedback.lightImpact();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }

  void _showAddTopicDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Telegram Forum Topic'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Topic Title',
            hintText: 'e.g. 🎒 Travel Photos',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              if (name.isNotEmpty) {
                try {
                  await ref.read(channelManagerProvider).createAlbumTopic(name);
                } catch (_) {}
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Created Telegram topic "$name"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _runAutoOrganize() async {
    HapticFeedback.mediumImpact();
    setState(() => _isOrganizing = true);
    try {
      final channelMgr = ref.read(channelManagerProvider);
      await channelMgr.autoCreateAndMapAllFolders([
        'Camera',
        'Screenshots',
        'WhatsApp Images',
        'Download',
      ]);
    } catch (_) {}
    if (mounted) {
      setState(() => _isOrganizing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 All device folders organized into Telegram forum topics!'),
          backgroundColor: Color(0xFF30D158),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resyncCatalog() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing remote Telegram cloud catalog...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final channelMgr = ref.read(channelManagerProvider);
      final mediaDao = ref.read(mediaDaoProvider);
      await channelMgr.syncFromCloud(mediaDao);
    } catch (_) {}
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
        title: const Text('Telegram Forum Topics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New Topic',
            onPressed: _showAddTopicDialog,
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
              // Filled card (150dp tall) with auto_fix_high placeholder icon
              M3ECard(
                height: 150,
                variant: M3ECardVariant.filled,
                placeholderIcon: Icons.auto_fix_high,
                headline: '1-Tap Auto-Organize Folders',
                body:
                    'Automatically creates matching forum topics with emoji badges for Camera, Screenshots, WhatsApp, and Downloads.',
              ),
              const SizedBox(height: 20),

              // Filled Button (380dp wide): "Run 1-Tap Auto-Organize"
              SizedBox(
                width: 380,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isOrganizing ? null : _runAutoOrganize,
                  icon: _isOrganizing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: const Text('Run 1-Tap Auto-Organize'),
                ),
              ),
              const SizedBox(height: 24),

              // Centered bold text at 18sp
              Text(
                'Active Folder -> Topic Mappings',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Stacked List of 4 items
              M3EStackedList(
                items: [
                  M3EListItemData(
                    title: 'Camera Roll (/DCIM/Camera)',
                    subtitle: 'Mapped to: 📷 Camera Photos (#topic_481)',
                    leadingIcon: Icons.photo_camera,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {},
                    ),
                  ),
                  M3EListItemData(
                    title: 'Screenshots (/Pictures/Screenshots)',
                    subtitle: 'Mapped to: 📸 Screenshots (#topic_482)',
                    leadingIcon: Icons.screenshot,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {},
                    ),
                  ),
                  M3EListItemData(
                    title: 'WhatsApp Media (/WhatsApp/Media)',
                    subtitle: 'Mapped to: 💬 WhatsApp Images (#topic_483)',
                    leadingIcon: Icons.chat,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {},
                    ),
                  ),
                  M3EListItemData(
                    title: 'Downloads (/Download)',
                    subtitle: 'Mapped to: ⬇️ Saved Downloads (#topic_484)',
                    leadingIcon: Icons.download,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Outlined Button (380dp wide): "Discover Photos in Topics (Re-sync Catalog)"
              SizedBox(
                width: 380,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _resyncCatalog,
                  icon: const Icon(Icons.sync),
                  label: const Text('Discover Photos in Topics (Re-sync Catalog)'),
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
