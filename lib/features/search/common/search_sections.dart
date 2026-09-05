import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_artwork_placeholder.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_search_chip.dart';
import '../../../design_system/yy_search_field.dart';
import '../../../design_system/yy_surface.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../design_system/yy_track_tile.dart';
import '../../../domain/models/library_entities.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/track.dart';
import 'search_controller.dart';

final class SearchSections {
  const SearchSections({
    required this.controller,
    required this.playback,
    required this.input,
    required this.focus,
    required this.navigation,
    required this.submit,
  });
  final CatalogSearchController controller;
  final PlaybackPresenter playback;
  final TextEditingController input;
  final FocusNode focus;
  final AppNavigation navigation;
  final VoidCallback submit;

  Widget header({required bool wide}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: Text('搜索', style: YYTypography.pageTitle)),
          YYIconButton(
            key: const ValueKey('open-design-gallery'),
            label: '设计基础预览',
            glyph: YYGlyph.palette,
            onPressed: navigation.openDesignGallery,
          ),
        ],
      ),
      const SizedBox(height: 18),
      if (wide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: 12),
            searchButton,
          ],
        )
      else ...[
        field,
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: searchButton),
      ],
      const SizedBox(height: 18),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in SearchFilter.values)
            YYSearchChip(
              key: ValueKey('search-filter-${filter.name}'),
              label: filter.label,
              selected: controller.filter == filter,
              onPressed: () => controller.selectFilter(filter),
            ),
        ],
      ),
      const SizedBox(height: 14),
      const Text(
        '搜索已保存的目录；实时在线搜索和音乐导入仍在开发。',
        style: TextStyle(fontSize: 11, height: 1.6),
      ),
      const Text(
        'Enter 搜索并播放首个可用曲目；专辑和艺术家详情仍在开发。',
        style: TextStyle(fontSize: 11, height: 1.6),
      ),
      const SizedBox(height: 18),
      _SearchHistory(controller: controller),
      if (controller.actionError case final error?) ...[
        const SizedBox(height: 12),
        YYErrorBanner(title: '操作未完成', message: error),
      ],
      const SizedBox(height: 24),
    ],
  );
  Widget get field => YYSearchField(
    key: const ValueKey('catalog-search-field'),
    controller: input,
    focusNode: focus,
    label: '搜索曲目、专辑、艺术家或来源',
    errorText: controller.inputError,
    // Loading is shown per result bucket, never locks the editable text.
    onSubmitted: (_) => unawaited(controller.submit(playFirst: true)),
  );
  Widget get searchButton => YYButton(
    key: const ValueKey('catalog-search-submit'),
    label: '搜索目录',
    glyph: YYGlyph.search,
    onPressed: controller.canSubmit ? submit : null,
  );

  List<Widget> get results => [
    if (controller.query.isEmpty)
      const SliverToBoxAdapter(child: _SearchWelcome())
    else
      for (final bucket in controller.visibleBuckets) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 10),
            child: Text(bucket.title, style: YYTypography.sectionTitle),
          ),
        ),
        if (bucket.items.isNotEmpty)
          SliverList.builder(
            itemCount: bucket.items.length,
            itemBuilder: (context, index) =>
                _result(bucket.items[index], bucket.sourceType),
          ),
        SliverToBoxAdapter(child: _bucketStatus(bucket)),
      ],
    const SliverToBoxAdapter(child: SizedBox(height: 32)),
  ];

  Widget _bucketStatus(SearchBucket<Object> bucket) {
    if (bucket.loading || bucket.phase == LoadPhase.idle) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: YYSkeleton(height: 60, semanticLabel: '搜索中'),
      );
    }
    if (bucket.phase == LoadPhase.error) {
      return YYErrorBanner(
        title: '此区域暂时不可用',
        message: '查询未完成，其他区域仍可使用。',
        actionLabel: '重试',
        onAction: () => unawaited(controller.loadMore(bucket)),
      );
    }
    if (bucket.items.isEmpty) return const YYEmptyState(message: '没有匹配结果');
    if (bucket.capped) return const YYEmptyState(message: '已读取前 200 条，请缩小查询范围');
    if (bucket.hasMore) {
      return Align(
        alignment: Alignment.center,
        child: YYButton(
          key: ValueKey('search-more-${bucket.id}'),
          label: '加载更多',
          onPressed: () => unawaited(controller.loadMore(bucket)),
        ),
      );
    }
    return const SizedBox(height: 12);
  }

  Widget _result(Object item, MusicSourceType type) => switch (item) {
    Track track => YYTrackTile(
      key: ValueKey(('search-track', track.ref)),
      title: track.title,
      subtitle: track.artists.join(' / '),
      sourceLabel: track.availability == TrackAvailability.available
          ? controller.sourceLabel(track.sourceId, type)
          : '暂不可用',
      durationLabel:
          '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
      artwork: YYArtworkKind.local,
      playing: playback.trackRef == track.ref && playback.data.playing,
      onPressed: controller.canPlay(track)
          ? () => unawaited(controller.play(track))
          : null,
    ),
    Album album => _EntityResult(
      title: album.title,
      subtitle:
          '${album.artists.map((a) => a.name).join(' / ')} · ${album.trackCount} 首',
      source: controller.sourceLabel(album.sourceId, type),
      glyph: YYGlyph.library,
    ),
    Artist artist => _EntityResult(
      title: artist.name,
      subtitle: '${artist.albumCount} 张专辑 · ${artist.trackCount} 首',
      source: controller.sourceLabel(artist.sourceId, type),
      glyph: YYGlyph.music,
    ),
    _ => const SizedBox.shrink(),
  };
}

class _EntityResult extends StatelessWidget {
  const _EntityResult({
    required this.title,
    required this.subtitle,
    required this.source,
    required this.glyph,
  });
  final String title, subtitle, source;
  final YYGlyph glyph;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: YYSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          YYIcon(glyph: glyph, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: YYTypography.text(size: 13, weight: 620),
                ),
                const SizedBox(height: 4),
                Text(
                  '$subtitle · $source',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: YYTypography.text(
                    size: 11,
                    color: YYTheme.of(context).colors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SearchWelcome extends StatelessWidget {
  const _SearchWelcome();
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 320),
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: YYTheme.of(context).colors.border),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const YYIcon(glyph: YYGlyph.search, size: 32),
          const SizedBox(height: 16),
          Text('搜索你的音乐', style: YYTypography.text(size: 17, weight: 620)),
          const SizedBox(height: 10),
          const Text(
            '输入曲目、专辑、艺术家或音乐源名称。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.6),
          ),
        ],
      ),
    ),
  );
}

class _SearchHistory extends StatefulWidget {
  const _SearchHistory({required this.controller});
  final CatalogSearchController controller;
  @override
  State<_SearchHistory> createState() => _SearchHistoryState();
}

class _SearchHistoryState extends State<_SearchHistory> {
  bool _confirm = false;
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text('最近搜索', style: YYTypography.sectionTitle),
            if (!_confirm)
              YYButton(
                label: '清除搜索历史',
                style: YYButtonStyle.quiet,
                onPressed:
                    controller.history.isNotEmpty && !controller.historyBusy
                    ? () => setState(() => _confirm = true)
                    : null,
              )
            else ...[
              const Text('只清除搜索记录，不删除歌曲', style: TextStyle(fontSize: 11)),
              YYButton(
                label: '取消',
                onPressed: () => setState(() => _confirm = false),
              ),
              YYButton(
                label: '确认清除搜索历史',
                onPressed: controller.historyBusy
                    ? null
                    : () async {
                        await controller.clearHistory();
                        if (mounted) setState(() => _confirm = false);
                      },
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (controller.historyError case final error?)
          YYErrorBanner(
            title: '历史记录暂时不可用',
            message: error,
            actionLabel: '重试',
            onAction: () => unawaited(controller.refreshHistory()),
          )
        else if (controller.history.isEmpty)
          Text(
            controller.historyBusy ? '读取搜索历史…' : '暂无搜索记录',
            style: const TextStyle(fontSize: 11),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in controller.history)
              YYSearchChip(
                label: entry.query,
                onPressed: () {
                  controller.updateInput(entry.query);
                  unawaited(controller.submit());
                },
              ),
          ],
        ),
      ],
    );
  }
}
