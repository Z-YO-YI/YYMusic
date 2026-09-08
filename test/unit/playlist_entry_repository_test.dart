import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_collection_repository.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/collection_repository.dart';

import '../support/fake_domain_repositories.dart';
import 'playlist_controller_test.dart' show playlistEpoch, commandPlaylist;
import 'playlist_metadata_sqlite_test.dart' show playlistFailure;

PlaylistEntryDraft entryDraft(String id, {TrackRef? track}) =>
    PlaylistEntryDraft(
      id: id,
      track:
          track ??
          TrackRef(
            sourceType: MusicSourceType.rest,
            sourceId: 'removed-source',
            trackId: 'same-id',
          ),
      addedAt: playlistEpoch,
    );

Future<void> seedEntries(
  CollectionRepository repository,
  String playlistId,
  Iterable<String> ids,
) async {
  await repository.createPlaylist(commandPlaylist(playlistId));
  for (final id in ids) {
    await repository.appendPlaylistEntry(playlistId, entryDraft(id));
  }
}

Future<void> expectEntryOrder(
  CollectionRepository repository,
  String playlistId,
  List<String> ids,
) async {
  final entries = await repository.getPlaylistEntries(playlistId);
  expect(entries.map((e) => e.id), ids);
  expect(entries.map((e) => e.position), List.generate(ids.length, (i) => i));
  expect(
    entries.every(
      (e) => e.playlistId == playlistId && e.addedAt == playlistEpoch,
    ),
    isTrue,
  );
}

void main() {
  test('entry drafts validate independent identity and UTC without requiring a position or a track row', () {
    final draft = entryDraft('entry');
    expect(draft.track.sourceId, 'removed-source');
    for (final id in ['', ' bad ', 'bad\n', List.filled(257, 'a').join()]) {
      expect(() => entryDraft(id), throwsArgumentError);
    }
    expect(entryDraft(List.filled(256, 'a').join()).id.length, 256);
    expect(
      () => PlaylistEntryDraft(
        id: 'id',
        track: draft.track,
        addedAt: DateTime(2026),
      ),
      throwsArgumentError,
    );
  });

  for (final sqlite in [true, false]) {
    group(sqlite ? 'SQLite entry contract' : 'Fake entry contract', () {
      late CollectionRepository repository;
      late DateTime now;
      setUp(() {
        now = playlistEpoch;
        if (sqlite) {
          final database = AppDatabase(NativeDatabase.memory());
          final storage = DriftCollectionRepository(database, clock: () => now);
          repository = storage;
          addTearDown(() async {
            await storage.dispose();
            await database.close();
          });
        } else {
          final storage = FakeCollectionRepository(clock: () => now);
          repository = storage;
          addTearDown(storage.dispose);
        }
      });

      test('concurrent appends preserve duplicates and full local/online identities without resolving missing sources', () async {
        await repository.createPlaylist(commandPlaylist('p'));
        final refs = [
          entryDraft('unused').track,
          TrackRef(
            sourceType: MusicSourceType.local,
            sourceId: 'removed-source',
            trackId: 'same-id',
          ),
          TrackRef(
            sourceType: MusicSourceType.rest,
            sourceId: 'another-source',
            trackId: 'same-id',
          ),
        ];
        await Future.wait([
          for (var i = 0; i < 20; i++)
            repository.appendPlaylistEntry(
              'p',
              entryDraft('entry-$i', track: refs[i % 3]),
            ),
        ]);
        final entries = await repository.getPlaylistEntries('p');
        expect(entries.length, 20);
        expect(entries.map((e) => e.position), List.generate(20, (i) => i));
        expect(entries.map((e) => e.id).toSet().length, 20);
        for (var i = 0; i < 20; i++) {
          expect(
            entries.singleWhere((e) => e.id == 'entry-$i').track,
            refs[i % 3],
          );
        }
      });

      test('global ID collision rejects instead of overwriting, including concurrent attempts across playlists', () async {
        await repository.createPlaylist(commandPlaylist('a'));
        await repository.createPlaylist(commandPlaylist('b'));
        Future<bool> append(String id) async {
          try {
            await repository.appendPlaylistEntry(id, entryDraft('shared'));
            return true;
          } on DomainFailure catch (failure) {
            expect(failure.code, DomainFailureCode.forbidden);
            return false;
          }
        }

        final outcomes = await Future.wait([append('a'), append('b')]);
        expect(outcomes.where((ok) => ok).length, 1);
        final winner = outcomes.first ? 'a' : 'b';
        now = now.add(const Duration(hours: 1));
        await expectLater(
          repository.appendPlaylistEntry(winner, entryDraft('shared')),
          throwsA(playlistFailure(DomainFailureCode.forbidden)),
        );
        await expectEntryOrder(repository, winner, ['shared']);
        expect(
          (await repository.getPlaylist(winner))!.updatedAt,
          playlistEpoch,
        );
        await expectEntryOrder(repository, outcomes.first ? 'b' : 'a', []);
      });

      test('all system kinds reject append remove and move including no-op requests', () async {
        for (final type in SystemPlaylistType.values) {
          final p = Playlist(
            id: type.name,
            name: '系统歌单',
            createdAt: playlistEpoch,
            updatedAt: playlistEpoch,
            isSystem: true,
            systemType: type,
          );
          await repository.savePlaylist(p);
          await repository.replacePlaylistEntries(p.id, [
            PlaylistEntry(
              id: 'system-${type.name}',
              playlistId: p.id,
              track: entryDraft('x').track,
              position: 0,
              addedAt: playlistEpoch,
            ),
          ]);
          for (final command in <Future<void> Function()>[
            () => repository.appendPlaylistEntry(p.id, entryDraft('new')),
            () => repository.removePlaylistEntry(p.id, 'missing'),
            () => repository.removePlaylistEntry(p.id, 'system-${type.name}'),
            () => repository.movePlaylistEntry(
              p.id,
              'system-${type.name}',
              beforeEntryId: 'system-${type.name}',
            ),
          ]) {
            await expectLater(
              command(),
              throwsA(playlistFailure(DomainFailureCode.forbidden)),
            );
          }
          await expectEntryOrder(repository, p.id, ['system-${type.name}']);
          expect(
            (await repository.getPlaylist(p.id))!.updatedAt,
            playlistEpoch,
          );
        }
      });

      test('missing playlist or move target/anchor and wrong-playlist IDs fail without partial writes', () async {
        await seedEntries(repository, 'a', ['one', 'two']);
        await seedEntries(repository, 'b', ['foreign']);
        for (final command in <Future<void> Function()>[
          () => repository.appendPlaylistEntry('missing', entryDraft('new')),
          () => repository.removePlaylistEntry('missing', 'one'),
          () => repository.movePlaylistEntry('missing', 'one'),
          () => repository.movePlaylistEntry('a', 'missing'),
          () => repository.movePlaylistEntry(
            'a',
            'missing',
            beforeEntryId: 'missing',
          ),
          () => repository.movePlaylistEntry(
            'a',
            'one',
            beforeEntryId: 'missing',
          ),
          () => repository.movePlaylistEntry('a', 'foreign'),
          () => repository.movePlaylistEntry(
            'a',
            'one',
            beforeEntryId: 'foreign',
          ),
          () => repository.removePlaylistEntry('a', 'foreign'),
        ]) {
          await expectLater(
            command(),
            throwsA(playlistFailure(DomainFailureCode.notFound)),
          );
        }
        await expectEntryOrder(repository, 'a', ['one', 'two']);
        await expectEntryOrder(repository, 'b', ['foreign']);
        expect(await repository.getPlaylist('missing'), isNull);
      });

      test('invalid IDs never mutate existing entries', () async {
        await seedEntries(repository, 'p', ['one', 'two']);
        for (final command in <Future<void> Function()>[
          () => repository.appendPlaylistEntry(' p ', entryDraft('new')),
          () => repository.removePlaylistEntry('p', ''),
          () => repository.removePlaylistEntry('missing', ''),
          () =>
              repository.movePlaylistEntry('missing', 'a', beforeEntryId: '\n'),
          () => repository.movePlaylistEntry('p', 'one', beforeEntryId: '\n'),
        ]) {
          await expectLater(Future.sync(command), throwsArgumentError);
        }
        await expectEntryOrder(repository, 'p', ['one', 'two']);
      });

      test('moving in both directions and removing first middle last retain metadata and contiguous positions', () async {
        await seedEntries(repository, 'p', ['a', 'b', 'c', 'd']);
        await seedEntries(repository, 'other', ['kept']);
        await repository.movePlaylistEntry('p', 'd', beforeEntryId: 'a');
        await expectEntryOrder(repository, 'p', ['d', 'a', 'b', 'c']);
        await repository.movePlaylistEntry('p', 'd', beforeEntryId: 'c');
        await expectEntryOrder(repository, 'p', ['a', 'b', 'd', 'c']);
        await repository.movePlaylistEntry('p', 'a');
        await expectEntryOrder(repository, 'p', ['b', 'd', 'c', 'a']);
        await repository.removePlaylistEntry('p', 'd');
        await expectEntryOrder(repository, 'p', ['b', 'c', 'a']);
        await repository.removePlaylistEntry('p', 'b');
        await repository.removePlaylistEntry('p', 'a');
        await expectEntryOrder(repository, 'p', ['c']);
        await repository.removePlaylistEntry('p', 'c');
        await expectEntryOrder(repository, 'p', []);
        await repository.appendPlaylistEntry('p', entryDraft('new'));
        await expectEntryOrder(repository, 'p', ['new']);
        await expectEntryOrder(repository, 'other', ['kept']);
        final stored = (await repository.getPlaylist('p'))!;
        expect(stored.name, commandPlaylist('p').name);
        expect(stored.description, commandPlaylist('p').description);
        expect(stored.createdAt, playlistEpoch);
      });

      test('no-op operations keep timestamps and real changes advance monotonically despite clock rollback', () async {
        await seedEntries(repository, 'p', ['a', 'b', 'c']);
        now = playlistEpoch.add(const Duration(hours: 1));
        await repository.removePlaylistEntry('p', 'absent');
        await repository.movePlaylistEntry('p', 'a', beforeEntryId: 'a');
        await repository.movePlaylistEntry('p', 'a', beforeEntryId: 'b');
        await repository.movePlaylistEntry('p', 'c');
        expect((await repository.getPlaylist('p'))!.updatedAt, playlistEpoch);
        await repository.movePlaylistEntry('p', 'c', beforeEntryId: 'a');
        expect((await repository.getPlaylist('p'))!.updatedAt, now);
        final latest = now;
        now = now.subtract(const Duration(days: 1));
        await repository.removePlaylistEntry('p', 'b');
        await repository.appendPlaylistEntry('p', entryDraft('d'));
        expect((await repository.getPlaylist('p'))!.updatedAt, latest);
        await expectEntryOrder(repository, 'p', ['c', 'a', 'd']);
      });

      test('quoted identities stay bound and mixed track refs and per-entry timestamps survive reordering', () async {
        const id = "歌单'--";
        await repository.createPlaylist(commandPlaylist(id));
        final drafts = [
          entryDraft("a'--"),
          PlaylistEntryDraft(
            id: "b'--",
            track: TrackRef(
              sourceType: MusicSourceType.local,
              sourceId: "源'--",
              trackId: 'same-id',
            ),
            addedAt: playlistEpoch.add(const Duration(minutes: 1)),
          ),
          PlaylistEntryDraft(
            id: "c'--",
            track: TrackRef(
              sourceType: MusicSourceType.rest,
              sourceId: "其他源'--",
              trackId: 'same-id',
            ),
            addedAt: playlistEpoch.add(const Duration(minutes: 2)),
          ),
        ];
        for (final draft in drafts) {
          await repository.appendPlaylistEntry(id, draft);
        }
        await repository.movePlaylistEntry(
          id,
          drafts.last.id,
          beforeEntryId: drafts.first.id,
        );
        await repository.removePlaylistEntry(id, drafts[1].id);
        final stored = await repository.getPlaylistEntries(id);
        expect(stored.map((e) => e.id), [drafts.last.id, drafts.first.id]);
        expect(stored.map((e) => e.position), [0, 1]);
        for (final entry in stored) {
          final original = drafts.singleWhere((d) => d.id == entry.id);
          expect(entry.track, original.track);
          expect(entry.addedAt, original.addedAt);
          expect(entry.playlistId, id);
        }
      });

      test('concurrent append remove and anchor move do not replace one another with stale snapshots', () async {
        await seedEntries(repository, 'p', ['a', 'b', 'c']);
        await Future.wait([
          repository.appendPlaylistEntry('p', entryDraft('new')),
          repository.removePlaylistEntry('p', 'b'),
          repository.movePlaylistEntry('p', 'c', beforeEntryId: 'a'),
        ]);
        await expectEntryOrder(repository, 'p', ['c', 'a', 'new']);
      });

      test('deterministic mixed command sequence matches identity-based list oracle', () async {
        await seedEntries(repository, 'p', ['a', 'b', 'c', 'd']);
        final expected = ['a', 'b', 'c', 'd'];
        final random = Random(60593);
        for (var step = 0; step < 120; step++) {
          final op = expected.isEmpty ? 0 : random.nextInt(3);
          if (op == 0) {
            final id = 'new-$step';
            await repository.appendPlaylistEntry('p', entryDraft(id));
            expected.add(id);
          } else if (op == 1) {
            final id = expected.removeAt(random.nextInt(expected.length));
            await repository.removePlaylistEntry('p', id);
          } else {
            final id = expected[random.nextInt(expected.length)];
            final anchor = random.nextBool()
                ? null
                : expected[random.nextInt(expected.length)];
            await repository.movePlaylistEntry('p', id, beforeEntryId: anchor);
            if (anchor != id) {
              expected.remove(id);
              expected.insert(
                anchor == null ? expected.length : expected.indexOf(anchor),
                id,
              );
            }
          }
          await expectEntryOrder(repository, 'p', expected);
        }
      });
    });
  }
}
