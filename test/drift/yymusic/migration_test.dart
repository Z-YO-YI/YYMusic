import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_library_repository.dart';
import 'package:yymusic/domain/models/pagination.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

void main() {
  final verifier = SchemaVerifier(GeneratedHelper());
  final now = DateTime.utc(2026, 9, 5);
  test(
    'file-backed v1 upgrade survives closing and reopening without reset',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'yymusic-v2-migration-',
      );
      addTearDown(() async => directory.delete(recursive: true));
      final file = File('${directory.path}/legacy.sqlite');
      final old = v1.DatabaseAtV1(NativeDatabase(file));
      try {
        for (final sql in _legacyInserts) {
          await old.customStatement(sql);
        }
      } finally {
        await old.close();
      }
      for (var attempt = 0; attempt < 2; attempt++) {
        final current = AppDatabase(NativeDatabase(file), clock: () => now);
        try {
          await current.validateDatabaseSchema();
          expect(
            (await current.select(current.schemaMigrationRecords).get()).length,
            2,
          );
          expect(
            (await current.select(current.trackRecords).getSingle()).addedAtMs,
            isNull,
          );
          expect(
            (await current.select(current.favoriteRecords).get()).length,
            1,
          );
          expect(
            (await current.select(current.appSettingRecords).getSingle())
                .valueJson,
            '"dark"',
          );
          expect(
            await current.customSelect('PRAGMA foreign_key_check').get(),
            isEmpty,
          );
        } finally {
          await current.close();
        }
      }
    },
  );
  test('v1 migrates to the complete exported v2 schema', () async {
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.rawDatabase.close);
    final db = AppDatabase(schema.newConnection(), clock: () => now);
    try {
      await verifier.migrateAndValidate(db, 2);
      expect(
        (await db.customSelect('PRAGMA foreign_keys').getSingle()).read<int>(
          'foreign_keys',
        ),
        1,
      );
    } finally {
      await db.close();
    }
  });

  test(
    'all 17 legacy tables preserve data and dates remain unknown after reopen',
    () async {
      final schema = await verifier.schemaAt(1);
      final raw = schema.rawDatabase;
      addTearDown(raw.close);
      for (final sql in _legacyInserts) {
        raw.execute(sql);
      }
      final oldRows = {
        for (final table in _tables)
          table: raw
              .select('SELECT * FROM $table')
              .map((row) => Map<String, Object?>.from(row))
              .toList(),
      };
      expect(oldRows.values.every((rows) => rows.isNotEmpty), isTrue);
      var db = AppDatabase(schema.newConnection(), clock: () => now);
      try {
        await verifier.migrateAndValidate(db, 2);
        for (final table in _tables) {
          final rows = (await db.customSelect('SELECT * FROM $table').get())
              .map((row) => Map<String, Object?>.from(row.data))
              .toList();
          if (table == 'tracks') {
            expect(rows.every((row) => row['added_at_ms'] == null), isTrue);
            for (final row in rows) {
              row.remove('added_at_ms');
            }
          }
          if (table == 'schema_migrations') {
            expect(rows.map((row) => row['version']), [1, 2]);
            expect(rows.last['applied_at_ms'], now.millisecondsSinceEpoch);
            rows.removeWhere((row) => row['version'] == 2);
          }
          expect(rows, oldRows[table], reason: 'Legacy data changed in $table');
        }
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        final library = DriftLibraryRepository(db, clock: () => now);
        await library.initialize();
        final legacy = (await library.listTracks(PageRequest())).items;
        expect(legacy.length, 1);
        await library.upsertTracks(legacy);
        expect(
          (await library.listRecentlyAdded(
            PageRequest(),
            since: now.subtract(const Duration(days: 7)),
            until: now,
          )).items,
          isEmpty,
        );
        await library.dispose();
      } finally {
        await db.close();
      }
      db = AppDatabase(
        schema.newConnection(),
        clock: () => now.add(const Duration(days: 1)),
      );
      try {
        await verifier.migrateAndValidate(db, 2);
        final audit = await db
            .customSelect('SELECT * FROM schema_migrations ORDER BY version')
            .get();
        expect(audit.length, 2);
        expect(
          audit.last.read<int>('applied_at_ms'),
          now.millisecondsSinceEpoch,
        );
        expect(
          (await db.select(db.trackRecords).getSingle()).addedAtMs,
          isNull,
        );
      } finally {
        await db.close();
      }
    },
  );

  test('failed migration rolls back column index and audit then retries without data loss', () async {
    final schema = await verifier.schemaAt(1);
    final raw = schema.rawDatabase;
    addTearDown(raw.close);
    for (final sql in _legacyInserts) {
      raw.execute(sql);
    }
    raw.execute(
      'CREATE TRIGGER fail_v2 BEFORE INSERT ON schema_migrations '
      'WHEN NEW.version = 2 BEGIN SELECT RAISE(ABORT, \'fixture migration failure\'); END',
    );
    final broken = AppDatabase(schema.newConnection(), clock: () => now);
    try {
      await expectLater(
        broken.customSelect('SELECT 1').get(),
        throwsA(anything),
      );
    } finally {
      await broken.close();
    }
    expect(raw.select('PRAGMA user_version').single['user_version'], 1);
    expect(
      raw
          .select('PRAGMA table_info(tracks)')
          .any((row) => row['name'] == 'added_at_ms'),
      isFalse,
    );
    expect(
      raw.select("SELECT name FROM sqlite_master WHERE name='tracks_by_added'"),
      isEmpty,
    );
    expect(raw.select('SELECT * FROM schema_migrations').length, 1);
    expect(raw.select('SELECT * FROM favorites').length, 1);
    raw.execute('DROP TRIGGER fail_v2');
    final recovered = AppDatabase(schema.newConnection(), clock: () => now);
    try {
      await verifier.migrateAndValidate(recovered, 2);
      expect(
        (await recovered.select(recovered.favoriteRecords).get()).length,
        1,
      );
      expect(
        (await recovered.select(recovered.queueStateRecords).getSingle())
            .currentEntryId,
        'queue-a',
      );
    } finally {
      await recovered.close();
    }
  });
}

// Only synthetic values in an in-memory v1 database; no credentials or user files.
const _tables = [
  'tracks',
  'albums',
  'artists',
  'track_artists',
  'album_artists',
  'playlists',
  'playlist_entries',
  'favorites',
  'play_history',
  'queue_entries',
  'queue_state',
  'music_sources',
  'local_folders',
  'lyrics_cache',
  'search_history',
  'app_settings',
  'schema_migrations',
];
const _legacyInserts = [
  "INSERT INTO schema_migrations VALUES (1,0,'Initial YYMusic schema')",
  "INSERT INTO music_sources (source_id,name,source_type,base_url,auth_type,credential_ref) VALUES ('source-a','Fixture source','rest','https://music.invalid','bearer','opaque-reference-only')",
  "INSERT INTO tracks (track_id,source_id,source_type,title,duration_ms,availability,album_id,album_title,metadata_json) VALUES ('track-a','source-a','rest','保留旧曲目',120000,'available','album-a','Album','{\"disc\":2}')",
  "INSERT INTO albums (album_id,source_id,title) VALUES ('album-a','source-a','Album')",
  "INSERT INTO artists (artist_id,source_id,name) VALUES ('artist-a','source-a','Artist')",
  "INSERT INTO track_artists VALUES ('rest','source-a','track-a','source-a','artist-a',0)",
  "INSERT INTO album_artists VALUES ('source-a','album-a','source-a','artist-a',0)",
  "INSERT INTO playlists (playlist_id,name,created_at_ms,updated_at_ms) VALUES ('playlist-a','保留歌单',0,0)",
  "INSERT INTO playlist_entries VALUES ('entry-a','playlist-a','rest','source-a','track-a',0,0)",
  "INSERT INTO favorites VALUES ('rest','source-a','track-a',0)",
  "INSERT INTO play_history (history_id,track_source_type,track_source_id,track_id,started_at_ms,last_position_ms) VALUES ('history-a','rest','source-a','track-a',0,30000)",
  "INSERT INTO queue_entries VALUES ('queue-a','rest','source-a','track-a',0,0)",
  "INSERT INTO queue_state VALUES (1,'queue-a',0)",
  "INSERT INTO local_folders (folder_id,platform,display_name,local_path,created_at_ms,updated_at_ms) VALUES ('folder-a','windows','Fixture folder','fixture-only',0,0)",
  "INSERT INTO lyrics_cache (track_source_type,track_source_id,track_id,kind,lines_json,language,updated_at_ms) VALUES ('rest','source-a','track-a','plain','[]','zh',0)",
  "INSERT INTO search_history (search_id,query,searched_at_ms) VALUES ('search-a','保留搜索',0)",
  "INSERT INTO app_settings VALUES ('themeMode','\"dark\"',0)",
];
