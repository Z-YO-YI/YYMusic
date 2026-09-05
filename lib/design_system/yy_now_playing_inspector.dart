part of 'yy_player_surface.dart';

/// Opaque, independently scrollable details from the composed .now-panel.
/// Reads only presentation data; playback and source identities remain outside.
class YYNowPlayingInspector extends StatelessWidget {
  const YYNowPlayingInspector({
    super.key,
    required this.data,
    required this.sourceLabel,
    required this.statusLabel,
    required this.queueCount,
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
  });
  final YYNowPlayingViewData data;
  final String sourceLabel, statusLabel;
  final int queueCount;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onTogglePlayback, onPrevious, onNext;
  final VoidCallback? onToggleShuffle, onCycleRepeat, onSeekCancel;
  final YYPlayerValueChanged? onSeekPreview, onSeekCommit;

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    Widget transport(
      String id,
      YYGlyph glyph,
      String label,
      VoidCallback? action, {
      bool primary = false,
      bool selected = false,
    }) => _TransportButton(
      id: 'inspector-$id',
      glyph: glyph,
      label: label,
      onPressed: action,
      loading: loading,
      primary: primary,
      selected: selected,
      inspector: true,
    );
    final shuffle = transport(
      'shuffle',
      YYGlyph.shuffle,
      '随机播放',
      onToggleShuffle,
      selected: data.shuffle,
    );
    final repeat = transport(
      'repeat',
      YYGlyph.repeat,
      _repeatLabel(data.repeat),
      onCycleRepeat,
      selected: data.repeat != YYRepeatState.off,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '正在播放详情',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SingleChildScrollView(
            key: const PageStorageKey('now-playing-inspector-scroll'),
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 250;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '正在播放',
                                style: YYTypography.text(size: 13, weight: 730),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sourceLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: YYTypography.text(
                                  size: 9,
                                  color: colors.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const YYButton(
                          label: '全屏播放',
                          glyph: YYGlyph.fullscreen,
                          iconOnly: true,
                          style: YYButtonStyle.quiet,
                          onPressed: null,
                        ),
                        const YYButton(
                          label: '播放设置',
                          glyph: YYGlyph.more,
                          iconOnly: true,
                          style: YYButtonStyle.quiet,
                          onPressed: null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    YYArtworkPlaceholder(
                      dimension: constraints.maxWidth,
                      kind: data.artwork,
                      role: YYArtworkRole.player,
                    ),
                    const SizedBox(height: 17),
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.text(
                        size: 16,
                        weight: 750,
                        spacing: -.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.text(
                        size: 11,
                        color: colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusLabel,
                      style: YYTypography.text(size: 9, color: colors.tertiary),
                    ),
                    if (errorMessage case final message?) ...[
                      const SizedBox(height: 12),
                      YYErrorBanner(
                        title: '播放暂不可用',
                        message: message,
                        actionLabel: '重试',
                        onAction: onTogglePlayback,
                      ),
                    ],
                    const SizedBox(height: 18),
                    YYSlider(
                      label: '详情播放进度',
                      value: data.progress,
                      loading: loading,
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
                          style: _timeStyle(context),
                        ),
                        Text(
                          '-${_formatDuration(data.duration > data.position ? data.duration - data.position : Duration.zero)}',
                          style: _timeStyle(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!narrow) shuffle,
                        transport(
                          'previous',
                          YYGlyph.previous,
                          '上一首',
                          onPrevious,
                        ),
                        transport(
                          'playback',
                          data.playing ? YYGlyph.pause : YYGlyph.play,
                          data.playing ? '暂停' : '播放',
                          onTogglePlayback,
                          primary: true,
                        ),
                        transport('next', YYGlyph.next, '下一首', onNext),
                        if (!narrow) repeat,
                      ],
                    ),
                    if (narrow)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [shuffle, repeat],
                      ),
                    const SizedBox(height: 15),
                    const YYButton(
                      label: '全屏歌词',
                      glyph: YYGlyph.lyrics,
                      onPressed: null,
                    ),
                    const SizedBox(height: 8),
                    const YYButton(
                      label: '播放设置',
                      glyph: YYGlyph.device,
                      onPressed: null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '播放队列 · $queueCount 首',
                      style: YYTypography.text(size: 11, weight: 660),
                    ),
                    const SizedBox(height: 8),
                    if (queueCount == 0)
                      const YYEmptyState(message: '队列为空，从音乐库选择曲目后播放。')
                    else
                      Text(
                        '队列详情正在开发，当前播放与底栏保持同步。',
                        style: YYTypography.text(
                          size: 10,
                          height: 1.6,
                          color: colors.tertiary,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
