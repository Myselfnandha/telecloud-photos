import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/storage_cleaner_service.dart';
import '../../../shared/theme/app_colors.dart';

class StorageCleanerScreen extends ConsumerStatefulWidget {
  const StorageCleanerScreen({super.key});

  @override
  ConsumerState<StorageCleanerScreen> createState() =>
      _StorageCleanerScreenState();
}

class _StorageCleanerScreenState extends ConsumerState<StorageCleanerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isLoading = true;
  StorageCleanSummary? _summary;
  bool _isCleaning = false;
  StorageCleanProgress _progress = const StorageCleanProgress();
  StorageCleanResult? _cleanResult;
  StreamSubscription<StorageCleanProgress>? _progressSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _loadSummary();

    final cleaner = ref.read(storageCleanerServiceProvider);
    _progressSub = cleaner.progressStream.listen((prog) {
      if (mounted) {
        setState(() {
          _progress = prog;
        });
      }
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final cleaner = ref.read(storageCleanerServiceProvider);
    final summary = await cleaner.getStorageSummary();
    if (mounted) {
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    }
  }

  Future<void> _startFreeUpSpace() async {
    if (_summary == null || !_summary!.hasReclaimableSpace || _isCleaning) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isCleaning = true;
      _cleanResult = null;
    });

    final cleaner = ref.read(storageCleanerServiceProvider);
    final result = await cleaner.freeUpSpace();

    if (mounted) {
      setState(() {
        _isCleaning = false;
        _cleanResult = result;
      });

      if (result.success && result.cleanedItemCount > 0) {
        HapticFeedback.heavyImpact();
      } else if (result.userCancelled) {
        HapticFeedback.lightImpact();
      }

      await _loadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor = AppColors.textPrimary(context);
    final secondaryTextColor = AppColors.textSecondary(context);
    final cardBg = isLight ? Colors.white : const Color(0xFF1C1C1E);
    final cardBorder = isLight ? const Color(0xFFE5E5EA) : const Color(0xFF2C2C2E);

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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Free Up Device Space',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              )
            : _cleanResult != null && _cleanResult!.success && _cleanResult!.cleanedItemCount > 0
                ? _buildCelebrationView(context, isLight, primaryTextColor, secondaryTextColor)
                : _isCleaning
                    ? _buildCleaningProgressView(context, isLight, primaryTextColor, secondaryTextColor)
                    : _buildMainOverview(context, isLight, primaryTextColor, secondaryTextColor, cardBg, cardBorder),
      ),
    );
  }

  Widget _buildMainOverview(
    BuildContext context,
    bool isLight,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color cardBg,
    Color cardBorder,
  ) {
    final hasReclaimable = _summary?.hasReclaimableSpace ?? false;
    final formattedSize = _summary?.formattedSize ?? '0 B';
    final totalItems = _summary?.totalItems ?? 0;
    final photoCount = _summary?.photoCount ?? 0;
    final videoCount = _summary?.videoCount ?? 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Central Storage Gauge Card
          ScaleTransition(
            scale: hasReclaimable ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: hasReclaimable
                      ? [
                          AppColors.primaryBlue.withValues(alpha: 0.18),
                          AppColors.primaryBlue.withValues(alpha: 0.04),
                        ]
                      : [
                          Colors.grey.withValues(alpha: 0.12),
                          Colors.grey.withValues(alpha: 0.02),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: hasReclaimable
                      ? AppColors.primaryBlue.withValues(alpha: 0.4)
                      : cardBorder,
                  width: 3,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasReclaimable
                          ? Icons.cleaning_services_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 40,
                      color: hasReclaimable
                          ? AppColors.primaryBlue
                          : AppColors.systemGreen,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasReclaimable ? formattedSize : 'Clean',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: hasReclaimable ? 26 : 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      hasReclaimable ? 'Reclaimable' : 'All Optimized',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Headline text
          Text(
            hasReclaimable
                ? 'Ready to Free Up Device Space'
                : 'Your Device Storage is Clean',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              hasReclaimable
                  ? 'All $totalItems items have been securely backed up in original quality to Telegram Cloud. You can safely delete local copies to reclaim device space.'
                  : 'All backed-up media has already been optimized. Cached thumbnails remain on device for lightning-fast browsing.',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Breakdown Chips Card
          if (hasReclaimable) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildBreakdownItem(
                      icon: Icons.photo_library_rounded,
                      iconColor: AppColors.primaryBlue,
                      title: 'Photos',
                      subtitle: '$photoCount items',
                      primaryColor: primaryTextColor,
                      secondaryColor: secondaryTextColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: cardBorder,
                  ),
                  Expanded(
                    child: _buildBreakdownItem(
                      icon: Icons.videocam_rounded,
                      iconColor: const Color(0xFFFF9F0A),
                      title: 'Videos',
                      subtitle: '$videoCount items',
                      primaryColor: primaryTextColor,
                      secondaryColor: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Safety Guarantee Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasReclaimable
                  ? AppColors.primaryBlue.withValues(alpha: 0.08)
                  : AppColors.systemGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasReclaimable
                    ? AppColors.primaryBlue.withValues(alpha: 0.25)
                    : AppColors.systemGreen.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: hasReclaimable
                      ? AppColors.primaryBlue
                      : AppColors.systemGreen,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Telegram Cloud Guaranteed',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uncompressed full originals and EXIF tags are stored in your private Telegram channel. Offline thumbnails remain cached on device.',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Primary Clean Button
          if (hasReclaimable)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.delete_sweep_rounded, size: 22),
                label: Text(
                  'Free Up $formattedSize',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _startFreeUpSpace,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'Refresh Storage Status',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _loadSummary,
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCleaningProgressView(
    BuildContext context,
    bool isLight,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final stageName = switch (_progress.stage) {
      CleanStage.cachingThumbnails => 'Caching High-Res Thumbnails...',
      CleanStage.deletingLocalFiles => 'Deleting Local Copies via MediaStore...',
      CleanStage.updatingDatabase => 'Updating Library Index...',
      _ => 'Reclaiming device space...',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              stageName,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _progress.currentFileName.isNotEmpty
                  ? _progress.currentFileName
                  : 'Processing items...',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress.progressPercentage > 0
                    ? _progress.progressPercentage
                    : null,
                minHeight: 8,
                backgroundColor: isLight ? Colors.grey.shade200 : const Color(0xFF2C2C2E),
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_progress.processedItems} of ${_progress.totalItems} items',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${(_progress.progressPercentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationView(
    BuildContext context,
    bool isLight,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final reclaimed = _cleanResult?.formattedReclaimed ?? '0 B';
    final count = _cleanResult?.cleanedItemCount ?? 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.systemGreen.withValues(alpha: 0.25),
                    AppColors.systemGreen.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.systemGreen,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.celebration_rounded,
                size: 52,
                color: AppColors.systemGreen,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '🎉 $reclaimed Freed!',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Successfully removed $count backed-up items from your device. All photos remain accessible via cached thumbnails and on-demand cloud streaming.',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.systemGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.photo_library_rounded, size: 20),
                label: const Text(
                  'Back to Timeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  context.go('/timeline');
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _cleanResult = null;
                });
                _loadSummary();
              },
              child: Text(
                'Storage Overview',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
