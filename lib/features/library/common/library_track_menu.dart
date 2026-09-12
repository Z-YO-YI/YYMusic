import 'package:flutter/widgets.dart';

import '../../../design_system/yy_context_menu.dart';
import '../../../design_system/yy_icon.dart';
import '../../../domain/models/track.dart';
import 'library_controller.dart';
import 'library_sections.dart';

class LibraryTrackMenu extends StatelessWidget {
  const LibraryTrackMenu({
    super.key,
    required this.track,
    required this.controller,
    required this.canInsert,
    required this.onSelected,
    required this.onDismiss,
  });
  final Track track;
  final LibraryController controller;
  final bool canInsert;
  final ValueChanged<String> onSelected;
  final VoidCallback onDismiss;
  @override
  Widget build(BuildContext context) => YYContextMenu(
    title: track.title,
    meta:
        '${controller.sourceLabel(track.sourceId)} · ${LibrarySections.availabilityLabel(track)}',
    items: [
      YYContextMenuItem(
        id: 'play',
        label: '播放歌曲',
        glyph: YYGlyph.play,
        enabled: controller.canPlay(track),
      ),
      YYContextMenuItem(
        id: 'next',
        label: '下一首播放',
        glyph: YYGlyph.next,
        enabled: canInsert,
      ),
      YYContextMenuItem(
        id: 'queue',
        label: '添加到队列',
        glyph: YYGlyph.listPlus,
        enabled: canInsert,
      ),
      YYContextMenuItem(
        id: 'favorite',
        label: controller.isFavorite(track) ? '取消收藏' : '收藏歌曲',
        glyph: YYGlyph.heart,
        enabled: controller.canFavorite(track),
      ),
      YYContextMenuItem(
        id: 'playlist',
        label: '添加到歌单',
        glyph: YYGlyph.playlist,
        enabled: controller.canAddToPlaylist(track),
      ),
    ],
    onSelected: onSelected,
    onDismiss: onDismiss,
  );
}
