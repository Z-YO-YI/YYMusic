import 'package:flutter/widgets.dart';

import '../../design_system/yy_icon.dart';
import '../../design_system/yy_playlist_card.dart';
import '../../design_system/yy_source_card.dart';
import '../../design_system/yy_surface.dart';
import '../../design_system/yy_theme.dart';
import '../../design_system/yy_tokens.dart';

/// Deterministic UI fixtures only; no source or playlist repository is used.
class GalleryCollectionCards extends StatefulWidget {
  const GalleryCollectionCards({super.key});

  @override
  State<GalleryCollectionCards> createState() => _GalleryCollectionCardsState();
}

class _GalleryCollectionCardsState extends State<GalleryCollectionCards> {
  int _selectedSource = 0;
  int _selectedPlaylist = 0;
  String _status = '集合卡片尚未操作';

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return YYSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('来源与歌单卡片 · Fixture', style: YYTypography.sectionTitle),
          const SizedBox(height: 4),
          Text(
            '只验证受控卡片；不会测试连接、读取曲库、创建或保存歌单。',
            style: YYTypography.caption.copyWith(color: colors.secondary),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final columns = constraints.maxWidth > 760 ? 2 : 1;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              final sources = [
                (
                  '本地音乐 Fixture',
                  '未读取设备目录',
                  YYGlyph.folder,
                  '可用',
                  YYSourceStatusTone.positive,
                ),
                (
                  '用户 API Fixture',
                  '未发送连接请求',
                  YYGlyph.cloud,
                  '异常',
                  YYSourceStatusTone.error,
                ),
                (
                  '测试中 Fixture',
                  '未启动计时器',
                  YYGlyph.refresh,
                  '测试中',
                  YYSourceStatusTone.warning,
                ),
                (
                  '停用 Fixture',
                  '受控禁用状态',
                  YYGlyph.cloud,
                  '已停用',
                  YYSourceStatusTone.neutral,
                ),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var index = 0; index < sources.length; index++)
                    SizedBox(
                      width: width,
                      child: YYSourceCard(
                        key: ValueKey('fixture-source-$index'),
                        name: sources[index].$1,
                        meta: sources[index].$2,
                        glyph: sources[index].$3,
                        statusLabel: sources[index].$4,
                        statusTone: sources[index].$5,
                        selected: _selectedSource == index,
                        loading: index == 2,
                        onPressed: index == 3
                            ? null
                            : () => setState(() {
                                _selectedSource = index;
                                _status = '已选择来源组件：${sources[index].$1}（未连接）';
                              }),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1180
                  ? 4
                  : constraints.maxWidth > 760
                  ? 3
                  : 2;
              const gap = 14.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              final playlists = [
                ('喜欢的音乐', '0 首 · Fixture', YYGlyph.heart),
                ('当前队列', '0 首 · Fixture', YYGlyph.queue),
                ('专注工作', '禁用状态示例', YYGlyph.playlist),
                ('稍后播放', '加载状态示例', YYGlyph.history),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var index = 0; index < playlists.length; index++)
                    SizedBox(
                      width: width,
                      child: YYPlaylistCard(
                        key: ValueKey('fixture-playlist-$index'),
                        title: playlists[index].$1,
                        meta: playlists[index].$2,
                        glyph: playlists[index].$3,
                        selected: _selectedPlaylist == index,
                        loading: index == 3,
                        onPressed: index == 2
                            ? null
                            : () => setState(() {
                                _selectedPlaylist = index;
                                _status = '已选择歌单组件：${playlists[index].$1}（未打开）';
                              }),
                      ),
                    ),
                  SizedBox(
                    width: width,
                    child: YYPlaylistCard(
                      key: const ValueKey('fixture-playlist-create'),
                      title: '新建歌单',
                      meta: '仅通知本页 Fixture',
                      glyph: YYGlyph.plus,
                      variant: YYPlaylistCardVariant.create,
                      onPressed: () =>
                          setState(() => _status = 'Fixture：收到新建歌单请求（未保存）'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            label: _status,
            child: Text(
              _status,
              key: const ValueKey('collection-fixture-status'),
              style: YYTypography.caption.copyWith(color: colors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
