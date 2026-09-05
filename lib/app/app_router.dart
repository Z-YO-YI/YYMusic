import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../design_system/yy_button.dart';
import '../design_system/yy_feedback.dart';
import '../domain/models/catalog_reference.dart';
import '../domain/repositories/license_repository.dart';
import '../features/catalog_detail/common/catalog_detail_controller.dart';
import '../features/catalog_detail/common/catalog_detail_screen.dart';
import '../features/catalog_detail/common/catalog_detail_state.dart';
import '../features/design_gallery/design_gallery_screen.dart';
import '../features/home/common/home_controller.dart';
import '../features/home/common/home_screen.dart';
import '../features/library/common/library_controller.dart';
import '../features/library/common/library_screen.dart';
import '../features/search/common/search_controller.dart';
import '../features/search/common/search_screen.dart';
import '../features/settings/common/licenses_screen.dart';
import '../shared/foundation_button.dart';
import 'adaptive_root.dart';
import 'app_routes.dart';
import 'app_view_state.dart';
import 'catalog_detail_location.dart';
import 'flutter_license_repository.dart';
import 'foundation_screen.dart';
import 'layout_class.dart';
import 'playback_presenter.dart';

final class AppRouter implements AppNavigation {
  AppRouter({
    required YYPlatform platform,
    required AppViewState viewState,
    String initialLocation = '/home',
    LicenseRepository licenses = const FlutterLicenseRepository(),
    bool audioBackendSelected = false,
    PlaybackPresenter? playbackPresenter,
    HomeController? homeController,
    CatalogSearchController? searchController,
    LibraryController? libraryController,
    CatalogDetailSessions? catalogDetails,
  }) {
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
            playback: playbackPresenter,
            navigation: this,
            viewState: viewState,
          )
        : FoundationScreen(
            route: route,
            navigation: this,
            viewState: viewState,
            showDesignGallery: route.isMain,
            audioBackendSelected: audioBackendSelected,
          );
    _router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', redirect: (_, _) => AppRoute.home.path),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AdaptiveRoot(
            platform: platform,
            navigation: this,
            selected: AppRoute.mainRoutes[shell.currentIndex],
            playbackPresenter: playbackPresenter,
            child: shell,
          ),
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
                        platform: platform,
                        navigation: this,
                        playback: playbackPresenter,
                        frame: (child) => AdaptiveRoot(
                          platform: platform,
                          navigation: this,
                          selected: AppRoute.library,
                          playbackPresenter: playbackPresenter,
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
  }

  late final GoRouter _router;
  RouterConfig<Object> get config => _router;

  @override
  void goTo(AppRoute route) => _router.go(route.path);
  @override
  void openPlayer() => unawaited(_router.push<void>(AppRoute.player.path));
  @override
  void openLyrics() => unawaited(_router.push<void>(AppRoute.lyrics.path));
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

  void dispose() => _router.dispose();
}
