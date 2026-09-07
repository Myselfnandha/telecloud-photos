import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out from Telegram Cloud? Local thumbnails and cached metadata will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/onboarding');
            },
            child: const Text('Sign Out'),
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
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {},
        ),
        title: const Text('Settings & Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Row: Alex Rivers (@alexrivers)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.account_circle,
                      size: 32,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alex Rivers (@alexrivers)',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+1 555-0199 • Supergroup: 📸 Cloud Vault (E2EE)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
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
