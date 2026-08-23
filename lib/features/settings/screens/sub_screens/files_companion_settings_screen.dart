import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/launcher_service.dart';
import '../../../../core/sync/files_sync_worker.dart';

class FilesCompanionSettingsScreen extends ConsumerStatefulWidget {
  const FilesCompanionSettingsScreen({super.key});

  @override
  ConsumerState<FilesCompanionSettingsScreen> createState() =>
      _FilesCompanionSettingsScreenState();
}

class _FilesCompanionSettingsScreenState
    extends ConsumerState<FilesCompanionSettingsScreen> {
  bool _isFilesLauncherEnabled = false;
  bool _isLoading = true;
  List<String> _monitoredFolders = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await LauncherService.isFilesLauncherEnabled();
    final folders = await FilesSyncWorker.getMonitoredFolders();
    if (mounted) {
      setState(() {
        _isFilesLauncherEnabled = enabled;
        _monitoredFolders = folders;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLauncherIcon(bool value) async {
    HapticFeedback.lightImpact();
    setState(() => _isFilesLauncherEnabled = value);
    await LauncherService.setFilesLauncherEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
              ? '✓ TeleCloud Files icon added to Home Screen'
              : 'TeleCloud Files icon removed from Home Screen',
          ),
          backgroundColor: value ? const Color(0xFF30D158) : Colors.grey.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        elevation: 0,
        title: const Text('Files Companion App', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF)))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Dual Launcher Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9F0A).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.folder_copy, color: Color(0xFFFF9F0A), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Home Screen Icon',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Display dedicated "TeleCloud Files" launcher icon',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isFilesLauncherEnabled,
                            activeColor: const Color(0xFF0A84FF),
                            onChanged: _toggleLauncherIcon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'When enabled, tapping the "TeleCloud Files" icon from your home screen directly opens your cloud drive explorer.',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Monitored Folders Section
                const Text(
                  'AUTOMATIC FOLDER BACKUP',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < _monitoredFolders.length; i++) ...[
                        if (i > 0) Divider(color: cardBorder, height: 1),
                        ListTile(
                          leading: const Icon(Icons.folder_open, color: Color(0xFF0A84FF)),
                          title: Text(_monitoredFolders[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Auto-syncs new documents & downloads to Cloud', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: const Icon(Icons.check_circle, color: Color(0xFF30D158), size: 18),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Storage Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF0A84FF)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Files are stored in your private "TeleCloud Files" Telegram supergroup with unlimited free storage up to 2GB (4GB for Telegram Premium) per file.',
                          style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
