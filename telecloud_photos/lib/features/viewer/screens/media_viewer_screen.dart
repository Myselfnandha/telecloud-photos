import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/m3e/m3e_card.dart';
import '../../../shared/widgets/m3e/m3e_floating_toolbar.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';

/// Screen 3: "Media Viewer"
/// Material 3 Expressive full-screen photo/video viewer with EXIF metadata,
/// chip group, floating toolbar, and slide-down gesture dismiss.
class MediaViewerScreen extends StatefulWidget {
  final String mediaId;

  const MediaViewerScreen({super.key, required this.mediaId});

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  double _dragOffsetY = 0.0;
  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;

  final Set<String> _selectedChips = {
    'Synced to Telegram',
    'Motion Photo',
  };

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_snapAnimation != null && mounted) {
          setState(() {
            _dragOffsetY = _snapAnimation!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _closeViewer() {
    HapticFeedback.lightImpact();
    context.pop();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta != null && details.primaryDelta! > 0) {
      setState(() {
        _dragOffsetY += details.primaryDelta!;
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 500 || _dragOffsetY > 120) {
      _closeViewer();
    } else {
      _snapAnimation = Tween<double>(begin: _dragOffsetY, end: 0.0).animate(
        CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
      );
      _snapController.forward(from: 0.0);
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
    final dragFraction = (_dragOffsetY / 300.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: scheme.surface.withValues(alpha: 1.0 - (dragFraction * 0.4)),
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _closeViewer,
        ),
        title: const Text('Sep 7, 2026 • 6:24 PM'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : scheme.onSurface,
            ),
            tooltip: 'Favorite',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isFavorite = !_isFavorite;
              });
              _showMessage(_isFavorite ? 'Added to Favorites' : 'Removed from Favorites');
            },
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        behavior: HitTestBehavior.translucent,
        child: Transform.translate(
          offset: Offset(0, _dragOffsetY),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filled card (320dp tall) with photo icon placeholder
                  M3ECard(
                    height: 320,
                    variant: M3ECardVariant.filled,
                    placeholderIcon: Icons.photo,
                    headline: 'Sony A7IV • FE 50mm F1.2 GM',
                    body: 'f/1.8 • 1/500s • ISO 100 • 61 MP RAW (72.4 MB)',
                  ),
                  const SizedBox(height: 16),

                  // Chip Group: "Synced to Telegram" (selected), "Motion Photo" (selected), "Google Takeout"
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChip('Synced to Telegram', scheme),
                        const SizedBox(width: 8),
                        _buildChip('Motion Photo', scheme),
                        const SizedBox(width: 8),
                        _buildChip('Google Takeout', scheme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bold text "Camera & Capture Hardware EXIF" at 17sp
                  Text(
                    'Camera & Capture Hardware EXIF',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Stacked List of 3 items
                  M3EStackedList(
                    items: [
                      M3EListItemData(
                        title: 'Sony ILCE-7M4 (A7IV)',
                        subtitle: 'Sony FE 50mm F1.2 GM • 9504 x 6336',
                        leadingIcon: Icons.camera_alt,
                      ),
                      M3EListItemData(
                        title: 'f/1.8 • 1/500s • ISO 100',
                        subtitle: 'Aperture Priority • Daylight White Balance',
                        leadingIcon: Icons.iso,
                      ),
                      M3EListItemData(
                        title: 'Supergroup Topic: #camera_photos',
                        subtitle: 'Message ID: #48291 • TDLib E2EE Direct Download',
                        leadingIcon: Icons.cloud,
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          color: scheme.primary,
                          onPressed: () => _showMessage('Downloading original RAW from Telegram Cloud...'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Vibrant (primaryContainer) floating toolbar: share, cloud_download, add_to_photos, delete_outline
                  Align(
                    alignment: Alignment.centerLeft,
                    child: M3EFloatingToolbar(
                      isVibrant: true,
                      actions: [
                        M3EToolbarAction(
                          icon: Icons.share,
                          tooltip: 'Share',
                          onPressed: () => _showMessage('Preparing direct Telegram media share link...'),
                        ),
                        M3EToolbarAction(
                          icon: Icons.cloud_download,
                          tooltip: 'Download',
                          onPressed: () => _showMessage('Saved original photo to device Gallery!'),
                        ),
                        M3EToolbarAction(
                          icon: Icons.add_to_photos,
                          tooltip: 'Add to Album',
                          onPressed: () => _showMessage('Choose destination cloud album'),
                        ),
                        M3EToolbarAction(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete',
                          onPressed: () {
                            _showMessage('Moved to Trash');
                            _closeViewer();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tonal button (380dp wide): "Close Viewer" with expand_more icon
                  Center(
                    child: SizedBox(
                      width: 380,
                      height: 56,
                      child: FilledButton.tonalIcon(
                        onPressed: _closeViewer,
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Close Viewer'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, ColorScheme scheme) {
    final isSelected = _selectedChips.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        HapticFeedback.selectionClick();
        setState(() {
          if (val) {
            _selectedChips.add(label);
          } else {
            _selectedChips.remove(label);
          }
        });
      },
    );
  }
}
