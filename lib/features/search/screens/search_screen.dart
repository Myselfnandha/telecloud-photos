import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/skeleton_layouts.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_elevation.dart';
import '../../../shared/theme/app_icons.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  final List<String> _quickFilters = [
    'Videos',
    'Screenshots',
    'Camera',
    'IMG',
    '2024',
    '2025',
    '2026',
  ];

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = query.trim();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
        title: TextField(
          controller: _searchController,
          autofocus: false,
          style: AppTypography.bodyMedium(color: primaryTextColor),
          cursorColor: AppColors.primaryBlue,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search photos, dates, formats...',
            hintStyle: AppTypography.bodyMedium(color: secondaryTextColor),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: secondaryTextColor,
              size: AppIcons.m,
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: secondaryTextColor,
                      size: AppIcons.s,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _quickFilters.map((filter) {
                final isSelected = _query.toLowerCase() == filter.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style:
                          AppTypography.labelSmall(
                            color: isSelected ? Colors.white : primaryTextColor,
                          ).copyWith(
                            fontWeight: isSelected
                                ? AppTypography.bold
                                : FontWeight.normal,
                          ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected) {
                          _query = filter;
                          _searchController.text = filter;
                        } else {
                          _query = '';
                          _searchController.clear();
                        }
                      });
                    },
                    backgroundColor: cardBg,
                    selectedColor: AppColors.primaryBlue,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryBlue : cardBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.borderXL,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Search results Grid
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 64,
                          color: secondaryTextColor,
                        ),
                        AppSpacing.gapVerticalM,
                        Text(
                          'Search your photos and videos',
                          style: AppTypography.bodyMedium(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<List<MediaItem>>(
                    stream: mediaDao.searchMedia(_query),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SearchResultsSkeleton();
                      }

                      final results = snapshot.data ?? [];
                      if (results.isEmpty) {
                        return Center(
                          child: Text(
                            'No items matching "$_query"',
                            style: AppTypography.bodyMedium(
                              color: secondaryTextColor,
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(4),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 3,
                              mainAxisSpacing: 3,
                            ),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return _SearchTile(
                            key: ValueKey(item.localId),
                            item: item,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchTile extends StatefulWidget {
  final MediaItem item;

  const _SearchTile({super.key, required this.item});

  @override
  State<_SearchTile> createState() => _SearchTileState();
}

class _SearchTileState extends State<_SearchTile>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _bytes;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final cached = ThumbnailCacheService().getFromMemory(widget.item.localId);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _bytes = cached;
        });
      }
      return;
    }

    final bytes = await ThumbnailCacheService().getThumbnail(
      id: widget.item.localId,
      diskPath: widget.item.thumbnailPath,
      isVideo: widget.item.mimeType.startsWith('video'),
    );

    if (mounted) {
      setState(() {
        _bytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final thumbPath = widget.item.thumbnailPath;
    final hasValidDiskThumb =
        thumbPath != null &&
        thumbPath.isNotEmpty &&
        File(thumbPath).existsSync();

    return GestureDetector(
      onTap: () => context.push('/viewer/${widget.item.localId}'),
      child: Hero(
        tag: 'media_${widget.item.localId}',
        child: ClipRRect(
          borderRadius: AppRadii.borderS,
          child: Container(
            color: const Color(0xFF141416),
            child: _bytes != null
                ? Image.memory(
                    _bytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ShimmerLoading(),
                  )
                : (hasValidDiskThumb
                      ? Image.file(
                          File(thumbPath),
                          fit: BoxFit.cover,
                          cacheWidth: 256,
                          cacheHeight: 256,
                          errorBuilder: (context, error, stackTrace) =>
                              const ShimmerLoading(),
                        )
                      : const ShimmerLoading()),
          ),
        ),
      ),
    );
  }
}
