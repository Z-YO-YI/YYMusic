import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../design_system/yy_button.dart';
import '../design_system/yy_feedback.dart';
import '../domain/models/catalog_reference.dart';
import '../domain/models/collection_models.dart';
import '../domain/models/track.dart';
import '../domain/repositories/license_repository.dart';
import '../features/catalog_detail/common/catalog_detail_controller.dart';
import '../features/catalog_detail/common/catalog_detail_screen.dart';
import '../features/catalog_detail/common/catalog_detail_state.dart';
import '../features/design_gallery/design_gallery_screen.dart';
import '../features/home/common/home_controller.dart';
import '../features/home/common/home_screen.dart';
import '../features/library/common/library_controller.dart';
import '../features/library/common/library_screen.dart';
import '../features/lyrics/common/lyrics_screen.dart';
import '../features/player/common/player_screen.dart';
import '../features/playlists/common/playlist_add_controller.dart';
import '../features/playlists/common/playlist_add_dialog.dart';
import '../features/playlists/common/playlist_content_controller.dart';
import '../features/playlists/common/playlist_content_screen.dart';
import '../features/playlists/common/playlist_controller.dart';
import '../features/playlists/common/playlist_editor_host.dart';
import '../features/playlists/common/system_playlist_controller.dart';
import '../features/playlists/common/system_playlist_screen.dart';
import '../features/queue/common/queue_screen.dart';
import '../features/search/common/search_controller.dart';
import '../features/search/common/search_screen.dart';
import '../features/settings/common/appearance_settings_controller.dart';
import '../features/settings/common/licenses_screen.dart';
import '../features/settings/common/settings_screen.dart';
import '../playback/lyrics_controller.dart';
import '../playback/playback_favorite_controller.dart';
import '../playback/queue_controller.dart';
import '../shared/foundation_button.dart';
import 'adaptive_root.dart';
import 'app_routes.dart';
import 'app_view_state.dart';
import 'catalog_detail_location.dart';
import 'flutter_license_repository.dart';
import 'foundation_screen.dart';
import 'fullscreen_presenter.dart';
import 'layout_class.dart';
import 'playback_presenter.dart';
import 'playlist_location.dart';
import 'system_playlist_location.dart';

final class AppRouter implements AppNavigation {
  AppRouter({
    required YYPlatform platform,
    required AppViewState viewState,
    String initialLocation = '/home',
    LicenseRepository licenses = const FlutterLicenseRepository(),
    bool audioBackendSelected = false,
    PlaybackPresenter? playbackPresenter,
    LyricsController? lyricsController,
    PlaybackFavoriteController? playbackFavorite,
    HomeController? homeController,
    CatalogSearchController? searchController,
    LibraryController? libraryController,
    CatalogDetailSessions? catalogDetails,
    PlaylistController? playlistController,
    PlaylistContentSessions? playlistContents,
    PlaylistAddSessions? playlistAdds,
    SystemPlaylistSessions? systemPlaylists,
    QueueController? queueController,
    AppearanceSettingsController? appearanceSettings,
    FullscreenPresenter? fullscreen,
    NavigatorObserver? fullscreenObserver,
  }) {
    void openFullscreenPlayer() {
      fullscreen?.enterOnNextPlayer();
      openPlayer();
    }

    _showPlaylistPicker = (track, title) async {
      final navigator = _rootNavigator.currentState;
      if (navigator == null || _pickerShowing) return;
      _pickerShowing = true;
      try {
        await navigator.push<void>(
          RawDialogRoute<void>(
            settings: const RouteSettings(name: 'playlist-add'),
            barrierDismissible: true,
            barrierLabel: '关闭添加到歌单',
            barrierColor: const Color(0x33000000),
            transitionDuration: Duration.zero,
            pageBuilder: (context, _, _) => playlistAdds == null
                ? Center(
                    child: YYErrorBanner(
                      title: '歌单存储不可用',
                      message: '请返回后重试。',
                      actionLabel: '返回',
                      onAction: back,
                    ),
                  )
                : PlaylistAddDialog(
                    sessions: playlistAdds,
                    track: track,
                    title: title,
                    platform: platform,
                    onClose: back,
                  ),
          ),
        );
      } finally {
        _pickerShowing = false;
      }
    };
    Widget screen(AppRoute route) =>
        route == AppRoute.home &&
            homeController != null &&
            playbackPresenter != null
        ? HomeScreen(
            platform: platform,
            controller: homeController,
            playback: playbackPresenter,
            navigation: this,
            viewState: viewState,
          )
        : route == AppRoute.search &&
              searchController != null &&
              playbackPresenter != null
        ? SearchScreen(
            platform: platform,
            controller: searchController,
            playback: playbackPresenter,
            navigation: this,
            viewState: viewState,
          )
        : route == AppRoute.library &&
              libraryController != null &&
              playbackPresenter != null
        ? LibraryScreen(
            platform: platform,
            controller: libraryController,
            queue: queueController,
            playback: playbackPresenter,
            navigation: this,
            viewState: viewState,
          )
        : route == AppRoute.settings && appearanceSettings != null
        ? SettingsScreen(
            key: const ValueKey('screen-settings'),
            platform: platform,
            controller: appearanceSettings,
            routeActive: _settingsActivity,
            navigation: this,
            viewState: viewState,
          )
        : route == AppRoute.player && playbackPresenter != null
        ? PlayerScreen(
            key: const ValueKey('screen-player'),
            platform: platform,
            presenter: playbackPresenter,
            favorite: playbackFavorite,
            navigation: this,
            routeActive: _playerActivity,
            fullscreen: fullscreen,
          )
        : route == AppRoute.lyrics &&
              lyricsController != null &&
              playbackPresenter != null
        ? LyricsScreen(
            key: const ValueKey('screen-lyrics'),
            platform: platform,
            controller: lyricsController,
            favorite: playbackFavorite,
            playback: playbackPresenter,
            navigation: this,
            routeActive: _lyricsActivity,
            fullscreen: fullscreen,
          )
        : FoundationScreen(
            route: route,
            navigation: this,
            viewState: viewState,
            showDesignGallery: route.isMain,
            audioBackendSelected: audioBackendSelected,
          );
    _router = GoRouter(
      navigatorKey: _rootNavigator,
      observers: [?fullscreenObserver],
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', redirect: (_, _) => AppRoute.home.path),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) {
            final selected = AppRoute.mainRoutes[shell.currentIndex];
            final frame = AdaptiveRoot(
              platform: platform,
              navigation: this,
              selected: selected,
              playbackPresenter: playbackPresenter,
              playbackFavorite: playbackFavorite,
              routeChanges: _router.routerDelegate,
              onOpenFullscreen: openFullscreenPlayer,
              child: shell,
            );
            return playlistController == null
                ? frame
                : PlaylistEditorHost(
                    controller: playlistController,
                    platform: platform,
                    active: selected == AppRoute.library,
                    child: frame,
                  );
          },
          branches: [
            for (final route in AppRoute.mainRoutes)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: route.path,
                    pageBuilder: (context, state) => NoTransitionPage<void>(
                      key: state.pageKey,
                      child: screen(route),
                    ),
                  ),
                ],
              ),
          ],
        ),
        for (final route in [AppRoute.player, AppRoute.lyrics])
          GoRoute(
            path: route.path,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              name: route.path,
              child: screen(route),
            ),
          ),
        for (final kind in ['album', 'artist'])
          GoRoute(
            path: '/$kind/:id',
            pageBuilder: (context, state) {
              final target = parseCatalogDetailLocation(state.uri);
              final identity = switch (target) {
                AlbumDetailTarget(:final reference) => reference,
                ArtistDetailTarget(:final reference) => reference,
                null => null,
              };
              final valid =
                  target != null &&
                  catalogDetails != null &&
                  playbackPresenter != null;
              return NoTransitionPage<void>(
                key: ValueKey((state.pageKey, identity)),
                child: valid
                    ? CatalogDetailScreen(
                        target: target,
                        sessions: catalogDetails,
                        queue: queueController,
                        platform: platform,
                        navigation: this,
                        playback: playbackPresenter,
                        frame: (child) => AdaptiveRoot(
                          platform: platform,
                          navigation: this,
                          selected: AppRoute.library,
                          playbackPresenter: playbackPresenter,
                          playbackFavorite: playbackFavorite,
                          routeChanges: _router.routerDelegate,
                          onOpenFullscreen: openFullscreenPlayer,
                          child: child,
                        ),
                      )
                    : SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              YYButton(label: '返回', onPressed: back),
                              const Expanded(
                                child: Center(
                                  child: YYErrorBanner(
                                    title: '无法打开详情',
                                    message: '链接缺少有效的来源或内容标识，请从音乐库重新打开。',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              );
            },
          ),
        GoRoute(
          path: '/playlist',
          pageBuilder: (context, state) {
            final id = parsePlaylistLocation(state.uri);
            return NoTransitionPage<void>(
              key: ValueKey((state.pageKey, id)),
              child:
                  id != null &&
                      playlistContents != null &&
                      playbackPresenter != null
                  ? PlaylistContentScreen(
                      playlistId: id,
                      sessions: playlistContents,
                      queue: queueController,
                      platform: platform,
                      navigation: this,
                      playback: playbackPresenter,
                      frame: (child) => AdaptiveRoot(
                        platform: platform,
                        navigation: this,
                        selected: AppRoute.library,
                        playbackPresenter: playbackPresenter,
                        playbackFavorite: playbackFavorite,
                        routeChanges: _router.routerDelegate,
                        onOpenFullscreen: openFullscreenPlayer,
                        child: child,
                      ),
                    )
                  : SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            YYButton(label: '返回', onPressed: back),
                            const SizedBox(height: 20),
                            const YYErrorBanner(
                              title: '无法打开歌单',
                              message: '链接或歌单存储不可用，请从音乐库重新打开。',
                            ),
                          ],
                        ),
                      ),
                    ),
            );
          },
        ),
        GoRoute(
          path: '/system-playlist',
          pageBuilder: (context, state) {
            final type = parseSystemPlaylistLocation(state.uri);
            return NoTransitionPage<void>(
              key: ValueKey((state.pageKey, type)),
              child:
                  type != null &&
                      systemPlaylists != null &&
                      playbackPresenter != null
                  ? SystemPlaylistScreen(
                      type: type,
                      sessions: systemPlaylists,
                      platform: platform,
                      navigation: this,
                      playback: playbackPresenter,
                      queue: queueController,
                      frame: (child) => AdaptiveRoot(
                        platform: platform,
                        navigation: this,
                        selected: AppRoute.library,
                        playbackPresenter: playbackPresenter,
                        playbackFavorite: playbackFavorite,
                        routeChanges: _router.routerDelegate,
                        onOpenFullscreen: openFullscreenPlayer,
                        child: child,
                      ),
                    )
                  : SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: YYErrorBanner(
                          title: '无法打开系统歌单',
                          message: '链接或存储不可用，请从音乐库重新打开。',
                          actionLabel: '返回',
                          onAction: back,
                        ),
                      ),
                    ),
            );
          },
        ),
        GoRoute(
          path: '/queue',
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            name: '/queue',
            child:
                systemPlaylists != null &&
                    queueController != null &&
                    playbackPresenter != null
                ? QueueScreen(
                    queue: queueController,
                    sessions: systemPlaylists,
                    platform: platform,
                    navigation: this,
                    frame: (child) => AdaptiveRoot(
                      platform: platform,
                      navigation: this,
                      selected: AppRoute.library,
                      playbackPresenter: playbackPresenter,
                      playbackFavorite: playbackFavorite,
                      routeChanges: _router.routerDelegate,
                      onOpenFullscreen: openFullscreenPlayer,
                      child: child,
                    ),
                  )
                : SafeArea(
                    child: YYErrorBanner(
                      title: '无法打开队列',
                      message: '队列存储不可用，请返回后重试。',
                      actionLabel: '返回',
                      onAction: back,
                    ),
                  ),
          ),
        ),
        GoRoute(
          path: '/settings/licenses',
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: LicensesScreen(repository: licenses, onBack: back),
          ),
        ),
        GoRoute(
          path: '/design-system',
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: DesignGalleryScreen(platform: platform, onBack: back),
          ),
        ),
      ],
      errorBuilder: (context, state) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('页面不存在'),
            FoundationButton(
              label: '返回首页',
              onPressed: () => goTo(AppRoute.home),
            ),
          ],
        ),
      ),
    );
    _refreshRouteActivity();
    _router.routerDelegate.addListener(_refreshRouteActivity);
  }

  late final GoRouter _router;
  final _settingsActivity = ValueNotifier(false);
  final _playerActivity = ValueNotifier(false);
  final _lyricsActivity = ValueNotifier(false);
  String? get _activePath =>
      _router.routerDelegate.currentConfiguration.lastOrNull?.matchedLocation;

  void _refreshRouteActivity() {
    _settingsActivity.value = _activePath == AppRoute.settings.path;
    _playerActivity.value = _activePath == AppRoute.player.path;
    _lyricsActivity.value = _activePath == AppRoute.lyrics.path;
  }

  final _rootNavigator = GlobalKey<NavigatorState>();
  late final Future<void> Function(TrackRef, String) _showPlaylistPicker;
  bool _pickerShowing = false;
  bool _playerPushPending = false;
  bool _lyricsPushPending = false;
  bool _queuePushPending = false;
  RouterConfig<Object> get config => _router;

  @override
  void goTo(AppRoute route) => _router.go(route.path);
  @override
  void openPlayer() {
    if (_restoreRoute(AppRoute.player)) return;
    if (_playerActivity.value || _playerPushPending) return;
    if (_lyricsActivity.value) {
      unawaited(_router.replace<void>(AppRoute.player.path));
      return;
    }
    _playerPushPending = true;
    unawaited(
      _router.push<void>(AppRoute.player.path).whenComplete(() {
        _playerPushPending = false;
      }),
    );
  }

  @override
  void openLyrics() {
    if (_restoreRoute(AppRoute.lyrics)) return;
    if (_lyricsActivity.value || _lyricsPushPending) return;
    _lyricsPushPending = true;
    unawaited(
      _router.push<void>(AppRoute.lyrics.path).whenComplete(() {
        _lyricsPushPending = false;
      }),
    );
  }

  // Named independent pages are reused instead of cycling player/lyrics stacks.
  bool _restoreRoute(AppRoute route) => _restorePath(route.path);

  bool _restorePath(String path) {
    // Configuration is updated before Navigator has built a just-pushed page.
    if (_activePath == path) return true;
    if (!_router.routerDelegate.currentConfiguration.matches.any(
      (match) => match.matchedLocation == path,
    )) {
      return false;
    }
    _rootNavigator.currentState?.popUntil((page) => page.settings.name == path);
    return true;
  }

  @override
  void openDesignGallery() => unawaited(_router.push<void>('/design-system'));
  @override
  void openLicenses() => unawaited(_router.push<void>('/settings/licenses'));
  @override
  void openAlbum(AlbumRef reference) => unawaited(
    _router.push<void>(
      catalogDetailLocation(AlbumDetailTarget(reference)).toString(),
    ),
  );
  @override
  void openArtist(ArtistRef reference) => unawaited(
    _router.push<void>(
      catalogDetailLocation(ArtistDetailTarget(reference)).toString(),
    ),
  );
  @override
  void back() {
    if (_router.canPop()) {
      _router.pop();
    } else if (!AppRoute.mainRoutes.any(
      (route) =>
          route.path == _router.routerDelegate.currentConfiguration.uri.path,
    )) {
      _router.go(AppRoute.home.path);
    }
  }

  @override
  void openPlaylist(String id) {
    final focus = FocusManager.instance.primaryFocus;
    unawaited(
      _router.push<void>(playlistLocation(id).toString()).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = focus?.context;
          if (context != null &&
              context.mounted &&
              TickerMode.valuesOf(context).enabled) {
            focus!.requestFocus();
          }
        });
      }),
    );
  }

  @override
  Future<void> addToPlaylist(TrackRef track, {required String title}) =>
      _showPlaylistPicker(track, title);

  @override
  void openSystemPlaylist(SystemPlaylistType type) {
    if (type == SystemPlaylistType.queue) {
      if (_restorePath('/queue') || _queuePushPending) return;
      _queuePushPending = true;
    }
    final focus = FocusManager.instance.primaryFocus;
    unawaited(
      _router
          .push<void>(
            type == SystemPlaylistType.queue
                ? '/queue'
                : systemPlaylistLocation(type).toString(),
          )
          .then((_) {
            if (type == SystemPlaylistType.queue) _queuePushPending = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final context = focus?.context;
              if (context != null &&
                  context.mounted &&
                  TickerMode.valuesOf(context).enabled &&
                  (ModalRoute.isCurrentOf(context) ?? true)) {
                focus!.requestFocus();
              }
            });
          }),
    );
  }

  void dispose() {
    _router.routerDelegate.removeListener(_refreshRouteActivity);
    _router.dispose();
    _settingsActivity.dispose();
    _playerActivity.dispose();
    _lyricsActivity.dispose();
  }
}
