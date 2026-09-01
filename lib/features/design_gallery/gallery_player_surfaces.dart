import 'package:flutter/widgets.dart';

import '../../app/layout_class.dart';
import '../../design_system/yy_artwork_placeholder.dart';
import '../../design_system/yy_player_data.dart';
import '../../design_system/yy_player_surface.dart';
import '../../design_system/yy_theme.dart';
import '../../design_system/yy_tokens.dart';

/// Local-only player fixtures. They never call the playback graph.
class GalleryPlayerSurfaces extends StatefulWidget {
  const GalleryPlayerSurfaces({super.key, required this.platform});

  final YYPlatform platform;

  @override
  State<GalleryPlayerSurfaces> createState() => _GalleryPlayerSurfacesState();
}

class _GalleryPlayerSurfacesState extends State<GalleryPlayerSurfaces> {
  late YYNowPlayingViewData _data = YYNowPlayingViewData(
    title: 'A Quiet Orbit',
    artist: 'Luna Harbor · Fixture',
    position: const Duration(minutes: 1, seconds: 14),
    duration: const Duration(minutes: 3, seconds: 48),
    artwork: YYArtworkKind.orbit,
    playing: true,
    favorite: true,
    shuffle: false,
    repeat: YYRepeatState.all,
  );
  String _status = '尚未操作 Player Fixture';

  void _update(YYNowPlayingViewData value, String status) {
    setState(() {
      _data = value;
      _status = status;
    });
  }

  YYRepeatState _nextRepeat() => switch (_data.repeat) {
    YYRepeatState.off => YYRepeatState.all,
    YYRepeatState.all => YYRepeatState.one,
    YYRepeatState.one => YYRepeatState.off,
  };

  void _seek(double value, {required bool committed}) => _update(
    _data.copyWith(
      position: Duration(
        milliseconds: (_data.duration.inMilliseconds * value).round(),
      ),
    ),
    committed
        ? 'Fixture：提交进度 ${(value * 100).round()}%（未调用播放器）'
        : 'Fixture：预览进度 ${(value * 100).round()}%',
  );

  void _volume(double value, {required bool committed}) => _update(
    _data.copyWith(volume: value),
    committed
        ? 'Fixture：提交音量 ${(value * 100).round()}%（未调用系统）'
        : 'Fixture：预览音量 ${(value * 100).round()}%',
  );

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    final callbacks = _PlayerCallbacks(
      open: () => setState(() => _status = 'Fixture：打开正在播放（未导航）'),
      togglePlayback: () => _update(
        _data.copyWith(playing: !_data.playing),
        'Fixture：切换播放视觉状态（未调用音频）',
      ),
      previous: () => setState(() => _status = 'Fixture：请求上一首（未操作队列）'),
      next: () => setState(() => _status = 'Fixture：请求下一首（未操作队列）'),
      shuffle: () => _update(
        _data.copyWith(shuffle: !_data.shuffle),
        'Fixture：切换随机视觉状态（未操作队列）',
      ),
      repeat: () => _update(
        _data.copyWith(repeat: _nextRepeat()),
        'Fixture：切换循环视觉状态（未操作队列）',
      ),
      favorite: () => _update(
        _data.copyWith(favorite: !_data.favorite),
        'Fixture：切换收藏视觉状态（未持久化）',
      ),
      fullscreen: () => setState(() => _status = 'Fixture：请求全屏播放（未调用系统）'),
      lyrics: () => setState(() => _status = 'Fixture：请求歌词（未导航）'),
      queue: () => setState(() => _status = 'Fixture：请求队列（未导航）'),
      settings: () => setState(() => _status = 'Fixture：请求播放设置（未导航）'),
      seekPreview: (value) => _seek(value, committed: false),
      seekCommit: (value) => _seek(value, committed: true),
      volumePreview: (value) => _volume(value, committed: false),
      volumeCommit: (value) => _volume(value, committed: true),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('播放器表面 · Fixture', style: YYTypography.sectionTitle),
        const SizedBox(height: 4),
        Text(
          '数据与操作仅存在于本页，不接入音频、队列、媒体会话或持久化。',
          style: YYTypography.caption.copyWith(color: colors.secondary),
        ),
        const SizedBox(height: 16),
        if (widget.platform == YYPlatform.windows) ...[
          _desktopPlayer(callbacks),
          const SizedBox(height: 12),
          Text('76dp Compact / Loading', style: YYTypography.caption),
          const SizedBox(height: 6),
          YYDesktopPlayerBar(data: _data, compact: true, loading: true),
        ] else ...[
          _miniPlayer(callbacks),
          const SizedBox(height: 12),
          Text('64dp Loading', style: YYTypography.caption),
          const SizedBox(height: 6),
          YYMiniPlayer(data: _data, loading: true),
        ],
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          label: _status,
          child: Text(
            _status,
            key: const ValueKey('player-fixture-status'),
            style: YYTypography.caption.copyWith(color: colors.secondary),
          ),
        ),
      ],
    );
  }

  Widget _miniPlayer(_PlayerCallbacks callbacks) => YYMiniPlayer(
    data: _data,
    onOpen: callbacks.open,
    onTogglePlayback: callbacks.togglePlayback,
    onNext: callbacks.next,
  );

  Widget _desktopPlayer(_PlayerCallbacks callbacks) => YYDesktopPlayerBar(
    data: _data,
    onOpen: callbacks.open,
    onTogglePlayback: callbacks.togglePlayback,
    onPrevious: callbacks.previous,
    onNext: callbacks.next,
    onToggleShuffle: callbacks.shuffle,
    onCycleRepeat: callbacks.repeat,
    onToggleFavorite: callbacks.favorite,
    onOpenFullscreen: callbacks.fullscreen,
    onOpenLyrics: callbacks.lyrics,
    onOpenQueue: callbacks.queue,
    onOpenSettings: callbacks.settings,
    onSeekPreview: callbacks.seekPreview,
    onSeekCommit: callbacks.seekCommit,
    onVolumePreview: callbacks.volumePreview,
    onVolumeCommit: callbacks.volumeCommit,
  );
}

class _PlayerCallbacks {
  const _PlayerCallbacks({
    required this.open,
    required this.togglePlayback,
    required this.previous,
    required this.next,
    required this.shuffle,
    required this.repeat,
    required this.favorite,
    required this.fullscreen,
    required this.lyrics,
    required this.queue,
    required this.settings,
    required this.seekPreview,
    required this.seekCommit,
    required this.volumePreview,
    required this.volumeCommit,
  });

  final VoidCallback open;
  final VoidCallback togglePlayback;
  final VoidCallback previous;
  final VoidCallback next;
  final VoidCallback shuffle;
  final VoidCallback repeat;
  final VoidCallback favorite;
  final VoidCallback fullscreen;
  final VoidCallback lyrics;
  final VoidCallback queue;
  final VoidCallback settings;
  final YYPlayerValueChanged seekPreview;
  final YYPlayerValueChanged seekCommit;
  final YYPlayerValueChanged volumePreview;
  final YYPlayerValueChanged volumeCommit;
}
