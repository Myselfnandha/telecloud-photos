import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables/media_table.dart';
import '../../../core/di/providers.dart';
import '../../../core/media/exif_parser_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';
import '../../../shared/theme/app_typography.dart';

class ExifInfoSheet extends ConsumerStatefulWidget {
  final MediaItem item;
  final AssetEntity? asset;

  const ExifInfoSheet({
    super.key,
    required this.item,
    this.asset,
  });

  @override
  ConsumerState<ExifInfoSheet> createState() => _ExifInfoSheetState();
}

class _ExifInfoSheetState extends ConsumerState<ExifInfoSheet> {
  ExifMetadata? _exif;
  bool _isLoading = true;
  late DateTime _capturedAt;

  @override
  void initState() {
    super.initState();
    _capturedAt = widget.item.capturedAt;
    _loadExif();
  }

  Future<void> _loadExif() async {
    ExifMetadata? metadata;
    if (widget.asset != null) {
      metadata = await ExifParserService.parseAsset(widget.asset!);
    } else {
      final file = File(widget.item.localId);
      if (await file.exists()) {
        metadata = await ExifParserService.parseFile(file);
      }
    }

    if (mounted) {
      setState(() {
        _exif = metadata ?? const ExifMetadata();
        _isLoading = false;
      });
    }
  }

  Future<void> _editDateTime() async {
    HapticFeedback.selectionClick();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _capturedAt,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: AppColors.darkSurface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_capturedAt),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: AppColors.darkSurface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() => _capturedAt = newDateTime);

    // Save to SQLite
    final dao = ref.read(mediaDaoProvider);
    await dao.updateMediaCapturedAt(widget.item.localId, newDateTime);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Timestamp updated to ${DateFormat('MMM d, y • h:mm a').format(newDateTime)}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1C1C1E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    HapticFeedback.lightImpact();
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

    if (await canLaunchUrl(geoUrl)) {
      await launchUrl(geoUrl);
    } else if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white60 : Colors.black54;
    final cardBg = isDark ? AppColors.darkSurface : Colors.grey.shade100;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final lat = _exif?.latitude ?? widget.item.latitude;
    final lng = _exif?.longitude ?? widget.item.longitude;
    final hasLocation = lat != null && lng != null && (lat != 0.0 || lng != 0.0);

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: AppRadii.borderTopXL,
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Info & EXIF Details',
                      style: AppTypography.titleLarge(color: primaryTextColor),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: secondaryTextColor,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 1. Date & Time Tile (with Edit Button)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppRadii.borderXL,
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: AppRadii.borderM,
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.primaryBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE, MMMM d, y').format(_capturedAt),
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('h:mm:ss a').format(_capturedAt),
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _editDateTime,
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Camera & Optical Breakdown Card
                    if (_isLoading)
                      Container(
                        height: 120,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: AppRadii.borderXL,
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF30D158).withValues(alpha: 0.15),
                                    borderRadius: AppRadii.borderM,
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera_rounded,
                                    color: Color(0xFF30D158),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _exif?.formattedCameraTitle ?? 'Device Camera',
                                        style: TextStyle(
                                          color: primaryTextColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (_exif?.lensModel != null)
                                        Text(
                                          _exif!.lensModel!,
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            // Exposure Matrix (4 pills)
                            Row(
                              children: [
                                _buildExposureCell(
                                  label: 'Aperture',
                                  value: _exif?.fNumber ?? 'f/1.8',
                                  primaryText: primaryTextColor,
                                  secondaryText: secondaryTextColor,
                                ),
                                _buildExposureCell(
                                  label: 'Shutter',
                                  value: _exif?.exposureTime ?? '1/120s',
                                  primaryText: primaryTextColor,
                                  secondaryText: secondaryTextColor,
                                ),
                                _buildExposureCell(
                                  label: 'ISO',
                                  value: _exif?.iso ?? 'ISO 100',
                                  primaryText: primaryTextColor,
                                  secondaryText: secondaryTextColor,
                                ),
                                _buildExposureCell(
                                  label: 'Focal',
                                  value: _exif?.focalLength ?? '24mm',
                                  primaryText: primaryTextColor,
                                  secondaryText: secondaryTextColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],

                    // 3. File & Resolution Details Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppRadii.borderXL,
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            label: 'Filename',
                            value: widget.item.filename,
                            primaryText: primaryTextColor,
                            secondaryText: secondaryTextColor,
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            label: 'Resolution',
                            value: _exif?.formattedResolution ??
                                (widget.item.width != null && widget.item.height != null
                                    ? '${widget.item.width} × ${widget.item.height}'
                                    : 'HD'),
                            primaryText: primaryTextColor,
                            secondaryText: secondaryTextColor,
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            label: 'File Size',
                            value: _exif?.formattedFileSize ??
                                (widget.item.fileSizeBytes != null
                                    ? '${(widget.item.fileSizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB'
                                    : 'Unknown'),
                            primaryText: primaryTextColor,
                            secondaryText: secondaryTextColor,
                          ),
                          if (widget.item.folderName != null) ...[
                            const Divider(height: 16),
                            _buildDetailRow(
                              label: 'Folder',
                              value: widget.item.folderName!,
                              primaryText: primaryTextColor,
                              secondaryText: secondaryTextColor,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 4. GPS Map & Location Card
                    if (hasLocation) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: AppRadii.borderXL,
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                                    borderRadius: AppRadii.borderM,
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFFFF9500),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'GPS Geotag Location',
                                        style: TextStyle(
                                          color: primaryTextColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        '${lat.toStringAsFixed(5)}°, ${lng.toStringAsFixed(5)}°',
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openMap(lat, lng),
                                icon: const Icon(Icons.map_rounded, size: 18),
                                label: const Text('Open in Google Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadii.borderL,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 5. Telegram Cloud Backup Info
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppRadii.borderXL,
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (widget.item.uploadStatus == UploadStatus.done
                                          ? const Color(0xFF30D158)
                                          : AppColors.primaryBlue)
                                      .withValues(alpha: 0.15),
                                  borderRadius: AppRadii.borderM,
                                ),
                                child: Icon(
                                  widget.item.uploadStatus == UploadStatus.done
                                      ? Icons.cloud_done_rounded
                                      : Icons.cloud_queue_rounded,
                                  color: widget.item.uploadStatus == UploadStatus.done
                                      ? const Color(0xFF30D158)
                                      : AppColors.primaryBlue,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.item.uploadStatus == UploadStatus.done
                                          ? 'Synced to Telegram Cloud'
                                          : 'Local Device Media',
                                      style: TextStyle(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      widget.item.telegramMsgId != null
                                          ? 'Message ID: #${widget.item.telegramMsgId}'
                                          : 'Pending Telegram Cloud Sync',
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (widget.item.sha256Hash != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'SHA-256: ${widget.item.sha256Hash!.substring(0, 16)}...',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExposureCell({
    required String label,
    required String value,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: primaryText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: secondaryText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: secondaryText,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
