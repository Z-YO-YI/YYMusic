import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/playback_continuation_codec.dart';
import 'package:yymusic/data/repositories/drift_playback_continuation_repository.dart';
import 'package:yymusic/domain/models/domain_failure.dart';

import '../support/search_query_probe.dart';

void main() {
  test(
    'dispose waits for blocked accepted write and queued replacement',
    () async {
      final probe = SearchQueryProbe();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
      final repo = DriftPlaybackContinuationRepository(db);
      await repo.read();
      final gate = Completer<void>(), entered = Completer<void>();
      probe.beforeInsert = () async {
        if (!entered.isCompleted) entered.complete();
        await gate.future;
      };
      final first = repo.save(false);
      await entered.future;
      final second = repo.save(true);
      var closed = false;
      final closing = repo.dispose().then((_) => closed = true);
      try {
        await Future<void>.delayed(Duration.zero);
        expect(closed, isFalse);
        expect(() => repo.save(false), throwsStateError);
        gate.complete();
        await Future.wait([first, second, closing]);
        final row = await db.select(db.appSettingRecords).getSingle();
        expect(PlaybackContinuationCodec.decode(row.valueJson), isTrue);
      } finally {
        if (!gate.isCompleted) gate.complete();
        await repo.dispose();
        await db.close();
      }
    },
  );
  for (final enabled in [false, true]) {
    test('codec round trips $enabled', () {
      expect(
        PlaybackContinuationCodec.decode(
          PlaybackContinuationCodec.encode(enabled),
        ),
        enabled,
      );
    });
  }
  for (final (name, source) in [
    ('empty', ''),
    ('invalid json', 'private-record'),
    ('array', '[]'),
    ('null', 'null'),
    ('missing bool', '{"version":1}'),
    ('future version', '{"version":2,"continueAfterTrack":true}'),
    ('float version', '{"version":1.0,"continueAfterTrack":true}'),
    ('string bool', '{"version":1,"continueAfterTrack":"false"}'),
    ('number bool', '{"version":1,"continueAfterTrack":0}'),
    ('extra field', '{"version":1,"continueAfterTrack":true,"private":"data"}'),
    ('over limit', List.filled(129, 'x').join()),
  ]) {
    test('codec rejects $name without exposing input', () {
      expect(
        () => PlaybackContinuationCodec.decode(source),
        throwsA(
          isA<FormatException>()
              .having(
                (error) => error.message,
                'message',
                'Invalid stored playback continuation',
              )
              .having((error) => error.source, 'source', isNull),
        ),
      );
    });
  }

  group('SQLite adapter', () {
    late AppDatabase db;
    late DriftPlaybackContinuationRepository repository;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = DriftPlaybackContinuationRepository(db);
    });
    tearDown(() async {
      await repository.dispose();
      await db.close();
    });

    test('missing preference does not write a default', () async {
      expect(await repository.read(), isNull);
      expect(await db.select(db.appSettingRecords).get(), isEmpty);
    });

    test('accepted saves and reads preserve invocation order', () async {
      final first = repository.save(false);
      final readFirst = repository.read();
      final second = repository.save(true);
      final readSecond = repository.read();
      await Future.wait([first, second]);
      expect(await readFirst, isFalse);
      expect(await readSecond, isTrue);
      expect((await db.select(db.appSettingRecords).get()).length, 1);
    });

    test(
      'corrupt version remains intact and explicit save can recover',
      () async {
        const raw = '{"version":999,"continueAfterTrack":false}';
        await db
            .into(db.appSettingRecords)
            .insert(
              AppSettingRecordsCompanion.insert(
                settingKey: DriftPlaybackContinuationRepository.settingKey,
                valueJson: raw,
                updatedAtMs: 1,
              ),
            );
        await expectLater(
          repository.read(),
          throwsA(
            isA<DomainFailure>().having(
              (failure) => failure.code,
              'code',
              DomainFailureCode.schemaMismatch,
            ),
          ),
        );
        expect(
          (await db.select(db.appSettingRecords).getSingle()).valueJson,
          raw,
        );
        await repository.save(false);
        expect(await repository.read(), isFalse);
      },
    );

    test('saving leaves unrelated settings untouched', () async {
      await db
          .into(db.appSettingRecords)
          .insert(
            AppSettingRecordsCompanion.insert(
              settingKey: 'unrelated-setting',
              valueJson: 'keep',
              updatedAtMs: 7,
            ),
          );
      await repository.save(false);
      final rows = await db.select(db.appSettingRecords).get();
      expect(rows.length, 2);
      expect(
        rows
            .singleWhere((row) => row.settingKey == 'unrelated-setting')
            .valueJson,
        'keep',
      );
    });

    test(
      'dispose drains accepted save and leaves borrowed database open',
      () async {
        final saving = repository.save(false);
        final closing = repository.dispose();
        expect(() => repository.read(), throwsStateError);
        expect(() => repository.save(true), throwsStateError);
        await saving;
        await closing;
        await repository.dispose();
        final row = await db.select(db.appSettingRecords).getSingle();
        expect(PlaybackContinuationCodec.decode(row.valueJson), isFalse);
      },
    );

    test(
      'failed dependency is safe and does not poison the serial queue',
      () async {
        var broken = true;
        await repository.dispose();
        repository = DriftPlaybackContinuationRepository(
          db,
          clock: () {
            if (broken) throw StateError('private-storage-marker');
            return DateTime.utc(2026);
          },
        );
        await expectLater(
          repository.save(false),
          throwsA(
            isA<DomainFailure>()
                .having(
                  (failure) => failure.diagnosticId,
                  'diagnostic',
                  'playback-continuation.save',
                )
                .having(
                  (failure) => failure.code,
                  'code',
                  DomainFailureCode.databaseCorrupted,
                ),
          ),
        );
        broken = false;
        await repository.save(true);
        expect(await repository.read(), isTrue);
      },
    );
  });

  test(
    'false and true survive closing and reopening an actual SQLite file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'yymusic-continuation-',
      );
      try {
        final file = File(
          '${directory.path}${Platform.pathSeparator}settings.sqlite',
        );
        for (final (stored, next) in [
          (null, false),
          (false, true),
          (true, null),
        ]) {
          final db = AppDatabase(NativeDatabase(file));
          final repo = DriftPlaybackContinuationRepository(db);
          try {
            expect(await repo.read(), stored);
            if (next != null) await repo.save(next);
          } finally {
            await repo.dispose();
            await db.close();
          }
        }
      } finally {
        expect(
          directory.absolute.path.startsWith(
            '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}',
          ),
          isTrue,
        );
        await directory.delete(recursive: true);
      }
    },
  );
}
