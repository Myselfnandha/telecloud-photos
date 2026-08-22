import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/google/google_auth_service.dart';
import '../../../core/google/google_photos_api_client.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/theme_provider.dart';

class GooglePhotosHubScreen extends ConsumerStatefulWidget {
  const GooglePhotosHubScreen({super.key});

  @override
  ConsumerState<GooglePhotosHubScreen> createState() =>
      _GooglePhotosHubScreenState();
}

class _GooglePhotosHubScreenState extends ConsumerState<GooglePhotosHubScreen> {
  String _selectedScope =
      'all'; // 'all', '30days', '90days', '1year', 'custom', 'albums', 'favorites'
  DateTimeRange? _customDateRange;
  List<GooglePhotosAlbum> _albums = [];
  bool _isLoadingAlbums = false;
  GooglePhotosAlbum? _selectedAlbum;
  String _mediaTypeFilter = 'all'; // 'all', 'photos', 'videos'
  bool _incrementalDeltaSync = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAlbums();
    });
  }

  Future<void> _fetchAlbums() async {
    setState(() => _isLoadingAlbums = true);
    final client = ref.read(googlePhotosApiClientProvider);
    final albums = await client.listAlbums();
    if (mounted) {
      setState(() {
        _albums = albums;
        if (_albums.isNotEmpty && _selectedAlbum == null) {
          _selectedAlbum = _albums.first;
        }
        _isLoadingAlbums = false;
      });
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = Theme.of(context);

    final bg = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E);
    final textColor = isLight ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final subtextColor = isLight ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    const primaryColor = Color(0xFF0A84FF);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange:
          _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            scaffoldBackgroundColor: bg,
            colorScheme: isLight
                ? const ColorScheme.light(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF000000),
                    surfaceContainerHighest: Color(0xFFF2F2F7),
                    secondary: primaryColor,
                    onSecondary: Colors.white,
                  )
                : const ColorScheme.dark(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1C1C1E),
                    onSurface: Colors.white,
                    surfaceContainerHighest: Color(0xFF2C2C2E),
                    secondary: primaryColor,
                    onSecondary: Colors.white,
                  ),
            appBarTheme: AppBarTheme(
              backgroundColor: bg,
              foregroundColor: textColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: primaryColor),
              actionsIconTheme: const IconThemeData(color: primaryColor),
              titleTextStyle: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: bg,
              elevation: 0,
              headerBackgroundColor: bg,
              headerForegroundColor: textColor,
              headerHeadlineStyle: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              headerHelpStyle: TextStyle(
                color: subtextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              weekdayStyle: TextStyle(
                color: subtextColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              dayStyle: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return subtextColor.withValues(alpha: 0.3);
                }
                return textColor;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryColor;
                }
                return null;
              }),
              rangePickerBackgroundColor: bg,
              rangePickerElevation: 0,
              rangePickerHeaderBackgroundColor: bg,
              rangePickerHeaderForegroundColor: textColor,
              rangePickerHeaderHeadlineStyle: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              rangePickerHeaderHelpStyle: TextStyle(
                color: subtextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              rangeSelectionBackgroundColor: primaryColor.withValues(alpha: 0.2),
              rangeSelectionOverlayColor: WidgetStatePropertyAll(
                primaryColor.withValues(alpha: 0.1),
              ),
              todayForegroundColor: const WidgetStatePropertyAll(primaryColor),
              todayBorder: const BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedScope = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isOLED = themeMode == AppThemeMode.pureBlack;

    final cardBg = isLight
        ? Colors.white
        : isOLED
        ? const Color(0xFF0A0A0C)
        : const Color(0xFF1C1C1E);
    final cardBorder = isLight
        ? const Color(0xFFE5E5EA)
        : isOLED
        ? const Color(0xFF222226)
        : Colors.white.withValues(alpha: 0.08);
    final primaryTextColor = isLight ? const Color(0xFF000000) : Colors.white;
    final secondaryTextColor = isLight
        ? const Color(0xFF8E8E93)
        : Colors.grey.shade400;

    final authService = ref.watch(googleAuthServiceProvider);
    final syncService = ref.watch(googlePhotosSyncServiceProvider);
    final telemetry = syncService.telemetry;
    final profile = authService.currentProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Google Photos Import Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'View Synced Media',
            icon: const Icon(
              Icons.collections_rounded,
              color: Color(0xFF4285F4),
            ),
            onPressed: () => context.push('/google-photos/synced'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Google Account Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: authService.isSignedIn && profile != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child:
                                profile.photoUrl != null &&
                                    profile.photoUrl!.isNotEmpty
                                ? Image.network(
                                    profile.photoUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildAvatarFallback(profile),
                                  )
                                : _buildAvatarFallback(profile),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile.displayName,
                                        style: TextStyle(
                                          color: primaryTextColor,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF34A853,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF34A853,
                                          ).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 12,
                                            color: Color(0xFF34A853),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Connected',
                                            style: TextStyle(
                                              color: Color(0xFF34A853),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.email,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: isLight
                            ? Colors.grey.shade200
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zero-Disk Streaming',
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Directly into Telegram Cloud storage',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text(
                                    'Disconnect Google Account?',
                                  ),
                                  content: const Text(
                                    'This will sign out of Google Photos. Your backed up photos in Telegram Cloud remain safe.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Disconnect',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await authService.signOut();
                              }
                            },
                            icon: const Icon(
                              Icons.link_off_rounded,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Disconnect',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF4285F4,
                          ).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_download_rounded,
                          color: Color(0xFF4285F4),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Direct Google Photos Sync',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in with your Google Account to import photos directly into your Telegram Cloud with unlimited backup space.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: authService.isLoading
                              ? null
                              : () async {
                                  HapticFeedback.lightImpact();
                                  final success = await authService.signIn();
                                  if (success) {
                                    _fetchAlbums();
                                  }
                                },
                          icon: authService.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login_rounded, size: 20),
                          label: Text(
                            authService.isLoading
                                ? 'Signing In...'
                                : 'Sign in with Google Account',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 20),

          // 2. Live Sync Telemetry Card
          if (telemetry.isSyncing || telemetry.importedCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isLight
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          telemetry.isSyncing
                              ? Icons.sync_rounded
                              : Icons.check_circle_rounded,
                          color: const Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              telemetry.isSyncing
                                  ? 'Transferring from Google Photos...'
                                  : 'Import Complete',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              telemetry.statusMessage,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (telemetry.isSyncing)
                        IconButton(
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            syncService.cancelSync();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: telemetry.isSyncing
                          ? telemetry.currentProgress
                          : 1.0,
                      minHeight: 6,
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Imported: ${telemetry.importedCount} items',
                        style: const TextStyle(
                          color: Color(0xFF34A853),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (telemetry.skippedDuplicatesCount > 0)
                        Text(
                          'Skipped ${telemetry.skippedDuplicatesCount} duplicates',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      if (telemetry.speedMBps > 0)
                        Text(
                          '${telemetry.speedMBps.toStringAsFixed(1)} MB/s',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 3. Media Type Filters (All / Photos / Videos)
          Text(
            'MEDIA TYPE FILTER',
            style: TextStyle(
              color: isLight ? Colors.grey.shade600 : Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFilterChip(
                label: 'All Media',
                icon: Icons.perm_media_rounded,
                selected: _mediaTypeFilter == 'all',
                onSelected: () => setState(() => _mediaTypeFilter = 'all'),
                isLight: isLight,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Photos Only',
                icon: Icons.photo_outlined,
                selected: _mediaTypeFilter == 'photos',
                onSelected: () => setState(() => _mediaTypeFilter = 'photos'),
                isLight: isLight,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Videos Only',
                icon: Icons.videocam_outlined,
                selected: _mediaTypeFilter == 'videos',
                onSelected: () => setState(() => _mediaTypeFilter = 'videos'),
                isLight: isLight,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4. Import Scope Configuration (Multi-Method)
          Text(
            'IMPORT SCOPE & PRESETS',
            style: TextStyle(
              color: isLight ? Colors.grey.shade600 : Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                _buildScopeOptionTile(
                  keyId: 'all',
                  title: 'Full Library (All Time)',
                  subtitle: 'Import all historical photos & videos',
                  icon: Icons.all_inclusive_rounded,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  isLight: isLight,
                ),
                Divider(
                  height: 1,
                  color: isLight
                      ? Colors.grey.shade200
                      : Colors.white.withValues(alpha: 0.05),
                ),
                _buildScopeOptionTile(
                  keyId: '30days',
                  title: 'Past 30 Days',
                  subtitle: 'Only media uploaded in the last month',
                  icon: Icons.date_range_rounded,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  isLight: isLight,
                ),
                Divider(
                  height: 1,
                  color: isLight
                      ? Colors.grey.shade200
                      : Colors.white.withValues(alpha: 0.05),
                ),
                _buildScopeOptionTile(
                  keyId: '90days',
                  title: 'Past 90 Days',
                  subtitle: 'Only media from the last quarter',
                  icon: Icons.calendar_month_rounded,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  isLight: isLight,
                ),
                Divider(
                  height: 1,
                  color: isLight
                      ? Colors.grey.shade200
                      : Colors.white.withValues(alpha: 0.05),
                ),
                _buildScopeOptionTile(
                  keyId: '1year',
                  title: 'Past 1 Year',
                  subtitle: 'Import media from the last 365 days',
                  icon: Icons.calendar_today_rounded,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  isLight: isLight,
                ),
                Divider(
                  height: 1,
                  color: isLight
                      ? Colors.grey.shade200
                      : Colors.white.withValues(alpha: 0.05),
                ),
                _buildScopeOptionTile(
                  keyId: 'custom',
                  title: 'Custom Date Range',
                  subtitle: _customDateRange != null
                      ? '${_customDateRange!.start.month}/${_customDateRange!.start.day}/${_customDateRange!.start.year} - ${_customDateRange!.end.month}/${_customDateRange!.end.day}/${_customDateRange!.end.year}'
                      : 'Select custom start and end dates',
                  icon: Icons.edit_calendar_rounded,
                  trailingButtonText: 'Pick Dates',
                  onTrailingTap: _pickCustomDateRange,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  isLight: isLight,
                ),
                Divider(
                  height: 1,
                  color: isLight
                      ? Colors.grey.shade200
                      : Colors.white.withValues(alpha: 0.05),
                ),
                _buildScopeOptionTile(
                  keyId: 'favorites',
                  title: 'Favorites / Starred Only',
                  subtitle: 'Import only starred & favorite media',
                  icon: Icons.star_rounded,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  isLight: isLight,
                ),
                Divider(
                  height: 1,
                  color: isLight
                      ? Colors.grey.shade200
                      : Colors.white.withValues(alpha: 0.05),
                ),
                _buildScopeOptionTile(
                  keyId: 'albums',
                  title: 'Selective Google Photos Albums',
                  subtitle: _selectedAlbum != null
                      ? 'Selected: ${_selectedAlbum!.title}'
                      : 'Choose specific albums to import',
                  icon: Icons.photo_library_rounded,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  isLight: isLight,
                ),
              ],
            ),
          ),

          // 5. Discovered Live Albums Horizontal Carousel
          if (_selectedScope == 'albums') ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SELECT AN ALBUM',
                  style: TextStyle(
                    color: isLight
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                if (_isLoadingAlbums)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: _fetchAlbums,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: Color(0xFF4285F4),
                    ),
                    label: const Text(
                      'Refresh',
                      style: TextStyle(color: Color(0xFF4285F4), fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_albums.isEmpty && !_isLoadingAlbums)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Center(
                  child: Text(
                    'No Google Photos albums found. Tap Refresh or sign in.',
                    style: TextStyle(color: secondaryTextColor, fontSize: 13),
                  ),
                ),
              )
            else
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _albums.length,
                  itemBuilder: (context, idx) {
                    final album = _albums[idx];
                    final isSelected = _selectedAlbum?.id == album.id;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedAlbum = album);
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4285F4).withValues(alpha: 0.15)
                              : cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4285F4)
                                : cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  Icons.photo_album_rounded,
                                  color: isSelected
                                      ? const Color(0xFF4285F4)
                                      : Colors.grey,
                                  size: 26,
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF4285F4),
                                    size: 18,
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  album.title,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF4285F4)
                                        : primaryTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${album.itemCount} items',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],

          const SizedBox(height: 20),

          // 6. Automation & Delta Sync Safeguards
          Text(
            'SYNC STRATEGY & AUTOMATION',
            style: TextStyle(
              color: isLight ? Colors.grey.shade600 : Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeTrackColor: const Color(0xFF4285F4),
                  title: Text(
                    'Incremental Delta Sync',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Only import new photos added after previous backup',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  value: _incrementalDeltaSync,
                  onChanged: (val) =>
                      setState(() => _incrementalDeltaSync = val),
                ),
                Divider(
                  height: 1,
                  color: isLight
                      ? Colors.grey.shade200
                      : Colors.white.withValues(alpha: 0.05),
                ),
                SwitchListTile(
                  activeTrackColor: const Color(0xFF4285F4),
                  title: Text(
                    'Background Auto-Sync',
                    style: TextStyle(color: primaryTextColor, fontSize: 15),
                  ),
                  subtitle: Text(
                    'Periodically check and import new Google Photos in background',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  value: syncService.isAutoSyncEnabled,
                  onChanged: (val) {
                    syncService.setAutoSync(val);
                  },
                ),
                Divider(
                  height: 1,
                  color: isLight
                      ? Colors.grey.shade200
                      : Colors.white.withValues(alpha: 0.05),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.fingerprint_rounded,
                    color: Color(0xFF34A853),
                  ),
                  title: Text(
                    'Smart Deduplication Active',
                    style: TextStyle(color: primaryTextColor, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Prevents duplicate uploads and preserves EXIF timestamps',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  dense: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 7. Action Button: Start Stream Import
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: telemetry.isSyncing
                  ? null
                  : () async {
                      if (!authService.isSignedIn) {
                        final success = await authService.signIn();
                        if (!success) return;
                      }

                      DateTime? start;
                      DateTime? end;
                      if (_selectedScope == '30days') {
                        start = DateTime.now().subtract(
                          const Duration(days: 30),
                        );
                      } else if (_selectedScope == '90days') {
                        start = DateTime.now().subtract(
                          const Duration(days: 90),
                        );
                      } else if (_selectedScope == '1year') {
                        start = DateTime.now().subtract(
                          const Duration(days: 365),
                        );
                      } else if (_selectedScope == 'custom' &&
                          _customDateRange != null) {
                        start = _customDateRange!.start;
                        end = _customDateRange!.end;
                      }

                      HapticFeedback.mediumImpact();
                      syncService.startImport(
                        albumId: _selectedScope == 'albums'
                            ? _selectedAlbum?.id
                            : null,
                        albumTitle: _selectedScope == 'albums'
                            ? _selectedAlbum?.title
                            : null,
                        startDate: start,
                        endDate: end,
                      );
                    },
              icon: telemetry.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_sync_rounded, size: 22),
              label: Text(
                telemetry.isSyncing
                    ? 'Importing from Google Photos...'
                    : 'Start Cloud Stream Import',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(GoogleAccountProfile profile) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
          ],
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          profile.displayName.isNotEmpty
              ? profile.displayName[0].toUpperCase()
              : 'G',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onSelected,
    required bool isLight,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF4285F4).withValues(alpha: 0.15)
                : (isLight ? const Color(0xFFF2F2F7) : const Color(0xFF2C2C2E)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4285F4)
                  : Colors.white.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? const Color(0xFF4285F4)
                    : (isLight ? Colors.black87 : Colors.white70),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF4285F4)
                      : (isLight ? Colors.black87 : Colors.white70),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScopeOptionTile({
    required String keyId,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required bool isLight,
    String? trailingButtonText,
    VoidCallback? onTrailingTap,
  }) {
    final isSelected = _selectedScope == keyId;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedScope = keyId);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4285F4).withValues(alpha: 0.15)
                    : (isLight
                          ? Colors.grey.shade100
                          : Colors.white.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF4285F4)
                    : secondaryTextColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF4285F4)
                          : primaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (trailingButtonText != null) ...[
              TextButton(
                onPressed: onTrailingTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  trailingButtonText,
                  style: const TextStyle(
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4285F4)
                      : (isLight ? Colors.grey.shade400 : Colors.white38),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFF4285F4)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
