import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  late FakeAudioEngine engine;
  late FakePlaybackSourceResolver resolver;
  late FakeCollectionRepository collection;
  late PlaybackController controller;
  late List<Track> tracks;
  late List<QueueEntry> entries;

  setUp(() async {
    tracks = [
      for (final id in ['a', 'b', 'c']) _track(id),
    ];
    entries = [
      for (final (index, track) in tracks.indexed)
        QueueEntry(
          id: track.id,
          track: track.ref,
          position: index,
          addedAt: _epoch,
        ),
    ];
    engine = FakeAudioEngine();
    resolver = FakePlaybackSourceResolver();
    collection = FakeCollectionRepository();
    controller = PlaybackController(
      engine,
      library: FakeLibraryRepository(tracks: tracks),
      collection: collection,
      sourceResolver: resolver,
      clock: () => _epoch,
    );
    await controller.replaceQueue(entries, currentEntryId: 'a');
  });

  tearDown(() async {
    controller.dispose();
    await engine.dispose();
    await collection.dispose();
  });

  test('stop then play resolves and loads the source again', () async {
    await controller.play();
    await controller.stop();
    expect(controller.state.phase, PlaybackPhase.idle);
    await controller.play();
    expect(engine.calls, ['load', 'play', 'stop', 'load', 'play']);
    expect(resolver.resolved, [tracks[0].ref, tracks[0].ref]);
    expect(controller.state.phase, PlaybackPhase.playing);
  });

  test('pause then play resumes without another source resolution', () async {
    await controller.play();
    await controller.pause();
    await controller.play();
    expect(engine.calls, ['load', 'play', 'pause', 'play']);
    expect(resolver.resolved, [tracks[0].ref]);
  });

  test(
    'a failed load can be retried through the ordinary play action',
    () async {
      engine.loadError = StateError('transient failure');
      await expectLater(controller.play(), throwsA(isA<DomainFailure>()));
      engine.loadError = null;
      await controller.play();
      expect(engine.calls.where((call) => call == 'load'), hasLength(2));
      expect(controller.state.phase, PlaybackPhase.playing);
      expect(controller.state.failure, isNull);
    },
  );

  test('replacing the current identity stops the previous audio', () async {
    await controller.play();
    await controller.replaceQueue(entries, currentEntryId: 'b');
    expect(engine.calls, ['load', 'play', 'stop']);
    expect(engine.loadedSource, isNull);
    expect(controller.state.currentTrack, isNull);
    expect(controller.state.phase, PlaybackPhase.idle);
    expect((await collection.loadQueue()).currentEntryId, 'b');
    await controller.play();
    expect(engine.loadedSource?.track, tracks[1].ref);
  });

  test('reusing an entry ID for a different track also stops audio', () async {
    await controller.play();
    await controller.replaceQueue([
      QueueEntry(id: 'a', track: tracks[1].ref, position: 0, addedAt: _epoch),
    ], currentEntryId: 'a');
    expect(engine.calls.where((call) => call == 'stop'), hasLength(1));
    expect(controller.state.currentTrack, isNull);
    await controller.play();
    expect(engine.loadedSource?.track, tracks[1].ref);
  });

  test(
    'reordering the same current reference does not stop playback',
    () async {
      await controller.play();
      await controller.replaceQueue(entries.reversed, currentEntryId: 'a');
      expect(engine.calls, ['load', 'play']);
      expect(controller.state.currentTrack?.ref, tracks[0].ref);
      expect(controller.state.phase, PlaybackPhase.playing);
    },
  );

  test('stop failure does not commit a replacement queue', () async {
    await controller.play();
    engine.stopError = StateError('cannot stop');
    await expectLater(
      controller.replaceQueue(entries, currentEntryId: 'b'),
      throwsA(isA<DomainFailure>()),
    );
    expect(controller.state.queue.currentEntryId, 'a');
    expect((await collection.loadQueue()).currentEntryId, 'a');
    expect(controller.state.phase, PlaybackPhase.error);
  });

  test('duplicate completed events advance only one entry', () async {
    await controller.play();
    engine.complete();
    engine.complete();
    await _drain();
    expect(controller.state.queue.currentEntryId, 'b');
    expect(resolver.resolved, [tracks[0].ref, tracks[1].ref]);
  });

  test('a queued completion cannot skip a manually chosen track', () async {
    await controller.play();
    final selected = controller.playEntry('b');
    engine.complete();
    await selected;
    await _drain();
    expect(controller.state.queue.currentEntryId, 'b');
    expect(resolver.resolved, [tracks[0].ref, tracks[1].ref]);
  });

  test('a queued stop invalidates automatic completion', () async {
    await controller.play();
    final stopped = controller.stop();
    engine.complete();
    await stopped;
    await _drain();
    expect(controller.state.queue.currentEntryId, 'a');
    expect(controller.state.phase, PlaybackPhase.idle);
    expect(resolver.resolved, [tracks[0].ref]);
  });

  test('late media events cannot revive a stopped session', () async {
    await controller.play();
    await controller.stop();
    engine.events.add(AudioEngineState(phase: AudioEnginePhase.playing));
    engine.complete();
    await _drain();
    expect(controller.state.phase, PlaybackPhase.idle);
    expect(controller.state.queue.currentEntryId, 'a');
    expect(resolver.resolved, [tracks[0].ref]);
  });

  test('native playback resumed by seek accepts its next completion', () async {
    await controller.play();
    final seeked = controller.seek(const Duration(seconds: 1));
    engine.complete();
    await seeked;
    engine.events.add(
      AudioEngineState(
        phase: AudioEnginePhase.playing,
        position: const Duration(seconds: 1),
      ),
    );
    engine.complete();
    await _drain();
    expect(controller.state.queue.currentEntryId, 'b');
    expect(resolver.resolved, [tracks[0].ref, tracks[1].ref]);
  });

  test(
    'repeat one consumes duplicates but accepts the next real cycle',
    () async {
      controller.setRepeatMode(RepeatMode.one);
      await controller.play();
      engine.complete();
      engine.complete();
      await _drain();
      expect(engine.calls.where((call) => call == 'seek:0'), hasLength(1));
      expect(controller.state.phase, PlaybackPhase.playing);
      engine.complete();
      await _drain();
      expect(engine.calls.where((call) => call == 'seek:0'), hasLength(2));
      expect(resolver.resolved, [tracks[0].ref]);
    },
  );

  test(
    'completed snapshots still update control values without advancing',
    () async {
      await controller.playEntry('c');
      engine.complete();
      await _drain();
      controller.setRepeatMode(RepeatMode.all);
      engine.events.add(
        AudioEngineState(phase: AudioEnginePhase.completed, volume: 0.4),
      );
      await _drain();
      expect(controller.state.volume, 0.4);
      expect(controller.state.phase, PlaybackPhase.completed);
      expect(controller.state.queue.currentEntryId, 'c');
      expect(resolver.resolved, [tracks[2].ref]);
    },
  );

  test('queue edits retain a matching error and its failure', () async {
    engine.loadError = StateError('load failed');
    await expectLater(controller.play(), throwsA(isA<DomainFailure>()));
    final failure = controller.state.failure;
    await controller.moveQueueEntry('c', 0);
    expect(controller.state.phase, PlaybackPhase.error);
    expect(controller.state.failure, same(failure));
    expect(controller.state.queue.entries.first.id, 'c');
  });

  test('dispose while loading never starts playback afterwards', () async {
    final gate = Completer<void>();
    engine.loadGate = gate.future;
    final operation = controller.play();
    final assertion = expectLater(operation, throwsA(isA<DomainFailure>()));
    await _drain();
    expect(engine.calls, ['load']);
    controller.dispose();
    gate.complete();
    await assertion;
    expect(engine.calls, ['load']);
  });
}

final _epoch = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);

Track _track(String id) => Track(
  id: id,
  sourceId: 'session-test',
  sourceType: MusicSourceType.rest,
  title: id,
  artists: const ['Test'],
  duration: const Duration(minutes: 3),
);

Future<void> _drain() => Future<void>.delayed(Duration.zero);
