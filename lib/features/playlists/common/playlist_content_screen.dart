import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_theme.dart';
import '../../../domain/models/playlist_content.dart';
import '../phone/phone_playlist_content_layout.dart';
import '../tablet/tablet_playlist_content_layout.dart';
import '../windows/windows_playlist_content_layout.dart';
import 'playlist_content_controller.dart';
import 'playlist_content_sections.dart';
import 'playlist_entry_menu.dart';

class PlaylistContentScreen extends StatefulWidget {
  const PlaylistContentScreen({
    super.key,
    required this.playlistId,
    required this.sessions,
    required this.platform,
    required this.navigation,
    required this.playback,
    required this.frame,
  });
  final String playlistId;
  final PlaylistContentSessions sessions;
  final YYPlatform platform;
  final AppNavigation navigation;
  final PlaybackPresenter playback;
  final Widget Function(Widget child) frame;
  @override
  State<PlaylistContentScreen> createState() => PlaylistContentScreenState();
}

final class _MenuRequest {
  _MenuRequest(this.id, this.snapshot);
  final String id;
  final PlaylistContent snapshot;
}

/// Route state remains above replaceable platform chrome and never owns storage.
class PlaylistContentScreenState extends State<PlaylistContentScreen> {
  late final PlaylistContentController controller;
  final scroll = ScrollController();
  final _menuFocus = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  _MenuRequest? _menu;
  FocusNode? _returnFocus;
  bool _active = true;
  int _shownOffset = 0;
  int? _scrollResetOffset;
  @override
  void initState() {
    super.initState();
    controller = widget.sessions.open(widget.playlistId);
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
    _scheduleWindowScroll();
    if (!_active && _menu != null) {
      final request = _menu;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(_menu, request)) _dismiss(restoreFocus: false);
      });
    }
  }

  void _changed() {
    final offset = controller.content?.page.offset ?? 0;
    if (controller.isCurrent && offset != _shownOffset) {
      _shownOffset = offset;
      _scrollResetOffset = offset;
      _scheduleWindowScroll();
    }
    final request = _menu;
    if (request != null &&
        (!controller.isCurrent ||
            !identical(controller.content, request.snapshot))) {
      _dismiss(restoreFocus: false);
    }
  }

  void _scheduleWindowScroll() {
    final offset = _scrollResetOffset;
    if (offset == null || !_active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _active &&
          _scrollResetOffset == offset &&
          scroll.hasClients) {
        _scrollResetOffset = null;
        scroll.jumpTo(0);
      }
    });
  }

  void _openMenu(String id) {
    if (!_active || !controller.canOpenEntry(id)) return;
    _returnFocus = FocusManager.instance.primaryFocus;
    setState(() => _menu = _MenuRequest(id, controller.content!));
  }

  void _dismiss({bool restoreFocus = true}) {
    if (_menu == null) return;
    setState(() => _menu = null);
    final focus = _returnFocus;
    _returnFocus = null;
    if (restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _active && _menu == null && focus?.context != null) {
          focus!.requestFocus();
        }
      });
    }
  }

  void _select(_MenuRequest request, String action) {
    if (!_active ||
        !identical(_menu, request) ||
        !identical(controller.content, request.snapshot) ||
        !controller.isCurrent) {
      return;
    }
    _dismiss();
    switch (action) {
      case 'play':
        unawaited(controller.playEntry(request.id));
      case 'remove':
        unawaited(controller.removeEntry(request.id));
      case 'up':
        unawaited(controller.moveEntry(request.id, up: true));
      case 'down':
        unawaited(controller.moveEntry(request.id, up: false));
    }
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    unawaited(controller.close().catchError((Object _) {}));
    scroll.dispose();
    _menuFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      controller,
      controller.writerChanges,
      widget.playback,
    ]),
    builder: (context, _) {
      final size = MediaQuery.sizeOf(context);
      final sections = PlaylistContentSections(
        controller: controller,
        navigation: widget.navigation,
        playback: widget.playback,
        menu: _openMenu,
        canInteract: () => mounted && _active && _menu == null,
      );
      final content = widget.platform == YYPlatform.windows
          ? WindowsPlaylistContentLayout(sections: sections, scroll: scroll)
          : size.width < 600
          ? PhonePlaylistContentLayout(sections: sections, scroll: scroll)
          : TabletPlaylistContentLayout(
              sections: sections,
              scroll: scroll,
              landscape: size.width > size.height,
            );
      final request = _menu;
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
                  semanticsLabel: '关闭歌单条目菜单',
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
                          child: PlaylistEntryMenu(
                            key: ValueKey(request),
                            controller: controller,
                            entry: request.snapshot.entries.firstWhere(
                              (e) => e.entry.id == request.id,
                            ),
                            onDismiss: () {
                              if (identical(_menu, request)) _dismiss();
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
