import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../app/layout_class.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_dialog.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_surface.dart';
import '../../../design_system/yy_text_field.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/playlist_name.dart';
import '../../../domain/models/playlist_name_query.dart';
import '../../../domain/models/track.dart';
import 'playlist_add_controller.dart';

/// The root modal route owns this view, above all replaceable platform shells.
class PlaylistAddDialog extends StatefulWidget {
  const PlaylistAddDialog({
    super.key,
    required this.sessions,
    required this.track,
    required this.title,
    required this.platform,
    required this.onClose,
  });
  final PlaylistAddSessions sessions;
  final TrackRef track;
  final String title;
  final YYPlatform platform;
  final VoidCallback onClose;
  @override
  State<PlaylistAddDialog> createState() => PlaylistAddDialogState();
}

class PlaylistAddDialogState extends State<PlaylistAddDialog> {
  late final PlaylistAddController controller;
  final input = TextEditingController();
  final inputFocus = FocusNode(debugLabel: 'playlist filter');
  final nameInput = TextEditingController();
  final nameFocus = FocusNode(debugLabel: 'new playlist name');
  final scroll = ScrollController();
  bool _active = true, _closing = false;
  bool get _canInteract =>
      mounted &&
      !_closing &&
      _active &&
      (ModalRoute.of(context)?.isCurrent ?? true);
  bool get _matchesInput {
    if (!input.value.composing.isCollapsed) return false;
    try {
      return PlaylistNameQuery(input.text).text == controller.query.text;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    controller = widget.sessions.open(widget.track, title: widget.title)
      ..start();
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
  }

  void _close() {
    if (!_canInteract) return;
    _closing = true;
    widget.onClose();
  }

  void _filter() {
    if (!_canInteract ||
        controller.busy ||
        !input.value.composing.isCollapsed) {
      return;
    }
    controller.filter(input.text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) scroll.jumpTo(0);
    });
  }

  bool get _validName {
    if (!nameInput.value.composing.isCollapsed) return false;
    try {
      PlaylistName.normalize(nameInput.text);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _createAndAdd(TextEditingValue draft) {
    if (!_canInteract ||
        !controller.canCreate ||
        !_validName ||
        nameInput.value != draft) {
      return;
    }
    unawaited(controller.createAndAdd(draft.text));
  }

  @override
  void dispose() {
    _active = false;
    unawaited(controller.close().catchError((Object _) {}));
    input.dispose();
    inputFocus.dispose();
    nameInput.dispose();
    nameFocus.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      controller,
      controller.writerChanges,
      input,
      nameInput,
    ]),
    builder: (context, _) {
      final media = MediaQuery.of(context);
      if (media.size.isEmpty) return const SizedBox.shrink();
      final phone =
          widget.platform == YYPlatform.android && media.size.width < 600;
      final body = _body(context);
      final actions = [
        YYButton(
          key: const ValueKey('playlist-add-close'),
          label: controller.addedTo != null
              ? '完成'
              : controller.busy
              ? '关闭'
              : '取消',
          onPressed: _close,
        ),
      ];
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: phone ? Alignment.bottomCenter : Alignment.center,
              child: SingleChildScrollView(
                child: MediaQuery(
                  data: media.copyWith(
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
                          event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                          HardwareKeyboard.instance.isAltPressed) {
                        _close();
                        return KeyEventResult.handled;
                      }
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
                              title: '添加到歌单',
                              subtitle: controller.title,
                              body: body,
                              actions: actions,
                              onClose: _close,
                            )
                          : YYDialog(
                              title: '添加到歌单',
                              subtitle: controller.title,
                              body: body,
                              actions: actions,
                              onClose: _close,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _body(BuildContext context) {
    final snapshot = controller.snapshot;
    final colors = YYTheme.of(context).colors;
    if (controller.addedTo case final name?) {
      return Semantics(
        liveRegion: true,
        child: Text(
          controller.created
              ? '已新建“$name”并添加歌曲。只保存歌曲引用，不复制音乐文件。'
              : '已添加到“$name”。只保存歌曲引用，不复制音乐文件。',
          style: YYTypography.text(),
        ),
      );
    }
    final availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YYTextField(
          key: const ValueKey('playlist-add-filter'),
          controller: input,
          focusNode: inputFocus,
          label: '按歌单名称筛选',
          placeholder: '留空显示全部自定义歌单',
          enabled: !controller.busy,
          onSubmitted: (_) => _filter(),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: YYButton(
            label: '筛选歌单',
            glyph: YYGlyph.search,
            onPressed: controller.busy || !input.value.composing.isCollapsed
                ? null
                : _filter,
          ),
        ),
        const SizedBox(height: 12),
        Text('选择已有歌单 · 最近更新优先 · 同名歌单按独立身份保存', style: YYTypography.caption),
        if (!_matchesInput)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('输入已更改，请先筛选再添加。'),
          ),
        if (controller.busy)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('已开始保存，关闭不会取消写入。'),
          ),
        if (controller.actionError case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: YYErrorBanner(title: '添加未完成', message: error),
          ),
        if (controller.phase == LoadPhase.loading ||
            controller.phase == LoadPhase.idle)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: YYSkeleton(height: 72, semanticLabel: '正在读取目标歌单'),
          ),
        if (controller.error case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: YYErrorBanner(
              title: '歌单暂不可选',
              message: error,
              actionLabel: '重试筛选',
              onAction: _filter,
            ),
          ),
        if (controller.phase == LoadPhase.empty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: YYEmptyState(
              glyph: YYGlyph.playlist,
              message: controller.query.text.isEmpty
                  ? '还没有自定义歌单。可在下方新建并添加当前歌曲。'
                  : '没有匹配的歌单，请更换筛选词。',
            ),
          ),
        if (snapshot != null && snapshot.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: math.min(360, math.max(120, availableHeight * .38)),
            child: ListView.separated(
              key: const PageStorageKey('playlist-add-choices'),
              controller: scroll,
              itemCount: snapshot.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final playlist = snapshot.items[index];
                final enabled = _matchesInput && controller.canAdd(playlist.id);
                return YYSurface(
                  key: ValueKey(('playlist-choice', playlist.id)),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: YYTheme.of(context).accent.soft,
                          borderRadius: BorderRadius.circular(
                            YYRadius.playlistIcon,
                          ),
                        ),
                        child: const Center(
                          child: YYIcon(glyph: YYGlyph.playlist, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              style: YYTypography.text(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              playlist.description.isEmpty
                                  ? '自定义歌单'
                                  : playlist.description,
                              style: YYTypography.caption.copyWith(
                                color: colors.secondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      YYButton(
                        label: '添加',
                        style: YYButtonStyle.primary,
                        onPressed: !enabled
                            ? null
                            : () {
                                if (_canInteract &&
                                    _matchesInput &&
                                    identical(controller.snapshot, snapshot)) {
                                  unawaited(
                                    controller.addTo(playlist.id, snapshot),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '已显示 ${snapshot.items.length} 个匹配歌单',
            style: YYTypography.caption,
          ),
        ],
        if (controller.capped)
          const Text('当前只显示前200个匹配歌单，请用名称缩小范围。')
        else if (controller.canLoadMore)
          YYButton(
            label: '更多歌单',
            onPressed: _matchesInput ? controller.loadMore : null,
          ),
        const SizedBox(height: 16),
        _createForm(),
      ],
    );
  }

  Widget _createForm() {
    final draft = nameInput.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YYTextField(
          key: const ValueKey('playlist-add-name'),
          controller: nameInput,
          focusNode: nameFocus,
          label: '新歌单名称',
          placeholder: '例如：夜间聆听',
          enabled: !controller.busy,
          onSubmitted: (_) => _createAndAdd(nameInput.value),
        ),
        const SizedBox(height: 8),
        Text('1–512个字符，不含换行；创建歌单与添加歌曲一并保存。', style: YYTypography.caption),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: YYButton(
            label: '新建并添加',
            glyph: YYGlyph.plus,
            style: YYButtonStyle.primary,
            onPressed: controller.canCreate && _validName
                ? () => _createAndAdd(draft)
                : null,
          ),
        ),
      ],
    );
  }
}
