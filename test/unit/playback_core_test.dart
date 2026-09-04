import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/playable_source.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_state.dart';
import 'package:yymusic/playback/queue_controller.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  group('playback source and state contracts', () {
    test(
      'accepts platform media references and redacts transient network data',
      () {
        final ref = _track('source').ref;
        final windows = PlayableSource.localFile(
          track: ref,
          path: r'C:\Music\合法路径\song.flac',
        );
        final android = PlayableSource.contentUri(
          track: ref,
          uri: Uri.parse('content://media/external/audio/media/42'),
        );
        final network = PlayableSource.networkStream(
          track: ref,
          uri: Uri.parse('https://media.invalid/play?id=short-lived-secret'),
          headers: const {'Authorization': 'Bearer header-secret'},
        );

        expect(windows.kind, PlayableSourceKind.localFile);
        expect(android.kind, PlayableSourceKind.contentUri);
        expect(network.headers['Authorization'], 'Bearer header-secret');
        expect(network.toString(), isNot(contains('short-lived-secret')));
        expect(network.toString(), isNot(contains('header-secret')));
        expect(
          () => PlayableSource.localFile(track: ref, path: 'relative.mp3'),
          throwsArgumentError,
        );
        expect(
          () => PlayableSource.networkStream(
            track: ref,
            uri: Uri.parse('http://media.invalid/insecure'),
          ),
          throwsArgumentError,
        );
        expect(
          () => PlayableSource.networkStream(
            track: ref,
            uri: Uri.parse('https://media.invalid/stream'),
            headers: const {'X-Test': 'line\r\ninjection'},
          ),
          throwsArgumentError,
        );
      },
    );

    test('covers all formal phases and rejects inconsistent values', () {
      expect(PlaybackPhase.values.map((value) => value.name), [
        'idle',
        'loading',
        'buffering',
        'ready',
        'playing',
        'paused',
        'completed',
        'error',
      ]);
      expect(AudioEnginePhase.values.map((value) => value.name), [
        'idle',
        'loading',
        'buffering',
        'ready',
        'playing',
        'paused',
        'completed',
        'error',
      ]);
      expect(
        () => PlaybackState(phase: PlaybackPhase.error),
        throwsArgumentError,
      );
      expect(
        () => PlaybackState(position: const Duration(milliseconds: -1)),
        throwsArgumentError,
      );
      expect(() => PlaybackState(volume: double.nan), throwsArgumentError);
      expect(() => PlaybackState(playbackRate: 2.1), throwsArgumentError);
      expect(
        () => AudioEngineState(
          phase: AudioEnginePhase.idle,
          failure: _failure('unexpected'),
        ),
        throwsArgumentError,
      );
      expect(
        PlaybackState(
          phase: PlaybackPhase.error,
          failure: _failure('expected'),
        ).failure?.diagnosticId,
        'playback.test-expected',
      );
    });
  });

  group('PlaybackController', () {
    test(
      'loads one queue identity, clamps seek and serves media callbacks',
      () async {
        final tracks = [_track('a'), _track('b')];
        final engine = FakeAudioEngine(duration: const Duration(minutes: 3));
        final resolver = FakePlaybackSourceResolver();
        final media = FakeMediaSessionGateway();
        final controller = PlaybackController(
          engine,
          library: FakeLibraryRepository(tracks: tracks),
          collection: FakeCollectionRepository(),
          sourceResolver: resolver,
          mediaSession: media,
          clock: () => _epoch,
        );
        final queue = QueueController(controller);
        addTearDown(() async {
          queue.dispose();
          controller.dispose();
          await engine.dispose();
          await media.dispose();
        });

        await controller.initialize();
        await queue.replace([
          _entry('entry-a', tracks[0].ref, 0),
          _entry('entry-b', tracks[1].ref, 1),
        ], currentEntryId: 'entry-a');
        await queue.play('entry-a');

        expect(controller.state.phase, PlaybackPhase.playing);
        expect(controller.state.currentTrack, same(tracks[0]));
        expect(queue.state, same(controller.state.queue));
        expect(resolver.resolved, [tracks[0].ref]);
        expect(engine.loadedSource?.track, tracks[0].ref);

        await controller.seek(const Duration(minutes: 5));
        await controller.setVolume(0.25);
        await controller.setPlaybackRate(1.5);
        expect(engine.position, const Duration(minutes: 3));
        expect(controller.state.position, const Duration(minutes: 3));
        expect(controller.state.volume, 0.25);
        expect(controller.state.playbackRate, 1.5);
        await expectLater(
          controller.seek(const Duration(seconds: -1)),
          throwsArgumentError,
        );

        await media.callbacks!.skipNext();
        await _drain();
        expect(controller.state.currentTrack, same(tracks[1]));
        expect(
          media.metadata,
          containsAllInOrder([tracks[0].ref, tracks[1].ref]),
        );
        expect(media.states.last.currentTrack, same(tracks[1]));
      },
    );

    test('keeps duplicate tracks independent across queue mutations', () async {
      final track = _track('duplicate');
      final engine = FakeAudioEngine();
      final repository = FakeCollectionRepository();
      final controller = PlaybackController(
        engine,
        library: FakeLibraryRepository(tracks: [track]),
        collection: repository,
        sourceResolver: FakePlaybackSourceResolver(),
        clock: () => _epoch,
      );
      final queue = QueueController(controller);
      addTearDown(() async {
        queue.dispose();
        controller.dispose();
        await engine.dispose();
      });

      await controller.initialize();
      await queue.replace([
        _entry('duplicate-1', track.ref, 0),
        _entry('duplicate-2', track.ref, 1),
      ], currentEntryId: 'duplicate-1');
      await queue.play('duplicate-1');
      await queue.playNext(_entry('inserted', track.ref, 9));
      await queue.move('duplicate-2', 0);

      expect(queue.state.entries.map((entry) => entry.id), [
        'duplicate-2',
        'duplicate-1',
        'inserted',
      ]);
      expect(queue.state.entries.map((entry) => entry.position), [0, 1, 2]);
      expect(controller.state.currentTrack, same(track));
      expect(engine.calls.where((call) => call == 'stop'), isEmpty);

      await queue.remove('duplicate-2');
      expect(controller.state.currentTrack, same(track));
      await queue.remove('duplicate-1');
      expect(engine.calls.where((call) => call == 'stop'), hasLength(1));
      expect(controller.state.currentTrack, isNull);
      expect(queue.state.currentEntryId, 'inserted');
      expect((await repository.loadQueue()).entries.single.id, 'inserted');
      await queue.clear();
      expect(queue.state.entries, isEmpty);
    });

    test(
      'shuffle visits one round and repeat modes govern completion',
      () async {
        final tracks = [_track('a'), _track('b'), _track('c')];
        final engine = FakeAudioEngine();
        final resolver = FakePlaybackSourceResolver();
        final controller = PlaybackController(
          engine,
          library: FakeLibraryRepository(tracks: tracks),
          sourceResolver: resolver,
          clock: () => _epoch,
          randomIndex: (_) => 0,
        );
        addTearDown(() async {
          controller.dispose();
          await engine.dispose();
        });
        await controller.replaceQueue([
          _entry('a', tracks[0].ref, 0),
          _entry('b', tracks[1].ref, 1),
          _entry('c', tracks[2].ref, 2),
        ], currentEntryId: 'a');
        await controller.playEntry('a');
        controller.setShuffleEnabled(true);

        await controller.skipNext();
        await controller.skipNext();
        await controller.skipNext();
        expect(resolver.resolved.map((ref) => ref.trackId), ['a', 'c', 'b']);

        engine.complete();
        await _drain();
        expect(controller.state.phase, PlaybackPhase.completed);
        expect(resolver.resolved, hasLength(3));

        controller.setRepeatMode(RepeatMode.all);
        engine.complete();
        await _drain();
        expect(controller.state.currentTrack?.id, 'c');

        controller.setRepeatMode(RepeatMode.one);
        final loadsBefore = engine.calls.where((call) => call == 'load').length;
        engine.complete();
        await _drain();
        expect(engine.calls, contains('seek:0'));
        expect(
          engine.calls.where((call) => call == 'load'),
          hasLength(loadsBefore),
        );
        expect(controller.state.phase, PlaybackPhase.playing);
      },
    );

    test(
      'maps resolver and engine failures without leaking exception text',
      () async {
        final track = _track('failure');
        final engine = FakeAudioEngine();
        final resolverFailure = DomainFailure(
          code: DomainFailureCode.unauthorized,
          diagnosticId: 'playback.test-unauthorized',
          sourceId: track.sourceId,
        );
        final controller = PlaybackController(
          engine,
          library: FakeLibraryRepository(tracks: [track]),
          sourceResolver: FakePlaybackSourceResolver(failure: resolverFailure),
          clock: () => _epoch,
        );
        addTearDown(() async {
          controller.dispose();
          await engine.dispose();
        });
        await controller.replaceQueue([
          _entry('failure', track.ref, 0),
        ], currentEntryId: 'failure');

        await expectLater(
          controller.playEntry('failure'),
          throwsA(same(resolverFailure)),
        );
        expect(controller.state.phase, PlaybackPhase.error);
        expect(controller.state.failure, same(resolverFailure));

        final secondEngine = FakeAudioEngine()
          ..loadError = StateError(
            'https://secret.invalid/stream Authorization: Bearer leaked',
          );
        final second = PlaybackController(
          secondEngine,
          library: FakeLibraryRepository(tracks: [track]),
          sourceResolver: FakePlaybackSourceResolver(),
          clock: () => _epoch,
        );
        addTearDown(() async {
          second.dispose();
          await secondEngine.dispose();
        });
        await second.replaceQueue([
          _entry('failure', track.ref, 0),
        ], currentEntryId: 'failure');
        await expectLater(
          second.playEntry('failure'),
          throwsA(isA<DomainFailure>()),
        );
        expect(second.state.failure?.code, DomainFailureCode.unknown);
        expect(
          second.state.failure.toString(),
          isNot(contains('secret.invalid')),
        );
        expect(second.state.failure.toString(), isNot(contains('Bearer')));
      },
    );

    test(
      'restores the persisted queue without loading or playing audio',
      () async {
        final track = _track('restored');
        final snapshot = QueueSnapshot(
          entries: [_entry('restored', track.ref, 0)],
          currentEntryId: 'restored',
          updatedAt: _epoch,
        );
        final engine = FakeAudioEngine();
        final controller = PlaybackController(
          engine,
          collection: FakeCollectionRepository(queue: snapshot),
        );
        addTearDown(() async {
          controller.dispose();
          await engine.dispose();
        });

        await controller.initialize();

        expect(controller.state.queue.currentEntryId, 'restored');
        expect(controller.state.currentTrack, isNull);
        expect(controller.state.phase, PlaybackPhase.idle);
        expect(engine.calls, isEmpty);
      },
    );
  });
}

final _epoch = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);

Track _track(String id) => Track(
  id: id,
  sourceId: 'source-rest',
  sourceType: MusicSourceType.rest,
  title: 'Track $id',
  artists: const ['Fixture Artist'],
  duration: const Duration(minutes: 3),
);

QueueEntry _entry(String id, TrackRef track, int position) =>
    QueueEntry(id: id, track: track, position: position, addedAt: _epoch);

DomainFailure _failure(String suffix) => DomainFailure(
  code: DomainFailureCode.unknown,
  diagnosticId: 'playback.test-$suffix',
);

Future<void> _drain() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
