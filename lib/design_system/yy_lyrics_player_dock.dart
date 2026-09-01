import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_artwork_placeholder.dart';
import 'yy_icon.dart';
import 'yy_player_data.dart';
import 'yy_slider.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

typedef YYLyricsDockValueChanged = void Function(double value);

/// Controlled lyrics transport. It never owns playback, seek or navigation.
class YYLyricsPlayerDock extends StatelessWidget {
  const YYLyricsPlayerDock({
    super.key,
    required this.data,
    this.atmosphereColor = const Color(0xFF34454D),
    this.loading = false,
    this.onPrevious,
    this.onTogglePlayback,
    this.onNext,
    this.onSeekPreview,
    this.onSeekCommit,
    this.onSeekCancel,
    this.onToggleFavorite,
    this.onReturnToPlayer,
  });

  final YYNowPlayingViewData data;
  final Color atmosphereColor;
  final bool loading;
  final VoidCallback? onPrevious;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onNext;
  final YYLyricsDockValueChanged? onSeekPreview;
  final YYLyricsDockValueChanged? onSeekCommit;
  final VoidCallback? onSeekCancel;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onReturnToPlayer;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '歌词播放器',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.sizeOf(context);
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : media.width;
        final phone = width < 600;
        final lowLandscape = media.height <= 620 && media.width > media.height;
        final twoRows = width <= 900;
        final artworkDimension = lowLandscape
            ? YYQueueLyricsMetrics.landscapeLyricsDockArtwork
            : phone
            ? YYQueueLyricsMetrics.phoneLyricsDockArtwork
            : YYQueueLyricsMetrics.lyricsDockArtwork;
        final padding = lowLandscape
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 7)
            : phone
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 13, vertical: 11);
        final track = _LyricsDockTrack(
          data: data,
          loading: loading,
          artworkDimension: artworkDimension,
          artworkRadius: phone ? 11 : 13,
          phone: phone,
        );
        final center = _LyricsDockCenter(
          data: data,
          atmosphereColor: atmosphereColor,
          phone: phone,
          lowLandscape: lowLandscape,
          loading: loading,
          onPrevious: onPrevious,
          onTogglePlayback: onTogglePlayback,
          onNext: onNext,
          onSeekPreview: onSeekPreview,
          onSeekCommit: onSeekCommit,
          onSeekCancel: onSeekCancel,
        );
        final actions = _LyricsDockActions(
          favorite: data.favorite,
          hideFavorite: phone,
          loading: loading,
          onToggleFavorite: onToggleFavorite,
          onReturnToPlayer: onReturnToPlayer,
        );
        final child = twoRows
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: track),
                      const SizedBox(width: 12),
                      actions,
                    ],
                  ),
                  const SizedBox(height: 7),
                  center,
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 8, child: track),
                  const SizedBox(width: 16),
                  Expanded(flex: 14, child: center),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: actions),
                ],
              );
        return _LyricsGlass(
          atmosphereColor: atmosphereColor,
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: lowLandscape
                  ? 64
                  : YYQueueLyricsMetrics.lyricsDockMinHeight,
            ),
            child: child,
          ),
        );
      },
    ),
  );
}

class _LyricsDockTrack extends StatelessWidget {
  const _LyricsDockTrack({
    required this.data,
    required this.loading,
    required this.artworkDimension,
    required this.artworkRadius,
    required this.phone,
  });

  final YYNowPlayingViewData data;
  final bool loading;
  final double artworkDimension;
  final double artworkRadius;
  final bool phone;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${data.title}，${data.artist}',
    value: loading ? '加载中' : null,
    excludeSemantics: true,
    child: Row(
      children: [
        Opacity(
          opacity: loading ? .36 : 1,
          child: YYArtworkPlaceholder(
            kind: data.artwork,
            dimension: artworkDimension,
            role: YYArtworkRole.lyricsDock,
            radius: artworkRadius,
            semanticLabel: '${data.title} 封面占位',
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loading ? '正在加载播放信息' : data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: YYTypography.text(
                  size: phone ? 10 : 11,
                  weight: 730,
                  height: 1.25,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                loading ? '请稍候' : data.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: YYTypography.text(
                  size: phone ? 8 : 9,
                  weight: 500,
                  height: 1.3,
                  color: const Color(0x94FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LyricsDockCenter extends StatelessWidget {
  const _LyricsDockCenter({
    required this.data,
    required this.atmosphereColor,
    required this.phone,
    required this.lowLandscape,
    required this.loading,
    required this.onPrevious,
    required this.onTogglePlayback,
    required this.onNext,
    required this.onSeekPreview,
    required this.onSeekCommit,
    required this.onSeekCancel,
  });

  final YYNowPlayingViewData data;
  final Color atmosphereColor;
  final bool phone;
  final bool lowLandscape;
  final bool loading;
  final VoidCallback? onPrevious;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onNext;
  final YYLyricsDockValueChanged? onSeekPreview;
  final YYLyricsDockValueChanged? onSeekCommit;
  final VoidCallback? onSeekCancel;

  @override
  Widget build(BuildContext context) {
    final controlSize = phone
        ? YYQueueLyricsMetrics.phoneLyricsDockControl
        : YYQueueLyricsMetrics.lyricsDockControl;
    final primarySize = lowLandscape
        ? 38.0
        : phone
        ? YYQueueLyricsMetrics.phoneLyricsDockPrimaryControl
        : YYQueueLyricsMetrics.lyricsDockPrimaryControl;
    final seekEnabled =
        !loading && (onSeekPreview != null || onSeekCommit != null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LyricsDockButton(
              glyph: YYGlyph.previous,
              label: '上一首',
              visualSize: controlSize,
              loading: loading,
              onPressed: onPrevious,
            ),
            SizedBox(width: phone ? 12 : 15),
            _LyricsDockButton(
              glyph: data.playing ? YYGlyph.pause : YYGlyph.play,
              label: data.playing ? '暂停' : '播放',
              visualSize: primarySize,
              primary: true,
              loading: loading,
              onPressed: onTogglePlayback,
            ),
            SizedBox(width: phone ? 12 : 15),
            _LyricsDockButton(
              glyph: YYGlyph.next,
              label: '下一首',
              visualSize: controlSize,
              loading: loading,
              onPressed: onNext,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                _formatDuration(data.position),
                textAlign: TextAlign.start,
                style: _timeStyle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: YYSlider(
                key: const ValueKey('lyrics-dock-progress'),
                label: '歌词播放进度',
                value: data.progress,
                step: data.duration == Duration.zero
                    ? .01
                    : (1000 / data.duration.inMilliseconds).clamp(.0001, 1),
                appearance: YYSliderAppearance.lyrics,
                lyricsBackgroundColor: atmosphereColor,
                loading: loading,
                semanticFormatter: (value) =>
                    _formatDuration(_scaleDuration(data.duration, value)),
                onChanged: seekEnabled
                    ? (value) => onSeekPreview?.call(value)
                    : null,
                onChangeEnd: seekEnabled
                    ? (value) => onSeekCommit?.call(value)
                    : null,
                onChangeCancel: seekEnabled ? onSeekCancel : null,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 34,
              child: Text(
                _formatDuration(data.duration),
                textAlign: TextAlign.end,
                style: _timeStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LyricsDockActions extends StatelessWidget {
  const _LyricsDockActions({
    required this.favorite,
    required this.hideFavorite,
    required this.loading,
    required this.onToggleFavorite,
    required this.onReturnToPlayer,
  });

  final bool favorite;
  final bool hideFavorite;
  final bool loading;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onReturnToPlayer;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      if (!hideFavorite) ...[
        _LyricsDockButton(
          glyph: YYGlyph.heart,
          label: favorite ? '取消收藏' : '收藏',
          visualSize: 38,
          glass: true,
          toggled: favorite,
          loading: loading,
          onPressed: onToggleFavorite,
        ),
        const SizedBox(width: 7),
      ],
      _LyricsDockButton(
        glyph: YYGlyph.music,
        label: '返回播放界面',
        visualSize: 38,
        glass: true,
        loading: loading,
        onPressed: onReturnToPlayer,
      ),
    ],
  );
}

class _LyricsDockButton extends StatelessWidget {
  const _LyricsDockButton({
    required this.glyph,
    required this.label,
    required this.visualSize,
    required this.loading,
    required this.onPressed,
    this.primary = false,
    this.glass = false,
    this.toggled = false,
  });

  final YYGlyph glyph;
  final String label;
  final double visualSize;
  final bool loading;
  final VoidCallback? onPressed;
  final bool primary;
  final bool glass;
  final bool toggled;

  @override
  Widget build(BuildContext context) => YYControlAction(
    label: label,
    onActivate: onPressed,
    toggled: toggled,
    loading: loading,
    builder: (context, interaction) {
      final theme = YYTheme.of(context);
      final Color fill;
      if (primary) {
        fill = interaction.pressed
            ? const Color(0xD9FFFFFF)
            : const Color(0xFFFFFFFF);
      } else if (glass) {
        fill = interaction.pressed
            ? const Color(0x2EFFFFFF)
            : interaction.hovered || toggled
            ? const Color(0x24FFFFFF)
            : const Color(0x380A0D10);
      } else {
        fill = interaction.pressed
            ? const Color(0x24FFFFFF)
            : interaction.hovered
            ? const Color(0x1AFFFFFF)
            : const Color(0x00000000);
      }
      return SizedBox.square(
        dimension: YYSpace.touchTarget,
        child: Center(
          child: AnimatedScale(
            duration: theme.motion(YYMotion.press),
            scale: interaction.pressed ? .93 : 1,
            child: AnimatedContainer(
              key: ValueKey('lyrics-dock-${glyph.assetName}'),
              duration: theme.motion(YYMotion.press),
              width: visualSize,
              height: visualSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(
                  color: interaction.focused
                      ? const Color(0xFFFFFFFF)
                      : glass
                      ? const Color(0x2EFFFFFF)
                      : const Color(0x00FFFFFF),
                  width: 1,
                ),
                boxShadow: primary
                    ? const [
                        BoxShadow(
                          color: Color(0x2E000000),
                          offset: Offset(0, 8),
                          blurRadius: 22,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: YYIcon(
                  glyph: glyph,
                  size: primary ? 20 : 18,
                  color: primary
                      ? const Color(0xFF111214)
                      : const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _LyricsGlass extends StatelessWidget {
  const _LyricsGlass({
    required this.atmosphereColor,
    required this.padding,
    required this.child,
  });

  final Color atmosphereColor;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final fill = theme.reduceGlass
        ? Color.alphaBlend(const Color(0xD90E1114), atmosphereColor)
        : const Color(0x4D0E1114);
    final panel = DecoratedBox(
      key: const ValueKey('yy-lyrics-dock-surface'),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(YYRadius.lyricsDock),
        border: Border.all(color: const Color(0x29FFFFFF)),
      ),
      child: Padding(padding: padding, child: child),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(YYRadius.lyricsDock),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            offset: Offset(0, 18),
            blurRadius: 54,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(YYRadius.lyricsDock),
        child: theme.reduceGlass
            ? panel
            : BackdropFilter(
                filter: ui.ImageFilter.compose(
                  outer: const ui.ColorFilter.matrix([
                    1.12,
                    -.06,
                    -.06,
                    0,
                    0,
                    -.04,
                    1.08,
                    -.04,
                    0,
                    0,
                    -.04,
                    -.06,
                    1.10,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  inner: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                ),
                child: panel,
              ),
      ),
    );
  }
}

const _timeStyle = TextStyle(
  fontFamily: 'Inter',
  fontFamilyFallback: ['Noto Sans SC', 'Segoe UI Variable', 'Segoe UI'],
  fontSize: 8,
  height: 1.2,
  color: Color(0x8CFFFFFF),
  fontFeatures: [ui.FontFeature.tabularFigures()],
);

Duration _scaleDuration(Duration duration, double value) => Duration(
  milliseconds: (duration.inMilliseconds * value.clamp(0, 1)).round(),
);

String _formatDuration(Duration value) {
  final totalSeconds = value.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
