import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/audio_sequence.dart';
import 'package:yymusic/playback/just_audio_backend.dart';
import 'package:yymusic/playback/just_audio_engine.dart';
import 'package:yymusic/playback/playable_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _NativeChannelProbe probe;
  late NativeJustAudioPlayerBackend backend;
  final track = TrackRef(
    trackId: 'sequence-fixture',
    sourceId: 'local-fixture',
    sourceType: MusicSourceType.local,
  );
  PlayableSource local(String path) =>
      PlayableSource.localFile(track: track, path: path);
  PlayableSource network({Map<String, String> headers = const {}}) =>
      PlayableSource.networkStream(
        track: track,
        uri: Uri.parse('https://example.invalid/fixture.mp3'),
        headers: headers,
      );

  setUp(() {
    probe = _NativeChannelProbe()..install();
    backend = NativeJustAudioPlayerBackend.create(
      useProxyForRequestHeaders: false,
      supportsRequestHeaders: false,
    );
  });
  tearDown(() async {
    await backend.dispose();
    probe.uninstall();
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

  void register(String name, Future<Object?> Function(MethodCall) handler) {
    channels.add(name);
    messenger.setMockMethodCallHandler(MethodChannel(name), handler);
  }

  void install() {
    register('com.ryanheise.audio_session', (_) async => null);
    register('com.ryanheise.just_audio.methods', (call) async {
      if (call.method == 'init') {
        playerId = (call.arguments as Map)['id'] as String;
        register(
          'com.ryanheise.just_audio.events.$playerId',
          (_) async => null,
        );
        register('com.ryanheise.just_audio.data.$playerId', (_) async => null);
        register('com.ryanheise.just_audio.methods.$playerId', (request) async {
          calls.add(request.method);
          if (request.method == 'load') {
            final args = Map<Object?, Object?>.from(request.arguments as Map);
            loads.add(args);
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
      return <String, Object?>{};
    });
  }

  Future<void> emit(int index) async {
    await messenger.handlePlatformMessage(
      'com.ryanheise.just_audio.events.$playerId',
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

  void uninstall() {
    for (final name in channels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
  }
}
