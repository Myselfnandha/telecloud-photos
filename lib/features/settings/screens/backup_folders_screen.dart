import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_elevation.dart';

class _FolderThumbnail extends StatefulWidget {
  final AssetPathEntity folder;
  final Color fallbackColor;

  const _FolderThumbnail({
    required this.folder,
    required this.fallbackColor,
  });

  @override
  State<_FolderThumbnail> createState() => _FolderThumbnailState();
}

class _FolderThumbnailState extends State<_FolderThumbnail> {
  Uint8List? _thumbBytes;

  @override
  void initState() {
    super.initState();
    _fetchThumbnail();
  }

  Future<void> _fetchThumbnail() async {
    try {
      final assets = await widget.folder.getAssetListRange(start: 0, end: 1);
      if (assets.isNotEmpty && mounted) {
        final bytes = await assets.first.thumbnailDataWithSize(
          const ThumbnailSize.square(120),
        );
        if (mounted) {
          setState(() {
            _thumbBytes = bytes;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbBytes != null) {
      return Image.memory(
        _thumbBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.folder_rounded, color: widget.fallbackColor),
      );
    }
    return Icon(Icons.folder_rounded, color: widget.fallbackColor);
  }
}

class BackupFoldersScreen extends ConsumerStatefulWidget {
  const BackupFoldersScreen({super.key});

  @override
  ConsumerState<BackupFoldersScreen> createState() =>
      _BackupFoldersScreenState();
}

class _BackupFoldersScreenState extends ConsumerState<BackupFoldersScreen> {
  List<({AssetPathEntity folder, int count})> _cachedFolders = [];
  Set<String> _selectedFolderIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('telecloud_backup_folder_ids');

    final rawFolders = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    // Parallel instant count resolution
    final loadedList = await Future.wait(
      rawFolders.map((folder) async {
        final count = await folder.assetCountAsync;
        return (folder: folder, count: count);
      }),
    );

    if (mounted) {
      setState(() {
        _cachedFolders = loadedList;
        if (savedIds != null) {
          _selectedFolderIds = savedIds.toSet();
        } else {
          // Default to all folders selected
          _selectedFolderIds = rawFolders.map((f) => f.id).toSet();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFolder(AssetPathEntity folder, bool isSelected) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (isSelected) {
        _selectedFolderIds.add(folder.id);
        if (folder.name.isNotEmpty) _selectedFolderIds.add(folder.name);
      } else {
        _selectedFolderIds.remove(folder.id);
        if (folder.name.isNotEmpty) _selectedFolderIds.remove(folder.name);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'telecloud_backup_folder_ids',
      _selectedFolderIds.toList(),
    );

    await ref.read(folderSyncManagerProvider).setFolderBackupEnabled(
      folder.id,
      isSelected,
    );

    // Rescan camera roll in background to update active scope
    ref.read(mediaScannerProvider).scanCameraRoll();

    if (isSelected && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-backup enabled for "${folder.name}".'),
          action: SnackBarAction(
            label: 'Back up All',
            textColor: AppColors.primaryBlue,
            onPressed: () async {
              final count = await ref
                  .read(folderSyncManagerProvider)
                  .queueFolderHistoricalMedia(folder.name);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Queued $count historical items in "${folder.name}" for backup.',
                    ),
                  ),
                );
              }
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _selectAll(bool select) async {
    HapticFeedback.mediumImpact();
    setState(() {
      if (select) {
        _selectedFolderIds = _cachedFolders
            .expand(
              (f) => [f.folder.id, if (f.folder.name.isNotEmpty) f.folder.name],
            )
            .toSet();
      } else {
        _selectedFolderIds.clear();
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'telecloud_backup_folder_ids',
      _selectedFolderIds.toList(),
    );
    ref.read(mediaScannerProvider).scanCameraRoll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final isOled = theme.scaffoldBackgroundColor == Colors.black;

    final bgColor = theme.scaffoldBackgroundColor;
    final cardBg = isLight
        ? AppColors.lightCard
        : (isOled ? const Color(0xFF121212) : AppColors.darkSurface);
    final cardBorder = isLight ? AppColors.lightBorder : AppColors.darkBorder;
    final primaryTextColor = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final secondaryTextColor = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.none,
        iconTheme: IconThemeData(color: primaryTextColor),
        title: Text(
          'Backup Folders',
          style: AppTypography.titleLarge(
            color: primaryTextColor,
          ).copyWith(fontWeight: AppTypography.bold),
        ),
        actions: [
          if (!_isLoading && _cachedFolders.isNotEmpty)
            TextButton(
              onPressed: () =>
                  _selectAll(_selectedFolderIds.length < _cachedFolders.length),
              child: Text(
                _selectedFolderIds.length < _cachedFolders.length
                    ? 'Select All'
                    : 'Deselect All',
                style: AppTypography.labelLarge(
                  color: AppColors.primaryBlue,
                ).copyWith(fontWeight: AppTypography.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : _cachedFolders.isEmpty
          ? Center(
              child: Text(
                'No media folders found on device',
                style: AppTypography.bodyMedium(color: secondaryTextColor),
              ),
            )
          : ListView.builder(
              padding: AppSpacing.screenPadding,
              itemCount: _cachedFolders.length,
              itemBuilder: (context, index) {
                final item = _cachedFolders[index];
                final folder = item.folder;
                final isChecked =
                    _selectedFolderIds.contains(folder.id) ||
                    _selectedFolderIds.contains(folder.name);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: AppRadii.borderL,
                    border: Border.all(color: cardBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isLight
                            ? Colors.grey.shade200
                            : Colors.grey.shade900,
                        borderRadius: AppRadii.borderM,
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadii.borderM,
                        child: _FolderThumbnail(
                          folder: folder,
                          fallbackColor: secondaryTextColor,
                        ),
                      ),
                    ),
                    title: Text(
                      folder.name.isNotEmpty
                          ? folder.name
                          : (folder.isAll ? 'All Media' : 'Camera / DCIM'),
                      style: AppTypography.labelLarge(
                        color: primaryTextColor,
                      ).copyWith(fontWeight: AppTypography.bold),
                    ),
                    subtitle: Text(
                      '${item.count} ${item.count == 1 ? 'item' : 'items'}',
                      style: AppTypography.labelSmall(
                        color: secondaryTextColor,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: isChecked,
                      activeTrackColor: AppColors.primaryBlue,
                      onChanged: (val) => _toggleFolder(folder, val),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
