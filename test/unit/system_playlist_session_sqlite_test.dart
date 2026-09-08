import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/fake_audio_engine.dart';
import '../support/playlist_content_probe.dart';
import '../support/search_query_probe.dart';
import '../support/system_playlist_probe.dart';
import 'system_playlist_repository_test.dart' show systemHistory, systemQueue;

void main() {
  late DatabaseAppDataServices services;
  late DependencyGraph graph;
  late SearchQueryProbe probe;
  late FakeAudioEngine engine;
  final track = Track(
    id: '同曲/a?%',
    sourceId: '来源/中',
    sourceType: MusicSourceType.rest,
    title: '多条目共用引用',
    artists: ['甲', '乙'],
    duration: const Duration(minutes: 3),
  );
  setUp(() async {
    probe = SearchQueryProbe();
    services = await DatabaseAppDataServices.open(
      AppDatabase(NativeDatabase.memory().interceptWith(probe)),
    );
    await services.library.upsertTracks([track]);
    engine = FakeAudioEngine();
    graph = DependencyGraph(dataServices: services, audioEngine: engine);
    await graph.initialize();
  });
  tearDown(() async {
    await graph.close();
  });

  test('real shared SQLite sessions refresh independent collections without writes or audio', () async {
    final cs = [
      for (final type in SystemPlaylistType.values)
        graph.systemPlaylists.open(type),
    ];
    probe.selects.clear();
    final transactions = probe.transactionCount,
        audioCalls = engine.calls.length;
    for (final c in cs) {
      c.start();
      await waitForSystem(c, () => c.phase == LoadPhase.empty);
    }
    expect(probe.selects.length, 3);
    expect(probe.transactionCount, transactions);
    await services.collection.setFavorite(track.ref, favorite: true);
    await waitForSystem(
      cs[0],
      () => cs[0].isCurrent && cs[0].content!.totalCount == 1,
    );
    await services.collection.recordHistory(
      systemHistory('h', track.ref, contentEpoch),
    );
    await waitForSystem(
      cs[1],
      () => cs[1].isCurrent && cs[1].content!.totalCount == 1,
    );
    await services.collection.saveQueue(
      systemQueue([track.ref, track.ref], current: 'q-1'),
    );
    await waitForSystem(
      cs[2],
      () => cs[2].isCurrent && cs[2].content!.totalCount == 2,
    );
    expect(cs[0].content!.entries.single.identity, track.ref);
    expect(cs[1].content!.entries.single.identity, 'h');
    expect(cs[2].content!.entries.map((e) => e.identity), ['q-0', 'q-1']);
    expect(cs[2].content!.currentQueueEntryId, 'q-1');
    for (final c in cs) {
      expect(c.content!.entries.first.track!.artists, ['甲', '乙']);
    }
    await services.library.setAvailability(
      track.ref,
      TrackAvailability.sourceDisabled,
    );
    for (final c in cs) {
      await waitForSystem(
        c,
        () => c.isCurrent && c.content!.entries.every((e) => !e.isAvailable),
      );
      expect(c.content!.entries.first.reference, track.ref);
    }
    await services.collection.clearHistory();
    await waitForSystem(cs[1], () => cs[1].phase == LoadPhase.empty);
    expect(cs[0].content!.totalCount, 1);
    expect(cs[2].content!.totalCount, 2);
    expect(await services.library.getTrack(track.ref), isNotNull);
    expect(await services.collection.watchPlaylists().first, isEmpty);
    expect(engine.calls.length, audioCalls);
  });

  test('1003 real queue references retain duplicates, one bounded query per group and page-external current ID', () async {
    await services.collection.saveQueue(
      systemQueue(List.filled(1003, track.ref), current: 'q-0'),
    );
    final c = graph.systemPlaylists.open(SystemPlaylistType.queue)..start();
    await expandSystemWindow(c);
    probe.selects.clear();
    final transactions = probe.transactionCount,
        audioCalls = engine.calls.length;
    final ids = c.content!.entries.map((e) => e.identity).toList();
    for (var offset = 200; offset <= 1000; offset += 200) {
      c.showNextWindow(c.content!);
      await waitForSystem(c, () => c.isCurrent);
      final data = c.content!;
      ids.addAll(data.entries.map((e) => e.identity));
      expect(data.currentQueueEntryId, 'q-0');
      expect(
        data.entries.every(
          (e) =>
              e.reference == track.ref && e.track!.artists.join(',') == '甲,乙',
        ),
        isTrue,
      );
      expect(data.page.offset, offset);
    }
    expect(ids, List.generate(1003, (i) => 'q-$i'));
    expect(probe.selects.length, 5);
    expect(probe.selects.map((s) => s.rows), [400, 400, 400, 400, 6]);
    expect(probe.selects.map((s) => s.args), [
      for (var o = 200; o <= 1000; o += 200) [200, o],
    ]);
    expect(probe.transactionCount, transactions);
    await services.collection.saveQueue(
      systemQueue(List.filled(1003, track.ref), current: 'q-1002'),
    );
    await waitForSystem(
      c,
      () => c.isCurrent && c.content!.currentQueueEntryId == 'q-1002',
    );
    expect(c.content!.page.offset, 1000);
    await services.collection.saveQueue(
      systemQueue(List.filled(220, track.ref), current: 'q-219'),
    );
    await waitForSystem(c, () => c.isCurrent && c.content!.totalCount == 220);
    expect(c.content!.page.offset, 200);
    expect(c.content!.entries.length, 20);
    expect(c.content!.currentQueueEntryId, 'q-219');
    expect(engine.calls.length, audioCalls);
  });

  test('root close drains the actual nonzero-offset SQLite query before storage closes', () async {
    await services.collection.saveQueue(
      systemQueue(List.filled(405, track.ref)),
    );
    final c = graph.systemPlaylists.open(SystemPlaylistType.queue)..start();
    await expandSystemWindow(c);
    final gate = Completer<void>(), entered = Completer<void>();
    probe.afterSelect = () async {
      if (probe.selects.last.sql.contains('system_count') &&
          probe.selects.last.args.toString() == '[200, 200]') {
        entered.complete();
        await gate.future;
      }
    };
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    c.showNextWindow(c.content!);
    await entered.future;
    var closed = false;
    final closing = graph.close().then((_) => closed = true);
    await contentTick();
    expect(closed, isFalse);
    expect(probe.closeCount, 0);
    expect(graph.systemPlaylists.retainedSessionCount, 1);
    gate.complete();
    await closing;
    expect(probe.closeCount, 1);
    expect(graph.systemPlaylists.retainedSessionCount, 0);
    expect(c.content!.page.offset, 0);
  });
}
