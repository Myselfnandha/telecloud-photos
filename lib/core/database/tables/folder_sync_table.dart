import 'package:drift/drift.dart';

class FolderSyncSettings extends Table {
  TextColumn get folderId => text()(); // Device bucket ID or unique folder identifier
  TextColumn get folderName => text()(); // Display name e.g. "Camera", "WhatsApp Images", "Screenshots"
  TextColumn get folderPath => text()(); // Absolute or relative filesystem path
  BoolColumn get isAutoBackupEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get mediaCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {folderId};
}
