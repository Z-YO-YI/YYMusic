import 'package:flutter/widgets.dart';

import '../../design_system/yy_album_card.dart';
import '../../design_system/yy_artwork_placeholder.dart';
import '../../design_system/yy_surface.dart';
import '../../design_system/yy_theme.dart';
import '../../design_system/yy_tokens.dart';
import '../../design_system/yy_track_tile.dart';

/// Deterministic component fixtures only; no catalog or playback is created.
class GalleryContentCards extends StatefulWidget {
  const GalleryContentCards({super.key});

  @override
  State<GalleryContentCards> createState() => _GalleryContentCardsState();
}

class _GalleryContentCardsState extends State<GalleryContentCards> {
  int _selectedAlbum = 0;
  int _selectedTrack = 0;
  String _status = '尚未操作';

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return YYSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('内容组件 · Fixture', style: YYTypography.sectionTitle),
          const SizedBox(height: 4),
          Text(
            '来自最终合成HTML的卡片与曲目行。选择只更新本页文字，不访问曲库或播放。',
            style: YYTypography.caption.copyWith(color: colors.secondary),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 3 : 2;
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - (columns - 1) * gap) / columns;
              final albums = [
                ('A Quiet Orbit', 'Luna Harbor · EP', YYArtworkKind.orbit),
                ('Blue Hour', 'Mira Coast · 专辑', YYArtworkKind.tide),
                ('Noon Geometry', '加载状态示例', YYArtworkKind.noon),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: 18,
                children: [
                  for (var index = 0; index < albums.length; index++)
                    SizedBox(
                      width: width,
                      child: YYAlbumCard(
                        key: ValueKey('fixture-album-$index'),
                        title: albums[index].$1,
                        subtitle: albums[index].$2,
                        artwork: albums[index].$3,
                        selected: _selectedAlbum == index,
                        loading: index == 2,
                        onPressed: index == 1
                            ? null
                            : () => setState(() {
                                _selectedAlbum = index;
                                _status = '已选择专辑组件：${albums[index].$1}';
                              }),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          for (final (index, title, meta, source, duration, artwork) in [
            (
              0,
              'A Quiet Orbit',
              'Luna Harbor · The Small Hours',
              'Cloud API',
              '3:48',
              YYArtworkKind.orbit,
            ),
            (
              1,
              'Slow Lines',
              'Mira Coast · Blue Hour',
              '本地',
              '4:12',
              YYArtworkKind.tide,
            ),
            (2, 'Warm Static', '禁用状态示例', 'REST', '2:56', YYArtworkKind.noon),
            (
              3,
              'Current No. 4',
              '加载状态示例',
              'Cloud API',
              '5:03',
              YYArtworkKind.mono,
            ),
          ])
            YYTrackTile(
              key: ValueKey('fixture-track-$index'),
              title: title,
              subtitle: meta,
              sourceLabel: source,
              durationLabel: duration,
              artwork: artwork,
              playing: _selectedTrack == index,
              loading: index == 3,
              onPressed: index == 2
                  ? null
                  : () => setState(() {
                      _selectedTrack = index;
                      _status = '已选择曲目组件：$title（未播放）';
                    }),
              onMore: index == 2
                  ? null
                  : () => setState(() => _status = '$title：更多操作尚未接入弹层'),
            ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            label: _status,
            child: Text(
              _status,
              key: const ValueKey('content-fixture-status'),
              style: YYTypography.caption.copyWith(color: colors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
