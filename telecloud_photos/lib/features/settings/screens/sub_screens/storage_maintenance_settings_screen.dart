import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/di/providers.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radii.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/theme/app_elevation.dart';
import '../../../../shared/theme/app_icons.dart';

class StorageMaintenanceSettingsScreen extends ConsumerStatefulWidget {
  const StorageMaintenanceSettingsScreen({super.key});

  @override
  ConsumerState<StorageMaintenanceSettingsScreen> createState() =>
      _StorageMaintenanceSettingsScreenState();
}

class _StorageMaintenanceSettingsScreenState
    extends ConsumerState<StorageMaintenanceSettingsScreen> {
  String _cacheSize = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      int totalBytes = 0;
      if (await cacheDir.exists()) {
        await for (final file in cacheDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (file is File) {
            totalBytes += await file.length();
          }
        }
      }
      if (mounted) {
        setState(() {
          _cacheSize = '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cacheSize = '0.0 MB');
    }
  }

  Future<void> _clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        final entities = cacheDir.listSync(recursive: false);
        for (final entity in entities) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (_) {}
        }
      }
      await _calculateCacheSize();
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Thumbnail cache cleared successfully.'),
            backgroundColor: Color(0xFF30D158),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showDeepKillConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderXL),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.errorRed,
              size: AppIcons.l,
            ),
            AppSpacing.gapHorizontalM,
            Text(
              'Deep App Kill',
              style: AppTypography.titleLarge(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'This will immediately terminate all active photo uploads, cancel background auto-sync tasks, stop foreground services, and shut down the app.\n\nNo background sync will run until you reopen the app.',
          style: AppTypography.bodyMedium(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.borderS,
              ),
            ),
            icon: const Icon(
              Icons.power_settings_new_rounded,
              size: AppIcons.s + 2,
            ),
            label: const Text(
              'Deep Kill & Exit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(backupManagerProvider.notifier).deepKillEverything();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Storage & Maintenance',
          style: AppTypography.titleLarge(
            color: primaryTextColor,
          ).copyWith(fontWeight: AppTypography.bold),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            'DEVICE DISK CLEANUP',
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
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF30D158).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cleaning_services_rounded,
                  color: Color(0xFF30D158),
                  size: 22,
                ),
              ),
              title: Text(
                'Free Up Device Space',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Safely delete local originals that have been verified in cloud',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
              onTap: () => context.push('/storage-cleaner'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'CACHE MANAGEMENT',
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
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cached_rounded,
                  color: Color(0xFF0A84FF),
                  size: 22,
                ),
              ),
              title: Text(
                'Clear Thumbnail Cache',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Current cache: $_cacheSize',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
              trailing: TextButton(
                onPressed: _clearCache,
                child: const Text('Clear'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'EMERGENCY DIAGNOSTICS & PROCESS CONTROL',
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
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: AppColors.errorRed,
                  size: 22,
                ),
              ),
              title: const Text(
                'Deep App Kill & Emergency Shutdown',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Force terminate all background tasks, services, and cancel wake-locks',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
              onTap: () => _showDeepKillConfirmation(context),
            ),
          ),
        ],
      ),
    );
  }
}
