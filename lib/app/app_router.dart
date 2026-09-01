import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/design_gallery/design_gallery_screen.dart';
import '../shared/foundation_button.dart';
import 'adaptive_root.dart';
import 'app_routes.dart';
import 'app_view_state.dart';
import 'foundation_screen.dart';
import 'layout_class.dart';

final class AppRouter implements AppNavigation {
  AppRouter({
    required YYPlatform platform,
    required AppViewState viewState,
    String initialLocation = '/home',
  }) {
    Widget screen(AppRoute route) => FoundationScreen(
      route: route,
      navigation: this,
      viewState: viewState,
      showDesignGallery: route.isMain,
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
