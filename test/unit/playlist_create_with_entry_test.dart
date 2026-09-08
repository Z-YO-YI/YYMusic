import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_collection_repository.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/collection_repository.dart';

import '../support/fake_domain_repositories.dart';
import '../support/playlist_content_probe.dart';
import '../support/search_query_probe.dart';
import 'playlist_controller_test.dart' show commandPlaylist, playlistEpoch;
import 'playlist_metadata_sqlite_test.dart' show playlistFailure;

PlaylistEntryDraft firstDraft(String id, {String source = 'missing-source'}) =>
    PlaylistEntryDraft(
      id: id,
      track: TrackRef(
        sourceType: MusicSourceType.rest,
        sourceId: source,
        trackId: 'same/%?歌曲',
      ),
      addedAt: playlistEpoch,
    );

void main() {
  test(
    'root close waits for the real SQLite transaction after parent insertion',
    () async {
      final probe = SearchQueryProbe();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
      final services = await DatabaseAppDataServices.open(db);
      final graph = DependencyGraph(dataServices: services);
      addTearDown(graph.close);
      await graph.initialize();
      await contentTick();
      final gate = Completer<void>(), entered = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      var inserts = 0;
      final beforeTransactions = probe.transactionCount;
      probe.beforeInsert = () async {
        if (++inserts == 2) {
          entered.complete();
          await gate.future;
        }
      };
      final picker = graph.playlistAdds.open(
        firstDraft('unused').track,
        title: '歌曲',
      );
      final writing = picker.createAndAdd('写入中关闭');
      await entered.future.timeout(const Duration(seconds: 5));
      final closing = graph.close();
      await contentTick();
      expect(probe.closeCount, 0);
      expect(graph.playlistAdds.retainedSessionCount, 1);
      expect(probe.transactionCount - beforeTransactions, 1);
      gate.complete();
      await writing;
      await closing;
      expect(inserts, 2);
      expect(probe.closeCount, 1);
      expect(graph.playlistAdds.retainedSessionCount, 0);
    },
  );
  for (final sqlite in [true, false]) {
    group(sqlite ? 'SQLite create with entry' : 'Fake create with entry', () {
      late CollectionRepository repository;
      setUp(() {
        if (sqlite) {
          final db = AppDatabase(NativeDatabase.memory());
          final r = DriftCollectionRepository(db);
          repository = r;
          addTearDown(() async {
            await r.dispose();
            await db.close();
          });
        } else {
          final r = FakeCollectionRepository();
          repository = r;
          addTearDown(r.dispose);
        }
      });
      test(
        'preserves full soft reference and metadata without requiring a track',
        () async {
          final parent = Playlist(
            id: 'p/%?中',
            name: '  夜间聆听  ',
            description: '保持说明',
            createdAt: playlistEpoch,
            updatedAt: playlistEpoch.add(const Duration(hours: 1)),
          );
          final draft = firstDraft('entry/%?中');
          await repository.createPlaylistWithEntry(parent, draft);
          final saved = (await repository.getPlaylist(parent.id))!;
          expect(saved.name, '夜间聆听');
          expect(saved.description, parent.description);
          expect(saved.createdAt, parent.createdAt);
          expect(saved.updatedAt, parent.updatedAt);
          final entry = (await repository.getPlaylistEntries(parent.id)).single;
          expect(entry.id, draft.id);
          expect(entry.playlistId, parent.id);
          expect(entry.position, 0);
          expect(entry.track, draft.track);
          expect(entry.addedAt, draft.addedAt);
        },
      );
      test('parent identity collision cannot overwrite or append to an existing playlist', () async {
        await repository.createPlaylistWithEntry(
          commandPlaylist('p'),
          firstDraft('old'),
        );
        await expectLater(
          repository.createPlaylistWithEntry(
            commandPlaylist('p'),
            firstDraft('new'),
          ),
          throwsA(playlistFailure(DomainFailureCode.forbidden)),
        );
        expect((await repository.getPlaylistEntries('p')).single.id, 'old');
        expect((await repository.getPlaylist('p'))!.name, '原名称');
      });
      test('global entry collision leaves no new parent and preserves the foreign playlist', () async {
        await repository.createPlaylistWithEntry(
          commandPlaylist('old'),
          firstDraft('collision'),
        );
        await expectLater(
          repository.createPlaylistWithEntry(
            commandPlaylist('new'),
            firstDraft('collision'),
          ),
          throwsA(playlistFailure(DomainFailureCode.forbidden)),
        );
        expect(await repository.getPlaylist('new'), isNull);
        expect(await repository.getPlaylistEntries('new'), isEmpty);
        expect(
          (await repository.getPlaylistEntries('old')).single.id,
          'collision',
        );
      });
      test('system and unsafe names cannot create either row', () async {
        await expectLater(
          repository.createPlaylistWithEntry(
            commandPlaylist('system', system: true),
            firstDraft('e'),
          ),
          throwsA(playlistFailure(DomainFailureCode.forbidden)),
        );
        final bad = Playlist(
          id: 'bad',
          name: 'bad\nname',
          createdAt: playlistEpoch,
          updatedAt: playlistEpoch,
        );
        await expectLater(
          () => repository.createPlaylistWithEntry(bad, firstDraft('e')),
          throwsArgumentError,
        );
        expect(await repository.getPlaylist('system'), isNull);
        expect(await repository.getPlaylist('bad'), isNull);
        expect(await repository.getPlaylistEntries('system'), isEmpty);
      });
      test('same names and repeated full references remain independently addressable', () async {
        await Future.wait([
          repository.createPlaylistWithEntry(
            commandPlaylist('a'),
            firstDraft('a'),
          ),
          repository.createPlaylistWithEntry(
            commandPlaylist('b'),
            firstDraft('b'),
          ),
        ]);
        final a = (await repository.getPlaylistEntries('a')).single;
        final b = (await repository.getPlaylistEntries('b')).single;
        expect(a.id, isNot(b.id));
        expect(a.track, b.track);
        await repository.createPlaylistWithEntry(
          commandPlaylist('other'),
          firstDraft('other', source: 'other-source'),
        );
        expect(
          (await repository.getPlaylistEntries('other')).single.track,
          isNot(a.track),
        );
      });
      test('watchers see a fully populated new playlist, not a half-created parent', () async {
        final observed = Completer<int>();
        final ready = Completer<void>();
        final sub = repository.watchPlaylists().listen((items) async {
          if (!ready.isCompleted) ready.complete();
          if (items.any((p) => p.id == 'new') && !observed.isCompleted) {
            observed.complete(
              (await repository.getPlaylistEntries('new')).length,
            );
          }
        });
        addTearDown(sub.cancel);
        await ready.future.timeout(const Duration(seconds: 5));
        await repository.createPlaylistWithEntry(
          commandPlaylist('new'),
          firstDraft('e'),
        );
        expect(await observed.future.timeout(const Duration(seconds: 5)), 1);
      });
      test('concurrent same-parent commands have one success and preserve one first entry', () async {
        final results = await Future.wait([
          for (final id in ['a', 'b'])
            repository
                .createPlaylistWithEntry(
                  commandPlaylist('same'),
                  firstDraft(id),
                )
                .then((_) => true)
                .catchError((Object _) => false),
        ]);
        expect(results.where((r) => r).length, 1);
        expect((await repository.getPlaylistEntries('same')).length, 1);
      });
    });
  }
  for (final stage in ['parent', 'entry', 'after-entry']) {
    test('SQLite $stage failure rolls back both rows and permits a clean retry', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final r = DriftCollectionRepository(db);
      addTearDown(() async {
        await r.dispose();
        await db.close();
      });
      await r.createPlaylistWithEntry(
        commandPlaylist('existing'),
        firstDraft('existing'),
      );
      final trigger = switch (stage) {
        'parent' => 'BEFORE INSERT ON playlists',
        'entry' => 'BEFORE INSERT ON playlist_entries',
        _ => 'AFTER INSERT ON playlist_entries',
      };
      await db.customStatement(
        "CREATE TRIGGER fail_create $trigger BEGIN SELECT RAISE(ABORT, 'private-marker'); END",
      );
      await expectLater(
        r.createPlaylistWithEntry(commandPlaylist('new'), firstDraft('new')),
        throwsA(playlistFailure(DomainFailureCode.databaseCorrupted)),
      );
      expect(await r.getPlaylist('new'), isNull);
      expect(await r.getPlaylistEntries('new'), isEmpty);
      expect((await r.getPlaylistEntries('existing')).single.id, 'existing');
      await db.customStatement('DROP TRIGGER fail_create');
      await r.createPlaylistWithEntry(
        commandPlaylist('new'),
        firstDraft('new'),
      );
      expect((await r.getPlaylistEntries('new')).single.position, 0);
    });
  }
}
