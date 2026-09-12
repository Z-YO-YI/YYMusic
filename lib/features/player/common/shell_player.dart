import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../design_system/yy_player_surface.dart';
import '../../../playback/playback_favorite_controller.dart';
import 'playback_favorite_feedback.dart';

part 'shell_favorite_actions.dart';

/// Shared presentation binding, not a second player or platform controller.
class ShellPlayer extends StatelessWidget {
  const ShellPlayer({
    super.key,
    required this.presenter,
    this.phone = false,
    this.compact = false,
    this.inspector = false,
    this.onOpen,
    this.onOpenLyrics,
    this.onOpenQueue,
    this.onOpenFullscreen,
    this.favorite,
    this.routeChanges,
    this.scopeIdentity,
  });

  final PlaybackPresenter presenter;
  final PlaybackFavoriteController? favorite;
  final Listenable? routeChanges;
  final Object? scopeIdentity;
  final bool phone;
  final bool compact;
  final bool inspector;
  final VoidCallback? onOpen;
  final VoidCallback? onOpenLyrics;
  final VoidCallback? onOpenQueue;
  final VoidCallback? onOpenFullscreen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: presenter,
    builder: (context, _) {
      final controls = _PlayerControls(
        // Reset gesture state when a queue entry or platform layout changes.
        key: ValueKey((presenter.entryId, phone, compact, inspector)),
        presenter: presenter,
        favorite: favorite,
        routeChanges: routeChanges,
        scopeIdentity: scopeIdentity,
        phone: phone,
        compact: compact,
        inspector: inspector,
        onOpen: onOpen,
        onOpenLyrics: onOpenLyrics,
        onOpenQueue: onOpenQueue,
        onOpenFullscreen: onOpenFullscreen,
      );
      if (inspector) return controls;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (presenter.errorMessage case final message?)
            YYErrorBanner(
              title: '播放暂不可用',
              message: message,
              actionLabel: '重试',
              onAction: presenter.canControl
                  ? () => unawaited(presenter.togglePlayback())
                  : null,
            ),
          controls,
        ],
      );
    },
  );
}

class _PlayerControls extends StatefulWidget {
  const _PlayerControls({
    super.key,
    required this.presenter,
    required this.phone,
    required this.compact,
    required this.inspector,
    required this.onOpen,
    required this.onOpenLyrics,
    required this.onOpenQueue,
    required this.onOpenFullscreen,
    required this.favorite,
    required this.routeChanges,
    required this.scopeIdentity,
  });
  final PlaybackPresenter presenter;
  final PlaybackFavoriteController? favorite;
  final Listenable? routeChanges;
  final Object? scopeIdentity;
  final bool phone;
  final bool compact;
  final bool inspector;
  final VoidCallback? onOpen;
  final VoidCallback? onOpenLyrics;
  final VoidCallback? onOpenQueue;
  final VoidCallback? onOpenFullscreen;
  @override
  State<_PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<_PlayerControls> {
  double? _seekPreview;
  double? _volumePreview;
  int _favoriteGeneration = 0;
  bool _favoriteVisible = true;
  Size? _favoriteViewport;

  @override
  void initState() {
    super.initState();
    widget.favorite?.addListener(_favoriteChanged);
    widget.routeChanges?.addListener(_favoriteRouteChanged);
  }

  void _favoriteChanged() {
    if (mounted) setState(() {});
  }

  void _favoriteRouteChanged() {
    _favoriteGeneration++;
    _favoriteChanged();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true) &&
        _focusAllowsFavorite(createDependency: true);
    if (_favoriteViewport != size || _favoriteVisible != visible) {
      _favoriteViewport = size;
      _favoriteVisible = visible;
      _favoriteGeneration++;
    }
  }

  @override
  void dispose() {
    _favoriteGeneration++;
    widget.favorite?.removeListener(_favoriteChanged);
    widget.routeChanges?.removeListener(_favoriteRouteChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(_PlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favorite != widget.favorite) {
      oldWidget.favorite?.removeListener(_favoriteChanged);
      widget.favorite?.addListener(_favoriteChanged);
      _favoriteGeneration++;
    }
    if (oldWidget.routeChanges != widget.routeChanges) {
      oldWidget.routeChanges?.removeListener(_favoriteRouteChanged);
      widget.routeChanges?.addListener(_favoriteRouteChanged);
      _favoriteGeneration++;
    }
    if (oldWidget.scopeIdentity != widget.scopeIdentity) _favoriteGeneration++;
    // YYSlider cancels its gesture when disabled; discard our preview too.
    if (!widget.presenter.canSeek) _seekPreview = null;
    if (!widget.presenter.canChangeVolume) _volumePreview = null;
  }

  @override
  Widget build(BuildContext context) {
    final presenter = widget.presenter;
    final favorite = widget.favorite;
    final favoriteGeneration = _favoriteGeneration;
    final data = presenter.data.copyWith(
      favorite: favorite?.state.isFavorite == true,
    );
    final entry = presenter.entryId;
    final preview = _seekPreview;
    final view = data.copyWith(
      position: preview == null || !presenter.canSeek
          ? data.position
          : Duration(
              microseconds: (data.duration.inMicroseconds * preview).round(),
            ),
      volume: _volumePreview ?? data.volume,
    );
    final toggle = presenter.canControl
        ? () => unawaited(presenter.togglePlayback())
        : null;
    final next = presenter.canControl
        ? () => unawaited(presenter.next())
        : null;
    final previous = presenter.canControl
        ? () => unawaited(presenter.previous())
        : null;
    final shuffle = presenter.canControl ? presenter.toggleShuffle : null;
    final repeat = presenter.canControl ? presenter.cycleRepeat : null;
    final void Function(double)? seekPreview = presenter.canSeek
        ? (value) => setState(() => _seekPreview = value)
        : null;
    final void Function(double)? seekCommit = presenter.canSeek && entry != null
        ? (value) {
            setState(() => _seekPreview = null);
            unawaited(presenter.seek(value, expectedEntryId: entry));
          }
        : null;
    void seekCancel() => setState(() => _seekPreview = null);
    if (widget.inspector) {
      return YYNowPlayingInspector(
        data: view,
        sourceLabel: presenter.sourceLabel,
        statusLabel: presenter.statusLabel,
        queueCount: presenter.queueCount,
        errorMessage: presenter.errorMessage,
        loading: presenter.busy,
        onTogglePlayback: toggle,
        onPrevious: previous,
        onNext: next,
        onToggleShuffle: shuffle,
        onCycleRepeat: repeat,
        onSeekPreview: seekPreview,
        onSeekCommit: seekCommit,
        onSeekCancel: seekCancel,
      );
    }
    if (widget.phone) {
      return YYMiniPlayer(
        data: view,
        loading: presenter.busy,
        onOpen: widget.onOpen,
        onOpenLyrics: presenter.queueCount > 0 ? widget.onOpenLyrics : null,
        onTogglePlayback: toggle,
        onNext: next,
      );
    }
    final bar = YYDesktopPlayerBar(
      data: view,
      favoriteKnown: favorite == null || favorite.state.isFavorite != null,
      favoriteBusy: favorite?.busy ?? false,
      onToggleFavorite: _favoriteAction(favoriteGeneration),
      onOpenQueue: _queueAction(favoriteGeneration),
      onOpenFullscreen: _navigationAction(
        favoriteGeneration,
        widget.onOpenFullscreen,
      ),
      compact: widget.compact,
      loading: presenter.busy,
      onOpen: widget.onOpen,
      onOpenLyrics: presenter.queueCount > 0 ? widget.onOpenLyrics : null,
      onTogglePlayback: toggle,
      onNext: next,
      onPrevious: previous,
      onToggleShuffle: shuffle,
      onCycleRepeat: repeat,
      onSeekPreview: seekPreview,
      onSeekCommit: seekCommit,
      onSeekCancel: seekCancel,
      onVolumePreview: presenter.canChangeVolume
          ? (value) => setState(() => _volumePreview = value)
          : null,
      onVolumeCommit: presenter.canChangeVolume
          ? (value) {
              setState(() => _volumePreview = null);
              unawaited(presenter.setVolume(value));
            }
          : null,
      onVolumeCancel: () => setState(() => _volumePreview = null),
    );
    if (favorite == null || (!favorite.busy && favorite.failure == null)) {
      return bar;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .2,
          ),
          child: SingleChildScrollView(
            child: PlaybackFavoriteFeedback(
              controller: favorite,
              permit: () => _canUseShellAction(favoriteGeneration),
            ),
          ),
        ),
        bar,
      ],
    );
  }
}
