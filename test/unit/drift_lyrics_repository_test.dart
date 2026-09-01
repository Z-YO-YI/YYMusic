import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_lyrics_repository.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/lyrics.dart';
import 'package:yymusic/domain/models/track.dart';

void main() {
  late AppDatabase database;
  late DriftLyricsRepository repository;
  late DateTime now;

  setUp(() {
    now = _epoch;
    database = AppDatabase(NativeDatabase.memory(), clock: () => _epoch);
    repository = DriftLyricsRepository(database, clock: () => now);
  });

  tearDown(() async {
    await repository.dispose();
    await database.close();
  });

  test('upserts and removes plain lyrics without catalog rows', () async {
    final track = _ref('plain-track');
    expect(await repository.getLyrics(track), isNull);

    await repository.saveLyrics(
      _document(
        track: track,
        lines: [
          LyricsLine(text: 'First line'),
          LyricsLine(text: 'Second line'),
        ],
      ),
    );

    var stored = await repository.getLyrics(track);
    expect(stored, isNotNull);
    expect(stored!.track, track);
    expect(stored.kind, LyricsKind.plain);
    expect(stored.language, 'en');
    expect(stored.translationLanguage, isNull);
    expect(stored.offset, Duration.zero);
    expect(stored.lines.map((line) => line.text), [
      'First line',
      'Second line',
    ]);
    expect(
      () => stored!.lines.add(LyricsLine(text: 'Mutation')),
      throwsUnsupportedError,
    );
    expect(await _count(database, 'lyrics_cache'), 1);
    expect(await _count(database, 'tracks'), 0);
    var row = await database.select(database.lyricsCacheRecords).getSingle();
    expect(row.updatedAtMs, _epoch.millisecondsSinceEpoch);

    now = _epoch.add(const Duration(minutes: 2));
    await repository.saveLyrics(
      _document(
        track: track,
        lines: [LyricsLine(text: 'Replacement')],
      ),
    );
    expect(await _count(database, 'lyrics_cache'), 1);
    stored = await repository.getLyrics(track);
    expect(stored!.lines.single.text, 'Replacement');
    row = await database.select(database.lyricsCacheRecords).getSingle();
    expect(row.updatedAtMs, now.millisecondsSinceEpoch);

    await repository.removeLyrics(track);
    await repository.removeLyrics(track);
    expect(await repository.getLyrics(track), isNull);
  });

  test(
    'round-trips synchronized bilingual lyrics and canonical JSON',
    () async {
      final track = _ref('sync-track', sourceId: 'remote');
      final document = LyricsDocument(
        track: track,
        kind: LyricsKind.synchronized,
        lines: [
          LyricsLine(
            start: const Duration(milliseconds: 120),
            end: const Duration(milliseconds: 920),
            text: 'Hello',
            translation: '你好',
          ),
          LyricsLine(
            start: const Duration(milliseconds: 920),
            end: const Duration(milliseconds: 1800),
            text: 'Again',
            translation: '再次',
          ),
        ],
        language: 'en-US',
        translationLanguage: 'zh-CN',
        offset: const Duration(milliseconds: -125),
      );

      await repository.saveLyrics(document);
      final stored = (await repository.getLyrics(track))!;
      expect(stored.kind, LyricsKind.synchronized);
      expect(stored.language, 'en-US');
      expect(stored.translationLanguage, 'zh-CN');
      expect(stored.offset, const Duration(milliseconds: -125));
      expect(stored.lines[0].start, const Duration(milliseconds: 120));
      expect(stored.lines[1].end, const Duration(milliseconds: 1800));
      expect(stored.lines.map((line) => line.translation), ['你好', '再次']);

      final row = await database
          .select(database.lyricsCacheRecords)
          .getSingle();
      expect(jsonDecode(row.linesJson), [
        {'startMs': 120, 'endMs': 920, 'text': 'Hello', 'translation': '你好'},
        {'startMs': 920, 'endMs': 1800, 'text': 'Again', 'translation': '再次'},
      ]);
    },
  );

  test('partitions the cache by the complete TrackRef', () async {
    final refs = [
      _ref('same', sourceId: 'alpha'),
      _ref('same', sourceId: 'beta'),
      _ref('same', sourceId: 'alpha', type: MusicSourceType.local),
    ];
    for (var index = 0; index < refs.length; index++) {
      await repository.saveLyrics(
        _document(
          track: refs[index],
          lines: [LyricsLine(text: 'Lyrics $index')],
        ),
      );
    }

    expect(await _count(database, 'lyrics_cache'), 3);
    for (var index = 0; index < refs.length; index++) {
      final result = (await repository.getLyrics(refs[index]))!;
      expect(result.track, refs[index]);
      expect(result.lines.single.text, 'Lyrics $index');
    }
  });

  test('rejects malformed cached JSON without leaking lyric content', () async {
    final track = _ref('private-track');
    await repository.saveLyrics(
      _document(
        track: track,
        lines: [LyricsLine(text: 'Initial')],
      ),
    );
    final cases = <({String json, String kind, String? translationLanguage})>[
      (json: '{}', kind: 'plain', translationLanguage: null),
      (json: '[]', kind: 'plain', translationLanguage: null),
      (
        json: '[{"startMs":null,"endMs":null,"text":"secret-lyric","translation":null,"extra":1}]',
        kind: 'plain',
        translationLanguage: null,
      ),
      (
        json: '[{"startMs":null,"endMs":null,"text":42,"translation":null}]',
        kind: 'plain',
        translationLanguage: null,
      ),
      (
        json: '[{"startMs":10,"endMs":20,"text":"secret-lyric","translation":null}]',
        kind: 'plain',
        translationLanguage: null,
      ),
      (
        json: '[{"startMs":null,"endMs":null,"text":"secret-lyric","translation":"private-translation"}]',
        kind: 'plain',
        translationLanguage: null,
      ),
    ];

    for (final corrupt in cases) {
      await database.customStatement(
        'UPDATE lyrics_cache SET lines_json = ?, kind = ?, translation_language = ?',
        [corrupt.json, corrupt.kind, corrupt.translationLanguage],
      );
      Object? failure;
      try {
        await repository.getLyrics(track);
      } catch (error) {
        failure = error;
      }
      expect(failure, _failureWith(DomainFailureCode.databaseCorrupted));
      expect(failure.toString(), isNot(contains('secret-lyric')));
      expect(failure.toString(), isNot(contains('private-translation')));
      expect(failure.toString(), isNot(contains('private-track')));
    }

    await database.customStatement(
      'UPDATE lyrics_cache SET lines_json = ?, kind = ?, '
      'translation_language = NULL, updated_at_ms = ?',
      [
        '[{"startMs":null,"endMs":null,"text":"valid","translation":null}]',
        'plain',
        9223372036854775807,
      ],
    );
    await expectLater(
      repository.getLyrics(track),
      throwsA(_failureWith(DomainFailureCode.databaseCorrupted)),
    );

    await database.customStatement(
      'UPDATE lyrics_cache SET updated_at_ms = ?, offset_ms = ?',
      [_epoch.millisecondsSinceEpoch, 9223372036854775807],
    );
    await expectLater(
      repository.getLyrics(track),
      throwsA(_failureWith(DomainFailureCode.databaseCorrupted)),
    );
  });

  test('redacts SQLite failures', () async {
    final track = _ref('sensitive-track');
    await database.customStatement('DROP TABLE lyrics_cache');
    Object? failure;
    try {
      await repository.getLyrics(track);
    } catch (error) {
      failure = error;
    }
    expect(failure, _failureWith(DomainFailureCode.databaseCorrupted));
    expect(failure.toString(), isNot(contains('sensitive-track')));
    expect(failure.toString(), isNot(contains('SELECT')));
  });

  test('supports shared and owned database disposal', () async {
    await repository.dispose();
    await repository.dispose();
    expect(() => repository.getLyrics(_ref('track')), throwsStateError);
    expect(await _count(database, 'lyrics_cache'), 0);

    final ownedRepository = DriftLyricsRepository.owned(database);
    await ownedRepository.saveLyrics(
      _document(
        track: _ref('owned'),
        lines: [LyricsLine(text: 'Owned')],
      ),
    );
    await ownedRepository.dispose();
    await ownedRepository.dispose();
    expect(() => ownedRepository.getLyrics(_ref('owned')), throwsStateError);
    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(anything),
    );
  });
}

final DateTime _epoch = DateTime.utc(2026, 9, 1, 8);

TrackRef _ref(
  String trackId, {
  String sourceId = 'source',
  MusicSourceType type = MusicSourceType.rest,
}) => TrackRef(trackId: trackId, sourceId: sourceId, sourceType: type);

LyricsDocument _document({
  required TrackRef track,
  required Iterable<LyricsLine> lines,
}) => LyricsDocument(
  track: track,
  kind: LyricsKind.plain,
  lines: lines,
  language: 'en',
);

Future<int> _count(AppDatabase database, String table) async =>
    (await database
            .customSelect('SELECT COUNT(*) AS count FROM $table')
            .getSingle())
        .read<int>('count');

Matcher _failureWith(DomainFailureCode code) =>
    isA<DomainFailure>().having((failure) => failure.code, 'code', code);
