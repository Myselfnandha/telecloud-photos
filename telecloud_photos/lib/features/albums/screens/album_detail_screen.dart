import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/m3e/m3e_card.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';

/// Screen 6: "Album Detail View"
/// Deep dive into a specific Telegram cloud topic album with photo list,
/// chip group, batch actions, and add-photo FAB.
class AlbumDetailScreen extends StatefulWidget {
  final int? albumId;
  final String? albumName;

  const AlbumDetailScreen({
    super.key,
    this.albumId,
    this.albumName,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final Set<String> _selectedChips = {};

  void _openViewer(String mediaId) {
    HapticFeedback.lightImpact();
    context.push('/viewer/$mediaId');
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/library');
    }
  }

  void _showMessage(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = widget.albumName ?? '✈️ Tokyo Summer 2026';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _goBack,
        ),
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            onPressed: () => _showMessage('Album options & permissions'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMessage('Select local device photos to upload to this album...'),
        tooltip: 'Add Photos',
        child: const Icon(Icons.add_photo_alternate),
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
              // Filled card (140dp tall) with photo_album placeholder icon
              M3ECard(
                height: 140,
                variant: M3ECardVariant.filled,
                placeholderIcon: Icons.photo_album,
                headline: '168 Photos & Videos • 4.2 GB',
                body:
                    'Telegram Topic: #tokyo_trip • Created Aug 2026\nShared with family members in Supergroup',
              ),
              const SizedBox(height: 16),

              // Chip Group: "Download All", "Share Link", "Cloud Re-sync"
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip('Download All', scheme, () => _showMessage('Downloading all 168 photos in original quality...')),
                    const SizedBox(width: 8),
                    _buildChip('Share Link', scheme, () => _showMessage('Copied Telegram Supergroup topic link!')),
                    const SizedBox(width: 8),
                    _buildChip('Cloud Re-sync', scheme, () => _showMessage('Catalog synchronized with Telegram cloud topic')),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stacked List of 5 items
              M3EStackedList(
                items: [
                  M3EListItemData(
                    title: 'Shibuya_Crossing_Night.jpg',
                    subtitle: '48 MP • Aug 14, 2026 • Synced',
                    leadingIcon: Icons.photo,
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF30D158),
                      size: 20,
                    ),
                    onTap: () => _openViewer('Shibuya_Crossing_Night.jpg'),
                  ),
                  M3EListItemData(
                    title: 'Shinjuku_Gyoen_Rain.jpg',
                    subtitle: '24 MP • Aug 15, 2026 • Synced',
                    leadingIcon: Icons.photo,
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF30D158),
                      size: 20,
                    ),
                    onTap: () => _openViewer('Shinjuku_Gyoen_Rain.jpg'),
                  ),
                  M3EListItemData(
                    title: 'Bullet_Train_Speed.mp4',
                    subtitle: '4K 60fps • 420 MB • Synced',
                    leadingIcon: Icons.videocam,
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF30D158),
                      size: 20,
                    ),
                    onTap: () => _openViewer('Bullet_Train_Speed.mp4'),
                  ),
                  M3EListItemData(
                    title: 'Tokyo_Tower_Sunset.dng',
                    subtitle: '61 MP RAW • Aug 16, 2026 • Synced',
                    leadingIcon: Icons.camera_alt,
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF30D158),
                      size: 20,
                    ),
                    onTap: () => _openViewer('Tokyo_Tower_Sunset.dng'),
                  ),
                  M3EListItemData(
                    title: 'Ramen_Ichiran.jpg',
                    subtitle: '12 MP • Aug 17, 2026 • Synced',
                    leadingIcon: Icons.restaurant,
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF30D158),
                      size: 20,
                    ),
                    onTap: () => _openViewer('Ramen_Ichiran.jpg'),
                  ),
                ],
              ),
              const SizedBox(height: 80), // Padding for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, ColorScheme scheme, VoidCallback onTap) {
    final isSelected = _selectedChips.contains(label);
    return ActionChip(
      label: Text(label),
      avatar: isSelected ? const Icon(Icons.check, size: 16) : null,
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedChips.remove(label);
          } else {
            _selectedChips.add(label);
          }
        });
        onTap();
      },
    );
  }
}
