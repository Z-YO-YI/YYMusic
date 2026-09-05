import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_theme.dart';
import '../../../domain/models/track.dart';
import '../phone/phone_catalog_detail_layout.dart';
import '../tablet/tablet_catalog_detail_layout.dart';
import '../windows/windows_catalog_detail_layout.dart';
import 'catalog_detail_controller.dart';
import 'catalog_detail_sections.dart';
import 'catalog_detail_state.dart';
import 'catalog_detail_track_menu.dart';

/// A route owns view state and borrows a root-registered, drainable detail session.
class CatalogDetailScreen extends StatefulWidget {
  const CatalogDetailScreen({
    super.key,
    required this.target,
    required this.sessions,
    required this.platform,
    required this.navigation,
    required this.playback,
    required this.frame,
  });
  final CatalogDetailTarget target;
  final CatalogDetailSessions sessions;
  final YYPlatform platform;
  final AppNavigation navigation;
  final PlaybackPresenter playback;

  /// App-owned chrome is below route state so shell changes cannot dispose it.
  final Widget Function(Widget child) frame;
  @override
  State<CatalogDetailScreen> createState() => CatalogDetailScreenState();
}

class CatalogDetailScreenState extends State<CatalogDetailScreen> {
  late final CatalogDetailController controller;
  final _scroll = ScrollController();
  CatalogDetailTab _tab = CatalogDetailTab.tracks;
  int _revision = 0;
  Track? _menuTrack;
  FocusNode? _returnFocus;
  @override
  void initState() {
    super.initState();
    controller = widget.sessions.open(widget.target);
    controller.addListener(_changed);
    unawaited(controller.start());
    _revision = controller.revision;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    controller.setActive(active);
    if (!active && _menuTrack != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dismiss(restoreFocus: false);
      });
    }
  }

  void _changed() {
    if (_revision == controller.revision) return;
    _revision = controller.revision;
    _dismiss(restoreFocus: false);
    _resetScroll();
  }

  void _openMenu(Track track) {
    if (!controller.canOpenActions(track.ref)) return;
    _returnFocus = FocusManager.instance.primaryFocus;
    setState(() => _menuTrack = track);
    controller.prepareTrackActions();
  }

  void _dismiss({bool restoreFocus = true}) {
    if (_menuTrack == null) return;
    setState(() => _menuTrack = null);
    final focus = _returnFocus;
    _returnFocus = null;
    if (restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && focus?.context != null) focus!.requestFocus();
      });
    }
  }

  void _resetScroll() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
  });
  @override
  void dispose() {
    controller.removeListener(_changed);
    unawaited(controller.close().catchError((Object _) {}));
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.frame(
    ColoredBox(
      color: YYTheme.of(context).colors.base,
      child: ListenableBuilder(
        listenable: Listenable.merge([controller, widget.playback]),
        builder: (context, _) {
          final size = MediaQuery.sizeOf(context);
          final sections = CatalogDetailSections(
            controller: controller,
            playback: widget.playback,
            navigation: widget.navigation,
            tab: _tab,
            menu: _openMenu,
            onTab: (value) {
              _dismiss(restoreFocus: false);
              setState(() => _tab = value);
              _resetScroll();
            },
          );
          final content = widget.platform == YYPlatform.windows
              ? WindowsCatalogDetailLayout(sections: sections, scroll: _scroll)
              : size.width < 600
              ? PhoneCatalogDetailLayout(sections: sections, scroll: _scroll)
              : TabletCatalogDetailLayout(
                  sections: sections,
                  scroll: _scroll,
                  landscape: size.width > size.height,
                );
          final track = _menuTrack;
          return PopScope(
            canPop: track == null,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _dismiss();
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeFocus(
                    excluding: track != null,
                    child: ExcludeSemantics(
                      excluding: track != null,
                      child: content,
                    ),
                  ),
                ),
                if (track != null) ...[
                  Positioned.fill(
                    child: ModalBarrier(
                      color: const Color(0x33000000),
                      dismissible: true,
                      semanticsLabel: '关闭曲目菜单',
                      onDismiss: _dismiss,
                    ),
                  ),
                  Positioned.fill(
                    child: SafeArea(
                      child: Align(
                        alignment:
                            widget.platform == YYPlatform.android &&
                                size.width < 600
                            ? Alignment.bottomCenter
                            : Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            child: CatalogDetailTrackMenu(
                              controller: controller,
                              track: track,
                              onDismiss: _dismiss,
                              onSelected: (id) {
                                if (id == 'retry-favorites') {
                                  controller.retryFavorites();
                                  return;
                                }
                                _dismiss();
                                if (id == 'play') {
                                  unawaited(controller.play(track.ref));
                                }
                                if (id == 'favorite') {
                                  unawaited(
                                    controller.toggleFavorite(track.ref),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ),
  );
}
