import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/fake_audio_engine.dart';
import '../support/playlist_content_probe.dart';
import '../support/search_query_probe.dart';
import 'playlist_window_navigation_test.dart' show expandWindow;

void main() {
  late DatabaseAppDataServices services;
  late DependencyGraph graph;
  late SearchQueryProbe probe;
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
    await services.collection.createPlaylist(contentPlaylist('p'));
    await services.collection.replacePlaylistEntries('p', [
      for (var i = 0; i < 1003; i++)
        contentItem('p', 'entry-$i', i, track).entry,
    ]);
    graph = DependencyGraph(
      dataServices: services,
      audioEngine: FakeAudioEngine(),
    );
    await graph.initialize();
  });
  tearDown(() async {
    await graph.close();
  });

  test('real SQLite session traverses every repeated reference with one joined statement per window and refreshes after reordering', () async {
    final c = graph.playlistContents.open('p')..start();
    await expandWindow(c);
    probe.selects.clear();
    final transactions = probe.transactionCount;
    final ids = c.content!.entries.map((e) => e.entry.id).toList();
    for (var offset = 200; offset <= 1000; offset += 200) {
      c.showNextWindow(c.content!);
      await waitForContent(c, () => c.isCurrent);
      final data = c.content!;
      ids.addAll(data.entries.map((e) => e.entry.id));
      expect(
        data.entries.every(
          (e) =>
              e.entry.track == track.ref && e.track!.artists.join(',') == '甲,乙',
        ),
        isTrue,
      );
      expect(data.page.offset, offset);
      expect(data.entries.length, lessThanOrEqualTo(200));
    }
    expect(ids, List.generate(1003, (i) => 'entry-$i'));
    expect(probe.selects.length, 5);
    expect(probe.selects.map((s) => s.rows), [400, 400, 400, 400, 6]);
    expect(probe.selects.map((s) => s.args), [
      for (var o = 200; o <= 1000; o += 200) ['p', 200, o],
    ]);
    expect(probe.transactionCount, transactions);
    await services.collection.movePlaylistEntry(
      'p',
      'entry-0',
      beforeEntryId: 'entry-1001',
    );
    await waitForContent(
      c,
      () => c.isCurrent && c.content!.entries.first.entry.id == 'entry-0',
    );
    expect(c.content!.page.offset, 1000);
    for (final id in ['entry-0', 'entry-1001', 'entry-1002']) {
      await services.collection.removePlaylistEntry('p', id);
    }
    await waitForContent(c, () => c.isCurrent && c.content!.totalCount == 1000);
    expect(c.content!.page.offset, 800);
    expect(c.content!.entries.length, 200);
    expect(await services.library.getTrack(track.ref), isNotNull);
  });

  test('root close waits for the actual nonzero-offset SQLite query before releasing storage', () async {
    final c = graph.playlistContents.open('p')..start();
    await expandWindow(c);
    final gate = Completer<void>();
    final entered = Completer<void>();
    probe.afterSelect = () async {
      if (probe.selects.last.args.toString() == '[p, 200, 200]') {
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
    final close = graph.close().then((_) => closed = true);
    await contentTick();
    expect(closed, isFalse);
    expect(probe.closeCount, 0);
    expect(graph.playlistContents.retainedSessionCount, 1);
    gate.complete();
    await close;
    expect(probe.closeCount, 1);
    expect(graph.playlistContents.retainedSessionCount, 0);
    expect(c.content!.page.offset, 0);
  });
}
