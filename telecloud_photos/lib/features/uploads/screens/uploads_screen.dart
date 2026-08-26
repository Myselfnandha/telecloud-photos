import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables/media_table.dart';
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../widgets/directory_tree_node.dart';
import '../widgets/error_recovery_banner.dart';
import '../widgets/manual_folder_upload_sheet.dart';
import '../widgets/monitored_folders_row.dart';
import '../widgets/upload_action_controls.dart';
import '../widgets/upload_telemetry_card.dart';

class UploadsScreen extends ConsumerStatefulWidget {
  const UploadsScreen({super.key});

  @override
  ConsumerState<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends ConsumerState<UploadsScreen> {
  final Set<String> _expandedPaths = {};
  final Map<String, String> _realPathCache = {};
  List<String>? _savedBackupFolderIds;
  List<MonitoredFolderItem> _monitoredFolders = [];
  bool _autoBackupEnabled = true;
  bool _errorBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadAutoBackupPref();
    _loadBackupFoldersPref();
  }

  Future<void> _loadBackupFoldersPref() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('telecloud_backup_folder_ids');
    try {
      final rawFolders = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      final monitored = <MonitoredFolderItem>[];
      for (final folder in rawFolders) {
        final rawName = folder.name.trim();
        final nameLower = rawName.toLowerCase();
        if (folder.isAll ||
            nameLower == 'recent' ||
            nameLower == 'all' ||
            nameLower == 'recent photos' ||
            nameLower.isEmpty) {
          continue;
        }
        if (savedIds == null ||
            savedIds.isEmpty ||
            savedIds.contains(folder.id) ||
            savedIds.any(
              (s) => rawName.toLowerCase().contains(s.toLowerCase()),
            )) {
          final count = await folder.assetCountAsync;
          if (count > 0) {
            monitored.add((name: rawName, count: count, id: folder.id));
          }
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
        _autoBackupEnabled = prefs.getBool(AppConstants.keyAutoBackupEnabled) ??
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
      ref
          .read(backupManagerProvider.notifier)
          .scheduleBackgroundWorker(forceReschedule: true);
    } else {
      ref.read(backupManagerProvider.notifier).cancelBackgroundWorker();
    }
    HapticFeedback.selectionClick();
  }

  bool _isFolderSelectedForBackup(String dirPath) {
    if (_savedBackupFolderIds == null || _savedBackupFolderIds!.isEmpty) {
      return true;
    }
    if (dirPath.startsWith('Google Photos') ||
        dirPath.startsWith('Telegram Cloud')) {
      return true;
    }
    final leaf = _parseLeafFolderName(dirPath).toLowerCase();
    for (final id in _savedBackupFolderIds!) {
      final idLower = id.toLowerCase();
      if (idLower == leaf ||
          dirPath.toLowerCase().contains(idLower) ||
          idLower.contains(leaf)) {
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
    if (item.folderName != null && item.folderName!.isNotEmpty) {
      return item.folderName!;
    }
    if (item.folderPath != null && item.folderPath!.isNotEmpty) {
      return item.folderPath!;
    }
    // Infer folder from filename patterns when metadata is missing
    final fn = item.filename.toUpperCase();
    if (fn.contains('SCREENSHOT')) return 'Screenshots';
    if (fn.startsWith('IMG_') || fn.startsWith('DCIM')) return 'Camera';
    if (fn.startsWith('VID_')) return 'Camera';
    if (fn.startsWith('MVIMG_')) return 'Camera';
    if (fn.startsWith('PXL_')) return 'Camera';
    if (fn.contains('DOWNLOAD')) return 'Download';
    if (fn.contains('WHATSAPP')) return 'WhatsApp Images';
    if (fn.contains('TELEGRAM')) return 'Telegram';
    return 'Camera';
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
    final backupManager = ref.watch(backupManagerProvider.notifier);
    final mediaScanner = ref.watch(mediaScannerProvider);
    final mediaDao = ref.watch(mediaDaoProvider);

    final theme = Theme.of(context);
    final primaryTextColor = AppColors.textPrimary(context);
    final secondaryTextColor = AppColors.textSecondary(context);

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
              color: AppColors.primaryBlue,
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
              color: AppColors.successGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.successGreen.withValues(alpha: 0.8),
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
              child: UploadTelemetryCard(
                telemetry: telemetry,
                autoBackupEnabled: _autoBackupEnabled,
                onToggleAutoBackup: _toggleAutoBackup,
              ),
            ),
          ),

          // 2. Error Recovery Banner (Feature 7)
          StreamBuilder<int>(
            stream: mediaDao.watchFailedCount(),
            builder: (context, snapshot) {
              final failedCount = snapshot.data ?? 0;
              if (failedCount <= 0 || _errorBannerDismissed) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: ErrorRecoveryBanner(
                  failedCount: failedCount,
                  onRetryAll: () async {
                    await mediaDao.retryAllFailed();
                    backupManager.onStartUploading?.call();
                  },
                  onDismiss: () {
                    setState(() {
                      _errorBannerDismissed = true;
                    });
                  },
                ),
              );
            },
          ),

          // 3. Self-Healing Recovery Notice Banner (if any)
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
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_fix_high_rounded,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          telemetry.recentRecoveryNotice!,
                          style: TextStyle(
                            color: primaryTextColor,
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

          // 4. Dynamic Contextual Action Controls
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: UploadActionControls(
                telemetry: telemetry,
                onStartUpload: () {
                  mediaScanner.scanCameraRoll();
                  backupManager.onStartUploading?.call();
                },
                onStopUpload: () {
                  backupManager.onStopUploading?.call();
                },
                onCancelAndClearQueue: () {
                  backupManager.onStopUploading?.call();
                  mediaDao.cancelPendingUploads();
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 5. Dedicated Monitored Backup Folders Section
          SliverToBoxAdapter(
            child: MonitoredFoldersRow(
              monitoredFolders: _monitoredFolders,
              onManageTap: () async {
                await context.push('/settings/folders');
                _loadBackupFoldersPref();
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // 6. Queue Section Header
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
                      color: secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // 7. Live Hierarchical File Tree Directory View
          StreamBuilder<List<MediaItem>>(
            stream: mediaDao.watchActiveUploadQueue(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
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
                            color:
                                AppColors.primaryBlue.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_done_rounded,
                            color: AppColors.primaryBlue,
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
                            color: secondaryTextColor,
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
                                  color: AppColors.primaryBlue,
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
                                color: AppColors.primaryBlue,
                                size: 18,
                              ),
                              label: const Text(
                                'Manual Folder Upload',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
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
                                backgroundColor: AppColors.primaryBlue,
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

              // Group items by directory path
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
                    final dirTotalMb =
                        (dirTotalBytes / (1024 * 1024)).toStringAsFixed(1);
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

                    return DirectoryTreeNode(
                      dirPath: dirPath,
                      leafFolderName: _parseLeafFolderName(dirPath),
                      dirItems: dirItems,
                      isExpanded: isExpanded,
                      isDirActive: isDirActive,
                      isDirAllDone: isDirAllDone,
                      pendingInDir: pendingInDir,
                      failedInDir: failedInDir,
                      dirTotalMb: dirTotalMb,
                      telemetry: telemetry,
                      onToggleExpand: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedPaths.remove(dirPath);
                          } else {
                            _expandedPaths.add(dirPath);
                          }
                        });
                      },
                      onUploadFolder: () {
                        final pendingIds = dirItems
                            .where(
                              (i) => i.uploadStatus != UploadStatus.done,
                            )
                            .map((i) => i.localId)
                            .toList();
                        mediaDao.queueLocalIdsForUpload(pendingIds);
                        backupManager.onStartUploading?.call();
                      },
                      onItemTap: (item) {
                        context.push('/viewer/${item.localId}');
                      },
                      onItemRetry: (item) {
                        mediaDao.retryFailedItem(item.localId);
                        backupManager.onStartUploading?.call();
                      },
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
