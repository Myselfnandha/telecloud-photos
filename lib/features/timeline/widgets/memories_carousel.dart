import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

class MemoriesCarousel extends ConsumerStatefulWidget {
  const MemoriesCarousel({super.key});

  @override
  ConsumerState<MemoriesCarousel> createState() => _MemoriesCarouselState();
}

class _MemoriesCarouselState extends ConsumerState<MemoriesCarousel> {
  List<MediaItem> _memoryItems = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final mediaDao = ref.read(mediaDaoProvider);
    final now = DateTime.now();
    final memories = await mediaDao.getMemoriesForDate(now.month, now.day);
    if (mounted) {
      setState(() {
        _memoryItems = memories;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _memoryItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    // Group by year difference
    final Map<int, List<MediaItem>> yearGroups = {};
    for (final item in _memoryItems) {
      final yearsAgo = now.year - item.capturedAt.year;
      if (yearsAgo > 0) {
        yearGroups.putIfAbsent(yearsAgo, () => []).add(item);
      }
    }

    if (yearGroups.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 160,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final entry in yearGroups.entries)
            _buildMemoryCard(yearsAgo: entry.key, items: entry.value),
        ],
      ),
    );
  }

  Widget _buildMemoryCard({
    required int yearsAgo,
    required List<MediaItem> items,
  }) {
    final cover = items.first;
    final title = yearsAgo == 1
        ? '1 Year Ago Today'
        : '$yearsAgo Years Ago Today';

    return GestureDetector(
      onTap: () {
        context.push('/viewer/${cover.localId}');
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: AppRadii.borderXL,
          color: const Color(0xFF1C1C1E),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadii.borderXL,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cover.thumbnailPath != null &&
                  cover.thumbnailPath!.isNotEmpty)
                Image.file(
                  File(cover.thumbnailPath!),
                  fit: BoxFit.cover,
                  cacheWidth: 400,
                  cacheHeight: 300,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFF2C2C2E)),
                )
              else
                Container(color: const Color(0xFF2C2C2E)),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: AppSpacing.paddingM,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        borderRadius: AppRadii.borderS,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF00D2FF),
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'FLASHBACK',
                            style: TextStyle(
                              color: Color(0xFF00D2FF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.labelLarge(
                            color: Colors.white,
                          ).copyWith(fontWeight: AppTypography.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${items.length} ${items.length == 1 ? 'photo' : 'photos'}',
                          style: AppTypography.labelSmall(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
