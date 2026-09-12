import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_theme.dart';
import '../../../domain/models/collection_models.dart';
import '../../../domain/models/playlist_content.dart';
import '../../../playback/queue_controller.dart';
import '../../../playback/queue_edit_result.dart';
import '../../queue/common/queue_operation_feedback.dart';
import '../phone/phone_playlist_content_layout.dart';
import '../tablet/tablet_playlist_content_layout.dart';
import '../windows/windows_playlist_content_layout.dart';
import 'playlist_content_controller.dart';
import 'playlist_content_sections.dart';
import 'playlist_entry_menu.dart';

part 'playlist_queue_actions.dart';

class PlaylistContentScreen extends StatefulWidget {
  const PlaylistContentScreen({
    super.key,
    required this.playlistId,
    required this.sessions,
    required this.platform,
    required this.navigation,
    required this.playback,
    required this.frame,
    this.queue,
  });
  final String playlistId;
  final PlaylistContentSessions sessions;
  final YYPlatform platform;
  final AppNavigation navigation;
  final PlaybackPresenter playback;
  final QueueController? queue;
  final Widget Function(Widget child) frame;
  @override
  State<PlaylistContentScreen> createState() => PlaylistContentScreenState();
}

final class _MenuRequest {
  _MenuRequest(this.id, this.snapshot, this.queue, this.sourcePermit);
  final String id;
  final PlaylistContent snapshot;
  final QueueSnapshot? queue;
  final bool Function()? sourcePermit;
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
  int _queueEpoch = 0;
  Size? _queueSize;
  PlaylistContent? _queueContent;
  bool _queueCurrent = false;
  String? _queueNotice;
  Object? _noticeIdentity;
  void _setQueueNotice(String? notice) => setState(() {
    _queueNotice = notice;
    _noticeIdentity = notice == null ? null : Object();
  });
  int _shownOffset = 0;
  int? _scrollResetOffset;
  @override
  void initState() {
    super.initState();
    controller = widget.sessions.open(widget.playlistId);
    controller.addListener(_changed);
    widget.queue?.addListener(_queueChanged);
    controller.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final wasActive = _active;
    _active =
        size.width > 0 &&
        size.height > 0 &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (_queueSize != size || wasActive != _active) {
      _queueEpoch++;
      _queueNotice = null;
      _noticeIdentity = null;
      final request = _menu;
      if (_active && wasActive && request != null) {
        _menu = _captureMenu(request.id, request.snapshot);
      }
    }
    _queueSize = size;
    controller.setActive(_active);
    _scheduleWindowScroll();
    if (!_active && _menu != null) {
      _menu = null;
      _returnFocus = null;
    }
  }

  void _changed() {
    if (!identical(_queueContent, controller.content) ||
        _queueCurrent != controller.isCurrent) {
      _queueEpoch++;
      _queueContent = controller.content;
      _queueCurrent = controller.isCurrent;
      _queueNotice = null;
      _noticeIdentity = null;
    }
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
    if (!_queuePageLive ||
        widget.queue?.editBusy == true ||
        !controller.canOpenEntry(id)) {
      return;
    }
    _returnFocus = FocusManager.instance.primaryFocus;
    setState(() => _menu = _captureMenu(id, controller.content!));
  }

  void _dismiss({bool restoreFocus = true}) {
    if (_menu == null) return;
    setState(() => _menu = null);
    final focus = _returnFocus;
    _returnFocus = null;
    if (restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_queuePageLive && _menu == null && focus?.context != null) {
          focus!.requestFocus();
        }
      });
    }
  }

  void _select(_MenuRequest request, String action) {
    if (!_queuePageLive ||
        !identical(_menu, request) ||
        !identical(controller.content, request.snapshot) ||
        !controller.isCurrent) {
      return;
    }
    if (action == 'queue' || action == 'next') {
      unawaited(_insertEntry(request, next: action == 'next'));
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
    _queueEpoch++;
    _menu = null;
    _returnFocus = null;
    widget.queue?.removeListener(_queueChanged);
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
      widget.queue,
    ]),
    builder: (context, _) {
      final size = MediaQuery.sizeOf(context);
      final sections = PlaylistContentSections(
        controller: controller,
        navigation: widget.navigation,
        playback: widget.playback,
        menu: _openMenu,
        queueFeedback: _queueFeedback(),
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
                            canInsert:
                                _active &&
                                widget.queue != null &&
                                !widget.queue!.editBusy &&
                                identical(widget.queue!.state, request.queue) &&
                                (request.sourcePermit?.call() ?? false),
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
