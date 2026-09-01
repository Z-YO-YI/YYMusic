import 'package:drift/drift.dart';

@DataClassName('TrackRow')
@TableIndex(name: 'tracks_by_title', columns: {#title})
@TableIndex(name: 'tracks_by_album', columns: {#sourceId, #albumId})
class TrackRecords extends Table {
  @override
  String get tableName => 'tracks';

  TextColumn get trackId => text().withLength(min: 1, max: 256)();
  TextColumn get sourceId => text().withLength(min: 1, max: 256)();
  TextColumn get sourceType => text().withLength(min: 1, max: 16)();
  TextColumn get title => text().withLength(min: 1, max: 1024)();
  TextColumn get albumId => text().nullable()();
  TextColumn get albumTitle => text().nullable()();
  IntColumn get durationMs => integer()();
  TextColumn get artworkUri => text().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get contentUri => text().nullable()();
  TextColumn get fileFingerprint => text().nullable()();
  IntColumn get modifiedAtMs => integer().nullable()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get availability => text().withLength(min: 1, max: 32)();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column<Object>> get primaryKey => {sourceType, sourceId, trackId};

  @override
  List<String> get customConstraints => const [
    "CHECK (source_type IN ('local', 'rest'))",
    'CHECK (duration_ms >= 0)',
    'CHECK (file_size IS NULL OR file_size >= 0)',
    "CHECK (availability IN ('available', 'sourceDisabled', "
        "'sourceRemoved', 'localMissing', 'unsupported'))",
    "CHECK ((source_type = 'local' AND "
        '(local_path IS NOT NULL OR content_uri IS NOT NULL)) OR '
        "(source_type = 'rest' AND local_path IS NULL AND content_uri IS NULL))",
  ];
}

@DataClassName('AlbumRow')
@TableIndex(name: 'albums_by_title', columns: {#title})
class AlbumRecords extends Table {
  @override
  String get tableName => 'albums';

  TextColumn get albumId => text().withLength(min: 1, max: 256)();
  TextColumn get sourceId => text().withLength(min: 1, max: 256)();
  TextColumn get title => text().withLength(min: 1, max: 1024)();
  IntColumn get year => integer().nullable()();
  TextColumn get artworkUri => text().nullable()();
  IntColumn get trackCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {sourceId, albumId};

  @override
  List<String> get customConstraints => const [
    'CHECK (year IS NULL OR year BETWEEN 1 AND 9999)',
    'CHECK (track_count >= 0)',
  ];
}

@DataClassName('ArtistRow')
@TableIndex(name: 'artists_by_name', columns: {#name})
class ArtistRecords extends Table {
  @override
  String get tableName => 'artists';

  TextColumn get artistId => text().withLength(min: 1, max: 256)();
  TextColumn get sourceId => text().withLength(min: 1, max: 256)();
  TextColumn get name => text().withLength(min: 1, max: 512)();
  TextColumn get artworkUri => text().nullable()();
  IntColumn get albumCount => integer().withDefault(const Constant(0))();
  IntColumn get trackCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {sourceId, artistId};

  @override
  List<String> get customConstraints => const [
    'CHECK (album_count >= 0)',
    'CHECK (track_count >= 0)',
  ];
}

@DataClassName('TrackArtistRow')
class TrackArtistRecords extends Table {
  @override
  String get tableName => 'track_artists';

  TextColumn get trackSourceType => text()();
  TextColumn get trackSourceId => text()();
  TextColumn get trackId => text()();
  TextColumn get artistSourceId => text()();
  TextColumn get artistId => text()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {
    trackSourceType,
    trackSourceId,
    trackId,
    artistSourceId,
    artistId,
  };

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {trackSourceType, trackSourceId, trackId, position},
  ];

  @override
  List<String> get customConstraints => const [
    'CHECK (position >= 0)',
    'FOREIGN KEY (track_source_type, track_source_id, track_id) '
        'REFERENCES tracks (source_type, source_id, track_id) ON DELETE CASCADE',
    'FOREIGN KEY (artist_source_id, artist_id) '
        'REFERENCES artists (source_id, artist_id) ON DELETE CASCADE',
  ];
}

@DataClassName('AlbumArtistRow')
class AlbumArtistRecords extends Table {
  @override
  String get tableName => 'album_artists';

  TextColumn get albumSourceId => text()();
  TextColumn get albumId => text()();
  TextColumn get artistSourceId => text()();
  TextColumn get artistId => text()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {
    albumSourceId,
    albumId,
    artistSourceId,
    artistId,
  };

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {albumSourceId, albumId, position},
  ];

  @override
  List<String> get customConstraints => const [
    'CHECK (position >= 0)',
    'FOREIGN KEY (album_source_id, album_id) '
        'REFERENCES albums (source_id, album_id) ON DELETE CASCADE',
    'FOREIGN KEY (artist_source_id, artist_id) '
        'REFERENCES artists (source_id, artist_id) ON DELETE CASCADE',
  ];
}

@DataClassName('PlaylistRow')
@TableIndex(name: 'playlists_by_updated', columns: {#updatedAtMs})
class PlaylistRecords extends Table {
  @override
  String get tableName => 'playlists';

  TextColumn get playlistId => text().withLength(min: 1, max: 256)();
  TextColumn get name => text().withLength(min: 1, max: 512)();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  TextColumn get systemType => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {playlistId};

  @override
  List<String> get customConstraints => const [
    'CHECK (updated_at_ms >= created_at_ms)',
    "CHECK ((is_system = 0 AND system_type IS NULL) OR "
        "(is_system = 1 AND system_type IS NOT NULL AND "
        "system_type IN ('favorites', 'recent', 'queue')))",
  ];
}

@DataClassName('PlaylistEntryRow')
@TableIndex(
  name: 'playlist_entries_by_track',
  columns: {#trackSourceType, #trackSourceId, #trackId},
)
class PlaylistEntryRecords extends Table {
  @override
  String get tableName => 'playlist_entries';

  TextColumn get entryId => text().withLength(min: 1, max: 256)();
  TextColumn get playlistId => text().references(
    PlaylistRecords,
    #playlistId,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get trackSourceType => text()();
  TextColumn get trackSourceId => text()();
  TextColumn get trackId => text()();
  IntColumn get position => integer()();
  IntColumn get addedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {entryId};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {playlistId, position},
  ];

  @override
  List<String> get customConstraints => const ['CHECK (position >= 0)'];
}

@DataClassName('FavoriteRow')
@TableIndex(name: 'favorites_by_added', columns: {#addedAtMs})
class FavoriteRecords extends Table {
  @override
  String get tableName => 'favorites';

  TextColumn get trackSourceType => text()();
  TextColumn get trackSourceId => text()();
  TextColumn get trackId => text()();
  IntColumn get addedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {
    trackSourceType,
    trackSourceId,
    trackId,
  };
}

@DataClassName('PlayHistoryRow')
@TableIndex(name: 'play_history_by_started', columns: {#startedAtMs})
class PlayHistoryRecords extends Table {
  @override
  String get tableName => 'play_history';

  TextColumn get historyId => text().withLength(min: 1, max: 256)();
  TextColumn get trackSourceType => text()();
  TextColumn get trackSourceId => text()();
  TextColumn get trackId => text()();
  IntColumn get startedAtMs => integer()();
  IntColumn get lastPositionMs => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {historyId};

  @override
  List<String> get customConstraints => const ['CHECK (last_position_ms >= 0)'];
}

@DataClassName('QueueEntryRow')
@TableIndex(
  name: 'queue_entries_by_track',
  columns: {#trackSourceType, #trackSourceId, #trackId},
)
class QueueEntryRecords extends Table {
  @override
  String get tableName => 'queue_entries';

  TextColumn get entryId => text().withLength(min: 1, max: 256)();
  TextColumn get trackSourceType => text()();
  TextColumn get trackSourceId => text()();
  TextColumn get trackId => text()();
  IntColumn get position => integer().unique()();
  IntColumn get addedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {entryId};

  @override
  List<String> get customConstraints => const ['CHECK (position >= 0)'];
}

@DataClassName('QueueStateRow')
class QueueStateRecords extends Table {
  @override
  String get tableName => 'queue_state';

  IntColumn get singletonId => integer()();
  TextColumn get currentEntryId => text()
      .references(QueueEntryRecords, #entryId, onDelete: KeyAction.setNull)
      .nullable()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {singletonId};

  @override
  List<String> get customConstraints => const ['CHECK (singleton_id = 1)'];
}

@DataClassName('MusicSourceRow')
class MusicSourceRecords extends Table {
  @override
  String get tableName => 'music_sources';

  TextColumn get sourceId => text().withLength(min: 1, max: 256)();
  TextColumn get name => text().withLength(min: 1, max: 512)();
  TextColumn get sourceType => text()();
  TextColumn get baseUrl => text().nullable()();
  TextColumn get authType => text()();
  TextColumn get credentialRef => text().nullable()();
  TextColumn get publicHeadersJson =>
      text().withDefault(const Constant('{}'))();
  TextColumn get endpointsJson => text().withDefault(const Constant('{}'))();
  TextColumn get responseMappingJson =>
      text().withDefault(const Constant('{}'))();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('disconnected'))();
  IntColumn get lastLatencyMs => integer().nullable()();
  IntColumn get lastTestedAtMs => integer().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  BoolColumn get builtIn => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {sourceId};

  @override
  List<String> get customConstraints => const [
    "CHECK (source_type IN ('local', 'rest'))",
    'CHECK (last_latency_ms IS NULL OR last_latency_ms >= 0)',
    "CHECK ((source_type = 'local' AND base_url IS NULL) OR "
        "(source_type = 'rest' AND base_url IS NOT NULL))",
  ];
}

@DataClassName('LocalFolderRow')
class LocalFolderRecords extends Table {
  @override
  String get tableName => 'local_folders';

  TextColumn get folderId => text().withLength(min: 1, max: 256)();
  TextColumn get platform => text().withLength(min: 1, max: 32)();
  TextColumn get displayName => text().withLength(min: 1, max: 512)();
  TextColumn get localPath => text().nullable()();
  TextColumn get contentUri => text().nullable()();
  TextColumn get grantRef => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get lastScannedAtMs => integer().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {folderId};

  @override
  List<String> get customConstraints => const [
    'CHECK (local_path IS NOT NULL OR content_uri IS NOT NULL)',
    'CHECK (updated_at_ms >= created_at_ms)',
  ];
}

@DataClassName('LyricsCacheRow')
class LyricsCacheRecords extends Table {
  @override
  String get tableName => 'lyrics_cache';

  TextColumn get trackSourceType => text()();
  TextColumn get trackSourceId => text()();
  TextColumn get trackId => text()();
  TextColumn get kind => text()();
  TextColumn get linesJson => text()();
  TextColumn get language => text().withLength(min: 1, max: 64)();
  TextColumn get translationLanguage => text().nullable()();
  IntColumn get offsetMs => integer().withDefault(const Constant(0))();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {
    trackSourceType,
    trackSourceId,
    trackId,
  };

  @override
  List<String> get customConstraints => const [
    "CHECK (kind IN ('plain', 'synchronized'))",
  ];
}

@DataClassName('SearchHistoryRow')
@TableIndex(name: 'search_history_by_time', columns: {#searchedAtMs})
class SearchHistoryRecords extends Table {
  @override
  String get tableName => 'search_history';

  TextColumn get searchId => text().withLength(min: 1, max: 256)();
  TextColumn get query => text().withLength(min: 1, max: 2048)();
  TextColumn get sourceId => text().nullable()();
  IntColumn get searchedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {searchId};
}

@DataClassName('AppSettingRow')
class AppSettingRecords extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get settingKey => text().withLength(min: 1, max: 256)();
  TextColumn get valueJson => text()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {settingKey};
}

@DataClassName('SchemaMigrationRow')
class SchemaMigrationRecords extends Table {
  @override
  String get tableName => 'schema_migrations';

  IntColumn get version => integer()();
  IntColumn get appliedAtMs => integer()();
  TextColumn get description => text().withLength(min: 1, max: 512)();

  @override
  Set<Column<Object>> get primaryKey => {version};

  @override
  List<String> get customConstraints => const ['CHECK (version > 0)'];
}
