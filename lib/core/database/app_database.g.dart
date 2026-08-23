// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AlbumsTable extends Albums with TableInfo<$AlbumsTable, Album> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _telegramTopicIdMeta =
      const VerificationMeta('telegramTopicId');
  @override
  late final GeneratedColumn<int> telegramTopicId = GeneratedColumn<int>(
      'telegram_topic_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, telegramTopicId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(Insertable<Album> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('telegram_topic_id')) {
      context.handle(
          _telegramTopicIdMeta,
          telegramTopicId.isAcceptableOrUnknown(
              data['telegram_topic_id']!, _telegramTopicIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Album map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Album(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      telegramTopicId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}telegram_topic_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AlbumsTable createAlias(String alias) {
    return $AlbumsTable(attachedDatabase, alias);
  }
}

class Album extends DataClass implements Insertable<Album> {
  final int id;
  final String name;
  final int? telegramTopicId;
  final DateTime createdAt;
  const Album(
      {required this.id,
      required this.name,
      this.telegramTopicId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || telegramTopicId != null) {
      map['telegram_topic_id'] = Variable<int>(telegramTopicId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AlbumsCompanion toCompanion(bool nullToAbsent) {
    return AlbumsCompanion(
      id: Value(id),
      name: Value(name),
      telegramTopicId: telegramTopicId == null && nullToAbsent
          ? const Value.absent()
          : Value(telegramTopicId),
      createdAt: Value(createdAt),
    );
  }

  factory Album.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Album(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      telegramTopicId: serializer.fromJson<int?>(json['telegramTopicId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'telegramTopicId': serializer.toJson<int?>(telegramTopicId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Album copyWith(
          {int? id,
          String? name,
          Value<int?> telegramTopicId = const Value.absent(),
          DateTime? createdAt}) =>
      Album(
        id: id ?? this.id,
        name: name ?? this.name,
        telegramTopicId: telegramTopicId.present
            ? telegramTopicId.value
            : this.telegramTopicId,
        createdAt: createdAt ?? this.createdAt,
      );
  Album copyWithCompanion(AlbumsCompanion data) {
    return Album(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      telegramTopicId: data.telegramTopicId.present
          ? data.telegramTopicId.value
          : this.telegramTopicId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Album(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('telegramTopicId: $telegramTopicId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, telegramTopicId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Album &&
          other.id == this.id &&
          other.name == this.name &&
          other.telegramTopicId == this.telegramTopicId &&
          other.createdAt == this.createdAt);
}

class AlbumsCompanion extends UpdateCompanion<Album> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> telegramTopicId;
  final Value<DateTime> createdAt;
  const AlbumsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.telegramTopicId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AlbumsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.telegramTopicId = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Album> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? telegramTopicId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (telegramTopicId != null) 'telegram_topic_id': telegramTopicId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AlbumsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int?>? telegramTopicId,
      Value<DateTime>? createdAt}) {
    return AlbumsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      telegramTopicId: telegramTopicId ?? this.telegramTopicId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (telegramTopicId.present) {
      map['telegram_topic_id'] = Variable<int>(telegramTopicId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('telegramTopicId: $telegramTopicId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _telegramMsgIdMeta =
      const VerificationMeta('telegramMsgId');
  @override
  late final GeneratedColumn<int> telegramMsgId = GeneratedColumn<int>(
      'telegram_msg_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _telegramFileIdMeta =
      const VerificationMeta('telegramFileId');
  @override
  late final GeneratedColumn<String> telegramFileId = GeneratedColumn<String>(
      'telegram_file_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _filenameMeta =
      const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
      'filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _capturedAtMeta =
      const VerificationMeta('capturedAt');
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
      'captured_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<UploadStatus, int> uploadStatus =
      GeneratedColumn<int>('upload_status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<UploadStatus>($MediaItemsTable.$converteruploadStatus);
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
      'album_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES albums (id)'));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isTrashedMeta =
      const VerificationMeta('isTrashed');
  @override
  late final GeneratedColumn<bool> isTrashed = GeneratedColumn<bool>(
      'is_trashed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_trashed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _trashedAtMeta =
      const VerificationMeta('trashedAt');
  @override
  late final GeneratedColumn<DateTime> trashedAt = GeneratedColumn<DateTime>(
      'trashed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        telegramMsgId,
        telegramFileId,
        thumbnailPath,
        filename,
        capturedAt,
        width,
        height,
        latitude,
        longitude,
        fileSizeBytes,
        mimeType,
        uploadStatus,
        albumId,
        isFavorite,
        isTrashed,
        trashedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(Insertable<MediaItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('telegram_msg_id')) {
      context.handle(
          _telegramMsgIdMeta,
          telegramMsgId.isAcceptableOrUnknown(
              data['telegram_msg_id']!, _telegramMsgIdMeta));
    }
    if (data.containsKey('telegram_file_id')) {
      context.handle(
          _telegramFileIdMeta,
          telegramFileId.isAcceptableOrUnknown(
              data['telegram_file_id']!, _telegramFileIdMeta));
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
          _capturedAtMeta,
          capturedAt.isAcceptableOrUnknown(
              data['captured_at']!, _capturedAtMeta));
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('is_trashed')) {
      context.handle(_isTrashedMeta,
          isTrashed.isAcceptableOrUnknown(data['is_trashed']!, _isTrashedMeta));
    }
    if (data.containsKey('trashed_at')) {
      context.handle(_trashedAtMeta,
          trashedAt.isAcceptableOrUnknown(data['trashed_at']!, _trashedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  MediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItem(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      telegramMsgId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}telegram_msg_id']),
      telegramFileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}telegram_file_id']),
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      filename: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filename'])!,
      capturedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}captured_at'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes']),
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      uploadStatus: $MediaItemsTable.$converteruploadStatus.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}upload_status'])!),
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}album_id']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      isTrashed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_trashed'])!,
      trashedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}trashed_at']),
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UploadStatus, int, int> $converteruploadStatus =
      const EnumIndexConverter<UploadStatus>(UploadStatus.values);
}

class MediaItem extends DataClass implements Insertable<MediaItem> {
  final String localId;
  final int? telegramMsgId;
  final String? telegramFileId;
  final String? thumbnailPath;
  final String filename;
  final DateTime capturedAt;
  final int? width;
  final int? height;
  final double? latitude;
  final double? longitude;
  final int? fileSizeBytes;
  final String mimeType;
  final UploadStatus uploadStatus;
  final int? albumId;
  final bool isFavorite;
  final bool isTrashed;
  final DateTime? trashedAt;
  const MediaItem(
      {required this.localId,
      this.telegramMsgId,
      this.telegramFileId,
      this.thumbnailPath,
      required this.filename,
      required this.capturedAt,
      this.width,
      this.height,
      this.latitude,
      this.longitude,
      this.fileSizeBytes,
      required this.mimeType,
      required this.uploadStatus,
      this.albumId,
      required this.isFavorite,
      required this.isTrashed,
      this.trashedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || telegramMsgId != null) {
      map['telegram_msg_id'] = Variable<int>(telegramMsgId);
    }
    if (!nullToAbsent || telegramFileId != null) {
      map['telegram_file_id'] = Variable<String>(telegramFileId);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['filename'] = Variable<String>(filename);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || fileSizeBytes != null) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    }
    map['mime_type'] = Variable<String>(mimeType);
    {
      map['upload_status'] = Variable<int>(
          $MediaItemsTable.$converteruploadStatus.toSql(uploadStatus));
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<int>(albumId);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_trashed'] = Variable<bool>(isTrashed);
    if (!nullToAbsent || trashedAt != null) {
      map['trashed_at'] = Variable<DateTime>(trashedAt);
    }
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      localId: Value(localId),
      telegramMsgId: telegramMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(telegramMsgId),
      telegramFileId: telegramFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(telegramFileId),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      filename: Value(filename),
      capturedAt: Value(capturedAt),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      fileSizeBytes: fileSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSizeBytes),
      mimeType: Value(mimeType),
      uploadStatus: Value(uploadStatus),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      isFavorite: Value(isFavorite),
      isTrashed: Value(isTrashed),
      trashedAt: trashedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(trashedAt),
    );
  }

  factory MediaItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItem(
      localId: serializer.fromJson<String>(json['localId']),
      telegramMsgId: serializer.fromJson<int?>(json['telegramMsgId']),
      telegramFileId: serializer.fromJson<String?>(json['telegramFileId']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      filename: serializer.fromJson<String>(json['filename']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      fileSizeBytes: serializer.fromJson<int?>(json['fileSizeBytes']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      uploadStatus: $MediaItemsTable.$converteruploadStatus
          .fromJson(serializer.fromJson<int>(json['uploadStatus'])),
      albumId: serializer.fromJson<int?>(json['albumId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isTrashed: serializer.fromJson<bool>(json['isTrashed']),
      trashedAt: serializer.fromJson<DateTime?>(json['trashedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'telegramMsgId': serializer.toJson<int?>(telegramMsgId),
      'telegramFileId': serializer.toJson<String?>(telegramFileId),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'filename': serializer.toJson<String>(filename),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'fileSizeBytes': serializer.toJson<int?>(fileSizeBytes),
      'mimeType': serializer.toJson<String>(mimeType),
      'uploadStatus': serializer.toJson<int>(
          $MediaItemsTable.$converteruploadStatus.toJson(uploadStatus)),
      'albumId': serializer.toJson<int?>(albumId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isTrashed': serializer.toJson<bool>(isTrashed),
      'trashedAt': serializer.toJson<DateTime?>(trashedAt),
    };
  }

  MediaItem copyWith(
          {String? localId,
          Value<int?> telegramMsgId = const Value.absent(),
          Value<String?> telegramFileId = const Value.absent(),
          Value<String?> thumbnailPath = const Value.absent(),
          String? filename,
          DateTime? capturedAt,
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          Value<int?> fileSizeBytes = const Value.absent(),
          String? mimeType,
          UploadStatus? uploadStatus,
          Value<int?> albumId = const Value.absent(),
          bool? isFavorite,
          bool? isTrashed,
          Value<DateTime?> trashedAt = const Value.absent()}) =>
      MediaItem(
        localId: localId ?? this.localId,
        telegramMsgId:
            telegramMsgId.present ? telegramMsgId.value : this.telegramMsgId,
        telegramFileId:
            telegramFileId.present ? telegramFileId.value : this.telegramFileId,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        filename: filename ?? this.filename,
        capturedAt: capturedAt ?? this.capturedAt,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        fileSizeBytes:
            fileSizeBytes.present ? fileSizeBytes.value : this.fileSizeBytes,
        mimeType: mimeType ?? this.mimeType,
        uploadStatus: uploadStatus ?? this.uploadStatus,
        albumId: albumId.present ? albumId.value : this.albumId,
        isFavorite: isFavorite ?? this.isFavorite,
        isTrashed: isTrashed ?? this.isTrashed,
        trashedAt: trashedAt.present ? trashedAt.value : this.trashedAt,
      );
  MediaItem copyWithCompanion(MediaItemsCompanion data) {
    return MediaItem(
      localId: data.localId.present ? data.localId.value : this.localId,
      telegramMsgId: data.telegramMsgId.present
          ? data.telegramMsgId.value
          : this.telegramMsgId,
      telegramFileId: data.telegramFileId.present
          ? data.telegramFileId.value
          : this.telegramFileId,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      filename: data.filename.present ? data.filename.value : this.filename,
      capturedAt:
          data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      uploadStatus: data.uploadStatus.present
          ? data.uploadStatus.value
          : this.uploadStatus,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      isTrashed: data.isTrashed.present ? data.isTrashed.value : this.isTrashed,
      trashedAt: data.trashedAt.present ? data.trashedAt.value : this.trashedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItem(')
          ..write('localId: $localId, ')
          ..write('telegramMsgId: $telegramMsgId, ')
          ..write('telegramFileId: $telegramFileId, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('filename: $filename, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('albumId: $albumId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isTrashed: $isTrashed, ')
          ..write('trashedAt: $trashedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      telegramMsgId,
      telegramFileId,
      thumbnailPath,
      filename,
      capturedAt,
      width,
      height,
      latitude,
      longitude,
      fileSizeBytes,
      mimeType,
      uploadStatus,
      albumId,
      isFavorite,
      isTrashed,
      trashedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItem &&
          other.localId == this.localId &&
          other.telegramMsgId == this.telegramMsgId &&
          other.telegramFileId == this.telegramFileId &&
          other.thumbnailPath == this.thumbnailPath &&
          other.filename == this.filename &&
          other.capturedAt == this.capturedAt &&
          other.width == this.width &&
          other.height == this.height &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.mimeType == this.mimeType &&
          other.uploadStatus == this.uploadStatus &&
          other.albumId == this.albumId &&
          other.isFavorite == this.isFavorite &&
          other.isTrashed == this.isTrashed &&
          other.trashedAt == this.trashedAt);
}

class MediaItemsCompanion extends UpdateCompanion<MediaItem> {
  final Value<String> localId;
  final Value<int?> telegramMsgId;
  final Value<String?> telegramFileId;
  final Value<String?> thumbnailPath;
  final Value<String> filename;
  final Value<DateTime> capturedAt;
  final Value<int?> width;
  final Value<int?> height;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<int?> fileSizeBytes;
  final Value<String> mimeType;
  final Value<UploadStatus> uploadStatus;
  final Value<int?> albumId;
  final Value<bool> isFavorite;
  final Value<bool> isTrashed;
  final Value<DateTime?> trashedAt;
  final Value<int> rowid;
  const MediaItemsCompanion({
    this.localId = const Value.absent(),
    this.telegramMsgId = const Value.absent(),
    this.telegramFileId = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.filename = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.albumId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isTrashed = const Value.absent(),
    this.trashedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    required String localId,
    this.telegramMsgId = const Value.absent(),
    this.telegramFileId = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    required String filename,
    required DateTime capturedAt,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    required String mimeType,
    required UploadStatus uploadStatus,
    this.albumId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isTrashed = const Value.absent(),
    this.trashedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        filename = Value(filename),
        capturedAt = Value(capturedAt),
        mimeType = Value(mimeType),
        uploadStatus = Value(uploadStatus);
  static Insertable<MediaItem> custom({
    Expression<String>? localId,
    Expression<int>? telegramMsgId,
    Expression<String>? telegramFileId,
    Expression<String>? thumbnailPath,
    Expression<String>? filename,
    Expression<DateTime>? capturedAt,
    Expression<int>? width,
    Expression<int>? height,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? fileSizeBytes,
    Expression<String>? mimeType,
    Expression<int>? uploadStatus,
    Expression<int>? albumId,
    Expression<bool>? isFavorite,
    Expression<bool>? isTrashed,
    Expression<DateTime>? trashedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (telegramMsgId != null) 'telegram_msg_id': telegramMsgId,
      if (telegramFileId != null) 'telegram_file_id': telegramFileId,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (filename != null) 'filename': filename,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (albumId != null) 'album_id': albumId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isTrashed != null) 'is_trashed': isTrashed,
      if (trashedAt != null) 'trashed_at': trashedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaItemsCompanion copyWith(
      {Value<String>? localId,
      Value<int?>? telegramMsgId,
      Value<String?>? telegramFileId,
      Value<String?>? thumbnailPath,
      Value<String>? filename,
      Value<DateTime>? capturedAt,
      Value<int?>? width,
      Value<int?>? height,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<int?>? fileSizeBytes,
      Value<String>? mimeType,
      Value<UploadStatus>? uploadStatus,
      Value<int?>? albumId,
      Value<bool>? isFavorite,
      Value<bool>? isTrashed,
      Value<DateTime?>? trashedAt,
      Value<int>? rowid}) {
    return MediaItemsCompanion(
      localId: localId ?? this.localId,
      telegramMsgId: telegramMsgId ?? this.telegramMsgId,
      telegramFileId: telegramFileId ?? this.telegramFileId,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      filename: filename ?? this.filename,
      capturedAt: capturedAt ?? this.capturedAt,
      width: width ?? this.width,
      height: height ?? this.height,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      albumId: albumId ?? this.albumId,
      isFavorite: isFavorite ?? this.isFavorite,
      isTrashed: isTrashed ?? this.isTrashed,
      trashedAt: trashedAt ?? this.trashedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (telegramMsgId.present) {
      map['telegram_msg_id'] = Variable<int>(telegramMsgId.value);
    }
    if (telegramFileId.present) {
      map['telegram_file_id'] = Variable<String>(telegramFileId.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (uploadStatus.present) {
      map['upload_status'] = Variable<int>(
          $MediaItemsTable.$converteruploadStatus.toSql(uploadStatus.value));
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isTrashed.present) {
      map['is_trashed'] = Variable<bool>(isTrashed.value);
    }
    if (trashedAt.present) {
      map['trashed_at'] = Variable<DateTime>(trashedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('localId: $localId, ')
          ..write('telegramMsgId: $telegramMsgId, ')
          ..write('telegramFileId: $telegramFileId, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('filename: $filename, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('albumId: $albumId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isTrashed: $isTrashed, ')
          ..write('trashedAt: $trashedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CloudFilesTable extends CloudFiles
    with TableInfo<$CloudFilesTable, CloudFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CloudFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<BigInt> fileSizeBytes = GeneratedColumn<BigInt>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _folderPathMeta =
      const VerificationMeta('folderPath');
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
      'folder_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('/'));
  static const VerificationMeta _telegramMsgIdMeta =
      const VerificationMeta('telegramMsgId');
  @override
  late final GeneratedColumn<int> telegramMsgId = GeneratedColumn<int>(
      'telegram_msg_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _telegramFileIdMeta =
      const VerificationMeta('telegramFileId');
  @override
  late final GeneratedColumn<String> telegramFileId = GeneratedColumn<String>(
      'telegram_file_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _topicIdMeta =
      const VerificationMeta('topicId');
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
      'topic_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isPinnedOfflineMeta =
      const VerificationMeta('isPinnedOffline');
  @override
  late final GeneratedColumn<bool> isPinnedOffline = GeneratedColumn<bool>(
      'is_pinned_offline', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_pinned_offline" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  late final GeneratedColumnWithTypeConverter<UploadStatus, int> uploadStatus =
      GeneratedColumn<int>('upload_status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<UploadStatus>($CloudFilesTable.$converteruploadStatus);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _modifiedAtMeta =
      const VerificationMeta('modifiedAt');
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
      'modified_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        localPath,
        fileName,
        fileSizeBytes,
        mimeType,
        folderPath,
        telegramMsgId,
        telegramFileId,
        topicId,
        isPinnedOffline,
        uploadStatus,
        createdAt,
        modifiedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloud_files';
  @override
  VerificationContext validateIntegrity(Insertable<CloudFile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('folder_path')) {
      context.handle(
          _folderPathMeta,
          folderPath.isAcceptableOrUnknown(
              data['folder_path']!, _folderPathMeta));
    }
    if (data.containsKey('telegram_msg_id')) {
      context.handle(
          _telegramMsgIdMeta,
          telegramMsgId.isAcceptableOrUnknown(
              data['telegram_msg_id']!, _telegramMsgIdMeta));
    }
    if (data.containsKey('telegram_file_id')) {
      context.handle(
          _telegramFileIdMeta,
          telegramFileId.isAcceptableOrUnknown(
              data['telegram_file_id']!, _telegramFileIdMeta));
    }
    if (data.containsKey('topic_id')) {
      context.handle(_topicIdMeta,
          topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta));
    }
    if (data.containsKey('is_pinned_offline')) {
      context.handle(
          _isPinnedOfflineMeta,
          isPinnedOffline.isAcceptableOrUnknown(
              data['is_pinned_offline']!, _isPinnedOfflineMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
          _modifiedAtMeta,
          modifiedAt.isAcceptableOrUnknown(
              data['modified_at']!, _modifiedAtMeta));
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CloudFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CloudFile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
          DriftSqlType.bigInt, data['${effectivePrefix}file_size_bytes'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      folderPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_path'])!,
      telegramMsgId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}telegram_msg_id']),
      telegramFileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}telegram_file_id']),
      topicId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}topic_id']),
      isPinnedOffline: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_pinned_offline'])!,
      uploadStatus: $CloudFilesTable.$converteruploadStatus.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}upload_status'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      modifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}modified_at'])!,
    );
  }

  @override
  $CloudFilesTable createAlias(String alias) {
    return $CloudFilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UploadStatus, int, int> $converteruploadStatus =
      const EnumIndexConverter<UploadStatus>(UploadStatus.values);
}

class CloudFile extends DataClass implements Insertable<CloudFile> {
  final int id;
  final String? localPath;
  final String fileName;
  final BigInt fileSizeBytes;
  final String mimeType;
  final String folderPath;
  final int? telegramMsgId;
  final String? telegramFileId;
  final int? topicId;
  final bool isPinnedOffline;
  final UploadStatus uploadStatus;
  final DateTime createdAt;
  final DateTime modifiedAt;
  const CloudFile(
      {required this.id,
      this.localPath,
      required this.fileName,
      required this.fileSizeBytes,
      required this.mimeType,
      required this.folderPath,
      this.telegramMsgId,
      this.telegramFileId,
      this.topicId,
      required this.isPinnedOffline,
      required this.uploadStatus,
      required this.createdAt,
      required this.modifiedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['file_name'] = Variable<String>(fileName);
    map['file_size_bytes'] = Variable<BigInt>(fileSizeBytes);
    map['mime_type'] = Variable<String>(mimeType);
    map['folder_path'] = Variable<String>(folderPath);
    if (!nullToAbsent || telegramMsgId != null) {
      map['telegram_msg_id'] = Variable<int>(telegramMsgId);
    }
    if (!nullToAbsent || telegramFileId != null) {
      map['telegram_file_id'] = Variable<String>(telegramFileId);
    }
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<int>(topicId);
    }
    map['is_pinned_offline'] = Variable<bool>(isPinnedOffline);
    {
      map['upload_status'] = Variable<int>(
          $CloudFilesTable.$converteruploadStatus.toSql(uploadStatus));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    return map;
  }

  CloudFilesCompanion toCompanion(bool nullToAbsent) {
    return CloudFilesCompanion(
      id: Value(id),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      fileName: Value(fileName),
      fileSizeBytes: Value(fileSizeBytes),
      mimeType: Value(mimeType),
      folderPath: Value(folderPath),
      telegramMsgId: telegramMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(telegramMsgId),
      telegramFileId: telegramFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(telegramFileId),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      isPinnedOffline: Value(isPinnedOffline),
      uploadStatus: Value(uploadStatus),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
    );
  }

  factory CloudFile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CloudFile(
      id: serializer.fromJson<int>(json['id']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileSizeBytes: serializer.fromJson<BigInt>(json['fileSizeBytes']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      telegramMsgId: serializer.fromJson<int?>(json['telegramMsgId']),
      telegramFileId: serializer.fromJson<String?>(json['telegramFileId']),
      topicId: serializer.fromJson<int?>(json['topicId']),
      isPinnedOffline: serializer.fromJson<bool>(json['isPinnedOffline']),
      uploadStatus: $CloudFilesTable.$converteruploadStatus
          .fromJson(serializer.fromJson<int>(json['uploadStatus'])),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localPath': serializer.toJson<String?>(localPath),
      'fileName': serializer.toJson<String>(fileName),
      'fileSizeBytes': serializer.toJson<BigInt>(fileSizeBytes),
      'mimeType': serializer.toJson<String>(mimeType),
      'folderPath': serializer.toJson<String>(folderPath),
      'telegramMsgId': serializer.toJson<int?>(telegramMsgId),
      'telegramFileId': serializer.toJson<String?>(telegramFileId),
      'topicId': serializer.toJson<int?>(topicId),
      'isPinnedOffline': serializer.toJson<bool>(isPinnedOffline),
      'uploadStatus': serializer.toJson<int>(
          $CloudFilesTable.$converteruploadStatus.toJson(uploadStatus)),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
    };
  }

  CloudFile copyWith(
          {int? id,
          Value<String?> localPath = const Value.absent(),
          String? fileName,
          BigInt? fileSizeBytes,
          String? mimeType,
          String? folderPath,
          Value<int?> telegramMsgId = const Value.absent(),
          Value<String?> telegramFileId = const Value.absent(),
          Value<int?> topicId = const Value.absent(),
          bool? isPinnedOffline,
          UploadStatus? uploadStatus,
          DateTime? createdAt,
          DateTime? modifiedAt}) =>
      CloudFile(
        id: id ?? this.id,
        localPath: localPath.present ? localPath.value : this.localPath,
        fileName: fileName ?? this.fileName,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        mimeType: mimeType ?? this.mimeType,
        folderPath: folderPath ?? this.folderPath,
        telegramMsgId:
            telegramMsgId.present ? telegramMsgId.value : this.telegramMsgId,
        telegramFileId:
            telegramFileId.present ? telegramFileId.value : this.telegramFileId,
        topicId: topicId.present ? topicId.value : this.topicId,
        isPinnedOffline: isPinnedOffline ?? this.isPinnedOffline,
        uploadStatus: uploadStatus ?? this.uploadStatus,
        createdAt: createdAt ?? this.createdAt,
        modifiedAt: modifiedAt ?? this.modifiedAt,
      );
  CloudFile copyWithCompanion(CloudFilesCompanion data) {
    return CloudFile(
      id: data.id.present ? data.id.value : this.id,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      folderPath:
          data.folderPath.present ? data.folderPath.value : this.folderPath,
      telegramMsgId: data.telegramMsgId.present
          ? data.telegramMsgId.value
          : this.telegramMsgId,
      telegramFileId: data.telegramFileId.present
          ? data.telegramFileId.value
          : this.telegramFileId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      isPinnedOffline: data.isPinnedOffline.present
          ? data.isPinnedOffline.value
          : this.isPinnedOffline,
      uploadStatus: data.uploadStatus.present
          ? data.uploadStatus.value
          : this.uploadStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt:
          data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CloudFile(')
          ..write('id: $id, ')
          ..write('localPath: $localPath, ')
          ..write('fileName: $fileName, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('folderPath: $folderPath, ')
          ..write('telegramMsgId: $telegramMsgId, ')
          ..write('telegramFileId: $telegramFileId, ')
          ..write('topicId: $topicId, ')
          ..write('isPinnedOffline: $isPinnedOffline, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      localPath,
      fileName,
      fileSizeBytes,
      mimeType,
      folderPath,
      telegramMsgId,
      telegramFileId,
      topicId,
      isPinnedOffline,
      uploadStatus,
      createdAt,
      modifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CloudFile &&
          other.id == this.id &&
          other.localPath == this.localPath &&
          other.fileName == this.fileName &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.mimeType == this.mimeType &&
          other.folderPath == this.folderPath &&
          other.telegramMsgId == this.telegramMsgId &&
          other.telegramFileId == this.telegramFileId &&
          other.topicId == this.topicId &&
          other.isPinnedOffline == this.isPinnedOffline &&
          other.uploadStatus == this.uploadStatus &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt);
}

class CloudFilesCompanion extends UpdateCompanion<CloudFile> {
  final Value<int> id;
  final Value<String?> localPath;
  final Value<String> fileName;
  final Value<BigInt> fileSizeBytes;
  final Value<String> mimeType;
  final Value<String> folderPath;
  final Value<int?> telegramMsgId;
  final Value<String?> telegramFileId;
  final Value<int?> topicId;
  final Value<bool> isPinnedOffline;
  final Value<UploadStatus> uploadStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  const CloudFilesCompanion({
    this.id = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.telegramMsgId = const Value.absent(),
    this.telegramFileId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.isPinnedOffline = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
  });
  CloudFilesCompanion.insert({
    this.id = const Value.absent(),
    this.localPath = const Value.absent(),
    required String fileName,
    required BigInt fileSizeBytes,
    required String mimeType,
    this.folderPath = const Value.absent(),
    this.telegramMsgId = const Value.absent(),
    this.telegramFileId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.isPinnedOffline = const Value.absent(),
    required UploadStatus uploadStatus,
    required DateTime createdAt,
    required DateTime modifiedAt,
  })  : fileName = Value(fileName),
        fileSizeBytes = Value(fileSizeBytes),
        mimeType = Value(mimeType),
        uploadStatus = Value(uploadStatus),
        createdAt = Value(createdAt),
        modifiedAt = Value(modifiedAt);
  static Insertable<CloudFile> custom({
    Expression<int>? id,
    Expression<String>? localPath,
    Expression<String>? fileName,
    Expression<BigInt>? fileSizeBytes,
    Expression<String>? mimeType,
    Expression<String>? folderPath,
    Expression<int>? telegramMsgId,
    Expression<String>? telegramFileId,
    Expression<int>? topicId,
    Expression<bool>? isPinnedOffline,
    Expression<int>? uploadStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localPath != null) 'local_path': localPath,
      if (fileName != null) 'file_name': fileName,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (folderPath != null) 'folder_path': folderPath,
      if (telegramMsgId != null) 'telegram_msg_id': telegramMsgId,
      if (telegramFileId != null) 'telegram_file_id': telegramFileId,
      if (topicId != null) 'topic_id': topicId,
      if (isPinnedOffline != null) 'is_pinned_offline': isPinnedOffline,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
    });
  }

  CloudFilesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? localPath,
      Value<String>? fileName,
      Value<BigInt>? fileSizeBytes,
      Value<String>? mimeType,
      Value<String>? folderPath,
      Value<int?>? telegramMsgId,
      Value<String?>? telegramFileId,
      Value<int?>? topicId,
      Value<bool>? isPinnedOffline,
      Value<UploadStatus>? uploadStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? modifiedAt}) {
    return CloudFilesCompanion(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      folderPath: folderPath ?? this.folderPath,
      telegramMsgId: telegramMsgId ?? this.telegramMsgId,
      telegramFileId: telegramFileId ?? this.telegramFileId,
      topicId: topicId ?? this.topicId,
      isPinnedOffline: isPinnedOffline ?? this.isPinnedOffline,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<BigInt>(fileSizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (telegramMsgId.present) {
      map['telegram_msg_id'] = Variable<int>(telegramMsgId.value);
    }
    if (telegramFileId.present) {
      map['telegram_file_id'] = Variable<String>(telegramFileId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (isPinnedOffline.present) {
      map['is_pinned_offline'] = Variable<bool>(isPinnedOffline.value);
    }
    if (uploadStatus.present) {
      map['upload_status'] = Variable<int>(
          $CloudFilesTable.$converteruploadStatus.toSql(uploadStatus.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CloudFilesCompanion(')
          ..write('id: $id, ')
          ..write('localPath: $localPath, ')
          ..write('fileName: $fileName, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('folderPath: $folderPath, ')
          ..write('telegramMsgId: $telegramMsgId, ')
          ..write('telegramFileId: $telegramFileId, ')
          ..write('topicId: $topicId, ')
          ..write('isPinnedOffline: $isPinnedOffline, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt')
          ..write(')'))
        .toString();
  }
}

class $CloudFoldersTable extends CloudFolders
    with TableInfo<$CloudFoldersTable, CloudFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CloudFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentPathMeta =
      const VerificationMeta('parentPath');
  @override
  late final GeneratedColumn<String> parentPath = GeneratedColumn<String>(
      'parent_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _folderNameMeta =
      const VerificationMeta('folderName');
  @override
  late final GeneratedColumn<String> folderName = GeneratedColumn<String>(
      'folder_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _topicIdMeta =
      const VerificationMeta('topicId');
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
      'topic_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, parentPath, folderName, topicId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloud_folders';
  @override
  VerificationContext validateIntegrity(Insertable<CloudFolder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_path')) {
      context.handle(
          _parentPathMeta,
          parentPath.isAcceptableOrUnknown(
              data['parent_path']!, _parentPathMeta));
    }
    if (data.containsKey('folder_name')) {
      context.handle(
          _folderNameMeta,
          folderName.isAcceptableOrUnknown(
              data['folder_name']!, _folderNameMeta));
    } else if (isInserting) {
      context.missing(_folderNameMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(_topicIdMeta,
          topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CloudFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CloudFolder(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      parentPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_path']),
      folderName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_name'])!,
      topicId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}topic_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CloudFoldersTable createAlias(String alias) {
    return $CloudFoldersTable(attachedDatabase, alias);
  }
}

class CloudFolder extends DataClass implements Insertable<CloudFolder> {
  final String id;
  final String? parentPath;
  final String folderName;
  final int? topicId;
  final DateTime createdAt;
  const CloudFolder(
      {required this.id,
      this.parentPath,
      required this.folderName,
      this.topicId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentPath != null) {
      map['parent_path'] = Variable<String>(parentPath);
    }
    map['folder_name'] = Variable<String>(folderName);
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<int>(topicId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CloudFoldersCompanion toCompanion(bool nullToAbsent) {
    return CloudFoldersCompanion(
      id: Value(id),
      parentPath: parentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(parentPath),
      folderName: Value(folderName),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      createdAt: Value(createdAt),
    );
  }

  factory CloudFolder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CloudFolder(
      id: serializer.fromJson<String>(json['id']),
      parentPath: serializer.fromJson<String?>(json['parentPath']),
      folderName: serializer.fromJson<String>(json['folderName']),
      topicId: serializer.fromJson<int?>(json['topicId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentPath': serializer.toJson<String?>(parentPath),
      'folderName': serializer.toJson<String>(folderName),
      'topicId': serializer.toJson<int?>(topicId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CloudFolder copyWith(
          {String? id,
          Value<String?> parentPath = const Value.absent(),
          String? folderName,
          Value<int?> topicId = const Value.absent(),
          DateTime? createdAt}) =>
      CloudFolder(
        id: id ?? this.id,
        parentPath: parentPath.present ? parentPath.value : this.parentPath,
        folderName: folderName ?? this.folderName,
        topicId: topicId.present ? topicId.value : this.topicId,
        createdAt: createdAt ?? this.createdAt,
      );
  CloudFolder copyWithCompanion(CloudFoldersCompanion data) {
    return CloudFolder(
      id: data.id.present ? data.id.value : this.id,
      parentPath:
          data.parentPath.present ? data.parentPath.value : this.parentPath,
      folderName:
          data.folderName.present ? data.folderName.value : this.folderName,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CloudFolder(')
          ..write('id: $id, ')
          ..write('parentPath: $parentPath, ')
          ..write('folderName: $folderName, ')
          ..write('topicId: $topicId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, parentPath, folderName, topicId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CloudFolder &&
          other.id == this.id &&
          other.parentPath == this.parentPath &&
          other.folderName == this.folderName &&
          other.topicId == this.topicId &&
          other.createdAt == this.createdAt);
}

class CloudFoldersCompanion extends UpdateCompanion<CloudFolder> {
  final Value<String> id;
  final Value<String?> parentPath;
  final Value<String> folderName;
  final Value<int?> topicId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CloudFoldersCompanion({
    this.id = const Value.absent(),
    this.parentPath = const Value.absent(),
    this.folderName = const Value.absent(),
    this.topicId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CloudFoldersCompanion.insert({
    required String id,
    this.parentPath = const Value.absent(),
    required String folderName,
    this.topicId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        folderName = Value(folderName),
        createdAt = Value(createdAt);
  static Insertable<CloudFolder> custom({
    Expression<String>? id,
    Expression<String>? parentPath,
    Expression<String>? folderName,
    Expression<int>? topicId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentPath != null) 'parent_path': parentPath,
      if (folderName != null) 'folder_name': folderName,
      if (topicId != null) 'topic_id': topicId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CloudFoldersCompanion copyWith(
      {Value<String>? id,
      Value<String?>? parentPath,
      Value<String>? folderName,
      Value<int?>? topicId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return CloudFoldersCompanion(
      id: id ?? this.id,
      parentPath: parentPath ?? this.parentPath,
      folderName: folderName ?? this.folderName,
      topicId: topicId ?? this.topicId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentPath.present) {
      map['parent_path'] = Variable<String>(parentPath.value);
    }
    if (folderName.present) {
      map['folder_name'] = Variable<String>(folderName.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CloudFoldersCompanion(')
          ..write('id: $id, ')
          ..write('parentPath: $parentPath, ')
          ..write('folderName: $folderName, ')
          ..write('topicId: $topicId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AlbumsTable albums = $AlbumsTable(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $CloudFilesTable cloudFiles = $CloudFilesTable(this);
  late final $CloudFoldersTable cloudFolders = $CloudFoldersTable(this);
  late final Index idxCapturedAt = Index('idx_captured_at',
      'CREATE INDEX idx_captured_at ON media_items (captured_at)');
  late final Index idxFilesFolder = Index('idx_files_folder',
      'CREATE INDEX idx_files_folder ON cloud_files (folder_path)');
  late final MediaDao mediaDao = MediaDao(this as AppDatabase);
  late final FilesDao filesDao = FilesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        albums,
        mediaItems,
        cloudFiles,
        cloudFolders,
        idxCapturedAt,
        idxFilesFolder
      ];
}

typedef $$AlbumsTableCreateCompanionBuilder = AlbumsCompanion Function({
  Value<int> id,
  required String name,
  Value<int?> telegramTopicId,
  Value<DateTime> createdAt,
});
typedef $$AlbumsTableUpdateCompanionBuilder = AlbumsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int?> telegramTopicId,
  Value<DateTime> createdAt,
});

final class $$AlbumsTableReferences
    extends BaseReferences<_$AppDatabase, $AlbumsTable, Album> {
  $$AlbumsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MediaItemsTable, List<MediaItem>>
      _mediaItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.mediaItems,
          aliasName: $_aliasNameGenerator(db.albums.id, db.mediaItems.albumId));

  $$MediaItemsTableProcessedTableManager get mediaItemsRefs {
    final manager = $$MediaItemsTableTableManager($_db, $_db.mediaItems)
        .filter((f) => f.albumId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AlbumsTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get telegramTopicId => $composableBuilder(
      column: $table.telegramTopicId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> mediaItemsRefs(
      Expression<bool> Function($$MediaItemsTableFilterComposer f) f) {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mediaItems,
        getReferencedColumn: (t) => t.albumId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MediaItemsTableFilterComposer(
              $db: $db,
              $table: $db.mediaItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AlbumsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get telegramTopicId => $composableBuilder(
      column: $table.telegramTopicId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AlbumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get telegramTopicId => $composableBuilder(
      column: $table.telegramTopicId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> mediaItemsRefs<T extends Object>(
      Expression<T> Function($$MediaItemsTableAnnotationComposer a) f) {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mediaItems,
        getReferencedColumn: (t) => t.albumId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MediaItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.mediaItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AlbumsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AlbumsTable,
    Album,
    $$AlbumsTableFilterComposer,
    $$AlbumsTableOrderingComposer,
    $$AlbumsTableAnnotationComposer,
    $$AlbumsTableCreateCompanionBuilder,
    $$AlbumsTableUpdateCompanionBuilder,
    (Album, $$AlbumsTableReferences),
    Album,
    PrefetchHooks Function({bool mediaItemsRefs})> {
  $$AlbumsTableTableManager(_$AppDatabase db, $AlbumsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> telegramTopicId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AlbumsCompanion(
            id: id,
            name: name,
            telegramTopicId: telegramTopicId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int?> telegramTopicId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AlbumsCompanion.insert(
            id: id,
            name: name,
            telegramTopicId: telegramTopicId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AlbumsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({mediaItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mediaItemsRefs) db.mediaItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mediaItemsRefs)
                    await $_getPrefetchedData<Album, $AlbumsTable, MediaItem>(
                        currentTable: table,
                        referencedTable:
                            $$AlbumsTableReferences._mediaItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AlbumsTableReferences(db, table, p0)
                                .mediaItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.albumId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AlbumsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AlbumsTable,
    Album,
    $$AlbumsTableFilterComposer,
    $$AlbumsTableOrderingComposer,
    $$AlbumsTableAnnotationComposer,
    $$AlbumsTableCreateCompanionBuilder,
    $$AlbumsTableUpdateCompanionBuilder,
    (Album, $$AlbumsTableReferences),
    Album,
    PrefetchHooks Function({bool mediaItemsRefs})>;
typedef $$MediaItemsTableCreateCompanionBuilder = MediaItemsCompanion Function({
  required String localId,
  Value<int?> telegramMsgId,
  Value<String?> telegramFileId,
  Value<String?> thumbnailPath,
  required String filename,
  required DateTime capturedAt,
  Value<int?> width,
  Value<int?> height,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<int?> fileSizeBytes,
  required String mimeType,
  required UploadStatus uploadStatus,
  Value<int?> albumId,
  Value<bool> isFavorite,
  Value<bool> isTrashed,
  Value<DateTime?> trashedAt,
  Value<int> rowid,
});
typedef $$MediaItemsTableUpdateCompanionBuilder = MediaItemsCompanion Function({
  Value<String> localId,
  Value<int?> telegramMsgId,
  Value<String?> telegramFileId,
  Value<String?> thumbnailPath,
  Value<String> filename,
  Value<DateTime> capturedAt,
  Value<int?> width,
  Value<int?> height,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<int?> fileSizeBytes,
  Value<String> mimeType,
  Value<UploadStatus> uploadStatus,
  Value<int?> albumId,
  Value<bool> isFavorite,
  Value<bool> isTrashed,
  Value<DateTime?> trashedAt,
  Value<int> rowid,
});

final class $$MediaItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem> {
  $$MediaItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AlbumsTable _albumIdTable(_$AppDatabase db) => db.albums
      .createAlias($_aliasNameGenerator(db.mediaItems.albumId, db.albums.id));

  $$AlbumsTableProcessedTableManager? get albumId {
    final $_column = $_itemColumn<int>('album_id');
    if ($_column == null) return null;
    final manager = $$AlbumsTableTableManager($_db, $_db.albums)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MediaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get telegramMsgId => $composableBuilder(
      column: $table.telegramMsgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get telegramFileId => $composableBuilder(
      column: $table.telegramFileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<UploadStatus, UploadStatus, int>
      get uploadStatus => $composableBuilder(
          column: $table.uploadStatus,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isTrashed => $composableBuilder(
      column: $table.isTrashed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get trashedAt => $composableBuilder(
      column: $table.trashedAt, builder: (column) => ColumnFilters(column));

  $$AlbumsTableFilterComposer get albumId {
    final $$AlbumsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.albumId,
        referencedTable: $db.albums,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlbumsTableFilterComposer(
              $db: $db,
              $table: $db.albums,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get telegramMsgId => $composableBuilder(
      column: $table.telegramMsgId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get telegramFileId => $composableBuilder(
      column: $table.telegramFileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uploadStatus => $composableBuilder(
      column: $table.uploadStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTrashed => $composableBuilder(
      column: $table.isTrashed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get trashedAt => $composableBuilder(
      column: $table.trashedAt, builder: (column) => ColumnOrderings(column));

  $$AlbumsTableOrderingComposer get albumId {
    final $$AlbumsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.albumId,
        referencedTable: $db.albums,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlbumsTableOrderingComposer(
              $db: $db,
              $table: $db.albums,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get telegramMsgId => $composableBuilder(
      column: $table.telegramMsgId, builder: (column) => column);

  GeneratedColumn<String> get telegramFileId => $composableBuilder(
      column: $table.telegramFileId, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UploadStatus, int> get uploadStatus =>
      $composableBuilder(
          column: $table.uploadStatus, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<bool> get isTrashed =>
      $composableBuilder(column: $table.isTrashed, builder: (column) => column);

  GeneratedColumn<DateTime> get trashedAt =>
      $composableBuilder(column: $table.trashedAt, builder: (column) => column);

  $$AlbumsTableAnnotationComposer get albumId {
    final $$AlbumsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.albumId,
        referencedTable: $db.albums,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlbumsTableAnnotationComposer(
              $db: $db,
              $table: $db.albums,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MediaItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaItemsTable,
    MediaItem,
    $$MediaItemsTableFilterComposer,
    $$MediaItemsTableOrderingComposer,
    $$MediaItemsTableAnnotationComposer,
    $$MediaItemsTableCreateCompanionBuilder,
    $$MediaItemsTableUpdateCompanionBuilder,
    (MediaItem, $$MediaItemsTableReferences),
    MediaItem,
    PrefetchHooks Function({bool albumId})> {
  $$MediaItemsTableTableManager(_$AppDatabase db, $MediaItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<int?> telegramMsgId = const Value.absent(),
            Value<String?> telegramFileId = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<String> filename = const Value.absent(),
            Value<DateTime> capturedAt = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<int?> fileSizeBytes = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<UploadStatus> uploadStatus = const Value.absent(),
            Value<int?> albumId = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isTrashed = const Value.absent(),
            Value<DateTime?> trashedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaItemsCompanion(
            localId: localId,
            telegramMsgId: telegramMsgId,
            telegramFileId: telegramFileId,
            thumbnailPath: thumbnailPath,
            filename: filename,
            capturedAt: capturedAt,
            width: width,
            height: height,
            latitude: latitude,
            longitude: longitude,
            fileSizeBytes: fileSizeBytes,
            mimeType: mimeType,
            uploadStatus: uploadStatus,
            albumId: albumId,
            isFavorite: isFavorite,
            isTrashed: isTrashed,
            trashedAt: trashedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            Value<int?> telegramMsgId = const Value.absent(),
            Value<String?> telegramFileId = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            required String filename,
            required DateTime capturedAt,
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<int?> fileSizeBytes = const Value.absent(),
            required String mimeType,
            required UploadStatus uploadStatus,
            Value<int?> albumId = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isTrashed = const Value.absent(),
            Value<DateTime?> trashedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaItemsCompanion.insert(
            localId: localId,
            telegramMsgId: telegramMsgId,
            telegramFileId: telegramFileId,
            thumbnailPath: thumbnailPath,
            filename: filename,
            capturedAt: capturedAt,
            width: width,
            height: height,
            latitude: latitude,
            longitude: longitude,
            fileSizeBytes: fileSizeBytes,
            mimeType: mimeType,
            uploadStatus: uploadStatus,
            albumId: albumId,
            isFavorite: isFavorite,
            isTrashed: isTrashed,
            trashedAt: trashedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MediaItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({albumId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (albumId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.albumId,
                    referencedTable:
                        $$MediaItemsTableReferences._albumIdTable(db),
                    referencedColumn:
                        $$MediaItemsTableReferences._albumIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MediaItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaItemsTable,
    MediaItem,
    $$MediaItemsTableFilterComposer,
    $$MediaItemsTableOrderingComposer,
    $$MediaItemsTableAnnotationComposer,
    $$MediaItemsTableCreateCompanionBuilder,
    $$MediaItemsTableUpdateCompanionBuilder,
    (MediaItem, $$MediaItemsTableReferences),
    MediaItem,
    PrefetchHooks Function({bool albumId})>;
typedef $$CloudFilesTableCreateCompanionBuilder = CloudFilesCompanion Function({
  Value<int> id,
  Value<String?> localPath,
  required String fileName,
  required BigInt fileSizeBytes,
  required String mimeType,
  Value<String> folderPath,
  Value<int?> telegramMsgId,
  Value<String?> telegramFileId,
  Value<int?> topicId,
  Value<bool> isPinnedOffline,
  required UploadStatus uploadStatus,
  required DateTime createdAt,
  required DateTime modifiedAt,
});
typedef $$CloudFilesTableUpdateCompanionBuilder = CloudFilesCompanion Function({
  Value<int> id,
  Value<String?> localPath,
  Value<String> fileName,
  Value<BigInt> fileSizeBytes,
  Value<String> mimeType,
  Value<String> folderPath,
  Value<int?> telegramMsgId,
  Value<String?> telegramFileId,
  Value<int?> topicId,
  Value<bool> isPinnedOffline,
  Value<UploadStatus> uploadStatus,
  Value<DateTime> createdAt,
  Value<DateTime> modifiedAt,
});

class $$CloudFilesTableFilterComposer
    extends Composer<_$AppDatabase, $CloudFilesTable> {
  $$CloudFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<BigInt> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get telegramMsgId => $composableBuilder(
      column: $table.telegramMsgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get telegramFileId => $composableBuilder(
      column: $table.telegramFileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinnedOffline => $composableBuilder(
      column: $table.isPinnedOffline,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<UploadStatus, UploadStatus, int>
      get uploadStatus => $composableBuilder(
          column: $table.uploadStatus,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnFilters(column));
}

class $$CloudFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CloudFilesTable> {
  $$CloudFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<BigInt> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get telegramMsgId => $composableBuilder(
      column: $table.telegramMsgId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get telegramFileId => $composableBuilder(
      column: $table.telegramFileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinnedOffline => $composableBuilder(
      column: $table.isPinnedOffline,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uploadStatus => $composableBuilder(
      column: $table.uploadStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnOrderings(column));
}

class $$CloudFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CloudFilesTable> {
  $$CloudFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<BigInt> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => column);

  GeneratedColumn<int> get telegramMsgId => $composableBuilder(
      column: $table.telegramMsgId, builder: (column) => column);

  GeneratedColumn<String> get telegramFileId => $composableBuilder(
      column: $table.telegramFileId, builder: (column) => column);

  GeneratedColumn<int> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<bool> get isPinnedOffline => $composableBuilder(
      column: $table.isPinnedOffline, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UploadStatus, int> get uploadStatus =>
      $composableBuilder(
          column: $table.uploadStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => column);
}

class $$CloudFilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CloudFilesTable,
    CloudFile,
    $$CloudFilesTableFilterComposer,
    $$CloudFilesTableOrderingComposer,
    $$CloudFilesTableAnnotationComposer,
    $$CloudFilesTableCreateCompanionBuilder,
    $$CloudFilesTableUpdateCompanionBuilder,
    (CloudFile, BaseReferences<_$AppDatabase, $CloudFilesTable, CloudFile>),
    CloudFile,
    PrefetchHooks Function()> {
  $$CloudFilesTableTableManager(_$AppDatabase db, $CloudFilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CloudFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CloudFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CloudFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<BigInt> fileSizeBytes = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<String> folderPath = const Value.absent(),
            Value<int?> telegramMsgId = const Value.absent(),
            Value<String?> telegramFileId = const Value.absent(),
            Value<int?> topicId = const Value.absent(),
            Value<bool> isPinnedOffline = const Value.absent(),
            Value<UploadStatus> uploadStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> modifiedAt = const Value.absent(),
          }) =>
              CloudFilesCompanion(
            id: id,
            localPath: localPath,
            fileName: fileName,
            fileSizeBytes: fileSizeBytes,
            mimeType: mimeType,
            folderPath: folderPath,
            telegramMsgId: telegramMsgId,
            telegramFileId: telegramFileId,
            topicId: topicId,
            isPinnedOffline: isPinnedOffline,
            uploadStatus: uploadStatus,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            required String fileName,
            required BigInt fileSizeBytes,
            required String mimeType,
            Value<String> folderPath = const Value.absent(),
            Value<int?> telegramMsgId = const Value.absent(),
            Value<String?> telegramFileId = const Value.absent(),
            Value<int?> topicId = const Value.absent(),
            Value<bool> isPinnedOffline = const Value.absent(),
            required UploadStatus uploadStatus,
            required DateTime createdAt,
            required DateTime modifiedAt,
          }) =>
              CloudFilesCompanion.insert(
            id: id,
            localPath: localPath,
            fileName: fileName,
            fileSizeBytes: fileSizeBytes,
            mimeType: mimeType,
            folderPath: folderPath,
            telegramMsgId: telegramMsgId,
            telegramFileId: telegramFileId,
            topicId: topicId,
            isPinnedOffline: isPinnedOffline,
            uploadStatus: uploadStatus,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CloudFilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CloudFilesTable,
    CloudFile,
    $$CloudFilesTableFilterComposer,
    $$CloudFilesTableOrderingComposer,
    $$CloudFilesTableAnnotationComposer,
    $$CloudFilesTableCreateCompanionBuilder,
    $$CloudFilesTableUpdateCompanionBuilder,
    (CloudFile, BaseReferences<_$AppDatabase, $CloudFilesTable, CloudFile>),
    CloudFile,
    PrefetchHooks Function()>;
typedef $$CloudFoldersTableCreateCompanionBuilder = CloudFoldersCompanion
    Function({
  required String id,
  Value<String?> parentPath,
  required String folderName,
  Value<int?> topicId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$CloudFoldersTableUpdateCompanionBuilder = CloudFoldersCompanion
    Function({
  Value<String> id,
  Value<String?> parentPath,
  Value<String> folderName,
  Value<int?> topicId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$CloudFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $CloudFoldersTable> {
  $$CloudFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentPath => $composableBuilder(
      column: $table.parentPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderName => $composableBuilder(
      column: $table.folderName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CloudFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $CloudFoldersTable> {
  $$CloudFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentPath => $composableBuilder(
      column: $table.parentPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderName => $composableBuilder(
      column: $table.folderName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CloudFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CloudFoldersTable> {
  $$CloudFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentPath => $composableBuilder(
      column: $table.parentPath, builder: (column) => column);

  GeneratedColumn<String> get folderName => $composableBuilder(
      column: $table.folderName, builder: (column) => column);

  GeneratedColumn<int> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CloudFoldersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CloudFoldersTable,
    CloudFolder,
    $$CloudFoldersTableFilterComposer,
    $$CloudFoldersTableOrderingComposer,
    $$CloudFoldersTableAnnotationComposer,
    $$CloudFoldersTableCreateCompanionBuilder,
    $$CloudFoldersTableUpdateCompanionBuilder,
    (
      CloudFolder,
      BaseReferences<_$AppDatabase, $CloudFoldersTable, CloudFolder>
    ),
    CloudFolder,
    PrefetchHooks Function()> {
  $$CloudFoldersTableTableManager(_$AppDatabase db, $CloudFoldersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CloudFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CloudFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CloudFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> parentPath = const Value.absent(),
            Value<String> folderName = const Value.absent(),
            Value<int?> topicId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudFoldersCompanion(
            id: id,
            parentPath: parentPath,
            folderName: folderName,
            topicId: topicId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> parentPath = const Value.absent(),
            required String folderName,
            Value<int?> topicId = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudFoldersCompanion.insert(
            id: id,
            parentPath: parentPath,
            folderName: folderName,
            topicId: topicId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CloudFoldersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CloudFoldersTable,
    CloudFolder,
    $$CloudFoldersTableFilterComposer,
    $$CloudFoldersTableOrderingComposer,
    $$CloudFoldersTableAnnotationComposer,
    $$CloudFoldersTableCreateCompanionBuilder,
    $$CloudFoldersTableUpdateCompanionBuilder,
    (
      CloudFolder,
      BaseReferences<_$AppDatabase, $CloudFoldersTable, CloudFolder>
    ),
    CloudFolder,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AlbumsTableTableManager get albums =>
      $$AlbumsTableTableManager(_db, _db.albums);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$CloudFilesTableTableManager get cloudFiles =>
      $$CloudFilesTableTableManager(_db, _db.cloudFiles);
  $$CloudFoldersTableTableManager get cloudFolders =>
      $$CloudFoldersTableTableManager(_db, _db.cloudFolders);
}
