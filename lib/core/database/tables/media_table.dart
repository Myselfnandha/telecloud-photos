import 'package:drift/drift.dart';
import 'albums_table.dart';

enum UploadStatus { pending, uploading, done, failed }

@TableIndex(name: 'idx_captured_at', columns: {#capturedAt})
@TableIndex(name: 'idx_sha256_hash', columns: {#sha256Hash})
class MediaItems extends Table {
  TextColumn get localId => text()();
  IntColumn get telegramMsgId => integer().nullable()();
  TextColumn get telegramFileId => text().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get filename => text()();
  DateTimeColumn get capturedAt => dateTime()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get fileSizeBytes => integer().nullable()();
  TextColumn get mimeType => text()();
  IntColumn get uploadStatus => intEnum<UploadStatus>()();
  IntColumn get albumId => integer().nullable().references(Albums, #id)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isTrashed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get trashedAt => dateTime().nullable()();
  TextColumn get sha256Hash => text().nullable()();
  TextColumn get folderName => text().nullable()();
  TextColumn get folderPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}

