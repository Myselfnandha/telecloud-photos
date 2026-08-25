import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radii.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/theme/app_elevation.dart';
import '../../../../shared/theme/app_icons.dart';
import '../../widgets/cloud_import_dialog.dart';
import '../../widgets/account_switcher_sheet.dart';

class CloudMigrationSettingsScreen extends ConsumerWidget {
  const CloudMigrationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Cloud Migration & Imports',
          style: AppTypography.titleLarge(
            color: primaryTextColor,
          ).copyWith(fontWeight: AppTypography.bold),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            'GOOGLE PHOTOS MIGRATION',
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
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: Color(0xFF4285F4),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Google Photos Sync Hub',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Direct authentic Google OAuth2 streaming sync to Telegram',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                  ),
                  onTap: () => context.push('/google-photos'),
                ),
                _buildDivider(isLight),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF34A853),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'View Synced Cloud Library',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Browse all imported Google Photos with bit-for-bit originals',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                  ),
                  onTap: () => context.push('/google-photos/synced'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'ARCHIVES & TAKE-OUT',
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBC05).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder_zip_rounded,
                  color: Color(0xFFFBBC05),
                  size: 22,
                ),
              ),
              title: Text(
                'Google Takeout Zip Importer',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Bulk extract and upload Takeout zip packages directly to cloud',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
              onTap: () => showDialog(
                context: context,
                builder: (_) => const CloudImportDialog(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'TELEGRAM ACCOUNTS',
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.switch_account_rounded,
                  color: Color(0xFF0A84FF),
                  size: 22,
                ),
              ),
              title: Text(
                'Multi-Account Switcher',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Manage multiple Telegram cloud sessions & vaults',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
              onTap: () => AccountSwitcherSheet.show(context),
            ),
          ),
        ],
      ),
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
