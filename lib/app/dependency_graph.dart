import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/yy_theme.dart';
import '../domain/models/domain_failure.dart';
import '../domain/repositories/appearance_settings_repository.dart';
import '../domain/repositories/catalog_browse_repository.dart';
import '../domain/repositories/catalog_search_repository.dart';
import '../domain/repositories/collection_repository.dart';
import '../domain/repositories/library_repository.dart';
import '../domain/repositories/license_repository.dart';
import '../domain/repositories/local_library_repository.dart';
import '../domain/repositories/lyrics_repository.dart';
import '../domain/repositories/music_source_repository.dart';
import '../domain/repositories/search_history_repository.dart';
import '../domain/repositories/sleep_timer_repository.dart';
import '../features/catalog_detail/common/catalog_detail_controller.dart';
import '../features/home/common/home_controller.dart';
import '../features/library/common/library_controller.dart';
import '../features/local_music/common/local_music_controller.dart';
import '../features/playlists/common/playlist_add_controller.dart';
import '../features/playlists/common/playlist_content_controller.dart';
import '../features/playlists/common/playlist_controller.dart';
import '../features/playlists/common/system_playlist_controller.dart';
import '../features/search/common/search_controller.dart';
import '../features/settings/common/appearance_settings_controller.dart';
import '../platform/contracts/fullscreen_gateway.dart';
import '../platform/contracts/media_session_gateway.dart';
import '../platform/contracts/secure_credential_gateway.dart';
import '../playback/audio_engine.dart';
import '../playback/lyrics_controller.dart';
import '../playback/playback_controller.dart';
import '../playback/playback_favorite_controller.dart';
import '../playback/playback_source_resolver.dart';
import '../playback/queue_controller.dart';
import '../playback/sleep_persistence_controller.dart';
import 'app_data_services.dart';
import 'app_view_state.dart';
import 'flutter_license_repository.dart';
import 'playback_presenter.dart';

/// One graph per app scope; a Shell never creates business controllers.
final class DependencyGraph {
  DependencyGraph({
    AudioEngine? audioEngine,
    PlaybackSourceResolver? playbackSourceResolver,
    DateTime Function()? playbackClock,
    MediaSessionGateway? mediaSession,
    this.dataServices,
    AppearanceSettingsRepository? appearanceRepository,
    SleepTimerRepository? sleepTimerRepository,
    LibraryRepository? library,
    LocalLibraryRepository? localLibrary,
    CatalogSearchRepository? catalogSearch,
    CatalogBrowseRepository? catalogBrowse,
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
                 appearanceRepository == null &&
                 sleepTimerRepository == null &&
                 localLibrary == null &&
                 catalogSearch == null &&
                 catalogBrowse == null &&
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
       localLibrary = dataServices?.localLibrary ?? localLibrary,
       catalogSearch = dataServices?.catalogSearch ?? catalogSearch,
       catalogBrowse = dataServices?.catalogBrowse ?? catalogBrowse,
       searchHistory = dataServices?.searchHistory ?? searchHistory,
       collection = dataServices?.collection ?? collection,
       lyrics = dataServices?.lyrics ?? lyrics,
       musicSources = dataServices?.musicSources ?? musicSources,
       credentials = dataServices?.credentials ?? credentials {
    appearanceSettings = AppearanceSettingsController(
      appearance: appearance,
      repository: dataServices?.appearanceSettings ?? appearanceRepository,
    );
    playback = PlaybackController(
      _audioEngine,
      library: this.library,
      collection: this.collection,
      sourceResolver: playbackSourceResolver,
      clock: playbackClock,
      mediaSession: _mediaSession,
    );
    sleepPersistence = SleepPersistenceController(
      playback: playback,
      repository: dataServices?.sleepTimers ?? sleepTimerRepository,
    );
    queue = QueueController(playback);
    playbackFavorite = PlaybackFavoriteController(
      playback: playback,
      repository: this.collection,
    );
    lyricsController = LyricsController(
      playback: playback,
      repository: this.lyrics,
    );
    playbackPresenter = PlaybackPresenter(
      playback,
      sleepPersistence: sleepPersistence,
    );
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
    localMusic = LocalMusicController(repository: this.localLibrary);
    libraryController = LibraryController(
      localMusic: localMusic,
      playback: playback,
      repository: this.catalogBrowse,
      collection: this.collection,
      sources: this.musicSources,
    );
    catalogDetails = CatalogDetailSessions(
      repository: this.catalogBrowse,
      playback: playback,
      sources: this.musicSources,
      collection: this.collection,
    );
    playlists = PlaylistController(collection: this.collection);
    playlistAdds = PlaylistAddSessions(
      repository: this.collection,
      writer: playlists,
    );
    playlistContents = PlaylistContentSessions(
      repository: this.collection,
      playback: playback,
      writer: playlists,
    );
    systemPlaylists = SystemPlaylistSessions(
      repository: this.collection,
      playback: playback,
    );
  }

  final AudioEngine _audioEngine;
  final MediaSessionGateway _mediaSession;
  final AppDataServices? dataServices;
  final LibraryRepository? library;
  final LocalLibraryRepository? localLibrary;
  final CatalogSearchRepository? catalogSearch;
  final CatalogBrowseRepository? catalogBrowse;
  final SearchHistoryRepository? searchHistory;
  final CollectionRepository? collection;
  final LyricsRepository? lyrics;
  final MusicSourceRepository? musicSources;
  final SecureCredentialGateway? credentials;
  final FullscreenGateway? fullscreen;
  final LicenseRepository licenses;
  final viewState = AppViewState();
  final appearance = YYAppearanceController();
  late final AppearanceSettingsController appearanceSettings;
  late final PlaybackController playback;
  late final SleepPersistenceController sleepPersistence;
  late final QueueController queue;
  late final PlaybackFavoriteController playbackFavorite;
  late final LyricsController lyricsController;
  late final PlaybackPresenter playbackPresenter;
  late final HomeController home;
  late final CatalogSearchController search;
  late final LibraryController libraryController;
  late final LocalMusicController localMusic;
  late final CatalogDetailSessions catalogDetails;
  late final PlaylistController playlists;
  late final PlaylistAddSessions playlistAdds;
  late final PlaylistContentSessions playlistContents;
  late final SystemPlaylistSessions systemPlaylists;
  Future<void>? _closeFuture;

  Future<void> initialize() async {
    await appearanceSettings.initialize();
    if (_closeFuture != null) return;
    await playback.initialize();
    if (_closeFuture != null) return;
    await sleepPersistence.initialize();
    if (_closeFuture == null) playbackFavorite.start();
  }

  void dispose() {
    unawaited(close().catchError((Object _) {}));
  }

  /// Stops commands immediately and drains users of data before closing storage.
  Future<void> close() {
    final existing = _closeFuture;
    if (existing != null) return existing;
    queue.dispose();
    playbackFavorite.dispose();
    home.dispose();
    search.dispose();
    libraryController.dispose();
    localMusic.dispose();
    catalogDetails.dispose();
    playlists.dispose();
    playlistAdds.dispose();
    playlistContents.dispose();
    systemPlaylists.dispose();
    playbackPresenter.dispose();
    lyricsController.dispose();
    sleepPersistence.dispose();
    playback.dispose();
    appearanceSettings.dispose();
    appearance.dispose();
    return _closeFuture = _closeOwnedResources();
  }

  Future<void> _closeOwnedResources() async {
    var failed = false;
    for (final release in <Future<void> Function()>[
      home.close,
      appearanceSettings.close,
      search.close,
      libraryController.close,
      localMusic.close,
      catalogDetails.close,
      playlists.close,
      playlistAdds.close,
      playlistContents.close,
      systemPlaylists.close,
      lyricsController.close,
      queue.close,
      playbackFavorite.close,
      playback.close,
      sleepPersistence.close,
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
