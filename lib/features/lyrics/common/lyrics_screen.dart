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
import '../../../design_system/yy_lyrics_player_dock.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/lyrics.dart';
import '../../../domain/models/track.dart';
import '../../../playback/lyrics_controller.dart';
import '../phone/phone_lyrics_layout.dart';
import '../tablet/tablet_lyrics_layout.dart';
import '../windows/windows_lyrics_layout.dart';
import 'lyrics_viewport.dart';

/// Independent route borrowing the unique root lyrics and playback controllers.
class LyricsScreen extends StatefulWidget {
  const LyricsScreen({
    super.key,
    required this.platform,
    required this.controller,
    required this.playback,
    required this.navigation,
    this.routeActive,
    this.fullscreen,
  });
  final YYPlatform platform;
  final LyricsController controller;
  final PlaybackPresenter playback;
  final AppNavigation navigation;
  final ValueListenable<bool>? routeActive;
  final FullscreenPresenter? fullscreen;

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  static const _atmosphere = Color(0xFF34454D);
  final _viewportKey = GlobalKey();
  bool _translation = true, _visible = false, _hasArea = false;
  bool _activityScheduled = false;
  double? _seekPreview;
  int _generation = 0;
  Size? _size;
  late (String?, TrackRef?) _identity;

  @override
  void initState() {
    super.initState();
    _identity = (widget.playback.entryId, widget.playback.trackRef);
    widget.controller.addListener(_lyricsChanged);
    widget.playback.addListener(_playbackChanged);
    widget.routeActive?.addListener(_routeChanged);
  }

  void _invalidate() {
    _generation++;
    _seekPreview = null;
  }

  bool get _wantsActive =>
      _visible && _hasArea && (widget.routeActive?.value ?? true);

  void _requestActivity() {
    if (_activityScheduled) return;
    _activityScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activityScheduled = false;
      if (mounted) widget.controller.setActive(_wantsActive);
    });
  }

  void _lyricsChanged() {
    if (mounted) setState(() {});
  }

  void _playbackChanged() {
    if (!mounted) return;
    setState(() {
      final identity = (widget.playback.entryId, widget.playback.trackRef);
      if (identity != _identity) {
        _identity = identity;
        _invalidate();
      }
      if (!widget.playback.canSeek) _seekPreview = null;
    });
  }

  void _routeChanged() {
    if (!mounted) return;
    setState(_invalidate);
    _requestActivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final visible =
        size.width > 0 &&
        size.height > 0 &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (_visible != visible) {
      _visible = visible;
      _invalidate();
    }
    _requestActivity();
  }

  @override
  void didUpdateWidget(LyricsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_lyricsChanged);
      oldWidget.controller.setActive(false);
      widget.controller.addListener(_lyricsChanged);
      _invalidate();
    }
    if (oldWidget.playback != widget.playback) {
      oldWidget.playback.removeListener(_playbackChanged);
      widget.playback.addListener(_playbackChanged);
      _identity = (widget.playback.entryId, widget.playback.trackRef);
      _invalidate();
    }
    if (oldWidget.routeActive != widget.routeActive) {
      oldWidget.routeActive?.removeListener(_routeChanged);
      widget.routeActive?.addListener(_routeChanged);
      _invalidate();
    }
    _requestActivity();
  }

  bool _canUse(int generation) {
    if (!mounted || !_wantsActive || generation != _generation) return false;
    final box = context.findRenderObject();
    return box is RenderBox &&
        box.hasSize &&
        box.size.width > 0 &&
        box.size.height > 0;
  }

  @override
  void dispose() {
    _invalidate();
    widget.controller.removeListener(_lyricsChanged);
    widget.playback.removeListener(_playbackChanged);
    widget.routeActive?.removeListener(_routeChanged);
    widget.controller.setActive(false);
    super.dispose();
  }

  Widget _message(String title, String detail, {VoidCallback? retry}) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const YYIcon(
                glyph: YYGlyph.lyrics,
                size: 34,
                color: Color(0xB8FFFFFF),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: YYTypography.text(
                  size: 28,
                  weight: 780,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                detail,
                style: YYTypography.text(
                  size: 14,
                  height: 1.7,
                  color: const Color(0xB8FFFFFF),
                ),
              ),
              if (retry != null) ...[
                const SizedBox(height: 18),
                YYButton(label: '重试', onPressed: retry),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      _hasArea = size.width > 0 && size.height > 0;
      if (_size != size) {
        _size = size;
        _invalidate();
      }
      _requestActivity();
      if (!_hasArea) return const SizedBox.shrink();
      final generation = _generation;
      final playback = widget.playback;
      final controller = widget.controller;
      final state = controller.state;
      final document = state.data;
      final data = playback.data;
      final entry = playback.entryId;
      final layout = classifyLayout(
        platform: widget.platform,
        width: size.width,
        height: size.height,
      );
      final phone = layout == YYLayoutClass.androidPhone;
      final theme = YYTheme.of(context);
      VoidCallback? action(bool enabled, VoidCallback callback) => enabled
          ? () {
              if (_canUse(generation)) callback();
            }
          : null;
      VoidCallback? command(bool enabled, Future<void> Function() callback) =>
          action(enabled, () => unawaited(callback()));
      final retryLyrics = action(_wantsActive, controller.refresh);
      final header = Row(
        children: [
          YYButton(
            key: const ValueKey('route-back'),
            label: '关闭歌词',
            glyph: YYGlyph.chevronDown,
            iconOnly: true,
            style: YYButtonStyle.quiet,
            onPressed: action(true, widget.navigation.back),
          ),
          const SizedBox(width: 8),
          const YYArtworkPlaceholder(
            dimension: 32,
            role: YYArtworkRole.lyricsDock,
            semanticLabel: '暂无封面',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: '${data.title}，${data.artist}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: YYTypography.text(
                      size: phone ? 12 : 15,
                      weight: 750,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${data.artist} · ${playback.statusLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: YYTypography.text(
                      size: 10,
                      color: const Color(0xB8FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (document?.translationLanguage != null) ...[
            const SizedBox(width: 8),
            YYButton(
              key: const ValueKey('lyrics-translation'),
              label: _translation ? '隐藏翻译' : '显示翻译',
              style: YYButtonStyle.quiet,
              onPressed: action(
                true,
                () => setState(() {
                  _translation = !_translation;
                  _invalidate();
                }),
              ),
            ),
          ],
          const SizedBox(width: 4),
          FullscreenButton(
            key: const ValueKey('lyrics-fullscreen'),
            presenter: widget.fullscreen,
            isCurrent: () => _canUse(generation),
          ),
          YYButton(
            key: const ValueKey('lyrics-refresh'),
            label: '重新读取歌词',
            glyph: YYGlyph.refresh,
            iconOnly: true,
            style: YYButtonStyle.quiet,
            onPressed: state.phase != LoadPhase.loading && entry != null
                ? retryLyrics
                : null,
          ),
        ],
      );
      final body = switch (state.phase) {
        LoadPhase.data => LyricsViewport(
          key: _viewportKey,
          document: document!,
          snapshotKey: state,
          position: data.position,
          activeIndex: controller.activeIndex,
          phoneLayout: phone,
          active: _wantsActive,
          showTranslation: _translation,
          onSeek: playback.canSeek && document.kind == LyricsKind.synchronized
              ? (index) {
                  if (_canUse(generation)) {
                    unawaited(
                      controller.seekLine(
                        index,
                        expectedState: state,
                        isIntentCurrent: () => _canUse(generation),
                      ),
                    );
                  }
                }
              : null,
        ),
        LoadPhase.loading => _message('正在读取歌词', '请稍候。'),
        LoadPhase.empty => _message(
          '暂无歌词',
          '当前曲目没有歌词，播放不受影响。',
          retry: retryLyrics,
        ),
        LoadPhase.error => _message(
          '歌词读取失败',
          '请重试。正在播放的音乐不会停止。',
          retry: retryLyrics,
        ),
        LoadPhase.idle => _message(
          entry == null ? '尚未选择音乐' : '等待播放',
          '从音乐库选择并播放曲目后，可在这里查看歌词。',
        ),
      };
      final error =
          playback.errorMessage ??
          (controller.seekFailure == null ? null : '歌词跳转未完成，请恢复播放后再次点击歌词。');
      final content = error == null
          ? body
          : Column(
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: YYErrorBanner(
                      title: '播放操作未完成',
                      message: error,
                      actionLabel: '重试播放',
                      onAction: command(
                        playback.canControl,
                        playback.togglePlayback,
                      ),
                    ),
                  ),
                ),
                Expanded(flex: 3, child: body),
              ],
            );
      final view = _seekPreview == null
          ? data
          : data.copyWith(
              position: Duration(
                microseconds: (data.duration.inMicroseconds * _seekPreview!)
                    .round(),
              ),
            );
      final dock = YYLyricsPlayerDock(
        data: view,
        atmosphereColor: _atmosphere,
        showFavorite: false,
        loading: playback.busy,
        onPrevious: command(playback.canControl, playback.previous),
        onTogglePlayback: command(playback.canControl, playback.togglePlayback),
        onNext: command(playback.canControl, playback.next),
        onReturnToPlayer: action(true, widget.navigation.openPlayer),
        onSeekPreview: playback.canSeek
            ? (value) {
                if (_canUse(generation)) setState(() => _seekPreview = value);
              }
            : null,
        onSeekCommit: playback.canSeek && entry != null
            ? (value) {
                if (!_canUse(generation)) return;
                setState(() => _seekPreview = null);
                unawaited(
                  playback.seek(
                    value,
                    expectedEntryId: entry,
                    isIntentCurrent: () => _canUse(generation),
                  ),
                );
              }
            : null,
        onSeekCancel: () {
          if (_canUse(generation) && _seekPreview != null) {
            setState(() => _seekPreview = null);
          }
        },
      );
      return YYTheme(
        data: YYThemeData(
          brightness: Brightness.dark,
          accent: theme.accent,
          reduceMotion: theme.reduceMotion,
          reduceGlass: theme.reduceGlass,
        ),
        child: ColoredBox(
          color: _atmosphere,
          child: PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && _canUse(generation)) widget.navigation.back();
            },
            child: SafeArea(
              child: switch (layout) {
                YYLayoutClass.androidPhone => PhoneLyricsLayout(
                  header: header,
                  body: content,
                  dock: dock,
                ),
                YYLayoutClass.androidTabletPortrait ||
                YYLayoutClass.androidTabletLandscape => TabletLyricsLayout(
                  header: header,
                  body: content,
                  dock: dock,
                ),
                _ => WindowsLyricsLayout(
                  header: header,
                  body: content,
                  dock: dock,
                ),
              },
            ),
          ),
        ),
      );
    },
  );
}
