import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/m3e/m3e_card.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';

/// Screen 5: "Library & Collections"
/// Material 3 Expressive albums overview with power cards for Google Photos
/// Takeout Importer, Free Up Space Storage Cleaner, and Telegram Cloud Albums.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  void _openAlbum(String albumTitle, String topicTag) {
    HapticFeedback.lightImpact();
    context.push('/album/$topicTag', extra: albumTitle);
  }

  void _showCreateAlbumDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Cloud Album'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Album Name',
            hintText: 'e.g. Summer Vacation',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              Navigator.pop(context);
              if (name.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created Telegram topic album "$name"'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.collections_bookmark),
          tooltip: 'Library',
          onPressed: () {},
        ),
        title: const Text('Library & Cloud Albums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Album',
            onPressed: _showCreateAlbumDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Elevated card: Google Photos Takeout Importer
            M3ECard(
              variant: M3ECardVariant.elevated,
              placeholderIcon: Icons.cloud_download,
              headline: 'Google Photos Takeout Importer',
              body:
                  'Zero-staging streaming import for takeout-*.zip archives directly into Telegram topics without disk bloat.',
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/takeout');
              },
            ),
            const SizedBox(height: 16),

            // Filled card: Free Up 14.8 GB Device Storage with layered heading
            M3ECard(
              variant: M3ECardVariant.filled,
              placeholderIcon: Icons.cleaning_services,
              headline: 'Free Up 14.8 GB Device Storage',
              body:
                  '1,240 photos safely stored in Telegram Cloud. Clean local phone copies with 1 tap.',
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/storage-cleaner');
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Cloud Albums & Topics',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stacked List of 4 items: Camera Roll, Tokyo Summer 2026, Favorites, Trash
            M3EStackedList(
              items: [
                M3EListItemData(
                  title: '📷 Camera Roll',
                  subtitle: '842 photos • Topic: #camera • Synced',
                  leadingIcon: Icons.photo_camera,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openAlbum('Camera Roll', 'camera'),
                ),
                M3EListItemData(
                  title: '✈️ Tokyo Summer 2026',
                  subtitle: '168 photos • Topic: #tokyo_trip • Synced',
                  leadingIcon: Icons.flight,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openAlbum('✈️ Tokyo Summer 2026', 'tokyo_trip'),
                ),
                M3EListItemData(
                  title: '⭐ Favorites',
                  subtitle: '45 photos • Synced to Cloud',
                  leadingIcon: Icons.star,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openAlbum('⭐ Favorites', 'favorites'),
                ),
                M3EListItemData(
                  title: '🗑️ Trash',
                  subtitle: '12 items • Auto-purge in 30 days',
                  leadingIcon: Icons.delete,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openAlbum('🗑️ Trash', 'trash'),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
