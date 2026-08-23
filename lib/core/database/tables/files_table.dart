import 'package:drift/drift.dart';
import 'media_table.dart';

@TableIndex(name: 'idx_files_folder', columns: {#folderPath})
class CloudFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get localPath => text().nullable()();
  TextColumn get fileName => text()();
  Int64Column get fileSizeBytes => int64()();
  TextColumn get mimeType => text()();
  TextColumn get folderPath => text().withDefault(const Constant('/'))();
  IntColumn get telegramMsgId => integer().nullable()();
  TextColumn get telegramFileId => text().nullable()();
  IntColumn get topicId => integer().nullable()();
  BoolColumn get isPinnedOffline => boolean().withDefault(const Constant(false))();
  IntColumn get uploadStatus => intEnum<UploadStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
}

class CloudFolders extends Table {
  TextColumn get id => text()(); // Full path: e.g. "/Documents" or "/Work/Reports"
  TextColumn get parentPath => text().nullable()(); // Parent path: e.g. "/" or "/Work"
  TextColumn get folderName => text()();
  IntColumn get topicId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
