import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/fullscreen_button.dart';
import '../../../app/fullscreen_presenter.dart';
import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_artwork_placeholder.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_player_surface.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../domain/models/collection_models.dart';
import '../../../domain/models/track.dart';
import '../../../playback/playback_favorite_controller.dart';
import '../phone/phone_player_layout.dart';
import '../tablet/tablet_player_layout.dart';
import '../windows/windows_player_layout.dart';
import 'playback_favorite_feedback.dart';

part 'player_favorite_actions.dart';

/// Independent native route; owns only gesture previews and presentation state.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.platform,
    required this.presenter,
    required this.navigation,
    this.routeActive,
    this.fullscreen,
    this.favorite,
  });
  final YYPlatform platform;
  final PlaybackPresenter presenter;
  final AppNavigation navigation;
  final ValueListenable<bool>? routeActive;
  final FullscreenPresenter? fullscreen;

  /// Borrows root collection state without owning its lifetime or storage.
  final PlaybackFavoriteController? favorite;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double? _seekPreview, _volumePreview;
  int _generation = 0;
  bool _active = true, _hasArea = true;
  YYLayoutClass? _layout;
  Size? _viewportSize;
  late (String?, TrackRef?) _identity;

  @override
  void initState() {
    super.initState();
    _identity = (widget.presenter.entryId, widget.presenter.trackRef);
    widget.presenter.addListener(_onPlayback);
    widget.favorite?.addListener(_onFavorite);
    widget.routeActive?.addListener(_routeChanged);
  }

  void _invalidate() {
    _generation++;
    _seekPreview = _volumePreview = null;
  }

  void _onPlayback() {
    if (!mounted) return;
    setState(() {
      final identity = (widget.presenter.entryId, widget.presenter.trackRef);
      if (_identity != identity) {
        _identity = identity;
        _invalidate();
      }
      if (!widget.presenter.canSeek) _seekPreview = null;
      if (!widget.presenter.canChangeVolume) _volumePreview = null;
    });
  }

  void _routeChanged() {
    if (mounted) setState(_invalidate);
  }

  void _onFavorite() {
    if (mounted) setState(() {});
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
    if (_active != active) {
      _active = active;
      _invalidate();
    }
  }

  @override
  void didUpdateWidget(PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favorite != widget.favorite) {
      oldWidget.favorite?.removeListener(_onFavorite);
      widget.favorite?.addListener(_onFavorite);
      _invalidate();
    }
    if (oldWidget.presenter != widget.presenter) {
      oldWidget.presenter.removeListener(_onPlayback);
      widget.presenter.addListener(_onPlayback);
      _identity = (widget.presenter.entryId, widget.presenter.trackRef);
      _invalidate();
    }
    if (oldWidget.routeActive != widget.routeActive) {
      oldWidget.routeActive?.removeListener(_routeChanged);
      widget.routeActive?.addListener(_routeChanged);
      _invalidate();
    }
  }

  bool _canInteract(int generation) {
    if (!mounted ||
        !_active ||
        !_hasArea ||
        !(widget.routeActive?.value ?? true) ||
        generation != _generation) {
      return false;
    }
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    final box = context.findRenderObject();
    return box is RenderBox &&
        box.hasSize &&
        box.size.width > 0 &&
        box.size.height > 0;
  }

  @override
  void dispose() {
    _invalidate();
    widget.presenter.removeListener(_onPlayback);
    widget.favorite?.removeListener(_onFavorite);
    widget.routeActive?.removeListener(_routeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final hasArea = box.maxWidth > 0 && box.maxHeight > 0;
      if (_hasArea != hasArea) {
        _hasArea = hasArea;
        _invalidate();
      }
      if (!hasArea) return const SizedBox.shrink();
      final layout = classifyLayout(
        platform: widget.platform,
        width: box.maxWidth,
        height: box.maxHeight,
      );
      final viewportSize = Size(box.maxWidth, box.maxHeight);
      if (_layout != layout || _viewportSize != viewportSize) {
        _layout = layout;
        _viewportSize = viewportSize;
        _invalidate();
      }
      final presenter = widget.presenter;
      final generation = _generation;
      final entry = presenter.entryId;
      final favorite = widget.favorite;
      final data = presenter.data.copyWith(
        favorite: favorite?.state.isFavorite == true,
      );
      final theme = YYTheme.of(context);
      final compact = box.maxHeight < 500;
      final view = data.copyWith(
        position: _seekPreview == null
            ? data.position
            : Duration(
                microseconds: (data.duration.inMicroseconds * _seekPreview!)
                    .round(),
              ),
        volume: _volumePreview ?? data.volume,
      );
      VoidCallback? command(bool enabled, Future<void> Function() callback) =>
          enabled
          ? () {
              if (_canInteract(generation)) unawaited(callback());
            }
          : null;
      VoidCallback? action(bool enabled, VoidCallback callback) => enabled
          ? () {
              if (_canInteract(generation)) callback();
            }
          : null;
      final playerControls = YYFullPlayerContent(
        key: ValueKey(('player-content', entry, layout)),
        data: view,
        showFavorite: favorite?.state.isFavorite != null,
        favoriteBusy: favorite?.busy ?? false,
        onToggleFavorite: _favoriteAction(generation),
        statusLabel: presenter.statusLabel,
        compact: compact,
        titleSize: compact
            ? 22
            : widget.platform == YYPlatform.windows
            ? 40
            : layout == YYLayoutClass.androidPhone
            ? 28
            : 34,
        loading: presenter.busy,
        errorMessage: presenter.errorMessage,
        onTogglePlayback: command(
          presenter.canControl,
          presenter.togglePlayback,
        ),
        onPrevious: command(presenter.canControl, presenter.previous),
        onNext: command(presenter.canControl, presenter.next),
        onToggleShuffle: action(presenter.canControl, presenter.toggleShuffle),
        onCycleRepeat: action(presenter.canControl, presenter.cycleRepeat),
        onSeekPreview: presenter.canSeek
            ? (value) {
                if (_canInteract(generation)) {
                  setState(() => _seekPreview = value);
                }
              }
            : null,
        onSeekCommit: presenter.canSeek && entry != null
            ? (value) {
                if (!_canInteract(generation)) return;
                setState(() => _seekPreview = null);
                unawaited(
                  presenter.seek(
                    value,
                    expectedEntryId: entry,
                    isIntentCurrent: () => _canInteract(generation),
                  ),
                );
              }
            : null,
        onSeekCancel: () {
          if (_canInteract(generation) && _seekPreview != null) {
            setState(() => _seekPreview = null);
          }
        },
        onVolumePreview: presenter.canChangeVolume
            ? (value) {
                if (_canInteract(generation)) {
                  setState(() => _volumePreview = value);
                }
              }
            : null,
        onVolumeCommit: presenter.canChangeVolume
            ? (value) {
                if (!_canInteract(generation)) return;
                setState(() => _volumePreview = null);
                unawaited(presenter.setVolume(value));
              }
            : null,
        onVolumeCancel: () {
          if (_canInteract(generation) && _volumePreview != null) {
            setState(() => _volumePreview = null);
          }
        },
      );
      final controls =
          favorite == null || (!favorite.busy && favorite.failure == null)
          ? playerControls
          : Column(
              children: [
                PlaybackFavoriteFeedback(
                  controller: favorite,
                  permit: () => _canInteract(generation),
                ),
                playerControls,
              ],
            );
      Widget artwork(double dimension) => AnimatedScale(
        key: const ValueKey('player-page-artwork-scale'),
        scale: theme.reduceMotion || data.playing ? 1 : .94,
        duration: theme.motion(YYMotion.selected),
        curve: YYMotion.standard,
        child: YYArtworkPlaceholder(
          dimension: dimension,
          role: YYArtworkRole.player,
          semanticLabel: '暂无封面',
        ),
      );
      return PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _canInteract(generation)) widget.navigation.back();
        },
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.platform == YYPlatform.windows ? 26 : 18,
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    YYButton(
                      key: const ValueKey('route-back'),
                      label: '收起播放页',
                      glyph: YYGlyph.chevronDown,
                      iconOnly: true,
                      style: YYButtonStyle.quiet,
                      onPressed: action(true, widget.navigation.back),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '正在播放',
                            style: YYTypography.text(size: 14, weight: 730),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            compact
                                ? '${presenter.sourceLabel} · ${presenter.statusLabel}'
                                : presenter.sourceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: YYTypography.text(
                              size: 10,
                              color: theme.colors.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    YYButton(
                      key: const ValueKey('player-page-queue'),
                      label: '查看当前队列，${presenter.queueCount} 首',
                      glyph: YYGlyph.queue,
                      iconOnly: true,
                      style: YYButtonStyle.quiet,
                      onPressed: action(
                        true,
                        () => widget.navigation.openSystemPlaylist(
                          SystemPlaylistType.queue,
                        ),
                      ),
                    ),
                    YYButton(
                      key: const ValueKey('player-page-lyrics'),
                      label: '打开歌词',
                      glyph: YYGlyph.lyrics,
                      iconOnly: true,
                      style: YYButtonStyle.quiet,
                      onPressed: action(true, widget.navigation.openLyrics),
                    ),
                    FullscreenButton(
                      key: const ValueKey('player-fullscreen'),
                      presenter: widget.fullscreen,
                      isCurrent: () => _canInteract(generation),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: presenter.queueCount == 0
                      ? const Center(
                          child: YYEmptyState(message: '队列为空，请返回音乐库选择曲目。'),
                        )
                      : switch (layout) {
                          YYLayoutClass.androidPhone => PhonePlayerLayout(
                            artwork: artwork,
                            controls: controls,
                          ),
                          YYLayoutClass.androidTabletPortrait ||
                          YYLayoutClass.androidTabletLandscape =>
                            TabletPlayerLayout(
                              artwork: artwork,
                              controls: controls,
                            ),
                          _ => WindowsPlayerLayout(
                            artwork: artwork,
                            controls: controls,
                          ),
                        },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
