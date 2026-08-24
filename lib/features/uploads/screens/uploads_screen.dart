import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/database/tables/media_table.dart';
import '../../../core/database/app_database.dart';
import '../widgets/manual_folder_upload_sheet.dart';

class UploadsScreen extends ConsumerStatefulWidget {
  const UploadsScreen({super.key});

  @override
  ConsumerState<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends ConsumerState<UploadsScreen> {
  final Set<String> _expandedPaths = {};
  final Map<String, String> _realPathCache = {};
  List<String>? _savedBackupFolderIds;
  List<({String name, int count, String id})> _monitoredFolders = [];
  bool _autoBackupEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAutoBackupPref();
    _loadBackupFoldersPref();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dao = ref.read(mediaDaoProvider);
      ref.read(channelManagerProvider).syncFromCloud(dao);
    });
  }

  Future<void> _loadBackupFoldersPref() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('telecloud_backup_folder_ids');
    try {
      final rawFolders = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      final monitored = <({String name, int count, String id})>[];
      for (final folder in rawFolders) {
        final nameLower = folder.name.trim().toLowerCase();
        if (folder.isAll || nameLower == 'recent' || nameLower == 'all') {
          continue;
        }
        if (savedIds == null ||
            savedIds.isEmpty ||
            savedIds.contains(folder.id) ||
            savedIds.any((s) => folder.name.toLowerCase().contains(s.toLowerCase()))) {
          final count = await folder.assetCountAsync;
          monitored.add((name: folder.name, count: count, id: folder.id));
        }
      }
      if (mounted) {
        setState(() {
          _savedBackupFolderIds = savedIds;
          _monitoredFolders = monitored;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _savedBackupFolderIds = savedIds;
        });
      }
    }
  }

  Future<void> _loadAutoBackupPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _autoBackupEnabled =
            prefs.getBool(AppConstants.keyAutoBackupEnabled) ??
            AppConstants.defaultAutoBackupEnabled;
      });
    }
  }

  Future<void> _toggleAutoBackup(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAutoBackupEnabled, val);
    if (mounted) {
      setState(() {
        _autoBackupEnabled = val;
      });
    }
    if (val) {
      ref.read(backupManagerProvider).scheduleBackgroundWorker(forceReschedule: true);
    } else {
      ref.read(backupManagerProvider).cancelBackgroundWorker();
    }
    HapticFeedback.selectionClick();
  }

  bool _isFolderSelectedForBackup(String dirPath) {
    if (_savedBackupFolderIds == null || _savedBackupFolderIds!.isEmpty) {
      return true;
    }
    if (dirPath.startsWith('Google Photos') || dirPath.startsWith('Telegram Cloud')) {
      return true;
    }
    final leaf = _parseLeafFolderName(dirPath).toLowerCase();
    for (final id in _savedBackupFolderIds!) {
      final idLower = id.toLowerCase();
      if (idLower == leaf || dirPath.toLowerCase().contains(idLower) || idLower.contains(leaf)) {
        return true;
      }
    }
    return false;
  }

  String _resolveDirectoryPath(MediaItem item) {
    if (_realPathCache.containsKey(item.localId)) {
      return _realPathCache[item.localId]!;
    }
    if (item.localId.startsWith('gp_')) {
      return 'Google Photos (Cloud Sync)';
    }
    if (item.localId.startsWith('tg_')) {
      return 'Telegram Cloud (Remote)';
    }
    final name = item.filename.toLowerCase();
    if (name.startsWith('screenshot') || name.contains('screen')) {
      return '/storage/emulated/0/Pictures/Screenshots';
    } else if (name.startsWith('wa') || name.contains('whatsapp')) {
      return '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images';
    } else if (name.contains('telegram')) {
      return '/storage/emulated/0/Pictures/Telegram';
    } else if (name.contains('doc') || name.contains('download')) {
      return '/storage/emulated/0/Download';
    } else if (name.contains('instagram')) {
      return '/storage/emulated/0/Pictures/Instagram';
    }
    return '/storage/emulated/0/DCIM/Camera';
  }

  String _parseLeafFolderName(String dirPath) {
    if (dirPath.startsWith('Google Photos')) return 'Google Photos';
    if (dirPath.startsWith('Telegram Cloud')) return 'Telegram Cloud';
    final parts = dirPath
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Camera';
    return parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(uploadTelemetryProvider);
    final backupManager = ref.watch(backupManagerProvider);
    final mediaScanner = ref.watch(mediaScannerProvider);
    final mediaDao = ref.watch(mediaDaoProvider);

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor = isLight ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Uploads & Activity',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_to_photos_rounded,
              color: Color(0xFF0A84FF),
            ),
            tooltip: 'Manual Folder Upload',
            onPressed: () {
              HapticFeedback.lightImpact();
              ManualFolderUploadSheet.show(context);
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF30D158),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF30D158).withValues(alpha: 0.8),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Live Upload Telemetry Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLight
                        ? const Color(0xFFE5E5EA)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                  gradient: isLight
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0A84FF,
                            ).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            telemetry.isUploading
                                ? Icons.cloud_upload
                                : Icons.cloud_done_rounded,
                            color: const Color(0xFF0A84FF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                telemetry.isUploading
                                    ? (telemetry.batchTotalCount > 0
                                          ? 'Uploading ${telemetry.batchCurrentIndex} of ${telemetry.batchTotalCount} items...'
                                          : 'Uploading to Telegram Cloud...')
                                    : !_autoBackupEnabled
                                    ? 'Auto-Upload Paused'
                                    : telemetry.pendingCount > 0
                                    ? '${telemetry.pendingCount} Items in Queue'
                                    : 'Cloud Sync Idle',
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                telemetry.isUploading
                                    ? '${(telemetry.speedMBps).toStringAsFixed(1)} MB/s • ${(telemetry.overallBatchProgress * 100).toInt()}% overall${telemetry.estimatedTimeRemaining != null ? ' • ${telemetry.estimatedTimeRemaining!.inSeconds}s remaining' : ''}'
                                    : '${telemetry.completedCount} photos safely backed up',
                                style: TextStyle(
                                  color: isLight
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Auto Upload Toggle Switch
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch.adaptive(
                              value: _autoBackupEnabled,
                              activeTrackColor: const Color(0xFF30D158),
                              onChanged: _toggleAutoBackup,
                            ),
                            Text(
                              'Auto Upload',
                              style: TextStyle(
                                color: isLight
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Overall Batch Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: telemetry.isUploading
                            ? telemetry.overallBatchProgress
                            : (telemetry.pendingCount == 0 ? 1.0 : 0.0),
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          telemetry.isUploading
                              ? const Color(0xFF0A84FF)
                              : const Color(0xFF30D158),
                        ),
                      ),
                    ),

                    if (telemetry.currentItem != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFFF2F2F7)
                              : const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFF0A84FF,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (telemetry.currentItem!.thumbnailPath != null &&
                                File(
                                  telemetry.currentItem!.thumbnailPath!,
                                ).existsSync())
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(telemetry.currentItem!.thumbnailPath!),
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0A84FF,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  color: Color(0xFF0A84FF),
                                  size: 18,
                                ),
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    telemetry.currentItem!.filename,
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Current file: ${(telemetry.progress * 100).toInt()}% • Original Uncompressed',
                                    style: TextStyle(
                                      color: isLight
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                value: telemetry.progress > 0
                                    ? telemetry.progress
                                    : null,
                                strokeWidth: 2,
                                color: const Color(0xFF0A84FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 2. Self-Healing Recovery Notice Banner (if any)
          if (telemetry.recentRecoveryNotice != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_fix_high_rounded,
                        color: Color(0xFF0A84FF),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          telemetry.recentRecoveryNotice!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 16,
                        ),
                        onPressed: () {
                          ref
                              .read(uploadTelemetryProvider.notifier)
                              .clearRecoveryNotice();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Dynamic Contextual Action Controls
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: telemetry.isUploading
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C2E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.stop_rounded,
                          color: Color(0xFFFF453A),
                          size: 20,
                        ),
                        label: const Text(
                          'Stop Upload',
                          style: TextStyle(
                            color: Color(0xFFFF453A),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: () {
                          final messenger = ScaffoldMessenger.of(context);
                          backupManager.onStopUploading?.call();
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Upload stopped.'),
                              backgroundColor: Color(0xFF2C2C2E),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    )
                  : telemetry.pendingCount > 0
                      ? Column(
                          children: [
                            _AnimatedStartUploadButton(
                              pendingCount: telemetry.pendingCount,
                              onPressed: () async {
                                await mediaScanner.scanCameraRoll();
                                backupManager.onStartUploading?.call();
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C2C2E),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.stop_rounded,
                                  color: Color(0xFFFF453A),
                                  size: 20,
                                ),
                                label: const Text(
                                  'Stop Upload',
                                  style: TextStyle(
                                    color: Color(0xFFFF453A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  backupManager.onStopUploading?.call();
                                  await mediaDao.cancelPendingUploads();
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Upload stopped and queue cleared.',
                                      ),
                                      backgroundColor: Color(0xFF2C2C2E),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF30D158,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF30D158,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: Color(0xFF30D158),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'All Photos & Videos Synced',
                                style: TextStyle(
                                  color: Color(0xFF30D158),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
            ),

          // 4. Live Self-Healing & Activity Feed (if available)
          if (telemetry.activityLogs.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            color: Color(0xFF0A84FF),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Self-Healing & Sync Activity',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...telemetry.activityLogs
                          .take(3)
                          .map(
                            (log) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: Text(
                                log,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 4b. Dedicated Monitored Backup Folders Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_special_rounded,
                        color: Color(0xFF0A84FF),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'MONITORED BACKUP FOLDERS',
                        style: TextStyle(
                          color: isLight
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await context.push('/settings/folders');
                      _loadBackupFoldersPref();
                    },
                    child: const Text(
                      'Manage',
                      style: TextStyle(
                        color: Color(0xFF0A84FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 88,
              child: _monitoredFolders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isLight
                              ? Colors.white
                              : const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isLight
                                ? const Color(0xFFE5E5EA)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.folder_open_rounded,
                              color: Color(0xFF0A84FF),
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'All device camera & photo folders monitored',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLight
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await context.push('/settings/folders');
                                _loadBackupFoldersPref();
                              },
                              child: const Text('Configure'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _monitoredFolders.length,
                      itemBuilder: (context, index) {
                        final f = _monitoredFolders[index];
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.white
                                : const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isLight
                                  ? const Color(0xFFE5E5EA)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(
                                    Icons.folder_rounded,
                                    color: Color(0xFF0A84FF),
                                    size: 20,
                                  ),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF30D158),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF30D158,
                                          ).withValues(alpha: 0.6),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.name,
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${f.count} items',
                                    style: TextStyle(
                                      color: isLight
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // 5. Queue Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Directory Tree Queue',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${telemetry.pendingCount} pending',
                    style: TextStyle(
                      color: isLight
                          ? Colors.grey.shade600
                          : Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // 4. Live Hierarchical File Tree Directory View
          StreamBuilder<List<MediaItem>>(
            stream: mediaDao.watchActiveUploadQueue(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
                  ),
                );
              }

              final allItems = snapshot.data!;
              final items = allItems.where((i) {
                final dir = _resolveDirectoryPath(i);
                return _isFolderSelectedForBackup(dir);
              }).toList();

              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 36.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0A84FF,
                            ).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_done_rounded,
                            color: Color(0xFF0A84FF),
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Upload Queue is Idle',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All items from selected backup folders are synced',
                          style: TextStyle(
                            color: isLight
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF0A84FF),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              icon: const Icon(
                                Icons.folder_open_rounded,
                                color: Color(0xFF0A84FF),
                                size: 18,
                              ),
                              label: const Text(
                                'Manual Folder Upload',
                                style: TextStyle(
                                  color: Color(0xFF0A84FF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                ManualFolderUploadSheet.show(context);
                              },
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A84FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              icon: const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: const Text(
                                'Backup Folders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                await context.push('/settings/folders');
                                _loadBackupFoldersPref();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Group items by pure directory path
              final dirGroups = <String, List<MediaItem>>{};
              for (final item in items) {
                final dir = _resolveDirectoryPath(item);
                dirGroups.putIfAbsent(dir, () => []).add(item);
              }

              final directories = dirGroups.keys.toList();

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= directories.length) return null;
                    final dirPath = directories[index];
                    final dirItems = dirGroups[dirPath]!;
                    final isExpanded = _expandedPaths.contains(dirPath);

                    final dirTotalBytes = dirItems.fold<int>(
                      0,
                      (sum, i) => sum + (i.fileSizeBytes ?? 0),
                    );
                    final dirTotalMb = (dirTotalBytes / (1024 * 1024))
                        .toStringAsFixed(1);
                    final pendingInDir = dirItems
                        .where((i) => i.uploadStatus == UploadStatus.pending)
                        .length;
                    final uploadingInDir = dirItems
                        .where(
                          (i) =>
                              i.uploadStatus == UploadStatus.uploading ||
                              (telemetry.currentItem?.localId == i.localId &&
                                  telemetry.isUploading),
                        )
                        .length;
                    final failedInDir = dirItems
                        .where((i) => i.uploadStatus == UploadStatus.failed)
                        .length;
                    final doneInDir = dirItems
                        .where((i) => i.uploadStatus == UploadStatus.done)
                        .length;

                    final isDirActive = uploadingInDir > 0;
                    final isDirAllDone = doneInDir == dirItems.length;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isLight ? Colors.white : const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDirActive
                              ? const Color(0xFF0A84FF)
                              : (isLight
                                    ? const Color(0xFFE5E5EA)
                                    : Colors.white.withValues(alpha: 0.08)),
                          width: isDirActive ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Folder Directory Tree Node Header
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (isExpanded) {
                                  _expandedPaths.remove(dirPath);
                                } else {
                                  _expandedPaths.add(dirPath);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.25 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      color: isLight
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isExpanded
                                        ? Icons.folder_open_rounded
                                        : Icons.folder_rounded,
                                    color: isDirActive
                                        ? const Color(0xFF0A84FF)
                                        : (isDirAllDone
                                              ? const Color(0xFF30D158)
                                              : const Color(0xFF0A84FF)),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _parseLeafFolderName(dirPath),
                                          style: TextStyle(
                                            color: primaryTextColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$dirPath • ${dirItems.length} items • $dirTotalMb MB',
                                          style: TextStyle(
                                            color: isLight
                                                ? Colors.grey.shade600
                                                : Colors.grey.shade400,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isDirAllDone)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF30D158,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 11,
                                            color: Color(0xFF30D158),
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Synced',
                                            style: TextStyle(
                                              color: Color(0xFF30D158),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (isDirActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF0A84FF,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 8,
                                            height: 8,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: Color(0xFF0A84FF),
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Uploading',
                                            style: TextStyle(
                                              color: Color(0xFF0A84FF),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isLight
                                                ? Colors.grey.shade200
                                                : Colors.white.withValues(
                                                    alpha: 0.08,
                                                  ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            failedInDir > 0
                                                ? '$failedInDir Failed • $pendingInDir Pending'
                                                : '$pendingInDir Pending',
                                            style: TextStyle(
                                              color: failedInDir > 0
                                                  ? const Color(0xFFFF453A)
                                                  : (isLight
                                                      ? Colors.grey.shade700
                                                      : Colors.grey.shade400),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF0A84FF),
                                            side: const BorderSide(
                                              color: Color(0xFF0A84FF),
                                              width: 1.2,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 13,
                                          ),
                                          label: const Text(
                                            'Upload',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onPressed: () async {
                                            HapticFeedback.mediumImpact();
                                            final pendingIds = dirItems
                                                .where(
                                                  (i) =>
                                                      i.uploadStatus !=
                                                      UploadStatus.done,
                                                )
                                                .map((i) => i.localId)
                                                .toList();
                                            await mediaDao
                                                .queueLocalIdsForUpload(
                                                  pendingIds,
                                                );
                                            final folderLeaf =
                                                _parseLeafFolderName(dirPath);
                                            final channelMgr = ref.read(
                                              channelManagerProvider,
                                            );
                                            await channelMgr.ensureAlbumTopic(
                                              folderLeaf,
                                            );
                                            backupManager.onStartUploading
                                                ?.call();
                                          },
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Active progress indicator on directory node
                          if (isDirActive)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: telemetry.progress > 0
                                      ? telemetry.progress
                                      : null,
                                  minHeight: 3,
                                  backgroundColor: isLight
                                      ? Colors.black12
                                      : Colors.white.withValues(alpha: 0.1),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0A84FF),
                                      ),
                                ),
                              ),
                            ),

                          // Indented Media Items in Tree View
                          if (isExpanded) ...[
                            Divider(
                              height: 1,
                              color: isLight
                                  ? const Color(0xFFE5E5EA)
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(18, 8, 12, 10),
                              itemCount: dirItems.length,
                              separatorBuilder: (context, idx) => Divider(
                                height: 1,
                                indent: 28,
                                color: isLight
                                    ? const Color(0xFFF2F2F7)
                                    : Colors.white.withValues(alpha: 0.03),
                              ),
                              itemBuilder: (context, itemIdx) {
                                final item = dirItems[itemIdx];
                                final isUploading =
                                    item.uploadStatus ==
                                        UploadStatus.uploading ||
                                    (telemetry.currentItem?.localId ==
                                            item.localId &&
                                        telemetry.isUploading);
                                final isDone =
                                    item.uploadStatus == UploadStatus.done;
                                final isFailed =
                                    item.uploadStatus == UploadStatus.failed;
                                final isLast = itemIdx == dirItems.length - 1;

                                final thumbPath = item.thumbnailPath;
                                final hasThumb =
                                    thumbPath != null &&
                                    thumbPath.isNotEmpty;
                                final sizeMb = item.fileSizeBytes != null
                                    ? (item.fileSizeBytes! / (1024 * 1024))
                                          .toStringAsFixed(1)
                                    : '0.0';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  child: Row(
                                    children: [
                                      // Tree Branch Connector
                                      Text(
                                        isLast ? '└─ ' : '├─ ',
                                        style: TextStyle(
                                          color: isLight
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => context.push('/viewer/${item.localId}'),
                                        child: Hero(
                                          tag: 'media_${item.localId}',
                                          child: Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: isLight
                                                  ? Colors.grey.shade200
                                                  : Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(
                                                6,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(
                                                6,
                                              ),
                                              child: hasThumb
                                                  ? Image.file(
                                                      File(thumbPath),
                                                      fit: BoxFit.cover,
                                                      cacheWidth: 80,
                                                      cacheHeight: 80,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Icon(
                                                            Icons.image,
                                                            size: 18,
                                                            color: isLight
                                                                ? Colors
                                                                      .grey
                                                                      .shade400
                                                                : Colors.grey,
                                                          ),
                                                    )
                                                  : Icon(
                                                      Icons.image,
                                                      size: 18,
                                                      color: isLight
                                                          ? Colors.grey.shade400
                                                          : Colors.grey,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => context.push('/viewer/${item.localId}'),
                                          behavior: HitTestBehavior.opaque,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.filename,
                                                style: TextStyle(
                                                  color: primaryTextColor,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                '$sizeMb MB • ${item.capturedAt.toLocal().toString().split('.')[0]}',
                                                style: TextStyle(
                                                  color: isLight
                                                      ? Colors.grey.shade600
                                                      : Colors.grey.shade500,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isDone)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 16,
                                          color: Color(0xFF30D158),
                                        )
                                      else if (isUploading)
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF0A84FF),
                                          ),
                                        )
                                      else if (isFailed)
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          size: 16,
                                          color: Color(0xFFFF453A),
                                        )
                                      else
                                        Text(
                                          'Pending',
                                          style: TextStyle(
                                            color: isLight
                                                ? Colors.grey.shade600
                                                : Colors.grey.shade400,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }, childCount: directories.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnimatedStartUploadButton extends StatefulWidget {
  final int pendingCount;
  final VoidCallback onPressed;

  const _AnimatedStartUploadButton({
    required this.pendingCount,
    required this.onPressed,
  });

  @override
  State<_AnimatedStartUploadButton> createState() =>
      _AnimatedStartUploadButtonState();
}

class _AnimatedStartUploadButtonState extends State<_AnimatedStartUploadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF0A84FF), Color(0xFF0066CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A84FF).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTapDown: (_) => _animController.forward(),
            onTapUp: (_) => _animController.reverse(),
            onTapCancel: () => _animController.reverse(),
            onTap: () {
              HapticFeedback.heavyImpact();
              widget.onPressed();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Resume Upload (${widget.pendingCount})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

