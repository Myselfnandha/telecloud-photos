import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/di/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_icons.dart';

class _DeviceFolderData {
  final AssetPathEntity folder;
  final int count;
  final Uint8List? thumbBytes;

  _DeviceFolderData({
    required this.folder,
    required this.count,
    this.thumbBytes,
  });
}

class ManualFolderUploadSheet extends ConsumerStatefulWidget {
  const ManualFolderUploadSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const ManualFolderUploadSheet(),
    );
  }

  @override
  ConsumerState<ManualFolderUploadSheet> createState() =>
      _ManualFolderUploadSheetState();
}

class _ManualFolderUploadSheetState
    extends ConsumerState<ManualFolderUploadSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<_DeviceFolderData> _deviceFolders = [];
  final Set<String> _selectedFolderIds = {};
  final Set<int> _selectedAlbumIds = {};
  bool _isLoading = true;
  bool _isQueueing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDeviceFolders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceFolders() async {
    try {
      final rawFolders = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      final loaded = <_DeviceFolderData>[];

      for (final folder in rawFolders) {
        if (folder.isAll) continue;
        final count = await folder.assetCountAsync;
        if (count == 0) continue;

        Uint8List? thumb;
        try {
          final assets = await folder.getAssetListRange(start: 0, end: 1);
          if (assets.isNotEmpty) {
            thumb = await assets.first.thumbnailDataWithSize(
              const ThumbnailSize.square(120),
            );
          }
        } catch (_) {}

        loaded.add(
          _DeviceFolderData(folder: folder, count: count, thumbBytes: thumb),
        );
      }

      if (mounted) {
        setState(() {
          _deviceFolders = loaded;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calculateTotalSelectedItems(List<Album> customAlbums) {
    int total = 0;
    for (final folderData in _deviceFolders) {
      if (_selectedFolderIds.contains(folderData.folder.id)) {
        total += folderData.count;
      }
    }
    // We count custom albums as selected batches
    total += _selectedAlbumIds.length;
    return total;
  }

  Future<void> _startManualUpload() async {
    if (_selectedFolderIds.isEmpty && _selectedAlbumIds.isEmpty) return;

    setState(() => _isQueueing = true);
    HapticFeedback.mediumImpact();

    final scanner = ref.read(mediaScannerProvider);
    final dao = ref.read(mediaDaoProvider);
    final backupManager = ref.read(backupManagerProvider);

    // 1. Queue Device Folders
    for (final folderData in _deviceFolders) {
      if (_selectedFolderIds.contains(folderData.folder.id)) {
        await scanner.queueFolderForUpload(folderData.folder);
      }
    }

    // 2. Queue In-App Custom Albums
    for (final albumId in _selectedAlbumIds) {
      await dao.queueAlbumForUpload(albumId);
    }

    // 3. Immediately trigger upload engine
    backupManager.onStartUploading?.call();

    if (mounted) {
      setState(() => _isQueueing = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaDao = ref.watch(mediaDaoProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final secondaryTextColor = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;
    final sheetBg = isLight ? Colors.white : AppColors.darkSurface;
    final cardBg = isLight ? Colors.grey.shade100 : const Color(0xFF1C1C1E);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: AppRadii.borderTopXL,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isLight ? Colors.grey.shade300 : Colors.white24,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud_upload_rounded,
                        color: AppColors.primaryBlue,
                        size: AppIcons.l,
                      ),
                      AppSpacing.gapHorizontalS,
                      Text(
                        'Manual Cloud Upload',
                        style: AppTypography.titleLarge(
                          color: primaryTextColor,
                        ).copyWith(fontWeight: AppTypography.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: AppIcons.m),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs: Device Folders & In-App Albums
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryBlue,
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: secondaryTextColor,
                labelStyle: AppTypography.labelLarge(
                  color: AppColors.primaryBlue,
                ).copyWith(fontWeight: AppTypography.bold),
                tabs: const [
                  Tab(text: 'Device Folders'),
                  Tab(text: 'Custom Albums'),
                ],
              ),
            ),
            const Divider(height: 1),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Device Folders
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : _deviceFolders.isEmpty
                      ? Center(
                          child: Text(
                            'No media folders found on device',
                            style: AppTypography.bodyMedium(
                              color: secondaryTextColor,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          itemCount: _deviceFolders.length,
                          itemBuilder: (context, index) {
                            final item = _deviceFolders[index];
                            final isSelected = _selectedFolderIds.contains(
                              item.folder.id,
                            );

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryBlue.withValues(
                                        alpha: 0.12,
                                      )
                                    : cardBg,
                                borderRadius: AppRadii.borderL,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.transparent,
                                ),
                              ),
                              child: ListTile(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.borderL,
                                ),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (isSelected) {
                                      _selectedFolderIds.remove(item.folder.id);
                                    } else {
                                      _selectedFolderIds.add(item.folder.id);
                                    }
                                  });
                                },
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: AppColors.primaryBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          if (val == true) {
                                            _selectedFolderIds.add(
                                              item.folder.id,
                                            );
                                          } else {
                                            _selectedFolderIds.remove(
                                              item.folder.id,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    ClipRRect(
                                      borderRadius: AppRadii.borderM,
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        color: isLight
                                            ? Colors.grey.shade300
                                            : const Color(0xFF2C2C2E),
                                        child: item.thumbBytes != null
                                            ? Image.memory(
                                                item.thumbBytes!,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(
                                                Icons.folder_rounded,
                                                color: AppColors.primaryBlue,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  item.folder.name,
                                  style: AppTypography.bodyLarge(
                                    color: primaryTextColor,
                                  ).copyWith(
                                    fontWeight: isSelected
                                        ? AppTypography.bold
                                        : AppTypography.medium,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.count} items',
                                  style: AppTypography.labelSmall(
                                    color: secondaryTextColor,
                                  ),
                                ),
                                trailing: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryBlue,
                                    side: const BorderSide(
                                      color: AppColors.primaryBlue,
                                      width: 1.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
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
                                    final scanner = ref.read(
                                      mediaScannerProvider,
                                    );
                                    final backupManager = ref.read(
                                      backupManagerProvider,
                                    );
                                    final channelMgr = ref.read(
                                      channelManagerProvider,
                                    );
                                    await scanner
                                        .queueFolderForUpload(item.folder);
                                    await channelMgr.ensureAlbumTopic(
                                      item.folder.name,
                                    );
                                    backupManager.onStartUploading?.call();
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                  // Tab 2: Custom Albums
                  StreamBuilder<List<Album>>(
                    stream: mediaDao.watchAllAlbums(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        );
                      }

                      final albums = snapshot.data!;
                      if (albums.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: AppSpacing.screenPadding,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_album_outlined,
                                  size: 48,
                                  color: secondaryTextColor,
                                ),
                                AppSpacing.gapVerticalM,
                                Text(
                                  'No custom albums yet',
                                  style: AppTypography.titleMedium(
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: albums.length,
                        itemBuilder: (context, index) {
                          final album = albums[index];
                          final isSelected = _selectedAlbumIds.contains(
                            album.id,
                          );

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue.withValues(
                                      alpha: 0.12,
                                    )
                                  : cardBg,
                              borderRadius: AppRadii.borderL,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : Colors.transparent,
                              ),
                            ),
                            child: ListTile(
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadii.borderL,
                              ),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (isSelected) {
                                    _selectedAlbumIds.remove(album.id);
                                  } else {
                                    _selectedAlbumIds.add(album.id);
                                  }
                                });
                              },
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: AppColors.primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        if (val == true) {
                                          _selectedAlbumIds.add(album.id);
                                        } else {
                                          _selectedAlbumIds.remove(album.id);
                                        }
                                      });
                                    },
                                  ),
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: AppRadii.borderM,
                                    ),
                                    child: const Icon(
                                      Icons.photo_library_rounded,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                album.name,
                                style: AppTypography.bodyLarge(
                                  color: primaryTextColor,
                                ).copyWith(
                                  fontWeight: isSelected
                                      ? AppTypography.bold
                                      : AppTypography.medium,
                                ),
                              ),
                              subtitle: Text(
                                'Created ${album.createdAt.toLocal().toString().split(' ')[0]}',
                                style: AppTypography.labelSmall(
                                  color: secondaryTextColor,
                                ),
                              ),
                              trailing: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                  side: const BorderSide(
                                    color: AppColors.primaryBlue,
                                    width: 1.2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                                  final dao = ref.read(mediaDaoProvider);
                                  final backupManager = ref.read(
                                    backupManagerProvider,
                                  );
                                  final channelMgr = ref.read(
                                    channelManagerProvider,
                                  );
                                   await dao.queueAlbumForUpload(
                                     album.id,
                                   );
                                  await channelMgr.ensureAlbumTopic(album.name);
                                  backupManager.onStartUploading?.call();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom Action Bar
            StreamBuilder<List<Album>>(
              stream: mediaDao.watchAllAlbums(),
              builder: (context, snapshot) {
                final customAlbums = snapshot.data ?? [];
                final totalSelected = _calculateTotalSelectedItems(
                  customAlbums,
                );
                final hasSelection =
                    _selectedFolderIds.isNotEmpty ||
                    _selectedAlbumIds.isNotEmpty;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sheetBg,
                    border: Border(
                      top: BorderSide(
                        color: isLight ? Colors.grey.shade200 : Colors.white12,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Select All / Clear Toggle
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (_tabController.index == 0) {
                              if (_selectedFolderIds.length ==
                                  _deviceFolders.length) {
                                _selectedFolderIds.clear();
                              } else {
                                _selectedFolderIds.addAll(
                                  _deviceFolders.map((f) => f.folder.id),
                                );
                              }
                            } else {
                              if (_selectedAlbumIds.length ==
                                  customAlbums.length) {
                                _selectedAlbumIds.clear();
                              } else {
                                _selectedAlbumIds.addAll(
                                  customAlbums.map((a) => a.id),
                                );
                              }
                            }
                          });
                        },
                        child: Text(
                          hasSelection ? 'Clear' : 'Select All',
                          style: AppTypography.labelLarge(
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                      AppSpacing.gapHorizontalM,

                      // Upload Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            disabledBackgroundColor: isLight
                                ? Colors.grey.shade300
                                : Colors.white12,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadii.borderL,
                            ),
                          ),
                          icon: _isQueueing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.cloud_upload_rounded,
                                  color: Colors.white,
                                  size: AppIcons.m,
                                ),
                          label: Text(
                            _isQueueing
                                ? 'Queueing Items...'
                                : hasSelection
                                ? 'Upload Selected ($totalSelected)'
                                : 'Select Folders to Upload',
                            style: AppTypography.labelLarge(
                              color: Colors.white,
                            ).copyWith(fontWeight: AppTypography.bold),
                          ),
                          onPressed: hasSelection && !_isQueueing
                              ? _startManualUpload
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
