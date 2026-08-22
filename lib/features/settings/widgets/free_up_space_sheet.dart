import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/storage/storage_cleanup_service.dart';

class FreeUpSpaceSheet extends ConsumerStatefulWidget {
  const FreeUpSpaceSheet({super.key});

  @override
  ConsumerState<FreeUpSpaceSheet> createState() => _FreeUpSpaceSheetState();
}

class _FreeUpSpaceSheetState extends ConsumerState<FreeUpSpaceSheet> {
  bool _isLoading = true;
  bool _isCleaning = false;
  ReclaimableStorageInfo? _info;
  int _processed = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() => _isLoading = true);
    final cleanupService = ref.read(storageCleanupServiceProvider);
    final info = await cleanupService.calculateReclaimableSpace();
    if (mounted) {
      setState(() {
        _info = info;
        _isLoading = false;
      });
    }
  }

  Future<void> _startCleanup() async {
    if (_info == null || _info!.items.isEmpty) return;

    setState(() {
      _isCleaning = true;
      _processed = 0;
      _total = _info!.items.length;
    });

    final cleanupService = ref.read(storageCleanupServiceProvider);
    final cleaned = await cleanupService.freeUpDeviceSpace(
      itemsToClean: _info!.items,
      onProgress: (p, t) {
        if (mounted) {
          setState(() {
            _processed = p;
            _total = t;
          });
        }
      },
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Freed up ${_info!.formattedSize} ($cleaned photos cleaned)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF30D158),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: _isLoading
            ? const SizedBox(
                height: 250,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF0A84FF)),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing backed up media...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0A84FF,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.cleaning_services_rounded,
                          color: Color(0xFF0A84FF),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Free Up Device Space',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _info != null && _info!.totalCount > 0
                                  ? '${_info!.totalCount} items backed up to Telegram'
                                  : 'Everything is clean',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_info != null && _info!.totalCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Reclaimable Space',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _info!.formattedSize,
                                style: const TextStyle(
                                  color: Color(0xFF30D158),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 12),
                          _benefitRow(
                            Icons.cloud_done,
                            'All photos remain safely backed up in Telegram Cloud',
                          ),
                          const SizedBox(height: 8),
                          _benefitRow(
                            Icons.photo_library_outlined,
                            'Fast offline thumbnails stay visible in your gallery',
                          ),
                          const SizedBox(height: 8),
                          _benefitRow(
                            Icons.download,
                            'Original high-res copies stream on-demand when viewed',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isCleaning) ...[
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: _total > 0 ? _processed / _total : 0,
                            backgroundColor: Colors.grey.shade800,
                            color: const Color(0xFF0A84FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Freeing space: $_processed / $_total',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A84FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _startCleanup,
                          child: Text(
                            'Free Up ${_info!.formattedSize}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF30D158),
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'No space to free up right now. Backup pending photos to reclaim storage.',
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0A84FF)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
