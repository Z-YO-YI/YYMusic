import 'package:flutter/widgets.dart';

import '../../../design_system/yy_context_menu.dart';
import '../../../design_system/yy_icon.dart';
import '../../../domain/models/playlist_content.dart';
import 'playlist_content_controller.dart';
import 'playlist_content_sections.dart';

class PlaylistEntryMenu extends StatelessWidget {
  const PlaylistEntryMenu({
    super.key,
    required this.controller,
    required this.entry,
    required this.onDismiss,
    required this.onSelected,
    this.canInsert = false,
  });
  final PlaylistContentController controller;
  final PlaylistContentEntry entry;
  final bool canInsert;
  final VoidCallback onDismiss;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) {
    final id = entry.entry.id;
    return YYContextMenu(
      title: PlaylistContentSections.entryTitle(entry),
      meta: '第 ${entry.entry.position + 1} 条 · 队列与歌单独立',
      items: [
        YYContextMenuItem(
          id: 'play',
          label: '播放歌曲',
          glyph: YYGlyph.play,
          enabled: controller.canPlayEntry(id),
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
          id: 'up',
          label: '上移一位',
          glyph: YYGlyph.up,
          enabled: controller.canMoveEntry(id, up: true),
        ),
        YYContextMenuItem(
          id: 'down',
          label: '下移一位',
          glyph: YYGlyph.down,
          enabled: controller.canMoveEntry(id, up: false),
        ),
        YYContextMenuItem(
          id: 'remove',
          label: '从歌单移除',
          glyph: YYGlyph.trash,
          enabled: controller.canManageEntry(id),
          danger: true,
          dividerBefore: true,
        ),
        const YYContextMenuItem(
          id: 'close',
          label: '关闭菜单',
          glyph: YYGlyph.close,
        ),
      ],
      onDismiss: onDismiss,
      onSelected: onSelected,
    );
  }
}
