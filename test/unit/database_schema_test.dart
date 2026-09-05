import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/database/database_connection.dart';

void main() {
  late AppDatabase database;
  var databaseClosed = false;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory(), clock: () => _epoch);
    databaseClosed = false;
  });

  tearDown(() async {
    if (!databaseClosed) await database.close();
  });

  test('schema v2 creates the exact tables and initial audit rows', () async {
    final tableRows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();
    final tables = tableRows.map((row) => row.read<String>('name')).toList();
    final foreignKeys = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();
    final userVersion = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    final migration = await database
        .customSelect(
          'SELECT version, applied_at_ms, description '
          'FROM schema_migrations',
        )
        .getSingle();
    final queueState = await database
        .customSelect(
          'SELECT singleton_id, current_entry_id, updated_at_ms '
          'FROM queue_state',
        )
        .getSingle();
    await database.validateDatabaseSchema();

    expect(tables, const [
      'album_artists',
      'albums',
      'app_settings',
      'artists',
      'favorites',
      'local_folders',
      'lyrics_cache',
      'music_sources',
      'play_history',
      'playlist_entries',
      'playlists',
      'queue_entries',
      'queue_state',
      'schema_migrations',
      'search_history',
      'track_artists',
      'tracks',
    ]);
    expect(foreignKeys.read<int>('foreign_keys'), 1);
    expect(userVersion.read<int>('user_version'), 2);
    expect(migration.read<int>('version'), 2);
    expect(migration.read<int>('applied_at_ms'), _epoch.millisecondsSinceEpoch);
    expect(migration.read<String>('description'), 'Initial YYMusic schema v2');
    expect(queueState.read<int>('singleton_id'), 1);
    expect(queueState.readNullable<String>('current_entry_id'), isNull);
    expect(
      queueState.read<int>('updated_at_ms'),
      _epoch.millisecondsSinceEpoch,
    );
  });

  test('schema exposes the required deterministic indexes', () async {
    final rows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();

    expect(rows.map((row) => row.read<String>('name')), const [
      'albums_by_title',
      'artists_by_name',
      'favorites_by_added',
      'play_history_by_started',
      'playlist_entries_by_track',
      'playlists_by_updated',
      'queue_entries_by_track',
      'search_history_by_time',
      'tracks_by_added',
      'tracks_by_album',
      'tracks_by_title',
    ]);
  });

  test('track and queue checks reject invalid persisted state', () async {
    await expectLater(
      database.customStatement(
        'INSERT INTO tracks '
        '(track_id, source_id, source_type, title, duration_ms, availability) '
        "VALUES ('missing-path', 'local', 'local', 'Invalid', 1, 'available')",
      ),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      database.customStatement(
        'INSERT INTO tracks '
        '(track_id, source_id, source_type, title, duration_ms, availability) '
        "VALUES ('negative', 'rest', 'rest', 'Invalid', -1, 'available')",
      ),
      throwsA(isA<SqliteException>()),
    );

    await database.customStatement(
      'INSERT INTO queue_entries '
      '(entry_id, track_source_type, track_source_id, track_id, position, added_at_ms) '
      "VALUES ('entry-1', 'rest', 'source-a', 'track-a', 0, 0)",
    );
    await database.customStatement(
      'INSERT INTO queue_entries '
      '(entry_id, track_source_type, track_source_id, track_id, position, added_at_ms) '
      "VALUES ('entry-2', 'rest', 'source-a', 'track-a', 1, 0)",
    );
    await expectLater(
      database.customStatement(
        'INSERT INTO queue_entries '
        '(entry_id, track_source_type, track_source_id, track_id, position, added_at_ms) '
        "VALUES ('entry-3', 'rest', 'source-a', 'track-b', 1, 0)",
      ),
      throwsA(isA<SqliteException>()),
    );

    final count = await database
        .customSelect('SELECT COUNT(*) AS amount FROM queue_entries')
        .getSingle();
    expect(count.read<int>('amount'), 2);
  });

  test('playlist deletion cascades but source deletion preserves references', () async {
    await database.customStatement(
      'INSERT INTO music_sources '
      '(source_id, name, source_type, base_url, auth_type) '
      "VALUES ('source-a', 'REST A', 'rest', 'https://music.invalid', 'none')",
    );
    await database.customStatement(
      'INSERT INTO tracks '
      '(track_id, source_id, source_type, title, duration_ms, availability) '
      "VALUES ('track-a', 'source-a', 'rest', 'Track A', 1000, 'available')",
    );
    await database.customStatement(
      'INSERT INTO favorites '
      '(track_source_type, track_source_id, track_id, added_at_ms) '
      "VALUES ('rest', 'source-a', 'track-a', 0)",
    );
    await database.customStatement(
      'INSERT INTO playlists '
      '(playlist_id, name, created_at_ms, updated_at_ms) '
      "VALUES ('playlist-a', 'Playlist A', 0, 0)",
    );
    await database.customStatement(
      'INSERT INTO playlist_entries '
      '(entry_id, playlist_id, track_source_type, track_source_id, track_id, position, added_at_ms) '
      "VALUES ('playlist-entry-a', 'playlist-a', 'rest', 'source-a', 'track-a', 0, 0)",
    );

    await database.customStatement(
      "DELETE FROM music_sources WHERE source_id = 'source-a'",
    );
    expect(await _count(database, 'tracks'), 1);
    expect(await _count(database, 'favorites'), 1);
    expect(await _count(database, 'playlist_entries'), 1);

    await database.customStatement(
      "DELETE FROM playlists WHERE playlist_id = 'playlist-a'",
    );
    expect(await _count(database, 'playlist_entries'), 0);
    expect(await _count(database, 'tracks'), 1);
    expect(await _count(database, 'favorites'), 1);
  });

  test('catalog junctions enforce parents and cascade independently', () async {
    await expectLater(
      database.customStatement(
        'INSERT INTO track_artists '
        '(track_source_type, track_source_id, track_id, artist_source_id, artist_id, position) '
        "VALUES ('rest', 'source-a', 'track-a', 'source-a', 'artist-a', 0)",
      ),
      throwsA(isA<SqliteException>()),
    );
    await database.customStatement(
      'INSERT INTO tracks '
      '(track_id, source_id, source_type, title, duration_ms, availability) '
      "VALUES ('track-a', 'source-a', 'rest', 'Track A', 1000, 'available')",
    );
    await database.customStatement(
      'INSERT INTO artists '
      '(artist_id, source_id, name) '
      "VALUES ('artist-a', 'source-a', 'Artist A')",
    );
    await database.customStatement(
      'INSERT INTO track_artists '
      '(track_source_type, track_source_id, track_id, artist_source_id, artist_id, position) '
      "VALUES ('rest', 'source-a', 'track-a', 'source-a', 'artist-a', 0)",
    );
    expect(await _count(database, 'track_artists'), 1);

    await database.customStatement(
      "DELETE FROM artists WHERE artist_id = 'artist-a' AND source_id = 'source-a'",
    );
    expect(await _count(database, 'track_artists'), 0);
    expect(await _count(database, 'tracks'), 1);
  });

  test(
    'music source table stores references but no plaintext secret columns',
    () async {
      final columns = await database
          .customSelect('PRAGMA table_info(music_sources)')
          .get();
      final names = columns.map((row) => row.read<String>('name')).toList();
      final prohibited = RegExp(
        r'authorization|password|api_?key|bearer|token|secret',
        caseSensitive: false,
      );

      expect(names, const [
        'source_id',
        'name',
        'source_type',
        'base_url',
        'auth_type',
        'credential_ref',
        'public_headers_json',
        'endpoints_json',
        'response_mapping_json',
        'enabled',
        'status',
        'last_latency_ms',
        'last_tested_at_ms',
        'last_error_code',
        'built_in',
      ]);
      expect(names.where(prohibited.hasMatch), isEmpty);
    },
  );

  test('system playlist and lyrics kind checks reject mismatches', () async {
    await expectLater(
      database.customStatement(
        'INSERT INTO playlists '
        '(playlist_id, name, created_at_ms, updated_at_ms, is_system) '
        "VALUES ('broken-system', 'Broken', 0, 0, 1)",
      ),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      database.customStatement(
        'INSERT INTO lyrics_cache '
        '(track_source_type, track_source_id, track_id, kind, lines_json, language, updated_at_ms) '
        "VALUES ('rest', 'source-a', 'track-a', 'script', '[]', 'en', 0)",
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test(
    'background opener uses the injected application support directory',
    () async {
      await database.close();
      databaseClosed = true;
      final root = await Directory.systemTemp.createTemp(
        'yymusic-schema-test-',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final fileDatabase = await openDefaultDatabase(
        supportDirectory: () async => root,
      );
      addTearDown(fileDatabase.close);

      final migration = await fileDatabase
          .customSelect('SELECT version FROM schema_migrations')
          .getSingle();
      expect(migration.read<int>('version'), 2);
      expect(
        File(path.join(root.path, 'YYMusic', 'yymusic.sqlite')).existsSync(),
        isTrue,
      );
    },
  );
}

Future<int> _count(AppDatabase database, String table) async {
  const allowed = {'tracks', 'favorites', 'playlist_entries', 'track_artists'};
  if (!allowed.contains(table)) throw ArgumentError.value(table, 'table');
  final row = await database
      .customSelect('SELECT COUNT(*) AS amount FROM $table')
      .getSingle();
  return row.read<int>('amount');
}

final _epoch = DateTime.fromMillisecondsSinceEpoch(1735689600000, isUtc: true);
