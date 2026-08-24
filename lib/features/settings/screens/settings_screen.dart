import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_elevation.dart';
import '../widgets/account_switcher_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAccount = ref.watch(activeTelegramAccountProvider);
    final telemetry = ref.watch(uploadTelemetryProvider);

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final secondaryTextColor = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;
    final cardBg = isLight ? AppColors.lightCard : AppColors.darkSurface;
    final cardBorder = isLight ? AppColors.lightBorder : AppColors.darkBorder;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: AppElevation.none,
        title: Text(
          'Settings',
          style: AppTypography.displayMedium(color: primaryTextColor),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // 1. Telegram Account & Cloud Hero Dashboard
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadii.borderXL,
              border: Border.all(color: cardBorder),
              gradient: isLight
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                    ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0088CC), Color(0xFF00C6FF)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0088CC).withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                activeAccount?.displayName ?? 'Telegram Cloud User',
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF0A84FF),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeAccount?.phoneNumber ?? 'Unlimited Cloud Storage',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFF0A84FF),
                      ),
                      tooltip: 'Switch Account',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        AccountSwitcherSheet.show(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => context.push('/settings/topics'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isLight
                          ? const Color(0xFFF2F2F7)
                          : Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF30D158),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF30D158).withValues(alpha: 0.6),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              telemetry.telegramStatus,
                              style: TextStyle(
                                color: isLight ? Colors.black87 : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Text(
                              'Supergroup Topics',
                              style: TextStyle(
                                color: Color(0xFF0A84FF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Color(0xFF0A84FF),
                              size: 11,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Compact Hierarchical Categories Grid / List
          Text(
            'CATEGORIES',
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
                _buildCategoryRow(
                  context: context,
                  icon: Icons.palette_outlined,
                  iconColor: const Color(0xFFBF5AF2),
                  title: 'Appearance & Display',
                  subtitle: 'OLED / Dark theme, Dynamic Aspect Ratio',
                  route: '/settings/appearance',
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildCategoryRow(
                  context: context,
                  icon: Icons.cloud_sync_outlined,
                  iconColor: const Color(0xFF4285F4),
                  title: 'Cloud Migration & Imports',
                  subtitle: 'Google Photos sync hub, Takeout zip packages',
                  route: '/settings/cloud',
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildCategoryRow(
                  context: context,
                  icon: Icons.sync_rounded,
                  iconColor: const Color(0xFF30D158),
                  title: 'Backup Engine & Rules',
                  subtitle: 'Auto-backup, Wi-Fi only, Backup folders, Media types',
                  route: '/settings/backup',
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildCategoryRow(
                  context: context,
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFFF9F0A),
                  title: 'Power & Battery Constraints',
                  subtitle: 'Charging only, Thermal dwell delay, Auto-kill worker',
                  route: '/settings/power',
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _buildDivider(isLight),
                _buildCategoryRow(
                  context: context,
                  icon: Icons.storage_rounded,
                  iconColor: const Color(0xFFFF453A),
                  title: 'Storage & Cache Maintenance',
                  subtitle: 'Free up space, Clear cache, Emergency deep kill',
                  route: '/settings/storage',
                  isLight: isLight,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. App Version & Build Footer
          Center(
            child: Column(
              children: [
                Text(
                  'TeleCloud Photos v1.0.0 (Build 5)',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Encrypted Private Cloud • TDLib MTProto Protocol',
                  style: TextStyle(
                    color: secondaryTextColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String route,
    required bool isLight,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: primaryTextColor,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: secondaryTextColor,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isLight ? Colors.grey.shade400 : Colors.grey.shade600,
        size: 22,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
    );
  }

  Widget _buildDivider(bool isLight) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: isLight
          ? const Color(0xFFF2F2F7)
          : Colors.white.withValues(alpha: 0.05),
    );
  }
}
