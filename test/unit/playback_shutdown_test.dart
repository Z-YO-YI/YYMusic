import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/domain_failure.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  test('close drains in-flight load before engine and data disposal, without late play', () async {
    final gate = Completer<void>();
    final engine = FakeAudioEngine()..loadGate = gate.future;
    final library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    final graph = DependencyGraph(
      audioEngine: engine,
      library: library,
      playbackSourceResolver: FakePlaybackSourceResolver(),
    );
    await graph.queue.replace([playbackFixtureEntry()]);
    final playCheck = expectLater(
      graph.playback.play(),
      throwsA(isA<DomainFailure>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(engine.calls, ['load']);
    final close = graph.close();
    expect(graph.close(), same(close));
    graph.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(engine.disposalCount, 0);
    expect(library.disposeCount, 0);
    gate.complete();
    await playCheck;
    await close;
    expect(engine.calls, ['load']);
    expect(engine.disposalCount, 1);
    expect(library.disposeCount, 1);
    await expectLater(graph.playback.play(), throwsStateError);
  });

  test(
    'close waits for active media metadata before disposing session and data',
    () async {
      final gate = Completer<void>();
      final engine = FakeAudioEngine();
      final media = FakeMediaSessionGateway()..metadataGate = gate.future;
      final library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
      final graph = DependencyGraph(
        audioEngine: engine,
        library: library,
        mediaSession: media,
        playbackSourceResolver: FakePlaybackSourceResolver(),
      );
      await graph.initialize();
      await graph.queue.replace([playbackFixtureEntry()]);
      await graph.playback.play();
      await Future<void>.delayed(Duration.zero);
      expect(media.calls, contains('metadata'));
      final statesBefore = media.states.length;
      final close = graph.close();
      await Future<void>.delayed(Duration.zero);
      expect(media.disposalCount, 0);
      expect(library.disposeCount, 0);
      gate.complete();
      await close;
      expect(media.states.length, statesBefore);
      expect(media.disposalCount, 1);
      expect(engine.disposalCount, 1);
      expect(library.disposeCount, 1);
    },
  );

  test(
    'all owned resources close even after failures and only safe error escapes',
    () async {
      final engine = FakeAudioEngine()
        ..disposeError = StateError('private-engine-marker');
      final media = FakeMediaSessionGateway()
        ..disposeError = StateError('private-media-marker');
      final library = FakeLibraryRepository();
      final graph = DependencyGraph(
        audioEngine: engine,
        mediaSession: media,
        library: library,
      );
      final close = graph.close();
      await expectLater(
        close,
        throwsA(
          isA<DomainFailure>()
              .having(
                (error) => error.diagnosticId,
                'diagnostic',
                'app.shutdown-failed',
              )
              .having(
                (error) => error.toString(),
                'redacted',
                isNot(contains('private-')),
              ),
        ),
      );
      expect(graph.close(), same(close));
      graph.dispose();
      expect(engine.disposalCount, 1);
      expect(media.disposalCount, 1);
      expect(library.disposeCount, 1);
    },
  );
}
