import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_collection_repository.dart';
import 'package:yymusic/data/repositories/drift_library_repository.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/catalog_detail_probe.dart' show detailTrack;
import '../support/fake_audio_engine.dart';
import '../support/playlist_content_probe.dart';
import '../support/search_query_probe.dart';
import 'playlist_controller_test.dart' show commandPlaylist;
import 'playlist_metadata_sqlite_test.dart' show playlistFailure;

void main() {
  late AppDatabase database;
  late DriftCollectionRepository collection;
  late DriftLibraryRepository library;
  late SearchQueryProbe probe;
  late DatabaseAppDataServices services;
  setUp(() async {
    probe = SearchQueryProbe();
    database = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    services = await DatabaseAppDataServices.open(database);
    collection = DriftCollectionRepository(database, clock: () => contentEpoch);
    library = services.library as DriftLibraryRepository;
  });
  tearDown(() async {
    await collection.dispose();
    await services.dispose();
  });

  Future<void> seed(
    List<Track> tracks, {
    String id = 'p',
    bool catalog = true,
  }) async {
    await collection.createPlaylist(contentPlaylist(id));
    if (catalog) await library.upsertTracks(tracks);
    await collection.replacePlaylistEntries(id, [
      for (var i = 0; i < tracks.length; i++)
        contentItem(id, '$id-entry-$i', i, tracks[i]).entry,
    ]);
  }

  test('one bound SQL distinguishes missing empty and beyond-end windows without writes', () async {
    await collection.createPlaylist(contentPlaylist("歌单'--"));
    probe.selects.clear();
    final transactions = probe.transactionCount;
    expect(
      await collection.readPlaylistContent('missing', PageRequest()),
      isNull,
    );
    final empty = (await collection.readPlaylistContent(
      "歌单'--",
      PageRequest(offset: 9, limit: 2),
    ))!;
    expect(empty.playlist.name, '测试歌单');
    expect(empty.totalCount, 0);
    expect(empty.entries, isEmpty);
    expect(empty.hasMore, isFalse);
    expect(probe.selects.length, 2);
    expect(probe.selects.last.args, ["歌单'--", 2, 9]);
    expect(probe.selects.last.sql, isNot(contains("歌单'--")));
    expect(probe.transactionCount, transactions);
  });

  test('window is limited before artist fan-out and groups entries rather than deduplicating tracks', () async {
    final track = Track(
      id: 't',
      sourceId: 's',
      sourceType: MusicSourceType.rest,
      title: '多人歌曲',
      artists: ['第一艺人', '第二艺人'],
      duration: const Duration(minutes: 3),
    );
    await collection.createPlaylist(contentPlaylist('p'));
    await library.upsertTracks([track]);
    await collection.replacePlaylistEntries('p', [
      for (var i = 0; i < 1000; i++)
        contentItem('p', 'entry-$i', i, track).entry,
    ]);
    probe.selects.clear();
    final window = (await collection.readPlaylistContent(
      'p',
      PageRequest(offset: 980, limit: 7),
    ))!;
    expect(window.totalCount, 1000);
    expect(
      window.entries.map((e) => e.entry.id),
      List.generate(7, (i) => 'entry-${980 + i}'),
    );
    expect(
      window.entries.every((e) => e.track!.artists.join(',') == '第一艺人,第二艺人'),
      isTrue,
    );
    expect(window.entries.map((e) => e.entry.track).toSet().length, 1);
    expect(window.hasMore, isTrue);
    expect(probe.selects.single.rows, 14);
    expect(probe.selects.single.args, ['p', 7, 980]);
    probe.selects.clear();
    final last = (await collection.readPlaylistContent(
      'p',
      PageRequest(offset: 998, limit: 7),
    ))!;
    expect(last.entries.length, 2);
    expect(last.hasMore, isFalse);
    expect(probe.selects.single.rows, 4);
  });

  test('complete source identities preserve duplicates missing tracks and all availability states', () async {
    final tracks = [
      detailTrack('same', source: 'source-a'),
      detailTrack('same', source: 'source-a', type: MusicSourceType.rest),
      detailTrack('same', source: 'source-b', type: MusicSourceType.rest),
      for (final state in TrackAvailability.values)
        detailTrack(state.name, availability: state),
    ];
    await seed(tracks);
    await collection.appendPlaylistEntry(
      'p',
      PlaylistEntryDraft(
        id: 'unresolved',
        track: detailTrack('missing').ref,
        addedAt: contentEpoch,
      ),
    );
    final result = (await collection.readPlaylistContent('p', PageRequest()))!;
    expect(result.totalCount, tracks.length + 1);
    for (var i = 0; i < tracks.length; i++) {
      expect(result.entries[i].track!.ref, tracks[i].ref);
      expect(result.entries[i].track!.availability, tracks[i].availability);
      expect(
        result.entries[i].isAvailable,
        tracks[i].availability == TrackAvailability.available,
      );
    }
    expect(result.entries.last.entry.id, 'unresolved');
    expect(result.entries.last.track, isNull);
    expect(result.entries.last.isAvailable, isFalse);
  });

  test('single statement returns a coherent old snapshot when a write occurs after SQL execution', () async {
    await seed([detailTrack('old')]);
    probe.selects.clear();
    probe.afterSelect = () async {
      probe.afterSelect = null;
      await collection.renamePlaylist('p', '新的名称');
      await collection.appendPlaylistEntry(
        'p',
        PlaylistEntryDraft(
          id: 'new',
          track: detailTrack('new').ref,
          addedAt: contentEpoch,
        ),
      );
    };
    final old = (await collection.readPlaylistContent('p', PageRequest()))!;
    expect(old.playlist.name, '测试歌单');
    expect(old.totalCount, 1);
    expect(old.entries.length, 1);
    final current = (await collection.readPlaylistContent('p', PageRequest()))!;
    expect(current.playlist.name, '新的名称');
    expect(current.totalCount, 2);
    expect(current.entries.length, 2);
  });

  test('malformed tracks outside the selected window are not decoded or silently substituted', () async {
    await seed([detailTrack('a'), detailTrack('b')]);
    await database.customStatement(
      "UPDATE tracks SET metadata_json = 'private-marker' WHERE track_id = 'b'",
    );
    expect(
      (await collection.readPlaylistContent(
        'p',
        PageRequest(limit: 1),
      ))!.entries.single.track!.id,
      'a',
    );
    await expectLater(
      collection.readPlaylistContent('p', PageRequest(offset: 1, limit: 1)),
      throwsA(playlistFailure(DomainFailureCode.databaseCorrupted)),
    );
    expect((await collection.getPlaylistEntries('p')).length, 2);
  });

  test('noncontiguous stored positions fail closed even if the gap is outside the window', () async {
    await seed([detailTrack('a'), detailTrack('b')]);
    await database.customStatement(
      "UPDATE playlist_entries SET position = 9 WHERE entry_id = 'p-entry-1'",
    );
    await expectLater(
      collection.readPlaylistContent('p', PageRequest(limit: 1)),
      throwsA(playlistFailure(DomainFailureCode.databaseCorrupted)),
    );
  });

  test('system playlists are not misrepresented as empty persisted content and bad IDs fail before SQL', () async {
    await collection.savePlaylist(commandPlaylist('system', system: true));
    await expectLater(
      collection.readPlaylistContent('system', PageRequest()),
      throwsA(playlistFailure(DomainFailureCode.forbidden)),
    );
    probe.selects.clear();
    expect(
      () => collection.readPlaylistContent(' bad ', PageRequest()),
      throwsArgumentError,
    );
    expect(probe.selects, isEmpty);
    await collection.dispose();
    expect(
      () => collection.readPlaylistContent('p', PageRequest()),
      throwsStateError,
    );
    expect(collection.watchPlaylistContentChanges, throwsStateError);
  });

  test('query-free invalidation excludes unrelated favorites and rollback notifications expose only stored data', () async {
    await seed([detailTrack('a'), detailTrack('b')]);
    probe.selects.clear();
    var notifications = 0;
    final observed = <List<String>>[];
    final reads = <Future<void>>[];
    final subscription = collection.watchPlaylistContentChanges().listen((_) {
      notifications++;
      reads.add(
        collection.readPlaylistContent('p', PageRequest()).then((value) {
          observed.add(value!.entries.map((e) => e.entry.id).toList());
        }),
      );
    });
    addTearDown(subscription.cancel);
    await contentTick();
    expect(notifications, 0);
    expect(probe.selects, isEmpty);
    await collection.setFavorite(detailTrack('a').ref, favorite: true);
    await contentTick();
    expect(notifications, 0);
    await expectLater(
      database.transaction(() async {
        await collection.movePlaylistEntry(
          'p',
          'p-entry-1',
          beforeEntryId: 'p-entry-0',
        );
        throw StateError('test rollback');
      }),
      throwsStateError,
    );
    await contentTick();
    await Future.wait(reads);
    for (final order in observed) {
      expect(order, ['p-entry-0', 'p-entry-1']);
    }
    expect(
      (await collection.readPlaylistContent(
        'p',
        PageRequest(),
      ))!.entries.map((e) => e.entry.id),
      ['p-entry-0', 'p-entry-1'],
    );
    final afterRollback = notifications;
    await collection.movePlaylistEntry(
      'p',
      'p-entry-1',
      beforeEntryId: 'p-entry-0',
    );
    await contentTick();
    await Future.wait(reads);
    expect(notifications, greaterThan(afterRollback));
    expect(observed.last, ['p-entry-1', 'p-entry-0']);
    final afterCommit = notifications;
    expect((await collection.getPlaylist('p'))!.updatedAt, contentEpoch);
    await collection.removePlaylistEntry('p', 'absent');
    await contentTick();
    expect(notifications, afterCommit);
  });

  test('root content reacts to same-time entry writes metadata catalog availability removal restoration and parent deletion', () async {
    final track = detailTrack('a');
    await seed([track, detailTrack('b')]);
    final engine = FakeAudioEngine();
    final graph = DependencyGraph(collection: collection, audioEngine: engine);
    addTearDown(graph.close);
    final session = graph.playlistContents.open('p');
    session.start();
    await waitForContent(session, () => session.phase == LoadPhase.data);
    await graph.playlists.moveEntry(
      'p',
      'p-entry-1',
      beforeEntryId: 'p-entry-0',
    );
    await waitForContent(
      session,
      () =>
          session.isCurrent &&
          session.content!.entries.first.entry.id == 'p-entry-1',
    );
    await graph.playlists.renamePlaylist('p', '即时名称');
    await waitForContent(
      session,
      () => session.isCurrent && session.content!.playlist.name == '即时名称',
    );
    await library.setAvailability(track.ref, TrackAvailability.localMissing);
    await waitForContent(
      session,
      () =>
          session.isCurrent &&
          session.content!.entries.last.track?.availability ==
              TrackAvailability.localMissing,
    );
    await (database.delete(
      database.trackRecords,
    )..where((t) => t.trackId.equals('a'))).go();
    await waitForContent(
      session,
      () => session.isCurrent && session.content!.entries.last.track == null,
    );
    expect(session.content!.totalCount, 2);
    await library.upsertTracks([track]);
    await waitForContent(
      session,
      () => session.isCurrent && session.content!.entries.last.isAvailable,
    );
    await graph.playlists.removeEntry('p', 'p-entry-0');
    await waitForContent(
      session,
      () => session.isCurrent && session.content!.totalCount == 1,
    );
    await graph.playlists.addTrack('p', track.ref);
    await waitForContent(
      session,
      () => session.isCurrent && session.content!.totalCount == 2,
    );
    await graph.playlists.deletePlaylist('p');
    await waitForContent(session, () => session.missing);
    expect(session.content, isNull);
    expect(engine.calls, isEmpty);
  });

  test('root never exposes rolled-back ordering and refreshes artist-only metadata changes', () async {
    await seed([detailTrack('a'), detailTrack('b')]);
    final graph = DependencyGraph(collection: collection);
    addTearDown(graph.close);
    final c = graph.playlistContents.open('p')..start();
    await waitForContent(c, () => c.isCurrent);
    final observed = <List<String>>[];
    c.addListener(() {
      if (c.isCurrent) {
        observed.add(c.content!.entries.map((e) => e.entry.id).toList());
      }
    });
    await expectLater(
      database.transaction(() async {
        await collection.movePlaylistEntry(
          'p',
          'p-entry-1',
          beforeEntryId: 'p-entry-0',
        );
        throw StateError('test rollback');
      }),
      throwsStateError,
    );
    await contentTick();
    await waitForContent(c, () => c.isCurrent);
    for (final order in observed) {
      expect(order, ['p-entry-0', 'p-entry-1']);
    }
    expect(c.content!.entries.first.entry.id, 'p-entry-0');
    await database
        .update(database.artistRecords)
        .write(const ArtistRecordsCompanion(name: Value('更新艺人')));
    await waitForContent(
      c,
      () =>
          c.isCurrent &&
          c.content!.entries.every((e) => e.track!.artists.contains('更新艺人')),
    );
    expect(c.content!.playlist.updatedAt, contentEpoch);
  });

  test('root waits for an actual intercepted SQLite read before closing the owned database', () async {
    await services.collection.createPlaylist(contentPlaylist('owned'));
    final graph = DependencyGraph(dataServices: services);
    final gate = Completer<void>();
    final entered = Completer<void>();
    probe.afterSelect = () async {
      if (!entered.isCompleted) entered.complete();
      await gate.future;
    };
    addTearDown(() async {
      if (!gate.isCompleted) gate.complete();
      await graph.close();
    });
    final session = graph.playlistContents.open('owned');
    session.start();
    await entered.future;
    var closed = false;
    final close = graph.close().then((_) => closed = true);
    await contentTick();
    expect(closed, isFalse);
    expect(probe.closeCount, 0);
    expect(graph.playlistContents.retainedSessionCount, 1);
    gate.complete();
    await close;
    expect(probe.closeCount, 1);
    expect(graph.playlistContents.retainedSessionCount, 0);
    expect(session.content, isNull);
    await graph.close();
    expect(probe.closeCount, 1);
  });
}
