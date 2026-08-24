import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_typography.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF000000).withValues(alpha: 0.85)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.88);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(top: BorderSide(color: borderColor, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AppleTabBarItem(
                    index: 0,
                    selectedIndex: currentIndex,
                    label: 'Photos',
                    unselectedIcon: Icons.photo_outlined,
                    selectedIcon: Icons.photo_rounded,
                    onTap: () => _handleTap(context, 0),
                  ),
                  _AppleTabBarItem(
                    index: 1,
                    selectedIndex: currentIndex,
                    label: 'Library',
                    unselectedIcon: Icons.photo_library_outlined,
                    selectedIcon: Icons.photo_library_rounded,
                    onTap: () => _handleTap(context, 1),
                  ),
                  _AppleTabBarItem(
                    index: 2,
                    selectedIndex: currentIndex,
                    label: 'Uploads',
                    unselectedIcon: Icons.cloud_sync_outlined,
                    selectedIcon: Icons.cloud_sync_rounded,
                    onTap: () => _handleTap(context, 2),
                  ),
                  _AppleTabBarItem(
                    index: 3,
                    selectedIndex: currentIndex,
                    label: 'Settings',
                    unselectedIcon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    onTap: () => _handleTap(context, 3),
                  ),
                ],
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
        context.go('/library');
        break;
      case 2:
        context.go('/uploads');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}

class _AppleTabBarItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final String label;
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final VoidCallback onTap;

  const _AppleTabBarItem({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    final activeColor = AppColors.primaryBlue;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: AppMotion.durationTabSwitch,
              curve: AppMotion.curveStandard,
              child: AnimatedSwitcher(
                duration: AppMotion.durationTabSwitch,
                child: Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  key: ValueKey<bool>(isSelected),
                  color: isSelected ? activeColor : unselectedColor,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall(
                color: isSelected ? activeColor : unselectedColor,
              ).copyWith(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
