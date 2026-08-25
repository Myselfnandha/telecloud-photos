import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/navigation/transition_preference_provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radii.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/theme/app_elevation.dart';
import '../../../../shared/theme/app_icons.dart';
import '../../../../shared/theme/theme_provider.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  String _aspectRatio = 'square';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aspectRatio = prefs.getString('telecloud_aspect_ratio') ?? 'square';
    });
  }

  Future<void> _saveAspectRatio(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('telecloud_aspect_ratio', val);
    setState(() => _aspectRatio = val);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor =
        isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;
    final secondaryTextColor =
        isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary;
    final cardBg = isLight ? AppColors.lightCard : AppColors.darkSurface;
    final cardBorder = isLight ? AppColors.lightBorder : AppColors.darkBorder;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: AppElevation.none,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryTextColor,
            size: AppIcons.m,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Appearance & Display',
          style: AppTypography.titleLarge(
            color: primaryTextColor,
          ).copyWith(fontWeight: AppTypography.bold),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            'COLOR THEME',
            style: AppTypography.labelSmall(
              color: secondaryTextColor,
            ).copyWith(fontWeight: AppTypography.bold, letterSpacing: 0.8),
          ),
          AppSpacing.gapVerticalS,
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadii.borderXL,
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                _buildThemeRow(
                  title: 'Pure Black (OLED)',
                  subtitle: 'True black #000000 theme for OLED displays',
                  value: AppThemeMode.pureBlack,
                  groupValue: currentThemeMode,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(AppThemeMode.pureBlack),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildThemeRow(
                  title: 'Dark Theme',
                  subtitle: 'Refined deep charcoal modern dark interface',
                  value: AppThemeMode.dark,
                  groupValue: currentThemeMode,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(AppThemeMode.dark),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildThemeRow(
                  title: 'Light Theme',
                  subtitle: 'Clean, high-contrast daylight appearance',
                  value: AppThemeMode.light,
                  groupValue: currentThemeMode,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(AppThemeMode.light),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'GALLERY ASPECT RATIO',
            style: AppTypography.labelSmall(
              color: secondaryTextColor,
            ).copyWith(fontWeight: AppTypography.bold, letterSpacing: 0.8),
          ),
          AppSpacing.gapVerticalS,
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadii.borderXL,
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                _buildAspectRatioRow(
                  title: 'Square Fill (1:1)',
                  subtitle: 'Standard cropped uniform grid',
                  value: 'square',
                  groupValue: _aspectRatio,
                  onTap: () => _saveAspectRatio('square'),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildAspectRatioRow(
                  title: 'Dynamic Masonry (Original Aspect)',
                  subtitle: 'Uncropped original photo proportions',
                  value: 'masonry',
                  groupValue: _aspectRatio,
                  onTap: () => _saveAspectRatio('masonry'),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PAGE TRANSITIONS',
            style: AppTypography.labelSmall(
              color: secondaryTextColor,
            ).copyWith(fontWeight: AppTypography.bold, letterSpacing: 0.8),
          ),
          AppSpacing.gapVerticalS,
          Consumer(
            builder: (context, ref, _) {
              final currentStyle = ref.watch(pageTransitionProvider);
              return Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadii.borderXL,
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  children: [
                    _buildTransitionRow(
                      title: PageTransitionStyle.fadeSlideUp.displayName,
                      subtitle: PageTransitionStyle.fadeSlideUp.description,
                      value: PageTransitionStyle.fadeSlideUp,
                      groupValue: currentStyle,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(pageTransitionProvider.notifier)
                            .setTransitionStyle(
                                PageTransitionStyle.fadeSlideUp);
                      },
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _buildDivider(isLight),
                    _buildTransitionRow(
                      title: PageTransitionStyle.sharedAxis.displayName,
                      subtitle: PageTransitionStyle.sharedAxis.description,
                      value: PageTransitionStyle.sharedAxis,
                      groupValue: currentStyle,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(pageTransitionProvider.notifier)
                            .setTransitionStyle(PageTransitionStyle.sharedAxis);
                      },
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _buildDivider(isLight),
                    _buildTransitionRow(
                      title: PageTransitionStyle.cupertinoSlide.displayName,
                      subtitle: PageTransitionStyle.cupertinoSlide.description,
                      value: PageTransitionStyle.cupertinoSlide,
                      groupValue: currentStyle,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(pageTransitionProvider.notifier)
                            .setTransitionStyle(
                                PageTransitionStyle.cupertinoSlide);
                      },
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionRow({
    required String title,
    required String subtitle,
    required PageTransitionStyle value,
    required PageTransitionStyle groupValue,
    required VoidCallback onTap,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final isSelected = value == groupValue;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primaryBlue : primaryTextColor,
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: secondaryTextColor, fontSize: 12),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primaryBlue, size: 22)
          : const Icon(Icons.circle_outlined, color: Colors.grey, size: 22),
      onTap: onTap,
    );
  }

  Widget _buildThemeRow({
    required String title,
    required String subtitle,
    required AppThemeMode value,
    required AppThemeMode groupValue,
    required VoidCallback onTap,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final isSelected = value == groupValue;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primaryBlue : primaryTextColor,
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: secondaryTextColor, fontSize: 12),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primaryBlue, size: 22)
          : const Icon(Icons.circle_outlined, color: Colors.grey, size: 22),
      onTap: onTap,
    );
  }

  Widget _buildAspectRatioRow({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required VoidCallback onTap,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final isSelected = value == groupValue;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primaryBlue : primaryTextColor,
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: secondaryTextColor, fontSize: 12),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primaryBlue, size: 22)
          : const Icon(Icons.circle_outlined, color: Colors.grey, size: 22),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isLight) {
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: isLight
          ? const Color(0xFFF2F2F7)
          : Colors.white.withValues(alpha: 0.05),
    );
  }
}
