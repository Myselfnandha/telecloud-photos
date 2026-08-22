import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final borderColor =
        theme.dividerTheme.color ?? Colors.grey.withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: NavigationBar(
        height: 64,
        backgroundColor: bgColor,
        indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.2),
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == currentIndex) return;
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
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.photo, color: AppColors.primaryBlue),
            label: 'Photos',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined, color: Colors.grey),
            selectedIcon: Icon(
              Icons.photo_library,
              color: AppColors.primaryBlue,
            ),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_sync_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.cloud_sync, color: AppColors.primaryBlue),
            label: 'Uploads',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.settings, color: AppColors.primaryBlue),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
