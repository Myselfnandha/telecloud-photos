import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_elevation.dart';
import '../../../shared/theme/app_icons.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _restoreSelected() async {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.lightImpact();
    final mediaDao = ref.read(mediaDaoProvider);
    final count = await mediaDao.restoreFromTrash(_selectedIds.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count items restored to timeline'),
          backgroundColor: AppColors.systemGreen,
        ),
      );
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _purgeSelected(List<MediaItem> allTrashItems) async {
    final idsToPurge = _selectedIds.isEmpty
        ? allTrashItems.map((e) => e.localId).toList()
        : _selectedIds.toList();

    if (idsToPurge.isEmpty) return;

    final isLight = Theme.of(context).brightness == Brightness.light;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isLight ? AppColors.lightCard : AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderXL),
        title: Text(
          'Delete Forever?',
          style: AppTypography.titleLarge(
            color: isLight
                ? AppColors.lightTextPrimary
                : AppColors.darkTextPrimary,
          ).copyWith(fontWeight: AppTypography.bold),
        ),
        content: Text(
          'This will permanently delete ${idsToPurge.length} items from Telegram Cloud and your device. This action cannot be undone.',
          style: AppTypography.bodyMedium(
            color: isLight
                ? AppColors.lightTextSecondary
                : AppColors.darkTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge(
                color: isLight ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.systemRed,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.borderM),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete Forever',
              style: AppTypography.labelLarge(
                color: Colors.white,
              ).copyWith(fontWeight: AppTypography.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      final mediaDao = ref.read(mediaDaoProvider);
      final client = ref.read(tdlibClientProvider);
      final channelMgr = ref.read(channelManagerProvider);

      // Collect Telegram msg IDs for cloud deletion
      final channelId = channelMgr.channelId;
      final msgIds = <int>[];
      for (final item in allTrashItems) {
        if (idsToPurge.contains(item.localId) && item.telegramMsgId != null) {
          msgIds.add(item.telegramMsgId!);
        }
      }

      if (channelId != null && msgIds.isNotEmpty) {
        client.send(
          td.DeleteMessages(
            chatId: channelId,
            messageIds: msgIds,
            revoke: true,
          ),
        );
      }

      await mediaDao.purgeTrashItems(idsToPurge);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${idsToPurge.length} items permanently deleted'),
            backgroundColor: AppColors.systemRed,
          ),
        );
        setState(() {
          _selectedIds.clear();
          _isSelectionMode = false;
        });
      }
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
          _isSelectionMode ? '${_selectedIds.length} Selected' : 'Trash',
          style: AppTypography.titleLarge(
            color: primaryTextColor,
          ).copyWith(fontWeight: AppTypography.bold),
        ),
        actions: [
          if (_isSelectionMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                });
              },
              child: Text(
                'Cancel',
                style: AppTypography.labelLarge(color: AppColors.primaryBlue),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<MediaItem>>(
        stream: mediaDao.watchTrash(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: AppSpacing.paddingXL,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 54,
                        color: secondaryTextColor,
                      ),
                    ),
                    AppSpacing.gapVerticalL,
                    Text(
                      'Trash is Empty',
                      style: AppTypography.headlineSmall(
                        color: primaryTextColor,
                      ).copyWith(fontWeight: AppTypography.bold),
                    ),
                    AppSpacing.gapVerticalS,
                    Text(
                      'Items moved to trash will stay here for 30 days',
                      style: AppTypography.bodyMedium(
                        color: secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: isLight ? AppColors.lightCard : const Color(0xFF161618),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: secondaryTextColor,
                      size: AppIcons.s,
                    ),
                    AppSpacing.gapHorizontalS,
                    Expanded(
                      child: Text(
                        'Items in trash are automatically purged after 30 days',
                        style: AppTypography.labelSmall(
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedIds.contains(item.localId);
                    final trashedDays = item.trashedAt != null
                        ? 30 - DateTime.now().difference(item.trashedAt!).inDays
                        : 30;

                    return GestureDetector(
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(item.localId);
                        } else {
                          _toggleSelection(item.localId);
                        }
                      },
                      onLongPress: () => _toggleSelection(item.localId),
                      child: ClipRRect(
                        borderRadius: AppRadii.borderS,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: const Color(0xFF1C1C1E),
                              child:
                                  item.thumbnailPath != null &&
                                      item.thumbnailPath!.isNotEmpty
                                  ? Image.file(
                                      File(item.thumbnailPath!),
                                      fit: BoxFit.cover,
                                      cacheWidth: 256,
                                      cacheHeight: 256,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.image,
                                                  color: Colors.white24,
                                                  size: 28,
                                                ),
                                              ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.white24,
                                        size: 28,
                                      ),
                                    ),
                            ),
                            if (isSelected)
                              Container(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.4,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${trashedDays}d left',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: AppSpacing.screenPadding,
                decoration: BoxDecoration(
                  color: isLight
                      ? AppColors.lightCard
                      : const Color(0xFF161618),
                  border: Border(top: BorderSide(color: cardBorder)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.systemGreen,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadii.borderM,
                            ),
                          ),
                          icon: const Icon(
                            Icons.restore,
                            color: AppColors.systemGreen,
                            size: AppIcons.m,
                          ),
                          label: Text(
                            _isSelectionMode
                                ? 'Restore (${_selectedIds.length})'
                                : 'Restore All',
                            style: AppTypography.labelLarge(
                              color: AppColors.systemGreen,
                            ).copyWith(fontWeight: AppTypography.bold),
                          ),
                          onPressed: _isSelectionMode
                              ? _restoreSelected
                              : () async {
                                  final allIds = items
                                      .map((e) => e.localId)
                                      .toList();
                                  await mediaDao.restoreFromTrash(allIds);
                                },
                        ),
                      ),
                      AppSpacing.gapHorizontalM,
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.systemRed,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadii.borderM,
                            ),
                          ),
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.white,
                            size: AppIcons.m,
                          ),
                          label: Text(
                            _isSelectionMode
                                ? 'Delete (${_selectedIds.length})'
                                : 'Empty Trash',
                            style: AppTypography.labelLarge(
                              color: Colors.white,
                            ).copyWith(fontWeight: AppTypography.bold),
                          ),
                          onPressed: () => _purgeSelected(items),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
