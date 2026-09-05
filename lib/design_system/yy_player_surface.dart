import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_artwork_placeholder.dart';
import 'yy_icon.dart';
import 'yy_player_data.dart';
import 'yy_slider.dart';
import 'yy_surface.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';
import 'yy_tooltip.dart';

typedef YYPlayerValueChanged = void Function(double value);

/// Phone player bar. Every action is controlled by the caller.
class YYMiniPlayer extends StatelessWidget {
  const YYMiniPlayer({
    super.key,
    required this.data,
    this.onOpen,
    this.onTogglePlayback,
    this.onNext,
    this.loading = false,
  });

  final YYNowPlayingViewData data;
  final VoidCallback? onOpen;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onNext;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '迷你播放器',
    child: SizedBox(
      height: YYPlayerMetrics.miniHeight,
      child: YYGlassPanel(
        radius: YYPlayerMetrics.miniRadius,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
        blurSigma: 30,
        child: Row(
          children: [
            Expanded(
              child: _TrackAction(
                key: const ValueKey('mini-player-track'),
                data: data,
                artworkDimension: YYPlayerMetrics.miniArtwork,
                artworkRole: YYArtworkRole.miniPlayer,
                compact: true,
                loading: loading,
                onPressed: onOpen,
              ),
            ),
            const SizedBox(width: 2),
            _TransportButton(
              id: 'mini-playback',
              glyph: data.playing ? YYGlyph.pause : YYGlyph.play,
              label: data.playing ? '暂停' : '播放',
              primary: true,
              loading: loading,
              onPressed: onTogglePlayback,
            ),
            _TransportButton(
              id: 'mini-next',
              glyph: YYGlyph.next,
              label: '下一首',
              loading: loading,
              onPressed: onNext,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Windows/tablet player bar. It renders state but never owns playback truth.
class YYDesktopPlayerBar extends StatelessWidget {
  const YYDesktopPlayerBar({
    super.key,
    required this.data,
    this.compact = false,
    this.loading = false,
    this.onOpen,
    this.onTogglePlayback,
    this.onPrevious,
    this.onNext,
    this.onToggleShuffle,
    this.onCycleRepeat,
    this.onToggleFavorite,
    this.onOpenFullscreen,
    this.onOpenLyrics,
    this.onOpenQueue,
    this.onOpenSettings,
    this.onSeekPreview,
    this.onSeekCommit,
    this.onSeekCancel,
    this.onVolumePreview,
    this.onVolumeCommit,
    this.onVolumeCancel,
  });

  final YYNowPlayingViewData data;
  final bool compact;
  final bool loading;
  final VoidCallback? onOpen;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToggleShuffle;
  final VoidCallback? onCycleRepeat;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onOpenFullscreen;
  final VoidCallback? onOpenLyrics;
  final VoidCallback? onOpenQueue;
  final VoidCallback? onOpenSettings;
  final YYPlayerValueChanged? onSeekPreview;
  final YYPlayerValueChanged? onSeekCommit;
  final VoidCallback? onSeekCancel;
  final YYPlayerValueChanged? onVolumePreview;
  final YYPlayerValueChanged? onVolumeCommit;
  final VoidCallback? onVolumeCancel;

  @override
  Widget build(BuildContext context) {
    final height = compact
        ? YYPlayerMetrics.desktopCompactHeight
        : YYPlayerMetrics.desktopHeight;
    return Semantics(
      container: true,
      label: '桌面播放器',
      child: SizedBox(
        height: height,
        child: YYGlassPanel(
          radius: compact
              ? YYPlayerMetrics.desktopCompactRadius
              : YYPlayerMetrics.desktopRadius,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          blurSigma: compact ? 34 : 40,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (width < 680) {
                return Row(
                  children: [
                    Expanded(
                      child: _TrackAction(
                        key: const ValueKey('desktop-player-track'),
                        data: data,
                        artworkDimension: compact
                            ? YYPlayerMetrics.desktopCompactArtwork
                            : YYPlayerMetrics.desktopArtwork,
                        artworkRole: YYArtworkRole.desktopPlayer,
                        compact: compact,
                        loading: loading,
                        onPressed: onOpen,
                      ),
                    ),
                    _TransportButton(
                      id: 'desktop-playback',
                      glyph: data.playing ? YYGlyph.pause : YYGlyph.play,
                      label: data.playing ? '暂停' : '播放',
                      primary: true,
                      loading: loading,
                      onPressed: onTogglePlayback,
                    ),
                    _TransportButton(
                      id: 'desktop-next',
                      glyph: YYGlyph.next,
                      label: '下一首',
                      loading: loading,
                      onPressed: onNext,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: _TrackAction(
                      key: const ValueKey('desktop-player-track'),
                      data: data,
                      artworkDimension: compact
                          ? YYPlayerMetrics.desktopCompactArtwork
                          : YYPlayerMetrics.desktopArtwork,
                      artworkRole: YYArtworkRole.desktopPlayer,
                      compact: compact,
                      loading: loading,
                      onPressed: onOpen,
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 18),
                  Expanded(
                    flex: 12,
                    child: _PlayerCenter(
                      data: data,
                      showProgress: !compact,
                      loading: loading,
                      onTogglePlayback: onTogglePlayback,
                      onPrevious: onPrevious,
                      onNext: onNext,
                      onToggleShuffle: onToggleShuffle,
                      onCycleRepeat: onCycleRepeat,
                      onSeekPreview: onSeekPreview,
                      onSeekCommit: onSeekCommit,
                      onSeekCancel: onSeekCancel,
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 18),
                  Expanded(
                    flex: 9,
                    child: _PlayerTools(
                      data: data,
                      width: width,
                      loading: loading,
                      onToggleFavorite: onToggleFavorite,
                      onOpenFullscreen: onOpenFullscreen,
                      onOpenLyrics: onOpenLyrics,
                      onOpenQueue: onOpenQueue,
                      onOpenSettings: onOpenSettings,
                      onVolumePreview: onVolumePreview,
                      onVolumeCommit: onVolumeCommit,
                      onVolumeCancel: onVolumeCancel,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TrackAction extends StatelessWidget {
  const _TrackAction({
    super.key,
    required this.data,
    required this.artworkDimension,
    required this.artworkRole,
    required this.compact,
    required this.loading,
    required this.onPressed,
  });

  final YYNowPlayingViewData data;
  final double artworkDimension;
  final YYArtworkRole artworkRole;
  final bool compact;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) {
      // Metadata remains readable even when the detail route is unavailable.
      return Semantics(
        label: '正在播放，${data.title}，${data.artist}',
        value: loading ? '加载中' : null,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: YYSpace.touchTarget),
          child: _buildContent(context, (
            hovered: false,
            pressed: false,
            focused: false,
          )),
        ),
      );
    }
    return YYControlAction(
      label: '打开正在播放，${data.title}，${data.artist}',
      onActivate: loading ? null : onPressed,
      loading: loading,
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context, YYControlInteraction interaction) {
    final theme = YYTheme.of(context);
    final colors = theme.colors;
    final fill = interaction.pressed
        ? colors.pressed
        : interaction.hovered
        ? theme.accent.color.withValues(alpha: .055)
        : const Color(0x00000000);
    return AnimatedContainer(
      duration: theme.motion(YYMotion.hover),
      curve: YYMotion.standard,
      height: artworkDimension,
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: interaction.focused ? colors.text : const Color(0x00000000),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          YYArtworkPlaceholder(
            kind: data.artwork,
            dimension: artworkDimension,
            role: artworkRole,
            semanticLabel: '${data.title} 封面',
            hovered: interaction.hovered,
          ),
          SizedBox(width: compact ? 9 : 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: YYTypography.text(
                    size: compact ? 11 : 12,
                    weight: 700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: YYTypography.text(
                    size: compact ? 9 : 10,
                    weight: 520,
                    color: colors.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCenter extends StatelessWidget {
  const _PlayerCenter({
    required this.data,
    required this.showProgress,
    required this.loading,
    required this.onTogglePlayback,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleShuffle,
    required this.onCycleRepeat,
    required this.onSeekPreview,
    required this.onSeekCommit,
    required this.onSeekCancel,
  });

  final YYNowPlayingViewData data;
  final bool showProgress;
  final bool loading;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToggleShuffle;
  final VoidCallback? onCycleRepeat;
  final YYPlayerValueChanged? onSeekPreview;
  final YYPlayerValueChanged? onSeekCommit;
  final VoidCallback? onSeekCancel;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TransportButton(
            id: 'desktop-shuffle',
            glyph: YYGlyph.shuffle,
            label: data.shuffle ? '关闭随机播放' : '开启随机播放',
            toggled: data.shuffle,
            loading: loading,
            onPressed: onToggleShuffle,
          ),
          const SizedBox(width: 5),
          _TransportButton(
            id: 'desktop-previous',
            glyph: YYGlyph.previous,
            label: '上一首',
            loading: loading,
            onPressed: onPrevious,
          ),
          const SizedBox(width: 5),
          _TransportButton(
            id: 'desktop-playback',
            glyph: data.playing ? YYGlyph.pause : YYGlyph.play,
            label: data.playing ? '暂停' : '播放',
            primary: true,
            loading: loading,
            onPressed: onTogglePlayback,
          ),
          const SizedBox(width: 5),
          _TransportButton(
            id: 'desktop-next',
            glyph: YYGlyph.next,
            label: '下一首',
            loading: loading,
            onPressed: onNext,
          ),
          const SizedBox(width: 5),
          _TransportButton(
            id: 'desktop-repeat',
            glyph: YYGlyph.repeat,
            label: _repeatLabel(data.repeat),
            selected: data.repeat != YYRepeatState.off,
            loading: loading,
            onPressed: onCycleRepeat,
          ),
        ],
      ),
      if (showProgress)
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  _formatDuration(data.position),
                  textAlign: TextAlign.right,
                  style: _timeStyle(context),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: YYSlider(
                  label: '播放进度',
                  value: data.progress,
                  onChanged: loading ? null : onSeekPreview,
                  onChangeEnd: loading ? null : onSeekCommit,
                  onChangeCancel: onSeekCancel,
                  semanticFormatter: (value) =>
                      _formatDuration(_scaleDuration(data.duration, value)),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 34,
                child: Text(
                  _formatDuration(data.duration),
                  style: _timeStyle(context),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _PlayerTools extends StatelessWidget {
  const _PlayerTools({
    required this.data,
    required this.width,
    required this.loading,
    required this.onToggleFavorite,
    required this.onOpenFullscreen,
    required this.onOpenLyrics,
    required this.onOpenQueue,
    required this.onOpenSettings,
    required this.onVolumePreview,
    required this.onVolumeCommit,
    required this.onVolumeCancel,
  });

  final YYNowPlayingViewData data;
  final double width;
  final bool loading;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onOpenFullscreen;
  final VoidCallback? onOpenLyrics;
  final VoidCallback? onOpenQueue;
  final VoidCallback? onOpenSettings;
  final YYPlayerValueChanged? onVolumePreview;
  final YYPlayerValueChanged? onVolumeCommit;
  final VoidCallback? onVolumeCancel;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      _TransportButton(
        id: 'desktop-fullscreen',
        glyph: YYGlyph.fullscreen,
        label: '全屏播放',
        loading: loading,
        onPressed: onOpenFullscreen,
      ),
      _TransportButton(
        id: 'desktop-lyrics',
        glyph: YYGlyph.lyrics,
        label: '打开全屏歌词',
        loading: loading,
        onPressed: onOpenLyrics,
      ),
      _TransportButton(
        id: 'desktop-favorite',
        glyph: YYGlyph.heart,
        label: data.favorite ? '取消收藏' : '收藏',
        toggled: data.favorite,
        loading: loading,
        onPressed: onToggleFavorite,
      ),
      _TransportButton(
        id: 'desktop-queue',
        glyph: YYGlyph.queue,
        label: '打开队列',
        loading: loading,
        onPressed: onOpenQueue,
      ),
      if (width >= 1200)
        _TransportButton(
          id: 'desktop-settings',
          glyph: YYGlyph.device,
          label: '播放设置',
          loading: loading,
          onPressed: onOpenSettings,
        ),
      if (width >= 1100)
        SizedBox(
          key: const ValueKey('desktop-volume'),
          width: 128,
          child: Row(
            children: [
              const YYIcon(glyph: YYGlyph.volume, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: YYSlider(
                  label: '音量',
                  value: data.volume,
                  onChanged: loading ? null : onVolumePreview,
                  onChangeEnd: loading ? null : onVolumeCommit,
                  onChangeCancel: onVolumeCancel,
                  semanticFormatter: (value) => '${(value * 100).round()}%',
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.id,
    required this.glyph,
    required this.label,
    required this.onPressed,
    required this.loading,
    this.primary = false,
    this.selected = false,
    this.toggled,
  });

  final String id;
  final YYGlyph glyph;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool primary;
  final bool selected;
  final bool? toggled;

  @override
  Widget build(BuildContext context) => YYTooltip(
    message: label,
    child: YYControlAction(
      label: label,
      onActivate: onPressed,
      loading: loading,
      selected: toggled == null && selected ? true : null,
      toggled: toggled,
      inMutuallyExclusiveGroup: false,
      builder: (context, interaction) {
        final theme = YYTheme.of(context);
        final colors = theme.colors;
        final active = selected || toggled == true;
        final visual = primary
            ? YYPlayerMetrics.primaryControlVisual
            : YYPlayerMetrics.controlVisual;
        final fill = primary
            ? colors.text
            : interaction.pressed
            ? colors.pressed
            : active
            ? Color.alphaBlend(theme.accent.soft, colors.elevated)
            : interaction.hovered
            ? theme.accent.color.withValues(alpha: .08)
            : const Color(0x00000000);
        final ink = primary
            ? colors.elevated
            : active
            ? theme.accent.readableOn(fill)
            : colors.icon;
        return SizedBox.square(
          dimension: YYSpace.touchTarget,
          child: Center(
            child: AnimatedScale(
              duration: theme.motion(YYMotion.press),
              curve: YYMotion.standard,
              scale: interaction.pressed ? .94 : 1,
              child: AnimatedContainer(
                key: ValueKey('player-control-$id'),
                duration: theme.motion(YYMotion.hover),
                curve: YYMotion.standard,
                width: visual,
                height: visual,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(
                    color: interaction.focused
                        ? theme.accent.color
                        : const Color(0x00000000),
                    width: 2,
                  ),
                  boxShadow: primary ? YYShadows.playerControl : null,
                ),
                alignment: Alignment.center,
                child: YYIcon(
                  glyph: glyph,
                  size: primary ? 21 : 18,
                  color: ink,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

String _repeatLabel(YYRepeatState value) => switch (value) {
  YYRepeatState.off => '循环关闭',
  YYRepeatState.all => '列表循环',
  YYRepeatState.one => '单曲循环',
};

String _formatDuration(Duration value) {
  final seconds = value.inSeconds;
  final minutes = seconds ~/ 60;
  return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
}

Duration _scaleDuration(Duration duration, double fraction) =>
    Duration(milliseconds: (duration.inMilliseconds * fraction).round());

TextStyle _timeStyle(BuildContext context) => YYTypography.text(
  size: 8,
  weight: 560,
  color: YYTheme.of(context).colors.tertiary,
);
