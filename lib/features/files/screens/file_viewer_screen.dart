import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';

class FileViewerScreen extends ConsumerStatefulWidget {
  final CloudFile file;
  const FileViewerScreen({super.key, required this.file});

  @override
  ConsumerState<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends ConsumerState<FileViewerScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _textContent;

  @override
  void initState() {
    super.initState();
    _loadLocalContent();
  }

  Future<void> _loadLocalContent() async {
    final localPath = widget.file.localPath;
    if (localPath != null && await File(localPath).exists()) {
      final ext = p.extension(widget.file.fileName).toLowerCase();
      if (['.txt', '.md', '.json', '.dart', '.py', '.js', '.html', '.css', '.log', '.csv', '.yaml', '.xml'].contains(ext)) {
        try {
          final content = await File(localPath).readAsString();
          if (mounted) {
            setState(() {
              _textContent = content.length > 50000 ? '${content.substring(0, 50000)}\n\n[... Truncated for display ...]' : content;
            });
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _handleDownload() async {
    if (widget.file.telegramFileId == null) return;
    final fileId = int.tryParse(widget.file.telegramFileId!);
    if (fileId == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final filesManager = ref.read(telegramFilesManagerProvider);
    final messenger = ScaffoldMessenger.of(context);

    final path = await filesManager.downloadFile(
      telegramFileId: fileId,
      fileName: widget.file.fileName,
      onProgress: (p) => setState(() => _downloadProgress = p),
    );

    if (mounted) {
      setState(() => _isDownloading = false);
      if (path != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('✓ Downloaded: ${widget.file.fileName}'),
            backgroundColor: const Color(0xFF30D158),
          ),
        );
        _loadLocalContent();
      }
    }
  }

  Future<void> _handleOpenInExternalApp() async {
    final messenger = ScaffoldMessenger.of(context);
    final path = widget.file.localPath;
    if (path == null || !await File(path).exists()) {
      await _handleDownload();
      return;
    }

    try {
      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No suitable application found to open this file'),
          backgroundColor: Color(0xFFFF9F0A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(
      p.extension(widget.file.fileName).toLowerCase().replaceAll('.', ''),
    );
    final hasLocal = widget.file.localPath != null && File(widget.file.localPath!).existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.file.fileName,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.file.isPinnedOffline ? Icons.push_pin : Icons.push_pin_outlined,
              color: widget.file.isPinnedOffline ? const Color(0xFFFF9F0A) : Colors.white,
            ),
            tooltip: 'Pin for offline',
            onPressed: () async {
              final dao = ref.read(filesDaoProvider);
              final nav = Navigator.of(context);
              await dao.togglePinOffline(widget.file.id, !widget.file.isPinnedOffline);
              nav.pop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF453A)),
            tooltip: 'Delete',
            onPressed: () async {
              final dao = ref.read(filesDaoProvider);
              final nav = Navigator.of(context);
              await dao.deleteFile(widget.file.id);
              nav.pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main Preview Area
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: isImage && hasLocal
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(widget.file.localPath!),
                          fit: BoxFit.contain,
                        ),
                      )
                    : _textContent != null
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              child: Text(
                                _textContent!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildBigIcon(widget.file.fileName),
                                const SizedBox(height: 16),
                                Text(
                                  widget.file.fileName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatFileSize(widget.file.fileSizeBytes),
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
              ),
            ),

            // Download progress bar
            if (_isDownloading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      backgroundColor: Colors.white12,
                      color: const Color(0xFF0A84FF),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Downloading from Telegram Cloud: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Bottom Actions Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A84FF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(hasLocal ? Icons.open_in_new : Icons.download),
                      label: Text(
                        hasLocal ? 'Open in System' : 'Download File',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _isDownloading
                          ? null
                          : () {
                              if (hasLocal) {
                                _handleOpenInExternalApp();
                              } else {
                                _handleDownload();
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');
    IconData icon = Icons.insert_drive_file;
    Color color = Colors.grey;

    if (['pdf'].contains(ext)) {
      icon = Icons.picture_as_pdf;
      color = const Color(0xFFFF453A);
    } else if (['doc', 'docx', 'txt', 'md'].contains(ext)) {
      icon = Icons.description;
      color = const Color(0xFF0A84FF);
    } else if (['xls', 'xlsx', 'csv'].contains(ext)) {
      icon = Icons.table_chart;
      color = const Color(0xFF30D158);
    } else if (['zip', 'rar', '7z', 'tar'].contains(ext)) {
      icon = Icons.folder_zip;
      color = const Color(0xFFFFD60A);
    } else if (['mp3', 'wav', 'aac', 'flac'].contains(ext)) {
      icon = Icons.audio_file;
      color = const Color(0xFFBF5AF2);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 48),
    );
  }

  String _formatFileSize(BigInt bytes) {
    final b = bytes.toDouble();
    if (b >= 1073741824) return '${(b / 1073741824).toStringAsFixed(2)} GB';
    if (b >= 1048576) return '${(b / 1048576).toStringAsFixed(1)} MB';
    if (b >= 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${bytes.toInt()} B';
  }
}
