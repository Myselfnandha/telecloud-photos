import 'package:drift/drift.dart';
import '../tables/media_table.dart';
import '../tables/files_table.dart';
import '../app_database.dart';

part 'files_dao.g.dart';

@DriftAccessor(tables: [CloudFiles, CloudFolders])
class FilesDao extends DatabaseAccessor<AppDatabase> with _$FilesDaoMixin {
  FilesDao(super.db);

  Stream<List<CloudFile>> watchFilesInFolder(String folderPath) {
    return (select(cloudFiles)
          ..where((t) => t.folderPath.equals(folderPath))
          ..orderBy([(t) => OrderingTerm.asc(t.fileName)]))
        .watch();
  }

  Stream<List<CloudFolder>> watchSubFolders(String? parentPath) {
    if (parentPath == null || parentPath == '/') {
      return (select(cloudFolders)
            ..where((t) => t.parentPath.isNull() | t.parentPath.equals('/'))
            ..orderBy([(t) => OrderingTerm.asc(t.folderName)]))
          .watch();
    }
    return (select(cloudFolders)
          ..where((t) => t.parentPath.equals(parentPath))
          ..orderBy([(t) => OrderingTerm.asc(t.folderName)]))
        .watch();
  }

  Stream<List<CloudFile>> watchPinnedFiles() {
    return (select(cloudFiles)
          ..where((t) => t.isPinnedOffline.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.fileName)]))
        .watch();
  }

  Stream<List<CloudFile>> watchRecentFiles({int limit = 20}) {
    return (select(cloudFiles)
          ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)])
          ..limit(limit))
        .watch();
  }

  Stream<List<CloudFile>> searchFiles(String query) {
    return (select(cloudFiles)
          ..where((t) => t.fileName.like('%$query%'))
          ..orderBy([(t) => OrderingTerm.asc(t.fileName)]))
        .watch();
  }

  Future<List<CloudFile>> getPendingUploads() {
    return (select(cloudFiles)
          ..where((t) => t.uploadStatus.equals(UploadStatus.pending.index)))
        .get();
  }

  Future<int> insertFile(CloudFilesCompanion file) =>
      into(cloudFiles).insert(file);

  Future<void> insertFolder(CloudFoldersCompanion folder) =>
      into(cloudFolders).insertOnConflictUpdate(folder);

  Future<bool> updateFileStatus(
    int id,
    UploadStatus status, {
    int? telegramMsgId,
    String? telegramFileId,
  }) {
    return (update(cloudFiles)..where((t) => t.id.equals(id))).write(
      CloudFilesCompanion(
        uploadStatus: Value(status),
        telegramMsgId: telegramMsgId != null ? Value(telegramMsgId) : const Value.absent(),
        telegramFileId: telegramFileId != null ? Value(telegramFileId) : const Value.absent(),
        modifiedAt: Value(DateTime.now()),
      ),
    ).then((rows) => rows > 0);
  }

  Future<bool> togglePinOffline(int id, bool isPinned) {
    return (update(cloudFiles)..where((t) => t.id.equals(id))).write(
      CloudFilesCompanion(
        isPinnedOffline: Value(isPinned),
        modifiedAt: Value(DateTime.now()),
      ),
    ).then((rows) => rows > 0);
  }

  Future<int> deleteFile(int id) {
    return (delete(cloudFiles)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteFolder(String folderPath) async {
    // Delete files in this folder and subfolders
    await (delete(cloudFiles)
          ..where((t) => t.folderPath.equals(folderPath) | t.folderPath.like('$folderPath/%')))
        .go();
    return (delete(cloudFolders)
          ..where((t) => t.id.equals(folderPath) | t.parentPath.equals(folderPath)))
        .go();
  }

  Future<List<CloudFolder>> getAllFolders() => select(cloudFolders).get();
}
