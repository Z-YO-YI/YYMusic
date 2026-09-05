import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/features/search/common/search_controller.dart';

import '../support/close_graph.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/search_graph_fixture.dart';

Future<void> flushSearch() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

SearchBucket<Track> localTracks(CatalogSearchController c) => c.buckets
    .whereType<SearchBucket<Track>>()
    .firstWhere((b) => b.sourceType == MusicSourceType.local);

void main() {
  test(
    'Enter skips unavailable local results without waiting for remote reads',
    () async {
      final fixture = SearchGraphFixture();
      addTearDown(fixture.close);
      final remote = Completer<PageResult<Track>>();
      final missing = Track(
        id: 'missing',
        sourceId: 'local-test',
        sourceType: MusicSourceType.local,
        title: '夜航 · 已移走',
        localPath: '/fixture-only/missing.wav',
        artists: const ['测试艺术家'],
        duration: Duration.zero,
        availability: TrackAvailability.localMissing,
      );
      fixture.repository.trackQuery = (q, p, c) async =>
          q.sourceType == MusicSourceType.rest
          ? remote.future
          : PageResult(items: [missing, fixture.tracks[1]], hasMore: false);
      final search = fixture.graph.search..updateInput('夜');
      final submitting = search.submit(playFirst: true);
      await flushSearch();
      expect(fixture.engine.calls, contains('play'));
      expect(
        fixture.graph.playback.state.queue.entries.single.track,
        fixture.tracks[1].ref,
      );
      remote.complete(PageResult(items: [], hasMore: false));
      await submitting;
      expect(fixture.engine.calls.where((c) => c == 'play').length, 1);
    },
  );
  testWidgets(
    '300ms debounce and composition-only commits never save history',
    (tester) async {
      final fixture = SearchGraphFixture();
      final search = fixture.graph.search;
      search.updateInput('夜', composing: true);
      await tester.pump(const Duration(seconds: 1));
      expect(fixture.repository.requests, isEmpty);
      await search.submit(playFirst: true);
      expect(fixture.engine.calls, isEmpty);
      search.updateInput('夜', composing: false);
      await tester.pump(const Duration(milliseconds: 299));
      expect(fixture.repository.requests, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(fixture.repository.requests.length, 6);
      expect(fixture.history.calls, isEmpty);
      search.updateInput('夜航');
      await tester.pump(const Duration(milliseconds: 200));
      search.updateInput('夜航 2');
      await tester.pump(const Duration(milliseconds: 300));
      expect(localTracks(search).items.single.title, '夜航 2');
      await closeGraph(tester, fixture.graph);
      await tester.runAsync(fixture.disposeFakes);
    },
  );

  test('six queries start independently; cancelled late results cannot replace new data', () async {
    final fixture = SearchGraphFixture();
    addTearDown(fixture.close);
    final gate = Completer<PageResult<Track>>();
    fixture.repository.trackQuery = (q, p, c) async => q.text == 'old'
        ? gate.future
        : PageResult(items: [fixture.tracks[1]], hasMore: false);
    final search = fixture.graph.search..updateInput('old');
    final old = search.submit(playFirst: true);
    await flushSearch();
    expect(fixture.repository.requests.length, 6);
    final oldToken = fixture.repository.requests.first.$4!;
    search.updateInput('new');
    await search.submit();
    gate.complete(PageResult(items: [fixture.tracks.first], hasMore: false));
    await old;
    expect(oldToken.isCancelled, isTrue);
    expect(localTracks(search).items.single.ref, fixture.tracks[1].ref);
    expect(fixture.engine.calls, isEmpty);
  });

  test(
    'REST errors do not hide local kinds or leak adapter diagnostics',
    () async {
      final fixture = SearchGraphFixture()..repository.remoteFailure = true;
      addTearDown(fixture.close);
      final search = fixture.graph.search..updateInput('夜');
      await search.submit();
      expect(
        search.buckets
            .where((b) => b.sourceType == MusicSourceType.local)
            .every((b) => b.phase == LoadPhase.data),
        isTrue,
      );
      expect(
        search.buckets
            .where((b) => b.sourceType == MusicSourceType.rest)
            .every((b) => b.phase == LoadPhase.error),
        isTrue,
      );
      fixture.repository.remoteFailure = false;
      final remote = search.buckets.last;
      await search.loadMore(remote);
      expect(remote.phase, LoadPhase.data);
    },
  );

  test('pagination uses raw offsets, full identities, one inflight page and immutable lists', () async {
    final fixture = SearchGraphFixture(count: 40);
    addTearDown(fixture.close);
    fixture.repository.trackQuery = (q, p, c) async => PageResult(
      items: p.offset == 0
          ? [
              fixture.tracks.first,
              fixture.tracks.first,
              fixture.tracks.last,
              ...fixture.tracks.skip(1).take(17),
            ]
          : fixture.tracks.skip(18).take(20),
      hasMore: true,
    );
    final search = fixture.graph.search
      ..selectFilter(SearchFilter.local)
      ..updateInput('夜');
    await search.submit();
    final bucket = localTracks(search);
    expect(bucket.items.length, 19);
    expect(bucket.items.take(2).map((t) => t.ref), [
      fixture.tracks.first.ref,
      fixture.tracks.last.ref,
    ]);
    await Future.wait([search.loadMore(bucket), search.loadMore(bucket)]);
    expect(
      fixture.repository.requests
          .where((r) => r.$1 == 'tracks')
          .map((r) => r.$3.offset),
      [0, 20],
    );
    expect(bucket.items.length, 39);
    expect(() => bucket.items.clear(), throwsUnsupportedError);
  });

  test('pagination cap bounds memory and asks for a narrower search', () async {
    final fixture = SearchGraphFixture(count: 220);
    addTearDown(fixture.close);
    final search = fixture.graph.search
      ..selectFilter(SearchFilter.local)
      ..updateInput('夜');
    await search.submit();
    final bucket = localTracks(search);
    for (var i = 0; i < 12; i++) {
      await search.loadMore(bucket);
    }
    expect(bucket.items.length, 200);
    expect(bucket.capped, isTrue);
    expect(
      fixture.repository.requests.where((r) => r.$1 == 'tracks').length,
      10,
    );
  });

  test('failed append preserves items and retries the same offset', () async {
    final fixture = SearchGraphFixture(count: 30);
    addTearDown(fixture.close);
    final search = fixture.graph.search
      ..selectFilter(SearchFilter.local)
      ..updateInput('夜');
    await search.submit();
    final bucket = localTracks(search);
    fixture.repository.trackQuery = (q, p, c) async =>
        throw StateError('private-search-marker');
    await search.loadMore(bucket);
    expect(bucket.phase, LoadPhase.error);
    expect(bucket.items.length, 20);
    fixture.repository.trackQuery = null;
    await search.loadMore(bucket);
    expect(bucket.phase, LoadPhase.data);
    expect(bucket.items.length, 30);
    expect(
      fixture.repository.requests
          .where((r) => r.$1 == 'tracks')
          .map((r) => r.$3.offset),
      [0, 20, 20],
    );
  });

  test(
    'history serializes explicit record then clear without resurrection',
    () async {
      final fixture = SearchGraphFixture();
      addTearDown(fixture.close);
      final gate = Completer<void>();
      fixture.history.recordGate = gate.future;
      final search = fixture.graph.search
        ..start()
        ..updateInput('夜');
      await search.submit();
      await flushSearch();
      final clear = search.clearHistory();
      expect(fixture.history.calls, isNot(contains('clear')));
      gate.complete();
      await clear;
      expect(search.history, isEmpty);
      expect(fixture.history.calls, [
        'list',
        'record',
        'list',
        'clear',
        'list',
      ]);
      expect(fixture.graph.playback.state.queue.entries, isEmpty);
      fixture.history.fail = true;
      await search.submit();
      await search.refreshHistory();
      expect(search.historyError, isNot(contains('private-search-marker')));
      expect(localTracks(search).items, isNotEmpty);
    },
  );

  test(
    'Enter uses root player and albums filter never plays invisible tracks',
    () async {
      final fixture = SearchGraphFixture();
      addTearDown(fixture.close);
      await fixture.graph.initialize();
      final search = fixture.graph.search..updateInput('夜');
      await search.submit(playFirst: true);
      expect(fixture.engine.calls.where((c) => c == 'play').length, 1);
      expect(
        fixture.graph.playback.state.queue.entries.single.track,
        fixture.tracks.first.ref,
      );
      await search.submit(playFirst: true);
      expect(fixture.graph.playback.state.queue.entries.length, 1);
      search.selectFilter(SearchFilter.albums);
      await search.submit(playFirst: true);
      expect(fixture.engine.calls.where((c) => c == 'play').length, 2);
    },
  );

  test(
    'leaving route or changing input cancels pending Enter intent',
    () async {
      for (final leave in [true, false]) {
        final fixture = SearchGraphFixture();
        final gate = Completer<PageResult<Track>>();
        fixture.repository.trackQuery = (q, p, c) => gate.future;
        final search = fixture.graph.search..updateInput('夜');
        final submit = search.submit(playFirst: true);
        if (leave) {
          search.setActive(false);
        } else {
          search.updateInput('');
        }
        gate.complete(
          PageResult(items: [fixture.tracks.first], hasMore: false),
        );
        await submit;
        search.setActive(true);
        expect(fixture.engine.calls, isEmpty);
        await fixture.close();
      }
    },
  );

  test(
    'revoking intent during engine load stops without starting audio',
    () async {
      final fixture = SearchGraphFixture();
      addTearDown(fixture.close);
      final gate = Completer<void>();
      fixture.engine.loadGate = gate.future;
      final search = fixture.graph.search..updateInput('夜');
      final submit = search.submit(playFirst: true);
      await flushSearch();
      expect(fixture.engine.calls, contains('load'));
      search.setActive(false);
      gate.complete();
      await submit;
      expect(fixture.engine.calls, isNot(contains('play')));
      expect(fixture.engine.calls, contains('stop'));
    },
  );

  test(
    'root catalog commands atomically reuse refs across concurrent selections',
    () async {
      final fixture = SearchGraphFixture();
      addTearDown(fixture.close);
      final player = fixture.graph.playback;
      await Future.wait([
        player.playCatalogTrack(fixture.tracks.first.ref),
        player.playCatalogTrack(fixture.tracks.last.ref),
        player.playCatalogTrack(fixture.tracks.first.ref),
      ]);
      expect(player.state.queue.entries.map((e) => e.track), [
        fixture.tracks.first.ref,
        fixture.tracks.last.ref,
      ]);
      expect(player.state.queue.entries.map((e) => e.id).toSet().length, 2);
      var allowed = true;
      final blocked = player.playCatalogTrack(
        fixture.tracks[1].ref,
        canPlay: () => allowed,
      );
      allowed = false;
      await blocked;
      expect(player.state.queue.entries.length, 2);
    },
  );

  test(
    'close drains pending reads without closing borrowed contracts',
    () async {
      final fixture = SearchGraphFixture();
      final gate = Completer<PageResult<Track>>();
      fixture.repository.trackQuery = (q, p, c) => gate.future;
      final search = fixture.graph.search..updateInput('夜');
      final submit = search.submit(playFirst: true);
      var closed = false;
      final closing = search.close().then((_) => closed = true);
      await flushSearch();
      expect(closed, isFalse);
      gate.complete(PageResult(items: fixture.tracks, hasMore: false));
      await submit;
      await closing;
      expect(fixture.history.disposed, isFalse);
      expect(fixture.engine.calls, isEmpty);
      await fixture.close();
    },
  );

  test('public source names update and failures fall back without exposing configs', () async {
    final fixture = SearchGraphFixture();
    addTearDown(fixture.close);
    final search = fixture.graph.search..start();
    await fixture.sources.saveSource(
      MusicSourceConfig(
        id: 'local-test',
        name: '我的音乐',
        type: MusicSourceType.local,
        authType: MusicSourceAuthType.system,
      ),
    );
    await flushSearch();
    expect(search.sourceLabel('local-test', MusicSourceType.local), '我的音乐');
    // Missing source configurations still expose only generic labels.
    expect(
      search.sourceLabel('private-search-marker', MusicSourceType.rest),
      '在线来源',
    );
  });

  test(
    'real database scope wires search and persists only explicit history',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final services = await DatabaseAppDataServices.open(database);
      final engine = FakeAudioEngine();
      final graph = DependencyGraph(
        dataServices: services,
        audioEngine: engine,
        playbackSourceResolver: FakePlaybackSourceResolver(),
      );
      addTearDown(graph.close);
      expect(graph.catalogSearch, same(services.library));
      final track = Track(
        id: 'real-db',
        sourceId: 'local',
        sourceType: MusicSourceType.local,
        title: '夜航',
        artists: const ['艺术家'],
        duration: Duration.zero,
        localPath: '/test-only.wav',
      );
      await services.library.upsertTracks([track]);
      await graph.initialize();
      final search = graph.search
        ..start()
        ..updateInput('夜');
      await search.submit();
      await search.refreshHistory();
      expect(search.history.single.query, '夜');
      expect(localTracks(search).items.single.ref, track.ref);
      await search.clearHistory();
      expect(await services.searchHistory.listHistory(), isEmpty);
      expect(await services.library.getTrack(track.ref), isNotNull);
    },
  );

  test(
    'blank and invalid input dispatch no queries and expose safe validation',
    () async {
      final fixture = SearchGraphFixture();
      addTearDown(fixture.close);
      final search = fixture.graph.search;
      for (final input in ['  ', 'private-search-marker\n', 'x' * 2049]) {
        search.updateInput(input);
        await search.submit(playFirst: true);
      }
      expect(fixture.repository.requests, isEmpty);
      expect(fixture.history.calls, isEmpty);
      expect(search.inputError, isNot(contains('private-search-marker')));
    },
  );
}
