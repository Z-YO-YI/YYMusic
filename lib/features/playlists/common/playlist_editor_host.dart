import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../app/layout_class.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_dialog.dart';
import '../../../design_system/yy_text_field.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../domain/models/collection_models.dart';
import 'playlist_controller.dart';

enum PlaylistEditorKind { create, rename, delete }

final class PlaylistEditorRequest {
  const PlaylistEditorRequest.create()
    : kind = PlaylistEditorKind.create,
      playlist = null;
  const PlaylistEditorRequest.rename(Playlist value)
    : kind = PlaylistEditorKind.rename,
      playlist = value;
  const PlaylistEditorRequest.delete(Playlist value)
    : kind = PlaylistEditorKind.delete,
      playlist = value;
  final PlaylistEditorKind kind;
  final Playlist? playlist;
  String get title => switch (kind) {
    PlaylistEditorKind.create => '新建歌单',
    PlaylistEditorKind.rename => '重命名歌单',
    PlaylistEditorKind.delete => '删除歌单',
  };
}

/// UI capabilities only; does not own a repository or a duplicate playlist list.
class PlaylistEditorScope extends InheritedWidget {
  const PlaylistEditorScope({
    super.key,
    required this.open,
    this.failure,
    this.dismissFailure,
    required super.child,
  });
  final ValueChanged<PlaylistEditorRequest>? open;
  final String? failure;
  final VoidCallback? dismissFailure;
  static PlaylistEditorScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlaylistEditorScope>();
  @override
  bool updateShouldNotify(PlaylistEditorScope oldWidget) =>
      open != oldWidget.open || failure != oldWidget.failure;
}

/// Lives above AdaptiveRoot so replacing a Phone/Tablet Shell keeps the draft.
class PlaylistEditorHost extends StatefulWidget {
  const PlaylistEditorHost({
    super.key,
    required this.controller,
    required this.platform,
    required this.active,
    required this.child,
  });
  final PlaylistController controller;
  final YYPlatform platform;
  final bool active;
  final Widget child;
  @override
  State<PlaylistEditorHost> createState() => _PlaylistEditorHostState();
}

class _PlaylistEditorHostState extends State<PlaylistEditorHost> {
  final _text = TextEditingController();
  final _inputFocus = FocusNode(debugLabel: 'playlist name');
  final _cancelFocus = FocusNode(debugLabel: 'playlist cancel');
  FocusNode? _returnFocus;
  PlaylistEditorRequest? _request;
  String? _error;
  String? _lateFailure;
  int _generation = 0;
  bool _submitting = false;
  bool _routeCurrent = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
    if (!_routeCurrent && _request != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_routeCurrent) _dismiss(restoreFocus: false);
      });
    }
  }

  @override
  void didUpdateWidget(PlaylistEditorHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && _request != null) _dismiss(restoreFocus: false);
  }

  void _open(PlaylistEditorRequest request) {
    if (!widget.active ||
        !_routeCurrent ||
        !widget.controller.isAvailable ||
        widget.controller.busy ||
        _request != null ||
        request.playlist?.isSystem == true) {
      return;
    }
    final generation = ++_generation;
    _returnFocus = FocusManager.instance.primaryFocus;
    _text.value = TextEditingValue(
      text: request.playlist?.name ?? '',
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: request.playlist?.name.length ?? 0,
      ),
    );
    setState(() {
      _request = request;
      _error = null;
      _submitting = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _generation) {
        (request.kind == PlaylistEditorKind.delete ? _cancelFocus : _inputFocus)
            .requestFocus();
      }
    });
  }

  void _dismiss({bool restoreFocus = true}) {
    if (_request == null) return;
    _generation++;
    final previous = _returnFocus;
    _returnFocus = null;
    _inputFocus.unfocus();
    _cancelFocus.unfocus();
    setState(() {
      _request = null;
      _error = null;
      _submitting = false;
    });
    if (restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _request == null &&
            widget.active &&
            _routeCurrent &&
            previous?.context != null &&
            previous!.canRequestFocus) {
          previous.requestFocus();
        }
      });
    }
  }

  Future<void> _submit() async {
    final request = _request;
    final generation = _generation;
    if (request == null ||
        _submitting ||
        widget.controller.busy ||
        !_text.value.composing.isCollapsed) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await switch (request.kind) {
      PlaylistEditorKind.create => widget.controller.createPlaylist(_text.text),
      PlaylistEditorKind.rename => widget.controller.renamePlaylist(
        request.playlist!.id,
        _text.text,
      ),
      PlaylistEditorKind.delete => widget.controller.deletePlaylist(
        request.playlist!.id,
      ),
    };
    if (!mounted) return;
    if (generation != _generation) {
      if (!result.succeeded) {
        setState(() => _lateFailure = '${request.title}：${result.message}');
      }
      return;
    }
    if (result.succeeded) {
      _dismiss();
    } else {
      setState(() {
        _submitting = false;
        _error = result.message;
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _inputFocus.dispose();
    _cancelFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final request = _request;
      return PlaylistEditorScope(
        failure: _lateFailure,
        dismissFailure: () => setState(() => _lateFailure = null),
        open: widget.controller.isAvailable && !widget.controller.busy
            ? _open
            : null,
        child: PopScope(
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
                    child: widget.child,
                  ),
                ),
              ),
              if (request != null) ...[
                Positioned.fill(
                  child: ModalBarrier(
                    color: const Color(0x33000000),
                    dismissible: true,
                    semanticsLabel: '关闭${request.title}',
                    onDismiss: _dismiss,
                  ),
                ),
                Positioned.fill(child: _overlay(context, request)),
              ],
            ],
          ),
        ),
      );
    },
  );

  Widget _overlay(BuildContext context, PlaylistEditorRequest request) {
    final busy = _submitting || widget.controller.busy;
    final colors = YYTheme.of(context).colors;
    final deleting = request.kind == PlaylistEditorKind.delete;
    final phone =
        widget.platform == YYPlatform.android &&
        MediaQuery.sizeOf(context).width < 600;
    final body = deleting
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '确定删除“${request.playlist!.name}”？',
                style: YYTypography.text(size: 14, weight: 700),
              ),
              const SizedBox(height: 12),
              Text(
                '只删除歌单及其条目，不删除歌曲文件或来源内容。此操作不可撤销。',
                style: YYTypography.caption.copyWith(color: colors.secondary),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(error, style: YYTypography.caption),
                ),
              ],
            ],
          )
        : YYTextField(
            key: const ValueKey('playlist-name'),
            controller: _text,
            focusNode: _inputFocus,
            label: request.kind == PlaylistEditorKind.create ? '新歌单名称' : '歌单名称',
            placeholder: '例如：夜间聆听',
            enabled: !busy,
            errorText: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          );
    final actions = <Widget>[
      YYButton(
        key: const ValueKey('playlist-cancel'),
        label: busy ? '关闭' : '取消',
        focusNode: _cancelFocus,
        onPressed: _dismiss,
      ),
      YYButton(
        key: const ValueKey('playlist-submit'),
        label: busy
            ? '保存中'
            : deleting
            ? '确认删除'
            : request.kind == PlaylistEditorKind.create
            ? '创建'
            : '保存名称',
        style: YYButtonStyle.primary,
        loading: busy,
        onPressed: busy || !widget.controller.isAvailable ? null : _submit,
      ),
    ];
    // The whole surface can scroll in a short IME-reduced viewport, including
    // header/actions. Rebase modal metrics to the actual safe drawable area.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: phone ? Alignment.bottomCenter : Alignment.center,
            child: SingleChildScrollView(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(
                    constraints.maxWidth,
                    math.max(320, constraints.maxHeight),
                  ),
                  padding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: Focus(
                  onKeyEvent: (_, event) {
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.escape ||
                            event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                                HardwareKeyboard.instance.isAltPressed)) {
                      _dismiss();
                      return KeyEventResult.handled;
                    }
                    // Empty/busy modal focus must not leak Space to the player.
                    // EditableText keeps native typing; buttons handle activation first.
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.space) {
                      final focused =
                          FocusManager.instance.primaryFocus?.context;
                      if (focused?.widget is! EditableText &&
                          focused
                                  ?.findAncestorWidgetOfExactType<
                                    EditableText
                                  >() ==
                              null) {
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextFieldTapRegion(
                    child: phone
                        ? YYBottomSheet(
                            title: request.title,
                            subtitle: busy
                                ? '已开始保存，关闭面板不会取消写入。'
                                : '自定义歌单 · 保存在本机',
                            body: body,
                            actions: actions,
                            autofocus: false,
                            onClose: _dismiss,
                          )
                        : YYDialog(
                            title: request.title,
                            subtitle: busy
                                ? '已开始保存，关闭面板不会取消写入。'
                                : '自定义歌单 · 保存在本机',
                            body: body,
                            actions: actions,
                            autofocus: false,
                            onClose: _dismiss,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
