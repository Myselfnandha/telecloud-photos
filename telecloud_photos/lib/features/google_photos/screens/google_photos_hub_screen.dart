import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/media_table.dart';
import '../../../core/di/providers.dart';
import '../../../core/takeout/takeout_parser_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_elevation.dart';

class GooglePhotosHubScreen extends ConsumerStatefulWidget {
  const GooglePhotosHubScreen({super.key});

  @override
  ConsumerState<GooglePhotosHubScreen> createState() =>
      _GooglePhotosHubScreenState();
}

class _GooglePhotosHubScreenState extends ConsumerState<GooglePhotosHubScreen> {
  final TextEditingController _customPathController = TextEditingController();

  bool _isAnalyzing = false;
  TakeoutZipSummary? _zipSummary;

  bool _isImporting = false;
  TakeoutImportProgress _progress = const TakeoutImportProgress();
  StreamSubscription<TakeoutImportProgress>? _progressSub;

  bool _uploadToTelegramTopic = true;
  int _lastImportedTotal = 0;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    final parser = ref.read(takeoutParserServiceProvider);
    _progressSub = parser.progressStream.listen((prog) {
      if (mounted) {
        setState(() {
          _progress = prog;
          if (prog.stage == TakeoutImportStage.completed && _isImporting) {
            _isImporting = false;
            _lastImportedTotal = prog.importedCount;
            _showCelebration = true;
          } else if (prog.stage == TakeoutImportStage.failed && _isImporting) {
            _isImporting = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _customPathController.dispose();
    super.dispose();
  }

  Future<void> _analyzeSelectedPath(String path) async {
    final file = File(path);
    final isZip = path.toLowerCase().endsWith('.zip');

    if (isZip && await file.exists()) {
      setState(() {
        _isAnalyzing = true;
      });

      final parser = ref.read(takeoutParserServiceProvider);
      final summary = await parser.analyzeZipArchive(path);

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _zipSummary = summary;
        });
      }
    } else {
      setState(() {
        _zipSummary = null;
      });
    }
  }

  Future<void> _startImport() async {
    final path = _customPathController.text.trim();
    if (path.isEmpty) return;

    final isZip = path.toLowerCase().endsWith('.zip');
    final file = File(path);
    final dir = Directory(path);

    if (!await file.exists() && !await dir.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Path "$path" does not exist.'),
            backgroundColor: AppColors.systemRed,
          ),
        );
      }
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isImporting = true;
      _showCelebration = false;
    });

    final parser = ref.read(takeoutParserServiceProvider);

    if (isZip) {
      await parser.importFromZip(
        zipFilePath: path,
        uploadToTelegram: _uploadToTelegramTopic,
        topicName: 'Google Photos Import',
      );
    } else {
      // Direct directory scan
      await _startDirectoryImport(path);
    }
  }

  Future<void> _startDirectoryImport(String folderPath) async {
    final dir = Directory(folderPath);
    final mediaDao = ref.read(mediaDaoProvider);
    final uploadService = ref.read(telegramUploadServiceProvider);
    final channelManager = ref.read(channelManagerProvider);
    final targetChatId = channelManager.channelId;

    int? targetTopicId;
    if (_uploadToTelegramTopic && targetChatId != null) {
      targetTopicId = await channelManager.ensureAlbumTopic('Google Photos Import');
    }

    final validExtensions = {
      '.jpg', '.jpeg', '.png', '.mp4', '.mov', '.webp', '.heic', '.mkv',
    };

    final entities = dir.listSync(recursive: true, followLinks: false);
    final files = entities.whereType<File>().where((f) {
      final ext = p.extension(f.path).toLowerCase();
      return validExtensions.contains(ext);
    }).toList();

    int count = 0;
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final filename = p.basename(file.path);
      final stat = file.statSync();
      final isVideo = filename.toLowerCase().endsWith('.mp4') ||
          filename.toLowerCase().endsWith('.mov') ||
          filename.toLowerCase().endsWith('.mkv');

      int? telegramMsgId;
      if (_uploadToTelegramTopic && targetChatId != null) {
        telegramMsgId = await uploadService.uploadDirectFile(
          file: file,
          filename: filename,
          capturedAt: stat.modified,
          targetChatId: targetChatId,
          topicId: targetTopicId,
          albumName: 'Google Photos Import',
        );
      }

      await mediaDao.insertOrIgnoreBatch([
        MediaItemsCompanion.insert(
          localId: 'gp_${stat.modified.millisecondsSinceEpoch}_$filename',
          filename: filename,
          mimeType: isVideo ? 'video/mp4' : 'image/jpeg',
          capturedAt: stat.modified,
          uploadStatus: telegramMsgId != null ? UploadStatus.done : UploadStatus.pending,
          telegramMsgId: telegramMsgId != null ? drift.Value(telegramMsgId) : const drift.Value.absent(),
          fileSizeBytes: drift.Value(stat.size),
          thumbnailPath: drift.Value(file.path),
        ),
      ]);

      count++;
      if (mounted) {
        setState(() {
          _progress = TakeoutImportProgress(
            stage: TakeoutImportStage.uploading,
            totalItems: files.length,
            processedItems: i + 1,
            importedCount: count,
            currentFilename: filename,
          );
        });
      }
    }

    if (mounted) {
      setState(() {
        _isImporting = false;
        _lastImportedTotal = count;
        _showCelebration = true;
      });
    }
  }

  Future<void> _scanCommonTakeoutLocations() async {
    try {
      final extDir = await getExternalStorageDirectory();
      final pathsToTry = [
        '/storage/emulated/0/Download/Takeout.zip',
        '/storage/emulated/0/Download/takeout.zip',
        '/storage/emulated/0/Download/Google Photos',
        '/storage/emulated/0/Download/Takeout',
        '/storage/emulated/0/Takeout',
        if (extDir != null) extDir.path,
      ];

      for (final p in pathsToTry) {
        final f = File(p);
        final d = Directory(p);
        if (await f.exists() || await d.exists()) {
          _customPathController.text = p;
          await _analyzeSelectedPath(p);
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No Takeout file found in default Downloads. Please specify file path below.',
            ),
            backgroundColor: Color(0xFFFF9F0A),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryTextColor = AppColors.textPrimary(context);
    final secondaryTextColor = AppColors.textSecondary(context);
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
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Google Photos Takeout',
          style: AppTypography.headlineSmall(
            color: primaryTextColor,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _showCelebration
            ? _buildCelebrationView(context, isLight, primaryTextColor, secondaryTextColor)
            : _isImporting
                ? _buildImportingProgressView(context, isLight, primaryTextColor, secondaryTextColor)
                : _buildMainView(context, isLight, primaryTextColor, secondaryTextColor, cardBg, cardBorder),
      ),
    );
  }

  Widget _buildMainView(
    BuildContext context,
    bool isLight,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color cardBg,
    Color cardBorder,
  ) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        // Hero Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4285F4), Color(0xFF34A853)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadii.borderXL,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_download_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Takeout Streaming Importer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Stream Google Photos .zip archives directly into Telegram Cloud without exhausting device storage. JSON metadata sidecars are automatically matched.',
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick Scan Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.drive_file_move_rounded, size: 20),
            label: Text(
              'Auto-Detect Downloads Takeout .ZIP',
              style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600),
            ),
            onPressed: _scanCommonTakeoutLocations,
          ),
        ),
        const SizedBox(height: 20),

        // Import Archive Input
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadii.borderL,
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TAKEOUT ARCHIVE PATH (.ZIP OR FOLDER)',
                style: TextStyle(
                  color: isLight ? Colors.grey.shade600 : Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _customPathController,
                style: TextStyle(color: primaryTextColor, fontSize: 14),
                onChanged: (val) {
                  _analyzeSelectedPath(val.trim());
                },
                decoration: InputDecoration(
                  hintText: '/storage/emulated/0/Download/takeout.zip',
                  hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
                  labelText: 'Zip File or Unpacked Folder',
                  labelStyle: const TextStyle(color: Color(0xFF0A84FF)),
                  filled: true,
                  fillColor: isLight ? Colors.grey.shade100 : const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              // Zip Analysis Card
              if (_isAnalyzing) ...[
                const SizedBox(height: 16),
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                      ),
                      SizedBox(width: 10),
                      Text('Inspecting zip entries...'),
                    ],
                  ),
                ),
              ] else if (_zipSummary != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0A84FF).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Photos', '${_zipSummary!.photoCount}', Icons.photo_rounded, primaryTextColor, secondaryTextColor),
                      _buildSummaryItem('Videos', '${_zipSummary!.videoCount}', Icons.videocam_rounded, primaryTextColor, secondaryTextColor),
                      _buildSummaryItem('Metadata', '${_zipSummary!.metadataJsonCount}', Icons.data_object_rounded, primaryTextColor, secondaryTextColor),
                      _buildSummaryItem('Size', _zipSummary!.formattedSize, Icons.storage_rounded, primaryTextColor, secondaryTextColor),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Supergroup Topic Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _uploadToTelegramTopic,
                activeColor: const Color(0xFF0A84FF),
                title: Text(
                  'Upload to "Google Photos" Topic',
                  style: TextStyle(color: primaryTextColor, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Organizes imported Takeout items into a dedicated Telegram Supergroup topic',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
                onChanged: (val) => setState(() => _uploadToTelegramTopic = val),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text(
                    'Start Streaming Import',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _startImport,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Live Imports Stream List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'IMPORTED FROM GOOGLE',
              style: AppTypography.labelSmall(color: secondaryTextColor)
                  .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            TextButton(
              onPressed: () => context.push('/google-photos/synced'),
              child: const Text('View All', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 12)),
            ),
          ],
        ),
        AppSpacing.gapVerticalS,
        StreamBuilder<List<MediaItem>>(
          stream: ref.watch(mediaDaoProvider).watchGooglePhotosMedia(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadii.borderL,
                  border: Border.all(color: cardBorder),
                ),
                child: Center(
                  child: Text(
                    'No Google Photos imported yet.\nExtract or stream your Takeout archive above.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryTextColor, fontSize: 13),
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: AppRadii.borderL,
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF30D158), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${items.length} Google Photos in Cloud',
                          style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Available directly in timeline & cloud viewer',
                          style: TextStyle(color: secondaryTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color primaryColor, Color secondaryColor) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0A84FF)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(color: secondaryColor, fontSize: 11)),
      ],
    );
  }

  Widget _buildImportingProgressView(
    BuildContext context,
    bool isLight,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF0A84FF), strokeWidth: 4),
            const SizedBox(height: 28),
            Text(
              'Streaming Takeout to Telegram...',
              style: TextStyle(color: primaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _progress.currentFilename.isNotEmpty ? _progress.currentFilename : 'Processing archive...',
              style: TextStyle(color: secondaryTextColor, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress.progressPercentage > 0 ? _progress.progressPercentage : null,
                minHeight: 8,
                backgroundColor: isLight ? Colors.grey.shade200 : const Color(0xFF2C2C2E),
                color: const Color(0xFF0A84FF),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_progress.processedItems} of ${_progress.totalItems} items',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
                Text(
                  '${(_progress.progressPercentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.systemRed),
              label: const Text('Cancel Import', style: TextStyle(color: AppColors.systemRed)),
              onPressed: () {
                ref.read(takeoutParserServiceProvider).cancelImport();
              },
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF30D158).withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.celebration_rounded, size: 48, color: Color(0xFF30D158)),
            ),
            const SizedBox(height: 24),
            Text(
              '🎉 Import Complete!',
              style: TextStyle(color: primaryTextColor, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Successfully imported $_lastImportedTotal Google Photos items into your Telegram Cloud and Timeline.',
              style: TextStyle(color: secondaryTextColor, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF30D158),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.photo_library_rounded, size: 20),
                label: const Text('View in Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => context.go('/timeline'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() => _showCelebration = false);
              },
              child: Text('Import Another Archive', style: TextStyle(color: secondaryTextColor)),
            ),
          ],
        ),
      ),
    );
  }
}
