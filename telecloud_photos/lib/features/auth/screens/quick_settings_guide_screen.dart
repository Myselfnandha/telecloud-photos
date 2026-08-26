import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';

class QuickSettingsGuideScreen extends ConsumerStatefulWidget {
  const QuickSettingsGuideScreen({super.key});

  @override
  ConsumerState<QuickSettingsGuideScreen> createState() =>
      _QuickSettingsGuideScreenState();
}

class _QuickSettingsGuideScreenState
    extends ConsumerState<QuickSettingsGuideScreen> {
  bool _autoBackup = AppConstants.defaultAutoBackupEnabled;
  bool _wifiOnly = AppConstants.defaultWifiOnly;
  bool _includeVideos = AppConstants.defaultIncludeVideos;
  bool _includeScreenshots = AppConstants.defaultIncludeScreenshots;
  bool _pureBlackTheme = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPreferences();
  }

  Future<void> _loadExistingPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _autoBackup =
              prefs.getBool(AppConstants.keyAutoBackupEnabled) ??
              AppConstants.defaultAutoBackupEnabled;
          _wifiOnly =
              prefs.getBool(AppConstants.keyWifiOnly) ??
              AppConstants.defaultWifiOnly;
          _includeVideos =
              prefs.getBool(AppConstants.keyIncludeVideos) ??
              AppConstants.defaultIncludeVideos;
          _includeScreenshots =
              prefs.getBool(AppConstants.keyIncludeScreenshots) ??
              AppConstants.defaultIncludeScreenshots;
          final themeMode = prefs.getString(AppConstants.keyAppTheme);
          _pureBlackTheme = themeMode != 'light' && themeMode != 'dark' || themeMode == 'pure_black';
        });
      }
    } catch (_) {}
  }

  Future<void> _finishSetup() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyAutoBackupEnabled, _autoBackup);
      await prefs.setBool(AppConstants.keyWifiOnly, _wifiOnly);
      await prefs.setBool(AppConstants.keyIncludeVideos, _includeVideos);
      await prefs.setBool(
        AppConstants.keyIncludeScreenshots,
        _includeScreenshots,
      );
      await prefs.setString(
        AppConstants.keyAppTheme,
        _pureBlackTheme ? 'pure_black' : 'dark',
      );
      await prefs.setBool('telecloud_onboarding_completed', true);
      await prefs.setBool('telecloud_is_authenticated', true);

      // Register or cancel background worker depending on auto-backup
      if (_autoBackup) {
        ref
            .read(backupManagerProvider.notifier)
            .scheduleBackgroundWorker(forceReschedule: true);
      } else {
        ref.read(backupManagerProvider.notifier).cancelBackgroundWorker();
      }
    } catch (_) {}

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('🎉 Welcome to TeleCloud Photos! Setup Complete.'),
        backgroundColor: Color(0xFF30D158),
        duration: Duration(seconds: 3),
      ),
    );

    context.go('/timeline');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: const Text(
          'Step 3 of 3 · Cloud Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Progress Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: AppColors.primaryBlue,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'STEP 3 OF 3 · QUICK SETTINGS GUIDE',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              const Text(
                'Initial Setup Preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Customize your essential sync and display preferences. You can adjust these anytime in Settings.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // 1. Auto-Sync Camera Roll
              _buildToggleCard(
                icon: Icons.camera_alt_rounded,
                iconColor: const Color(0xFFFF9F0A),
                title: 'Auto-Sync Camera Roll',
                subtitle:
                    'Automatically detects and queues new photos taken with your camera.',
                value: _autoBackup,
                onChanged: (val) => setState(() => _autoBackup = val),
              ),
              const SizedBox(height: 12),

              // 2. Wi-Fi Only Sync
              _buildToggleCard(
                icon: Icons.wifi_rounded,
                iconColor: AppColors.primaryBlue,
                title: 'Back up on Wi-Fi Only',
                subtitle:
                    'Saves mobile data by backing up photos only when connected to Wi-Fi.',
                value: _wifiOnly,
                onChanged: (val) => setState(() => _wifiOnly = val),
              ),
              const SizedBox(height: 12),

              // 3. Include Videos Backup
              _buildToggleCard(
                icon: Icons.videocam_rounded,
                iconColor: const Color(0xFF30B0C7),
                title: 'Include Videos Backup',
                subtitle:
                    'Automatically back up high-definition videos and screen recordings.',
                value: _includeVideos,
                onChanged: (val) => setState(() => _includeVideos = val),
              ),
              const SizedBox(height: 12),

              // 4. Include Screenshots
              _buildToggleCard(
                icon: Icons.screenshot_monitor_rounded,
                iconColor: const Color(0xFF5E5CE6),
                title: 'Include Screenshots',
                subtitle:
                    'Back up captured screenshots alongside camera roll photos.',
                value: _includeScreenshots,
                onChanged: (val) => setState(() => _includeScreenshots = val),
              ),
              const SizedBox(height: 12),

              // 5. Pure Black OLED Theme
              _buildToggleCard(
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFFFFD60A),
                title: 'Pure Black OLED Theme',
                subtitle:
                    'Deep OLED true-black aesthetic to maximize battery efficiency.',
                value: _pureBlackTheme,
                onChanged: (val) => setState(() => _pureBlackTheme = val),
              ),
              const SizedBox(height: 36),

              // Finish Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                  label: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Finish Setup & Enter TeleCloud',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  onPressed: _isSaving ? null : _finishSetup,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? iconColor.withValues(alpha: 0.3) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeColor: iconColor,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              onChanged(val);
            },
          ),
        ],
      ),
    );
  }
}
