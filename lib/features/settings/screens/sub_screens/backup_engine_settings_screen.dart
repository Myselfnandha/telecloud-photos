import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/backup/backup_manager.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radii.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/theme/app_elevation.dart';
import '../../../../shared/theme/app_icons.dart';

class BackupEngineSettingsScreen extends ConsumerStatefulWidget {
  const BackupEngineSettingsScreen({super.key});

  @override
  ConsumerState<BackupEngineSettingsScreen> createState() =>
      _BackupEngineSettingsScreenState();
}

class _BackupEngineSettingsScreenState
    extends ConsumerState<BackupEngineSettingsScreen> {
  bool _autoBackupEnabled = true;
  bool _wifiOnly = true;
  bool _allowMobileData = false;
  int _syncIntervalMins = 30;
  bool _uploadMp4Videos = true;
  bool _uploadMovVideos = true;
  bool _uploadScreenshots = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackupEnabled =
          prefs.getBool(AppConstants.keyAutoBackupEnabled) ??
          AppConstants.defaultAutoBackupEnabled;
      _wifiOnly =
          prefs.getBool(AppConstants.keyWifiOnly) ??
          AppConstants.defaultWifiOnly;
      _allowMobileData =
          prefs.getBool(AppConstants.keyAllowMobileData) ??
          AppConstants.defaultAllowMobileData;
      _syncIntervalMins =
          prefs.getInt(AppConstants.keySyncFrequencyMins) ??
          AppConstants.defaultSyncFrequencyMins;
      _uploadMp4Videos =
          prefs.getBool(AppConstants.keyIncludeMp4Videos) ??
          prefs.getBool(AppConstants.keyIncludeVideos) ??
          AppConstants.defaultIncludeMp4Videos;
      _uploadMovVideos =
          prefs.getBool(AppConstants.keyIncludeMovVideos) ??
          prefs.getBool(AppConstants.keyIncludeVideos) ??
          AppConstants.defaultIncludeMovVideos;
      _uploadScreenshots =
          prefs.getBool(AppConstants.keyIncludeScreenshots) ??
          AppConstants.defaultIncludeScreenshots;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
    await BackupManager().scheduleBackgroundWorker(forceReschedule: true);
  }

  @override
  Widget build(BuildContext context) {
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryTextColor,
            size: AppIcons.m,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Backup Engine & Rules',
          style: AppTypography.titleLarge(
            color: primaryTextColor,
          ).copyWith(fontWeight: AppTypography.bold),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Master Switch
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadii.borderXL,
              border: Border.all(color: cardBorder),
            ),
            child: SwitchListTile.adaptive(
              title: Text(
                'Background Auto-Backup',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Automatically scan and upload new media to Telegram',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
              value: _autoBackupEnabled,
              activeTrackColor: const Color(0xFF30D158),
              onChanged: (val) {
                setState(() => _autoBackupEnabled = val);
                _saveSetting(AppConstants.keyAutoBackupEnabled, val);
                HapticFeedback.selectionClick();
              },
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'BACKUP FOLDERS',
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
              leading: const Icon(
                Icons.folder_copy_rounded,
                color: Color(0xFF0A84FF),
              ),
              title: Text(
                'Select Backup Folders',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Choose device albums & directories for automated backup',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
              onTap: () => context.push('/settings/folders'),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'NETWORK POLICIES',
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
                SwitchListTile.adaptive(
                  title: Text(
                    'Backup Over Wi-Fi Only',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Prevent cellular mobile data consumption',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  value: _wifiOnly,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    setState(() {
                      _wifiOnly = val;
                      if (val) _allowMobileData = false;
                    });
                    _saveSetting(AppConstants.keyWifiOnly, val);
                    _saveSetting(AppConstants.keyAllowMobileData, _allowMobileData);
                    HapticFeedback.selectionClick();
                  },
                ),
                _buildDivider(isLight),
                SwitchListTile.adaptive(
                  title: Text(
                    'Allow Mobile Data Backup',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Permit uploads over 4G/5G cellular connections',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  value: _allowMobileData,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: _wifiOnly
                      ? null
                      : (val) {
                          setState(() => _allowMobileData = val);
                          _saveSetting(AppConstants.keyAllowMobileData, val);
                          HapticFeedback.selectionClick();
                        },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'MEDIA TYPES TO BACKUP',
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
                SwitchListTile.adaptive(
                  title: Text(
                    'MP4 Videos',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  value: _uploadMp4Videos,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    setState(() => _uploadMp4Videos = val);
                    _saveSetting(AppConstants.keyIncludeMp4Videos, val);
                    HapticFeedback.selectionClick();
                  },
                ),
                _buildDivider(isLight),
                SwitchListTile.adaptive(
                  title: Text(
                    'MOV / Apple QuickTime Videos',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  value: _uploadMovVideos,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    setState(() => _uploadMovVideos = val);
                    _saveSetting(AppConstants.keyIncludeMovVideos, val);
                    HapticFeedback.selectionClick();
                  },
                ),
                _buildDivider(isLight),
                SwitchListTile.adaptive(
                  title: Text(
                    'Device Screenshots',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  value: _uploadScreenshots,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    setState(() => _uploadScreenshots = val);
                    _saveSetting(AppConstants.keyIncludeScreenshots, val);
                    HapticFeedback.selectionClick();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'BACKGROUND SYNC FREQUENCY',
            style: AppTypography.labelSmall(
              color: secondaryTextColor,
            ).copyWith(fontWeight: AppTypography.bold, letterSpacing: 0.8),
          ),
          AppSpacing.gapVerticalS,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadii.borderXL,
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Periodic Sync Interval',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${_syncIntervalMins}m',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'WorkManager periodic background check interval',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
                Slider.adaptive(
                  value: _syncIntervalMins.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 7,
                  activeColor: AppColors.primaryBlue,
                  onChanged: (v) {
                    setState(() => _syncIntervalMins = v.toInt());
                    _saveSetting(AppConstants.keySyncFrequencyMins, v.toInt());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isLight) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isLight
          ? const Color(0xFFF2F2F7)
          : Colors.white.withValues(alpha: 0.05),
    );
  }
}
