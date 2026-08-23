import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/dual_app_setup_dialog.dart';

class QuickSettingsGuideScreen extends StatefulWidget {
  const QuickSettingsGuideScreen({super.key});

  @override
  State<QuickSettingsGuideScreen> createState() => _QuickSettingsGuideScreenState();
}

class _QuickSettingsGuideScreenState extends State<QuickSettingsGuideScreen> {
  bool _losslessQuality = true;
  bool _wifiOnly = true;
  bool _chargingOnly = false;
  bool _cameraBackup = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPreferences();
  }

  Future<void> _loadExistingPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _wifiOnly = prefs.getBool('backup_wifi_only') ?? true;
        _chargingOnly = prefs.getBool('backup_charging_only') ?? false;
        _cameraBackup = prefs.getBool('backup_camera_auto') ?? true;
        _losslessQuality = prefs.getBool('backup_lossless') ?? true;
      });
    } catch (_) {}
  }

  Future<void> _finishSetup() async {
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('backup_wifi_only', _wifiOnly);
      await prefs.setBool('backup_charging_only', _chargingOnly);
      await prefs.setBool('backup_camera_auto', _cameraBackup);
      await prefs.setBool('backup_lossless', _losslessQuality);
      await prefs.setBool('telecloud_onboarding_completed', true);
      await prefs.setBool('telecloud_is_authenticated', true);
    } catch (_) {}

    if (!mounted) return;

    // Prompt user for TeleCloud Files companion launcher setup
    await DualAppSetupDialog.show(context);

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('🎉 Welcome to TeleCloud! Setup Complete.'),
        backgroundColor: Color(0xFF30D158),
        duration: Duration(seconds: 2),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0A84FF).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, color: Color(0xFF0A84FF), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'STEP 3 OF 3 · QUICK SETTINGS GUIDE',
                      style: TextStyle(
                        color: Color(0xFF0A84FF),
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
                'Cloud Backup Preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Customize your sync preferences. You can adjust these anytime in Settings.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Setting Card 1: Lossless Quality
              _buildToggleCard(
                icon: Icons.hd_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: 'Lossless Original Quality',
                subtitle: 'Store photos & 4K videos in original raw resolution without compression.',
                value: _losslessQuality,
                onChanged: (val) => setState(() => _losslessQuality = val),
              ),
              const SizedBox(height: 12),

              // Setting Card 2: Wi-Fi Only
              _buildToggleCard(
                icon: Icons.wifi_rounded,
                iconColor: const Color(0xFF0A84FF),
                title: 'Back up on Wi-Fi Only',
                subtitle: 'Saves mobile data by backing up photos only when connected to Wi-Fi.',
                value: _wifiOnly,
                onChanged: (val) => setState(() => _wifiOnly = val),
              ),
              const SizedBox(height: 12),

              // Setting Card 3: Charging Only
              _buildToggleCard(
                icon: Icons.battery_charging_full_rounded,
                iconColor: const Color(0xFF30D158),
                title: 'Back up while Charging',
                subtitle: 'Optimizes battery life by running heavy upload sync while plugged into power.',
                value: _chargingOnly,
                onChanged: (val) => setState(() => _chargingOnly = val),
              ),
              const SizedBox(height: 12),

              // Setting Card 4: Camera Auto-Backup
              _buildToggleCard(
                icon: Icons.camera_alt_rounded,
                iconColor: const Color(0xFFFF9F0A),
                title: 'Auto-Sync Camera Photos',
                subtitle: 'Automatically detects and queues new photos taken with your camera.',
                value: _cameraBackup,
                onChanged: (val) => setState(() => _cameraBackup = val),
              ),
              const SizedBox(height: 36),

              // Finish Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                  label: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Finish Setup & Enter TeleCloud',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        border: Border.all(color: value ? iconColor.withValues(alpha: 0.3) : Colors.white10),
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
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeColor: iconColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
