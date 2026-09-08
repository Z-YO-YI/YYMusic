import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_view_state.dart';
import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_context_menu.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_theme.dart';
import '../../../domain/models/track.dart';
import '../phone/phone_library_layout.dart';
import '../tablet/tablet_library_layout.dart';
import '../windows/windows_library_layout.dart';
import 'library_controller.dart';
import 'library_sections.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.platform,
    required this.controller,
    required this.playback,
    required this.navigation,
    required this.viewState,
  });
  final YYPlatform platform;
  final LibraryController controller;
  final PlaybackPresenter playback;
  final AppNavigation navigation;
  final AppViewState viewState;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final ScrollController _scroll;
  int _revision = 0;
  Track? _menuTrack;
  FocusNode? _returnFocus;
  int _menuGeneration = 0;
  bool _pickerOpen = false;
  @override
  void initState() {
    super.initState();
    _revision = widget.controller.viewRevision;
    _scroll = ScrollController(
      initialScrollOffset: widget.viewState.scrollOffset(AppRoute.library),
    )..addListener(_save);
    widget.controller.addListener(_changed);
    widget.controller.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = !_pickerOpen && TickerMode.valuesOf(context).enabled;
    widget.controller.setActive(active);
    if (!active && _menuTrack != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dismiss(restoreFocus: false);
      });
    }
  }

  void _changed() {
    if (_revision == widget.controller.viewRevision) return;
    _revision = widget.controller.viewRevision;
    _dismiss(restoreFocus: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _save() =>
      widget.viewState.saveScrollOffset(AppRoute.library, _scroll.offset);
  void _openMenu(Track track) {
    if (_pickerOpen) return;
    _menuGeneration++;
    _returnFocus = FocusManager.instance.primaryFocus;
    setState(() => _menuTrack = track);
  }

  void _dismiss({bool restoreFocus = true}) {
    if (_menuTrack == null) return;
    _menuGeneration++;
    setState(() => _menuTrack = null);
    final focus = _returnFocus;
    _returnFocus = null;
    if (restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && focus?.context != null) focus!.requestFocus();
      });
    }
  }

  Future<void> _pickPlaylist(Track track) async {
    if (!widget.controller.canAddToPlaylist(track) || _pickerOpen) return;
    final focus = _returnFocus;
    _dismiss(restoreFocus: false);
    _pickerOpen = true;
    widget.controller.setActive(false);
    try {
      await widget.navigation.addToPlaylist(track.ref, title: track.title);
    } finally {
      if (mounted) {
        _pickerOpen = false;
        final active = TickerMode.valuesOf(context).enabled;
        widget.controller.setActive(active);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              !_pickerOpen &&
              TickerMode.valuesOf(context).enabled &&
              (ModalRoute.isCurrentOf(context) ?? true) &&
              focus?.context != null) {
            focus!.requestFocus();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    widget.controller.setActive(false);
    widget.controller.removeListener(_changed);
    _scroll.removeListener(_save);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: YYTheme.of(context).colors.base,
    child: ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.playback]),
      builder: (context, _) {
        final size = MediaQuery.sizeOf(context);
        final sections = LibrarySections(
          controller: widget.controller,
          playback: widget.playback,
          navigation: widget.navigation,
          menu: _openMenu,
        );
        final content = widget.platform == YYPlatform.windows
            ? WindowsLibraryLayout(sections: sections, scroll: _scroll)
            : size.width < 600
            ? PhoneLibraryLayout(sections: sections, scroll: _scroll)
            : TabletLibraryLayout(
                sections: sections,
                scroll: _scroll,
                landscape: size.width > size.height,
              );
        final track = _menuTrack;
        final generation = _menuGeneration;
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
                          child: YYContextMenu(
                            title: track.title,
                            meta:
                                '${widget.controller.sourceLabel(track.sourceId)} · ${LibrarySections.availabilityLabel(track)}',
                            items: [
                              YYContextMenuItem(
                                id: 'play',
                                label: '播放歌曲',
                                glyph: YYGlyph.play,
                                enabled: widget.controller.canPlay(track),
                              ),
                              YYContextMenuItem(
                                id: 'favorite',
                                label: widget.controller.isFavorite(track)
                                    ? '取消收藏'
                                    : '收藏歌曲',
                                glyph: YYGlyph.heart,
                                enabled: widget.controller.canFavorite(track),
                              ),
                              YYContextMenuItem(
                                id: 'playlist',
                                label: '添加到歌单',
                                glyph: YYGlyph.playlist,
                                enabled: widget.controller.canAddToPlaylist(
                                  track,
                                ),
                              ),
                            ],
                            onDismiss: _dismiss,
                            onSelected: (id) {
                              if (_pickerOpen ||
                                  generation != _menuGeneration ||
                                  !identical(_menuTrack, track)) {
                                return;
                              }
                              if (id == 'playlist') {
                                unawaited(_pickPlaylist(track));
                                return;
                              }
                              _dismiss();
                              if (id == 'play') {
                                unawaited(widget.controller.play(track));
                              }
                              if (id == 'favorite') {
                                unawaited(
                                  widget.controller.toggleFavorite(track),
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
  );
}
