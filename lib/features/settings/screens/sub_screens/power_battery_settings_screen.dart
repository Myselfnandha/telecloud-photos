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

class PowerBatterySettingsScreen extends ConsumerStatefulWidget {
  const PowerBatterySettingsScreen({super.key});

  @override
  ConsumerState<PowerBatterySettingsScreen> createState() =>
      _PowerBatterySettingsScreenState();
}

class _PowerBatterySettingsScreenState
    extends ConsumerState<PowerBatterySettingsScreen> {
  bool _chargingOnly = true;
  int _chargingDwellMins = 30;
  bool _batteryNotLow = true;
  bool _autoKillWhenDone = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _chargingOnly =
          prefs.getBool(AppConstants.keyChargingOnly) ??
          AppConstants.defaultChargingOnly;
      _chargingDwellMins =
          prefs.getInt(AppConstants.keyChargingDwellMins) ??
          AppConstants.defaultChargingDwellMins;
      _batteryNotLow =
          prefs.getBool(AppConstants.keyBatteryNotLow) ??
          AppConstants.defaultBatteryNotLow;
      _autoKillWhenDone =
          prefs.getBool(AppConstants.keyAutoKillWhenDone) ??
          AppConstants.defaultAutoKillWhenDone;
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
          'Power & Battery Constraints',
          style: AppTypography.titleLarge(
            color: primaryTextColor,
          ).copyWith(fontWeight: AppTypography.bold),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            'CHARGING & DWELL TIME',
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
                    'Backup Only While Charging',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Postpone uploads until connected to wall power',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  value: _chargingOnly,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    setState(() => _chargingOnly = val);
                    _saveSetting(AppConstants.keyChargingOnly, val);
                    HapticFeedback.selectionClick();
                  },
                ),
                if (_chargingOnly) ...[
                  _buildDivider(isLight),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Thermal Stabilization Delay',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${_chargingDwellMins}m',
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Waits for device battery temperature to stabilize before intensive transfers',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                        Slider.adaptive(
                          value: _chargingDwellMins.toDouble(),
                          min: 0,
                          max: 60,
                          divisions: 4,
                          activeColor: AppColors.primaryBlue,
                          onChanged: (v) {
                            setState(() => _chargingDwellMins = v.toInt());
                            _saveSetting(
                              AppConstants.keyChargingDwellMins,
                              v.toInt(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'BATTERY PROTECTION & WORKER LIFECYCLE',
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
                    'Pause on Low Battery (< 20%)',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Automatically halts sync to avoid battery drain',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  value: _batteryNotLow,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    setState(() => _batteryNotLow = val);
                    _saveSetting(AppConstants.keyBatteryNotLow, val);
                    HapticFeedback.selectionClick();
                  },
                ),
                _buildDivider(isLight),
                SwitchListTile.adaptive(
                  title: Text(
                    'Auto-Kill Idle Background Worker',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Immediately releases Android WakeLock when upload queue is clean',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  value: _autoKillWhenDone,
                  activeTrackColor: const Color(0xFF30D158),
                  onChanged: (val) {
                    setState(() => _autoKillWhenDone = val);
                    _saveSetting(AppConstants.keyAutoKillWhenDone, val);
                    HapticFeedback.selectionClick();
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
