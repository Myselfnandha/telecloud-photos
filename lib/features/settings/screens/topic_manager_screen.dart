import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

class TopicManagerScreen extends ConsumerStatefulWidget {
  const TopicManagerScreen({super.key});

  @override
  ConsumerState<TopicManagerScreen> createState() => _TopicManagerScreenState();
}

class _TopicManagerScreenState extends ConsumerState<TopicManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AssetPathEntity> _deviceFolders = [];
  bool _loadingFolders = true;

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
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: false,
      );
      if (mounted) {
        setState(() {
          _deviceFolders = paths;
          _loadingFolders = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingFolders = false);
      }
    }
  }

  void _showCreateTopicDialog() {
    final titleController = TextEditingController();
    int selectedColor = 0x6FB9F0;
    final colors = [
      0x6FB9F0, // Blue
      0xFFD67E, // Gold
      0xCB86DB, // Purple
      0x8EEE98, // Green
      0xFF93B2, // Pink
      0xFB6F5F, // Red
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'New Forum Topic',
            style: AppTypography.titleMedium(
              color: AppColors.darkTextPrimary,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Topic Name',
                style: AppTypography.labelSmall(
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Vacation 2026, Screenshots',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Icon Color',
                style: AppTypography.labelSmall(
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: colors.map((c) {
                  final isSelected = selectedColor == c;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(0xFF000000 | c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.darkTextSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final name = titleController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(dialogCtx);
                  final channelMgr = ref.read(channelManagerProvider);
                  final newId = await channelMgr.createCustomTopic(
                    name,
                    iconColor: selectedColor,
                  );
                  if (mounted) {
                    ref.invalidate(supergroupTopicsProvider);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newId != null
                              ? 'Topic "$name" created in Telegram Supergroup!'
                              : 'Failed to create topic',
                        ),
                        backgroundColor: newId != null
                            ? const Color(0xFF30D158)
                            : Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Create',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTopicDialog(td.ForumTopic topic) {
    final titleController = TextEditingController(text: topic.info.name);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Rename Topic',
          style: AppTypography.titleMedium(
            color: AppColors.darkTextPrimary,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Topic Name',
            filled: true,
            fillColor: AppColors.darkCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.darkTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final newName = titleController.text.trim();
              if (newName.isNotEmpty && newName != topic.info.name) {
                Navigator.pop(dialogCtx);
                final channelMgr = ref.read(channelManagerProvider);
                final ok = await channelMgr.editCustomTopic(
                  topic.info.messageThreadId,
                  newTitle: newName,
                );
                if (mounted) {
                  ref.invalidate(supergroupTopicsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Topic renamed to "$newName"'
                            : 'Failed to rename topic',
                      ),
                      backgroundColor: ok
                          ? const Color(0xFF30D158)
                          : Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTopic(td.ForumTopic topic) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Topic "${topic.info.name}"?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This will close and remove this forum topic from your Telegram Supergroup. Photos already backed up remain safe.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final channelMgr = ref.read(channelManagerProvider);
              final ok = await channelMgr.deleteCustomTopic(
                topic.info.messageThreadId,
              );
              if (mounted) {
                ref.invalidate(supergroupTopicsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Topic deleted from Supergroup'
                          : 'Failed to delete topic',
                    ),
                    backgroundColor: ok
                        ? const Color(0xFF30D158)
                        : Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(supergroupTopicsProvider);
    final mappingsAsync = ref.watch(folderTopicMappingsProvider);
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
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryTextColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Supergroup Topics',
          style: AppTypography.titleLarge(
            color: primaryTextColor,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primaryBlue,
              size: 26,
            ),
            tooltip: 'New Topic',
            onPressed: _showCreateTopicDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: secondaryTextColor,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              text: 'Forum Topics',
              icon: Icon(Icons.forum_rounded, size: 18),
            ),
            Tab(
              text: 'Folder Mappings',
              icon: Icon(Icons.alt_route_rounded, size: 18),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Live Supergroup Topics
          _buildTopicsTab(
            topicsAsync: topicsAsync,
            cardBg: cardBg,
            cardBorder: cardBorder,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),

          // TAB 2: Folder to Topic Mapping Selector
          _buildFolderMappingsTab(
            topicsAsync: topicsAsync,
            mappingsAsync: mappingsAsync,
            cardBg: cardBg,
            cardBorder: cardBorder,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            isLight: isLight,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Create Topic',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _showCreateTopicDialog,
      ),
    );
  }

  Widget _buildTopicsTab({
    required AsyncValue<List<td.ForumTopic>> topicsAsync,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return topicsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
      error: (err, _) => Center(
        child: Text(
          'Error loading topics: $err',
          style: TextStyle(color: secondaryTextColor),
        ),
      ),
      data: (topics) {
        if (topics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 64,
                  color: secondaryTextColor.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Forum Topics Found',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap "Create Topic" below to create one.',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(supergroupTopicsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: topics.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final topic = topics[index];
              final info = topic.info;
              final iconColor = info.icon.color != 0
                  ? Color(0xFF000000 | info.icon.color)
                  : AppColors.primaryBlue;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tag_rounded,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  info.name,
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (info.isClosed) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Closed',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Thread ID: ${info.messageThreadId} • ${topic.unreadCount} unread',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: secondaryTextColor,
                        size: 20,
                      ),
                      onSelected: (action) {
                        if (action == 'rename') {
                          _showEditTopicDialog(topic);
                        } else if (action == 'delete') {
                          _confirmDeleteTopic(topic);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Rename Topic'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete Topic',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFolderMappingsTab({
    required AsyncValue<List<td.ForumTopic>> topicsAsync,
    required AsyncValue<Map<String, int>> mappingsAsync,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required bool isLight,
  }) {
    if (_loadingFolders) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    final topics = topicsAsync.value ?? [];
    final mappings = mappingsAsync.value ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Map local camera roll or device albums to dedicated Telegram Supergroup topics for structured cloud backups.',
                  style: TextStyle(color: primaryTextColor, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_deviceFolders.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Text(
              'No device folders indexed.',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
        ] else ...[
          ..._deviceFolders.map((folder) {
            final rawName = folder.name.trim();
            final folderName = rawName.isEmpty ? 'Main Storage' : rawName;
            final mappedTopicId = mappings[folderName.toLowerCase()] ?? mappings[folder.name.toLowerCase()];

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF30D158).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Color(0xFF30D158),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          folderName,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: mappedTopicId != null
                              ? AppColors.primaryBlue.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          mappedTopicId != null ? 'Custom Topic' : 'Auto Topic',
                          style: TextStyle(
                            color: mappedTopicId != null
                                ? AppColors.primaryBlue
                                : secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'TARGET SUPERGROUP TOPIC',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF2F2F7) : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: mappedTopicId,
                        isExpanded: true,
                        dropdownColor: isLight ? Colors.white : AppColors.darkCard,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: secondaryTextColor,
                        ),
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: AppColors.primaryBlue.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Auto Topic ("$folderName")',
                                    style: TextStyle(color: secondaryTextColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...topics.map(
                            (t) => DropdownMenuItem<int?>(
                              value: t.info.messageThreadId,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.tag_rounded,
                                    size: 16,
                                    color: Color(0xFF30D158),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${t.info.name} (#${t.info.messageThreadId})',
                                      style: TextStyle(color: primaryTextColor),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) async {
                          final channelMgr = ref.read(channelManagerProvider);
                          if (val == null) {
                            await channelMgr.removeFolderTopicMapping(folderName);
                            if (folder.name.isNotEmpty && folder.name != folderName) {
                              await channelMgr.removeFolderTopicMapping(folder.name);
                            }
                          } else {
                            await channelMgr.setFolderTopicMapping(folderName, val);
                            if (folder.name.isNotEmpty && folder.name != folderName) {
                              await channelMgr.setFolderTopicMapping(folder.name, val);
                            }
                          }
                          ref.invalidate(folderTopicMappingsProvider);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
