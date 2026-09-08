import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/features/playlists/common/playlist_content_controller.dart';

import '../support/catalog_detail_probe.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playlist_content_probe.dart';
import '../support/search_query_probe.dart';
import 'playlist_controller_test.dart' show commandPlaylist;
import 'playlist_metadata_sqlite_test.dart' show playlistFailure;

void main() {
  late AppDatabase database;
  late DatabaseAppDataServices services;
  late SearchQueryProbe probe;
  setUp(() async {
    probe = SearchQueryProbe();
    database = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    services = await DatabaseAppDataServices.open(database);
  });
  tearDown(() => services.dispose());
  Future<void> seed(
    List<Track> entries, {
    List<Track>? catalog,
    String id = 'p',
  }) async {
    await services.library.upsertTracks(catalog ?? entries);
    await services.collection.createPlaylist(contentPlaylist(id));
    await services.collection.replacePlaylistEntries(id, [
      for (var i = 0; i < entries.length; i++)
        contentItem(id, 'entry-$i', i, entries[i]).entry,
    ]);
  }

  test(
    'one bound read distinguishes missing empty and system without mutation',
    () async {
      await services.collection.createPlaylist(contentPlaylist("歌单'--"));
      await services.collection.savePlaylist(
        commandPlaylist('system', system: true),
      );
      probe.selects.clear();
      final transactions = probe.transactionCount;
      expect(
        await services.collection.readPlaylistPlaybackPlan('missing'),
        isNull,
      );
      expect(
        (await services.collection.readPlaylistPlaybackPlan("歌单'--"))!.entries,
        isEmpty,
      );
      expect(probe.selects.last.args, ["歌单'--"]);
      expect(probe.selects.last.sql, isNot(contains("歌单'--")));
      await expectLater(
        services.collection.readPlaylistPlaybackPlan('system'),
        throwsA(playlistFailure(DomainFailureCode.forbidden)),
      );
      expect(probe.selects.length, 3);
      expect(probe.transactionCount, transactions);
      expect(
        () => services.collection.readPlaylistPlaybackPlan(' bad '),
        throwsArgumentError,
      );
      expect(probe.selects.length, 3);
    },
  );
  test('1003 repeated entries use one lightweight SQL without artists metadata or 200 cap', () async {
    final track = Track(
      id: 'same',
      sourceId: 's',
      sourceType: MusicSourceType.rest,
      title: '多人歌曲',
      artists: ['甲', '乙', '丙'],
      duration: const Duration(minutes: 3),
    );
    await seed(List.filled(1003, track), catalog: [track]);
    // Invalid full metadata must not be decoded by the playback-plan reader.
    await database.customStatement(
      "UPDATE tracks SET metadata_json = 'private-marker'",
    );
    probe.selects.clear();
    final plan = (await services.collection.readPlaylistPlaybackPlan('p'))!;
    expect(
      plan.entries.map((e) => e.id),
      List.generate(1003, (i) => 'entry-$i'),
    );
    expect(
      plan.entries.every((e) => e.track == track.ref && e.isAvailable),
      isTrue,
    );
    expect(probe.selects.single.rows, 1003);
    expect(probe.selects.single.args, ['p']);
    expect(
      probe.selects.single.sql.toLowerCase(),
      isNot(
        matches(
          r'\b(limit|offset|track_artists|title|duration_ms|local_path)\b',
        ),
      ),
    );
  });
  test('full identity distinguishes sources types availability and unresolved references', () async {
    final tracks = [
      detailTrack('same', source: 'a'),
      detailTrack('same', source: 'a', type: MusicSourceType.rest),
      detailTrack('same', source: 'b', type: MusicSourceType.rest),
      for (final state in TrackAvailability.values)
        detailTrack(state.name, availability: state),
    ];
    await seed([
      ...tracks,
      tracks.first,
      detailTrack('missing'),
    ], catalog: tracks);
    final plan = (await services.collection.readPlaylistPlaybackPlan('p'))!;
    expect(plan.entries.length, tracks.length + 2);
    for (var i = 0; i < tracks.length; i++) {
      expect(plan.entries[i].track, tracks[i].ref);
      expect(plan.entries[i].availability, tracks[i].availability);
    }
    expect(plan.entries[tracks.length].track, tracks.first.ref);
    expect(plan.entries.last.availability, isNull);
    expect(plan.entries.last.isAvailable, isFalse);
  });
  for (final corrupt in ['availability', 'position']) {
    test('$corrupt corruption yields safe failure instead of partial queue', () async {
      await seed([detailTrack('a')]);
      // Inject a damaged legacy row only in this test database. Production
      // keeps its schema CHECK; restore checking before exercising the reader.
      await database.customStatement('PRAGMA ignore_check_constraints = ON');
      await database.customStatement(
        corrupt == 'availability'
            ? "UPDATE tracks SET availability = 'private-marker'"
            : 'UPDATE playlist_entries SET position = 2',
      );
      await database.customStatement('PRAGMA ignore_check_constraints = OFF');
      await expectLater(
        services.collection.readPlaylistPlaybackPlan('p'),
        throwsA(playlistFailure(DomainFailureCode.databaseCorrupted)),
      );
    });
  }
  test(
    'root shutdown drains actual complete-plan SQL before releasing storage',
    () async {
      await seed([detailTrack('a')]);
      final engine = FakeAudioEngine();
      final graph = DependencyGraph(
        dataServices: services,
        audioEngine: engine,
        playbackSourceResolver: FakePlaybackSourceResolver(),
      );
      await graph.initialize();
      final c = graph.playlistContents.open('p')..start();
      await waitForContent(c, () => c.isCurrent);
      final gate = Completer<void>();
      final entered = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      probe.afterSelect = () async {
        if (probe.selects.last.sql.contains('t.availability') &&
            probe.selects.last.args.length == 1) {
          entered.complete();
          await gate.future;
        }
      };
      final play = c.playAll(c.content!, shuffle: false);
      await entered.future;
      var closed = false;
      final close = graph.close().then((_) => closed = true);
      await contentTick();
      expect(closed, isFalse);
      expect(probe.closeCount, 0);
      gate.complete();
      await play;
      await close;
      expect(probe.closeCount, 1);
      expect(engine.calls, isEmpty);
      expect(graph.playlistContents.retainedSessionCount, 0);
    },
  );
}
