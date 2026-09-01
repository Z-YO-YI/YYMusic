// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TrackRecordsTable extends TrackRecords
    with TableInfo<$TrackRecordsTable, TrackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1024,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumTitleMeta = const VerificationMeta(
    'albumTitle',
  );
  @override
  late final GeneratedColumn<String> albumTitle = GeneratedColumn<String>(
    'album_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artworkUriMeta = const VerificationMeta(
    'artworkUri',
  );
  @override
  late final GeneratedColumn<String> artworkUri = GeneratedColumn<String>(
    'artwork_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentUriMeta = const VerificationMeta(
    'contentUri',
  );
  @override
  late final GeneratedColumn<String> contentUri = GeneratedColumn<String>(
    'content_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileFingerprintMeta = const VerificationMeta(
    'fileFingerprint',
  );
  @override
  late final GeneratedColumn<String> fileFingerprint = GeneratedColumn<String>(
    'file_fingerprint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMsMeta = const VerificationMeta(
    'modifiedAtMs',
  );
  @override
  late final GeneratedColumn<int> modifiedAtMs = GeneratedColumn<int>(
    'modified_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _availabilityMeta = const VerificationMeta(
    'availability',
  );
  @override
  late final GeneratedColumn<String> availability = GeneratedColumn<String>(
    'availability',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    trackId,
    sourceId,
    sourceType,
    title,
    albumId,
    albumTitle,
    durationMs,
    artworkUri,
    localPath,
    contentUri,
    fileFingerprint,
    modifiedAtMs,
    fileSize,
    availability,
    metadataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('album_title')) {
      context.handle(
        _albumTitleMeta,
        albumTitle.isAcceptableOrUnknown(data['album_title']!, _albumTitleMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('artwork_uri')) {
      context.handle(
        _artworkUriMeta,
        artworkUri.isAcceptableOrUnknown(data['artwork_uri']!, _artworkUriMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('content_uri')) {
      context.handle(
        _contentUriMeta,
        contentUri.isAcceptableOrUnknown(data['content_uri']!, _contentUriMeta),
      );
    }
    if (data.containsKey('file_fingerprint')) {
      context.handle(
        _fileFingerprintMeta,
        fileFingerprint.isAcceptableOrUnknown(
          data['file_fingerprint']!,
          _fileFingerprintMeta,
        ),
      );
    }
    if (data.containsKey('modified_at_ms')) {
      context.handle(
        _modifiedAtMsMeta,
        modifiedAtMs.isAcceptableOrUnknown(
          data['modified_at_ms']!,
          _modifiedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('availability')) {
      context.handle(
        _availabilityMeta,
        availability.isAcceptableOrUnknown(
          data['availability']!,
          _availabilityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_availabilityMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceType, sourceId, trackId};
  @override
  TrackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackRow(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      ),
      albumTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_title'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      artworkUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_uri'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      contentUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_uri'],
      ),
      fileFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_fingerprint'],
      ),
      modifiedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at_ms'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      availability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
    );
  }

  @override
  $TrackRecordsTable createAlias(String alias) {
    return $TrackRecordsTable(attachedDatabase, alias);
  }
}

class TrackRow extends DataClass implements Insertable<TrackRow> {
  final String trackId;
  final String sourceId;
  final String sourceType;
  final String title;
  final String? albumId;
  final String? albumTitle;
  final int durationMs;
  final String? artworkUri;
  final String? localPath;
  final String? contentUri;
  final String? fileFingerprint;
  final int? modifiedAtMs;
  final int? fileSize;
  final String availability;
  final String metadataJson;
  const TrackRow({
    required this.trackId,
    required this.sourceId,
    required this.sourceType,
    required this.title,
    this.albumId,
    this.albumTitle,
    required this.durationMs,
    this.artworkUri,
    this.localPath,
    this.contentUri,
    this.fileFingerprint,
    this.modifiedAtMs,
    this.fileSize,
    required this.availability,
    required this.metadataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    map['source_id'] = Variable<String>(sourceId);
    map['source_type'] = Variable<String>(sourceType);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || albumTitle != null) {
      map['album_title'] = Variable<String>(albumTitle);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || artworkUri != null) {
      map['artwork_uri'] = Variable<String>(artworkUri);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || contentUri != null) {
      map['content_uri'] = Variable<String>(contentUri);
    }
    if (!nullToAbsent || fileFingerprint != null) {
      map['file_fingerprint'] = Variable<String>(fileFingerprint);
    }
    if (!nullToAbsent || modifiedAtMs != null) {
      map['modified_at_ms'] = Variable<int>(modifiedAtMs);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    map['availability'] = Variable<String>(availability);
    map['metadata_json'] = Variable<String>(metadataJson);
    return map;
  }

  TrackRecordsCompanion toCompanion(bool nullToAbsent) {
    return TrackRecordsCompanion(
      trackId: Value(trackId),
      sourceId: Value(sourceId),
      sourceType: Value(sourceType),
      title: Value(title),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      albumTitle: albumTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(albumTitle),
      durationMs: Value(durationMs),
      artworkUri: artworkUri == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUri),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      contentUri: contentUri == null && nullToAbsent
          ? const Value.absent()
          : Value(contentUri),
      fileFingerprint: fileFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(fileFingerprint),
      modifiedAtMs: modifiedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedAtMs),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      availability: Value(availability),
      metadataJson: Value(metadataJson),
    );
  }

  factory TrackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackRow(
      trackId: serializer.fromJson<String>(json['trackId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      title: serializer.fromJson<String>(json['title']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      albumTitle: serializer.fromJson<String?>(json['albumTitle']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      artworkUri: serializer.fromJson<String?>(json['artworkUri']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      contentUri: serializer.fromJson<String?>(json['contentUri']),
      fileFingerprint: serializer.fromJson<String?>(json['fileFingerprint']),
      modifiedAtMs: serializer.fromJson<int?>(json['modifiedAtMs']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      availability: serializer.fromJson<String>(json['availability']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'sourceId': serializer.toJson<String>(sourceId),
      'sourceType': serializer.toJson<String>(sourceType),
      'title': serializer.toJson<String>(title),
      'albumId': serializer.toJson<String?>(albumId),
      'albumTitle': serializer.toJson<String?>(albumTitle),
      'durationMs': serializer.toJson<int>(durationMs),
      'artworkUri': serializer.toJson<String?>(artworkUri),
      'localPath': serializer.toJson<String?>(localPath),
      'contentUri': serializer.toJson<String?>(contentUri),
      'fileFingerprint': serializer.toJson<String?>(fileFingerprint),
      'modifiedAtMs': serializer.toJson<int?>(modifiedAtMs),
      'fileSize': serializer.toJson<int?>(fileSize),
      'availability': serializer.toJson<String>(availability),
      'metadataJson': serializer.toJson<String>(metadataJson),
    };
  }

  TrackRow copyWith({
    String? trackId,
    String? sourceId,
    String? sourceType,
    String? title,
    Value<String?> albumId = const Value.absent(),
    Value<String?> albumTitle = const Value.absent(),
    int? durationMs,
    Value<String?> artworkUri = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<String?> contentUri = const Value.absent(),
    Value<String?> fileFingerprint = const Value.absent(),
    Value<int?> modifiedAtMs = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    String? availability,
    String? metadataJson,
  }) => TrackRow(
    trackId: trackId ?? this.trackId,
    sourceId: sourceId ?? this.sourceId,
    sourceType: sourceType ?? this.sourceType,
    title: title ?? this.title,
    albumId: albumId.present ? albumId.value : this.albumId,
    albumTitle: albumTitle.present ? albumTitle.value : this.albumTitle,
    durationMs: durationMs ?? this.durationMs,
    artworkUri: artworkUri.present ? artworkUri.value : this.artworkUri,
    localPath: localPath.present ? localPath.value : this.localPath,
    contentUri: contentUri.present ? contentUri.value : this.contentUri,
    fileFingerprint: fileFingerprint.present
        ? fileFingerprint.value
        : this.fileFingerprint,
    modifiedAtMs: modifiedAtMs.present ? modifiedAtMs.value : this.modifiedAtMs,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    availability: availability ?? this.availability,
    metadataJson: metadataJson ?? this.metadataJson,
  );
  TrackRow copyWithCompanion(TrackRecordsCompanion data) {
    return TrackRow(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      title: data.title.present ? data.title.value : this.title,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      albumTitle: data.albumTitle.present
          ? data.albumTitle.value
          : this.albumTitle,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      artworkUri: data.artworkUri.present
          ? data.artworkUri.value
          : this.artworkUri,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      contentUri: data.contentUri.present
          ? data.contentUri.value
          : this.contentUri,
      fileFingerprint: data.fileFingerprint.present
          ? data.fileFingerprint.value
          : this.fileFingerprint,
      modifiedAtMs: data.modifiedAtMs.present
          ? data.modifiedAtMs.value
          : this.modifiedAtMs,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      availability: data.availability.present
          ? data.availability.value
          : this.availability,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackRow(')
          ..write('trackId: $trackId, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceType: $sourceType, ')
          ..write('title: $title, ')
          ..write('albumId: $albumId, ')
          ..write('albumTitle: $albumTitle, ')
          ..write('durationMs: $durationMs, ')
          ..write('artworkUri: $artworkUri, ')
          ..write('localPath: $localPath, ')
          ..write('contentUri: $contentUri, ')
          ..write('fileFingerprint: $fileFingerprint, ')
          ..write('modifiedAtMs: $modifiedAtMs, ')
          ..write('fileSize: $fileSize, ')
          ..write('availability: $availability, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trackId,
    sourceId,
    sourceType,
    title,
    albumId,
    albumTitle,
    durationMs,
    artworkUri,
    localPath,
    contentUri,
    fileFingerprint,
    modifiedAtMs,
    fileSize,
    availability,
    metadataJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackRow &&
          other.trackId == this.trackId &&
          other.sourceId == this.sourceId &&
          other.sourceType == this.sourceType &&
          other.title == this.title &&
          other.albumId == this.albumId &&
          other.albumTitle == this.albumTitle &&
          other.durationMs == this.durationMs &&
          other.artworkUri == this.artworkUri &&
          other.localPath == this.localPath &&
          other.contentUri == this.contentUri &&
          other.fileFingerprint == this.fileFingerprint &&
          other.modifiedAtMs == this.modifiedAtMs &&
          other.fileSize == this.fileSize &&
          other.availability == this.availability &&
          other.metadataJson == this.metadataJson);
}

class TrackRecordsCompanion extends UpdateCompanion<TrackRow> {
  final Value<String> trackId;
  final Value<String> sourceId;
  final Value<String> sourceType;
  final Value<String> title;
  final Value<String?> albumId;
  final Value<String?> albumTitle;
  final Value<int> durationMs;
  final Value<String?> artworkUri;
  final Value<String?> localPath;
  final Value<String?> contentUri;
  final Value<String?> fileFingerprint;
  final Value<int?> modifiedAtMs;
  final Value<int?> fileSize;
  final Value<String> availability;
  final Value<String> metadataJson;
  final Value<int> rowid;
  const TrackRecordsCompanion({
    this.trackId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.title = const Value.absent(),
    this.albumId = const Value.absent(),
    this.albumTitle = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.artworkUri = const Value.absent(),
    this.localPath = const Value.absent(),
    this.contentUri = const Value.absent(),
    this.fileFingerprint = const Value.absent(),
    this.modifiedAtMs = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.availability = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackRecordsCompanion.insert({
    required String trackId,
    required String sourceId,
    required String sourceType,
    required String title,
    this.albumId = const Value.absent(),
    this.albumTitle = const Value.absent(),
    required int durationMs,
    this.artworkUri = const Value.absent(),
    this.localPath = const Value.absent(),
    this.contentUri = const Value.absent(),
    this.fileFingerprint = const Value.absent(),
    this.modifiedAtMs = const Value.absent(),
    this.fileSize = const Value.absent(),
    required String availability,
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       sourceId = Value(sourceId),
       sourceType = Value(sourceType),
       title = Value(title),
       durationMs = Value(durationMs),
       availability = Value(availability);
  static Insertable<TrackRow> custom({
    Expression<String>? trackId,
    Expression<String>? sourceId,
    Expression<String>? sourceType,
    Expression<String>? title,
    Expression<String>? albumId,
    Expression<String>? albumTitle,
    Expression<int>? durationMs,
    Expression<String>? artworkUri,
    Expression<String>? localPath,
    Expression<String>? contentUri,
    Expression<String>? fileFingerprint,
    Expression<int>? modifiedAtMs,
    Expression<int>? fileSize,
    Expression<String>? availability,
    Expression<String>? metadataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (sourceId != null) 'source_id': sourceId,
      if (sourceType != null) 'source_type': sourceType,
      if (title != null) 'title': title,
      if (albumId != null) 'album_id': albumId,
      if (albumTitle != null) 'album_title': albumTitle,
      if (durationMs != null) 'duration_ms': durationMs,
      if (artworkUri != null) 'artwork_uri': artworkUri,
      if (localPath != null) 'local_path': localPath,
      if (contentUri != null) 'content_uri': contentUri,
      if (fileFingerprint != null) 'file_fingerprint': fileFingerprint,
      if (modifiedAtMs != null) 'modified_at_ms': modifiedAtMs,
      if (fileSize != null) 'file_size': fileSize,
      if (availability != null) 'availability': availability,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackRecordsCompanion copyWith({
    Value<String>? trackId,
    Value<String>? sourceId,
    Value<String>? sourceType,
    Value<String>? title,
    Value<String?>? albumId,
    Value<String?>? albumTitle,
    Value<int>? durationMs,
    Value<String?>? artworkUri,
    Value<String?>? localPath,
    Value<String?>? contentUri,
    Value<String?>? fileFingerprint,
    Value<int?>? modifiedAtMs,
    Value<int?>? fileSize,
    Value<String>? availability,
    Value<String>? metadataJson,
    Value<int>? rowid,
  }) {
    return TrackRecordsCompanion(
      trackId: trackId ?? this.trackId,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      title: title ?? this.title,
      albumId: albumId ?? this.albumId,
      albumTitle: albumTitle ?? this.albumTitle,
      durationMs: durationMs ?? this.durationMs,
      artworkUri: artworkUri ?? this.artworkUri,
      localPath: localPath ?? this.localPath,
      contentUri: contentUri ?? this.contentUri,
      fileFingerprint: fileFingerprint ?? this.fileFingerprint,
      modifiedAtMs: modifiedAtMs ?? this.modifiedAtMs,
      fileSize: fileSize ?? this.fileSize,
      availability: availability ?? this.availability,
      metadataJson: metadataJson ?? this.metadataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (albumTitle.present) {
      map['album_title'] = Variable<String>(albumTitle.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (artworkUri.present) {
      map['artwork_uri'] = Variable<String>(artworkUri.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (contentUri.present) {
      map['content_uri'] = Variable<String>(contentUri.value);
    }
    if (fileFingerprint.present) {
      map['file_fingerprint'] = Variable<String>(fileFingerprint.value);
    }
    if (modifiedAtMs.present) {
      map['modified_at_ms'] = Variable<int>(modifiedAtMs.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (availability.present) {
      map['availability'] = Variable<String>(availability.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackRecordsCompanion(')
          ..write('trackId: $trackId, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceType: $sourceType, ')
          ..write('title: $title, ')
          ..write('albumId: $albumId, ')
          ..write('albumTitle: $albumTitle, ')
          ..write('durationMs: $durationMs, ')
          ..write('artworkUri: $artworkUri, ')
          ..write('localPath: $localPath, ')
          ..write('contentUri: $contentUri, ')
          ..write('fileFingerprint: $fileFingerprint, ')
          ..write('modifiedAtMs: $modifiedAtMs, ')
          ..write('fileSize: $fileSize, ')
          ..write('availability: $availability, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlbumRecordsTable extends AlbumRecords
    with TableInfo<$AlbumRecordsTable, AlbumRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1024,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUriMeta = const VerificationMeta(
    'artworkUri',
  );
  @override
  late final GeneratedColumn<String> artworkUri = GeneratedColumn<String>(
    'artwork_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackCountMeta = const VerificationMeta(
    'trackCount',
  );
  @override
  late final GeneratedColumn<int> trackCount = GeneratedColumn<int>(
    'track_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    albumId,
    sourceId,
    title,
    year,
    artworkUri,
    trackCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlbumRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('artwork_uri')) {
      context.handle(
        _artworkUriMeta,
        artworkUri.isAcceptableOrUnknown(data['artwork_uri']!, _artworkUriMeta),
      );
    }
    if (data.containsKey('track_count')) {
      context.handle(
        _trackCountMeta,
        trackCount.isAcceptableOrUnknown(data['track_count']!, _trackCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, albumId};
  @override
  AlbumRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlbumRow(
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      artworkUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_uri'],
      ),
      trackCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_count'],
      )!,
    );
  }

  @override
  $AlbumRecordsTable createAlias(String alias) {
    return $AlbumRecordsTable(attachedDatabase, alias);
  }
}

class AlbumRow extends DataClass implements Insertable<AlbumRow> {
  final String albumId;
  final String sourceId;
  final String title;
  final int? year;
  final String? artworkUri;
  final int trackCount;
  const AlbumRow({
    required this.albumId,
    required this.sourceId,
    required this.title,
    this.year,
    this.artworkUri,
    required this.trackCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['album_id'] = Variable<String>(albumId);
    map['source_id'] = Variable<String>(sourceId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || artworkUri != null) {
      map['artwork_uri'] = Variable<String>(artworkUri);
    }
    map['track_count'] = Variable<int>(trackCount);
    return map;
  }

  AlbumRecordsCompanion toCompanion(bool nullToAbsent) {
    return AlbumRecordsCompanion(
      albumId: Value(albumId),
      sourceId: Value(sourceId),
      title: Value(title),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      artworkUri: artworkUri == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUri),
      trackCount: Value(trackCount),
    );
  }

  factory AlbumRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlbumRow(
      albumId: serializer.fromJson<String>(json['albumId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      title: serializer.fromJson<String>(json['title']),
      year: serializer.fromJson<int?>(json['year']),
      artworkUri: serializer.fromJson<String?>(json['artworkUri']),
      trackCount: serializer.fromJson<int>(json['trackCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'albumId': serializer.toJson<String>(albumId),
      'sourceId': serializer.toJson<String>(sourceId),
      'title': serializer.toJson<String>(title),
      'year': serializer.toJson<int?>(year),
      'artworkUri': serializer.toJson<String?>(artworkUri),
      'trackCount': serializer.toJson<int>(trackCount),
    };
  }

  AlbumRow copyWith({
    String? albumId,
    String? sourceId,
    String? title,
    Value<int?> year = const Value.absent(),
    Value<String?> artworkUri = const Value.absent(),
    int? trackCount,
  }) => AlbumRow(
    albumId: albumId ?? this.albumId,
    sourceId: sourceId ?? this.sourceId,
    title: title ?? this.title,
    year: year.present ? year.value : this.year,
    artworkUri: artworkUri.present ? artworkUri.value : this.artworkUri,
    trackCount: trackCount ?? this.trackCount,
  );
  AlbumRow copyWithCompanion(AlbumRecordsCompanion data) {
    return AlbumRow(
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      title: data.title.present ? data.title.value : this.title,
      year: data.year.present ? data.year.value : this.year,
      artworkUri: data.artworkUri.present
          ? data.artworkUri.value
          : this.artworkUri,
      trackCount: data.trackCount.present
          ? data.trackCount.value
          : this.trackCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlbumRow(')
          ..write('albumId: $albumId, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('artworkUri: $artworkUri, ')
          ..write('trackCount: $trackCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(albumId, sourceId, title, year, artworkUri, trackCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumRow &&
          other.albumId == this.albumId &&
          other.sourceId == this.sourceId &&
          other.title == this.title &&
          other.year == this.year &&
          other.artworkUri == this.artworkUri &&
          other.trackCount == this.trackCount);
}

class AlbumRecordsCompanion extends UpdateCompanion<AlbumRow> {
  final Value<String> albumId;
  final Value<String> sourceId;
  final Value<String> title;
  final Value<int?> year;
  final Value<String?> artworkUri;
  final Value<int> trackCount;
  final Value<int> rowid;
  const AlbumRecordsCompanion({
    this.albumId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.title = const Value.absent(),
    this.year = const Value.absent(),
    this.artworkUri = const Value.absent(),
    this.trackCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlbumRecordsCompanion.insert({
    required String albumId,
    required String sourceId,
    required String title,
    this.year = const Value.absent(),
    this.artworkUri = const Value.absent(),
    this.trackCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : albumId = Value(albumId),
       sourceId = Value(sourceId),
       title = Value(title);
  static Insertable<AlbumRow> custom({
    Expression<String>? albumId,
    Expression<String>? sourceId,
    Expression<String>? title,
    Expression<int>? year,
    Expression<String>? artworkUri,
    Expression<int>? trackCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (albumId != null) 'album_id': albumId,
      if (sourceId != null) 'source_id': sourceId,
      if (title != null) 'title': title,
      if (year != null) 'year': year,
      if (artworkUri != null) 'artwork_uri': artworkUri,
      if (trackCount != null) 'track_count': trackCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlbumRecordsCompanion copyWith({
    Value<String>? albumId,
    Value<String>? sourceId,
    Value<String>? title,
    Value<int?>? year,
    Value<String?>? artworkUri,
    Value<int>? trackCount,
    Value<int>? rowid,
  }) {
    return AlbumRecordsCompanion(
      albumId: albumId ?? this.albumId,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      year: year ?? this.year,
      artworkUri: artworkUri ?? this.artworkUri,
      trackCount: trackCount ?? this.trackCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (artworkUri.present) {
      map['artwork_uri'] = Variable<String>(artworkUri.value);
    }
    if (trackCount.present) {
      map['track_count'] = Variable<int>(trackCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumRecordsCompanion(')
          ..write('albumId: $albumId, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('artworkUri: $artworkUri, ')
          ..write('trackCount: $trackCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArtistRecordsTable extends ArtistRecords
    with TableInfo<$ArtistRecordsTable, ArtistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtistRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
    'artist_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 512,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artworkUriMeta = const VerificationMeta(
    'artworkUri',
  );
  @override
  late final GeneratedColumn<String> artworkUri = GeneratedColumn<String>(
    'artwork_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumCountMeta = const VerificationMeta(
    'albumCount',
  );
  @override
  late final GeneratedColumn<int> albumCount = GeneratedColumn<int>(
    'album_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _trackCountMeta = const VerificationMeta(
    'trackCount',
  );
  @override
  late final GeneratedColumn<int> trackCount = GeneratedColumn<int>(
    'track_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    artistId,
    sourceId,
    name,
    artworkUri,
    albumCount,
    trackCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artists';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArtistRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('artwork_uri')) {
      context.handle(
        _artworkUriMeta,
        artworkUri.isAcceptableOrUnknown(data['artwork_uri']!, _artworkUriMeta),
      );
    }
    if (data.containsKey('album_count')) {
      context.handle(
        _albumCountMeta,
        albumCount.isAcceptableOrUnknown(data['album_count']!, _albumCountMeta),
      );
    }
    if (data.containsKey('track_count')) {
      context.handle(
        _trackCountMeta,
        trackCount.isAcceptableOrUnknown(data['track_count']!, _trackCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, artistId};
  @override
  ArtistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArtistRow(
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      artworkUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_uri'],
      ),
      albumCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_count'],
      )!,
      trackCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_count'],
      )!,
    );
  }

  @override
  $ArtistRecordsTable createAlias(String alias) {
    return $ArtistRecordsTable(attachedDatabase, alias);
  }
}

class ArtistRow extends DataClass implements Insertable<ArtistRow> {
  final String artistId;
  final String sourceId;
  final String name;
  final String? artworkUri;
  final int albumCount;
  final int trackCount;
  const ArtistRow({
    required this.artistId,
    required this.sourceId,
    required this.name,
    this.artworkUri,
    required this.albumCount,
    required this.trackCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['artist_id'] = Variable<String>(artistId);
    map['source_id'] = Variable<String>(sourceId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || artworkUri != null) {
      map['artwork_uri'] = Variable<String>(artworkUri);
    }
    map['album_count'] = Variable<int>(albumCount);
    map['track_count'] = Variable<int>(trackCount);
    return map;
  }

  ArtistRecordsCompanion toCompanion(bool nullToAbsent) {
    return ArtistRecordsCompanion(
      artistId: Value(artistId),
      sourceId: Value(sourceId),
      name: Value(name),
      artworkUri: artworkUri == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUri),
      albumCount: Value(albumCount),
      trackCount: Value(trackCount),
    );
  }

  factory ArtistRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArtistRow(
      artistId: serializer.fromJson<String>(json['artistId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      name: serializer.fromJson<String>(json['name']),
      artworkUri: serializer.fromJson<String?>(json['artworkUri']),
      albumCount: serializer.fromJson<int>(json['albumCount']),
      trackCount: serializer.fromJson<int>(json['trackCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'artistId': serializer.toJson<String>(artistId),
      'sourceId': serializer.toJson<String>(sourceId),
      'name': serializer.toJson<String>(name),
      'artworkUri': serializer.toJson<String?>(artworkUri),
      'albumCount': serializer.toJson<int>(albumCount),
      'trackCount': serializer.toJson<int>(trackCount),
    };
  }

  ArtistRow copyWith({
    String? artistId,
    String? sourceId,
    String? name,
    Value<String?> artworkUri = const Value.absent(),
    int? albumCount,
    int? trackCount,
  }) => ArtistRow(
    artistId: artistId ?? this.artistId,
    sourceId: sourceId ?? this.sourceId,
    name: name ?? this.name,
    artworkUri: artworkUri.present ? artworkUri.value : this.artworkUri,
    albumCount: albumCount ?? this.albumCount,
    trackCount: trackCount ?? this.trackCount,
  );
  ArtistRow copyWithCompanion(ArtistRecordsCompanion data) {
    return ArtistRow(
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      name: data.name.present ? data.name.value : this.name,
      artworkUri: data.artworkUri.present
          ? data.artworkUri.value
          : this.artworkUri,
      albumCount: data.albumCount.present
          ? data.albumCount.value
          : this.albumCount,
      trackCount: data.trackCount.present
          ? data.trackCount.value
          : this.trackCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArtistRow(')
          ..write('artistId: $artistId, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('artworkUri: $artworkUri, ')
          ..write('albumCount: $albumCount, ')
          ..write('trackCount: $trackCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(artistId, sourceId, name, artworkUri, albumCount, trackCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtistRow &&
          other.artistId == this.artistId &&
          other.sourceId == this.sourceId &&
          other.name == this.name &&
          other.artworkUri == this.artworkUri &&
          other.albumCount == this.albumCount &&
          other.trackCount == this.trackCount);
}

class ArtistRecordsCompanion extends UpdateCompanion<ArtistRow> {
  final Value<String> artistId;
  final Value<String> sourceId;
  final Value<String> name;
  final Value<String?> artworkUri;
  final Value<int> albumCount;
  final Value<int> trackCount;
  final Value<int> rowid;
  const ArtistRecordsCompanion({
    this.artistId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.name = const Value.absent(),
    this.artworkUri = const Value.absent(),
    this.albumCount = const Value.absent(),
    this.trackCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArtistRecordsCompanion.insert({
    required String artistId,
    required String sourceId,
    required String name,
    this.artworkUri = const Value.absent(),
    this.albumCount = const Value.absent(),
    this.trackCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : artistId = Value(artistId),
       sourceId = Value(sourceId),
       name = Value(name);
  static Insertable<ArtistRow> custom({
    Expression<String>? artistId,
    Expression<String>? sourceId,
    Expression<String>? name,
    Expression<String>? artworkUri,
    Expression<int>? albumCount,
    Expression<int>? trackCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (artistId != null) 'artist_id': artistId,
      if (sourceId != null) 'source_id': sourceId,
      if (name != null) 'name': name,
      if (artworkUri != null) 'artwork_uri': artworkUri,
      if (albumCount != null) 'album_count': albumCount,
      if (trackCount != null) 'track_count': trackCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArtistRecordsCompanion copyWith({
    Value<String>? artistId,
    Value<String>? sourceId,
    Value<String>? name,
    Value<String?>? artworkUri,
    Value<int>? albumCount,
    Value<int>? trackCount,
    Value<int>? rowid,
  }) {
    return ArtistRecordsCompanion(
      artistId: artistId ?? this.artistId,
      sourceId: sourceId ?? this.sourceId,
      name: name ?? this.name,
      artworkUri: artworkUri ?? this.artworkUri,
      albumCount: albumCount ?? this.albumCount,
      trackCount: trackCount ?? this.trackCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (artworkUri.present) {
      map['artwork_uri'] = Variable<String>(artworkUri.value);
    }
    if (albumCount.present) {
      map['album_count'] = Variable<int>(albumCount.value);
    }
    if (trackCount.present) {
      map['track_count'] = Variable<int>(trackCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtistRecordsCompanion(')
          ..write('artistId: $artistId, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('artworkUri: $artworkUri, ')
          ..write('albumCount: $albumCount, ')
          ..write('trackCount: $trackCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackArtistRecordsTable extends TrackArtistRecords
    with TableInfo<$TrackArtistRecordsTable, TrackArtistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackArtistRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackSourceTypeMeta = const VerificationMeta(
    'trackSourceType',
  );
  @override
  late final GeneratedColumn<String> trackSourceType = GeneratedColumn<String>(
    'track_source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackSourceIdMeta = const VerificationMeta(
    'trackSourceId',
  );
  @override
  late final GeneratedColumn<String> trackSourceId = GeneratedColumn<String>(
    'track_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistSourceIdMeta = const VerificationMeta(
    'artistSourceId',
  );
  @override
  late final GeneratedColumn<String> artistSourceId = GeneratedColumn<String>(
    'artist_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
    'artist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    trackSourceType,
    trackSourceId,
    trackId,
    artistSourceId,
    artistId,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_artists';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackArtistRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_source_type')) {
      context.handle(
        _trackSourceTypeMeta,
        trackSourceType.isAcceptableOrUnknown(
          data['track_source_type']!,
          _trackSourceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceTypeMeta);
    }
    if (data.containsKey('track_source_id')) {
      context.handle(
        _trackSourceIdMeta,
        trackSourceId.isAcceptableOrUnknown(
          data['track_source_id']!,
          _trackSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('artist_source_id')) {
      context.handle(
        _artistSourceIdMeta,
        artistSourceId.isAcceptableOrUnknown(
          data['artist_source_id']!,
          _artistSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_artistSourceIdMeta);
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    trackSourceType,
    trackSourceId,
    trackId,
    artistSourceId,
    artistId,
  };
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {trackSourceType, trackSourceId, trackId, position},
  ];
  @override
  TrackArtistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackArtistRow(
      trackSourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_type'],
      )!,
      trackSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      artistSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_source_id'],
      )!,
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $TrackArtistRecordsTable createAlias(String alias) {
    return $TrackArtistRecordsTable(attachedDatabase, alias);
  }
}

class TrackArtistRow extends DataClass implements Insertable<TrackArtistRow> {
  final String trackSourceType;
  final String trackSourceId;
  final String trackId;
  final String artistSourceId;
  final String artistId;
  final int position;
  const TrackArtistRow({
    required this.trackSourceType,
    required this.trackSourceId,
    required this.trackId,
    required this.artistSourceId,
    required this.artistId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_source_type'] = Variable<String>(trackSourceType);
    map['track_source_id'] = Variable<String>(trackSourceId);
    map['track_id'] = Variable<String>(trackId);
    map['artist_source_id'] = Variable<String>(artistSourceId);
    map['artist_id'] = Variable<String>(artistId);
    map['position'] = Variable<int>(position);
    return map;
  }

  TrackArtistRecordsCompanion toCompanion(bool nullToAbsent) {
    return TrackArtistRecordsCompanion(
      trackSourceType: Value(trackSourceType),
      trackSourceId: Value(trackSourceId),
      trackId: Value(trackId),
      artistSourceId: Value(artistSourceId),
      artistId: Value(artistId),
      position: Value(position),
    );
  }

  factory TrackArtistRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackArtistRow(
      trackSourceType: serializer.fromJson<String>(json['trackSourceType']),
      trackSourceId: serializer.fromJson<String>(json['trackSourceId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      artistSourceId: serializer.fromJson<String>(json['artistSourceId']),
      artistId: serializer.fromJson<String>(json['artistId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackSourceType': serializer.toJson<String>(trackSourceType),
      'trackSourceId': serializer.toJson<String>(trackSourceId),
      'trackId': serializer.toJson<String>(trackId),
      'artistSourceId': serializer.toJson<String>(artistSourceId),
      'artistId': serializer.toJson<String>(artistId),
      'position': serializer.toJson<int>(position),
    };
  }

  TrackArtistRow copyWith({
    String? trackSourceType,
    String? trackSourceId,
    String? trackId,
    String? artistSourceId,
    String? artistId,
    int? position,
  }) => TrackArtistRow(
    trackSourceType: trackSourceType ?? this.trackSourceType,
    trackSourceId: trackSourceId ?? this.trackSourceId,
    trackId: trackId ?? this.trackId,
    artistSourceId: artistSourceId ?? this.artistSourceId,
    artistId: artistId ?? this.artistId,
    position: position ?? this.position,
  );
  TrackArtistRow copyWithCompanion(TrackArtistRecordsCompanion data) {
    return TrackArtistRow(
      trackSourceType: data.trackSourceType.present
          ? data.trackSourceType.value
          : this.trackSourceType,
      trackSourceId: data.trackSourceId.present
          ? data.trackSourceId.value
          : this.trackSourceId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      artistSourceId: data.artistSourceId.present
          ? data.artistSourceId.value
          : this.artistSourceId,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackArtistRow(')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('artistSourceId: $artistSourceId, ')
          ..write('artistId: $artistId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trackSourceType,
    trackSourceId,
    trackId,
    artistSourceId,
    artistId,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackArtistRow &&
          other.trackSourceType == this.trackSourceType &&
          other.trackSourceId == this.trackSourceId &&
          other.trackId == this.trackId &&
          other.artistSourceId == this.artistSourceId &&
          other.artistId == this.artistId &&
          other.position == this.position);
}

class TrackArtistRecordsCompanion extends UpdateCompanion<TrackArtistRow> {
  final Value<String> trackSourceType;
  final Value<String> trackSourceId;
  final Value<String> trackId;
  final Value<String> artistSourceId;
  final Value<String> artistId;
  final Value<int> position;
  final Value<int> rowid;
  const TrackArtistRecordsCompanion({
    this.trackSourceType = const Value.absent(),
    this.trackSourceId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.artistSourceId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackArtistRecordsCompanion.insert({
    required String trackSourceType,
    required String trackSourceId,
    required String trackId,
    required String artistSourceId,
    required String artistId,
    required int position,
    this.rowid = const Value.absent(),
  }) : trackSourceType = Value(trackSourceType),
       trackSourceId = Value(trackSourceId),
       trackId = Value(trackId),
       artistSourceId = Value(artistSourceId),
       artistId = Value(artistId),
       position = Value(position);
  static Insertable<TrackArtistRow> custom({
    Expression<String>? trackSourceType,
    Expression<String>? trackSourceId,
    Expression<String>? trackId,
    Expression<String>? artistSourceId,
    Expression<String>? artistId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackSourceType != null) 'track_source_type': trackSourceType,
      if (trackSourceId != null) 'track_source_id': trackSourceId,
      if (trackId != null) 'track_id': trackId,
      if (artistSourceId != null) 'artist_source_id': artistSourceId,
      if (artistId != null) 'artist_id': artistId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackArtistRecordsCompanion copyWith({
    Value<String>? trackSourceType,
    Value<String>? trackSourceId,
    Value<String>? trackId,
    Value<String>? artistSourceId,
    Value<String>? artistId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return TrackArtistRecordsCompanion(
      trackSourceType: trackSourceType ?? this.trackSourceType,
      trackSourceId: trackSourceId ?? this.trackSourceId,
      trackId: trackId ?? this.trackId,
      artistSourceId: artistSourceId ?? this.artistSourceId,
      artistId: artistId ?? this.artistId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackSourceType.present) {
      map['track_source_type'] = Variable<String>(trackSourceType.value);
    }
    if (trackSourceId.present) {
      map['track_source_id'] = Variable<String>(trackSourceId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (artistSourceId.present) {
      map['artist_source_id'] = Variable<String>(artistSourceId.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackArtistRecordsCompanion(')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('artistSourceId: $artistSourceId, ')
          ..write('artistId: $artistId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlbumArtistRecordsTable extends AlbumArtistRecords
    with TableInfo<$AlbumArtistRecordsTable, AlbumArtistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumArtistRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _albumSourceIdMeta = const VerificationMeta(
    'albumSourceId',
  );
  @override
  late final GeneratedColumn<String> albumSourceId = GeneratedColumn<String>(
    'album_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistSourceIdMeta = const VerificationMeta(
    'artistSourceId',
  );
  @override
  late final GeneratedColumn<String> artistSourceId = GeneratedColumn<String>(
    'artist_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
    'artist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    albumSourceId,
    albumId,
    artistSourceId,
    artistId,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'album_artists';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlbumArtistRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('album_source_id')) {
      context.handle(
        _albumSourceIdMeta,
        albumSourceId.isAcceptableOrUnknown(
          data['album_source_id']!,
          _albumSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_albumSourceIdMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('artist_source_id')) {
      context.handle(
        _artistSourceIdMeta,
        artistSourceId.isAcceptableOrUnknown(
          data['artist_source_id']!,
          _artistSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_artistSourceIdMeta);
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    albumSourceId,
    albumId,
    artistSourceId,
    artistId,
  };
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {albumSourceId, albumId, position},
  ];
  @override
  AlbumArtistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlbumArtistRow(
      albumSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_source_id'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      )!,
      artistSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_source_id'],
      )!,
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $AlbumArtistRecordsTable createAlias(String alias) {
    return $AlbumArtistRecordsTable(attachedDatabase, alias);
  }
}

class AlbumArtistRow extends DataClass implements Insertable<AlbumArtistRow> {
  final String albumSourceId;
  final String albumId;
  final String artistSourceId;
  final String artistId;
  final int position;
  const AlbumArtistRow({
    required this.albumSourceId,
    required this.albumId,
    required this.artistSourceId,
    required this.artistId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['album_source_id'] = Variable<String>(albumSourceId);
    map['album_id'] = Variable<String>(albumId);
    map['artist_source_id'] = Variable<String>(artistSourceId);
    map['artist_id'] = Variable<String>(artistId);
    map['position'] = Variable<int>(position);
    return map;
  }

  AlbumArtistRecordsCompanion toCompanion(bool nullToAbsent) {
    return AlbumArtistRecordsCompanion(
      albumSourceId: Value(albumSourceId),
      albumId: Value(albumId),
      artistSourceId: Value(artistSourceId),
      artistId: Value(artistId),
      position: Value(position),
    );
  }

  factory AlbumArtistRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlbumArtistRow(
      albumSourceId: serializer.fromJson<String>(json['albumSourceId']),
      albumId: serializer.fromJson<String>(json['albumId']),
      artistSourceId: serializer.fromJson<String>(json['artistSourceId']),
      artistId: serializer.fromJson<String>(json['artistId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'albumSourceId': serializer.toJson<String>(albumSourceId),
      'albumId': serializer.toJson<String>(albumId),
      'artistSourceId': serializer.toJson<String>(artistSourceId),
      'artistId': serializer.toJson<String>(artistId),
      'position': serializer.toJson<int>(position),
    };
  }

  AlbumArtistRow copyWith({
    String? albumSourceId,
    String? albumId,
    String? artistSourceId,
    String? artistId,
    int? position,
  }) => AlbumArtistRow(
    albumSourceId: albumSourceId ?? this.albumSourceId,
    albumId: albumId ?? this.albumId,
    artistSourceId: artistSourceId ?? this.artistSourceId,
    artistId: artistId ?? this.artistId,
    position: position ?? this.position,
  );
  AlbumArtistRow copyWithCompanion(AlbumArtistRecordsCompanion data) {
    return AlbumArtistRow(
      albumSourceId: data.albumSourceId.present
          ? data.albumSourceId.value
          : this.albumSourceId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      artistSourceId: data.artistSourceId.present
          ? data.artistSourceId.value
          : this.artistSourceId,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlbumArtistRow(')
          ..write('albumSourceId: $albumSourceId, ')
          ..write('albumId: $albumId, ')
          ..write('artistSourceId: $artistSourceId, ')
          ..write('artistId: $artistId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(albumSourceId, albumId, artistSourceId, artistId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumArtistRow &&
          other.albumSourceId == this.albumSourceId &&
          other.albumId == this.albumId &&
          other.artistSourceId == this.artistSourceId &&
          other.artistId == this.artistId &&
          other.position == this.position);
}

class AlbumArtistRecordsCompanion extends UpdateCompanion<AlbumArtistRow> {
  final Value<String> albumSourceId;
  final Value<String> albumId;
  final Value<String> artistSourceId;
  final Value<String> artistId;
  final Value<int> position;
  final Value<int> rowid;
  const AlbumArtistRecordsCompanion({
    this.albumSourceId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.artistSourceId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlbumArtistRecordsCompanion.insert({
    required String albumSourceId,
    required String albumId,
    required String artistSourceId,
    required String artistId,
    required int position,
    this.rowid = const Value.absent(),
  }) : albumSourceId = Value(albumSourceId),
       albumId = Value(albumId),
       artistSourceId = Value(artistSourceId),
       artistId = Value(artistId),
       position = Value(position);
  static Insertable<AlbumArtistRow> custom({
    Expression<String>? albumSourceId,
    Expression<String>? albumId,
    Expression<String>? artistSourceId,
    Expression<String>? artistId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (albumSourceId != null) 'album_source_id': albumSourceId,
      if (albumId != null) 'album_id': albumId,
      if (artistSourceId != null) 'artist_source_id': artistSourceId,
      if (artistId != null) 'artist_id': artistId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlbumArtistRecordsCompanion copyWith({
    Value<String>? albumSourceId,
    Value<String>? albumId,
    Value<String>? artistSourceId,
    Value<String>? artistId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return AlbumArtistRecordsCompanion(
      albumSourceId: albumSourceId ?? this.albumSourceId,
      albumId: albumId ?? this.albumId,
      artistSourceId: artistSourceId ?? this.artistSourceId,
      artistId: artistId ?? this.artistId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (albumSourceId.present) {
      map['album_source_id'] = Variable<String>(albumSourceId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (artistSourceId.present) {
      map['artist_source_id'] = Variable<String>(artistSourceId.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumArtistRecordsCompanion(')
          ..write('albumSourceId: $albumSourceId, ')
          ..write('albumId: $albumId, ')
          ..write('artistSourceId: $artistSourceId, ')
          ..write('artistId: $artistId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistRecordsTable extends PlaylistRecords
    with TableInfo<$PlaylistRecordsTable, PlaylistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 512,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _systemTypeMeta = const VerificationMeta(
    'systemType',
  );
  @override
  late final GeneratedColumn<String> systemType = GeneratedColumn<String>(
    'system_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playlistId,
    name,
    description,
    createdAtMs,
    updatedAtMs,
    isSystem,
    systemType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('system_type')) {
      context.handle(
        _systemTypeMeta,
        systemType.isAcceptableOrUnknown(data['system_type']!, _systemTypeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId};
  @override
  PlaylistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistRow(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      systemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_type'],
      ),
    );
  }

  @override
  $PlaylistRecordsTable createAlias(String alias) {
    return $PlaylistRecordsTable(attachedDatabase, alias);
  }
}

class PlaylistRow extends DataClass implements Insertable<PlaylistRow> {
  final String playlistId;
  final String name;
  final String description;
  final int createdAtMs;
  final int updatedAtMs;
  final bool isSystem;
  final String? systemType;
  const PlaylistRow({
    required this.playlistId,
    required this.name,
    required this.description,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.isSystem,
    this.systemType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['is_system'] = Variable<bool>(isSystem);
    if (!nullToAbsent || systemType != null) {
      map['system_type'] = Variable<String>(systemType);
    }
    return map;
  }

  PlaylistRecordsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistRecordsCompanion(
      playlistId: Value(playlistId),
      name: Value(name),
      description: Value(description),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      isSystem: Value(isSystem),
      systemType: systemType == null && nullToAbsent
          ? const Value.absent()
          : Value(systemType),
    );
  }

  factory PlaylistRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistRow(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      systemType: serializer.fromJson<String?>(json['systemType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'isSystem': serializer.toJson<bool>(isSystem),
      'systemType': serializer.toJson<String?>(systemType),
    };
  }

  PlaylistRow copyWith({
    String? playlistId,
    String? name,
    String? description,
    int? createdAtMs,
    int? updatedAtMs,
    bool? isSystem,
    Value<String?> systemType = const Value.absent(),
  }) => PlaylistRow(
    playlistId: playlistId ?? this.playlistId,
    name: name ?? this.name,
    description: description ?? this.description,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    isSystem: isSystem ?? this.isSystem,
    systemType: systemType.present ? systemType.value : this.systemType,
  );
  PlaylistRow copyWithCompanion(PlaylistRecordsCompanion data) {
    return PlaylistRow(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      systemType: data.systemType.present
          ? data.systemType.value
          : this.systemType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistRow(')
          ..write('playlistId: $playlistId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('isSystem: $isSystem, ')
          ..write('systemType: $systemType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    playlistId,
    name,
    description,
    createdAtMs,
    updatedAtMs,
    isSystem,
    systemType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistRow &&
          other.playlistId == this.playlistId &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.isSystem == this.isSystem &&
          other.systemType == this.systemType);
}

class PlaylistRecordsCompanion extends UpdateCompanion<PlaylistRow> {
  final Value<String> playlistId;
  final Value<String> name;
  final Value<String> description;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<bool> isSystem;
  final Value<String?> systemType;
  final Value<int> rowid;
  const PlaylistRecordsCompanion({
    this.playlistId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.systemType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistRecordsCompanion.insert({
    required String playlistId,
    required String name,
    this.description = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.isSystem = const Value.absent(),
    this.systemType = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       name = Value(name),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<PlaylistRow> custom({
    Expression<String>? playlistId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<bool>? isSystem,
    Expression<String>? systemType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (isSystem != null) 'is_system': isSystem,
      if (systemType != null) 'system_type': systemType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistRecordsCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? name,
    Value<String>? description,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<bool>? isSystem,
    Value<String?>? systemType,
    Value<int>? rowid,
  }) {
    return PlaylistRecordsCompanion(
      playlistId: playlistId ?? this.playlistId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      isSystem: isSystem ?? this.isSystem,
      systemType: systemType ?? this.systemType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (systemType.present) {
      map['system_type'] = Variable<String>(systemType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistRecordsCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('isSystem: $isSystem, ')
          ..write('systemType: $systemType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistEntryRecordsTable extends PlaylistEntryRecords
    with TableInfo<$PlaylistEntryRecordsTable, PlaylistEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistEntryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (playlist_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _trackSourceTypeMeta = const VerificationMeta(
    'trackSourceType',
  );
  @override
  late final GeneratedColumn<String> trackSourceType = GeneratedColumn<String>(
    'track_source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackSourceIdMeta = const VerificationMeta(
    'trackSourceId',
  );
  @override
  late final GeneratedColumn<String> trackSourceId = GeneratedColumn<String>(
    'track_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMsMeta = const VerificationMeta(
    'addedAtMs',
  );
  @override
  late final GeneratedColumn<int> addedAtMs = GeneratedColumn<int>(
    'added_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    playlistId,
    trackSourceType,
    trackSourceId,
    trackId,
    position,
    addedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_source_type')) {
      context.handle(
        _trackSourceTypeMeta,
        trackSourceType.isAcceptableOrUnknown(
          data['track_source_type']!,
          _trackSourceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceTypeMeta);
    }
    if (data.containsKey('track_source_id')) {
      context.handle(
        _trackSourceIdMeta,
        trackSourceId.isAcceptableOrUnknown(
          data['track_source_id']!,
          _trackSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('added_at_ms')) {
      context.handle(
        _addedAtMsMeta,
        addedAtMs.isAcceptableOrUnknown(data['added_at_ms']!, _addedAtMsMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {playlistId, position},
  ];
  @override
  PlaylistEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistEntryRow(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackSourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_type'],
      )!,
      trackSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      addedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at_ms'],
      )!,
    );
  }

  @override
  $PlaylistEntryRecordsTable createAlias(String alias) {
    return $PlaylistEntryRecordsTable(attachedDatabase, alias);
  }
}

class PlaylistEntryRow extends DataClass
    implements Insertable<PlaylistEntryRow> {
  final String entryId;
  final String playlistId;
  final String trackSourceType;
  final String trackSourceId;
  final String trackId;
  final int position;
  final int addedAtMs;
  const PlaylistEntryRow({
    required this.entryId,
    required this.playlistId,
    required this.trackSourceType,
    required this.trackSourceId,
    required this.trackId,
    required this.position,
    required this.addedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['playlist_id'] = Variable<String>(playlistId);
    map['track_source_type'] = Variable<String>(trackSourceType);
    map['track_source_id'] = Variable<String>(trackSourceId);
    map['track_id'] = Variable<String>(trackId);
    map['position'] = Variable<int>(position);
    map['added_at_ms'] = Variable<int>(addedAtMs);
    return map;
  }

  PlaylistEntryRecordsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistEntryRecordsCompanion(
      entryId: Value(entryId),
      playlistId: Value(playlistId),
      trackSourceType: Value(trackSourceType),
      trackSourceId: Value(trackSourceId),
      trackId: Value(trackId),
      position: Value(position),
      addedAtMs: Value(addedAtMs),
    );
  }

  factory PlaylistEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistEntryRow(
      entryId: serializer.fromJson<String>(json['entryId']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      trackSourceType: serializer.fromJson<String>(json['trackSourceType']),
      trackSourceId: serializer.fromJson<String>(json['trackSourceId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      position: serializer.fromJson<int>(json['position']),
      addedAtMs: serializer.fromJson<int>(json['addedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'playlistId': serializer.toJson<String>(playlistId),
      'trackSourceType': serializer.toJson<String>(trackSourceType),
      'trackSourceId': serializer.toJson<String>(trackSourceId),
      'trackId': serializer.toJson<String>(trackId),
      'position': serializer.toJson<int>(position),
      'addedAtMs': serializer.toJson<int>(addedAtMs),
    };
  }

  PlaylistEntryRow copyWith({
    String? entryId,
    String? playlistId,
    String? trackSourceType,
    String? trackSourceId,
    String? trackId,
    int? position,
    int? addedAtMs,
  }) => PlaylistEntryRow(
    entryId: entryId ?? this.entryId,
    playlistId: playlistId ?? this.playlistId,
    trackSourceType: trackSourceType ?? this.trackSourceType,
    trackSourceId: trackSourceId ?? this.trackSourceId,
    trackId: trackId ?? this.trackId,
    position: position ?? this.position,
    addedAtMs: addedAtMs ?? this.addedAtMs,
  );
  PlaylistEntryRow copyWithCompanion(PlaylistEntryRecordsCompanion data) {
    return PlaylistEntryRow(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackSourceType: data.trackSourceType.present
          ? data.trackSourceType.value
          : this.trackSourceType,
      trackSourceId: data.trackSourceId.present
          ? data.trackSourceId.value
          : this.trackSourceId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      position: data.position.present ? data.position.value : this.position,
      addedAtMs: data.addedAtMs.present ? data.addedAtMs.value : this.addedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntryRow(')
          ..write('entryId: $entryId, ')
          ..write('playlistId: $playlistId, ')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position, ')
          ..write('addedAtMs: $addedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entryId,
    playlistId,
    trackSourceType,
    trackSourceId,
    trackId,
    position,
    addedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistEntryRow &&
          other.entryId == this.entryId &&
          other.playlistId == this.playlistId &&
          other.trackSourceType == this.trackSourceType &&
          other.trackSourceId == this.trackSourceId &&
          other.trackId == this.trackId &&
          other.position == this.position &&
          other.addedAtMs == this.addedAtMs);
}

class PlaylistEntryRecordsCompanion extends UpdateCompanion<PlaylistEntryRow> {
  final Value<String> entryId;
  final Value<String> playlistId;
  final Value<String> trackSourceType;
  final Value<String> trackSourceId;
  final Value<String> trackId;
  final Value<int> position;
  final Value<int> addedAtMs;
  final Value<int> rowid;
  const PlaylistEntryRecordsCompanion({
    this.entryId = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.trackSourceType = const Value.absent(),
    this.trackSourceId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.position = const Value.absent(),
    this.addedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistEntryRecordsCompanion.insert({
    required String entryId,
    required String playlistId,
    required String trackSourceType,
    required String trackSourceId,
    required String trackId,
    required int position,
    required int addedAtMs,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       playlistId = Value(playlistId),
       trackSourceType = Value(trackSourceType),
       trackSourceId = Value(trackSourceId),
       trackId = Value(trackId),
       position = Value(position),
       addedAtMs = Value(addedAtMs);
  static Insertable<PlaylistEntryRow> custom({
    Expression<String>? entryId,
    Expression<String>? playlistId,
    Expression<String>? trackSourceType,
    Expression<String>? trackSourceId,
    Expression<String>? trackId,
    Expression<int>? position,
    Expression<int>? addedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackSourceType != null) 'track_source_type': trackSourceType,
      if (trackSourceId != null) 'track_source_id': trackSourceId,
      if (trackId != null) 'track_id': trackId,
      if (position != null) 'position': position,
      if (addedAtMs != null) 'added_at_ms': addedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistEntryRecordsCompanion copyWith({
    Value<String>? entryId,
    Value<String>? playlistId,
    Value<String>? trackSourceType,
    Value<String>? trackSourceId,
    Value<String>? trackId,
    Value<int>? position,
    Value<int>? addedAtMs,
    Value<int>? rowid,
  }) {
    return PlaylistEntryRecordsCompanion(
      entryId: entryId ?? this.entryId,
      playlistId: playlistId ?? this.playlistId,
      trackSourceType: trackSourceType ?? this.trackSourceType,
      trackSourceId: trackSourceId ?? this.trackSourceId,
      trackId: trackId ?? this.trackId,
      position: position ?? this.position,
      addedAtMs: addedAtMs ?? this.addedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (trackSourceType.present) {
      map['track_source_type'] = Variable<String>(trackSourceType.value);
    }
    if (trackSourceId.present) {
      map['track_source_id'] = Variable<String>(trackSourceId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (addedAtMs.present) {
      map['added_at_ms'] = Variable<int>(addedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntryRecordsCompanion(')
          ..write('entryId: $entryId, ')
          ..write('playlistId: $playlistId, ')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position, ')
          ..write('addedAtMs: $addedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteRecordsTable extends FavoriteRecords
    with TableInfo<$FavoriteRecordsTable, FavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackSourceTypeMeta = const VerificationMeta(
    'trackSourceType',
  );
  @override
  late final GeneratedColumn<String> trackSourceType = GeneratedColumn<String>(
    'track_source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackSourceIdMeta = const VerificationMeta(
    'trackSourceId',
  );
  @override
  late final GeneratedColumn<String> trackSourceId = GeneratedColumn<String>(
    'track_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMsMeta = const VerificationMeta(
    'addedAtMs',
  );
  @override
  late final GeneratedColumn<int> addedAtMs = GeneratedColumn<int>(
    'added_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    trackSourceType,
    trackSourceId,
    trackId,
    addedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_source_type')) {
      context.handle(
        _trackSourceTypeMeta,
        trackSourceType.isAcceptableOrUnknown(
          data['track_source_type']!,
          _trackSourceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceTypeMeta);
    }
    if (data.containsKey('track_source_id')) {
      context.handle(
        _trackSourceIdMeta,
        trackSourceId.isAcceptableOrUnknown(
          data['track_source_id']!,
          _trackSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('added_at_ms')) {
      context.handle(
        _addedAtMsMeta,
        addedAtMs.isAcceptableOrUnknown(data['added_at_ms']!, _addedAtMsMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    trackSourceType,
    trackSourceId,
    trackId,
  };
  @override
  FavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteRow(
      trackSourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_type'],
      )!,
      trackSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      addedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at_ms'],
      )!,
    );
  }

  @override
  $FavoriteRecordsTable createAlias(String alias) {
    return $FavoriteRecordsTable(attachedDatabase, alias);
  }
}

class FavoriteRow extends DataClass implements Insertable<FavoriteRow> {
  final String trackSourceType;
  final String trackSourceId;
  final String trackId;
  final int addedAtMs;
  const FavoriteRow({
    required this.trackSourceType,
    required this.trackSourceId,
    required this.trackId,
    required this.addedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_source_type'] = Variable<String>(trackSourceType);
    map['track_source_id'] = Variable<String>(trackSourceId);
    map['track_id'] = Variable<String>(trackId);
    map['added_at_ms'] = Variable<int>(addedAtMs);
    return map;
  }

  FavoriteRecordsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteRecordsCompanion(
      trackSourceType: Value(trackSourceType),
      trackSourceId: Value(trackSourceId),
      trackId: Value(trackId),
      addedAtMs: Value(addedAtMs),
    );
  }

  factory FavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteRow(
      trackSourceType: serializer.fromJson<String>(json['trackSourceType']),
      trackSourceId: serializer.fromJson<String>(json['trackSourceId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      addedAtMs: serializer.fromJson<int>(json['addedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackSourceType': serializer.toJson<String>(trackSourceType),
      'trackSourceId': serializer.toJson<String>(trackSourceId),
      'trackId': serializer.toJson<String>(trackId),
      'addedAtMs': serializer.toJson<int>(addedAtMs),
    };
  }

  FavoriteRow copyWith({
    String? trackSourceType,
    String? trackSourceId,
    String? trackId,
    int? addedAtMs,
  }) => FavoriteRow(
    trackSourceType: trackSourceType ?? this.trackSourceType,
    trackSourceId: trackSourceId ?? this.trackSourceId,
    trackId: trackId ?? this.trackId,
    addedAtMs: addedAtMs ?? this.addedAtMs,
  );
  FavoriteRow copyWithCompanion(FavoriteRecordsCompanion data) {
    return FavoriteRow(
      trackSourceType: data.trackSourceType.present
          ? data.trackSourceType.value
          : this.trackSourceType,
      trackSourceId: data.trackSourceId.present
          ? data.trackSourceId.value
          : this.trackSourceId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      addedAtMs: data.addedAtMs.present ? data.addedAtMs.value : this.addedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteRow(')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('addedAtMs: $addedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(trackSourceType, trackSourceId, trackId, addedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteRow &&
          other.trackSourceType == this.trackSourceType &&
          other.trackSourceId == this.trackSourceId &&
          other.trackId == this.trackId &&
          other.addedAtMs == this.addedAtMs);
}

class FavoriteRecordsCompanion extends UpdateCompanion<FavoriteRow> {
  final Value<String> trackSourceType;
  final Value<String> trackSourceId;
  final Value<String> trackId;
  final Value<int> addedAtMs;
  final Value<int> rowid;
  const FavoriteRecordsCompanion({
    this.trackSourceType = const Value.absent(),
    this.trackSourceId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.addedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteRecordsCompanion.insert({
    required String trackSourceType,
    required String trackSourceId,
    required String trackId,
    required int addedAtMs,
    this.rowid = const Value.absent(),
  }) : trackSourceType = Value(trackSourceType),
       trackSourceId = Value(trackSourceId),
       trackId = Value(trackId),
       addedAtMs = Value(addedAtMs);
  static Insertable<FavoriteRow> custom({
    Expression<String>? trackSourceType,
    Expression<String>? trackSourceId,
    Expression<String>? trackId,
    Expression<int>? addedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackSourceType != null) 'track_source_type': trackSourceType,
      if (trackSourceId != null) 'track_source_id': trackSourceId,
      if (trackId != null) 'track_id': trackId,
      if (addedAtMs != null) 'added_at_ms': addedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteRecordsCompanion copyWith({
    Value<String>? trackSourceType,
    Value<String>? trackSourceId,
    Value<String>? trackId,
    Value<int>? addedAtMs,
    Value<int>? rowid,
  }) {
    return FavoriteRecordsCompanion(
      trackSourceType: trackSourceType ?? this.trackSourceType,
      trackSourceId: trackSourceId ?? this.trackSourceId,
      trackId: trackId ?? this.trackId,
      addedAtMs: addedAtMs ?? this.addedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackSourceType.present) {
      map['track_source_type'] = Variable<String>(trackSourceType.value);
    }
    if (trackSourceId.present) {
      map['track_source_id'] = Variable<String>(trackSourceId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (addedAtMs.present) {
      map['added_at_ms'] = Variable<int>(addedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteRecordsCompanion(')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('addedAtMs: $addedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayHistoryRecordsTable extends PlayHistoryRecords
    with TableInfo<$PlayHistoryRecordsTable, PlayHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayHistoryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _historyIdMeta = const VerificationMeta(
    'historyId',
  );
  @override
  late final GeneratedColumn<String> historyId = GeneratedColumn<String>(
    'history_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackSourceTypeMeta = const VerificationMeta(
    'trackSourceType',
  );
  @override
  late final GeneratedColumn<String> trackSourceType = GeneratedColumn<String>(
    'track_source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackSourceIdMeta = const VerificationMeta(
    'trackSourceId',
  );
  @override
  late final GeneratedColumn<String> trackSourceId = GeneratedColumn<String>(
    'track_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  @override
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPositionMsMeta = const VerificationMeta(
    'lastPositionMs',
  );
  @override
  late final GeneratedColumn<int> lastPositionMs = GeneratedColumn<int>(
    'last_position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    historyId,
    trackSourceType,
    trackSourceId,
    trackId,
    startedAtMs,
    lastPositionMs,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('history_id')) {
      context.handle(
        _historyIdMeta,
        historyId.isAcceptableOrUnknown(data['history_id']!, _historyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_historyIdMeta);
    }
    if (data.containsKey('track_source_type')) {
      context.handle(
        _trackSourceTypeMeta,
        trackSourceType.isAcceptableOrUnknown(
          data['track_source_type']!,
          _trackSourceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceTypeMeta);
    }
    if (data.containsKey('track_source_id')) {
      context.handle(
        _trackSourceIdMeta,
        trackSourceId.isAcceptableOrUnknown(
          data['track_source_id']!,
          _trackSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('last_position_ms')) {
      context.handle(
        _lastPositionMsMeta,
        lastPositionMs.isAcceptableOrUnknown(
          data['last_position_ms']!,
          _lastPositionMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastPositionMsMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {historyId};
  @override
  PlayHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayHistoryRow(
      historyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}history_id'],
      )!,
      trackSourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_type'],
      )!,
      trackSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      )!,
      lastPositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_position_ms'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $PlayHistoryRecordsTable createAlias(String alias) {
    return $PlayHistoryRecordsTable(attachedDatabase, alias);
  }
}

class PlayHistoryRow extends DataClass implements Insertable<PlayHistoryRow> {
  final String historyId;
  final String trackSourceType;
  final String trackSourceId;
  final String trackId;
  final int startedAtMs;
  final int lastPositionMs;
  final bool completed;
  const PlayHistoryRow({
    required this.historyId,
    required this.trackSourceType,
    required this.trackSourceId,
    required this.trackId,
    required this.startedAtMs,
    required this.lastPositionMs,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['history_id'] = Variable<String>(historyId);
    map['track_source_type'] = Variable<String>(trackSourceType);
    map['track_source_id'] = Variable<String>(trackSourceId);
    map['track_id'] = Variable<String>(trackId);
    map['started_at_ms'] = Variable<int>(startedAtMs);
    map['last_position_ms'] = Variable<int>(lastPositionMs);
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  PlayHistoryRecordsCompanion toCompanion(bool nullToAbsent) {
    return PlayHistoryRecordsCompanion(
      historyId: Value(historyId),
      trackSourceType: Value(trackSourceType),
      trackSourceId: Value(trackSourceId),
      trackId: Value(trackId),
      startedAtMs: Value(startedAtMs),
      lastPositionMs: Value(lastPositionMs),
      completed: Value(completed),
    );
  }

  factory PlayHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayHistoryRow(
      historyId: serializer.fromJson<String>(json['historyId']),
      trackSourceType: serializer.fromJson<String>(json['trackSourceType']),
      trackSourceId: serializer.fromJson<String>(json['trackSourceId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      startedAtMs: serializer.fromJson<int>(json['startedAtMs']),
      lastPositionMs: serializer.fromJson<int>(json['lastPositionMs']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'historyId': serializer.toJson<String>(historyId),
      'trackSourceType': serializer.toJson<String>(trackSourceType),
      'trackSourceId': serializer.toJson<String>(trackSourceId),
      'trackId': serializer.toJson<String>(trackId),
      'startedAtMs': serializer.toJson<int>(startedAtMs),
      'lastPositionMs': serializer.toJson<int>(lastPositionMs),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  PlayHistoryRow copyWith({
    String? historyId,
    String? trackSourceType,
    String? trackSourceId,
    String? trackId,
    int? startedAtMs,
    int? lastPositionMs,
    bool? completed,
  }) => PlayHistoryRow(
    historyId: historyId ?? this.historyId,
    trackSourceType: trackSourceType ?? this.trackSourceType,
    trackSourceId: trackSourceId ?? this.trackSourceId,
    trackId: trackId ?? this.trackId,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    lastPositionMs: lastPositionMs ?? this.lastPositionMs,
    completed: completed ?? this.completed,
  );
  PlayHistoryRow copyWithCompanion(PlayHistoryRecordsCompanion data) {
    return PlayHistoryRow(
      historyId: data.historyId.present ? data.historyId.value : this.historyId,
      trackSourceType: data.trackSourceType.present
          ? data.trackSourceType.value
          : this.trackSourceType,
      trackSourceId: data.trackSourceId.present
          ? data.trackSourceId.value
          : this.trackSourceId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      lastPositionMs: data.lastPositionMs.present
          ? data.lastPositionMs.value
          : this.lastPositionMs,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryRow(')
          ..write('historyId: $historyId, ')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    historyId,
    trackSourceType,
    trackSourceId,
    trackId,
    startedAtMs,
    lastPositionMs,
    completed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayHistoryRow &&
          other.historyId == this.historyId &&
          other.trackSourceType == this.trackSourceType &&
          other.trackSourceId == this.trackSourceId &&
          other.trackId == this.trackId &&
          other.startedAtMs == this.startedAtMs &&
          other.lastPositionMs == this.lastPositionMs &&
          other.completed == this.completed);
}

class PlayHistoryRecordsCompanion extends UpdateCompanion<PlayHistoryRow> {
  final Value<String> historyId;
  final Value<String> trackSourceType;
  final Value<String> trackSourceId;
  final Value<String> trackId;
  final Value<int> startedAtMs;
  final Value<int> lastPositionMs;
  final Value<bool> completed;
  final Value<int> rowid;
  const PlayHistoryRecordsCompanion({
    this.historyId = const Value.absent(),
    this.trackSourceType = const Value.absent(),
    this.trackSourceId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.lastPositionMs = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayHistoryRecordsCompanion.insert({
    required String historyId,
    required String trackSourceType,
    required String trackSourceId,
    required String trackId,
    required int startedAtMs,
    required int lastPositionMs,
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : historyId = Value(historyId),
       trackSourceType = Value(trackSourceType),
       trackSourceId = Value(trackSourceId),
       trackId = Value(trackId),
       startedAtMs = Value(startedAtMs),
       lastPositionMs = Value(lastPositionMs);
  static Insertable<PlayHistoryRow> custom({
    Expression<String>? historyId,
    Expression<String>? trackSourceType,
    Expression<String>? trackSourceId,
    Expression<String>? trackId,
    Expression<int>? startedAtMs,
    Expression<int>? lastPositionMs,
    Expression<bool>? completed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (historyId != null) 'history_id': historyId,
      if (trackSourceType != null) 'track_source_type': trackSourceType,
      if (trackSourceId != null) 'track_source_id': trackSourceId,
      if (trackId != null) 'track_id': trackId,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (lastPositionMs != null) 'last_position_ms': lastPositionMs,
      if (completed != null) 'completed': completed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayHistoryRecordsCompanion copyWith({
    Value<String>? historyId,
    Value<String>? trackSourceType,
    Value<String>? trackSourceId,
    Value<String>? trackId,
    Value<int>? startedAtMs,
    Value<int>? lastPositionMs,
    Value<bool>? completed,
    Value<int>? rowid,
  }) {
    return PlayHistoryRecordsCompanion(
      historyId: historyId ?? this.historyId,
      trackSourceType: trackSourceType ?? this.trackSourceType,
      trackSourceId: trackSourceId ?? this.trackSourceId,
      trackId: trackId ?? this.trackId,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      lastPositionMs: lastPositionMs ?? this.lastPositionMs,
      completed: completed ?? this.completed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (historyId.present) {
      map['history_id'] = Variable<String>(historyId.value);
    }
    if (trackSourceType.present) {
      map['track_source_type'] = Variable<String>(trackSourceType.value);
    }
    if (trackSourceId.present) {
      map['track_source_id'] = Variable<String>(trackSourceId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (lastPositionMs.present) {
      map['last_position_ms'] = Variable<int>(lastPositionMs.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryRecordsCompanion(')
          ..write('historyId: $historyId, ')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('completed: $completed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueueEntryRecordsTable extends QueueEntryRecords
    with TableInfo<$QueueEntryRecordsTable, QueueEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueEntryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackSourceTypeMeta = const VerificationMeta(
    'trackSourceType',
  );
  @override
  late final GeneratedColumn<String> trackSourceType = GeneratedColumn<String>(
    'track_source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackSourceIdMeta = const VerificationMeta(
    'trackSourceId',
  );
  @override
  late final GeneratedColumn<String> trackSourceId = GeneratedColumn<String>(
    'track_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _addedAtMsMeta = const VerificationMeta(
    'addedAtMs',
  );
  @override
  late final GeneratedColumn<int> addedAtMs = GeneratedColumn<int>(
    'added_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    trackSourceType,
    trackSourceId,
    trackId,
    position,
    addedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('track_source_type')) {
      context.handle(
        _trackSourceTypeMeta,
        trackSourceType.isAcceptableOrUnknown(
          data['track_source_type']!,
          _trackSourceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceTypeMeta);
    }
    if (data.containsKey('track_source_id')) {
      context.handle(
        _trackSourceIdMeta,
        trackSourceId.isAcceptableOrUnknown(
          data['track_source_id']!,
          _trackSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('added_at_ms')) {
      context.handle(
        _addedAtMsMeta,
        addedAtMs.isAcceptableOrUnknown(data['added_at_ms']!, _addedAtMsMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  QueueEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueEntryRow(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      trackSourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_type'],
      )!,
      trackSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      addedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at_ms'],
      )!,
    );
  }

  @override
  $QueueEntryRecordsTable createAlias(String alias) {
    return $QueueEntryRecordsTable(attachedDatabase, alias);
  }
}

class QueueEntryRow extends DataClass implements Insertable<QueueEntryRow> {
  final String entryId;
  final String trackSourceType;
  final String trackSourceId;
  final String trackId;
  final int position;
  final int addedAtMs;
  const QueueEntryRow({
    required this.entryId,
    required this.trackSourceType,
    required this.trackSourceId,
    required this.trackId,
    required this.position,
    required this.addedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['track_source_type'] = Variable<String>(trackSourceType);
    map['track_source_id'] = Variable<String>(trackSourceId);
    map['track_id'] = Variable<String>(trackId);
    map['position'] = Variable<int>(position);
    map['added_at_ms'] = Variable<int>(addedAtMs);
    return map;
  }

  QueueEntryRecordsCompanion toCompanion(bool nullToAbsent) {
    return QueueEntryRecordsCompanion(
      entryId: Value(entryId),
      trackSourceType: Value(trackSourceType),
      trackSourceId: Value(trackSourceId),
      trackId: Value(trackId),
      position: Value(position),
      addedAtMs: Value(addedAtMs),
    );
  }

  factory QueueEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueEntryRow(
      entryId: serializer.fromJson<String>(json['entryId']),
      trackSourceType: serializer.fromJson<String>(json['trackSourceType']),
      trackSourceId: serializer.fromJson<String>(json['trackSourceId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      position: serializer.fromJson<int>(json['position']),
      addedAtMs: serializer.fromJson<int>(json['addedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'trackSourceType': serializer.toJson<String>(trackSourceType),
      'trackSourceId': serializer.toJson<String>(trackSourceId),
      'trackId': serializer.toJson<String>(trackId),
      'position': serializer.toJson<int>(position),
      'addedAtMs': serializer.toJson<int>(addedAtMs),
    };
  }

  QueueEntryRow copyWith({
    String? entryId,
    String? trackSourceType,
    String? trackSourceId,
    String? trackId,
    int? position,
    int? addedAtMs,
  }) => QueueEntryRow(
    entryId: entryId ?? this.entryId,
    trackSourceType: trackSourceType ?? this.trackSourceType,
    trackSourceId: trackSourceId ?? this.trackSourceId,
    trackId: trackId ?? this.trackId,
    position: position ?? this.position,
    addedAtMs: addedAtMs ?? this.addedAtMs,
  );
  QueueEntryRow copyWithCompanion(QueueEntryRecordsCompanion data) {
    return QueueEntryRow(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      trackSourceType: data.trackSourceType.present
          ? data.trackSourceType.value
          : this.trackSourceType,
      trackSourceId: data.trackSourceId.present
          ? data.trackSourceId.value
          : this.trackSourceId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      position: data.position.present ? data.position.value : this.position,
      addedAtMs: data.addedAtMs.present ? data.addedAtMs.value : this.addedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueEntryRow(')
          ..write('entryId: $entryId, ')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position, ')
          ..write('addedAtMs: $addedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entryId,
    trackSourceType,
    trackSourceId,
    trackId,
    position,
    addedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueEntryRow &&
          other.entryId == this.entryId &&
          other.trackSourceType == this.trackSourceType &&
          other.trackSourceId == this.trackSourceId &&
          other.trackId == this.trackId &&
          other.position == this.position &&
          other.addedAtMs == this.addedAtMs);
}

class QueueEntryRecordsCompanion extends UpdateCompanion<QueueEntryRow> {
  final Value<String> entryId;
  final Value<String> trackSourceType;
  final Value<String> trackSourceId;
  final Value<String> trackId;
  final Value<int> position;
  final Value<int> addedAtMs;
  final Value<int> rowid;
  const QueueEntryRecordsCompanion({
    this.entryId = const Value.absent(),
    this.trackSourceType = const Value.absent(),
    this.trackSourceId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.position = const Value.absent(),
    this.addedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueueEntryRecordsCompanion.insert({
    required String entryId,
    required String trackSourceType,
    required String trackSourceId,
    required String trackId,
    required int position,
    required int addedAtMs,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       trackSourceType = Value(trackSourceType),
       trackSourceId = Value(trackSourceId),
       trackId = Value(trackId),
       position = Value(position),
       addedAtMs = Value(addedAtMs);
  static Insertable<QueueEntryRow> custom({
    Expression<String>? entryId,
    Expression<String>? trackSourceType,
    Expression<String>? trackSourceId,
    Expression<String>? trackId,
    Expression<int>? position,
    Expression<int>? addedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (trackSourceType != null) 'track_source_type': trackSourceType,
      if (trackSourceId != null) 'track_source_id': trackSourceId,
      if (trackId != null) 'track_id': trackId,
      if (position != null) 'position': position,
      if (addedAtMs != null) 'added_at_ms': addedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueueEntryRecordsCompanion copyWith({
    Value<String>? entryId,
    Value<String>? trackSourceType,
    Value<String>? trackSourceId,
    Value<String>? trackId,
    Value<int>? position,
    Value<int>? addedAtMs,
    Value<int>? rowid,
  }) {
    return QueueEntryRecordsCompanion(
      entryId: entryId ?? this.entryId,
      trackSourceType: trackSourceType ?? this.trackSourceType,
      trackSourceId: trackSourceId ?? this.trackSourceId,
      trackId: trackId ?? this.trackId,
      position: position ?? this.position,
      addedAtMs: addedAtMs ?? this.addedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (trackSourceType.present) {
      map['track_source_type'] = Variable<String>(trackSourceType.value);
    }
    if (trackSourceId.present) {
      map['track_source_id'] = Variable<String>(trackSourceId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (addedAtMs.present) {
      map['added_at_ms'] = Variable<int>(addedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueEntryRecordsCompanion(')
          ..write('entryId: $entryId, ')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position, ')
          ..write('addedAtMs: $addedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueueStateRecordsTable extends QueueStateRecords
    with TableInfo<$QueueStateRecordsTable, QueueStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueStateRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  @override
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentEntryIdMeta = const VerificationMeta(
    'currentEntryId',
  );
  @override
  late final GeneratedColumn<String> currentEntryId = GeneratedColumn<String>(
    'current_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES queue_entries (entry_id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    singletonId,
    currentEntryId,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('current_entry_id')) {
      context.handle(
        _currentEntryIdMeta,
        currentEntryId.isAcceptableOrUnknown(
          data['current_entry_id']!,
          _currentEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  QueueStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueStateRow(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      currentEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_entry_id'],
      ),
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $QueueStateRecordsTable createAlias(String alias) {
    return $QueueStateRecordsTable(attachedDatabase, alias);
  }
}

class QueueStateRow extends DataClass implements Insertable<QueueStateRow> {
  final int singletonId;
  final String? currentEntryId;
  final int updatedAtMs;
  const QueueStateRow({
    required this.singletonId,
    this.currentEntryId,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    if (!nullToAbsent || currentEntryId != null) {
      map['current_entry_id'] = Variable<String>(currentEntryId);
    }
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  QueueStateRecordsCompanion toCompanion(bool nullToAbsent) {
    return QueueStateRecordsCompanion(
      singletonId: Value(singletonId),
      currentEntryId: currentEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentEntryId),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory QueueStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueStateRow(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      currentEntryId: serializer.fromJson<String?>(json['currentEntryId']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'currentEntryId': serializer.toJson<String?>(currentEntryId),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  QueueStateRow copyWith({
    int? singletonId,
    Value<String?> currentEntryId = const Value.absent(),
    int? updatedAtMs,
  }) => QueueStateRow(
    singletonId: singletonId ?? this.singletonId,
    currentEntryId: currentEntryId.present
        ? currentEntryId.value
        : this.currentEntryId,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  QueueStateRow copyWithCompanion(QueueStateRecordsCompanion data) {
    return QueueStateRow(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      currentEntryId: data.currentEntryId.present
          ? data.currentEntryId.value
          : this.currentEntryId,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueStateRow(')
          ..write('singletonId: $singletonId, ')
          ..write('currentEntryId: $currentEntryId, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(singletonId, currentEntryId, updatedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueStateRow &&
          other.singletonId == this.singletonId &&
          other.currentEntryId == this.currentEntryId &&
          other.updatedAtMs == this.updatedAtMs);
}

class QueueStateRecordsCompanion extends UpdateCompanion<QueueStateRow> {
  final Value<int> singletonId;
  final Value<String?> currentEntryId;
  final Value<int> updatedAtMs;
  const QueueStateRecordsCompanion({
    this.singletonId = const Value.absent(),
    this.currentEntryId = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
  });
  QueueStateRecordsCompanion.insert({
    this.singletonId = const Value.absent(),
    this.currentEntryId = const Value.absent(),
    required int updatedAtMs,
  }) : updatedAtMs = Value(updatedAtMs);
  static Insertable<QueueStateRow> custom({
    Expression<int>? singletonId,
    Expression<String>? currentEntryId,
    Expression<int>? updatedAtMs,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (currentEntryId != null) 'current_entry_id': currentEntryId,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
    });
  }

  QueueStateRecordsCompanion copyWith({
    Value<int>? singletonId,
    Value<String?>? currentEntryId,
    Value<int>? updatedAtMs,
  }) {
    return QueueStateRecordsCompanion(
      singletonId: singletonId ?? this.singletonId,
      currentEntryId: currentEntryId ?? this.currentEntryId,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (currentEntryId.present) {
      map['current_entry_id'] = Variable<String>(currentEntryId.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueStateRecordsCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('currentEntryId: $currentEntryId, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }
}

class $MusicSourceRecordsTable extends MusicSourceRecords
    with TableInfo<$MusicSourceRecordsTable, MusicSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MusicSourceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 512,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authTypeMeta = const VerificationMeta(
    'authType',
  );
  @override
  late final GeneratedColumn<String> authType = GeneratedColumn<String>(
    'auth_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _credentialRefMeta = const VerificationMeta(
    'credentialRef',
  );
  @override
  late final GeneratedColumn<String> credentialRef = GeneratedColumn<String>(
    'credential_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publicHeadersJsonMeta = const VerificationMeta(
    'publicHeadersJson',
  );
  @override
  late final GeneratedColumn<String> publicHeadersJson =
      GeneratedColumn<String>(
        'public_headers_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _endpointsJsonMeta = const VerificationMeta(
    'endpointsJson',
  );
  @override
  late final GeneratedColumn<String> endpointsJson = GeneratedColumn<String>(
    'endpoints_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _responseMappingJsonMeta =
      const VerificationMeta('responseMappingJson');
  @override
  late final GeneratedColumn<String> responseMappingJson =
      GeneratedColumn<String>(
        'response_mapping_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('disconnected'),
  );
  static const VerificationMeta _lastLatencyMsMeta = const VerificationMeta(
    'lastLatencyMs',
  );
  @override
  late final GeneratedColumn<int> lastLatencyMs = GeneratedColumn<int>(
    'last_latency_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastTestedAtMsMeta = const VerificationMeta(
    'lastTestedAtMs',
  );
  @override
  late final GeneratedColumn<int> lastTestedAtMs = GeneratedColumn<int>(
    'last_tested_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _builtInMeta = const VerificationMeta(
    'builtIn',
  );
  @override
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    name,
    sourceType,
    baseUrl,
    authType,
    credentialRef,
    publicHeadersJson,
    endpointsJson,
    responseMappingJson,
    enabled,
    status,
    lastLatencyMs,
    lastTestedAtMs,
    lastErrorCode,
    builtIn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'music_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<MusicSourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    }
    if (data.containsKey('auth_type')) {
      context.handle(
        _authTypeMeta,
        authType.isAcceptableOrUnknown(data['auth_type']!, _authTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_authTypeMeta);
    }
    if (data.containsKey('credential_ref')) {
      context.handle(
        _credentialRefMeta,
        credentialRef.isAcceptableOrUnknown(
          data['credential_ref']!,
          _credentialRefMeta,
        ),
      );
    }
    if (data.containsKey('public_headers_json')) {
      context.handle(
        _publicHeadersJsonMeta,
        publicHeadersJson.isAcceptableOrUnknown(
          data['public_headers_json']!,
          _publicHeadersJsonMeta,
        ),
      );
    }
    if (data.containsKey('endpoints_json')) {
      context.handle(
        _endpointsJsonMeta,
        endpointsJson.isAcceptableOrUnknown(
          data['endpoints_json']!,
          _endpointsJsonMeta,
        ),
      );
    }
    if (data.containsKey('response_mapping_json')) {
      context.handle(
        _responseMappingJsonMeta,
        responseMappingJson.isAcceptableOrUnknown(
          data['response_mapping_json']!,
          _responseMappingJsonMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_latency_ms')) {
      context.handle(
        _lastLatencyMsMeta,
        lastLatencyMs.isAcceptableOrUnknown(
          data['last_latency_ms']!,
          _lastLatencyMsMeta,
        ),
      );
    }
    if (data.containsKey('last_tested_at_ms')) {
      context.handle(
        _lastTestedAtMsMeta,
        lastTestedAtMs.isAcceptableOrUnknown(
          data['last_tested_at_ms']!,
          _lastTestedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('built_in')) {
      context.handle(
        _builtInMeta,
        builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId};
  @override
  MusicSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MusicSourceRow(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      ),
      authType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_type'],
      )!,
      credentialRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_ref'],
      ),
      publicHeadersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_headers_json'],
      )!,
      endpointsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoints_json'],
      )!,
      responseMappingJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_mapping_json'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastLatencyMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_latency_ms'],
      ),
      lastTestedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_tested_at_ms'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      builtIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}built_in'],
      )!,
    );
  }

  @override
  $MusicSourceRecordsTable createAlias(String alias) {
    return $MusicSourceRecordsTable(attachedDatabase, alias);
  }
}

class MusicSourceRow extends DataClass implements Insertable<MusicSourceRow> {
  final String sourceId;
  final String name;
  final String sourceType;
  final String? baseUrl;
  final String authType;
  final String? credentialRef;
  final String publicHeadersJson;
  final String endpointsJson;
  final String responseMappingJson;
  final bool enabled;
  final String status;
  final int? lastLatencyMs;
  final int? lastTestedAtMs;
  final String? lastErrorCode;
  final bool builtIn;
  const MusicSourceRow({
    required this.sourceId,
    required this.name,
    required this.sourceType,
    this.baseUrl,
    required this.authType,
    this.credentialRef,
    required this.publicHeadersJson,
    required this.endpointsJson,
    required this.responseMappingJson,
    required this.enabled,
    required this.status,
    this.lastLatencyMs,
    this.lastTestedAtMs,
    this.lastErrorCode,
    required this.builtIn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['name'] = Variable<String>(name);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || baseUrl != null) {
      map['base_url'] = Variable<String>(baseUrl);
    }
    map['auth_type'] = Variable<String>(authType);
    if (!nullToAbsent || credentialRef != null) {
      map['credential_ref'] = Variable<String>(credentialRef);
    }
    map['public_headers_json'] = Variable<String>(publicHeadersJson);
    map['endpoints_json'] = Variable<String>(endpointsJson);
    map['response_mapping_json'] = Variable<String>(responseMappingJson);
    map['enabled'] = Variable<bool>(enabled);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastLatencyMs != null) {
      map['last_latency_ms'] = Variable<int>(lastLatencyMs);
    }
    if (!nullToAbsent || lastTestedAtMs != null) {
      map['last_tested_at_ms'] = Variable<int>(lastTestedAtMs);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    map['built_in'] = Variable<bool>(builtIn);
    return map;
  }

  MusicSourceRecordsCompanion toCompanion(bool nullToAbsent) {
    return MusicSourceRecordsCompanion(
      sourceId: Value(sourceId),
      name: Value(name),
      sourceType: Value(sourceType),
      baseUrl: baseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUrl),
      authType: Value(authType),
      credentialRef: credentialRef == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialRef),
      publicHeadersJson: Value(publicHeadersJson),
      endpointsJson: Value(endpointsJson),
      responseMappingJson: Value(responseMappingJson),
      enabled: Value(enabled),
      status: Value(status),
      lastLatencyMs: lastLatencyMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLatencyMs),
      lastTestedAtMs: lastTestedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTestedAtMs),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      builtIn: Value(builtIn),
    );
  }

  factory MusicSourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MusicSourceRow(
      sourceId: serializer.fromJson<String>(json['sourceId']),
      name: serializer.fromJson<String>(json['name']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      baseUrl: serializer.fromJson<String?>(json['baseUrl']),
      authType: serializer.fromJson<String>(json['authType']),
      credentialRef: serializer.fromJson<String?>(json['credentialRef']),
      publicHeadersJson: serializer.fromJson<String>(json['publicHeadersJson']),
      endpointsJson: serializer.fromJson<String>(json['endpointsJson']),
      responseMappingJson: serializer.fromJson<String>(
        json['responseMappingJson'],
      ),
      enabled: serializer.fromJson<bool>(json['enabled']),
      status: serializer.fromJson<String>(json['status']),
      lastLatencyMs: serializer.fromJson<int?>(json['lastLatencyMs']),
      lastTestedAtMs: serializer.fromJson<int?>(json['lastTestedAtMs']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      builtIn: serializer.fromJson<bool>(json['builtIn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<String>(sourceId),
      'name': serializer.toJson<String>(name),
      'sourceType': serializer.toJson<String>(sourceType),
      'baseUrl': serializer.toJson<String?>(baseUrl),
      'authType': serializer.toJson<String>(authType),
      'credentialRef': serializer.toJson<String?>(credentialRef),
      'publicHeadersJson': serializer.toJson<String>(publicHeadersJson),
      'endpointsJson': serializer.toJson<String>(endpointsJson),
      'responseMappingJson': serializer.toJson<String>(responseMappingJson),
      'enabled': serializer.toJson<bool>(enabled),
      'status': serializer.toJson<String>(status),
      'lastLatencyMs': serializer.toJson<int?>(lastLatencyMs),
      'lastTestedAtMs': serializer.toJson<int?>(lastTestedAtMs),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'builtIn': serializer.toJson<bool>(builtIn),
    };
  }

  MusicSourceRow copyWith({
    String? sourceId,
    String? name,
    String? sourceType,
    Value<String?> baseUrl = const Value.absent(),
    String? authType,
    Value<String?> credentialRef = const Value.absent(),
    String? publicHeadersJson,
    String? endpointsJson,
    String? responseMappingJson,
    bool? enabled,
    String? status,
    Value<int?> lastLatencyMs = const Value.absent(),
    Value<int?> lastTestedAtMs = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    bool? builtIn,
  }) => MusicSourceRow(
    sourceId: sourceId ?? this.sourceId,
    name: name ?? this.name,
    sourceType: sourceType ?? this.sourceType,
    baseUrl: baseUrl.present ? baseUrl.value : this.baseUrl,
    authType: authType ?? this.authType,
    credentialRef: credentialRef.present
        ? credentialRef.value
        : this.credentialRef,
    publicHeadersJson: publicHeadersJson ?? this.publicHeadersJson,
    endpointsJson: endpointsJson ?? this.endpointsJson,
    responseMappingJson: responseMappingJson ?? this.responseMappingJson,
    enabled: enabled ?? this.enabled,
    status: status ?? this.status,
    lastLatencyMs: lastLatencyMs.present
        ? lastLatencyMs.value
        : this.lastLatencyMs,
    lastTestedAtMs: lastTestedAtMs.present
        ? lastTestedAtMs.value
        : this.lastTestedAtMs,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    builtIn: builtIn ?? this.builtIn,
  );
  MusicSourceRow copyWithCompanion(MusicSourceRecordsCompanion data) {
    return MusicSourceRow(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      name: data.name.present ? data.name.value : this.name,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      authType: data.authType.present ? data.authType.value : this.authType,
      credentialRef: data.credentialRef.present
          ? data.credentialRef.value
          : this.credentialRef,
      publicHeadersJson: data.publicHeadersJson.present
          ? data.publicHeadersJson.value
          : this.publicHeadersJson,
      endpointsJson: data.endpointsJson.present
          ? data.endpointsJson.value
          : this.endpointsJson,
      responseMappingJson: data.responseMappingJson.present
          ? data.responseMappingJson.value
          : this.responseMappingJson,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      status: data.status.present ? data.status.value : this.status,
      lastLatencyMs: data.lastLatencyMs.present
          ? data.lastLatencyMs.value
          : this.lastLatencyMs,
      lastTestedAtMs: data.lastTestedAtMs.present
          ? data.lastTestedAtMs.value
          : this.lastTestedAtMs,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MusicSourceRow(')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('sourceType: $sourceType, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('authType: $authType, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('publicHeadersJson: $publicHeadersJson, ')
          ..write('endpointsJson: $endpointsJson, ')
          ..write('responseMappingJson: $responseMappingJson, ')
          ..write('enabled: $enabled, ')
          ..write('status: $status, ')
          ..write('lastLatencyMs: $lastLatencyMs, ')
          ..write('lastTestedAtMs: $lastTestedAtMs, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('builtIn: $builtIn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    name,
    sourceType,
    baseUrl,
    authType,
    credentialRef,
    publicHeadersJson,
    endpointsJson,
    responseMappingJson,
    enabled,
    status,
    lastLatencyMs,
    lastTestedAtMs,
    lastErrorCode,
    builtIn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MusicSourceRow &&
          other.sourceId == this.sourceId &&
          other.name == this.name &&
          other.sourceType == this.sourceType &&
          other.baseUrl == this.baseUrl &&
          other.authType == this.authType &&
          other.credentialRef == this.credentialRef &&
          other.publicHeadersJson == this.publicHeadersJson &&
          other.endpointsJson == this.endpointsJson &&
          other.responseMappingJson == this.responseMappingJson &&
          other.enabled == this.enabled &&
          other.status == this.status &&
          other.lastLatencyMs == this.lastLatencyMs &&
          other.lastTestedAtMs == this.lastTestedAtMs &&
          other.lastErrorCode == this.lastErrorCode &&
          other.builtIn == this.builtIn);
}

class MusicSourceRecordsCompanion extends UpdateCompanion<MusicSourceRow> {
  final Value<String> sourceId;
  final Value<String> name;
  final Value<String> sourceType;
  final Value<String?> baseUrl;
  final Value<String> authType;
  final Value<String?> credentialRef;
  final Value<String> publicHeadersJson;
  final Value<String> endpointsJson;
  final Value<String> responseMappingJson;
  final Value<bool> enabled;
  final Value<String> status;
  final Value<int?> lastLatencyMs;
  final Value<int?> lastTestedAtMs;
  final Value<String?> lastErrorCode;
  final Value<bool> builtIn;
  final Value<int> rowid;
  const MusicSourceRecordsCompanion({
    this.sourceId = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.authType = const Value.absent(),
    this.credentialRef = const Value.absent(),
    this.publicHeadersJson = const Value.absent(),
    this.endpointsJson = const Value.absent(),
    this.responseMappingJson = const Value.absent(),
    this.enabled = const Value.absent(),
    this.status = const Value.absent(),
    this.lastLatencyMs = const Value.absent(),
    this.lastTestedAtMs = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MusicSourceRecordsCompanion.insert({
    required String sourceId,
    required String name,
    required String sourceType,
    this.baseUrl = const Value.absent(),
    required String authType,
    this.credentialRef = const Value.absent(),
    this.publicHeadersJson = const Value.absent(),
    this.endpointsJson = const Value.absent(),
    this.responseMappingJson = const Value.absent(),
    this.enabled = const Value.absent(),
    this.status = const Value.absent(),
    this.lastLatencyMs = const Value.absent(),
    this.lastTestedAtMs = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       name = Value(name),
       sourceType = Value(sourceType),
       authType = Value(authType);
  static Insertable<MusicSourceRow> custom({
    Expression<String>? sourceId,
    Expression<String>? name,
    Expression<String>? sourceType,
    Expression<String>? baseUrl,
    Expression<String>? authType,
    Expression<String>? credentialRef,
    Expression<String>? publicHeadersJson,
    Expression<String>? endpointsJson,
    Expression<String>? responseMappingJson,
    Expression<bool>? enabled,
    Expression<String>? status,
    Expression<int>? lastLatencyMs,
    Expression<int>? lastTestedAtMs,
    Expression<String>? lastErrorCode,
    Expression<bool>? builtIn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (name != null) 'name': name,
      if (sourceType != null) 'source_type': sourceType,
      if (baseUrl != null) 'base_url': baseUrl,
      if (authType != null) 'auth_type': authType,
      if (credentialRef != null) 'credential_ref': credentialRef,
      if (publicHeadersJson != null) 'public_headers_json': publicHeadersJson,
      if (endpointsJson != null) 'endpoints_json': endpointsJson,
      if (responseMappingJson != null)
        'response_mapping_json': responseMappingJson,
      if (enabled != null) 'enabled': enabled,
      if (status != null) 'status': status,
      if (lastLatencyMs != null) 'last_latency_ms': lastLatencyMs,
      if (lastTestedAtMs != null) 'last_tested_at_ms': lastTestedAtMs,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (builtIn != null) 'built_in': builtIn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MusicSourceRecordsCompanion copyWith({
    Value<String>? sourceId,
    Value<String>? name,
    Value<String>? sourceType,
    Value<String?>? baseUrl,
    Value<String>? authType,
    Value<String?>? credentialRef,
    Value<String>? publicHeadersJson,
    Value<String>? endpointsJson,
    Value<String>? responseMappingJson,
    Value<bool>? enabled,
    Value<String>? status,
    Value<int?>? lastLatencyMs,
    Value<int?>? lastTestedAtMs,
    Value<String?>? lastErrorCode,
    Value<bool>? builtIn,
    Value<int>? rowid,
  }) {
    return MusicSourceRecordsCompanion(
      sourceId: sourceId ?? this.sourceId,
      name: name ?? this.name,
      sourceType: sourceType ?? this.sourceType,
      baseUrl: baseUrl ?? this.baseUrl,
      authType: authType ?? this.authType,
      credentialRef: credentialRef ?? this.credentialRef,
      publicHeadersJson: publicHeadersJson ?? this.publicHeadersJson,
      endpointsJson: endpointsJson ?? this.endpointsJson,
      responseMappingJson: responseMappingJson ?? this.responseMappingJson,
      enabled: enabled ?? this.enabled,
      status: status ?? this.status,
      lastLatencyMs: lastLatencyMs ?? this.lastLatencyMs,
      lastTestedAtMs: lastTestedAtMs ?? this.lastTestedAtMs,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      builtIn: builtIn ?? this.builtIn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (authType.present) {
      map['auth_type'] = Variable<String>(authType.value);
    }
    if (credentialRef.present) {
      map['credential_ref'] = Variable<String>(credentialRef.value);
    }
    if (publicHeadersJson.present) {
      map['public_headers_json'] = Variable<String>(publicHeadersJson.value);
    }
    if (endpointsJson.present) {
      map['endpoints_json'] = Variable<String>(endpointsJson.value);
    }
    if (responseMappingJson.present) {
      map['response_mapping_json'] = Variable<String>(
        responseMappingJson.value,
      );
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastLatencyMs.present) {
      map['last_latency_ms'] = Variable<int>(lastLatencyMs.value);
    }
    if (lastTestedAtMs.present) {
      map['last_tested_at_ms'] = Variable<int>(lastTestedAtMs.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MusicSourceRecordsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('sourceType: $sourceType, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('authType: $authType, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('publicHeadersJson: $publicHeadersJson, ')
          ..write('endpointsJson: $endpointsJson, ')
          ..write('responseMappingJson: $responseMappingJson, ')
          ..write('enabled: $enabled, ')
          ..write('status: $status, ')
          ..write('lastLatencyMs: $lastLatencyMs, ')
          ..write('lastTestedAtMs: $lastTestedAtMs, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('builtIn: $builtIn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalFolderRecordsTable extends LocalFolderRecords
    with TableInfo<$LocalFolderRecordsTable, LocalFolderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFolderRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 512,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentUriMeta = const VerificationMeta(
    'contentUri',
  );
  @override
  late final GeneratedColumn<String> contentUri = GeneratedColumn<String>(
    'content_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grantRefMeta = const VerificationMeta(
    'grantRef',
  );
  @override
  late final GeneratedColumn<String> grantRef = GeneratedColumn<String>(
    'grant_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastScannedAtMsMeta = const VerificationMeta(
    'lastScannedAtMs',
  );
  @override
  late final GeneratedColumn<int> lastScannedAtMs = GeneratedColumn<int>(
    'last_scanned_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    folderId,
    platform,
    displayName,
    localPath,
    contentUri,
    grantRef,
    createdAtMs,
    updatedAtMs,
    lastScannedAtMs,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalFolderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('content_uri')) {
      context.handle(
        _contentUriMeta,
        contentUri.isAcceptableOrUnknown(data['content_uri']!, _contentUriMeta),
      );
    }
    if (data.containsKey('grant_ref')) {
      context.handle(
        _grantRefMeta,
        grantRef.isAcceptableOrUnknown(data['grant_ref']!, _grantRefMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('last_scanned_at_ms')) {
      context.handle(
        _lastScannedAtMsMeta,
        lastScannedAtMs.isAcceptableOrUnknown(
          data['last_scanned_at_ms']!,
          _lastScannedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {folderId};
  @override
  LocalFolderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFolderRow(
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      contentUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_uri'],
      ),
      grantRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grant_ref'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      lastScannedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_scanned_at_ms'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $LocalFolderRecordsTable createAlias(String alias) {
    return $LocalFolderRecordsTable(attachedDatabase, alias);
  }
}

class LocalFolderRow extends DataClass implements Insertable<LocalFolderRow> {
  final String folderId;
  final String platform;
  final String displayName;
  final String? localPath;
  final String? contentUri;
  final String? grantRef;
  final int createdAtMs;
  final int updatedAtMs;
  final int? lastScannedAtMs;
  final bool enabled;
  const LocalFolderRow({
    required this.folderId,
    required this.platform,
    required this.displayName,
    this.localPath,
    this.contentUri,
    this.grantRef,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.lastScannedAtMs,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['folder_id'] = Variable<String>(folderId);
    map['platform'] = Variable<String>(platform);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || contentUri != null) {
      map['content_uri'] = Variable<String>(contentUri);
    }
    if (!nullToAbsent || grantRef != null) {
      map['grant_ref'] = Variable<String>(grantRef);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    if (!nullToAbsent || lastScannedAtMs != null) {
      map['last_scanned_at_ms'] = Variable<int>(lastScannedAtMs);
    }
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  LocalFolderRecordsCompanion toCompanion(bool nullToAbsent) {
    return LocalFolderRecordsCompanion(
      folderId: Value(folderId),
      platform: Value(platform),
      displayName: Value(displayName),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      contentUri: contentUri == null && nullToAbsent
          ? const Value.absent()
          : Value(contentUri),
      grantRef: grantRef == null && nullToAbsent
          ? const Value.absent()
          : Value(grantRef),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      lastScannedAtMs: lastScannedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastScannedAtMs),
      enabled: Value(enabled),
    );
  }

  factory LocalFolderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFolderRow(
      folderId: serializer.fromJson<String>(json['folderId']),
      platform: serializer.fromJson<String>(json['platform']),
      displayName: serializer.fromJson<String>(json['displayName']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      contentUri: serializer.fromJson<String?>(json['contentUri']),
      grantRef: serializer.fromJson<String?>(json['grantRef']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      lastScannedAtMs: serializer.fromJson<int?>(json['lastScannedAtMs']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'folderId': serializer.toJson<String>(folderId),
      'platform': serializer.toJson<String>(platform),
      'displayName': serializer.toJson<String>(displayName),
      'localPath': serializer.toJson<String?>(localPath),
      'contentUri': serializer.toJson<String?>(contentUri),
      'grantRef': serializer.toJson<String?>(grantRef),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'lastScannedAtMs': serializer.toJson<int?>(lastScannedAtMs),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  LocalFolderRow copyWith({
    String? folderId,
    String? platform,
    String? displayName,
    Value<String?> localPath = const Value.absent(),
    Value<String?> contentUri = const Value.absent(),
    Value<String?> grantRef = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> lastScannedAtMs = const Value.absent(),
    bool? enabled,
  }) => LocalFolderRow(
    folderId: folderId ?? this.folderId,
    platform: platform ?? this.platform,
    displayName: displayName ?? this.displayName,
    localPath: localPath.present ? localPath.value : this.localPath,
    contentUri: contentUri.present ? contentUri.value : this.contentUri,
    grantRef: grantRef.present ? grantRef.value : this.grantRef,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    lastScannedAtMs: lastScannedAtMs.present
        ? lastScannedAtMs.value
        : this.lastScannedAtMs,
    enabled: enabled ?? this.enabled,
  );
  LocalFolderRow copyWithCompanion(LocalFolderRecordsCompanion data) {
    return LocalFolderRow(
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      platform: data.platform.present ? data.platform.value : this.platform,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      contentUri: data.contentUri.present
          ? data.contentUri.value
          : this.contentUri,
      grantRef: data.grantRef.present ? data.grantRef.value : this.grantRef,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      lastScannedAtMs: data.lastScannedAtMs.present
          ? data.lastScannedAtMs.value
          : this.lastScannedAtMs,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFolderRow(')
          ..write('folderId: $folderId, ')
          ..write('platform: $platform, ')
          ..write('displayName: $displayName, ')
          ..write('localPath: $localPath, ')
          ..write('contentUri: $contentUri, ')
          ..write('grantRef: $grantRef, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('lastScannedAtMs: $lastScannedAtMs, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    folderId,
    platform,
    displayName,
    localPath,
    contentUri,
    grantRef,
    createdAtMs,
    updatedAtMs,
    lastScannedAtMs,
    enabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFolderRow &&
          other.folderId == this.folderId &&
          other.platform == this.platform &&
          other.displayName == this.displayName &&
          other.localPath == this.localPath &&
          other.contentUri == this.contentUri &&
          other.grantRef == this.grantRef &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.lastScannedAtMs == this.lastScannedAtMs &&
          other.enabled == this.enabled);
}

class LocalFolderRecordsCompanion extends UpdateCompanion<LocalFolderRow> {
  final Value<String> folderId;
  final Value<String> platform;
  final Value<String> displayName;
  final Value<String?> localPath;
  final Value<String?> contentUri;
  final Value<String?> grantRef;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> lastScannedAtMs;
  final Value<bool> enabled;
  final Value<int> rowid;
  const LocalFolderRecordsCompanion({
    this.folderId = const Value.absent(),
    this.platform = const Value.absent(),
    this.displayName = const Value.absent(),
    this.localPath = const Value.absent(),
    this.contentUri = const Value.absent(),
    this.grantRef = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.lastScannedAtMs = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFolderRecordsCompanion.insert({
    required String folderId,
    required String platform,
    required String displayName,
    this.localPath = const Value.absent(),
    this.contentUri = const Value.absent(),
    this.grantRef = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.lastScannedAtMs = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : folderId = Value(folderId),
       platform = Value(platform),
       displayName = Value(displayName),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<LocalFolderRow> custom({
    Expression<String>? folderId,
    Expression<String>? platform,
    Expression<String>? displayName,
    Expression<String>? localPath,
    Expression<String>? contentUri,
    Expression<String>? grantRef,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? lastScannedAtMs,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (folderId != null) 'folder_id': folderId,
      if (platform != null) 'platform': platform,
      if (displayName != null) 'display_name': displayName,
      if (localPath != null) 'local_path': localPath,
      if (contentUri != null) 'content_uri': contentUri,
      if (grantRef != null) 'grant_ref': grantRef,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (lastScannedAtMs != null) 'last_scanned_at_ms': lastScannedAtMs,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFolderRecordsCompanion copyWith({
    Value<String>? folderId,
    Value<String>? platform,
    Value<String>? displayName,
    Value<String?>? localPath,
    Value<String?>? contentUri,
    Value<String?>? grantRef,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? lastScannedAtMs,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return LocalFolderRecordsCompanion(
      folderId: folderId ?? this.folderId,
      platform: platform ?? this.platform,
      displayName: displayName ?? this.displayName,
      localPath: localPath ?? this.localPath,
      contentUri: contentUri ?? this.contentUri,
      grantRef: grantRef ?? this.grantRef,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      lastScannedAtMs: lastScannedAtMs ?? this.lastScannedAtMs,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (contentUri.present) {
      map['content_uri'] = Variable<String>(contentUri.value);
    }
    if (grantRef.present) {
      map['grant_ref'] = Variable<String>(grantRef.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (lastScannedAtMs.present) {
      map['last_scanned_at_ms'] = Variable<int>(lastScannedAtMs.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFolderRecordsCompanion(')
          ..write('folderId: $folderId, ')
          ..write('platform: $platform, ')
          ..write('displayName: $displayName, ')
          ..write('localPath: $localPath, ')
          ..write('contentUri: $contentUri, ')
          ..write('grantRef: $grantRef, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('lastScannedAtMs: $lastScannedAtMs, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LyricsCacheRecordsTable extends LyricsCacheRecords
    with TableInfo<$LyricsCacheRecordsTable, LyricsCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LyricsCacheRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackSourceTypeMeta = const VerificationMeta(
    'trackSourceType',
  );
  @override
  late final GeneratedColumn<String> trackSourceType = GeneratedColumn<String>(
    'track_source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackSourceIdMeta = const VerificationMeta(
    'trackSourceId',
  );
  @override
  late final GeneratedColumn<String> trackSourceId = GeneratedColumn<String>(
    'track_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linesJsonMeta = const VerificationMeta(
    'linesJson',
  );
  @override
  late final GeneratedColumn<String> linesJson = GeneratedColumn<String>(
    'lines_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationLanguageMeta =
      const VerificationMeta('translationLanguage');
  @override
  late final GeneratedColumn<String> translationLanguage =
      GeneratedColumn<String>(
        'translation_language',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _offsetMsMeta = const VerificationMeta(
    'offsetMs',
  );
  @override
  late final GeneratedColumn<int> offsetMs = GeneratedColumn<int>(
    'offset_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    trackSourceType,
    trackSourceId,
    trackId,
    kind,
    linesJson,
    language,
    translationLanguage,
    offsetMs,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lyrics_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<LyricsCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_source_type')) {
      context.handle(
        _trackSourceTypeMeta,
        trackSourceType.isAcceptableOrUnknown(
          data['track_source_type']!,
          _trackSourceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceTypeMeta);
    }
    if (data.containsKey('track_source_id')) {
      context.handle(
        _trackSourceIdMeta,
        trackSourceId.isAcceptableOrUnknown(
          data['track_source_id']!,
          _trackSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackSourceIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('lines_json')) {
      context.handle(
        _linesJsonMeta,
        linesJson.isAcceptableOrUnknown(data['lines_json']!, _linesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_linesJsonMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('translation_language')) {
      context.handle(
        _translationLanguageMeta,
        translationLanguage.isAcceptableOrUnknown(
          data['translation_language']!,
          _translationLanguageMeta,
        ),
      );
    }
    if (data.containsKey('offset_ms')) {
      context.handle(
        _offsetMsMeta,
        offsetMs.isAcceptableOrUnknown(data['offset_ms']!, _offsetMsMeta),
      );
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    trackSourceType,
    trackSourceId,
    trackId,
  };
  @override
  LyricsCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LyricsCacheRow(
      trackSourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_type'],
      )!,
      trackSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_source_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      linesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lines_json'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      translationLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_language'],
      ),
      offsetMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $LyricsCacheRecordsTable createAlias(String alias) {
    return $LyricsCacheRecordsTable(attachedDatabase, alias);
  }
}

class LyricsCacheRow extends DataClass implements Insertable<LyricsCacheRow> {
  final String trackSourceType;
  final String trackSourceId;
  final String trackId;
  final String kind;
  final String linesJson;
  final String language;
  final String? translationLanguage;
  final int offsetMs;
  final int updatedAtMs;
  const LyricsCacheRow({
    required this.trackSourceType,
    required this.trackSourceId,
    required this.trackId,
    required this.kind,
    required this.linesJson,
    required this.language,
    this.translationLanguage,
    required this.offsetMs,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_source_type'] = Variable<String>(trackSourceType);
    map['track_source_id'] = Variable<String>(trackSourceId);
    map['track_id'] = Variable<String>(trackId);
    map['kind'] = Variable<String>(kind);
    map['lines_json'] = Variable<String>(linesJson);
    map['language'] = Variable<String>(language);
    if (!nullToAbsent || translationLanguage != null) {
      map['translation_language'] = Variable<String>(translationLanguage);
    }
    map['offset_ms'] = Variable<int>(offsetMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  LyricsCacheRecordsCompanion toCompanion(bool nullToAbsent) {
    return LyricsCacheRecordsCompanion(
      trackSourceType: Value(trackSourceType),
      trackSourceId: Value(trackSourceId),
      trackId: Value(trackId),
      kind: Value(kind),
      linesJson: Value(linesJson),
      language: Value(language),
      translationLanguage: translationLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(translationLanguage),
      offsetMs: Value(offsetMs),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory LyricsCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LyricsCacheRow(
      trackSourceType: serializer.fromJson<String>(json['trackSourceType']),
      trackSourceId: serializer.fromJson<String>(json['trackSourceId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      kind: serializer.fromJson<String>(json['kind']),
      linesJson: serializer.fromJson<String>(json['linesJson']),
      language: serializer.fromJson<String>(json['language']),
      translationLanguage: serializer.fromJson<String?>(
        json['translationLanguage'],
      ),
      offsetMs: serializer.fromJson<int>(json['offsetMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackSourceType': serializer.toJson<String>(trackSourceType),
      'trackSourceId': serializer.toJson<String>(trackSourceId),
      'trackId': serializer.toJson<String>(trackId),
      'kind': serializer.toJson<String>(kind),
      'linesJson': serializer.toJson<String>(linesJson),
      'language': serializer.toJson<String>(language),
      'translationLanguage': serializer.toJson<String?>(translationLanguage),
      'offsetMs': serializer.toJson<int>(offsetMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  LyricsCacheRow copyWith({
    String? trackSourceType,
    String? trackSourceId,
    String? trackId,
    String? kind,
    String? linesJson,
    String? language,
    Value<String?> translationLanguage = const Value.absent(),
    int? offsetMs,
    int? updatedAtMs,
  }) => LyricsCacheRow(
    trackSourceType: trackSourceType ?? this.trackSourceType,
    trackSourceId: trackSourceId ?? this.trackSourceId,
    trackId: trackId ?? this.trackId,
    kind: kind ?? this.kind,
    linesJson: linesJson ?? this.linesJson,
    language: language ?? this.language,
    translationLanguage: translationLanguage.present
        ? translationLanguage.value
        : this.translationLanguage,
    offsetMs: offsetMs ?? this.offsetMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  LyricsCacheRow copyWithCompanion(LyricsCacheRecordsCompanion data) {
    return LyricsCacheRow(
      trackSourceType: data.trackSourceType.present
          ? data.trackSourceType.value
          : this.trackSourceType,
      trackSourceId: data.trackSourceId.present
          ? data.trackSourceId.value
          : this.trackSourceId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      kind: data.kind.present ? data.kind.value : this.kind,
      linesJson: data.linesJson.present ? data.linesJson.value : this.linesJson,
      language: data.language.present ? data.language.value : this.language,
      translationLanguage: data.translationLanguage.present
          ? data.translationLanguage.value
          : this.translationLanguage,
      offsetMs: data.offsetMs.present ? data.offsetMs.value : this.offsetMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LyricsCacheRow(')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('kind: $kind, ')
          ..write('linesJson: $linesJson, ')
          ..write('language: $language, ')
          ..write('translationLanguage: $translationLanguage, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trackSourceType,
    trackSourceId,
    trackId,
    kind,
    linesJson,
    language,
    translationLanguage,
    offsetMs,
    updatedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LyricsCacheRow &&
          other.trackSourceType == this.trackSourceType &&
          other.trackSourceId == this.trackSourceId &&
          other.trackId == this.trackId &&
          other.kind == this.kind &&
          other.linesJson == this.linesJson &&
          other.language == this.language &&
          other.translationLanguage == this.translationLanguage &&
          other.offsetMs == this.offsetMs &&
          other.updatedAtMs == this.updatedAtMs);
}

class LyricsCacheRecordsCompanion extends UpdateCompanion<LyricsCacheRow> {
  final Value<String> trackSourceType;
  final Value<String> trackSourceId;
  final Value<String> trackId;
  final Value<String> kind;
  final Value<String> linesJson;
  final Value<String> language;
  final Value<String?> translationLanguage;
  final Value<int> offsetMs;
  final Value<int> updatedAtMs;
  final Value<int> rowid;
  const LyricsCacheRecordsCompanion({
    this.trackSourceType = const Value.absent(),
    this.trackSourceId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.kind = const Value.absent(),
    this.linesJson = const Value.absent(),
    this.language = const Value.absent(),
    this.translationLanguage = const Value.absent(),
    this.offsetMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LyricsCacheRecordsCompanion.insert({
    required String trackSourceType,
    required String trackSourceId,
    required String trackId,
    required String kind,
    required String linesJson,
    required String language,
    this.translationLanguage = const Value.absent(),
    this.offsetMs = const Value.absent(),
    required int updatedAtMs,
    this.rowid = const Value.absent(),
  }) : trackSourceType = Value(trackSourceType),
       trackSourceId = Value(trackSourceId),
       trackId = Value(trackId),
       kind = Value(kind),
       linesJson = Value(linesJson),
       language = Value(language),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<LyricsCacheRow> custom({
    Expression<String>? trackSourceType,
    Expression<String>? trackSourceId,
    Expression<String>? trackId,
    Expression<String>? kind,
    Expression<String>? linesJson,
    Expression<String>? language,
    Expression<String>? translationLanguage,
    Expression<int>? offsetMs,
    Expression<int>? updatedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackSourceType != null) 'track_source_type': trackSourceType,
      if (trackSourceId != null) 'track_source_id': trackSourceId,
      if (trackId != null) 'track_id': trackId,
      if (kind != null) 'kind': kind,
      if (linesJson != null) 'lines_json': linesJson,
      if (language != null) 'language': language,
      if (translationLanguage != null)
        'translation_language': translationLanguage,
      if (offsetMs != null) 'offset_ms': offsetMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LyricsCacheRecordsCompanion copyWith({
    Value<String>? trackSourceType,
    Value<String>? trackSourceId,
    Value<String>? trackId,
    Value<String>? kind,
    Value<String>? linesJson,
    Value<String>? language,
    Value<String?>? translationLanguage,
    Value<int>? offsetMs,
    Value<int>? updatedAtMs,
    Value<int>? rowid,
  }) {
    return LyricsCacheRecordsCompanion(
      trackSourceType: trackSourceType ?? this.trackSourceType,
      trackSourceId: trackSourceId ?? this.trackSourceId,
      trackId: trackId ?? this.trackId,
      kind: kind ?? this.kind,
      linesJson: linesJson ?? this.linesJson,
      language: language ?? this.language,
      translationLanguage: translationLanguage ?? this.translationLanguage,
      offsetMs: offsetMs ?? this.offsetMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackSourceType.present) {
      map['track_source_type'] = Variable<String>(trackSourceType.value);
    }
    if (trackSourceId.present) {
      map['track_source_id'] = Variable<String>(trackSourceId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (linesJson.present) {
      map['lines_json'] = Variable<String>(linesJson.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (translationLanguage.present) {
      map['translation_language'] = Variable<String>(translationLanguage.value);
    }
    if (offsetMs.present) {
      map['offset_ms'] = Variable<int>(offsetMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LyricsCacheRecordsCompanion(')
          ..write('trackSourceType: $trackSourceType, ')
          ..write('trackSourceId: $trackSourceId, ')
          ..write('trackId: $trackId, ')
          ..write('kind: $kind, ')
          ..write('linesJson: $linesJson, ')
          ..write('language: $language, ')
          ..write('translationLanguage: $translationLanguage, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryRecordsTable extends SearchHistoryRecords
    with TableInfo<$SearchHistoryRecordsTable, SearchHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _searchIdMeta = const VerificationMeta(
    'searchId',
  );
  @override
  late final GeneratedColumn<String> searchId = GeneratedColumn<String>(
    'search_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 2048,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchedAtMsMeta = const VerificationMeta(
    'searchedAtMs',
  );
  @override
  late final GeneratedColumn<int> searchedAtMs = GeneratedColumn<int>(
    'searched_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    searchId,
    query,
    sourceId,
    searchedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('search_id')) {
      context.handle(
        _searchIdMeta,
        searchId.isAcceptableOrUnknown(data['search_id']!, _searchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_searchIdMeta);
    }
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('searched_at_ms')) {
      context.handle(
        _searchedAtMsMeta,
        searchedAtMs.isAcceptableOrUnknown(
          data['searched_at_ms']!,
          _searchedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_searchedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {searchId};
  @override
  SearchHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryRow(
      searchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_id'],
      )!,
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      searchedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}searched_at_ms'],
      )!,
    );
  }

  @override
  $SearchHistoryRecordsTable createAlias(String alias) {
    return $SearchHistoryRecordsTable(attachedDatabase, alias);
  }
}

class SearchHistoryRow extends DataClass
    implements Insertable<SearchHistoryRow> {
  final String searchId;
  final String query;
  final String? sourceId;
  final int searchedAtMs;
  const SearchHistoryRow({
    required this.searchId,
    required this.query,
    this.sourceId,
    required this.searchedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['search_id'] = Variable<String>(searchId);
    map['query'] = Variable<String>(query);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['searched_at_ms'] = Variable<int>(searchedAtMs);
    return map;
  }

  SearchHistoryRecordsCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryRecordsCompanion(
      searchId: Value(searchId),
      query: Value(query),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      searchedAtMs: Value(searchedAtMs),
    );
  }

  factory SearchHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryRow(
      searchId: serializer.fromJson<String>(json['searchId']),
      query: serializer.fromJson<String>(json['query']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      searchedAtMs: serializer.fromJson<int>(json['searchedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'searchId': serializer.toJson<String>(searchId),
      'query': serializer.toJson<String>(query),
      'sourceId': serializer.toJson<String?>(sourceId),
      'searchedAtMs': serializer.toJson<int>(searchedAtMs),
    };
  }

  SearchHistoryRow copyWith({
    String? searchId,
    String? query,
    Value<String?> sourceId = const Value.absent(),
    int? searchedAtMs,
  }) => SearchHistoryRow(
    searchId: searchId ?? this.searchId,
    query: query ?? this.query,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    searchedAtMs: searchedAtMs ?? this.searchedAtMs,
  );
  SearchHistoryRow copyWithCompanion(SearchHistoryRecordsCompanion data) {
    return SearchHistoryRow(
      searchId: data.searchId.present ? data.searchId.value : this.searchId,
      query: data.query.present ? data.query.value : this.query,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      searchedAtMs: data.searchedAtMs.present
          ? data.searchedAtMs.value
          : this.searchedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryRow(')
          ..write('searchId: $searchId, ')
          ..write('query: $query, ')
          ..write('sourceId: $sourceId, ')
          ..write('searchedAtMs: $searchedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(searchId, query, sourceId, searchedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryRow &&
          other.searchId == this.searchId &&
          other.query == this.query &&
          other.sourceId == this.sourceId &&
          other.searchedAtMs == this.searchedAtMs);
}

class SearchHistoryRecordsCompanion extends UpdateCompanion<SearchHistoryRow> {
  final Value<String> searchId;
  final Value<String> query;
  final Value<String?> sourceId;
  final Value<int> searchedAtMs;
  final Value<int> rowid;
  const SearchHistoryRecordsCompanion({
    this.searchId = const Value.absent(),
    this.query = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.searchedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchHistoryRecordsCompanion.insert({
    required String searchId,
    required String query,
    this.sourceId = const Value.absent(),
    required int searchedAtMs,
    this.rowid = const Value.absent(),
  }) : searchId = Value(searchId),
       query = Value(query),
       searchedAtMs = Value(searchedAtMs);
  static Insertable<SearchHistoryRow> custom({
    Expression<String>? searchId,
    Expression<String>? query,
    Expression<String>? sourceId,
    Expression<int>? searchedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (searchId != null) 'search_id': searchId,
      if (query != null) 'query': query,
      if (sourceId != null) 'source_id': sourceId,
      if (searchedAtMs != null) 'searched_at_ms': searchedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchHistoryRecordsCompanion copyWith({
    Value<String>? searchId,
    Value<String>? query,
    Value<String?>? sourceId,
    Value<int>? searchedAtMs,
    Value<int>? rowid,
  }) {
    return SearchHistoryRecordsCompanion(
      searchId: searchId ?? this.searchId,
      query: query ?? this.query,
      sourceId: sourceId ?? this.sourceId,
      searchedAtMs: searchedAtMs ?? this.searchedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (searchId.present) {
      map['search_id'] = Variable<String>(searchId.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (searchedAtMs.present) {
      map['searched_at_ms'] = Variable<int>(searchedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryRecordsCompanion(')
          ..write('searchId: $searchId, ')
          ..write('query: $query, ')
          ..write('sourceId: $sourceId, ')
          ..write('searchedAtMs: $searchedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingRecordsTable extends AppSettingRecords
    with TableInfo<$AppSettingRecordsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingKeyMeta = const VerificationMeta(
    'settingKey',
  );
  @override
  late final GeneratedColumn<String> settingKey = GeneratedColumn<String>(
    'setting_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [settingKey, valueJson, updatedAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setting_key')) {
      context.handle(
        _settingKeyMeta,
        settingKey.isAcceptableOrUnknown(data['setting_key']!, _settingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_settingKeyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingKey};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      settingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $AppSettingRecordsTable createAlias(String alias) {
    return $AppSettingRecordsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String settingKey;
  final String valueJson;
  final int updatedAtMs;
  const AppSettingRow({
    required this.settingKey,
    required this.valueJson,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setting_key'] = Variable<String>(settingKey);
    map['value_json'] = Variable<String>(valueJson);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  AppSettingRecordsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingRecordsCompanion(
      settingKey: Value(settingKey),
      valueJson: Value(valueJson),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      settingKey: serializer.fromJson<String>(json['settingKey']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingKey': serializer.toJson<String>(settingKey),
      'valueJson': serializer.toJson<String>(valueJson),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  AppSettingRow copyWith({
    String? settingKey,
    String? valueJson,
    int? updatedAtMs,
  }) => AppSettingRow(
    settingKey: settingKey ?? this.settingKey,
    valueJson: valueJson ?? this.valueJson,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  AppSettingRow copyWithCompanion(AppSettingRecordsCompanion data) {
    return AppSettingRow(
      settingKey: data.settingKey.present
          ? data.settingKey.value
          : this.settingKey,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('settingKey: $settingKey, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingKey, valueJson, updatedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.settingKey == this.settingKey &&
          other.valueJson == this.valueJson &&
          other.updatedAtMs == this.updatedAtMs);
}

class AppSettingRecordsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> settingKey;
  final Value<String> valueJson;
  final Value<int> updatedAtMs;
  final Value<int> rowid;
  const AppSettingRecordsCompanion({
    this.settingKey = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingRecordsCompanion.insert({
    required String settingKey,
    required String valueJson,
    required int updatedAtMs,
    this.rowid = const Value.absent(),
  }) : settingKey = Value(settingKey),
       valueJson = Value(valueJson),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<AppSettingRow> custom({
    Expression<String>? settingKey,
    Expression<String>? valueJson,
    Expression<int>? updatedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingKey != null) 'setting_key': settingKey,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingRecordsCompanion copyWith({
    Value<String>? settingKey,
    Value<String>? valueJson,
    Value<int>? updatedAtMs,
    Value<int>? rowid,
  }) {
    return AppSettingRecordsCompanion(
      settingKey: settingKey ?? this.settingKey,
      valueJson: valueJson ?? this.valueJson,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingKey.present) {
      map['setting_key'] = Variable<String>(settingKey.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRecordsCompanion(')
          ..write('settingKey: $settingKey, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchemaMigrationRecordsTable extends SchemaMigrationRecords
    with TableInfo<$SchemaMigrationRecordsTable, SchemaMigrationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchemaMigrationRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appliedAtMsMeta = const VerificationMeta(
    'appliedAtMs',
  );
  @override
  late final GeneratedColumn<int> appliedAtMs = GeneratedColumn<int>(
    'applied_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 512,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [version, appliedAtMs, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schema_migrations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchemaMigrationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('applied_at_ms')) {
      context.handle(
        _appliedAtMsMeta,
        appliedAtMs.isAcceptableOrUnknown(
          data['applied_at_ms']!,
          _appliedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appliedAtMsMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {version};
  @override
  SchemaMigrationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchemaMigrationRow(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      appliedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_at_ms'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
    );
  }

  @override
  $SchemaMigrationRecordsTable createAlias(String alias) {
    return $SchemaMigrationRecordsTable(attachedDatabase, alias);
  }
}

class SchemaMigrationRow extends DataClass
    implements Insertable<SchemaMigrationRow> {
  final int version;
  final int appliedAtMs;
  final String description;
  const SchemaMigrationRow({
    required this.version,
    required this.appliedAtMs,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    map['applied_at_ms'] = Variable<int>(appliedAtMs);
    map['description'] = Variable<String>(description);
    return map;
  }

  SchemaMigrationRecordsCompanion toCompanion(bool nullToAbsent) {
    return SchemaMigrationRecordsCompanion(
      version: Value(version),
      appliedAtMs: Value(appliedAtMs),
      description: Value(description),
    );
  }

  factory SchemaMigrationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchemaMigrationRow(
      version: serializer.fromJson<int>(json['version']),
      appliedAtMs: serializer.fromJson<int>(json['appliedAtMs']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'appliedAtMs': serializer.toJson<int>(appliedAtMs),
      'description': serializer.toJson<String>(description),
    };
  }

  SchemaMigrationRow copyWith({
    int? version,
    int? appliedAtMs,
    String? description,
  }) => SchemaMigrationRow(
    version: version ?? this.version,
    appliedAtMs: appliedAtMs ?? this.appliedAtMs,
    description: description ?? this.description,
  );
  SchemaMigrationRow copyWithCompanion(SchemaMigrationRecordsCompanion data) {
    return SchemaMigrationRow(
      version: data.version.present ? data.version.value : this.version,
      appliedAtMs: data.appliedAtMs.present
          ? data.appliedAtMs.value
          : this.appliedAtMs,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMigrationRow(')
          ..write('version: $version, ')
          ..write('appliedAtMs: $appliedAtMs, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(version, appliedAtMs, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemaMigrationRow &&
          other.version == this.version &&
          other.appliedAtMs == this.appliedAtMs &&
          other.description == this.description);
}

class SchemaMigrationRecordsCompanion
    extends UpdateCompanion<SchemaMigrationRow> {
  final Value<int> version;
  final Value<int> appliedAtMs;
  final Value<String> description;
  const SchemaMigrationRecordsCompanion({
    this.version = const Value.absent(),
    this.appliedAtMs = const Value.absent(),
    this.description = const Value.absent(),
  });
  SchemaMigrationRecordsCompanion.insert({
    this.version = const Value.absent(),
    required int appliedAtMs,
    required String description,
  }) : appliedAtMs = Value(appliedAtMs),
       description = Value(description);
  static Insertable<SchemaMigrationRow> custom({
    Expression<int>? version,
    Expression<int>? appliedAtMs,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (appliedAtMs != null) 'applied_at_ms': appliedAtMs,
      if (description != null) 'description': description,
    });
  }

  SchemaMigrationRecordsCompanion copyWith({
    Value<int>? version,
    Value<int>? appliedAtMs,
    Value<String>? description,
  }) {
    return SchemaMigrationRecordsCompanion(
      version: version ?? this.version,
      appliedAtMs: appliedAtMs ?? this.appliedAtMs,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (appliedAtMs.present) {
      map['applied_at_ms'] = Variable<int>(appliedAtMs.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMigrationRecordsCompanion(')
          ..write('version: $version, ')
          ..write('appliedAtMs: $appliedAtMs, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TrackRecordsTable trackRecords = $TrackRecordsTable(this);
  late final $AlbumRecordsTable albumRecords = $AlbumRecordsTable(this);
  late final $ArtistRecordsTable artistRecords = $ArtistRecordsTable(this);
  late final $TrackArtistRecordsTable trackArtistRecords =
      $TrackArtistRecordsTable(this);
  late final $AlbumArtistRecordsTable albumArtistRecords =
      $AlbumArtistRecordsTable(this);
  late final $PlaylistRecordsTable playlistRecords = $PlaylistRecordsTable(
    this,
  );
  late final $PlaylistEntryRecordsTable playlistEntryRecords =
      $PlaylistEntryRecordsTable(this);
  late final $FavoriteRecordsTable favoriteRecords = $FavoriteRecordsTable(
    this,
  );
  late final $PlayHistoryRecordsTable playHistoryRecords =
      $PlayHistoryRecordsTable(this);
  late final $QueueEntryRecordsTable queueEntryRecords =
      $QueueEntryRecordsTable(this);
  late final $QueueStateRecordsTable queueStateRecords =
      $QueueStateRecordsTable(this);
  late final $MusicSourceRecordsTable musicSourceRecords =
      $MusicSourceRecordsTable(this);
  late final $LocalFolderRecordsTable localFolderRecords =
      $LocalFolderRecordsTable(this);
  late final $LyricsCacheRecordsTable lyricsCacheRecords =
      $LyricsCacheRecordsTable(this);
  late final $SearchHistoryRecordsTable searchHistoryRecords =
      $SearchHistoryRecordsTable(this);
  late final $AppSettingRecordsTable appSettingRecords =
      $AppSettingRecordsTable(this);
  late final $SchemaMigrationRecordsTable schemaMigrationRecords =
      $SchemaMigrationRecordsTable(this);
  late final Index tracksByTitle = Index(
    'tracks_by_title',
    'CREATE INDEX tracks_by_title ON tracks (title)',
  );
  late final Index tracksByAlbum = Index(
    'tracks_by_album',
    'CREATE INDEX tracks_by_album ON tracks (source_id, album_id)',
  );
  late final Index albumsByTitle = Index(
    'albums_by_title',
    'CREATE INDEX albums_by_title ON albums (title)',
  );
  late final Index artistsByName = Index(
    'artists_by_name',
    'CREATE INDEX artists_by_name ON artists (name)',
  );
  late final Index playlistsByUpdated = Index(
    'playlists_by_updated',
    'CREATE INDEX playlists_by_updated ON playlists (updated_at_ms)',
  );
  late final Index playlistEntriesByTrack = Index(
    'playlist_entries_by_track',
    'CREATE INDEX playlist_entries_by_track ON playlist_entries (track_source_type, track_source_id, track_id)',
  );
  late final Index favoritesByAdded = Index(
    'favorites_by_added',
    'CREATE INDEX favorites_by_added ON favorites (added_at_ms)',
  );
  late final Index playHistoryByStarted = Index(
    'play_history_by_started',
    'CREATE INDEX play_history_by_started ON play_history (started_at_ms)',
  );
  late final Index queueEntriesByTrack = Index(
    'queue_entries_by_track',
    'CREATE INDEX queue_entries_by_track ON queue_entries (track_source_type, track_source_id, track_id)',
  );
  late final Index searchHistoryByTime = Index(
    'search_history_by_time',
    'CREATE INDEX search_history_by_time ON search_history (searched_at_ms)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trackRecords,
    albumRecords,
    artistRecords,
    trackArtistRecords,
    albumArtistRecords,
    playlistRecords,
    playlistEntryRecords,
    favoriteRecords,
    playHistoryRecords,
    queueEntryRecords,
    queueStateRecords,
    musicSourceRecords,
    localFolderRecords,
    lyricsCacheRecords,
    searchHistoryRecords,
    appSettingRecords,
    schemaMigrationRecords,
    tracksByTitle,
    tracksByAlbum,
    albumsByTitle,
    artistsByName,
    playlistsByUpdated,
    playlistEntriesByTrack,
    favoritesByAdded,
    playHistoryByStarted,
    queueEntriesByTrack,
    searchHistoryByTime,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'queue_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('queue_state', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$TrackRecordsTableCreateCompanionBuilder =
    TrackRecordsCompanion Function({
      required String trackId,
      required String sourceId,
      required String sourceType,
      required String title,
      Value<String?> albumId,
      Value<String?> albumTitle,
      required int durationMs,
      Value<String?> artworkUri,
      Value<String?> localPath,
      Value<String?> contentUri,
      Value<String?> fileFingerprint,
      Value<int?> modifiedAtMs,
      Value<int?> fileSize,
      required String availability,
      Value<String> metadataJson,
      Value<int> rowid,
    });
typedef $$TrackRecordsTableUpdateCompanionBuilder =
    TrackRecordsCompanion Function({
      Value<String> trackId,
      Value<String> sourceId,
      Value<String> sourceType,
      Value<String> title,
      Value<String?> albumId,
      Value<String?> albumTitle,
      Value<int> durationMs,
      Value<String?> artworkUri,
      Value<String?> localPath,
      Value<String?> contentUri,
      Value<String?> fileFingerprint,
      Value<int?> modifiedAtMs,
      Value<int?> fileSize,
      Value<String> availability,
      Value<String> metadataJson,
      Value<int> rowid,
    });

class $$TrackRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackRecordsTable> {
  $$TrackRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUri => $composableBuilder(
    column: $table.artworkUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileFingerprint => $composableBuilder(
    column: $table.fileFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAtMs => $composableBuilder(
    column: $table.modifiedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrackRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackRecordsTable> {
  $$TrackRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUri => $composableBuilder(
    column: $table.artworkUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileFingerprint => $composableBuilder(
    column: $table.fileFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAtMs => $composableBuilder(
    column: $table.modifiedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrackRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackRecordsTable> {
  $$TrackRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkUri => $composableBuilder(
    column: $table.artworkUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileFingerprint => $composableBuilder(
    column: $table.fileFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get modifiedAtMs => $composableBuilder(
    column: $table.modifiedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );
}

class $$TrackRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackRecordsTable,
          TrackRow,
          $$TrackRecordsTableFilterComposer,
          $$TrackRecordsTableOrderingComposer,
          $$TrackRecordsTableAnnotationComposer,
          $$TrackRecordsTableCreateCompanionBuilder,
          $$TrackRecordsTableUpdateCompanionBuilder,
          (
            TrackRow,
            BaseReferences<_$AppDatabase, $TrackRecordsTable, TrackRow>,
          ),
          TrackRow,
          PrefetchHooks Function()
        > {
  $$TrackRecordsTableTableManager(_$AppDatabase db, $TrackRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> trackId = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<String?> albumTitle = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String?> artworkUri = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> contentUri = const Value.absent(),
                Value<String?> fileFingerprint = const Value.absent(),
                Value<int?> modifiedAtMs = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String> availability = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackRecordsCompanion(
                trackId: trackId,
                sourceId: sourceId,
                sourceType: sourceType,
                title: title,
                albumId: albumId,
                albumTitle: albumTitle,
                durationMs: durationMs,
                artworkUri: artworkUri,
                localPath: localPath,
                contentUri: contentUri,
                fileFingerprint: fileFingerprint,
                modifiedAtMs: modifiedAtMs,
                fileSize: fileSize,
                availability: availability,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackId,
                required String sourceId,
                required String sourceType,
                required String title,
                Value<String?> albumId = const Value.absent(),
                Value<String?> albumTitle = const Value.absent(),
                required int durationMs,
                Value<String?> artworkUri = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> contentUri = const Value.absent(),
                Value<String?> fileFingerprint = const Value.absent(),
                Value<int?> modifiedAtMs = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                required String availability,
                Value<String> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackRecordsCompanion.insert(
                trackId: trackId,
                sourceId: sourceId,
                sourceType: sourceType,
                title: title,
                albumId: albumId,
                albumTitle: albumTitle,
                durationMs: durationMs,
                artworkUri: artworkUri,
                localPath: localPath,
                contentUri: contentUri,
                fileFingerprint: fileFingerprint,
                modifiedAtMs: modifiedAtMs,
                fileSize: fileSize,
                availability: availability,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrackRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackRecordsTable,
      TrackRow,
      $$TrackRecordsTableFilterComposer,
      $$TrackRecordsTableOrderingComposer,
      $$TrackRecordsTableAnnotationComposer,
      $$TrackRecordsTableCreateCompanionBuilder,
      $$TrackRecordsTableUpdateCompanionBuilder,
      (TrackRow, BaseReferences<_$AppDatabase, $TrackRecordsTable, TrackRow>),
      TrackRow,
      PrefetchHooks Function()
    >;
typedef $$AlbumRecordsTableCreateCompanionBuilder =
    AlbumRecordsCompanion Function({
      required String albumId,
      required String sourceId,
      required String title,
      Value<int?> year,
      Value<String?> artworkUri,
      Value<int> trackCount,
      Value<int> rowid,
    });
typedef $$AlbumRecordsTableUpdateCompanionBuilder =
    AlbumRecordsCompanion Function({
      Value<String> albumId,
      Value<String> sourceId,
      Value<String> title,
      Value<int?> year,
      Value<String?> artworkUri,
      Value<int> trackCount,
      Value<int> rowid,
    });

class $$AlbumRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumRecordsTable> {
  $$AlbumRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUri => $composableBuilder(
    column: $table.artworkUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlbumRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumRecordsTable> {
  $$AlbumRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUri => $composableBuilder(
    column: $table.artworkUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlbumRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumRecordsTable> {
  $$AlbumRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get artworkUri => $composableBuilder(
    column: $table.artworkUri,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => column,
  );
}

class $$AlbumRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumRecordsTable,
          AlbumRow,
          $$AlbumRecordsTableFilterComposer,
          $$AlbumRecordsTableOrderingComposer,
          $$AlbumRecordsTableAnnotationComposer,
          $$AlbumRecordsTableCreateCompanionBuilder,
          $$AlbumRecordsTableUpdateCompanionBuilder,
          (
            AlbumRow,
            BaseReferences<_$AppDatabase, $AlbumRecordsTable, AlbumRow>,
          ),
          AlbumRow,
          PrefetchHooks Function()
        > {
  $$AlbumRecordsTableTableManager(_$AppDatabase db, $AlbumRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> albumId = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> artworkUri = const Value.absent(),
                Value<int> trackCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumRecordsCompanion(
                albumId: albumId,
                sourceId: sourceId,
                title: title,
                year: year,
                artworkUri: artworkUri,
                trackCount: trackCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String albumId,
                required String sourceId,
                required String title,
                Value<int?> year = const Value.absent(),
                Value<String?> artworkUri = const Value.absent(),
                Value<int> trackCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumRecordsCompanion.insert(
                albumId: albumId,
                sourceId: sourceId,
                title: title,
                year: year,
                artworkUri: artworkUri,
                trackCount: trackCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlbumRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumRecordsTable,
      AlbumRow,
      $$AlbumRecordsTableFilterComposer,
      $$AlbumRecordsTableOrderingComposer,
      $$AlbumRecordsTableAnnotationComposer,
      $$AlbumRecordsTableCreateCompanionBuilder,
      $$AlbumRecordsTableUpdateCompanionBuilder,
      (AlbumRow, BaseReferences<_$AppDatabase, $AlbumRecordsTable, AlbumRow>),
      AlbumRow,
      PrefetchHooks Function()
    >;
typedef $$ArtistRecordsTableCreateCompanionBuilder =
    ArtistRecordsCompanion Function({
      required String artistId,
      required String sourceId,
      required String name,
      Value<String?> artworkUri,
      Value<int> albumCount,
      Value<int> trackCount,
      Value<int> rowid,
    });
typedef $$ArtistRecordsTableUpdateCompanionBuilder =
    ArtistRecordsCompanion Function({
      Value<String> artistId,
      Value<String> sourceId,
      Value<String> name,
      Value<String?> artworkUri,
      Value<int> albumCount,
      Value<int> trackCount,
      Value<int> rowid,
    });

class $$ArtistRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ArtistRecordsTable> {
  $$ArtistRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUri => $composableBuilder(
    column: $table.artworkUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get albumCount => $composableBuilder(
    column: $table.albumCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArtistRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtistRecordsTable> {
  $$ArtistRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUri => $composableBuilder(
    column: $table.artworkUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get albumCount => $composableBuilder(
    column: $table.albumCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArtistRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtistRecordsTable> {
  $$ArtistRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get artworkUri => $composableBuilder(
    column: $table.artworkUri,
    builder: (column) => column,
  );

  GeneratedColumn<int> get albumCount => $composableBuilder(
    column: $table.albumCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => column,
  );
}

class $$ArtistRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtistRecordsTable,
          ArtistRow,
          $$ArtistRecordsTableFilterComposer,
          $$ArtistRecordsTableOrderingComposer,
          $$ArtistRecordsTableAnnotationComposer,
          $$ArtistRecordsTableCreateCompanionBuilder,
          $$ArtistRecordsTableUpdateCompanionBuilder,
          (
            ArtistRow,
            BaseReferences<_$AppDatabase, $ArtistRecordsTable, ArtistRow>,
          ),
          ArtistRow,
          PrefetchHooks Function()
        > {
  $$ArtistRecordsTableTableManager(_$AppDatabase db, $ArtistRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtistRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtistRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtistRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> artistId = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> artworkUri = const Value.absent(),
                Value<int> albumCount = const Value.absent(),
                Value<int> trackCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArtistRecordsCompanion(
                artistId: artistId,
                sourceId: sourceId,
                name: name,
                artworkUri: artworkUri,
                albumCount: albumCount,
                trackCount: trackCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String artistId,
                required String sourceId,
                required String name,
                Value<String?> artworkUri = const Value.absent(),
                Value<int> albumCount = const Value.absent(),
                Value<int> trackCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArtistRecordsCompanion.insert(
                artistId: artistId,
                sourceId: sourceId,
                name: name,
                artworkUri: artworkUri,
                albumCount: albumCount,
                trackCount: trackCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArtistRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtistRecordsTable,
      ArtistRow,
      $$ArtistRecordsTableFilterComposer,
      $$ArtistRecordsTableOrderingComposer,
      $$ArtistRecordsTableAnnotationComposer,
      $$ArtistRecordsTableCreateCompanionBuilder,
      $$ArtistRecordsTableUpdateCompanionBuilder,
      (
        ArtistRow,
        BaseReferences<_$AppDatabase, $ArtistRecordsTable, ArtistRow>,
      ),
      ArtistRow,
      PrefetchHooks Function()
    >;
typedef $$TrackArtistRecordsTableCreateCompanionBuilder =
    TrackArtistRecordsCompanion Function({
      required String trackSourceType,
      required String trackSourceId,
      required String trackId,
      required String artistSourceId,
      required String artistId,
      required int position,
      Value<int> rowid,
    });
typedef $$TrackArtistRecordsTableUpdateCompanionBuilder =
    TrackArtistRecordsCompanion Function({
      Value<String> trackSourceType,
      Value<String> trackSourceId,
      Value<String> trackId,
      Value<String> artistSourceId,
      Value<String> artistId,
      Value<int> position,
      Value<int> rowid,
    });

class $$TrackArtistRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackArtistRecordsTable> {
  $$TrackArtistRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistSourceId => $composableBuilder(
    column: $table.artistSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrackArtistRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackArtistRecordsTable> {
  $$TrackArtistRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistSourceId => $composableBuilder(
    column: $table.artistSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrackArtistRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackArtistRecordsTable> {
  $$TrackArtistRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get artistSourceId => $composableBuilder(
    column: $table.artistSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$TrackArtistRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackArtistRecordsTable,
          TrackArtistRow,
          $$TrackArtistRecordsTableFilterComposer,
          $$TrackArtistRecordsTableOrderingComposer,
          $$TrackArtistRecordsTableAnnotationComposer,
          $$TrackArtistRecordsTableCreateCompanionBuilder,
          $$TrackArtistRecordsTableUpdateCompanionBuilder,
          (
            TrackArtistRow,
            BaseReferences<
              _$AppDatabase,
              $TrackArtistRecordsTable,
              TrackArtistRow
            >,
          ),
          TrackArtistRow,
          PrefetchHooks Function()
        > {
  $$TrackArtistRecordsTableTableManager(
    _$AppDatabase db,
    $TrackArtistRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackArtistRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackArtistRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackArtistRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> trackSourceType = const Value.absent(),
                Value<String> trackSourceId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<String> artistSourceId = const Value.absent(),
                Value<String> artistId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackArtistRecordsCompanion(
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                artistSourceId: artistSourceId,
                artistId: artistId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackSourceType,
                required String trackSourceId,
                required String trackId,
                required String artistSourceId,
                required String artistId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => TrackArtistRecordsCompanion.insert(
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                artistSourceId: artistSourceId,
                artistId: artistId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrackArtistRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackArtistRecordsTable,
      TrackArtistRow,
      $$TrackArtistRecordsTableFilterComposer,
      $$TrackArtistRecordsTableOrderingComposer,
      $$TrackArtistRecordsTableAnnotationComposer,
      $$TrackArtistRecordsTableCreateCompanionBuilder,
      $$TrackArtistRecordsTableUpdateCompanionBuilder,
      (
        TrackArtistRow,
        BaseReferences<_$AppDatabase, $TrackArtistRecordsTable, TrackArtistRow>,
      ),
      TrackArtistRow,
      PrefetchHooks Function()
    >;
typedef $$AlbumArtistRecordsTableCreateCompanionBuilder =
    AlbumArtistRecordsCompanion Function({
      required String albumSourceId,
      required String albumId,
      required String artistSourceId,
      required String artistId,
      required int position,
      Value<int> rowid,
    });
typedef $$AlbumArtistRecordsTableUpdateCompanionBuilder =
    AlbumArtistRecordsCompanion Function({
      Value<String> albumSourceId,
      Value<String> albumId,
      Value<String> artistSourceId,
      Value<String> artistId,
      Value<int> position,
      Value<int> rowid,
    });

class $$AlbumArtistRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumArtistRecordsTable> {
  $$AlbumArtistRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get albumSourceId => $composableBuilder(
    column: $table.albumSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistSourceId => $composableBuilder(
    column: $table.artistSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlbumArtistRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumArtistRecordsTable> {
  $$AlbumArtistRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get albumSourceId => $composableBuilder(
    column: $table.albumSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistSourceId => $composableBuilder(
    column: $table.artistSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlbumArtistRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumArtistRecordsTable> {
  $$AlbumArtistRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get albumSourceId => $composableBuilder(
    column: $table.albumSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<String> get artistSourceId => $composableBuilder(
    column: $table.artistSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$AlbumArtistRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumArtistRecordsTable,
          AlbumArtistRow,
          $$AlbumArtistRecordsTableFilterComposer,
          $$AlbumArtistRecordsTableOrderingComposer,
          $$AlbumArtistRecordsTableAnnotationComposer,
          $$AlbumArtistRecordsTableCreateCompanionBuilder,
          $$AlbumArtistRecordsTableUpdateCompanionBuilder,
          (
            AlbumArtistRow,
            BaseReferences<
              _$AppDatabase,
              $AlbumArtistRecordsTable,
              AlbumArtistRow
            >,
          ),
          AlbumArtistRow,
          PrefetchHooks Function()
        > {
  $$AlbumArtistRecordsTableTableManager(
    _$AppDatabase db,
    $AlbumArtistRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumArtistRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumArtistRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumArtistRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> albumSourceId = const Value.absent(),
                Value<String> albumId = const Value.absent(),
                Value<String> artistSourceId = const Value.absent(),
                Value<String> artistId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumArtistRecordsCompanion(
                albumSourceId: albumSourceId,
                albumId: albumId,
                artistSourceId: artistSourceId,
                artistId: artistId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String albumSourceId,
                required String albumId,
                required String artistSourceId,
                required String artistId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => AlbumArtistRecordsCompanion.insert(
                albumSourceId: albumSourceId,
                albumId: albumId,
                artistSourceId: artistSourceId,
                artistId: artistId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlbumArtistRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumArtistRecordsTable,
      AlbumArtistRow,
      $$AlbumArtistRecordsTableFilterComposer,
      $$AlbumArtistRecordsTableOrderingComposer,
      $$AlbumArtistRecordsTableAnnotationComposer,
      $$AlbumArtistRecordsTableCreateCompanionBuilder,
      $$AlbumArtistRecordsTableUpdateCompanionBuilder,
      (
        AlbumArtistRow,
        BaseReferences<_$AppDatabase, $AlbumArtistRecordsTable, AlbumArtistRow>,
      ),
      AlbumArtistRow,
      PrefetchHooks Function()
    >;
typedef $$PlaylistRecordsTableCreateCompanionBuilder =
    PlaylistRecordsCompanion Function({
      required String playlistId,
      required String name,
      Value<String> description,
      required int createdAtMs,
      required int updatedAtMs,
      Value<bool> isSystem,
      Value<String?> systemType,
      Value<int> rowid,
    });
typedef $$PlaylistRecordsTableUpdateCompanionBuilder =
    PlaylistRecordsCompanion Function({
      Value<String> playlistId,
      Value<String> name,
      Value<String> description,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<bool> isSystem,
      Value<String?> systemType,
      Value<int> rowid,
    });

final class $$PlaylistRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistRecordsTable, PlaylistRow> {
  $$PlaylistRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PlaylistEntryRecordsTable, List<PlaylistEntryRow>>
  _playlistEntryRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playlistEntryRecords,
        aliasName: 'playlists__playlist_id__playlist_entries__playlist_id',
      );

  $$PlaylistEntryRecordsTableProcessedTableManager
  get playlistEntryRecordsRefs {
    final manager =
        $$PlaylistEntryRecordsTableTableManager(
          $_db,
          $_db.playlistEntryRecords,
        ).filter(
          (f) => f.playlistId.playlistId.sqlEquals(
            $_itemColumn<String>('playlist_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _playlistEntryRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistRecordsTable> {
  $$PlaylistRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemType => $composableBuilder(
    column: $table.systemType,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistEntryRecordsRefs(
    Expression<bool> Function($$PlaylistEntryRecordsTableFilterComposer f) f,
  ) {
    final $$PlaylistEntryRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlistEntryRecords,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistEntryRecordsTableFilterComposer(
            $db: $db,
            $table: $db.playlistEntryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistRecordsTable> {
  $$PlaylistRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemType => $composableBuilder(
    column: $table.systemType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistRecordsTable> {
  $$PlaylistRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<String> get systemType => $composableBuilder(
    column: $table.systemType,
    builder: (column) => column,
  );

  Expression<T> playlistEntryRecordsRefs<T extends Object>(
    Expression<T> Function($$PlaylistEntryRecordsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistEntryRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.playlistId,
          referencedTable: $db.playlistEntryRecords,
          getReferencedColumn: (t) => t.playlistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaylistEntryRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.playlistEntryRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlaylistRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistRecordsTable,
          PlaylistRow,
          $$PlaylistRecordsTableFilterComposer,
          $$PlaylistRecordsTableOrderingComposer,
          $$PlaylistRecordsTableAnnotationComposer,
          $$PlaylistRecordsTableCreateCompanionBuilder,
          $$PlaylistRecordsTableUpdateCompanionBuilder,
          (PlaylistRow, $$PlaylistRecordsTableReferences),
          PlaylistRow,
          PrefetchHooks Function({bool playlistEntryRecordsRefs})
        > {
  $$PlaylistRecordsTableTableManager(
    _$AppDatabase db,
    $PlaylistRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<String?> systemType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistRecordsCompanion(
                playlistId: playlistId,
                name: name,
                description: description,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                isSystem: isSystem,
                systemType: systemType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String name,
                Value<String> description = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<bool> isSystem = const Value.absent(),
                Value<String?> systemType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistRecordsCompanion.insert(
                playlistId: playlistId,
                name: name,
                description: description,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                isSystem: isSystem,
                systemType: systemType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistEntryRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistEntryRecordsRefs) db.playlistEntryRecords,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistEntryRecordsRefs)
                    await $_getPrefetchedData<
                      PlaylistRow,
                      $PlaylistRecordsTable,
                      PlaylistEntryRow
                    >(
                      currentTable: table,
                      referencedTable: $$PlaylistRecordsTableReferences
                          ._playlistEntryRecordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlaylistRecordsTableReferences(
                            db,
                            table,
                            p0,
                          ).playlistEntryRecordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.playlistId == item.playlistId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistRecordsTable,
      PlaylistRow,
      $$PlaylistRecordsTableFilterComposer,
      $$PlaylistRecordsTableOrderingComposer,
      $$PlaylistRecordsTableAnnotationComposer,
      $$PlaylistRecordsTableCreateCompanionBuilder,
      $$PlaylistRecordsTableUpdateCompanionBuilder,
      (PlaylistRow, $$PlaylistRecordsTableReferences),
      PlaylistRow,
      PrefetchHooks Function({bool playlistEntryRecordsRefs})
    >;
typedef $$PlaylistEntryRecordsTableCreateCompanionBuilder =
    PlaylistEntryRecordsCompanion Function({
      required String entryId,
      required String playlistId,
      required String trackSourceType,
      required String trackSourceId,
      required String trackId,
      required int position,
      required int addedAtMs,
      Value<int> rowid,
    });
typedef $$PlaylistEntryRecordsTableUpdateCompanionBuilder =
    PlaylistEntryRecordsCompanion Function({
      Value<String> entryId,
      Value<String> playlistId,
      Value<String> trackSourceType,
      Value<String> trackSourceId,
      Value<String> trackId,
      Value<int> position,
      Value<int> addedAtMs,
      Value<int> rowid,
    });

final class $$PlaylistEntryRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlaylistEntryRecordsTable,
          PlaylistEntryRow
        > {
  $$PlaylistEntryRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistRecordsTable _playlistIdTable(_$AppDatabase db) => db
      .playlistRecords
      .createAlias('playlist_entries__playlist_id__playlists__playlist_id');

  $$PlaylistRecordsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistRecordsTableTableManager(
      $_db,
      $_db.playlistRecords,
    ).filter((f) => f.playlistId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistEntryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistEntryRecordsTable> {
  $$PlaylistEntryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAtMs => $composableBuilder(
    column: $table.addedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistRecordsTableFilterComposer get playlistId {
    final $$PlaylistRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlistRecords,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistRecordsTableFilterComposer(
            $db: $db,
            $table: $db.playlistRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistEntryRecordsTable> {
  $$PlaylistEntryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAtMs => $composableBuilder(
    column: $table.addedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistRecordsTableOrderingComposer get playlistId {
    final $$PlaylistRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlistRecords,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.playlistRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistEntryRecordsTable> {
  $$PlaylistEntryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get addedAtMs =>
      $composableBuilder(column: $table.addedAtMs, builder: (column) => column);

  $$PlaylistRecordsTableAnnotationComposer get playlistId {
    final $$PlaylistRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlistRecords,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistEntryRecordsTable,
          PlaylistEntryRow,
          $$PlaylistEntryRecordsTableFilterComposer,
          $$PlaylistEntryRecordsTableOrderingComposer,
          $$PlaylistEntryRecordsTableAnnotationComposer,
          $$PlaylistEntryRecordsTableCreateCompanionBuilder,
          $$PlaylistEntryRecordsTableUpdateCompanionBuilder,
          (PlaylistEntryRow, $$PlaylistEntryRecordsTableReferences),
          PlaylistEntryRow,
          PrefetchHooks Function({bool playlistId})
        > {
  $$PlaylistEntryRecordsTableTableManager(
    _$AppDatabase db,
    $PlaylistEntryRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistEntryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistEntryRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlaylistEntryRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> trackSourceType = const Value.absent(),
                Value<String> trackSourceId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> addedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistEntryRecordsCompanion(
                entryId: entryId,
                playlistId: playlistId,
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                position: position,
                addedAtMs: addedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String playlistId,
                required String trackSourceType,
                required String trackSourceId,
                required String trackId,
                required int position,
                required int addedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => PlaylistEntryRecordsCompanion.insert(
                entryId: entryId,
                playlistId: playlistId,
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                position: position,
                addedAtMs: addedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistEntryRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistId,
                        referencedTable: $$PlaylistEntryRecordsTableReferences
                            ._playlistIdTable(db),
                        referencedColumn: $$PlaylistEntryRecordsTableReferences
                            ._playlistIdTable(db)
                            .playlistId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistEntryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistEntryRecordsTable,
      PlaylistEntryRow,
      $$PlaylistEntryRecordsTableFilterComposer,
      $$PlaylistEntryRecordsTableOrderingComposer,
      $$PlaylistEntryRecordsTableAnnotationComposer,
      $$PlaylistEntryRecordsTableCreateCompanionBuilder,
      $$PlaylistEntryRecordsTableUpdateCompanionBuilder,
      (PlaylistEntryRow, $$PlaylistEntryRecordsTableReferences),
      PlaylistEntryRow,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$FavoriteRecordsTableCreateCompanionBuilder =
    FavoriteRecordsCompanion Function({
      required String trackSourceType,
      required String trackSourceId,
      required String trackId,
      required int addedAtMs,
      Value<int> rowid,
    });
typedef $$FavoriteRecordsTableUpdateCompanionBuilder =
    FavoriteRecordsCompanion Function({
      Value<String> trackSourceType,
      Value<String> trackSourceId,
      Value<String> trackId,
      Value<int> addedAtMs,
      Value<int> rowid,
    });

class $$FavoriteRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteRecordsTable> {
  $$FavoriteRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAtMs => $composableBuilder(
    column: $table.addedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoriteRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteRecordsTable> {
  $$FavoriteRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAtMs => $composableBuilder(
    column: $table.addedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteRecordsTable> {
  $$FavoriteRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get addedAtMs =>
      $composableBuilder(column: $table.addedAtMs, builder: (column) => column);
}

class $$FavoriteRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteRecordsTable,
          FavoriteRow,
          $$FavoriteRecordsTableFilterComposer,
          $$FavoriteRecordsTableOrderingComposer,
          $$FavoriteRecordsTableAnnotationComposer,
          $$FavoriteRecordsTableCreateCompanionBuilder,
          $$FavoriteRecordsTableUpdateCompanionBuilder,
          (
            FavoriteRow,
            BaseReferences<_$AppDatabase, $FavoriteRecordsTable, FavoriteRow>,
          ),
          FavoriteRow,
          PrefetchHooks Function()
        > {
  $$FavoriteRecordsTableTableManager(
    _$AppDatabase db,
    $FavoriteRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> trackSourceType = const Value.absent(),
                Value<String> trackSourceId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<int> addedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoriteRecordsCompanion(
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                addedAtMs: addedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackSourceType,
                required String trackSourceId,
                required String trackId,
                required int addedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => FavoriteRecordsCompanion.insert(
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                addedAtMs: addedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoriteRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteRecordsTable,
      FavoriteRow,
      $$FavoriteRecordsTableFilterComposer,
      $$FavoriteRecordsTableOrderingComposer,
      $$FavoriteRecordsTableAnnotationComposer,
      $$FavoriteRecordsTableCreateCompanionBuilder,
      $$FavoriteRecordsTableUpdateCompanionBuilder,
      (
        FavoriteRow,
        BaseReferences<_$AppDatabase, $FavoriteRecordsTable, FavoriteRow>,
      ),
      FavoriteRow,
      PrefetchHooks Function()
    >;
typedef $$PlayHistoryRecordsTableCreateCompanionBuilder =
    PlayHistoryRecordsCompanion Function({
      required String historyId,
      required String trackSourceType,
      required String trackSourceId,
      required String trackId,
      required int startedAtMs,
      required int lastPositionMs,
      Value<bool> completed,
      Value<int> rowid,
    });
typedef $$PlayHistoryRecordsTableUpdateCompanionBuilder =
    PlayHistoryRecordsCompanion Function({
      Value<String> historyId,
      Value<String> trackSourceType,
      Value<String> trackSourceId,
      Value<String> trackId,
      Value<int> startedAtMs,
      Value<int> lastPositionMs,
      Value<bool> completed,
      Value<int> rowid,
    });

class $$PlayHistoryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PlayHistoryRecordsTable> {
  $$PlayHistoryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get historyId => $composableBuilder(
    column: $table.historyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayHistoryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayHistoryRecordsTable> {
  $$PlayHistoryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get historyId => $composableBuilder(
    column: $table.historyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayHistoryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayHistoryRecordsTable> {
  $$PlayHistoryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get historyId =>
      $composableBuilder(column: $table.historyId, builder: (column) => column);

  GeneratedColumn<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$PlayHistoryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayHistoryRecordsTable,
          PlayHistoryRow,
          $$PlayHistoryRecordsTableFilterComposer,
          $$PlayHistoryRecordsTableOrderingComposer,
          $$PlayHistoryRecordsTableAnnotationComposer,
          $$PlayHistoryRecordsTableCreateCompanionBuilder,
          $$PlayHistoryRecordsTableUpdateCompanionBuilder,
          (
            PlayHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $PlayHistoryRecordsTable,
              PlayHistoryRow
            >,
          ),
          PlayHistoryRow,
          PrefetchHooks Function()
        > {
  $$PlayHistoryRecordsTableTableManager(
    _$AppDatabase db,
    $PlayHistoryRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayHistoryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayHistoryRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayHistoryRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> historyId = const Value.absent(),
                Value<String> trackSourceType = const Value.absent(),
                Value<String> trackSourceId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<int> startedAtMs = const Value.absent(),
                Value<int> lastPositionMs = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayHistoryRecordsCompanion(
                historyId: historyId,
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                startedAtMs: startedAtMs,
                lastPositionMs: lastPositionMs,
                completed: completed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String historyId,
                required String trackSourceType,
                required String trackSourceId,
                required String trackId,
                required int startedAtMs,
                required int lastPositionMs,
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayHistoryRecordsCompanion.insert(
                historyId: historyId,
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                startedAtMs: startedAtMs,
                lastPositionMs: lastPositionMs,
                completed: completed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayHistoryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayHistoryRecordsTable,
      PlayHistoryRow,
      $$PlayHistoryRecordsTableFilterComposer,
      $$PlayHistoryRecordsTableOrderingComposer,
      $$PlayHistoryRecordsTableAnnotationComposer,
      $$PlayHistoryRecordsTableCreateCompanionBuilder,
      $$PlayHistoryRecordsTableUpdateCompanionBuilder,
      (
        PlayHistoryRow,
        BaseReferences<_$AppDatabase, $PlayHistoryRecordsTable, PlayHistoryRow>,
      ),
      PlayHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$QueueEntryRecordsTableCreateCompanionBuilder =
    QueueEntryRecordsCompanion Function({
      required String entryId,
      required String trackSourceType,
      required String trackSourceId,
      required String trackId,
      required int position,
      required int addedAtMs,
      Value<int> rowid,
    });
typedef $$QueueEntryRecordsTableUpdateCompanionBuilder =
    QueueEntryRecordsCompanion Function({
      Value<String> entryId,
      Value<String> trackSourceType,
      Value<String> trackSourceId,
      Value<String> trackId,
      Value<int> position,
      Value<int> addedAtMs,
      Value<int> rowid,
    });

final class $$QueueEntryRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $QueueEntryRecordsTable, QueueEntryRow> {
  $$QueueEntryRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$QueueStateRecordsTable, List<QueueStateRow>>
  _queueStateRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.queueStateRecords,
        aliasName: 'queue_entries__entry_id__queue_state__current_entry_id',
      );

  $$QueueStateRecordsTableProcessedTableManager get queueStateRecordsRefs {
    final manager =
        $$QueueStateRecordsTableTableManager(
          $_db,
          $_db.queueStateRecords,
        ).filter(
          (f) => f.currentEntryId.entryId.sqlEquals(
            $_itemColumn<String>('entry_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _queueStateRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$QueueEntryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $QueueEntryRecordsTable> {
  $$QueueEntryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAtMs => $composableBuilder(
    column: $table.addedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> queueStateRecordsRefs(
    Expression<bool> Function($$QueueStateRecordsTableFilterComposer f) f,
  ) {
    final $$QueueStateRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.queueStateRecords,
      getReferencedColumn: (t) => t.currentEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueueStateRecordsTableFilterComposer(
            $db: $db,
            $table: $db.queueStateRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QueueEntryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueEntryRecordsTable> {
  $$QueueEntryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAtMs => $composableBuilder(
    column: $table.addedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueueEntryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueEntryRecordsTable> {
  $$QueueEntryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get addedAtMs =>
      $composableBuilder(column: $table.addedAtMs, builder: (column) => column);

  Expression<T> queueStateRecordsRefs<T extends Object>(
    Expression<T> Function($$QueueStateRecordsTableAnnotationComposer a) f,
  ) {
    final $$QueueStateRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.entryId,
          referencedTable: $db.queueStateRecords,
          getReferencedColumn: (t) => t.currentEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$QueueStateRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.queueStateRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$QueueEntryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueueEntryRecordsTable,
          QueueEntryRow,
          $$QueueEntryRecordsTableFilterComposer,
          $$QueueEntryRecordsTableOrderingComposer,
          $$QueueEntryRecordsTableAnnotationComposer,
          $$QueueEntryRecordsTableCreateCompanionBuilder,
          $$QueueEntryRecordsTableUpdateCompanionBuilder,
          (QueueEntryRow, $$QueueEntryRecordsTableReferences),
          QueueEntryRow,
          PrefetchHooks Function({bool queueStateRecordsRefs})
        > {
  $$QueueEntryRecordsTableTableManager(
    _$AppDatabase db,
    $QueueEntryRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueEntryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueEntryRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueEntryRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> trackSourceType = const Value.absent(),
                Value<String> trackSourceId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> addedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueueEntryRecordsCompanion(
                entryId: entryId,
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                position: position,
                addedAtMs: addedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String trackSourceType,
                required String trackSourceId,
                required String trackId,
                required int position,
                required int addedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => QueueEntryRecordsCompanion.insert(
                entryId: entryId,
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                position: position,
                addedAtMs: addedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QueueEntryRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({queueStateRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (queueStateRecordsRefs) db.queueStateRecords,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (queueStateRecordsRefs)
                    await $_getPrefetchedData<
                      QueueEntryRow,
                      $QueueEntryRecordsTable,
                      QueueStateRow
                    >(
                      currentTable: table,
                      referencedTable: $$QueueEntryRecordsTableReferences
                          ._queueStateRecordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$QueueEntryRecordsTableReferences(
                            db,
                            table,
                            p0,
                          ).queueStateRecordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.currentEntryId == item.entryId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$QueueEntryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueueEntryRecordsTable,
      QueueEntryRow,
      $$QueueEntryRecordsTableFilterComposer,
      $$QueueEntryRecordsTableOrderingComposer,
      $$QueueEntryRecordsTableAnnotationComposer,
      $$QueueEntryRecordsTableCreateCompanionBuilder,
      $$QueueEntryRecordsTableUpdateCompanionBuilder,
      (QueueEntryRow, $$QueueEntryRecordsTableReferences),
      QueueEntryRow,
      PrefetchHooks Function({bool queueStateRecordsRefs})
    >;
typedef $$QueueStateRecordsTableCreateCompanionBuilder =
    QueueStateRecordsCompanion Function({
      Value<int> singletonId,
      Value<String?> currentEntryId,
      required int updatedAtMs,
    });
typedef $$QueueStateRecordsTableUpdateCompanionBuilder =
    QueueStateRecordsCompanion Function({
      Value<int> singletonId,
      Value<String?> currentEntryId,
      Value<int> updatedAtMs,
    });

final class $$QueueStateRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $QueueStateRecordsTable, QueueStateRow> {
  $$QueueStateRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $QueueEntryRecordsTable _currentEntryIdTable(_$AppDatabase db) => db
      .queueEntryRecords
      .createAlias('queue_state__current_entry_id__queue_entries__entry_id');

  $$QueueEntryRecordsTableProcessedTableManager? get currentEntryId {
    final $_column = $_itemColumn<String>('current_entry_id');
    if ($_column == null) return null;
    final manager = $$QueueEntryRecordsTableTableManager(
      $_db,
      $_db.queueEntryRecords,
    ).filter((f) => f.entryId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currentEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QueueStateRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $QueueStateRecordsTable> {
  $$QueueStateRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  $$QueueEntryRecordsTableFilterComposer get currentEntryId {
    final $$QueueEntryRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currentEntryId,
      referencedTable: $db.queueEntryRecords,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueueEntryRecordsTableFilterComposer(
            $db: $db,
            $table: $db.queueEntryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueueStateRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueStateRecordsTable> {
  $$QueueStateRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$QueueEntryRecordsTableOrderingComposer get currentEntryId {
    final $$QueueEntryRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currentEntryId,
      referencedTable: $db.queueEntryRecords,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueueEntryRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.queueEntryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueueStateRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueStateRecordsTable> {
  $$QueueStateRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  $$QueueEntryRecordsTableAnnotationComposer get currentEntryId {
    final $$QueueEntryRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.currentEntryId,
          referencedTable: $db.queueEntryRecords,
          getReferencedColumn: (t) => t.entryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$QueueEntryRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.queueEntryRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$QueueStateRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueueStateRecordsTable,
          QueueStateRow,
          $$QueueStateRecordsTableFilterComposer,
          $$QueueStateRecordsTableOrderingComposer,
          $$QueueStateRecordsTableAnnotationComposer,
          $$QueueStateRecordsTableCreateCompanionBuilder,
          $$QueueStateRecordsTableUpdateCompanionBuilder,
          (QueueStateRow, $$QueueStateRecordsTableReferences),
          QueueStateRow,
          PrefetchHooks Function({bool currentEntryId})
        > {
  $$QueueStateRecordsTableTableManager(
    _$AppDatabase db,
    $QueueStateRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueStateRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueStateRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueStateRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                Value<String?> currentEntryId = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
              }) => QueueStateRecordsCompanion(
                singletonId: singletonId,
                currentEntryId: currentEntryId,
                updatedAtMs: updatedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                Value<String?> currentEntryId = const Value.absent(),
                required int updatedAtMs,
              }) => QueueStateRecordsCompanion.insert(
                singletonId: singletonId,
                currentEntryId: currentEntryId,
                updatedAtMs: updatedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QueueStateRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({currentEntryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (currentEntryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.currentEntryId,
                        referencedTable: $$QueueStateRecordsTableReferences
                            ._currentEntryIdTable(db),
                        referencedColumn: $$QueueStateRecordsTableReferences
                            ._currentEntryIdTable(db)
                            .entryId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QueueStateRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueueStateRecordsTable,
      QueueStateRow,
      $$QueueStateRecordsTableFilterComposer,
      $$QueueStateRecordsTableOrderingComposer,
      $$QueueStateRecordsTableAnnotationComposer,
      $$QueueStateRecordsTableCreateCompanionBuilder,
      $$QueueStateRecordsTableUpdateCompanionBuilder,
      (QueueStateRow, $$QueueStateRecordsTableReferences),
      QueueStateRow,
      PrefetchHooks Function({bool currentEntryId})
    >;
typedef $$MusicSourceRecordsTableCreateCompanionBuilder =
    MusicSourceRecordsCompanion Function({
      required String sourceId,
      required String name,
      required String sourceType,
      Value<String?> baseUrl,
      required String authType,
      Value<String?> credentialRef,
      Value<String> publicHeadersJson,
      Value<String> endpointsJson,
      Value<String> responseMappingJson,
      Value<bool> enabled,
      Value<String> status,
      Value<int?> lastLatencyMs,
      Value<int?> lastTestedAtMs,
      Value<String?> lastErrorCode,
      Value<bool> builtIn,
      Value<int> rowid,
    });
typedef $$MusicSourceRecordsTableUpdateCompanionBuilder =
    MusicSourceRecordsCompanion Function({
      Value<String> sourceId,
      Value<String> name,
      Value<String> sourceType,
      Value<String?> baseUrl,
      Value<String> authType,
      Value<String?> credentialRef,
      Value<String> publicHeadersJson,
      Value<String> endpointsJson,
      Value<String> responseMappingJson,
      Value<bool> enabled,
      Value<String> status,
      Value<int?> lastLatencyMs,
      Value<int?> lastTestedAtMs,
      Value<String?> lastErrorCode,
      Value<bool> builtIn,
      Value<int> rowid,
    });

class $$MusicSourceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MusicSourceRecordsTable> {
  $$MusicSourceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authType => $composableBuilder(
    column: $table.authType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicHeadersJson => $composableBuilder(
    column: $table.publicHeadersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpointsJson => $composableBuilder(
    column: $table.endpointsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseMappingJson => $composableBuilder(
    column: $table.responseMappingJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastLatencyMs => $composableBuilder(
    column: $table.lastLatencyMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastTestedAtMs => $composableBuilder(
    column: $table.lastTestedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MusicSourceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MusicSourceRecordsTable> {
  $$MusicSourceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authType => $composableBuilder(
    column: $table.authType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicHeadersJson => $composableBuilder(
    column: $table.publicHeadersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpointsJson => $composableBuilder(
    column: $table.endpointsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseMappingJson => $composableBuilder(
    column: $table.responseMappingJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastLatencyMs => $composableBuilder(
    column: $table.lastLatencyMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastTestedAtMs => $composableBuilder(
    column: $table.lastTestedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MusicSourceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MusicSourceRecordsTable> {
  $$MusicSourceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get authType =>
      $composableBuilder(column: $table.authType, builder: (column) => column);

  GeneratedColumn<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publicHeadersJson => $composableBuilder(
    column: $table.publicHeadersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endpointsJson => $composableBuilder(
    column: $table.endpointsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responseMappingJson => $composableBuilder(
    column: $table.responseMappingJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get lastLatencyMs => $composableBuilder(
    column: $table.lastLatencyMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastTestedAtMs => $composableBuilder(
    column: $table.lastTestedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get builtIn =>
      $composableBuilder(column: $table.builtIn, builder: (column) => column);
}

class $$MusicSourceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MusicSourceRecordsTable,
          MusicSourceRow,
          $$MusicSourceRecordsTableFilterComposer,
          $$MusicSourceRecordsTableOrderingComposer,
          $$MusicSourceRecordsTableAnnotationComposer,
          $$MusicSourceRecordsTableCreateCompanionBuilder,
          $$MusicSourceRecordsTableUpdateCompanionBuilder,
          (
            MusicSourceRow,
            BaseReferences<
              _$AppDatabase,
              $MusicSourceRecordsTable,
              MusicSourceRow
            >,
          ),
          MusicSourceRow,
          PrefetchHooks Function()
        > {
  $$MusicSourceRecordsTableTableManager(
    _$AppDatabase db,
    $MusicSourceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MusicSourceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MusicSourceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MusicSourceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sourceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> baseUrl = const Value.absent(),
                Value<String> authType = const Value.absent(),
                Value<String?> credentialRef = const Value.absent(),
                Value<String> publicHeadersJson = const Value.absent(),
                Value<String> endpointsJson = const Value.absent(),
                Value<String> responseMappingJson = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> lastLatencyMs = const Value.absent(),
                Value<int?> lastTestedAtMs = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MusicSourceRecordsCompanion(
                sourceId: sourceId,
                name: name,
                sourceType: sourceType,
                baseUrl: baseUrl,
                authType: authType,
                credentialRef: credentialRef,
                publicHeadersJson: publicHeadersJson,
                endpointsJson: endpointsJson,
                responseMappingJson: responseMappingJson,
                enabled: enabled,
                status: status,
                lastLatencyMs: lastLatencyMs,
                lastTestedAtMs: lastTestedAtMs,
                lastErrorCode: lastErrorCode,
                builtIn: builtIn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceId,
                required String name,
                required String sourceType,
                Value<String?> baseUrl = const Value.absent(),
                required String authType,
                Value<String?> credentialRef = const Value.absent(),
                Value<String> publicHeadersJson = const Value.absent(),
                Value<String> endpointsJson = const Value.absent(),
                Value<String> responseMappingJson = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> lastLatencyMs = const Value.absent(),
                Value<int?> lastTestedAtMs = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MusicSourceRecordsCompanion.insert(
                sourceId: sourceId,
                name: name,
                sourceType: sourceType,
                baseUrl: baseUrl,
                authType: authType,
                credentialRef: credentialRef,
                publicHeadersJson: publicHeadersJson,
                endpointsJson: endpointsJson,
                responseMappingJson: responseMappingJson,
                enabled: enabled,
                status: status,
                lastLatencyMs: lastLatencyMs,
                lastTestedAtMs: lastTestedAtMs,
                lastErrorCode: lastErrorCode,
                builtIn: builtIn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MusicSourceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MusicSourceRecordsTable,
      MusicSourceRow,
      $$MusicSourceRecordsTableFilterComposer,
      $$MusicSourceRecordsTableOrderingComposer,
      $$MusicSourceRecordsTableAnnotationComposer,
      $$MusicSourceRecordsTableCreateCompanionBuilder,
      $$MusicSourceRecordsTableUpdateCompanionBuilder,
      (
        MusicSourceRow,
        BaseReferences<_$AppDatabase, $MusicSourceRecordsTable, MusicSourceRow>,
      ),
      MusicSourceRow,
      PrefetchHooks Function()
    >;
typedef $$LocalFolderRecordsTableCreateCompanionBuilder =
    LocalFolderRecordsCompanion Function({
      required String folderId,
      required String platform,
      required String displayName,
      Value<String?> localPath,
      Value<String?> contentUri,
      Value<String?> grantRef,
      required int createdAtMs,
      required int updatedAtMs,
      Value<int?> lastScannedAtMs,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$LocalFolderRecordsTableUpdateCompanionBuilder =
    LocalFolderRecordsCompanion Function({
      Value<String> folderId,
      Value<String> platform,
      Value<String> displayName,
      Value<String?> localPath,
      Value<String?> contentUri,
      Value<String?> grantRef,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int?> lastScannedAtMs,
      Value<bool> enabled,
      Value<int> rowid,
    });

class $$LocalFolderRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFolderRecordsTable> {
  $$LocalFolderRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grantRef => $composableBuilder(
    column: $table.grantRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastScannedAtMs => $composableBuilder(
    column: $table.lastScannedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalFolderRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFolderRecordsTable> {
  $$LocalFolderRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grantRef => $composableBuilder(
    column: $table.grantRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastScannedAtMs => $composableBuilder(
    column: $table.lastScannedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalFolderRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFolderRecordsTable> {
  $$LocalFolderRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grantRef =>
      $composableBuilder(column: $table.grantRef, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastScannedAtMs => $composableBuilder(
    column: $table.lastScannedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$LocalFolderRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalFolderRecordsTable,
          LocalFolderRow,
          $$LocalFolderRecordsTableFilterComposer,
          $$LocalFolderRecordsTableOrderingComposer,
          $$LocalFolderRecordsTableAnnotationComposer,
          $$LocalFolderRecordsTableCreateCompanionBuilder,
          $$LocalFolderRecordsTableUpdateCompanionBuilder,
          (
            LocalFolderRow,
            BaseReferences<
              _$AppDatabase,
              $LocalFolderRecordsTable,
              LocalFolderRow
            >,
          ),
          LocalFolderRow,
          PrefetchHooks Function()
        > {
  $$LocalFolderRecordsTableTableManager(
    _$AppDatabase db,
    $LocalFolderRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFolderRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFolderRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalFolderRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> folderId = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> contentUri = const Value.absent(),
                Value<String?> grantRef = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int?> lastScannedAtMs = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFolderRecordsCompanion(
                folderId: folderId,
                platform: platform,
                displayName: displayName,
                localPath: localPath,
                contentUri: contentUri,
                grantRef: grantRef,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                lastScannedAtMs: lastScannedAtMs,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String folderId,
                required String platform,
                required String displayName,
                Value<String?> localPath = const Value.absent(),
                Value<String?> contentUri = const Value.absent(),
                Value<String?> grantRef = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<int?> lastScannedAtMs = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFolderRecordsCompanion.insert(
                folderId: folderId,
                platform: platform,
                displayName: displayName,
                localPath: localPath,
                contentUri: contentUri,
                grantRef: grantRef,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                lastScannedAtMs: lastScannedAtMs,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalFolderRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalFolderRecordsTable,
      LocalFolderRow,
      $$LocalFolderRecordsTableFilterComposer,
      $$LocalFolderRecordsTableOrderingComposer,
      $$LocalFolderRecordsTableAnnotationComposer,
      $$LocalFolderRecordsTableCreateCompanionBuilder,
      $$LocalFolderRecordsTableUpdateCompanionBuilder,
      (
        LocalFolderRow,
        BaseReferences<_$AppDatabase, $LocalFolderRecordsTable, LocalFolderRow>,
      ),
      LocalFolderRow,
      PrefetchHooks Function()
    >;
typedef $$LyricsCacheRecordsTableCreateCompanionBuilder =
    LyricsCacheRecordsCompanion Function({
      required String trackSourceType,
      required String trackSourceId,
      required String trackId,
      required String kind,
      required String linesJson,
      required String language,
      Value<String?> translationLanguage,
      Value<int> offsetMs,
      required int updatedAtMs,
      Value<int> rowid,
    });
typedef $$LyricsCacheRecordsTableUpdateCompanionBuilder =
    LyricsCacheRecordsCompanion Function({
      Value<String> trackSourceType,
      Value<String> trackSourceId,
      Value<String> trackId,
      Value<String> kind,
      Value<String> linesJson,
      Value<String> language,
      Value<String?> translationLanguage,
      Value<int> offsetMs,
      Value<int> updatedAtMs,
      Value<int> rowid,
    });

class $$LyricsCacheRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $LyricsCacheRecordsTable> {
  $$LyricsCacheRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translationLanguage => $composableBuilder(
    column: $table.translationLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMs => $composableBuilder(
    column: $table.offsetMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LyricsCacheRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $LyricsCacheRecordsTable> {
  $$LyricsCacheRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translationLanguage => $composableBuilder(
    column: $table.translationLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMs => $composableBuilder(
    column: $table.offsetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LyricsCacheRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LyricsCacheRecordsTable> {
  $$LyricsCacheRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackSourceType => $composableBuilder(
    column: $table.trackSourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackSourceId => $composableBuilder(
    column: $table.trackSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get linesJson =>
      $composableBuilder(column: $table.linesJson, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get translationLanguage => $composableBuilder(
    column: $table.translationLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offsetMs =>
      $composableBuilder(column: $table.offsetMs, builder: (column) => column);

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );
}

class $$LyricsCacheRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LyricsCacheRecordsTable,
          LyricsCacheRow,
          $$LyricsCacheRecordsTableFilterComposer,
          $$LyricsCacheRecordsTableOrderingComposer,
          $$LyricsCacheRecordsTableAnnotationComposer,
          $$LyricsCacheRecordsTableCreateCompanionBuilder,
          $$LyricsCacheRecordsTableUpdateCompanionBuilder,
          (
            LyricsCacheRow,
            BaseReferences<
              _$AppDatabase,
              $LyricsCacheRecordsTable,
              LyricsCacheRow
            >,
          ),
          LyricsCacheRow,
          PrefetchHooks Function()
        > {
  $$LyricsCacheRecordsTableTableManager(
    _$AppDatabase db,
    $LyricsCacheRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LyricsCacheRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LyricsCacheRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LyricsCacheRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> trackSourceType = const Value.absent(),
                Value<String> trackSourceId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> linesJson = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> translationLanguage = const Value.absent(),
                Value<int> offsetMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LyricsCacheRecordsCompanion(
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                kind: kind,
                linesJson: linesJson,
                language: language,
                translationLanguage: translationLanguage,
                offsetMs: offsetMs,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackSourceType,
                required String trackSourceId,
                required String trackId,
                required String kind,
                required String linesJson,
                required String language,
                Value<String?> translationLanguage = const Value.absent(),
                Value<int> offsetMs = const Value.absent(),
                required int updatedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => LyricsCacheRecordsCompanion.insert(
                trackSourceType: trackSourceType,
                trackSourceId: trackSourceId,
                trackId: trackId,
                kind: kind,
                linesJson: linesJson,
                language: language,
                translationLanguage: translationLanguage,
                offsetMs: offsetMs,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LyricsCacheRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LyricsCacheRecordsTable,
      LyricsCacheRow,
      $$LyricsCacheRecordsTableFilterComposer,
      $$LyricsCacheRecordsTableOrderingComposer,
      $$LyricsCacheRecordsTableAnnotationComposer,
      $$LyricsCacheRecordsTableCreateCompanionBuilder,
      $$LyricsCacheRecordsTableUpdateCompanionBuilder,
      (
        LyricsCacheRow,
        BaseReferences<_$AppDatabase, $LyricsCacheRecordsTable, LyricsCacheRow>,
      ),
      LyricsCacheRow,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoryRecordsTableCreateCompanionBuilder =
    SearchHistoryRecordsCompanion Function({
      required String searchId,
      required String query,
      Value<String?> sourceId,
      required int searchedAtMs,
      Value<int> rowid,
    });
typedef $$SearchHistoryRecordsTableUpdateCompanionBuilder =
    SearchHistoryRecordsCompanion Function({
      Value<String> searchId,
      Value<String> query,
      Value<String?> sourceId,
      Value<int> searchedAtMs,
      Value<int> rowid,
    });

class $$SearchHistoryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SearchHistoryRecordsTable> {
  $$SearchHistoryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get searchId => $composableBuilder(
    column: $table.searchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get searchedAtMs => $composableBuilder(
    column: $table.searchedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchHistoryRecordsTable> {
  $$SearchHistoryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get searchId => $composableBuilder(
    column: $table.searchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get searchedAtMs => $composableBuilder(
    column: $table.searchedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchHistoryRecordsTable> {
  $$SearchHistoryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get searchId =>
      $composableBuilder(column: $table.searchId, builder: (column) => column);

  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get searchedAtMs => $composableBuilder(
    column: $table.searchedAtMs,
    builder: (column) => column,
  );
}

class $$SearchHistoryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoryRecordsTable,
          SearchHistoryRow,
          $$SearchHistoryRecordsTableFilterComposer,
          $$SearchHistoryRecordsTableOrderingComposer,
          $$SearchHistoryRecordsTableAnnotationComposer,
          $$SearchHistoryRecordsTableCreateCompanionBuilder,
          $$SearchHistoryRecordsTableUpdateCompanionBuilder,
          (
            SearchHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $SearchHistoryRecordsTable,
              SearchHistoryRow
            >,
          ),
          SearchHistoryRow,
          PrefetchHooks Function()
        > {
  $$SearchHistoryRecordsTableTableManager(
    _$AppDatabase db,
    $SearchHistoryRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoryRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SearchHistoryRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> searchId = const Value.absent(),
                Value<String> query = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> searchedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchHistoryRecordsCompanion(
                searchId: searchId,
                query: query,
                sourceId: sourceId,
                searchedAtMs: searchedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String searchId,
                required String query,
                Value<String?> sourceId = const Value.absent(),
                required int searchedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => SearchHistoryRecordsCompanion.insert(
                searchId: searchId,
                query: query,
                sourceId: sourceId,
                searchedAtMs: searchedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoryRecordsTable,
      SearchHistoryRow,
      $$SearchHistoryRecordsTableFilterComposer,
      $$SearchHistoryRecordsTableOrderingComposer,
      $$SearchHistoryRecordsTableAnnotationComposer,
      $$SearchHistoryRecordsTableCreateCompanionBuilder,
      $$SearchHistoryRecordsTableUpdateCompanionBuilder,
      (
        SearchHistoryRow,
        BaseReferences<
          _$AppDatabase,
          $SearchHistoryRecordsTable,
          SearchHistoryRow
        >,
      ),
      SearchHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingRecordsTableCreateCompanionBuilder =
    AppSettingRecordsCompanion Function({
      required String settingKey,
      required String valueJson,
      required int updatedAtMs,
      Value<int> rowid,
    });
typedef $$AppSettingRecordsTableUpdateCompanionBuilder =
    AppSettingRecordsCompanion Function({
      Value<String> settingKey,
      Value<String> valueJson,
      Value<int> updatedAtMs,
      Value<int> rowid,
    });

class $$AppSettingRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingRecordsTable> {
  $$AppSettingRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingRecordsTable> {
  $$AppSettingRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingRecordsTable> {
  $$AppSettingRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );
}

class $$AppSettingRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingRecordsTable,
          AppSettingRow,
          $$AppSettingRecordsTableFilterComposer,
          $$AppSettingRecordsTableOrderingComposer,
          $$AppSettingRecordsTableAnnotationComposer,
          $$AppSettingRecordsTableCreateCompanionBuilder,
          $$AppSettingRecordsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<
              _$AppDatabase,
              $AppSettingRecordsTable,
              AppSettingRow
            >,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingRecordsTableTableManager(
    _$AppDatabase db,
    $AppSettingRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> settingKey = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingRecordsCompanion(
                settingKey: settingKey,
                valueJson: valueJson,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String settingKey,
                required String valueJson,
                required int updatedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingRecordsCompanion.insert(
                settingKey: settingKey,
                valueJson: valueJson,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingRecordsTable,
      AppSettingRow,
      $$AppSettingRecordsTableFilterComposer,
      $$AppSettingRecordsTableOrderingComposer,
      $$AppSettingRecordsTableAnnotationComposer,
      $$AppSettingRecordsTableCreateCompanionBuilder,
      $$AppSettingRecordsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingRecordsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;
typedef $$SchemaMigrationRecordsTableCreateCompanionBuilder =
    SchemaMigrationRecordsCompanion Function({
      Value<int> version,
      required int appliedAtMs,
      required String description,
    });
typedef $$SchemaMigrationRecordsTableUpdateCompanionBuilder =
    SchemaMigrationRecordsCompanion Function({
      Value<int> version,
      Value<int> appliedAtMs,
      Value<String> description,
    });

class $$SchemaMigrationRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SchemaMigrationRecordsTable> {
  $$SchemaMigrationRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appliedAtMs => $composableBuilder(
    column: $table.appliedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchemaMigrationRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SchemaMigrationRecordsTable> {
  $$SchemaMigrationRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedAtMs => $composableBuilder(
    column: $table.appliedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchemaMigrationRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchemaMigrationRecordsTable> {
  $$SchemaMigrationRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get appliedAtMs => $composableBuilder(
    column: $table.appliedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$SchemaMigrationRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchemaMigrationRecordsTable,
          SchemaMigrationRow,
          $$SchemaMigrationRecordsTableFilterComposer,
          $$SchemaMigrationRecordsTableOrderingComposer,
          $$SchemaMigrationRecordsTableAnnotationComposer,
          $$SchemaMigrationRecordsTableCreateCompanionBuilder,
          $$SchemaMigrationRecordsTableUpdateCompanionBuilder,
          (
            SchemaMigrationRow,
            BaseReferences<
              _$AppDatabase,
              $SchemaMigrationRecordsTable,
              SchemaMigrationRow
            >,
          ),
          SchemaMigrationRow,
          PrefetchHooks Function()
        > {
  $$SchemaMigrationRecordsTableTableManager(
    _$AppDatabase db,
    $SchemaMigrationRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchemaMigrationRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SchemaMigrationRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SchemaMigrationRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int> appliedAtMs = const Value.absent(),
                Value<String> description = const Value.absent(),
              }) => SchemaMigrationRecordsCompanion(
                version: version,
                appliedAtMs: appliedAtMs,
                description: description,
              ),
          createCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                required int appliedAtMs,
                required String description,
              }) => SchemaMigrationRecordsCompanion.insert(
                version: version,
                appliedAtMs: appliedAtMs,
                description: description,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchemaMigrationRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchemaMigrationRecordsTable,
      SchemaMigrationRow,
      $$SchemaMigrationRecordsTableFilterComposer,
      $$SchemaMigrationRecordsTableOrderingComposer,
      $$SchemaMigrationRecordsTableAnnotationComposer,
      $$SchemaMigrationRecordsTableCreateCompanionBuilder,
      $$SchemaMigrationRecordsTableUpdateCompanionBuilder,
      (
        SchemaMigrationRow,
        BaseReferences<
          _$AppDatabase,
          $SchemaMigrationRecordsTable,
          SchemaMigrationRow
        >,
      ),
      SchemaMigrationRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TrackRecordsTableTableManager get trackRecords =>
      $$TrackRecordsTableTableManager(_db, _db.trackRecords);
  $$AlbumRecordsTableTableManager get albumRecords =>
      $$AlbumRecordsTableTableManager(_db, _db.albumRecords);
  $$ArtistRecordsTableTableManager get artistRecords =>
      $$ArtistRecordsTableTableManager(_db, _db.artistRecords);
  $$TrackArtistRecordsTableTableManager get trackArtistRecords =>
      $$TrackArtistRecordsTableTableManager(_db, _db.trackArtistRecords);
  $$AlbumArtistRecordsTableTableManager get albumArtistRecords =>
      $$AlbumArtistRecordsTableTableManager(_db, _db.albumArtistRecords);
  $$PlaylistRecordsTableTableManager get playlistRecords =>
      $$PlaylistRecordsTableTableManager(_db, _db.playlistRecords);
  $$PlaylistEntryRecordsTableTableManager get playlistEntryRecords =>
      $$PlaylistEntryRecordsTableTableManager(_db, _db.playlistEntryRecords);
  $$FavoriteRecordsTableTableManager get favoriteRecords =>
      $$FavoriteRecordsTableTableManager(_db, _db.favoriteRecords);
  $$PlayHistoryRecordsTableTableManager get playHistoryRecords =>
      $$PlayHistoryRecordsTableTableManager(_db, _db.playHistoryRecords);
  $$QueueEntryRecordsTableTableManager get queueEntryRecords =>
      $$QueueEntryRecordsTableTableManager(_db, _db.queueEntryRecords);
  $$QueueStateRecordsTableTableManager get queueStateRecords =>
      $$QueueStateRecordsTableTableManager(_db, _db.queueStateRecords);
  $$MusicSourceRecordsTableTableManager get musicSourceRecords =>
      $$MusicSourceRecordsTableTableManager(_db, _db.musicSourceRecords);
  $$LocalFolderRecordsTableTableManager get localFolderRecords =>
      $$LocalFolderRecordsTableTableManager(_db, _db.localFolderRecords);
  $$LyricsCacheRecordsTableTableManager get lyricsCacheRecords =>
      $$LyricsCacheRecordsTableTableManager(_db, _db.lyricsCacheRecords);
  $$SearchHistoryRecordsTableTableManager get searchHistoryRecords =>
      $$SearchHistoryRecordsTableTableManager(_db, _db.searchHistoryRecords);
  $$AppSettingRecordsTableTableManager get appSettingRecords =>
      $$AppSettingRecordsTableTableManager(_db, _db.appSettingRecords);
  $$SchemaMigrationRecordsTableTableManager get schemaMigrationRecords =>
      $$SchemaMigrationRecordsTableTableManager(
        _db,
        _db.schemaMigrationRecords,
      );
}
