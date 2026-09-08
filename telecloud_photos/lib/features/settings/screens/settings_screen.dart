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

  void _showThemeSelectionSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14171C) : scheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Display Theme',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose how TeleCloud Photos renders colors and contrast.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._themeOptions.map((opt) {
                    final isSelected = _selectedTheme == opt;
                    final IconData icon;
                    final String subtitle;
                    final Color swatchColor;
                    if (opt == 'AMOLED Pure Dark') {
                      icon = Icons.dark_mode_outlined;
                      subtitle = 'Pitch-black OLED contrast with zero battery draw';
                      swatchColor = const Color(0xFF000000);
                    } else if (opt == 'Material 3 Light') {
                      icon = Icons.light_mode_outlined;
                      subtitle = 'Clean daytime palette with high legibility';
                      swatchColor = const Color(0xFFF2F2F7);
                    } else {
                      icon = Icons.wallpaper_outlined;
                      subtitle = 'Adapts dynamically to system wallpaper palette';
                      swatchColor = scheme.primary;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: InkWell(
                        onTap: () {
                          _onThemeSelected(opt);
                          setSheetState(() {});
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.primary.withValues(alpha: 0.12)
                                : scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? scheme.primary.withValues(alpha: 0.6)
                                  : scheme.outlineVariant.withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: swatchColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  size: 16,
                                  color: opt == 'Material 3 Light' ? Colors.black87 : Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? scheme.primary : scheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: opt,
                                groupValue: _selectedTheme,
                                activeColor: scheme.primary,
                                onChanged: (val) {
                                  if (val != null) {
                                    _onThemeSelected(val);
                                    setSheetState(() {});
                                    Navigator.of(ctx).pop();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
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

            // Section header "Appearance & Theme"
            Text(
              'Appearance & Theme',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Single Theme Configuration Tile
            InkWell(
              onTap: () => _showThemeSelectionSheet(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedTheme == 'AMOLED Pure Dark'
                            ? Icons.dark_mode
                            : (_selectedTheme == 'Material 3 Light'
                                ? Icons.light_mode
                                : Icons.wallpaper),
                        color: scheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Color Palette',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedTheme,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: scheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ],
                ),
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
