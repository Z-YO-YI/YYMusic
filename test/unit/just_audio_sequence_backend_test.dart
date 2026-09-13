import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/audio_sequence.dart';
import 'package:yymusic/playback/just_audio_backend.dart';
import 'package:yymusic/playback/just_audio_engine.dart';
import 'package:yymusic/playback/playable_source.dart';
import 'package:yymusic/playback/playback_controller.dart';

import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _NativeChannelProbe probe;
  late NativeJustAudioPlayerBackend backend;
  late DateTime now;
  final track = TrackRef(
    trackId: 'sequence-fixture',
    sourceId: 'local-fixture',
    sourceType: MusicSourceType.local,
  );
  PlayableSource local(String path) =>
      PlayableSource.localFile(track: track, path: path);
  PlayableSource network({
    Map<String, String> headers = const {},
    DateTime? expiresAt,
  }) => PlayableSource.networkStream(
    track: track,
    uri: Uri.parse('https://example.invalid/fixture.mp3'),
    headers: headers,
    expiresAt: expiresAt,
  );

  setUp(() {
    now = DateTime.utc(2026, 9, 13);
    probe = _NativeChannelProbe()..install();
    backend = NativeJustAudioPlayerBackend.create(
      useProxyForRequestHeaders: false,
      supportsRequestHeaders: false,
      clock: () => now,
    );
  });
  tearDown(() async {
    await backend.dispose();
    probe.uninstall();
  });

  test('expired preflight keeps prior native media usable', () async {
    await backend.openSequence([local('/old.wav')]);
    final id = probe.playerId;
    await expectLater(
      backend.open(network().uri!, headers: const {}, expiresAt: now),
      throwsA(isA<JustAudioSourceExpired>()),
    );
    await expectLater(
      backend.openSequence([network(expiresAt: now)]),
      throwsA(isA<JustAudioSourceExpired>()),
    );
    expect(probe.loads, hasLength(1));
    expect(probe.playerId, id);
    await backend.play();
    expect(backend.current.playing, isTrue);
  });

  for (final sequence in [false, true]) {
    test(
      'expiry during old release rejects dispatch, sequence=$sequence',
      () async {
        await backend.openSequence([local('/old.wav')]);
        final gate = probe.disposeGate = Completer<void>();
        final source = network(expiresAt: now.add(const Duration(seconds: 1)));
        final opening = sequence
            ? backend.openSequence([source])
            : backend.open(
                source.uri!,
                headers: source.headers,
                expiresAt: source.expiresAt,
              );
        final checked = expectLater(
          opening,
          throwsA(isA<JustAudioSourceExpired>()),
        );
        await probe.disposing.future;
        now = now.add(const Duration(seconds: 2));
        gate.complete();
        await checked;
        expect(probe.loads, hasLength(1));
        await expectLater(
          backend.play(),
          throwsA(isA<JustAudioSourceExpired>()),
        );
        await backend.openSequence([local('/recovered.wav')]);
        await backend.play();
        expect(probe.loads, hasLength(2));
        expect(backend.current.playing, isTrue);
      },
    );

    test(
      'expiry during native load remains locked, sequence=$sequence',
      () async {
        final gate = probe.loadGate = Completer<void>();
        final source = network(expiresAt: now.add(const Duration(seconds: 1)));
        final opening = sequence
            ? backend.openSequence([source])
            : backend.open(
                source.uri!,
                headers: source.headers,
                expiresAt: source.expiresAt,
              );
        final checked = expectLater(
          opening,
          throwsA(isA<JustAudioSourceExpired>()),
        );
        await probe.loading.future;
        now = now.add(const Duration(seconds: 2));
        gate.complete();
        await checked;
        expect(backend.current.playing, isFalse);
        now = now.subtract(const Duration(minutes: 1));
        await expectLater(
          backend.play(),
          throwsA(isA<JustAudioSourceExpired>()),
        );
        expect(probe.calls, isNot(contains('play')));
      },
    );
  }

  test('append acknowledgement after expiry cannot succeed', () async {
    await backend.openSequence([local('/first.wav')]);
    final gate = probe.insertGate = Completer<void>();
    final appending = expectLater(
      backend.appendSequence([
        network(expiresAt: now.add(const Duration(seconds: 1))),
      ], expectedLength: 1),
      throwsA(isA<JustAudioSourceExpired>()),
    );
    await probe.inserting.future;
    now = now.add(const Duration(seconds: 2));
    gate.complete();
    await appending;
    await expectLater(backend.play(), throwsA(isA<JustAudioSourceExpired>()));
  });

  test('expired append preflight does not poison existing source', () async {
    await backend.openSequence([local('/first.wav')]);
    await expectLater(
      backend.appendSequence([network(expiresAt: now)], expectedLength: 1),
      throwsA(isA<JustAudioSourceExpired>()),
    );
    expect(probe.insertions, isEmpty);
    await backend.play();
    expect(backend.current.playing, isTrue);
  });

  test(
    'seek acknowledgement after expiry cannot leave source playable',
    () async {
      await backend.openSequence([
        network(expiresAt: now.add(const Duration(seconds: 1))),
      ]);
      final gate = probe.seekGate = Completer<void>();
      final seeking = expectLater(
        backend.seek(const Duration(seconds: 2)),
        throwsA(isA<JustAudioSourceExpired>()),
      );
      await probe.seeking.future;
      now = now.add(const Duration(seconds: 2));
      gate.complete();
      await seeking;
      await expectLater(backend.play(), throwsA(isA<JustAudioSourceExpired>()));
    },
  );

  test('native expiry maps to safe engine domain failure', () async {
    final engine = JustAudioEngine(backend, clock: () => now);
    addTearDown(engine.dispose);
    final states = <AudioEngineState>[];
    engine.states.listen(states.add);
    final gate = probe.loadGate = Completer<void>();
    final loading = expectLater(
      engine.load(network(expiresAt: now.add(const Duration(seconds: 1)))),
      throwsA(
        isA<DomainFailure>().having(
          (value) => value.code,
          'code',
          DomainFailureCode.streamUrlExpired,
        ),
      ),
    );
    await probe.loading.future;
    now = now.add(const Duration(seconds: 2));
    gate.complete();
    await loading;
    expect(states.last.failure!.code, DomainFailureCode.streamUrlExpired);
    expect(states.last.failure.toString(), isNot(contains('example.invalid')));
    expect(states.last.sequenceCursor, isNull);
  });

  test('native play rejects expired loaded source through engine', () async {
    final engine = JustAudioEngine(backend, clock: () => now);
    addTearDown(engine.dispose);
    await engine.load(network(expiresAt: now.add(const Duration(seconds: 1))));
    now = now.add(const Duration(seconds: 2));
    await expectLater(
      engine.play(),
      throwsA(
        isA<DomainFailure>().having(
          (value) => value.code,
          'code',
          DomainFailureCode.streamUrlExpired,
        ),
      ),
    );
    expect(probe.calls, isNot(contains('play')));
  });

  test(
    'native channel index maps through production engine to batch and entry',
    () async {
      final engine = JustAudioEngine(backend);
      addTearDown(engine.dispose);
      final states = <AudioEngineState>[];
      engine.states.listen(states.add);
      final source = local('/same.wav');
      final sequence = AudioSequence([
        AudioSequenceEntry(entryId: 'occurrence-a', source: source),
        AudioSequenceEntry(entryId: 'occurrence-b', source: source),
      ]);
      await engine.loadSequence(sequence);
      expect(states.last.sequenceCursor!.entryId, 'occurrence-a');
      final transitioned = engine.states
          .firstWhere(
            (state) => state.sequenceCursor?.entryId == 'occurrence-b',
          )
          .timeout(const Duration(seconds: 3));
      await probe.emit(1);
      final state = await transitioned;
      expect(
        identical(state.sequenceCursor!.sequenceIdentity, sequence.identity),
        isTrue,
      );
      expect(state.sequenceCursor!.track, track);
      expect(state.position, Duration.zero);
      expect(state.failure, isNull);
      expect(probe.loads, hasLength(1));
      expect(probe.calls, isNot(contains('play')));
      await engine.stop();
      expect(states.last.sequenceCursor, isNull);
    },
  );

  test(
    'replacing a batch changes native ID and ignores old index/error events',
    () async {
      await backend.openSequence([local('/a.wav'), local('/b.wav')]);
      final oldId = probe.playerId!;
      await backend.openSequence([local('/new.wav'), local('/new2.wav')]);
      final newId = probe.playerId!;
      expect(newId, isNot(oldId));
      expect(probe.lifecycle, ['init:$oldId', 'dispose:$oldId', 'init:$newId']);
      final errors = <void>[];
      final subscription = backend.errors.listen(errors.add);
      addTearDown(subscription.cancel);
      await probe.emit(1, id: oldId);
      await probe.emitError(oldId);
      expect(backend.current.currentIndex, 0);
      expect(errors, isEmpty);
      final changed = backend.snapshots
          .firstWhere((state) => state.currentIndex == 1)
          .timeout(const Duration(seconds: 3));
      await probe.emit(1);
      await changed;
      expect(probe.playerId, newId);
      expect(probe.loads, hasLength(2));
    },
  );

  test('sequence replacement restores volume and speed without play', () async {
    await backend.openSequence([local('/a.wav')]);
    await backend.setVolume(0.35);
    await backend.setSpeed(1.25);
    await backend.openSequence([local('/b.wav')]);
    expect(backend.current.volume, 0.35);
    expect(backend.current.speed, 1.25);
    expect(backend.current.playing, isFalse);
    expect(probe.calls, isNot(contains('play')));
  });

  test(
    'single-to-sequence and sequence-to-single also isolate native IDs',
    () async {
      await backend.open(Uri.file('/single.wav'), headers: const {});
      final firstId = probe.playerId;
      await backend.openSequence([local('/sequence.wav')]);
      final secondId = probe.playerId;
      await backend.open(Uri.file('/last.wav'), headers: const {});
      expect({firstId, secondId, probe.playerId}, hasLength(3));
      expect(probe.loads, hasLength(3));
    },
  );

  test(
    'unsupported replacement retains the native player and loaded media',
    () async {
      await backend.openSequence([local('/keep.wav')]);
      final id = probe.playerId;
      await expectLater(
        backend.openSequence([
          network(headers: {'X-Fixture': 'rejected'}),
        ]),
        throwsUnsupportedError,
      );
      expect(probe.playerId, id);
      expect(probe.lifecycle, ['init:$id']);
      expect(probe.loads, hasLength(1));
    },
  );

  test(
    'pause failure does not create a replacement or permit later playback',
    () async {
      await backend.openSequence([local('/old.wav')]);
      await backend.play();
      final id = probe.playerId;
      probe.failPause = true;
      await expectLater(
        backend.openSequence([local('/new.wav')]),
        throwsStateError,
      );
      expect(probe.playerId, id);
      expect(probe.loads, hasLength(1));
      await expectLater(
        backend.openSequence([local('/retry.wav')]),
        throwsStateError,
      );
      await expectLater(backend.play(), throwsStateError);
      expect(probe.loads, hasLength(1));
      probe.failPause = false;
    },
  );

  test(
    'close during old player release never creates the replacement',
    () async {
      await backend.openSequence([local('/old.wav')]);
      final id = probe.playerId;
      probe.disposeGate = Completer<void>();
      final replacing = backend.openSequence([local('/new.wav')]);
      final rejected = expectLater(replacing, throwsStateError);
      await probe.disposing.future.timeout(const Duration(seconds: 3));
      final closed = backend.dispose();
      probe.disposeGate!.complete();
      await rejected;
      await closed;
      expect(probe.playerId, id);
      expect(probe.loads, hasLength(1));
    },
  );

  test('late old play-request failure cannot poison a replacement', () async {
    await backend.openSequence([local('/old.wav')]);
    probe.playGate = Completer<void>();
    await backend.play();
    await probe.playing.future.timeout(const Duration(seconds: 3));
    await backend.openSequence([local('/new.wav')]);
    final errors = <void>[];
    final subscription = backend.errors.listen(errors.add);
    addTearDown(subscription.cancel);
    probe.playGate!.completeError(
      PlatformException(code: 'fixture', message: 'private-old-play'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(errors, isEmpty);
    expect(backend.current.currentIndex, 0);
    expect(backend.current.playing, isFalse);
  });

  test(
    'pinned plugin hides release failure despite acknowledged pause',
    () async {
      await backend.openSequence([local('/old.wav')]);
      await backend.play();
      final oldId = probe.playerId;
      probe.failDispose = true;
      await backend.openSequence([local('/new.wav')]);
      expect(probe.calls, contains('pause'));
      expect(probe.calls, contains('dispose'));
      expect(probe.playerId, isNot(oldId));
      expect(backend.current.playing, isFalse);
      // Successful public dispose does NOT prove successful native resource release.
      probe.failDispose = false;
    },
  );

  test(
    'native boundary removes only tail without replacing or pausing current',
    () async {
      await backend.openSequence([
        local('/a.wav'),
        local('/b.wav'),
        local('/c.wav'),
      ], initialIndex: 1);
      await backend.play();
      final id = probe.playerId;
      final offset = probe.calls.length;
      expect(await backend.retainSequenceThrough(1), isTrue);
      expect(probe.removals.single['startIndex'], 2);
      expect(probe.removals.single['endIndex'], 3);
      expect(probe.playerId, id);
      expect(probe.loads, hasLength(1));
      expect(probe.calls.skip(offset), ['concatenatingRemoveRange']);
      expect(backend.current.currentIndex, 1);
      expect(backend.current.playing, isTrue);
      expect(await backend.retainSequenceThrough(1), isTrue);
      expect(probe.removals, hasLength(1));
    },
  );

  test('stale native boundary is a no-op and closed backend rejects', () async {
    await backend.openSequence([local('/a.wav'), local('/b.wav')]);
    for (final index in [-1, 1, 2]) {
      expect(await backend.retainSequenceThrough(index), isFalse);
    }
    expect(probe.removals, isEmpty);
    await backend.dispose();
    await expectLater(backend.retainSequenceThrough(0), throwsStateError);
  });

  test('native boundary failure is redacted', () async {
    await backend.openSequence([local('/a.wav'), local('/b.wav')]);
    probe.failRemove = true;
    await expectLater(
      backend.retainSequenceThrough(0),
      throwsA(
        isA<StateError>().having(
          (e) => e.toString(),
          'safe error',
          'Bad state: Audio sequence boundary could not be applied',
        ),
      ),
    );
  });

  for (final returnsToOriginal in [false, true]) {
    test(
      'native transition during boundary edit fails, returns=$returnsToOriginal',
      () async {
        final engine = JustAudioEngine(backend);
        addTearDown(engine.dispose);
        final states = <AudioEngineState>[];
        engine.states.listen(states.add);
        await engine.loadSequence(
          AudioSequence([
            AudioSequenceEntry(entryId: 'a', source: local('/a.wav')),
            AudioSequenceEntry(entryId: 'b', source: local('/b.wav')),
          ]),
        );
        probe.removeGate = Completer<void>();
        final editing = engine.retainSequenceThrough(
          states.last.sequenceCursor!,
        );
        final rejected = expectLater(editing, throwsA(isA<DomainFailure>()));
        await probe.removing.future.timeout(const Duration(seconds: 3));
        await probe.emit(1);
        await Future<void>.delayed(Duration.zero);
        if (returnsToOriginal) {
          await probe.emit(0);
          await Future<void>.delayed(Duration.zero);
        }
        probe.removeGate!.complete();
        await rejected;
        expect(states.last.phase, AudioEnginePhase.error);
        expect(states.last.sequenceCursor, isNull);
        expect(
          states.last.failure!.diagnosticId,
          'audio.just-audio.sequence-boundary',
        );
      },
    );
  }

  test(
    'native channel reaches root queue adoption and continuation tail control',
    () async {
      final media = Track(
        id: track.trackId,
        sourceId: track.sourceId,
        sourceType: track.sourceType,
        title: 'Native fixture',
        artists: const ['Fixture'],
        duration: const Duration(seconds: 10),
        localPath: '/native-fixture.wav',
      );
      final library = FakeLibraryRepository(tracks: [media]);
      final collection = FakeCollectionRepository();
      final engine = JustAudioEngine(backend);
      final root = PlaybackController(
        engine,
        library: library,
        collection: collection,
        sourceResolver: FakePlaybackSourceResolver(),
      );
      addTearDown(() async {
        await root.close();
        await engine.dispose();
        await library.dispose();
        await collection.dispose();
      });
      await root.initialize();
      await root.replaceQueue([
        for (var i = 0; i < 3; i++)
          QueueEntry(
            id: 'native-$i',
            track: media.ref,
            position: i,
            addedAt: DateTime.utc(2026),
          ),
      ], currentEntryId: 'native-0');
      await root.playNativeSequence('native-0');
      final id = probe.playerId;
      final moved = Completer<void>();
      root.addListener(() {
        if (root.state.queue.currentEntryId == 'native-1' &&
            !moved.isCompleted) {
          moved.complete();
        }
      });
      await probe.emit(1);
      await moved.future.timeout(const Duration(seconds: 3));
      expect((await collection.loadQueue()).currentEntryId, 'native-1');
      expect(root.state.currentTrack!.ref, media.ref);
      root.setContinueAfterTrack(false);
      await probe.removing.future.timeout(const Duration(seconds: 3));
      expect(probe.removals.single['startIndex'], 2);
      expect(probe.removals.single['endIndex'], 3);
      expect(probe.loads, hasLength(1));
      expect(probe.playerId, id);
      expect(backend.current.playing, isTrue);
    },
  );

  test(
    'append dispatches insertion without replacing player or playing',
    () async {
      await backend.openSequence([local('/a.wav'), local('/b.wav')]);
      final id = probe.playerId;
      expect(
        await backend.appendSequence([local('/c.wav')], expectedLength: 2),
        isTrue,
      );
      expect(probe.insertions.single['index'], 2);
      expect(probe.insertions.single['children'] as List, hasLength(1));
      expect(probe.loads, hasLength(1));
      expect(probe.playerId, id);
      expect(probe.calls, isNot(contains('play')));
      expect(
        await backend.appendSequence([local('/d.wav')], expectedLength: 2),
        isFalse,
      );
      expect(probe.insertions, hasLength(1));
    },
  );

  test('loads ordered sources once without issuing play', () async {
    await backend.openSequence([
      local(r'C:\Music\a tone.wav'),
      PlayableSource.contentUri(
        track: track,
        uri: Uri.parse('content://media/external/audio/media/12'),
      ),
      network(),
    ], initialIndex: 1);
    expect(probe.loads, hasLength(1));
    final load = probe.loads.single;
    expect(load['initialIndex'], 1);
    expect(load['initialPosition'], 0);
    final sequence = load['audioSource'] as Map;
    expect(sequence['type'], 'concatenating');
    final children = sequence['children'] as List;
    expect(children.map((dynamic e) => (e as Map)['uri']), [
      'file:///C:/Music/a%20tone.wav',
      'content://media/external/audio/media/12',
      'https://example.invalid/fixture.mp3',
    ]);
    expect(probe.calls, isNot(contains('play')));
    expect(backend.current.playing, isFalse);
    expect(backend.current.currentIndex, 1);
  });

  test(
    'native index-only transition reaches snapshots without a reload',
    () async {
      await backend.openSequence([local('/a.wav'), local('/b.wav')]);
      final observed = backend.snapshots
          .firstWhere((state) => state.currentIndex == 1)
          .timeout(const Duration(seconds: 3));
      await probe.emit(1);
      expect((await observed).currentIndex, 1);
      expect(probe.loads, hasLength(1));
      expect(probe.calls, isNot(contains('play')));
    },
  );

  for (final index in [-1, 1]) {
    test(
      'invalid initial index $index does not replace loaded media',
      () async {
        await backend.openSequence([local('/keep.wav')]);
        final before = probe.calls.length;
        await expectLater(
          backend.openSequence([local('/reject.wav')], initialIndex: index),
          throwsArgumentError,
        );
        expect(probe.calls.length, before);
        expect(probe.loads, hasLength(1));
      },
    );
  }

  test('empty sequence is rejected before native dispatch', () async {
    await expectLater(backend.openSequence([]), throwsArgumentError);
    expect(probe.loads, isEmpty);
  });

  test('later unsupported headers reject the entire batch', () async {
    await expectLater(
      backend.openSequence([
        local('/first.wav'),
        network(headers: {'X-Fixture': 'fixture-value'}),
      ]),
      throwsUnsupportedError,
    );
    expect(probe.loads, isEmpty);
  });

  test('accepted headers and source list are snapshots', () async {
    await backend.dispose();
    backend = NativeJustAudioPlayerBackend.create(
      useProxyForRequestHeaders: false,
      supportsRequestHeaders: true,
    );
    final headers = {'X-Fixture': 'original'};
    final sources = [network(headers: headers), local('/last.wav')];
    final loading = backend.openSequence(sources);
    headers['X-Fixture'] = 'changed';
    sources.clear();
    await loading;
    final sequence = probe.loads.single['audioSource'] as Map;
    final children = sequence['children'] as List;
    expect(children, hasLength(2));
    expect((children.first as Map)['headers'], {'X-Fixture': 'original'});
  });

  test('UNC and POSIX paths preserve resource encoding', () async {
    await backend.openSequence([
      local(r'\\server\music\a #.wav'),
      local('/music/b #.wav'),
    ]);
    final sequence = probe.loads.single['audioSource'] as Map;
    final children = sequence['children'] as List;
    expect(children.map((dynamic e) => (e as Map)['uri']), [
      'file://server/music/a%20%23.wav',
      'file:///music/b%20%23.wav',
    ]);
  });

  test('single-source open resets sequence and native index', () async {
    await backend.openSequence([
      local('/a.wav'),
      local('/b.wav'),
    ], initialIndex: 1);
    await backend.open(Uri.file('/single.wav'), headers: const {});
    final sequence = probe.loads.last['audioSource'] as Map;
    expect(sequence['children'] as List, hasLength(1));
    expect(backend.current.currentIndex, 0);
  });

  test('native load error is redacted and a later load can succeed', () async {
    probe.failLoad = true;
    await expectLater(
      backend.openSequence([network()]),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'safe message',
          'Bad state: Audio sequence could not be loaded',
        ),
      ),
    );
    probe.failLoad = false;
    await backend.openSequence([local('/recovered.wav')]);
    expect(backend.current.currentIndex, 0);
    expect(backend.current.playing, isFalse);
  });

  test('disposed backend rejects sequence without native calls', () async {
    await backend.dispose();
    final count = probe.calls.length;
    await expectLater(
      backend.openSequence([local('/closed.wav')]),
      throwsStateError,
    );
    expect(probe.calls.length, count);
  });
}

/// Exercises the actual pinned just_audio implementation up to its platform
/// channels; it does not synthesize acoustic evidence or call a native player.
final class _NativeChannelProbe {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];
  final loads = <Map<Object?, Object?>>[];
  final channels = <String>[];
  String? playerId;
  bool failLoad = false;
  bool failDispose = false;
  bool failPause = false;
  Completer<void>? disposeGate;
  Completer<void>? playGate;
  final playing = Completer<void>();
  final disposing = Completer<void>();
  final lifecycle = <String>[];
  final removals = <Map<Object?, Object?>>[];
  final insertions = <Map<Object?, Object?>>[];
  final loading = Completer<void>();
  final inserting = Completer<void>();
  final seeking = Completer<void>();
  Completer<void>? loadGate;
  Completer<void>? insertGate;
  Completer<void>? seekGate;
  final removing = Completer<void>();
  Completer<void>? removeGate;
  bool failRemove = false;

  void register(String name, Future<Object?> Function(MethodCall) handler) {
    channels.add(name);
    messenger.setMockMethodCallHandler(MethodChannel(name), handler);
  }

  void install() {
    register('com.ryanheise.audio_session', (_) async => null);
    register('com.ryanheise.just_audio.methods', (call) async {
      if (call.method == 'init') {
        playerId = (call.arguments as Map)['id'] as String;
        lifecycle.add('init:$playerId');
        register(
          'com.ryanheise.just_audio.events.$playerId',
          (_) async => null,
        );
        register('com.ryanheise.just_audio.data.$playerId', (_) async => null);
        register('com.ryanheise.just_audio.methods.$playerId', (request) async {
          calls.add(request.method);
          if (request.method == 'seek') {
            if (!seeking.isCompleted) seeking.complete();
            if (seekGate != null) await seekGate!.future;
          }
          if (request.method == 'concatenatingInsertAll') {
            if (!inserting.isCompleted) inserting.complete();
            if (insertGate != null) await insertGate!.future;
            insertions.add(
              Map<Object?, Object?>.from(request.arguments as Map),
            );
          }
          if (request.method == 'concatenatingRemoveRange') {
            removals.add(Map<Object?, Object?>.from(request.arguments as Map));
            if (!removing.isCompleted) removing.complete();
            if (removeGate != null) await removeGate!.future;
            if (failRemove) {
              throw PlatformException(
                code: 'fixture',
                message: 'private-remove',
              );
            }
          }
          if (request.method == 'play') {
            if (!playing.isCompleted) playing.complete();
            if (playGate != null) await playGate!.future;
          }
          if (request.method == 'pause' && failPause) {
            throw PlatformException(code: 'fixture', message: 'private-pause');
          }
          if (request.method == 'dispose' && failDispose) {
            throw PlatformException(
              code: 'fixture',
              message: 'private-fallback-release',
            );
          }
          if (request.method == 'load') {
            final args = Map<Object?, Object?>.from(request.arguments as Map);
            loads.add(args);
            if (!loading.isCompleted) loading.complete();
            if (loadGate != null) await loadGate!.future;
            if (failLoad) {
              throw PlatformException(
                code: 'fixture',
                message: 'private-locator',
              );
            }
            await emit(args['initialIndex'] as int? ?? 0);
            return {'duration': 10000000};
          }
          return <String, Object?>{};
        });
      }
      if (call.method == 'disposePlayer') {
        final id = (call.arguments as Map)['id'] as String;
        lifecycle.add('dispose:$id');
        if (!disposing.isCompleted) disposing.complete();
        if (disposeGate != null) await disposeGate!.future;
        if (failDispose) {
          throw PlatformException(code: 'fixture', message: 'private-release');
        }
      }
      return <String, Object?>{};
    });
  }

  Future<void> emit(int index, {String? id}) async {
    await messenger.handlePlatformMessage(
      'com.ryanheise.just_audio.events.${id ?? playerId}',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'processingState': 3,
        'updateTime': DateTime.now().millisecondsSinceEpoch,
        'updatePosition': 0,
        'bufferedPosition': 0,
        'duration': 10000000,
        'currentIndex': index,
      }),
      (_) {},
    );
  }

  Future<void> emitError(String id) async {
    await messenger.handlePlatformMessage(
      'com.ryanheise.just_audio.events.$id',
      const StandardMethodCodec().encodeErrorEnvelope(
        code: 'fixture',
        message: 'private-old-error',
      ),
      (_) {},
    );
  }

  void uninstall() {
    for (final name in channels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
  }
}
