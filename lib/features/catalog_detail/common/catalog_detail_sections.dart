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
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../design_system/yy_track_tile.dart';
import '../../../domain/models/catalog_reference.dart';
import '../../../domain/models/library_entities.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/track.dart';
import 'catalog_detail_controller.dart';
import 'catalog_detail_state.dart';

enum CatalogDetailTab { tracks, albums }

/// Shared controlled content; each platform layout chooses its own composition.
final class CatalogDetailSections {
  const CatalogDetailSections({
    required this.controller,
    required this.playback,
    required this.navigation,
    required this.tab,
    required this.onTab,
    required this.menu,
    this.queueFeedback,
  });
  final CatalogDetailController controller;
  final PlaybackPresenter playback;
  final AppNavigation navigation;
  final CatalogDetailTab tab;
  final ValueChanged<CatalogDetailTab> onTab;
  final ValueChanged<Track> menu;
  final Widget? queueFeedback;
  bool get isArtist => controller.target is ArtistDetailTarget;

  Widget get toolbar => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        YYButton(
          label: '返回',
          onPressed: navigation.back,
          style: YYButtonStyle.quiet,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            isArtist ? '艺人详情' : '专辑详情',
            style: YYTypography.sectionTitle,
          ),
        ),
        YYIconButton(
          label: '刷新详情',
          glyph: YYGlyph.refresh,
          onPressed: () => unawaited(controller.refresh()),
        ),
      ],
    ),
  );

  Widget summary({
    required bool horizontal,
    required double artworkSize,
  }) => Builder(
    builder: (context) {
      final colors = YYTheme.of(context).colors;
      final state = controller.summary;
      if (state.phase == LoadPhase.loading || state.phase == LoadPhase.idle) {
        return const YYSkeleton(height: 160, semanticLabel: '详情加载中');
      }
      if (state.phase == LoadPhase.error) {
        return YYErrorBanner(
          title: '详情读取失败',
          message: '请重试，或返回音乐库选择其他内容。',
          actionLabel: '重试详情',
          onAction: () => unawaited(controller.refresh()),
        );
      }
      if (state.phase == LoadPhase.empty) {
        return const YYEmptyState(
          message: '此内容已不在目录中。不会使用同名专辑或艺人替代。',
          glyph: YYGlyph.library,
        );
      }
      final data = state.data!;
      final info = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            key: const ValueKey('detail-title'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: YYTypography.pageTitle,
          ),
          const SizedBox(height: 12),
          Text(
            '来自 ${controller.sourceLabel}',
            style: YYTypography.caption.copyWith(color: colors.secondary),
          ),
          const SizedBox(height: 8),
          Text(switch (data) {
            AlbumDetailSummary(:final album) =>
              '${album.year ?? '年份未知'} · ${album.trackCount} 首歌曲',
            ArtistDetailSummary(:final artist) =>
              '${artist.albumCount} 张专辑 · ${artist.trackCount} 首歌曲',
          }, style: YYTypography.caption.copyWith(color: colors.secondary)),
          if (data case AlbumDetailSummary(:final album)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final credit in album.artists)
                  YYButton(
                    label: credit.name,
                    glyph: YYGlyph.chevronRight,
                    style: YYButtonStyle.quiet,
                    onPressed: () => navigation.openArtist(
                      ArtistRef(sourceId: album.sourceId, artistId: credit.id),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '已保存目录 · 封面暂用占位',
            style: YYTypography.caption.copyWith(color: colors.tertiary),
          ),
        ],
      );
      final art = YYArtworkPlaceholder(
        dimension: artworkSize,
        semanticLabel: '${data.title} 封面占位',
      );
      return horizontal
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                art,
                const SizedBox(width: 24),
                Expanded(child: info),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [art, const SizedBox(height: 20), info],
            );
    },
  );

  Widget get sectionHeader => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ?queueFeedback,
      if (controller.actionError case final error?) ...[
        YYErrorBanner(title: '操作未完成', message: error),
        const SizedBox(height: 16),
      ],
      if (isArtist)
        YYSegmentedControl<CatalogDetailTab>(
          label: '艺人内容',
          segments: const [
            YYSegment(value: CatalogDetailTab.tracks, label: '歌曲'),
            YYSegment(value: CatalogDetailTab.albums, label: '专辑'),
          ],
          value: tab,
          onChanged: onTab,
        )
      else
        Text('专辑歌曲', style: YYTypography.sectionTitle),
      const SizedBox(height: 8),
      Text('按名称排序 · 逐页读取 · 不下载音频', style: YYTypography.caption),
      const SizedBox(height: 16),
    ],
  );

  List<Widget> get content {
    if (controller.summary.phase != LoadPhase.data) return const [];
    return [
      SliverToBoxAdapter(child: sectionHeader),
      if (isArtist && tab == CatalogDetailTab.albums)
        ..._albums
      else
        ..._tracks,
    ];
  }

  List<Widget> get _tracks => [
    SliverList.builder(
      itemCount: controller.tracks.items.length,
      itemBuilder: (context, index) {
        final track = controller.tracks.items[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => menu(track),
          onSecondaryTapUp: (_) => menu(track),
          child: YYTrackTile(
            key: ValueKey(track.ref),
            title: track.title,
            subtitle: track.artists.join(' / '),
            // All rows belong to the source shown in the header. Keep the short
            // badge for availability so missing-file warnings remain visible.
            sourceLabel: _availability(track),
            durationLabel:
                '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
            artwork: YYArtworkKind.local,
            allowMoreWhenDisabled: true,
            onMore: () => menu(track),
            playing: playback.trackRef == track.ref && playback.data.playing,
            onPressed: controller.canPlay(track.ref)
                ? () => unawaited(controller.play(track.ref))
                : null,
          ),
        );
      },
    ),
    _footer(controller.tracks, '歌曲', controller.loadMoreTracks),
  ];

  List<Widget> get _albums => [
    SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.crossAxisExtent + 16) / 164)
            .floor()
            .clamp(1, 4);
        final width =
            (constraints.crossAxisExtent - (columns - 1) * 16) / columns;
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
            mainAxisExtent: width + 76,
          ),
          itemCount: controller.albums.items.length,
          itemBuilder: (context, index) {
            final Album album = controller.albums.items[index];
            return YYAlbumCard(
              key: ValueKey(album.ref),
              title: album.title,
              subtitle: '${album.year ?? '年份未知'} · ${album.trackCount} 首歌曲',
              artwork: YYArtworkKind.local,
              onPressed: () => navigation.openAlbum(album.ref),
            );
          },
        );
      },
    ),
    _footer(controller.albums, '专辑', controller.loadMoreAlbums),
  ];

  Widget _footer<T>(
    CatalogDetailPage<T> page,
    String label,
    Future<void> Function() load,
  ) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          if (page.loading || page.phase == LoadPhase.idle)
            YYSkeleton(height: 80, semanticLabel: '$label加载中')
          else if (page.phase == LoadPhase.error)
            YYErrorBanner(
              title: '$label读取失败',
              message: '已加载的内容保留，可重试当前页。',
              actionLabel: '重试$label',
              onAction: () => unawaited(load()),
            )
          else if (page.phase == LoadPhase.empty)
            YYEmptyState(message: '此目录中暂无$label。', glyph: YYGlyph.music),
          if (page.capped)
            Text('已读取前 200 条$label记录。完整目录管理仍在开发。')
          else if (page.hasMore &&
              !page.loading &&
              page.phase != LoadPhase.error)
            YYButton(label: '更多$label', onPressed: () => unawaited(load())),
        ],
      ),
    ),
  );

  static String _availability(Track track) => switch (track.availability) {
    TrackAvailability.available =>
      track.sourceType == MusicSourceType.local ? '本地' : '在线引用',
    TrackAvailability.localMissing => '文件失效',
    TrackAvailability.sourceDisabled => '来源停用',
    TrackAvailability.sourceRemoved => '来源已移除',
    TrackAvailability.unsupported => '暂不支持',
  };
}
