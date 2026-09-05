import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/collection_repository.dart';
import 'package:yymusic/domain/repositories/library_repository.dart';
import 'package:yymusic/domain/repositories/music_source_repository.dart';
import 'package:yymusic/features/home/common/home_controller.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

final _now = DateTime.utc(2026, 9, 5, 12);
Track _track(String id, {String source = 'local-test', bool remote = false}) =>
    Track(
      id: id,
      sourceId: source,
      sourceType: remote ? MusicSourceType.rest : MusicSourceType.local,
      title: '曲目 $id',
      artists: const ['测试艺人'],
      duration: const Duration(minutes: 3),
      localPath: remote ? null : '/fixture-only/$id.wav',
    );
PlayHistoryEntry _history(Track track, [String? id]) => PlayHistoryEntry(
  id: id ?? track.id,
  track: track.ref,
  startedAt: _now,
  lastPosition: Duration.zero,
);
Future<void> _flush() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('absent repositories are errors, real empty stores are empty', () async {
    final absent = DependencyGraph();
    absent.home.start();
    await _flush();
    expect(absent.home.recent.phase, LoadPhase.error);
    expect(absent.home.history.phase, LoadPhase.error);
    expect(absent.home.sources.phase, LoadPhase.error);
    await absent.close();
    final fixture = _Fixture();
    addTearDown(fixture.close);
    fixture.home.start();
    await _flush();
    expect(fixture.home.recent.phase, LoadPhase.empty);
    expect(fixture.home.history.phase, LoadPhase.empty);
    expect(fixture.home.sources.phase, LoadPhase.empty);
    expect(fixture.home.featured, isEmpty);
  });

  test(
    'bounded 7-day queries, full identities, dedupe and source error isolation',
    () async {
      final a = _track('same');
      final b = _track('same', source: 'another', remote: true);
      final tracks = [a, b, for (var i = 0; i < 35; i++) _track('extra-$i')];
      final fixture = _Fixture(tracks: tracks);
      addTearDown(fixture.close);
      fixture.home.start();
      await _flush();
      fixture.collection.events.add([
        _history(a),
        _history(a, 'repeat'),
        _history(b, 'b'),
        ...tracks.skip(2).map(_history),
      ]);
      fixture.sources.events.addError(StateError('Authorization=test-secret'));
      await _flush();
      expect(fixture.home.recent.data!.length, 20);
      expect(fixture.library.requests.single.limit, 20);
      expect(fixture.library.since, _now.subtract(const Duration(days: 7)));
      expect(fixture.library.until, _now);
      expect(fixture.home.history.data!.take(2).map((t) => t.ref), [
        a.ref,
        b.ref,
      ]);
      expect(fixture.library.reads.length, 19);
      expect(fixture.home.sources.phase, LoadPhase.error);
      expect(
        fixture.home.sources.failure.toString(),
        isNot(contains('test-secret')),
      );
      expect(fixture.home.featured.first.ref, a.ref);
      expect(fixture.home.featured.length, 6);
      expect(() => fixture.home.recent.data!.clear(), throwsUnsupportedError);
      fixture.home.start();
      expect(fixture.library.requests.length, 1);
    },
  );

  test(
    'older catalog responses cannot replace newer refresh results',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);
      final old = Completer<PageResult<Track>>();
      fixture.library.recentOverride = () => old.future;
      final first = fixture.home.refreshCatalog();
      fixture.library.recentOverride = () async =>
          PageResult(items: [_track('new')], hasMore: false);
      await fixture.home.refreshCatalog();
      old.complete(PageResult(items: [_track('old')], hasMore: false));
      await first;
      expect(fixture.home.recent.data!.single.id, 'new');
    },
  );

  test(
    'history event version ignores stale hydration after error and recovery',
    () async {
      final a = _track('a');
      final b = _track('b');
      final fixture = _Fixture(tracks: [a, b]);
      addTearDown(fixture.close);
      fixture.home.start();
      await _flush();
      final old = Completer<Track?>();
      fixture.library.trackOverride = (ref) =>
          ref == a.ref ? old.future : Future.value(b);
      fixture.collection.events.add([_history(a)]);
      await _flush();
      fixture.collection.events.addError(StateError('secret-error'));
      expect(fixture.home.history.phase, LoadPhase.error);
      fixture.collection.events.add([_history(b)]);
      await _flush();
      old.complete(a);
      await _flush();
      expect(fixture.home.history.data!.single.ref, b.ref);
    },
  );

  test('recent query failure leaves local featured selection usable and retry recovers', () async {
    final fixture = _Fixture(tracks: [_track('local')]);
    addTearDown(fixture.close);
    fixture.library.recentOverride = () async =>
        throw StateError('sensitive database detail');
    fixture.home.start();
    await _flush();
    expect(fixture.home.recent.phase, LoadPhase.error);
    expect(fixture.home.featured.single.id, 'local');
    fixture.library.recentOverride = null;
    await fixture.home.refreshCatalog();
    expect(fixture.home.recent.phase, LoadPhase.data);
  });

  test('selecting a track preserves queue, reuses identity and prevents double activation', () async {
    final a = _track('a');
    final b = _track('b');
    final fixture = _Fixture(tracks: [a, b]);
    addTearDown(fixture.close);
    await fixture.graph.initialize();
    await fixture.graph.queue.replace([
      QueueEntry(id: 'existing', track: a.ref, position: 0, addedAt: _now),
    ]);
    final gate = Completer<void>();
    fixture.engine.loadGate = gate.future;
    final play = fixture.home.play(b);
    expect(fixture.home.busy, isTrue);
    await fixture.home.play(b);
    gate.complete();
    await play;
    expect(fixture.engine.calls, contains('play'));
    expect(fixture.graph.playbackPresenter.trackRef, b.ref);
    expect(fixture.graph.queue.state.entries.map((e) => e.track), [
      a.ref,
      b.ref,
    ]);
    await fixture.home.play(b);
    expect(fixture.graph.queue.state.entries.length, 2);
    await fixture.home.play(a.withAvailability(TrackAvailability.localMissing));
    expect(fixture.graph.queue.state.currentEntryId, isNot('existing'));
    fixture.engine.loadError = StateError('Bearer secret-error');
    await fixture.home.play(a);
    expect(fixture.home.actionError, isNotNull);
    expect(fixture.home.actionError, isNot(contains('secret-error')));
  });

  test(
    'close cancels streams and drains reads before owned library disposal',
    () async {
      final fixture = _Fixture();
      final gate = Completer<PageResult<Track>>();
      fixture.library.recentOverride = () => gate.future;
      fixture.graph.home.start();
      await _flush();
      var notifications = 0;
      fixture.graph.home.addListener(() => notifications++);
      var closed = false;
      final close = fixture.graph.close().then((_) => closed = true);
      await _flush();
      expect(closed, isFalse);
      expect(fixture.library.backing.disposeCount, 0);
      final count = fixture.library.requests.length;
      await fixture.graph.home.refreshCatalog();
      fixture.graph.home.retrySources();
      fixture.graph.home.retryHistory();
      expect(fixture.library.requests.length, count);
      gate.complete(PageResult(items: [_track('late')], hasMore: false));
      await close;
      expect(notifications, 0);
      expect(fixture.library.backing.disposeCount, 1);
      expect(fixture.sources.events.hasListener, isFalse);
      expect(fixture.collection.events.hasListener, isFalse);
      await fixture.close();
    },
  );

  test('clear history is explicit, keeps tracks and queue, and reports safe failure', () async {
    final a = _track('a');
    final fixture = _Fixture(tracks: [a]);
    addTearDown(fixture.close);
    fixture.home.start();
    await _flush();
    fixture.collection.events.add([_history(a)]);
    await _flush();
    expect(fixture.home.canClearHistory, isTrue);
    fixture.collection.clearError = StateError('private sqlite path');
    await fixture.home.clearHistory();
    expect(fixture.home.history.data!.single.ref, a.ref);
    expect(fixture.home.actionError, '历史未能清除，请重试。');
    fixture.collection.clearError = null;
    await fixture.home.clearHistory();
    await _flush();
    expect(fixture.home.history.phase, LoadPhase.empty);
    expect(await fixture.library.getTrack(a.ref), isNotNull);
    expect(fixture.home.canClearHistory, isFalse);
  });
}

final class _Library implements LibraryRepository {
  _Library(Iterable<Track> tracks)
    : backing = FakeLibraryRepository(tracks: tracks, clock: () => _now);
  final FakeLibraryRepository backing;
  final requests = <PageRequest>[];
  final reads = <TrackRef>[];
  DateTime? since, until;
  Future<PageResult<Track>> Function()? recentOverride;
  Future<Track?> Function(TrackRef)? trackOverride;
  @override
  Future<PageResult<Track>> listRecentlyAdded(
    PageRequest request, {
    required DateTime since,
    required DateTime until,
  }) {
    requests.add(request);
    this.since = since;
    this.until = until;
    return recentOverride?.call() ??
        backing.listRecentlyAdded(request, since: since, until: until);
  }

  @override
  Future<PageResult<Track>> listTracks(PageRequest request) =>
      backing.listTracks(request);
  @override
  Future<Track?> getTrack(TrackRef ref) {
    reads.add(ref);
    return trackOverride?.call(ref) ?? backing.getTrack(ref);
  }

  @override
  Future<void> dispose() => backing.dispose();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Collection implements CollectionRepository {
  final events = StreamController<List<PlayHistoryEntry>>.broadcast(sync: true);
  Object? clearError;
  Future<void> dispose() => events.close();
  @override
  Stream<List<PlayHistoryEntry>> watchHistory() async* {
    yield const [];
    yield* events.stream;
  }

  @override
  Future<void> clearHistory() async {
    if (clearError case final error?) {
      throw error;
    }
    events.add(const []);
  }

  @override
  Future<QueueSnapshot> loadQueue() async =>
      QueueSnapshot(entries: const [], updatedAt: _now);
  @override
  Future<void> saveQueue(QueueSnapshot snapshot) async {}
  @override
  Future<void> recordHistory(PlayHistoryEntry entry) async {
    events.add([entry]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Sources implements MusicSourceRepository {
  final events = StreamController<List<MusicSourceConfig>>.broadcast(
    sync: true,
  );
  Future<void> dispose() => events.close();
  @override
  Stream<List<MusicSourceConfig>> watchSources() async* {
    yield const [];
    yield* events.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Fixture {
  _Fixture({Iterable<Track> tracks = const []}) : library = _Library(tracks) {
    graph = DependencyGraph(
      library: library,
      collection: collection,
      musicSources: sources,
      audioEngine: engine,
      playbackSourceResolver: FakePlaybackSourceResolver(),
    );
    home = HomeController(
      playback: graph.playback,
      library: library,
      collection: collection,
      sourceRepository: sources,
      clock: () => _now,
    );
  }
  final _Library library;
  final collection = _Collection();
  final sources = _Sources();
  final engine = FakeAudioEngine();
  late final DependencyGraph graph;
  late final HomeController home;
  Future<void> close() async {
    await home.close();
    await graph.close();
    await collection.dispose();
    await sources.dispose();
  }
}
