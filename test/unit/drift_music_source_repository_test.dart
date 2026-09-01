import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_music_source_repository.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/track.dart';

void main() {
  late AppDatabase database;
  late DriftMusicSourceRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory(), clock: () => _epoch);
    repository = DriftMusicSourceRepository(database);
  });

  tearDown(() async {
    await repository.dispose();
    await database.close();
  });

  test('round-trips complete REST configuration with canonical JSON', () async {
    final source = _restSource(
      id: 'rest-source',
      name: 'REST Source',
      enabled: true,
      status: MusicSourceStatus.error,
      lastLatency: const Duration(milliseconds: 125),
      lastTestedAt: _epoch,
      lastErrorCode: DomainFailureCode.networkTimeout,
    );
    await repository.saveSource(source);

    final stored = (await repository.getSource(source.id))!;
    expect(stored.id, source.id);
    expect(stored.name, source.name);
    expect(stored.type, MusicSourceType.rest);
    expect(stored.baseUrl, Uri.parse('https://music.invalid/api/'));
    expect(stored.authType, MusicSourceAuthType.bearer);
    expect(stored.credentialRef, 'vault-reference');
    expect(stored.publicHeaders, {
      'Z-Public': 'last',
      'Accept': 'application/json',
    });
    expect(stored.endpoints, {'tracks': '/tracks', 'albums': '/albums'});
    expect(stored.responseMapping, {
      'title': r'$.data.title',
      'items': r'$.data.items[0]',
    });
    expect(stored.enabled, isTrue);
    expect(stored.status, MusicSourceStatus.error);
    expect(stored.lastLatency, const Duration(milliseconds: 125));
    expect(stored.lastTestedAt, _epoch);
    expect(stored.lastErrorCode, DomainFailureCode.networkTimeout);
    expect(stored.builtIn, isFalse);
    expect(() => stored.publicHeaders['new'] = 'value', throwsUnsupportedError);

    final row = await database.select(database.musicSourceRecords).getSingle();
    expect(
      row.publicHeadersJson,
      '{"Accept":"application/json","Z-Public":"last"}',
    );
    expect(row.endpointsJson, '{"albums":"/albums","tracks":"/tracks"}');
    expect(
      row.responseMappingJson,
      r'{"items":"$.data.items[0]","title":"$.data.title"}',
    );
    expect(row.credentialRef, 'vault-reference');
    expect(row.toString(), isNot(contains('token-value')));
  });

  test(
    'round-trips a built-in local source without a URL or credential',
    () async {
      final source = MusicSourceConfig(
        id: 'local-library',
        name: 'Local Library',
        type: MusicSourceType.local,
        authType: MusicSourceAuthType.system,
        enabled: true,
        status: MusicSourceStatus.connected,
        builtIn: true,
      );
      await repository.saveSource(source);

      final stored = (await repository.getSource(source.id))!;
      expect(stored.type, MusicSourceType.local);
      expect(stored.baseUrl, isNull);
      expect(stored.credentialRef, isNull);
      expect(stored.publicHeaders, isEmpty);
      expect(stored.endpoints, isEmpty);
      expect(stored.responseMapping, isEmpty);
      expect(stored.builtIn, isTrue);
    },
  );

  test(
    'watches immutable source snapshots in deterministic ID order',
    () async {
      final iterator = StreamIterator(repository.watchSources());
      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, isEmpty);

      await repository.saveSource(_restSource(id: 'source-z', name: 'Zed'));
      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current.map((source) => source.id), ['source-z']);

      await repository.saveSource(_restSource(id: 'source-a', name: 'Alpha'));
      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current.map((source) => source.id), [
        'source-a',
        'source-z',
      ]);
      expect(
        () => iterator.current.add(_restSource(id: 'x', name: 'X')),
        throwsUnsupportedError,
      );
      await iterator.cancel();
    },
  );

  test('protects stable type and built-in source identity', () async {
    final builtIn = MusicSourceConfig(
      id: 'local-library',
      name: 'Local Library',
      type: MusicSourceType.local,
      authType: MusicSourceAuthType.system,
      builtIn: true,
    );
    await repository.saveSource(builtIn);

    await expectLater(
      repository.saveSource(
        MusicSourceConfig(
          id: builtIn.id,
          name: 'Converted',
          type: MusicSourceType.local,
          authType: MusicSourceAuthType.system,
          builtIn: false,
        ),
      ),
      throwsA(_failureWith(DomainFailureCode.forbidden)),
    );
    await expectLater(
      repository.saveSource(
        _restSource(id: builtIn.id, name: 'Changed type', builtIn: true),
      ),
      throwsA(_failureWith(DomainFailureCode.forbidden)),
    );
    await expectLater(
      repository.deleteSource(builtIn.id),
      throwsA(_failureWith(DomainFailureCode.forbidden)),
    );
    expect(
      (await repository.getSource(builtIn.id))!.type,
      MusicSourceType.local,
    );

    await repository.saveSource(_restSource(id: 'custom', name: 'Custom'));
    await repository.deleteSource('custom');
    await repository.deleteSource('custom');
    expect(await repository.getSource('custom'), isNull);
  });

  test('deleting a source preserves user TrackRef records', () async {
    final source = _restSource(id: 'source-a', name: 'Source A');
    await repository.saveSource(source);
    await database.customStatement(
      'INSERT INTO favorites '
      '(track_source_type, track_source_id, track_id, added_at_ms) '
      "VALUES ('rest', 'source-a', 'track-a', ?)",
      [_epoch.millisecondsSinceEpoch],
    );

    await repository.deleteSource(source.id);
    expect(await repository.getSource(source.id), isNull);
    expect(await _count(database, 'favorites'), 1);
  });

  test('rejects corrupt configuration without leaking stored values', () async {
    final source = _restSource(id: 'sensitive-source', name: 'Private Source');

    Future<void> expectCorrupt(String sql, List<Object?> args) async {
      await database.customStatement(
        'DELETE FROM music_sources WHERE source_id = ?',
        [source.id],
      );
      await repository.saveSource(source);
      await database.customStatement(sql, args);
      Object? failure;
      try {
        await repository.getSource(source.id);
      } catch (error) {
        failure = error;
      }
      expect(failure, _failureWith(DomainFailureCode.databaseCorrupted));
      expect(failure.toString(), isNot(contains('sensitive-source')));
      expect(failure.toString(), isNot(contains('super-secret-token')));
      expect(failure.toString(), isNot(contains('music.invalid')));
    }

    await expectCorrupt('UPDATE music_sources SET public_headers_json = ?', [
      '[]',
    ]);
    await expectCorrupt('UPDATE music_sources SET public_headers_json = ?', [
      '{"Accept":42}',
    ]);
    await expectCorrupt('UPDATE music_sources SET public_headers_json = ?', [
      '{"Authorization":"super-secret-token"}',
    ]);
    await expectCorrupt('UPDATE music_sources SET endpoints_json = ?', [
      '{"search":"https://music.invalid/search"}',
    ]);
    await expectCorrupt('UPDATE music_sources SET response_mapping_json = ?', [
      '{"title":"process.exit()"}',
    ]);
    await expectCorrupt('UPDATE music_sources SET auth_type = ?', ['invalid']);
    await expectCorrupt('UPDATE music_sources SET status = ?', ['invalid']);
    await expectCorrupt('UPDATE music_sources SET last_error_code = ?', [
      'invalid',
    ]);
    await expectCorrupt('UPDATE music_sources SET base_url = ?', [
      'http://user:super-secret-token@music.invalid/api',
    ]);
    await expectCorrupt('UPDATE music_sources SET last_tested_at_ms = ?', [
      9223372036854775807,
    ]);
    await expectCorrupt('UPDATE music_sources SET last_latency_ms = ?', [
      9223372036854775807,
    ]);
  });

  test('redacts SQLite failures', () async {
    await database.customStatement('DROP TABLE music_sources');
    Object? failure;
    try {
      await repository.getSource('sensitive-source');
    } catch (error) {
      failure = error;
    }
    expect(failure, _failureWith(DomainFailureCode.databaseCorrupted));
    expect(failure.toString(), isNot(contains('sensitive-source')));
    expect(failure.toString(), isNot(contains('SELECT')));
  });

  test('supports shared and owned database disposal', () async {
    await repository.dispose();
    await repository.dispose();
    expect(() => repository.watchSources(), throwsStateError);
    expect(await _count(database, 'music_sources'), 0);

    final owned = DriftMusicSourceRepository.owned(database);
    await owned.saveSource(_restSource(id: 'owned', name: 'Owned'));
    await owned.dispose();
    await owned.dispose();
    expect(() => owned.getSource('owned'), throwsStateError);
    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(anything),
    );
  });
}

final DateTime _epoch = DateTime.utc(2026, 9, 1, 8);

MusicSourceConfig _restSource({
  required String id,
  required String name,
  bool enabled = false,
  MusicSourceStatus status = MusicSourceStatus.disconnected,
  Duration? lastLatency,
  DateTime? lastTestedAt,
  DomainFailureCode? lastErrorCode,
  bool builtIn = false,
}) => MusicSourceConfig(
  id: id,
  name: name,
  type: MusicSourceType.rest,
  baseUrl: Uri.parse('https://music.invalid/api/'),
  authType: MusicSourceAuthType.bearer,
  credentialRef: 'vault-reference',
  publicHeaders: const {'Z-Public': 'last', 'Accept': 'application/json'},
  endpoints: const {'tracks': '/tracks', 'albums': '/albums'},
  responseMapping: const {
    'title': r'$.data.title',
    'items': r'$.data.items[0]',
  },
  enabled: enabled,
  status: status,
  lastLatency: lastLatency,
  lastTestedAt: lastTestedAt,
  lastErrorCode: lastErrorCode,
  builtIn: builtIn,
);

Future<int> _count(AppDatabase database, String table) async =>
    (await database
            .customSelect('SELECT COUNT(*) AS count FROM $table')
            .getSingle())
        .read<int>('count');

Matcher _failureWith(DomainFailureCode code) =>
    isA<DomainFailure>().having((failure) => failure.code, 'code', code);
