import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../../../core/database/app_database.dart';
import '../../../core/di/providers.dart';
import 'file_viewer_screen.dart';

class FilesExplorerScreen extends ConsumerStatefulWidget {
  final String initialFolder;
  const FilesExplorerScreen({super.key, this.initialFolder = '/'});

  @override
  ConsumerState<FilesExplorerScreen> createState() => _FilesExplorerScreenState();
}

class _FilesExplorerScreenState extends ConsumerState<FilesExplorerScreen> {
  late String _currentFolder;
  bool _isGridView = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentFolder = widget.initialFolder;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToFolder(String folderPath) {
    setState(() {
      _currentFolder = folderPath;
      _searchQuery = '';
      _isSearching = false;
      _searchController.clear();
    });
  }

  void _navigateUp() {
    if (_currentFolder == '/' || _currentFolder.isEmpty) return;
    final parent = p.dirname(_currentFolder);
    setState(() {
      _currentFolder = parent == '.' ? '/' : parent;
    });
  }

  List<String> _getBreadcrumbs() {
    if (_currentFolder == '/' || _currentFolder.isEmpty) {
      return ['Home'];
    }
    final segments = _currentFolder.split('/').where((s) => s.isNotEmpty).toList();
    return ['Home', ...segments];
  }

  Future<void> _handleUploadFiles() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final filesManager = ref.read(telegramFilesManagerProvider);

      messenger.showSnackBar(
        SnackBar(
          content: Text('Uploading ${result.files.length} file(s) to cloud...'),
          backgroundColor: const Color(0xFF0A84FF),
          duration: const Duration(seconds: 2),
        ),
      );

      for (final platformFile in result.files) {
        if (platformFile.path != null) {
          await filesManager.uploadFile(
            localPath: platformFile.path!,
            fileName: platformFile.name,
            folderPath: _currentFolder,
          );
        }
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('✓ All files uploaded to Telegram Cloud!'),
          backgroundColor: Color(0xFF30D158),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: const Color(0xFFFF453A),
        ),
      );
    }
  }

  Future<void> _handleCreateFolder() async {
    final folderController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Cloud Folder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: folderController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Folder name (e.g. Work, Invoices)',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final name = folderController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(ctx).pop(name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != null && created.isNotEmpty) {
      final filesManager = ref.read(telegramFilesManagerProvider);
      await filesManager.ensureFolderTopic(created);
      messenger.showSnackBar(
        SnackBar(
          content: Text('✓ Folder "$created" created & synchronized!'),
          backgroundColor: const Color(0xFF30D158),
        ),
      );
    }
  }

  Future<void> _handleSyncDeviceFolders() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Scanning device Downloads & Documents...'),
        backgroundColor: Color(0xFF0A84FF),
      ),
    );

    final worker = ref.read(filesSyncWorkerProvider);
    final count = await worker.scanAndSyncMonitoredFolders();

    messenger.showSnackBar(
      SnackBar(
        content: Text('✓ Sync complete! Uploaded $count new files.'),
        backgroundColor: const Color(0xFF30D158),
      ),
    );
  }

  void _showFileActions(CloudFile file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: _buildFileIcon(file.fileName, size: 28),
                title: Text(
                  file.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${_formatFileSize(file.fileSizeBytes)} · ${file.folderPath}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF0A84FF)),
                title: const Text('Open / Preview File', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openFile(file);
                },
              ),
              ListTile(
                leading: Icon(
                  file.isPinnedOffline ? Icons.push_pin : Icons.push_pin_outlined,
                  color: file.isPinnedOffline ? const Color(0xFFFF9F0A) : Colors.white,
                ),
                title: Text(
                  file.isPinnedOffline ? 'Unpin from Offline' : 'Pin for Offline Access',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final dao = ref.read(filesDaoProvider);
                  await dao.togglePinOffline(file.id, !file.isPinnedOffline);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFFF453A)),
                title: const Text('Delete from Cloud', style: TextStyle(color: Color(0xFFFF453A))),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final dao = ref.read(filesDaoProvider);
                  await dao.deleteFile(file.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFile(CloudFile file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => FileViewerScreen(file: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subFoldersAsync = ref.watch(subFoldersStreamProvider(_currentFolder));

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: _currentFolder != '/'
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: _navigateUp,
              )
            : IconButton(
                icon: const Icon(Icons.photo_library_outlined, color: Color(0xFF0A84FF)),
                tooltip: 'Switch to Photos',
                onPressed: () => context.go('/'),
              ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search files and folders...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : Text(
                _currentFolder == '/' ? 'TeleCloud Files' : p.basename(_currentFolder),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs Navigation Bar
            if (!_isSearching) _buildBreadcrumbsBar(),

            // Main Explorer Content
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0A84FF),
                backgroundColor: const Color(0xFF1C1C1E),
                onRefresh: () async {
                  ref.invalidate(filesInFolderStreamProvider);
                  ref.invalidate(subFoldersStreamProvider);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // Sub-folders Section
                    if (!_isSearching)
                      subFoldersAsync.when(
                        data: (folders) {
                          if (folders.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FOLDERS (${folders.length})',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 48,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: folders.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                                      itemBuilder: (ctx, idx) {
                                        final folder = folders[idx];
                                        return InkWell(
                                          onTap: () => _navigateToFolder(folder.id),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1C1C1E),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.folder, color: Color(0xFFFF9F0A), size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  folder.folderName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                        error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                      ),

                    // Files Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        child: Text(
                          _searchQuery.isNotEmpty ? 'SEARCH RESULTS' : 'FILES',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),

                    // Files Content (Stream or Search)
                    StreamBuilder<List<CloudFile>>(
                      stream: _searchQuery.isNotEmpty
                          ? ref.watch(filesDaoProvider).searchFiles(_searchQuery)
                          : ref.watch(filesDaoProvider).watchFilesInFolder(_currentFolder),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
                            ),
                          );
                        }

                        final files = snapshot.data ?? [];

                        if (files.isEmpty) {
                          return SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey.shade700),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ? 'No matching files found' : 'No files in this folder',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap + to upload documents, archives or media',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (_isGridView) {
                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (ctx, idx) => _buildGridFileCard(files[idx]),
                                childCount: files.length,
                              ),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, idx) => _buildListFileTile(files[idx]),
                              childCount: files.length,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0A84FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showFabActions,
      ),
    );
  }

  Widget _buildBreadcrumbsBar() {
    final crumbs = _getBreadcrumbs();
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: crumbs.length,
        separatorBuilder: (_, __) => const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
        itemBuilder: (ctx, idx) {
          final crumb = crumbs[idx];
          final isLast = idx == crumbs.length - 1;
          return InkWell(
            onTap: () {
              if (idx == 0) {
                _navigateToFolder('/');
              } else {
                final targetPath = '/${crumbs.sublist(1, idx + 1).join('/')}';
                _navigateToFolder(targetPath);
              }
            },
            child: Center(
              child: Text(
                crumb,
                style: TextStyle(
                  color: isLast ? const Color(0xFF0A84FF) : Colors.grey.shade400,
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListFileTile(CloudFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        onTap: () => _openFile(file),
        leading: _buildFileIcon(file.fileName),
        title: Text(
          file.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            Text(
              _formatFileSize(file.fileSizeBytes),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              '·  ${_formatDate(file.modifiedAt)}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            if (file.isPinnedOffline) ...[
              const SizedBox(width: 8),
              const Icon(Icons.offline_pin, color: Color(0xFF30D158), size: 14),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
          onPressed: () => _showFileActions(file),
        ),
      ),
    );
  }

  Widget _buildGridFileCard(CloudFile file) {
    return InkWell(
      onTap: () => _openFile(file),
      onLongPress: () => _showFileActions(file),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildFileIcon(file.fileName, size: 32),
                const Spacer(),
                if (file.isPinnedOffline)
                  const Icon(Icons.offline_pin, color: Color(0xFF30D158), size: 16),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                  onPressed: () => _showFileActions(file),
                ),
              ],
            ),
            const Spacer(),
            Text(
              file.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _formatFileSize(file.fileSizeBytes),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(String fileName, {double size = 28}) {
    final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');
    IconData icon;
    Color color;

    switch (ext) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = const Color(0xFFFF453A);
        break;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'md':
        icon = Icons.description;
        color = const Color(0xFF0A84FF);
        break;
      case 'xls':
      case 'xlsx':
      case 'csv':
        icon = Icons.table_chart;
        color = const Color(0xFF30D158);
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        color = const Color(0xFFFF9F0A);
        break;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        icon = Icons.folder_zip;
        color = const Color(0xFFFFD60A);
        break;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
        icon = Icons.audio_file;
        color = const Color(0xFFBF5AF2);
        break;
      case 'mp4':
      case 'mkv':
      case 'mov':
      case 'avi':
        icon = Icons.video_file;
        color = const Color(0xFF64D2FF);
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        icon = Icons.image;
        color = const Color(0xFFFF375F);
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  void _showFabActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.upload_file, color: Color(0xFF0A84FF)),
                title: const Text('Upload Files to Cloud', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Pick any document, PDF, archive or media', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleUploadFiles();
                },
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined, color: Color(0xFFFF9F0A)),
                title: const Text('New Folder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Create a synchronized cloud folder & topic', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleCreateFolder();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync_alt, color: Color(0xFF30D158)),
                title: const Text('Sync Device Folders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Scan and sync Downloads & Documents folders', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleSyncDeviceFolders();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFileSize(BigInt bytes) {
    final b = bytes.toDouble();
    if (b >= 1073741824) return '${(b / 1073741824).toStringAsFixed(2)} GB';
    if (b >= 1048576) return '${(b / 1048576).toStringAsFixed(1)} MB';
    if (b >= 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${bytes.toInt()} B';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
