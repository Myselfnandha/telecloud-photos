import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Apple-style Floating Frosted Glass Capsule Dock Navigation Bar
/// Floats above the bottom edge with 24dp horizontal margins and 36dp capsule radius.
/// Uses BackdropFilter with 24px blur so content smoothly scrolls behind it.
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
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      bottom: true,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.16),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xE6101418) // Deep frosted OLED surface
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.2,
                  ),
                ),
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
            ),
          ),
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

    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? const Color(0xFF00E5FF) : scheme.primary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: isDark ? 0.18 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: isSelected
                    ? Border.all(
                        color: activeColor.withValues(alpha: 0.35),
                        width: 1,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                size: 22,
                color: isSelected
                    ? activeColor
                    : scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? (isDark ? Colors.white : scheme.onSurface)
                    : scheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
