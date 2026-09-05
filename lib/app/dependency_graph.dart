import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/yy_theme.dart';
import '../domain/models/domain_failure.dart';
import '../domain/repositories/catalog_search_repository.dart';
import '../domain/repositories/collection_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../domain/repositories/license_repository.dart';
import '../domain/repositories/lyrics_repository.dart';
import '../domain/repositories/music_source_repository.dart';
import '../domain/repositories/search_history_repository.dart';
import '../features/home/common/home_controller.dart';
import '../features/search/common/search_controller.dart';
import '../platform/contracts/fullscreen_gateway.dart';
import '../platform/contracts/media_session_gateway.dart';
import '../platform/contracts/secure_credential_gateway.dart';
import '../playback/audio_engine.dart';
import '../playback/playback_controller.dart';
import '../playback/playback_source_resolver.dart';
import '../playback/queue_controller.dart';
import 'app_data_services.dart';
import 'app_view_state.dart';
import 'flutter_license_repository.dart';
import 'playback_presenter.dart';

/// One graph per app scope; a Shell never creates business controllers.
final class DependencyGraph {
  DependencyGraph({
    AudioEngine? audioEngine,
    PlaybackSourceResolver? playbackSourceResolver,
    MediaSessionGateway? mediaSession,
    this.dataServices,
    LibraryRepository? library,
    CatalogSearchRepository? catalogSearch,
    SearchHistoryRepository? searchHistory,
    CollectionRepository? collection,
    LyricsRepository? lyrics,
    MusicSourceRepository? musicSources,
    SecureCredentialGateway? credentials,
    this.fullscreen,
    this.licenses = const FlutterLicenseRepository(),
  }) : assert(
         dataServices == null ||
             (library == null &&
                 catalogSearch == null &&
                 searchHistory == null &&
                 collection == null &&
                 lyrics == null &&
                 musicSources == null &&
                 credentials == null),
         'Inject either an owned data scope or individual contracts',
       ),
       _audioEngine = audioEngine ?? UnavailableAudioEngine(),
       _mediaSession = mediaSession ?? const UnavailableMediaSessionGateway(),
       library = dataServices?.library ?? library,
       catalogSearch = dataServices?.catalogSearch ?? catalogSearch,
       searchHistory = dataServices?.searchHistory ?? searchHistory,
       collection = dataServices?.collection ?? collection,
       lyrics = dataServices?.lyrics ?? lyrics,
       musicSources = dataServices?.musicSources ?? musicSources,
       credentials = dataServices?.credentials ?? credentials {
    playback = PlaybackController(
      _audioEngine,
      library: this.library,
      collection: this.collection,
      sourceResolver: playbackSourceResolver,
      mediaSession: _mediaSession,
    );
    queue = QueueController(playback);
    playbackPresenter = PlaybackPresenter(playback);
    home = HomeController(
      playback: playback,
      library: this.library,
      collection: this.collection,
      sourceRepository: this.musicSources,
    );
    search = CatalogSearchController(
      playback: playback,
      repository: this.catalogSearch,
      historyRepository: this.searchHistory,
      sourceRepository: this.musicSources,
    );
  }

  final AudioEngine _audioEngine;
  final MediaSessionGateway _mediaSession;
  final AppDataServices? dataServices;
  final LibraryRepository? library;
  final CatalogSearchRepository? catalogSearch;
  final SearchHistoryRepository? searchHistory;
  final CollectionRepository? collection;
  final LyricsRepository? lyrics;
  final MusicSourceRepository? musicSources;
  final SecureCredentialGateway? credentials;
  final FullscreenGateway? fullscreen;
  final LicenseRepository licenses;
  final viewState = AppViewState();
  final appearance = YYAppearanceController();
  late final PlaybackController playback;
  late final QueueController queue;
  late final PlaybackPresenter playbackPresenter;
  late final HomeController home;
  late final CatalogSearchController search;
  Future<void>? _closeFuture;

  Future<void> initialize() => playback.initialize();

  void dispose() {
    unawaited(close().catchError((Object _) {}));
  }

  /// Stops commands immediately and drains users of data before closing storage.
  Future<void> close() {
    final existing = _closeFuture;
    if (existing != null) return existing;
    queue.dispose();
    home.dispose();
    search.dispose();
    playbackPresenter.dispose();
    playback.dispose();
    appearance.dispose();
    return _closeFuture = _closeOwnedResources();
  }

  Future<void> _closeOwnedResources() async {
    var failed = false;
    for (final release in <Future<void> Function()>[
      home.close,
      search.close,
      playback.close,
      _audioEngine.dispose,
      _mediaSession.dispose,
      if (dataServices case final services?)
        services.dispose
      else if (library case final repository?)
        repository.dispose,
    ]) {
      try {
        await release();
      } catch (_) {
        failed = true;
      }
    }
    if (failed) {
      throw DomainFailure(
        code: DomainFailureCode.unknown,
        diagnosticId: 'app.shutdown-failed',
      );
    }
  }
}

final dependencyGraphProvider = Provider<DependencyGraph>((ref) {
  final graph = DependencyGraph();
  ref.onDispose(graph.dispose);
  return graph;
});
