import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_lyrics_line.dart';
import '../../../domain/models/lyrics.dart';

/// Lazy, bidirectional lyrics body. The parent owns playback and seek authority.
class LyricsViewport extends StatefulWidget {
  const LyricsViewport({
    super.key,
    required this.document,
    required this.snapshotKey,
    required this.position,
    required this.activeIndex,
    required this.phoneLayout,
    this.active = true,
    this.showTranslation = true,
    this.onSeek,
  });

  final LyricsDocument document;
  final Object snapshotKey;
  final Duration position;
  final int? activeIndex;
  final bool phoneLayout, active, showTranslation;
  final ValueChanged<int>? onSeek;

  @override
  State<LyricsViewport> createState() => _LyricsViewportState();
}

class _LyricsViewportState extends State<LyricsViewport> {
  static const _resumeDelay = Duration(seconds: 5);
  final _centerSliver = GlobalKey();
  GlobalKey _anchorLine = GlobalKey();
  final _viewport = GlobalKey();
  ScrollController _scroll = ScrollController();
  Timer? _resumeTimer;
  int _anchor = 0, _generation = 0, _anchorVersion = 0;
  bool _manual = false, _active = false, _hasArea = false;
  Size? _size;
  TextScaler? _textScaler;

  int? get _currentIndex {
    final index = widget.activeIndex;
    return widget.document.kind == LyricsKind.synchronized &&
            index != null &&
            index >= 0 &&
            index < widget.document.lines.length
        ? index
        : null;
  }

  @override
  void initState() {
    super.initState();
    _anchor = _currentIndex ?? 0;
  }

  void _invalidate() {
    _generation++;
    _resumeTimer?.cancel();
    _resumeTimer = null;
  }

  void _rebase() {
    _invalidate();
    _anchorVersion++;
    final nextAnchor =
        _currentIndex ?? _anchor.clamp(0, widget.document.lines.length - 1);
    if (nextAnchor != _anchor) _anchorLine = GlobalKey();
    _anchor = nextAnchor;
    final previous = _scroll;
    _scroll = ScrollController();
    // The old Scrollable detaches during this frame, before disposal.
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_canUse(generation) || _manual) return;
      _reveal(_anchorLine.currentContext);
    });
  }

  void _reveal(BuildContext? targetContext) {
    final target = targetContext?.findRenderObject();
    final viewport = _viewport.currentContext?.findRenderObject();
    if (target is RenderBox &&
        viewport is RenderBox &&
        target.hasSize &&
        viewport.hasSize &&
        _scroll.hasClients) {
      // Reveal calculations assume an edge anchor. Measure the actual center
      // instead, because this bidirectional viewport has a 0.5 anchor.
      final center = target
          .localToGlobal(Offset(0, target.size.height / 2), ancestor: viewport)
          .dy;
      final position = _scroll.position;
      _scroll.jumpTo(
        (position.pixels + center - viewport.size.height / 2).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    }
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
    final scaler = MediaQuery.textScalerOf(context);
    if (_active != active || _textScaler != scaler) {
      _active = active;
      _textScaler = scaler;
      _manual = false;
      _rebase();
    }
  }

  @override
  void didUpdateWidget(LyricsViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.document, widget.document) ||
        !identical(oldWidget.snapshotKey, widget.snapshotKey) ||
        oldWidget.active != widget.active ||
        oldWidget.showTranslation != widget.showTranslation ||
        oldWidget.phoneLayout != widget.phoneLayout) {
      if (!identical(oldWidget.document, widget.document) ||
          !identical(oldWidget.snapshotKey, widget.snapshotKey)) {
        _anchor = 0;
        _anchorLine = GlobalKey();
      }
      _manual = false;
      _rebase();
    } else if (!_manual &&
        oldWidget.activeIndex != widget.activeIndex &&
        _currentIndex != null) {
      _rebase();
    }
  }

  bool _canUse(int generation) {
    if (!mounted ||
        !_active ||
        !widget.active ||
        !_hasArea ||
        generation != _generation) {
      return false;
    }
    final box = context.findRenderObject();
    return box is RenderBox &&
        box.hasSize &&
        box.size.width > 0 &&
        box.size.height > 0;
  }

  void _manualScroll() {
    if (!_canUse(_generation) ||
        widget.document.kind != LyricsKind.synchronized) {
      return;
    }
    _resumeTimer?.cancel();
    if (!_manual) setState(() => _manual = true);
    _armResume();
  }

  void _armResume() {
    _resumeTimer?.cancel();
    final generation = _generation;
    _resumeTimer = Timer(_resumeDelay, () {
      if (!_canUse(generation) || !_manual) return;
      if (_scroll.hasClients && _scroll.position.isScrollingNotifier.value) {
        _armResume();
      } else {
        _resume();
      }
    });
  }

  void _resume() {
    if (!_canUse(_generation)) return;
    setState(() {
      _manual = false;
      _invalidate();
      if (_currentIndex != null) _rebase();
    });
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if ((notification is ScrollStartNotification &&
            notification.dragDetails != null) ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails != null) ||
        (notification is UserScrollNotification &&
            notification.direction != ScrollDirection.idle)) {
      _manualScroll();
    } else if (notification is ScrollEndNotification && _manual) {
      _armResume();
    }
    return false;
  }

  YYLyricsLineState _lineState(int index) {
    if (widget.document.kind == LyricsKind.plain) return YYLyricsLineState.past;
    if (index == _currentIndex) return YYLyricsLineState.active;
    final line = widget.document.lines[index];
    if (line.end != null) {
      // Extreme valid offsets cannot wrap around into an incorrect past state.
      final time =
          BigInt.from(widget.position.inMicroseconds) -
          BigInt.from(widget.document.offset.inMicroseconds);
      if (time >= BigInt.from(line.end!.inMicroseconds)) {
        return YYLyricsLineState.past;
      }
    }
    return YYLyricsLineState.future;
  }

  Widget _line(int index, int generation) {
    final line = widget.document.lines[index];
    final synchronized = widget.document.kind == LyricsKind.synchronized;
    return IndexedSemantics(
      index: index,
      child: Padding(
        key: ValueKey(('lyric-row', index)),
        padding: const EdgeInsets.only(bottom: 28),
        child: YYLyricsLine(
          key: index == _anchor ? _anchorLine : ValueKey(('lyric-line', index)),
          text: line.text,
          translation: widget.showTranslation ? line.translation : null,
          phoneLayout: widget.phoneLayout,
          onFocusReveal: (target) {
            if (_canUse(generation)) {
              _manualScroll();
              _reveal(target);
            }
          },
          state: _lineState(index),
          onPressed: synchronized && widget.onSeek != null && widget.active
              ? () {
                  if (_canUse(generation)) widget.onSeek?.call(index);
                }
              : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _invalidate();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      _hasArea = size.width > 0 && size.height > 0;
      if (_size != size) {
        _size = size;
        _manual = false;
        _rebase();
      }
      if (!_hasArea) return const SizedBox.shrink();
      final generation = _generation;
      return Column(
        children: [
          Expanded(
            child: Listener(
              key: _viewport,
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) _manualScroll();
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: KeyedSubtree(
                  key: ValueKey(_anchorVersion),
                  child: CustomScrollView(
                    key: const ValueKey('lyrics-scroll'),
                    controller: _scroll,
                    center: _centerSliver,
                    anchor: .5,
                    scrollCacheExtent: const ScrollCacheExtent.pixels(200),
                    semanticChildCount: widget.document.lines.length,
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => index == _anchor
                              ? SizedBox(height: size.height / 2)
                              : _line(_anchor - index - 1, generation),
                          childCount: _anchor + 1,
                          addSemanticIndexes: false,
                          addAutomaticKeepAlives: false,
                        ),
                      ),
                      SliverList(
                        key: _centerSliver,
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              index + _anchor == widget.document.lines.length
                              ? SizedBox(height: size.height / 2)
                              : _line(index + _anchor, generation),
                          childCount:
                              widget.document.lines.length - _anchor + 1,
                          addSemanticIndexes: false,
                          addAutomaticKeepAlives: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_manual)
            YYButton(
              key: const ValueKey('lyrics-resume-follow'),
              label: '回到当前歌词',
              onPressed: () {
                if (_canUse(generation)) _resume();
              },
            ),
        ],
      );
    },
  );
}
