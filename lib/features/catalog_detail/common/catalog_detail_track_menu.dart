import 'package:flutter/widgets.dart';

import '../../../design_system/yy_context_menu.dart';
import '../../../design_system/yy_icon.dart';
import '../../../domain/models/track.dart';
import 'catalog_detail_controller.dart';

/// Controlled native actions. Placement, dismissal and lifecycle belong to the route.
class CatalogDetailTrackMenu extends StatelessWidget {
  const CatalogDetailTrackMenu({
    super.key,
    required this.controller,
    required this.track,
    required this.onDismiss,
    required this.onSelected,
    this.canInsert = false,
  });
  final CatalogDetailController controller;
  final Track track;
  final bool canInsert;
  final VoidCallback onDismiss;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => YYContextMenu(
    title: track.title,
    meta: controller.favoriteError ?? controller.sourceLabel,
    items: [
      YYContextMenuItem(
        id: 'play',
        label: '播放歌曲',
        glyph: YYGlyph.play,
        enabled: controller.canPlay(track.ref),
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
        label: controller.favoritesReady
            ? controller.isFavorite(track.ref)
                  ? '取消收藏'
                  : '收藏歌曲'
            : controller.favoriteError == null
            ? '收藏状态读取中'
            : '收藏暂不可用',
        glyph: YYGlyph.heart,
        enabled: controller.canFavorite(track.ref),
        loading: !controller.favoritesReady && controller.favoriteError == null,
      ),
      if (controller.favoriteError != null)
        const YYContextMenuItem(
          id: 'retry-favorites',
          label: '重试收藏状态',
          glyph: YYGlyph.refresh,
        ),
      YYContextMenuItem(
        id: 'playlist',
        label: '添加到歌单',
        glyph: YYGlyph.playlist,
        enabled: controller.canOpenActions(track.ref),
      ),
      const YYContextMenuItem(id: 'close', label: '关闭菜单', glyph: YYGlyph.close),
    ],
    onDismiss: onDismiss,
    onSelected: onSelected,
  );
}
