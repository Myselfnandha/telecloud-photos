import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Material 3 Expressive Bottom Navigation Bar
/// 80dp tall on surfaceContainer, extended through system gesture inset.
/// Active destination shows a 64x32dp secondaryContainer pill indicator,
/// filled icon, and labelMedium label.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: scheme.surfaceContainer,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _M3ENavDestination(
              index: 0,
              selectedIndex: currentIndex,
              label: 'Photos',
              selectedIcon: Icons.photo_library,
              unselectedIcon: Icons.photo_library_outlined,
              onTap: () => _handleTap(context, 0),
            ),
            _M3ENavDestination(
              index: 1,
              selectedIndex: currentIndex,
              label: 'Uploads',
              selectedIcon: Icons.cloud_upload,
              unselectedIcon: Icons.cloud_upload_outlined,
              onTap: () => _handleTap(context, 1),
            ),
            _M3ENavDestination(
              index: 2,
              selectedIndex: currentIndex,
              label: 'Library',
              selectedIcon: Icons.collections_bookmark,
              unselectedIcon: Icons.collections_bookmark_outlined,
              onTap: () => _handleTap(context, 2),
            ),
            _M3ENavDestination(
              index: 3,
              selectedIndex: currentIndex,
              label: 'Settings',
              selectedIcon: Icons.settings,
              unselectedIcon: Icons.settings_outlined,
              onTap: () => _handleTap(context, 3),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    HapticFeedback.selectionClick();
    if (onTap != null) {
      onTap!(index);
      return;
    }
    switch (index) {
      case 0:
        context.go('/timeline');
        break;
      case 1:
        context.go('/uploads');
        break;
      case 2:
        context.go('/library');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}

class _M3ENavDestination extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final VoidCallback onTap;

  const _M3ENavDestination({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSelected = index == selectedIndex;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 64x32dp pill indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 64,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                size: 24,
                color: isSelected
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
