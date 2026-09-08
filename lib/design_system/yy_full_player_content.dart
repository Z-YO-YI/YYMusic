part of 'yy_player_surface.dart';

/// Controlled playback-page content; native layouts own artwork placement.
class YYFullPlayerContent extends StatelessWidget {
  const YYFullPlayerContent({
    super.key,
    required this.data,
    required this.statusLabel,
    this.titleSize = 30,
    this.compact = false,
    this.loading = false,
    this.errorMessage,
    this.onTogglePlayback,
    this.onPrevious,
    this.onNext,
    this.onToggleShuffle,
    this.onCycleRepeat,
    this.onSeekPreview,
    this.onSeekCommit,
    this.onSeekCancel,
    this.onVolumePreview,
    this.onVolumeCommit,
    this.onVolumeCancel,
  });

  final YYNowPlayingViewData data;
  final String statusLabel;
  final double titleSize;
  final bool compact;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onTogglePlayback, onPrevious, onNext;
  final VoidCallback? onToggleShuffle, onCycleRepeat, onSeekCancel;
  final VoidCallback? onVolumeCancel;
  final YYPlayerValueChanged? onSeekPreview, onSeekCommit;
  final YYPlayerValueChanged? onVolumePreview, onVolumeCommit;

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    Widget control(
      String id,
      YYGlyph glyph,
      String label,
      VoidCallback? action, {
      bool primary = false,
      bool selected = false,
      bool? toggled,
    }) => _TransportButton(
      id: 'page-$id',
      glyph: glyph,
      label: label,
      onPressed: action,
      loading: loading,
      primary: primary,
      selected: selected,
      toggled: toggled,
      fullscreen: true,
    );
    final shuffle = control(
      'shuffle',
      YYGlyph.shuffle,
      data.shuffle ? '关闭随机播放' : '开启随机播放',
      onToggleShuffle,
      toggled: data.shuffle,
    );
    final repeat = control(
      'repeat',
      YYGlyph.repeat,
      _repeatLabel(data.repeat),
      onCycleRepeat,
      selected: data.repeat != YYRepeatState.off,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          data.title,
          maxLines: compact ? 1 : 3,
          overflow: TextOverflow.ellipsis,
          style: YYTypography.text(
            size: titleSize,
            weight: 780,
            spacing: -1.0,
            height: 1.12,
          ),
        ),
        SizedBox(height: compact ? 6 : 9),
        Text(
          data.artist,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: YYTypography.text(
            size: compact ? 12 : 15,
            color: colors.secondary,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 9),
          Text(
            statusLabel,
            style: YYTypography.text(size: 11, color: colors.tertiary),
          ),
        ],
        if (errorMessage case final message?) ...[
          const SizedBox(height: 14),
          YYErrorBanner(
            title: '播放暂不可用',
            message: message,
            actionLabel: '重试',
            onAction: onTogglePlayback,
          ),
        ],
        SizedBox(height: compact ? 8 : 20),
        YYSlider(
          key: const ValueKey('player-page-seek'),
          label: '播放页进度',
          value: data.progress,
          onChanged: onSeekPreview,
          onChangeEnd: onSeekCommit,
          onChangeCancel: onSeekCancel,
          semanticFormatter: (value) =>
              _formatDuration(_scaleDuration(data.duration, value)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(data.position),
              style: YYTypography.text(size: 11, color: colors.tertiary),
            ),
            Text(
              data.duration == Duration.zero
                  ? '时长未知'
                  : _formatDuration(data.duration),
              style: YYTypography.text(size: 11, color: colors.tertiary),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 310;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!narrow) shuffle,
                    control('previous', YYGlyph.previous, '上一首', onPrevious),
                    control(
                      'playback',
                      data.playing ? YYGlyph.pause : YYGlyph.play,
                      data.playing ? '暂停' : '播放',
                      onTogglePlayback,
                      primary: true,
                    ),
                    control('next', YYGlyph.next, '下一首', onNext),
                    if (!narrow) repeat,
                  ],
                ),
                if (narrow)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [shuffle, repeat],
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const YYIcon(glyph: YYGlyph.volume, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: YYSlider(
                key: const ValueKey('player-page-volume'),
                label: '播放页音量',
                value: data.volume,
                onChanged: onVolumePreview,
                onChangeEnd: onVolumeCommit,
                onChangeCancel: onVolumeCancel,
                semanticFormatter: (value) => '${(value * 100).round()}%',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
