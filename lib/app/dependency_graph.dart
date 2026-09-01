import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/yy_theme.dart';
import '../domain/repositories/collection_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../domain/repositories/lyrics_repository.dart';
import '../domain/repositories/music_source_repository.dart';
import '../platform/contracts/fullscreen_gateway.dart';
import '../platform/contracts/secure_credential_gateway.dart';
import '../playback/audio_engine.dart';
import '../playback/playback_controller.dart';
import '../playback/queue_controller.dart';
import 'app_data_services.dart';
import 'app_view_state.dart';

/// One graph per app scope; a Shell never creates business controllers.
final class DependencyGraph {
  DependencyGraph({
    AudioEngine? audioEngine,
    this.dataServices,
    LibraryRepository? library,
    CollectionRepository? collection,
    LyricsRepository? lyrics,
    MusicSourceRepository? musicSources,
    SecureCredentialGateway? credentials,
    this.fullscreen,
  }) : assert(
         dataServices == null ||
             (library == null &&
                 collection == null &&
                 lyrics == null &&
                 musicSources == null &&
                 credentials == null),
         'Inject either an owned data scope or individual contracts',
       ),
       _audioEngine = audioEngine ?? UnavailableAudioEngine(),
       library = dataServices?.library ?? library,
       collection = dataServices?.collection ?? collection,
       lyrics = dataServices?.lyrics ?? lyrics,
       musicSources = dataServices?.musicSources ?? musicSources,
       credentials = dataServices?.credentials ?? credentials {
    playback = PlaybackController(_audioEngine);
  }

  final AudioEngine _audioEngine;
  final AppDataServices? dataServices;
  final LibraryRepository? library;
  final CollectionRepository? collection;
  final LyricsRepository? lyrics;
  final MusicSourceRepository? musicSources;
  final SecureCredentialGateway? credentials;
  final FullscreenGateway? fullscreen;
  final viewState = AppViewState();
  final appearance = YYAppearanceController();
  final queue = QueueController();
  late final PlaybackController playback;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    playback.dispose();
    queue.dispose();
    appearance.dispose();
    unawaited(_audioEngine.dispose());
    final services = dataServices;
    if (services != null) {
      unawaited(services.dispose());
    } else {
      final repository = library;
      if (repository != null) unawaited(repository.dispose());
    }
  }
}

final dependencyGraphProvider = Provider<DependencyGraph>((ref) {
  final graph = DependencyGraph();
  ref.onDispose(graph.dispose);
  return graph;
});
