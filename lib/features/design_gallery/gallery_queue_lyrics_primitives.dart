import 'package:flutter/widgets.dart';

import '../../design_system/yy_artwork_placeholder.dart';
import '../../design_system/yy_lyrics_line.dart';
import '../../design_system/yy_lyrics_player_dock.dart';
import '../../design_system/yy_player_data.dart';
import '../../design_system/yy_queue_tile.dart';
import '../../design_system/yy_surface.dart';
import '../../design_system/yy_theme.dart';
import '../../design_system/yy_tokens.dart';

/// Deterministic local-only fixtures; no queue, lyric or playback graph access.
class GalleryQueueLyricsPrimitives extends StatefulWidget {
  const GalleryQueueLyricsPrimitives({super.key});

  @override
  State<GalleryQueueLyricsPrimitives> createState() =>
      _GalleryQueueLyricsPrimitivesState();
}

class _GalleryQueueLyricsPrimitivesState
    extends State<GalleryQueueLyricsPrimitives> {
  int _currentQueue = 0;
  int _currentLyric = 1;
  String _status = '尚未操作 Queue / Lyrics Fixture';
  late YYNowPlayingViewData _data = YYNowPlayingViewData(
    title: 'A Quiet Orbit',
    artist: 'Luna Harbor · Fixture',
    position: const Duration(minutes: 1, seconds: 14),
    duration: const Duration(minutes: 3, seconds: 48),
    artwork: YYArtworkKind.orbit,
    playing: true,
    favorite: true,
  );

  void _setStatus(String value) => setState(() => _status = value);

  void _seek(double value, {required bool committed}) {
    setState(() {
      _data = _data.copyWith(
        position: Duration(
          milliseconds: (_data.duration.inMilliseconds * value).round(),
        ),
      );
      _status = committed ? 'Fixture：提交歌词进度（未调用音频Seek）' : 'Fixture：预览歌词进度';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    const queue = [
      ('A Quiet Orbit', 'Luna Harbor · Fixture', '3:48', YYArtworkKind.orbit),
      ('Slow Lines', 'Mira Coast · Fixture', '4:12', YYArtworkKind.tide),
      ('Warm Static', 'Field Notes · Fixture', '2:56', YYArtworkKind.noon),
    ];
    const lyrics = [
      ('The room is listening closely', '整个房间都在认真聆听'),
      ('Every small sound becomes clear', '每个细小的声音都逐渐清晰'),
      ('We follow the rhythm together', '我们一起跟随这段节奏'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('队列与歌词原语 · Fixture', style: YYTypography.sectionTitle),
        const SizedBox(height: 4),
        Text(
          '所有状态只存在于本页；不排序持久化、不Seek、不自动滚动、不调用播放核心。',
          style: YYTypography.caption.copyWith(color: colors.secondary),
        ),
        const SizedBox(height: 16),
        YYSurface(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Queue Tile', style: YYTypography.text(weight: 700)),
              const SizedBox(height: 8),
              for (var index = 0; index < queue.length; index++) ...[
                YYQueueTile(
                  key: ValueKey('queue-fixture-$index'),
                  title: queue[index].$1,
                  meta: queue[index].$2,
                  durationLabel: queue[index].$3,
                  artwork: queue[index].$4,
                  current: _currentQueue == index,
                  density: index == 1
                      ? YYQueueTileDensity.immersive
                      : YYQueueTileDensity.standard,
                  onPressed: () => setState(() {
                    _currentQueue = index;
                    _status = 'Fixture：选择队列项 ${index + 1}（未开始播放）';
                  }),
                  onMoveUp: index == 0
                      ? null
                      : () => _setStatus('Fixture：请求上移（未修改队列）'),
                  onMoveDown: index == queue.length - 1
                      ? null
                      : () => _setStatus('Fixture：请求下移（未修改队列）'),
                  onRemove: () => _setStatus('Fixture：请求移除（未修改队列）'),
                ),
                if (index != queue.length - 1) const SizedBox(height: 4),
              ],
              const SizedBox(height: 6),
              YYQueueTile(
                title: '加载状态 Fixture',
                meta: '未读取QueueController',
                durationLabel: '--:--',
                artwork: YYArtworkKind.local,
                loading: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ColoredBox(
            color: const Color(0xFF3D4A52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Lyrics · 单一纯色 Fixture',
                    style: YYTypography.text(
                      size: 11,
                      weight: 760,
                      spacing: .8,
                      color: const Color(0x94FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (var index = 0; index < lyrics.length; index++) ...[
                    YYLyricsLine(
                      key: ValueKey('lyrics-fixture-$index'),
                      text: lyrics[index].$1,
                      translation: lyrics[index].$2,
                      state: index < _currentLyric
                          ? YYLyricsLineState.past
                          : index == _currentLyric
                          ? YYLyricsLineState.active
                          : YYLyricsLineState.future,
                      onPressed: () => setState(() {
                        _currentLyric = index;
                        _status = 'Fixture：请求跳转歌词 ${index + 1}（未调用Seek）';
                      }),
                    ),
                    if (index != lyrics.length - 1) const SizedBox(height: 22),
                  ],
                  const SizedBox(height: 24),
                  YYLyricsPlayerDock(
                    data: _data,
                    atmosphereColor: const Color(0xFF3D4A52),
                    onPrevious: () => _setStatus('Fixture：请求上一首（未操作队列）'),
                    onTogglePlayback: () => setState(() {
                      _data = _data.copyWith(playing: !_data.playing);
                      _status = 'Fixture：切换播放视觉状态（未调用音频）';
                    }),
                    onNext: () => _setStatus('Fixture：请求下一首（未操作队列）'),
                    onSeekPreview: (value) => _seek(value, committed: false),
                    onSeekCommit: (value) => _seek(value, committed: true),
                    onToggleFavorite: () => setState(() {
                      _data = _data.copyWith(favorite: !_data.favorite);
                      _status = 'Fixture：切换收藏视觉状态（未持久化）';
                    }),
                    onReturnToPlayer: () => _setStatus('Fixture：请求返回播放页（未导航）'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          label: _status,
          child: Text(
            _status,
            key: const ValueKey('queue-lyrics-fixture-status'),
            style: YYTypography.caption.copyWith(color: colors.secondary),
          ),
        ),
      ],
    );
  }
}
