import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/telegram/channel_manager.dart';

/// Modal sheet for selecting among duplicate or existing TeleCloud storage groups
/// and inspecting the forum topics inside each group.
class TeleCloudGroupSelectorSheet extends ConsumerStatefulWidget {
  final List<TeleCloudGroupSummary>? preloadedGroups;
  final bool isInitialSetup;

  const TeleCloudGroupSelectorSheet({
    super.key,
    this.preloadedGroups,
    this.isInitialSetup = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    List<TeleCloudGroupSummary>? preloadedGroups,
    bool isInitialSetup = false,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TeleCloudGroupSelectorSheet(
        preloadedGroups: preloadedGroups,
        isInitialSetup: isInitialSetup,
      ),
    );
  }

  @override
  ConsumerState<TeleCloudGroupSelectorSheet> createState() =>
      _TeleCloudGroupSelectorSheetState();
}

class _TeleCloudGroupSelectorSheetState
    extends ConsumerState<TeleCloudGroupSelectorSheet> {
  late Future<List<TeleCloudGroupSummary>> _groupsFuture;
  bool _isCreatingNew = false;
  int? _switchingChatId;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedGroups != null && widget.preloadedGroups!.isNotEmpty) {
      _groupsFuture = Future.value(widget.preloadedGroups);
    } else {
      _groupsFuture = ref.read(channelManagerProvider).getAvailableSupergroups();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _groupsFuture = ref.read(channelManagerProvider).getAvailableSupergroups();
    });
  }

  Future<void> _handleSelectGroup(TeleCloudGroupSummary summary) async {
    if (_switchingChatId != null || _isCreatingNew) return;

    setState(() => _switchingChatId = summary.id);
    HapticFeedback.mediumImpact();

    final channelMgr = ref.read(channelManagerProvider);
    final mediaDao = ref.read(mediaDaoProvider);

    final ok = await channelMgr.switchStorageChannel(
      summary.id,
      mediaDao: mediaDao,
    );

    if (mounted) {
      setState(() => _switchingChatId = null);
      if (ok) {
        ref.invalidate(supergroupTopicsProvider);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Active storage set to "${summary.title}"',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF30D158),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleCreateNewGroup() async {
    if (_isCreatingNew || _switchingChatId != null) return;

    setState(() => _isCreatingNew = true);
    HapticFeedback.mediumImpact();

    final channelMgr = ref.read(channelManagerProvider);
    final mediaDao = ref.read(mediaDaoProvider);

    final newChatId = await channelMgr.createNewBackupChannel();

    if (mounted) {
      setState(() => _isCreatingNew = false);
      if (newChatId != null) {
        await channelMgr.switchStorageChannel(newChatId, mediaDao: mediaDao);
        ref.invalidate(supergroupTopicsProvider);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Created fresh TeleCloud Storage Supergroup!',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF0A84FF),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create new supergroup. Please try again.'),
            backgroundColor: Color(0xFFFF453A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentActiveId = ref.watch(channelManagerProvider).channelId;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161618),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: Color(0xFF0A84FF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TeleCloud Storage Groups',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.isInitialSetup
                              ? 'Multiple duplicate storage groups found. Pick one to use:'
                              : 'Select which TeleCloud group to use for cloud backup:',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFF2C2C2E)),

            // Groups list
            Flexible(
              child: FutureBuilder<List<TeleCloudGroupSummary>>(
                future: _groupsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0A84FF),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFFF453A),
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load storage groups: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _refresh,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C2C2E),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final groups = snapshot.data ?? [];
                  if (groups.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            color: Colors.grey.shade600,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No TeleCloud Groups Found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No existing TeleCloud storage groups were detected on this Telegram account.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final summary = groups[index];
                      final isSelected = summary.id == currentActiveId;
                      final isSwitching = summary.id == _switchingChatId;

                      return _GroupSummaryCard(
                        summary: summary,
                        isSelected: isSelected,
                        isSwitching: isSwitching,
                        onTap: () => _handleSelectGroup(summary),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E),
                border: Border(
                  top: BorderSide(color: Color(0xFF2C2C2E), width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCreatingNew ? null : _handleCreateNewGroup,
                  icon: _isCreatingNew
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0A84FF),
                          ),
                        )
                      : const Icon(Icons.add_rounded, color: Color(0xFF0A84FF)),
                  label: Text(
                    _isCreatingNew
                        ? 'Creating Storage Supergroup...'
                        : '+ Create Fresh Storage Group',
                    style: const TextStyle(
                      color: Color(0xFF0A84FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF0A84FF), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSummaryCard extends StatefulWidget {
  final TeleCloudGroupSummary summary;
  final bool isSelected;
  final bool isSwitching;
  final VoidCallback onTap;

  const _GroupSummaryCard({
    required this.summary,
    required this.isSelected,
    required this.isSwitching,
    required this.onTap,
  });

  @override
  State<_GroupSummaryCard> createState() => _GroupSummaryCardState();
}

class _GroupSummaryCardState extends State<_GroupSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final isSelected = widget.isSelected;
    final topics = summary.topics;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF0A84FF).withValues(alpha: 0.12)
            : const Color(0xFF242426),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF0A84FF)
              : const Color(0xFF333336),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.isSwitching ? null : widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0A84FF)
                            : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.forum_rounded,
                        color: isSelected ? Colors.white : Colors.white70,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  summary.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF30D158),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Chat ID: ${summary.id} • ${summary.totalTopics} ${summary.totalTopics == 1 ? 'Topic' : 'Topics'}',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isSwitching)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0A84FF),
                        ),
                      )
                    else if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF0A84FF),
                        size: 22,
                      )
                    else
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() => _isExpanded = !_isExpanded);
                        },
                      ),
                  ],
                ),

                // Topics list preview
                if (topics.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFF333336)),
                  const SizedBox(height: 8),

                  // Topic Chips Preview
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (_isExpanded || isSelected
                            ? topics
                            : topics.take(3).toList())
                        .map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0A84FF).withValues(alpha: 0.3)
                                : const Color(0xFF3A3A3C),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '#',
                              style: TextStyle(
                                color: Color(0xFF0A84FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.info.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (t.unreadCount > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A84FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${t.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  if (topics.length > 3 && !_isExpanded && !isSelected) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = true),
                      child: Text(
                        '+ ${topics.length - 3} more topics',
                        style: const TextStyle(
                          color: Color(0xFF0A84FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
