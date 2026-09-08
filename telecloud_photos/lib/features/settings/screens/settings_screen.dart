import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/theme_provider.dart';
import '../../../shared/widgets/m3e/m3e_stacked_list.dart';

/// Screen 10: "Settings & Account"
/// Material 3 Expressive account settings, AMOLED / Light / Dynamic theme toggles,
/// Telegram blue accent, expressive spring physics, and direct maintenance hub links.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedTheme = 'AMOLED Pure Dark';
  bool _blueAccent = true;
  bool _expressiveSpring = true;

  final List<String> _themeOptions = [
    'AMOLED Pure Dark',
    'Material 3 Light',
    'Dynamic Wallpaper',
  ];

  @override
  void initState() {
    super.initState();
    final mode = ref.read(themeModeProvider);
    if (mode == AppThemeMode.pureBlack) {
      _selectedTheme = 'AMOLED Pure Dark';
    } else if (mode == AppThemeMode.light) {
      _selectedTheme = 'Material 3 Light';
    } else {
      _selectedTheme = 'Dynamic Wallpaper';
    }

    Future.microtask(() {
      try {
        ref.read(telegramAuthManagerProvider).refreshAccountProfile();
      } catch (_) {}
    });
  }

  void _onThemeSelected(String themeName) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTheme = themeName;
    });

    final notifier = ref.read(themeModeProvider.notifier);
    if (themeName == 'AMOLED Pure Dark') {
      notifier.setThemeMode(AppThemeMode.pureBlack);
    } else if (themeName == 'Material 3 Light') {
      notifier.setThemeMode(AppThemeMode.light);
    } else {
      notifier.setThemeMode(AppThemeMode.system);
    }
  }

  Widget _buildInitialsAvatar(String name, ColorScheme scheme) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'TC';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.tertiary,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: scheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeAccount = ref.watch(activeTelegramAccountProvider);

    final uname = activeAccount?.username;
    final displayName = (activeAccount?.firstName != null || activeAccount?.lastName != null)
        ? '${activeAccount?.firstName ?? ""} ${activeAccount?.lastName ?? ""}'.trim()
        : (uname != null && uname.isNotEmpty
            ? '@$uname'
            : 'Telegram User');

    final usernameTag = (uname != null && uname.isNotEmpty)
        ? ' (@$uname)'
        : '';
    final phone = activeAccount?.phoneNumber ?? '';
    final photoPath = activeAccount?.profilePhotoPath;
    final hasValidPhoto = photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync();

    Widget avatarWidget;
    if (hasValidPhoto) {
      avatarWidget = ClipOval(
        child: Image.file(
          File(photoPath),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsAvatar(displayName, scheme),
        ),
      );
    } else {
      avatarWidget = _buildInitialsAvatar(displayName, scheme);
    }

    final supergroupSubtitle = phone.isNotEmpty
        ? '$phone • Supergroup: 📸 TeleCloud Photos (E2EE)'
        : 'Supergroup: 📸 TeleCloud Photos (E2EE)';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings & Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out of Telegram Cloud?'),
                  content: const Text(
                    'Your local media database will remain cached, but Telegram Cloud supergroup sync will be paused until you sign back in.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                HapticFeedback.heavyImpact();
                ref.read(telegramAuthManagerProvider).logout();
                if (context.mounted) context.go('/onboarding');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Real User Profile Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  avatarWidget,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$displayName$usernameTag',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          supergroupSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.verified,
                    color: scheme.primary,
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bold text "Appearance & Theme Selection" at 18sp
            Text(
              'Appearance & Theme Selection',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Chip Group: "AMOLED Pure Dark", "Material 3 Light", "Dynamic Wallpaper"
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _themeOptions.map((opt) {
                  final isSelected = _selectedTheme == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(opt),
                      selected: isSelected,
                      onSelected: (val) => _onThemeSelected(opt),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Stacked List of 2 switches
            M3EStackedList(
              items: [
                M3EListItemData(
                  title: 'Vibrant Telegram Blue Accent',
                  subtitle: 'Signature cloud branding and badges',
                  leadingIcon: Icons.palette,
                  trailing: Switch(
                    value: _blueAccent,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _blueAccent = val);
                    },
                  ),
                ),
                M3EListItemData(
                  title: 'Expressive Spring Physics',
                  subtitle: 'Fluid pinch-to-zoom and sheet morphing',
                  leadingIcon: Icons.animation,
                  trailing: Switch(
                    value: _expressiveSpring,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _expressiveSpring = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bold text "Cloud & Maintenance Hubs" at 18sp
            Text(
              'Cloud & Maintenance Hubs',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Stacked List of 3 maintenance links
            M3EStackedList(
              items: [
                M3EListItemData(
                  title: 'Storage Recovery Center',
                  subtitle: 'Free up 14.8 GB local phone storage',
                  leadingIcon: Icons.cleaning_services,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/storage-cleaner');
                  },
                ),
                M3EListItemData(
                  title: 'Telegram Forum Topics Manager',
                  subtitle: 'Configure supergroup albums & auto-organize',
                  leadingIcon: Icons.forum,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/topics');
                  },
                ),
                M3EListItemData(
                  title: 'Google Photos Takeout Importer',
                  subtitle: 'Zero-staging streaming zip archive importer',
                  leadingIcon: Icons.cloud_download,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/takeout');
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
