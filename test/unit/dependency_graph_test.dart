import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/fake_audio_engine.dart';

void main() {
  test('one graph per scope and unavailable production backend', () async {
    final scope = ProviderContainer();
    addTearDown(scope.dispose);
    final graph = scope.read(dependencyGraphProvider);
    expect(scope.read(dependencyGraphProvider), same(graph));
    expect(graph.playback.isAvailable, isFalse);
    expect(graph.playback.state.phase, PlaybackPhase.unavailable);
    expect(graph.queue.isAvailable, isFalse);
    expect(graph.library, isNull);
    expect(graph.collection, isNull);
    expect(graph.lyrics, isNull);
    expect(graph.musicSources, isNull);
    expect(graph.credentials, isNull);
    expect(graph.fullscreen, isNull);
    await expectLater(graph.playback.play(), throwsUnsupportedError);
    expect(graph.playback.state.phase, PlaybackPhase.unavailable);
  });

  test(
    'engine events drive shared state and graph disposes exactly once',
    () async {
      final engine = FakeAudioEngine();
      final graph = DependencyGraph(audioEngine: engine);
      engine.events.add(
        const PlaybackState(
          phase: PlaybackPhase.paused,
          position: Duration(seconds: 19),
        ),
      );
      expect(graph.playback.state.position, const Duration(seconds: 19));
      engine.events.addError(StateError('test failure'), StackTrace.current);
      expect(graph.playback.state.phase, PlaybackPhase.error);
      graph.dispose();
      graph.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(engine.disposalCount, 1);
      expect(engine.events.hasListener, isFalse);
    },
  );

  test('view selections and offsets are shared but route-specific', () {
    final graph = DependencyGraph();
    addTearDown(graph.dispose);
    graph.viewState.saveScrollOffset(AppRoute.library, 182);
    graph.viewState.select(AppRoute.library, 'test-only-id');
    expect(graph.viewState.scrollOffset(AppRoute.library), 182);
    expect(graph.viewState.scrollOffset(AppRoute.search), 0);
    expect(graph.viewState.selection(AppRoute.library), 'test-only-id');
    graph.viewState.select(AppRoute.library, null);
    expect(graph.viewState.selection(AppRoute.library), isNull);
    expect(
      () => graph.viewState.saveScrollOffset(AppRoute.home, double.nan),
      throwsArgumentError,
    );
  });
}
