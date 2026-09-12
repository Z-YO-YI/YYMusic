import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/layout_class.dart';
import '../../../design_system/yy_artwork_placeholder.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_dialog.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_queue_tile.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/queue_edit.dart';
import '../../../domain/models/system_playlist_content.dart';
import '../../../playback/queue_controller.dart';
import '../../playlists/common/system_playlist_controller.dart';
import '../../playlists/common/system_playlist_sections.dart';
import '../phone/phone_queue_layout.dart';
import '../tablet/tablet_queue_layout.dart';
import '../windows/windows_queue_layout.dart';
import 'queue_page_controller.dart';
import 'queue_reorder_sliver.dart';

part 'queue_sections.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({
    super.key,
    required this.queue,
    required this.sessions,
    required this.platform,
    required this.navigation,
    required this.frame,
  });
  final QueueController queue;
  final SystemPlaylistSessions sessions;
  final YYPlatform platform;
  final AppNavigation navigation;
  final Widget Function(Widget) frame;
  @override
  State<QueueScreen> createState() => QueueScreenState();
}

final class _QueueConfirmation {
  const _QueueConfirmation(this.edit, this.permit, this.clear);
  final QueueEdit edit;
  final bool Function() permit;
  final bool clear;
}

class QueueScreenState extends State<QueueScreen> {
  late final QueuePageController controller;
  final scroll = ScrollController();
  final _backFocus = FocusNode(debugLabel: 'queue back');
  final _pageFocus = FocusNode(debugLabel: 'queue route');
  final _actionFocus = <(String, YYGlyph), FocusNode>{};
  FocusNode? _pendingFocus;
  SystemPlaylistContent? _focusContent;
  _QueueConfirmation? _confirmation;
  bool _active = true;
  Size? _size;
  int _offset = 0;

  bool get _live =>
      mounted && _active && (ModalRoute.of(context)?.isCurrent ?? true);
  bool get _interactive => _live && _confirmation == null;

  @override
  void initState() {
    super.initState();
    controller = QueuePageController(
      queue: widget.queue,
      sessions: widget.sessions,
    );
    controller.read.addListener(_changed);
    widget.queue.addListener(_changed);
    controller.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final active =
        size.width > 0 &&
        size.height > 0 &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (_size != size || !active) {
      _pendingFocus = null;
      controller.invalidate();
      controller.read.setActive(false);
      _confirmation = null;
    }
    _size = size;
    _active = active;
    controller.setActive(active);
    controller.read.setActive(active && _confirmation == null);
  }

  void _changed() {
    final confirmation = _confirmation;
    if (confirmation != null && !confirmation.permit()) _dismiss();
    final read = controller.read, data = controller.read.content;
    if (read.isCurrent &&
        !widget.queue.editBusy &&
        (_pendingFocus != null || !identical(_focusContent, data))) {
      _focusContent = data;
      final focus = _pendingFocus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (focus != null && identical(_pendingFocus, focus)) {
          _pendingFocus = null;
          final primary = FocusManager.instance.primaryFocus;
          if (_interactive &&
              (identical(primary, focus) ||
                  identical(primary, _pageFocus) ||
                  primary is FocusScopeNode)) {
            (focus.context != null && focus.canRequestFocus
                    ? focus
                    : _backFocus)
                .requestFocus();
          }
        }
        final visible =
            controller.read.content?.entries
                .map((entry) => entry.entryId)
                .toSet() ??
            {};
        final obsolete = _actionFocus.keys
            .where((key) => !visible.contains(key.$1))
            .toList();
        for (final key in obsolete) {
          _actionFocus.remove(key)!.dispose();
        }
      });
    }
    if (read.isCurrent && data != null && data.page.offset != _offset) {
      _offset = data.page.offset;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients) scroll.jumpTo(0);
      });
    }
  }

  void _dismiss() {
    if (!mounted || _confirmation == null) return;
    setState(() => _confirmation = null);
    controller.read.setActive(_active);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_interactive && _backFocus.context != null) _backFocus.requestFocus();
    });
  }

  void _edit(
    QueueEdit edit,
    bool Function() permit, {
    bool? confirmClear,
    FocusNode? restoreFocus,
  }) {
    if (!_interactive || !permit() || widget.queue.editBusy) return;
    if (confirmClear != null) {
      controller.invalidate();
      controller.read.setActive(false);
      setState(
        () => _confirmation = _QueueConfirmation(
          edit,
          controller.permit(),
          confirmClear,
        ),
      );
    } else {
      if (restoreFocus?.hasFocus ?? false) _pendingFocus = restoreFocus;
      unawaited(controller.submit(edit, () => _interactive && permit()));
    }
  }

  Widget _confirm(_QueueConfirmation request, bool phone) {
    final title = request.clear ? '清空播放队列' : '移除当前队列项';
    final body = Text(
      request.clear
          ? '将移除 ${request.edit.expected.entries.length} 个队列条目并停止播放。不会删除音乐文件、收藏或歌单。'
          : '将停止当前播放并移除此条目。保留其他队列条目，不会自动播放相邻歌曲，也不会删除音乐文件。',
    );
    final actions = [
      YYButton(label: '取消', onPressed: _dismiss),
      YYButton(
        label: '确认${request.clear ? '清空' : '移除'}',
        glyph: YYGlyph.trash,
        onPressed: request.permit() && !widget.queue.editBusy
            ? () {
                if (!_live ||
                    !identical(_confirmation, request) ||
                    !request.permit()) {
                  return;
                }
                _dismiss();
                unawaited(
                  controller.submit(
                    request.edit,
                    () => _interactive && request.permit(),
                  ),
                );
              }
            : null,
      ),
    ];
    return phone
        ? YYBottomSheet(
            title: title,
            body: body,
            actions: actions,
            onClose: _dismiss,
          )
        : YYDialog(
            title: title,
            body: body,
            actions: actions,
            onClose: _dismiss,
          );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller.read, widget.queue]),
    builder: (context, _) {
      final size = MediaQuery.sizeOf(context);
      final phone = widget.platform == YYPlatform.android && size.width < 600;
      final slivers = _slivers();
      final content = widget.platform == YYPlatform.windows
          ? WindowsQueueLayout(slivers: slivers, scroll: scroll)
          : phone
          ? PhoneQueueLayout(slivers: slivers, scroll: scroll)
          : TabletQueueLayout(
              slivers: slivers,
              scroll: scroll,
              landscape: size.width > size.height,
            );
      final request = _confirmation;
      return PopScope(
        canPop: request == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _dismiss();
        },
        child: Focus(
          focusNode: _pageFocus,
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape &&
                _live) {
              if (_confirmation != null) {
                _dismiss();
              } else {
                widget.navigation.back();
              }
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
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
                    semanticsLabel: '关闭队列确认',
                    onDismiss: _dismiss,
                  ),
                ),
                Positioned.fill(
                  child: SafeArea(
                    child: Align(
                      alignment: phone
                          ? Alignment.bottomCenter
                          : Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SingleChildScrollView(
                          child: _confirm(request, phone),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  @override
  void dispose() {
    controller.read.removeListener(_changed);
    widget.queue.removeListener(_changed);
    unawaited(controller.close().catchError((Object _) {}));
    scroll.dispose();
    _backFocus.dispose();
    _pageFocus.dispose();
    for (final focus in _actionFocus.values) {
      focus.dispose();
    }
    super.dispose();
  }
}
