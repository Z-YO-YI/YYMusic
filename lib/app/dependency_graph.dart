import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/library_repository.dart';
import '../platform/contracts/fullscreen_gateway.dart';
import '../playback/audio_engine.dart';
import '../playback/playback_controller.dart';
import '../playback/queue_controller.dart';
import 'app_view_state.dart';

/// One graph per app scope; a Shell never creates business controllers.
final class DependencyGraph {
  DependencyGraph({AudioEngine? audioEngine, this.library, this.fullscreen})
    : _audioEngine = audioEngine ?? UnavailableAudioEngine() {
    playback = PlaybackController(_audioEngine);
  }

  final AudioEngine _audioEngine;
  final LibraryRepository? library;
  final FullscreenGateway? fullscreen;
  final viewState = AppViewState();
  final queue = QueueController();
  late final PlaybackController playback;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    playback.dispose();
    queue.dispose();
    unawaited(_audioEngine.dispose());
    final repository = library;
    if (repository != null) unawaited(repository.dispose());
  }
}

final dependencyGraphProvider = Provider<DependencyGraph>((ref) {
  final graph = DependencyGraph();
  ref.onDispose(graph.dispose);
  return graph;
});
