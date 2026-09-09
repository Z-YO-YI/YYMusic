import 'package:flutter/widgets.dart';

import 'app_routes.dart';
import 'fullscreen_presenter.dart';

/// Observes the real top route, including imperatively pushed dialogs.
final class FullscreenRouteObserver extends NavigatorObserver {
  FullscreenRouteObserver(this.presenter);
  final FullscreenPresenter presenter;

  @override
  void didChangeTop(Route<Object?> topRoute, Route<Object?>? previousTopRoute) {
    final name = topRoute.settings.name;
    presenter.setRoute(
      topRoute,
      eligible: name == AppRoute.player.path || name == AppRoute.lyrics.path,
      player: name == AppRoute.player.path,
      modal: topRoute is PopupRoute<Object?>,
      isCurrent: () => topRoute.isCurrent,
    );
  }
}
