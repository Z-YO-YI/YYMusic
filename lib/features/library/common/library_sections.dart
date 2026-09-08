import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_album_card.dart';
import '../../../design_system/yy_artwork_placeholder.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_segmented_control.dart';
import '../../../design_system/yy_surface.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../design_system/yy_track_tile.dart';
import '../../../domain/models/catalog_browse.dart';
import '../../../domain/models/collection_models.dart';
import '../../../domain/models/library_entities.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/track.dart';
import '../../playlists/common/playlist_editor_host.dart';
import 'library_controller.dart';

/// Controlled native sections; platform layouts own their composition.
final class LibrarySections {
  const LibrarySections({
    required this.controller,
    required this.playback,
    required this.navigation,
    required this.menu,
  });
  final LibraryController controller;
  final PlaybackPresenter playback;
  final AppNavigation navigation;
  final ValueChanged<Track> menu;

  Widget header({required bool wide}) => Builder(
    builder: (context) {
      final colors = YYTheme.of(context).colors;
      final openPlaylistEditor = PlaylistEditorScope.maybeOf(context)?.open;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 20,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('音乐库', style: YYTypography.pageTitle),
              Wrap(
                spacing: 8,
                children: [
                  YYButton(
                    label: '刷新曲库',
                    glyph: YYGlyph.refresh,
                    onPressed: controller.refresh,
                  ),
                  YYButton(
                    label: '打开设置',
                    style: YYButtonStyle.quiet,
                    onPressed: () => navigation.goTo(AppRoute.settings),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '浏览已保存的目录；导入、实时在线来源和详情编辑仍在开发。',
            style: YYTypography.caption.copyWith(color: colors.tertiary),
          ),
          const SizedBox(height: 20),
          YYSegmentedControl<LibraryCategory>(
            label: '音乐库类型',
            segments: [
              for (final category in LibraryCategory.values)
                YYSegment(value: category, label: category.label),
            ],
            value: controller.category,
            onChanged: controller.selectCategory,
          ),
          const SizedBox(height: 16),
          if (controller.category != LibraryCategory.playlists) ...[
            Wrap(
              spacing: wide ? 16 : 8,
              runSpacing: 8,
              children: [
                YYSegmentedControl<LibrarySource>(
                  label: '来源类型',
                  segments: const [
                    YYSegment(value: LibrarySource.all, label: '全部来源'),
                    YYSegment(value: LibrarySource.local, label: '本地音乐'),
                    YYSegment(value: LibrarySource.online, label: '已保存在线'),
                  ],
                  value: controller.category == LibraryCategory.local
                      ? LibrarySource.local
                      : controller.source,
                  onChanged: controller.category == LibraryCategory.local
                      ? null
                      : controller.setSource,
                ),
                YYSegmentedControl<LibraryAvailability>(
                  label: '曲目可用性',
                  segments: const [
                    YYSegment(value: LibraryAvailability.all, label: '全部状态'),
                    YYSegment(
                      value: LibraryAvailability.available,
                      label: '可用',
                    ),
                    YYSegment(
                      value: LibraryAvailability.unavailable,
                      label: '不可用',
                    ),
                  ],
                  value: controller.availability,
                  onChanged: controller.setAvailability,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                YYSegmentedControl<int>(
                  label: '音乐库排序',
                  segments: [
                    for (var i = 0; i < controller.sortLabels.length; i++)
                      YYSegment(value: i, label: controller.sortLabels[i]),
                  ],
                  value: controller.page.sort,
                  onChanged: controller.setSort,
                ),
                YYButton(
                  label: controller.page.direction == CatalogDirection.ascending
                      ? '升序'
                      : '降序',
                  glyph: controller.page.direction == CatalogDirection.ascending
                      ? YYGlyph.up
                      : YYGlyph.down,
                  onPressed: controller.toggleDirection,
                ),
              ],
            ),
          ] else ...[
            Text(
              '查看自定义歌单、管理名称和歌曲；添加歌曲与系统歌单入口仍在开发。',
              style: YYTypography.caption.copyWith(color: colors.secondary),
            ),
            const SizedBox(height: 12),
            YYButton(
              key: const ValueKey('playlist-create'),
              label: '新建歌单',
              glyph: YYGlyph.plus,
              style: YYButtonStyle.primary,
              onPressed: openPlaylistEditor == null
                  ? null
                  : () => openPlaylistEditor(
                      const PlaylistEditorRequest.create(),
                    ),
            ),
          ],
          if (controller.category == LibraryCategory.local) ...[
            const SizedBox(height: 12),
            Text(
              '这里只展示已入库的本地引用。文件导入、授权和失效恢复尚未接入。',
              style: YYTypography.caption.copyWith(color: colors.secondary),
            ),
          ],
          if (controller.actionError case final error?) ...[
            const SizedBox(height: 12),
            YYErrorBanner(title: '音乐库操作未完成', message: error),
          ],
          if (PlaylistEditorScope.maybeOf(context)?.failure
              case final failure?) ...[
            const SizedBox(height: 12),
            YYErrorBanner(
              title: '关闭面板后的歌单操作未完成',
              message: failure,
              actionLabel: '知道了',
              onAction: PlaylistEditorScope.maybeOf(context)?.dismissFailure,
            ),
          ],
          if (controller.favoriteError case final error?) ...[
            const SizedBox(height: 12),
            YYErrorBanner(
              title: '收藏状态不可用',
              message: error,
              actionLabel: '重试收藏',
              onAction: controller.retryFavorites,
            ),
          ],
          const SizedBox(height: 20),
        ],
      );
    },
  );

  List<Widget> get results {
    final page = controller.page;
    return [
      if (page.items.isNotEmpty &&
          controller.category == LibraryCategory.albums)
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final columns = ((constraints.crossAxisExtent + 16) / 164)
                .floor()
                .clamp(1, 5);
            final width =
                (constraints.crossAxisExtent - (columns - 1) * 16) / columns;
            return SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                mainAxisExtent: width + 110,
              ),
              itemCount: page.items.length,
              itemBuilder: (context, index) {
                final album = page.items[index] as Album;
                return Column(
                  key: ValueKey(album.ref),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    YYAlbumCard(
                      title: album.title,
                      subtitle:
                          '${album.artists.map((a) => a.name).join(' / ')} · ${album.year ?? '年份未知'}',
                      artwork: YYArtworkKind.local,
                      onPressed: () => navigation.openAlbum(album.ref),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${controller.sourceLabel(album.sourceId)} · ${album.trackCount} 首',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.caption.copyWith(
                        color: YYTheme.of(context).colors.secondary,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        )
      else if (page.items.isNotEmpty)
        SliverList.builder(
          itemCount: page.items.length,
          itemBuilder: (context, index) => _item(page.items[index]),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              if (page.loading ||
                  page.phase == LoadPhase.loading ||
                  page.phase == LoadPhase.idle)
                const YYSkeleton(height: 100, semanticLabel: '音乐库加载中')
              else if (page.phase == LoadPhase.error)
                YYErrorBanner(
                  title: '曲库读取失败',
                  message: '请重试。已加载内容仍保留，不显示原始错误。',
                  actionLabel: '重试曲库',
                  onAction: () {
                    if (controller.category == LibraryCategory.playlists) {
                      controller.refresh();
                    } else {
                      unawaited(controller.loadMore());
                    }
                  },
                )
              else if (page.phase == LoadPhase.empty)
                const YYEmptyState(
                  message: '没有符合条件的内容。可调整筛选或刷新；新安装不会自动添加示例歌曲。',
                  glyph: YYGlyph.library,
                ),
              if (page.capped)
                Text(
                  controller.category == LibraryCategory.playlists
                      ? '仅展示前 200 个歌单，完整管理将在歌单页面接入。'
                      : '已展示前 200 项，请调整筛选范围。',
                )
              else if (page.hasMore &&
                  !page.loading &&
                  page.phase != LoadPhase.error)
                YYButton(
                  label: '加载更多',
                  onPressed: () => unawaited(controller.loadMore()),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _item(Object item) => switch (item) {
    Track() => GestureDetector(
      key: ValueKey(item.ref),
      behavior: HitTestBehavior.opaque,
      onLongPress: () => menu(item),
      onSecondaryTapUp: (_) => menu(item),
      child: YYTrackTile(
        title: item.title,
        subtitle: item.artists.join(' / '),
        sourceLabel:
            '${controller.sourceLabel(item.sourceId)} · ${availabilityLabel(item)}',
        durationLabel:
            '${item.duration.inMinutes}:${(item.duration.inSeconds % 60).toString().padLeft(2, '0')}',
        artwork: YYArtworkKind.local,
        playing: playback.trackRef == item.ref && playback.data.playing,
        onPressed: controller.canPlay(item)
            ? () => unawaited(controller.play(item))
            : null,
        onMore: () => menu(item),
        allowMoreWhenDisabled: true,
      ),
    ),
    Artist() => _metadata(
      item.ref,
      item.name,
      '${controller.sourceLabel(item.sourceId)} · ${item.albumCount} 张专辑 · ${item.trackCount} 首歌曲',
      action: YYButton(
        label: '查看艺人',
        glyph: YYGlyph.chevronRight,
        style: YYButtonStyle.quiet,
        onPressed: () => navigation.openArtist(item.ref),
      ),
    ),
    Playlist() => _metadata(
      item.id,
      item.name,
      item.isSystem ? '系统歌单 · 不可删除' : '自定义歌单 · 保存在本机',
      action: item.isSystem
          ? null
          : Builder(
              builder: (context) {
                final open = PlaylistEditorScope.maybeOf(context)?.open;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    YYButton(
                      key: ValueKey(('playlist-open', item.id)),
                      label: '查看歌曲',
                      glyph: YYGlyph.chevronRight,
                      onPressed: () => navigation.openPlaylist(item.id),
                    ),
                    YYButton(
                      key: ValueKey(('playlist-rename', item.id)),
                      label: '重命名',
                      onPressed: open == null
                          ? null
                          : () => open(PlaylistEditorRequest.rename(item)),
                    ),
                    YYButton(
                      key: ValueKey(('playlist-delete', item.id)),
                      label: '删除歌单',
                      style: YYButtonStyle.quiet,
                      onPressed: open == null
                          ? null
                          : () => open(PlaylistEditorRequest.delete(item)),
                    ),
                  ],
                );
              },
            ),
    ),
    _ => const SizedBox.shrink(),
  };
  Widget _metadata(
    Object key,
    String title,
    String subtitle, {
    Widget? action,
  }) => Padding(
    key: ValueKey(key),
    padding: const EdgeInsets.only(bottom: 12),
    child: YYSurface(
      padding: const EdgeInsets.all(18),
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: YYTypography.text(size: 14, weight: 700)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: YYTypography.caption.copyWith(
                color: YYTheme.of(context).colors.secondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    ),
  );
  static String availabilityLabel(Track track) => switch (track.availability) {
    TrackAvailability.available =>
      track.sourceType == MusicSourceType.local ? '本地' : '在线引用',
    TrackAvailability.localMissing => '文件失效',
    TrackAvailability.sourceDisabled => '来源停用',
    _ => '不可用',
  };
}
