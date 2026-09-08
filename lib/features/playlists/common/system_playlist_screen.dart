import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_theme.dart';
import '../../../domain/models/collection_models.dart';
import '../../../domain/models/system_playlist_content.dart';
import '../phone/phone_system_playlist_layout.dart';
import '../tablet/tablet_system_playlist_layout.dart';
import '../windows/windows_system_playlist_layout.dart';
import 'system_playlist_controller.dart';
import 'system_playlist_management_panel.dart';
import 'system_playlist_sections.dart';

class SystemPlaylistScreen extends StatefulWidget {
  const SystemPlaylistScreen({
    super.key,
    required this.type,
    required this.sessions,
    required this.platform,
    required this.navigation,
    required this.playback,
    required this.frame,
  });
  final SystemPlaylistType type;
  final SystemPlaylistSessions sessions;
  final YYPlatform platform;
  final AppNavigation navigation;
  final PlaybackPresenter playback;
  final Widget Function(Widget child) frame;
  @override
  State<SystemPlaylistScreen> createState() => SystemPlaylistScreenState();
}

final class _ManagementRequest {
  _ManagementRequest(this.snapshot, this.favoriteIdentity);
  final SystemPlaylistContent snapshot;
  final Object? favoriteIdentity;
}

/// Route state is retained above replaceable platform chrome and owns no storage.
class SystemPlaylistScreenState extends State<SystemPlaylistScreen> {
  late final SystemPlaylistController controller;
  final scroll = ScrollController();
  final _menuFocus = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  final _backFocus = FocusNode(debugLabel: 'system playlist back');
  FocusNode? _returnFocus;
  _ManagementRequest? _request;
  bool _active = true;
  int _shownOffset = 0;
  int? _resetOffset;
  @override
  void initState() {
    super.initState();
    controller = widget.sessions.open(widget.type);
    controller.addListener(_changed);
    controller.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    _active =
        size.width > 0 &&
        size.height > 0 &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    controller.setActive(_active);
    _scheduleScroll();
    if (!_active && _request != null) {
      final request = _request;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(_request, request)) {
          _dismiss(restoreFocus: false);
        }
      });
    }
  }

  void _changed() {
    final offset = controller.content?.page.offset ?? 0;
    if (controller.isCurrent && offset != _shownOffset) {
      _shownOffset = offset;
      _resetOffset = offset;
      _scheduleScroll();
    }
    final request = _request;
    if (request != null &&
        (!controller.isCurrent ||
            !identical(controller.content, request.snapshot))) {
      _dismiss(restoreFocus: false);
    }
  }

  void _openFavoriteMenu(SystemPlaylistContent snapshot, Object identity) {
    if (!mounted ||
        !_active ||
        _request != null ||
        !controller.canRemoveFavorite(snapshot, identity)) {
      return;
    }
    _returnFocus = FocusManager.instance.primaryFocus;
    setState(() => _request = _ManagementRequest(snapshot, identity));
  }

  void _openClear(SystemPlaylistContent snapshot) {
    if (!mounted ||
        !_active ||
        _request != null ||
        !controller.canClearHistory(snapshot)) {
      return;
    }
    _returnFocus = FocusManager.instance.primaryFocus;
    setState(() => _request = _ManagementRequest(snapshot, null));
  }

  void _dismiss({bool restoreFocus = true}) {
    if (_request == null) return;
    setState(() => _request = null);
    final focus = _returnFocus;
    _returnFocus = null;
    if (restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _active && _request == null) {
          (focus?.context != null ? focus! : _backFocus).requestFocus();
        }
      });
    }
  }

  void _select(_ManagementRequest request, String action) {
    if (!mounted ||
        !_active ||
        !identical(_request, request) ||
        !controller.isCurrent ||
        !identical(controller.content, request.snapshot)) {
      return;
    }
    _dismiss();
    final identity = request.favoriteIdentity;
    switch (action) {
      case 'play':
        if (identity != null) {
          unawaited(controller.playEntry(request.snapshot, identity));
        }
      case 'remove-favorite':
        if (identity != null) {
          unawaited(controller.removeFavorite(request.snapshot, identity));
        }
      case 'clear-history':
        if (identity == null) {
          unawaited(controller.clearHistory(request.snapshot));
        }
    }
  }

  void _scheduleScroll() {
    final offset = _resetOffset;
    if (offset == null || !_active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _active && _resetOffset == offset && scroll.hasClients) {
        _resetOffset = null;
        scroll.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    unawaited(controller.close().catchError((Object _) {}));
    scroll.dispose();
    _menuFocus.dispose();
    _backFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, widget.playback]),
    builder: (context, _) {
      final size = MediaQuery.sizeOf(context);
      final sections = SystemPlaylistSections(
        controller: controller,
        navigation: widget.navigation,
        playback: widget.playback,
        canInteract: () => mounted && _active && _request == null,
        onFavoriteMenu: _openFavoriteMenu,
        onClearHistory: _openClear,
        backFocus: _backFocus,
      );
      final content = widget.platform == YYPlatform.windows
          ? WindowsSystemPlaylistLayout(sections: sections, scroll: scroll)
          : size.width < 600
          ? PhoneSystemPlaylistLayout(sections: sections, scroll: scroll)
          : TabletSystemPlaylistLayout(
              sections: sections,
              scroll: scroll,
              landscape: size.width > size.height,
            );
      final request = _request;
      return PopScope(
        canPop: request == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _dismiss();
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeFocus(
                excluding: request != null,
                child: ExcludeSemantics(
                  excluding: request != null,
                  child: widget.frame(
                    ColoredBox(
                      color: YYTheme.of(context).colors.base,
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
            if (request != null) ...[
              Positioned.fill(
                child: ModalBarrier(
                  color: const Color(0x33000000),
                  dismissible: true,
                  semanticsLabel: '关闭系统歌单操作',
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
                        child: FocusScope(
                          node: _menuFocus,
                          child: SystemPlaylistManagementPanel(
                            key: ValueKey(request),
                            controller: controller,
                            snapshot: request.snapshot,
                            favoriteIdentity: request.favoriteIdentity,
                            platform: widget.platform,
                            onDismiss: () {
                              if (identical(_request, request)) _dismiss();
                            },
                            onSelected: (action) => _select(request, action),
                          ),
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
  );
}
