import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import '../../../shared/widgets/m3e/m3e_card.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';

/// Screen 5: "Library & Collections"
/// 100% Real Material 3 Expressive albums overview with dynamic SQLite storage calculations,
/// Google Photos Takeout Importer, Free Up Space Storage Cleaner, and Telegram Cloud Albums.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _backedUpCount = 0;
  int _backedUpBytes = 0;
  int _cameraRollCount = 0;
  int _favoritesCount = 0;
  int _trashCount = 0;
  List<Album> _cloudAlbums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLibraryData();
  }

  Future<void> _loadLibraryData() async {
    try {
      final mediaDao = ref.read(mediaDaoProvider);
      final backedUp = await mediaDao.getBackedUpMedia();
      final all = await mediaDao.getAllMedia();
      final favs = await mediaDao.getFavoriteMedia();
      final trashed = await mediaDao.getTrashedMedia();
      final albums = await mediaDao.getAllAlbums();

      int bytes = 0;
      for (final m in backedUp) {
        bytes += (m.fileSizeBytes ?? 0).toInt();
      }

      if (mounted) {
        setState(() {
          _backedUpCount = backedUp.length;
          _backedUpBytes = bytes;
          _cameraRollCount = all.length;
          _favoritesCount = favs.length;
          _trashCount = trashed.length;
          _cloudAlbums = albums;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            onPressed: () async {
              final name = controller.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              if (name.isNotEmpty) {
                final mediaDao = ref.read(mediaDaoProvider);
                await mediaDao.createAlbum(name);
                if (!mounted) return;
                _loadLibraryData();
                messenger.showSnackBar(
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

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes > 0) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '0 MB';
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Library',
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadLibraryData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Album',
            onPressed: _showCreateAlbumDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        'Zero-staging streaming import for takeout-*.zip archives directly into Telegram topics without local disk bloat.',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/takeout');
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filled card: Dynamic Free Up Space Storage Cleaner
                  M3ECard(
                    variant: M3ECardVariant.filled,
                    placeholderIcon: Icons.cleaning_services,
                    headline: _backedUpCount > 0
                        ? 'Free Up ${_formatBytes(_backedUpBytes)} Device Storage'
                        : 'Storage Fully Optimized',
                    body: _backedUpCount > 0
                        ? '$_backedUpCount photos safely stored in Telegram Cloud. Clean local phone copies with 1 tap.'
                        : 'All eligible media is backed up or optimized. No orphaned media found.',
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

                  // Stacked List of Real Albums
                  M3EStackedList(
                    items: [
                      M3EListItemData(
                        title: '📷 Camera Roll',
                        subtitle: '$_cameraRollCount photos • Topic: #camera • Auto-sync',
                        leadingIcon: Icons.photo_camera,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openAlbum('Camera Roll', 'camera'),
                      ),
                      ..._cloudAlbums.map(
                        (a) => M3EListItemData(
                          title: '📁 ${a.name}',
                          subtitle: a.telegramTopicId != null
                              ? 'Topic: #${a.telegramTopicId} • Telegram Supergroup'
                              : 'Local & Cloud Album',
                          leadingIcon: Icons.folder,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openAlbum(a.name, a.name.toLowerCase()),
                        ),
                      ),
                      M3EListItemData(
                        title: '⭐ Favorites',
                        subtitle: '$_favoritesCount photos • Starred Collection',
                        leadingIcon: Icons.star,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/favorites');
                        },
                      ),
                      M3EListItemData(
                        title: '🗑️ Trash',
                        subtitle: '$_trashCount items • Auto-purge in 30 days',
                        leadingIcon: Icons.delete,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/trash');
                        },
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
