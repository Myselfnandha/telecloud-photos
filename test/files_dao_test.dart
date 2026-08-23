import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/database/app_database.dart';
import 'package:telecloud_photos/core/database/daos/files_dao.dart';
import 'package:telecloud_photos/core/database/tables/media_table.dart';

void main() {
  late AppDatabase db;
  late FilesDao filesDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    filesDao = FilesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('FilesDao — File & Folder Database Tests', () {
    test('1. Insert and watch folders hierarchy', () async {
      final now = DateTime.now();

      await filesDao.insertFolder(
        CloudFoldersCompanion(
          id: const Value('/Documents'),
          parentPath: const Value('/'),
          folderName: const Value('Documents'),
          topicId: const Value(101),
          createdAt: Value(now),
        ),
      );

      await filesDao.insertFolder(
        CloudFoldersCompanion(
          id: const Value('/Downloads'),
          parentPath: const Value('/'),
          folderName: const Value('Downloads'),
          topicId: const Value(102),
          createdAt: Value(now),
        ),
      );

      await filesDao.insertFolder(
        CloudFoldersCompanion(
          id: const Value('/Documents/Work'),
          parentPath: const Value('/Documents'),
          folderName: const Value('Work'),
          topicId: const Value(103),
          createdAt: Value(now),
        ),
      );

      // Root folders
      final rootFolders = await filesDao.watchSubFolders('/').first;
      expect(rootFolders.length, 2);
      expect(rootFolders.map((f) => f.folderName).toList(), ['Documents', 'Downloads']);

      // Sub-folders of /Documents
      final subFolders = await filesDao.watchSubFolders('/Documents').first;
      expect(subFolders.length, 1);
      expect(subFolders.first.folderName, 'Work');
    });

    test('2. Insert files, query by folder, and search by keyword', () async {
      final now = DateTime.now();

      final id1 = await filesDao.insertFile(
        CloudFilesCompanion(
          fileName: const Value('Financial_Report_2026.pdf'),
          fileSizeBytes: Value(BigInt.from(5242880)),
          mimeType: const Value('application/pdf'),
          folderPath: const Value('/Documents'),
          uploadStatus: const Value(UploadStatus.done),
          createdAt: Value(now),
          modifiedAt: Value(now),
        ),
      );

      final id2 = await filesDao.insertFile(
        CloudFilesCompanion(
          fileName: const Value('Project_Archive.zip'),
          fileSizeBytes: Value(BigInt.from(104857600)),
          mimeType: const Value('application/zip'),
          folderPath: const Value('/Documents'),
          uploadStatus: const Value(UploadStatus.done),
          createdAt: Value(now),
          modifiedAt: Value(now),
        ),
      );

      expect(id1, isPositive);
      expect(id2, isPositive);

      // Watch files in /Documents
      final docs = await filesDao.watchFilesInFolder('/Documents').first;
      expect(docs.length, 2);
      expect(docs.first.fileName, 'Financial_Report_2026.pdf');

      // Search by keyword
      final searchResults = await filesDao.searchFiles('Archive').first;
      expect(searchResults.length, 1);
      expect(searchResults.first.fileName, 'Project_Archive.zip');
    });

    test('3. Offline pinning toggle and watchPinnedFiles stream', () async {
      final now = DateTime.now();

      final id = await filesDao.insertFile(
        CloudFilesCompanion(
          fileName: const Value('Passport_Scan.pdf'),
          fileSizeBytes: Value(BigInt.from(2048000)),
          mimeType: const Value('application/pdf'),
          folderPath: const Value('/'),
          uploadStatus: const Value(UploadStatus.done),
          isPinnedOffline: const Value(false),
          createdAt: Value(now),
          modifiedAt: Value(now),
        ),
      );

      var pinnedList = await filesDao.watchPinnedFiles().first;
      expect(pinnedList.isEmpty, isTrue);

      // Pin for offline
      await filesDao.togglePinOffline(id, true);
      pinnedList = await filesDao.watchPinnedFiles().first;
      expect(pinnedList.length, 1);
      expect(pinnedList.first.isPinnedOffline, isTrue);

      // Unpin
      await filesDao.togglePinOffline(id, false);
      pinnedList = await filesDao.watchPinnedFiles().first;
      expect(pinnedList.isEmpty, isTrue);
    });

    test('4. Delete file and cascade folder delete', () async {
      final now = DateTime.now();

      await filesDao.insertFolder(
        CloudFoldersCompanion(
          id: const Value('/Archive'),
          parentPath: const Value('/'),
          folderName: const Value('Archive'),
          createdAt: Value(now),
        ),
      );

      final fileId = await filesDao.insertFile(
        CloudFilesCompanion(
          fileName: const Value('Old_Data.tar.gz'),
          fileSizeBytes: Value(BigInt.from(50000000)),
          mimeType: const Value('application/zip'),
          folderPath: const Value('/Archive'),
          uploadStatus: const Value(UploadStatus.done),
          createdAt: Value(now),
          modifiedAt: Value(now),
        ),
      );

      // Delete file directly
      await filesDao.deleteFile(fileId);
      final remaining = await filesDao.watchFilesInFolder('/Archive').first;
      expect(remaining.isEmpty, isTrue);

      // Delete folder
      await filesDao.deleteFolder('/Archive');
      final folders = await filesDao.getAllFolders();
      expect(folders.where((f) => f.id == '/Archive').isEmpty, isTrue);
    });
  });
}
