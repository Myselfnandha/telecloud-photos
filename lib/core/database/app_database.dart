import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/media_table.dart';
import 'tables/albums_table.dart';
import 'tables/files_table.dart';
import 'daos/media_dao.dart';
import 'daos/files_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [MediaItems, Albums, CloudFiles, CloudFolders],
  daos: [MediaDao, FilesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(mediaItems, mediaItems.isFavorite);
        await m.addColumn(mediaItems, mediaItems.isTrashed);
        await m.addColumn(mediaItems, mediaItems.trashedAt);
      }
      if (from < 3) {
        await m.createTable(cloudFiles);
        await m.createTable(cloudFolders);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'telecloud_photos.db'));
    return NativeDatabase.createInBackground(file);
  });
}
