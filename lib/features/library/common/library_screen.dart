import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_view_state.dart';
import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_theme.dart';
import '../../../domain/models/collection_models.dart';
import '../../../domain/models/track.dart';
import '../../../playback/queue_controller.dart';
import '../../../playback/queue_edit_result.dart';
import '../../local_music/common/local_music_panel.dart';
import '../../queue/common/queue_operation_feedback.dart';
import '../phone/phone_library_layout.dart';
import '../tablet/tablet_library_layout.dart';
import '../windows/windows_library_layout.dart';
import 'library_controller.dart';
import 'library_sections.dart';
import 'library_track_menu.dart';

part 'library_queue_actions.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.platform,
    required this.controller,
    required this.playback,
    required this.navigation,
    required this.viewState,
    this.queue,
  });
  final YYPlatform platform;
  final LibraryController controller;
  final PlaybackPresenter playback;
  final AppNavigation navigation;
  final AppViewState viewState;
  final QueueController? queue;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final ScrollController _scroll;
  final _localPanelKey = GlobalKey(debugLabel: 'Library local overview');
  int _revision = 0;
  Track? _menuTrack;
  FocusNode? _returnFocus;
  int _menuGeneration = 0;
  bool _pickerOpen = false;
  QueueSnapshot? _menuQueue;
  bool Function()? _menuSourcePermit;
  int _queueEpoch = 0;
  bool _queueActive = false;
  Size? _queueSize;
  String? _queueNotice;
  Object? _noticeIdentity;
  void _setQueueNotice(String? notice) => setState(() {
    _queueNotice = notice;
    _noticeIdentity = notice == null ? null : Object();
  });
  @override
  void initState() {
    super.initState();
    _revision = widget.controller.viewRevision;
    _scroll = ScrollController(
      initialScrollOffset: widget.viewState.scrollOffset(AppRoute.library),
    )..addListener(_save);
    widget.controller.addListener(_changed);
    widget.queue?.addListener(_queueChanged);
    widget.controller.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final active =
        !_pickerOpen &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true) &&
        !size.isEmpty;
    if (_queueSize != size || _queueActive != active) {
      _queueEpoch++;
      _queueNotice = null;
      final generation = _menuGeneration;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == _menuGeneration) {
          _dismiss(restoreFocus: false);
        }
      });
    }
    _queueSize = size;
    _queueActive = active;
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
    _queueEpoch++;
    _queueNotice = null;
    _noticeIdentity = null;
    _dismiss(restoreFocus: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _save() =>
      widget.viewState.saveScrollOffset(AppRoute.library, _scroll.offset);
  void _openMenu(Track track) {
    if (_pickerOpen || !_queueActive || widget.queue?.editBusy == true) return;
    _menuGeneration++;
    _menuQueue = widget.queue?.state;
    _menuSourcePermit = widget.controller.queueSourcePermit(track);
    _returnFocus = FocusManager.instance.primaryFocus;
    setState(() => _menuTrack = track);
  }

  void _dismiss({bool restoreFocus = true}) {
    if (_menuTrack == null) return;
    _menuGeneration++;
    _menuQueue = null;
    _menuSourcePermit = null;
    setState(() => _menuTrack = null);
    final focus = _returnFocus;
    _returnFocus = null;
    if (restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_queuePageLive && _menuTrack == null && focus?.context != null) {
          focus!.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _queueEpoch++;
    widget.queue?.removeListener(_queueChanged);
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
      listenable: Listenable.merge([
        widget.controller,
        widget.playback,
        widget.queue,
      ]),
      builder: (context, _) {
        final size = MediaQuery.sizeOf(context);
        final sections = LibrarySections(
          controller: widget.controller,
          playback: widget.playback,
          navigation: widget.navigation,
          menu: _openMenu,
          queueFeedback: _queueFeedback(),
          localPanel: widget.controller.localMusic == null
              ? null
              : LocalMusicPanel(
                  key: _localPanelKey,
                  controller: widget.controller.localMusic!,
                  platform: widget.platform,
                  enabled: !_pickerOpen && _menuTrack == null,
                ),
          canNavigateSystem: () =>
              mounted &&
              !_pickerOpen &&
              _menuTrack == null &&
              widget.controller.category == LibraryCategory.playlists &&
              MediaQuery.sizeOf(context).width > 0 &&
              MediaQuery.sizeOf(context).height > 0,
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
                          child: LibraryTrackMenu(
                            track: track,
                            controller: widget.controller,
                            canInsert:
                                _queueActive &&
                                widget.queue != null &&
                                widget.queue!.editBusy == false &&
                                identical(widget.queue!.state, _menuQueue) &&
                                (_menuSourcePermit?.call() ?? false),
                            onDismiss: _dismiss,
                            onSelected: (id) {
                              if (!_queuePageLive ||
                                  generation != _menuGeneration ||
                                  !identical(_menuTrack, track)) {
                                return;
                              }
                              if (id == 'playlist') {
                                unawaited(_pickPlaylist(track));
                                return;
                              }
                              if (id == 'queue' || id == 'next') {
                                unawaited(
                                  _insertTrack(track, next: id == 'next'),
                                );
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
