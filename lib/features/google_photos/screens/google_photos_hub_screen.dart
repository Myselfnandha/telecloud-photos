import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables/media_table.dart';
import '../../../core/di/providers.dart';
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
  bool _isImporting = false;
  int _importedCount = 0;
  String _importStatus = '';
  final TextEditingController _customPathController = TextEditingController();

  @override
  void dispose() {
    _customPathController.dispose();
    super.dispose();
  }

  Future<void> _startTakeoutScan(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Directory "$folderPath" does not exist.'),
            backgroundColor: AppColors.systemRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isImporting = true;
      _importedCount = 0;
      _importStatus = 'Scanning Google Photos Takeout directory...';
    });

    try {
      final mediaDao = ref.read(mediaDaoProvider);
      final validExtensions = {
        '.jpg',
        '.jpeg',
        '.png',
        '.mp4',
        '.mov',
        '.webp',
        '.heic',
        '.mkv',
      };

      int count = 0;
      final entities = dir.listSync(recursive: true, followLinks: false);

      for (final entity in entities) {
        if (entity is File) {
          final path = entity.path;
          final ext = path.substring(path.lastIndexOf('.')).toLowerCase();
          if (validExtensions.contains(ext)) {
            final filename = path.split(Platform.pathSeparator).last;
            final stat = entity.statSync();
            final isVideo = ext == '.mp4' || ext == '.mov' || ext == '.mkv';

            await mediaDao.insertOrIgnoreBatch([
              MediaItemsCompanion.insert(
                localId: 'gp_${stat.modified.millisecondsSinceEpoch}_$filename',
                filename: filename,
                mimeType: isVideo ? 'video/mp4' : 'image/jpeg',
                capturedAt: stat.modified,
                uploadStatus: UploadStatus.pending,
                width: const drift.Value(1920),
                height: const drift.Value(1080),
                fileSizeBytes: drift.Value(stat.size),
                thumbnailPath: drift.Value(path),
              ),
            ]);

            count++;
            if (count % 10 == 0 && mounted) {
              setState(() {
                _importedCount = count;
                _importStatus = 'Imported $count Google Photos items...';
              });
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _isImporting = false;
          _importedCount = count;
          _importStatus = 'Import complete! $count items added.';
        });

        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Successfully imported $count photos from Takeout!'),
            backgroundColor: const Color(0xFF30D158),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importStatus = 'Import error: $e';
        });
      }
    }
  }

  Future<void> _scanCommonTakeoutLocations() async {
    try {
      final extDir = await getExternalStorageDirectory();
      final pathsToTry = [
        '/storage/emulated/0/Download/Google Photos',
        '/storage/emulated/0/Download/Takeout',
        '/storage/emulated/0/Takeout',
        '/storage/emulated/0/DCIM/GooglePhotos',
        if (extDir != null) extDir.path,
      ];

      for (final p in pathsToTry) {
        final d = Directory(p);
        if (await d.exists()) {
          _startTakeoutScan(p);
          return;
        }
      }

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No Takeout directory found in default locations. Please enter folder path below.',
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
    final primaryTextColor =
        isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;
    final secondaryTextColor =
        isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary;
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
      body: ListView(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_download_rounded,
                        color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Google Takeout Importer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Import uncompressed photos & videos from your Google Takeout archive directly into TeleCloud unlimited storage.',
                  style:
                      TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Instructions Card
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
                  'HOW TO EXPORT FROM GOOGLE',
                  style: TextStyle(
                    color:
                        isLight ? Colors.grey.shade600 : Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStep(
                  '1',
                  'Visit takeout.google.com and select "Google Photos"',
                  primaryTextColor,
                ),
                _buildStep(
                  '2',
                  'Download & extract the ZIP files to your device Downloads',
                  primaryTextColor,
                ),
                _buildStep(
                  '3',
                  'Tap Scan below or specify the folder path to import',
                  primaryTextColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Import Action Box
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
                  'IMPORT ARCHIVE',
                  style: TextStyle(
                    color:
                        isLight ? Colors.grey.shade600 : Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _customPathController,
                  style: TextStyle(color: primaryTextColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '/storage/emulated/0/Download/Takeout',
                    hintStyle:
                        TextStyle(color: secondaryTextColor, fontSize: 13),
                    labelText: 'Custom Folder Path',
                    labelStyle: const TextStyle(color: Color(0xFF0A84FF)),
                    filled: true,
                    fillColor: isLight
                        ? Colors.grey.shade100
                        : const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
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
                    icon: _isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.folder_open_rounded),
                    label: Text(
                      _isImporting
                          ? 'Importing...'
                          : 'Scan & Import Takeout Folder',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isImporting
                        ? null
                        : () {
                            final path = _customPathController.text.trim();
                            if (path.isNotEmpty) {
                              _startTakeoutScan(path);
                            } else {
                              _scanCommonTakeoutLocations();
                            }
                          },
                  ),
                ),
                if (_importStatus.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (_importedCount > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0A84FF).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_importedCount',
                            style: const TextStyle(
                              color: Color(0xFF0A84FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _importStatus,
                          style: TextStyle(
                            color: _importStatus.contains('complete')
                                ? const Color(0xFF30D158)
                                : const Color(0xFF0A84FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF0A84FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
