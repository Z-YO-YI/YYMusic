import 'package:flutter/widgets.dart';

import '../../../app/layout_class.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_context_menu.dart';
import '../../../design_system/yy_dialog.dart';
import '../../../design_system/yy_icon.dart';
import '../../../domain/models/system_playlist_content.dart';
import 'system_playlist_controller.dart';

/// Controlled native menu/confirmation; never accesses storage from a Widget.
class SystemPlaylistManagementPanel extends StatelessWidget {
  const SystemPlaylistManagementPanel({
    super.key,
    required this.controller,
    required this.snapshot,
    required this.favoriteIdentity,
    required this.platform,
    required this.onDismiss,
    required this.onSelected,
  });
  final SystemPlaylistController controller;
  final SystemPlaylistContent snapshot;
  final Object? favoriteIdentity;
  final YYPlatform platform;
  final VoidCallback onDismiss;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final identity = favoriteIdentity;
    if (identity != null) {
      final entry = snapshot.entries.firstWhere((e) => e.identity == identity);
      return YYContextMenu(
        title: entry.track?.title ?? '未解析的歌曲',
        meta: '已喜欢 · 取消不删除歌曲',
        items: [
          YYContextMenuItem(
            id: 'play',
            label: '播放歌曲',
            glyph: YYGlyph.play,
            enabled: controller.canPlayEntry(snapshot, identity),
          ),
          YYContextMenuItem(
            id: 'remove-favorite',
            label: '取消喜欢',
            glyph: YYGlyph.heart,
            selected: true,
            enabled: controller.canRemoveFavorite(snapshot, identity),
          ),
          const YYContextMenuItem(
            id: 'close',
            label: '关闭菜单',
            glyph: YYGlyph.close,
          ),
        ],
        onSelected: onSelected,
        onDismiss: onDismiss,
      );
    }
    final body = Text(
      '将清除 ${snapshot.totalCount} 条最近播放记录。\n只清除历史，不删除歌曲、收藏或队列；当前播放不受影响。',
    );
    final actions = [
      YYButton(label: '取消', onPressed: onDismiss),
      YYButton(
        label: '确认清除',
        glyph: YYGlyph.trash,
        onPressed: controller.canClearHistory(snapshot)
            ? () => onSelected('clear-history')
            : null,
      ),
    ];
    return platform == YYPlatform.android &&
            MediaQuery.sizeOf(context).width < 600
        ? YYBottomSheet(
            title: '清除播放历史',
            body: body,
            actions: actions,
            onClose: onDismiss,
          )
        : YYDialog(
            title: '清除播放历史',
            body: body,
            actions: actions,
            onClose: onDismiss,
          );
  }
}
