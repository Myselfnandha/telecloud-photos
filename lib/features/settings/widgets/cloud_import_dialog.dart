import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';

class CloudImportDialog extends ConsumerStatefulWidget {
  const CloudImportDialog({super.key});

  @override
  ConsumerState<CloudImportDialog> createState() => _CloudImportDialogState();
}

class _CloudImportDialogState extends ConsumerState<CloudImportDialog> {
  bool _isSyncing = false;
  int _syncedCount = 0;
  String _statusText = 'Ready to sync with Telegram Cloud';

  Future<void> _startSync() async {
    setState(() {
      _isSyncing = true;
      _statusText = 'Scanning Telegram forum channel & topics...';
    });

    final syncService = ref.read(cloudSyncServiceProvider);
    final count = await syncService.rebuildTimelineFromCloud();

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _syncedCount = count;
        _statusText =
            'Sync complete! $count photos & videos indexed into timeline.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.cloud_sync_rounded,
              color: Color(0xFF0A84FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Rebuild from Cloud',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan your Telegram backup supergroup channel to restore the full photo & video timeline on this device.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (_isSyncing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0A84FF),
                    ),
                  )
                else
                  Icon(
                    _syncedCount > 0 ? Icons.check_circle : Icons.info_outline,
                    color: _syncedCount > 0
                        ? const Color(0xFF30D158)
                        : Colors.grey,
                    size: 20,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusText,
                    style: TextStyle(
                      color: _syncedCount > 0
                          ? const Color(0xFF30D158)
                          : Colors.grey.shade300,
                      fontSize: 13,
                      fontWeight: _syncedCount > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (!_isSyncing)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A84FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isSyncing ? null : _startSync,
          child: Text(
            _isSyncing
                ? 'Syncing...'
                : (_syncedCount > 0 ? 'Sync Again' : 'Start Cloud Sync'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
