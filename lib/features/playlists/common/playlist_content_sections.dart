import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_artwork_placeholder.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_surface.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../design_system/yy_track_tile.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/playlist_content.dart';
import '../../../domain/models/track.dart';
import 'playlist_content_controller.dart';

/// Shared controlled sections; the three layouts decide their composition.
final class PlaylistContentSections {
  const PlaylistContentSections({
    required this.controller,
    required this.navigation,
    required this.playback,
    required this.menu,
    required this.canInteract,
    this.queueFeedback,
  });
  final PlaylistContentController controller;
  final AppNavigation navigation;
  final PlaybackPresenter playback;
  final ValueChanged<String> menu;
  final bool Function() canInteract;
  final Widget? queueFeedback;

  Widget get toolbar => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        YYButton(
          label: '返回',
          style: YYButtonStyle.quiet,
          onPressed: navigation.back,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text('歌单内容', style: YYTypography.sectionTitle)),
        YYIconButton(
          label: '刷新歌单',
          glyph: YYGlyph.refresh,
          onPressed: controller.refresh,
        ),
      ],
    ),
  );

  Widget get summary => Builder(
    builder: (context) {
      final data = controller.content;
      final theme = YYTheme.of(context);
      return YYSurface(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.accent.soft,
                borderRadius: BorderRadius.circular(YYRadius.playlistIcon),
              ),
              child: Center(
                child: YYIcon(
                  glyph: YYGlyph.playlist,
                  color: theme.colors.text,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(data?.playlist.name ?? '自定义歌单', style: YYTypography.pageTitle),
            const SizedBox(height: 8),
            if (data != null) ...[
              Text('${data.totalCount} 首 · 保存在本机', style: YYTypography.caption),
              if (data.playlist.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(data.playlist.description, style: YYTypography.caption),
              ],
            ],
            const SizedBox(height: 12),
            Text(
              '移除只改变本歌单，不删除歌曲或来源内容。',
              style: YYTypography.caption.copyWith(
                color: theme.colors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                YYButton(
                  key: const ValueKey('playlist-play-all'),
                  label: '播放全部',
                  glyph: YYGlyph.play,
                  style: YYButtonStyle.primary,
                  onPressed: controller.canPlayAll && data != null
                      ? () {
                          if (canInteract()) {
                            unawaited(controller.playAll(data, shuffle: false));
                          }
                        }
                      : null,
                ),
                YYButton(
                  key: const ValueKey('playlist-play-shuffle'),
                  label: '随机播放',
                  glyph: YYGlyph.shuffle,
                  onPressed: controller.canPlayAll && data != null
                      ? () {
                          if (canInteract()) {
                            unawaited(controller.playAll(data, shuffle: true));
                          }
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '播放整份歌单的可用歌曲，替换当前队列。',
              style: YYTypography.caption.copyWith(
                color: theme.colors.secondary,
              ),
            ),
          ],
        ),
      );
    },
  );

  List<Widget> get content => [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('歌单歌曲', style: YYTypography.sectionTitle),
            const SizedBox(height: 8),
            Text('按歌单顺序 · 长按或右键管理条目', style: YYTypography.caption),
            ?queueFeedback,
            if (controller.content case final data?
                when data.totalCount >
                        PlaylistContentController.maxVisibleCount ||
                    data.page.offset > 0) ...[
              const SizedBox(height: 12),
              _windowNavigation(data, 'top'),
            ],
            if (controller.busy) ...[
              const SizedBox(height: 12),
              const Text('正在处理歌曲操作…'),
            ],
            if (controller.actionError case final message?) ...[
              const SizedBox(height: 12),
              YYErrorBanner(title: '歌曲操作未完成', message: message),
            ],
            if (controller.actionNote case final message?) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(message, style: YYTypography.caption),
              ),
            ],
            if (controller.phase == LoadPhase.error) ...[
              const SizedBox(height: 12),
              YYErrorBanner(
                title: '歌单读取失败',
                message: '内容暂不可操作，请重试。',
                actionLabel: '重试歌单',
                onAction: controller.refresh,
              ),
            ],
            if (controller.loading || controller.phase == LoadPhase.idle) ...[
              const SizedBox(height: 12),
              const YYSkeleton(height: 72, semanticLabel: '歌单加载中'),
            ],
            if (controller.phase == LoadPhase.empty) ...[
              const SizedBox(height: 12),
              YYEmptyState(
                message: controller.missing ? '此歌单已不存在。' : '歌单中还没有歌曲。',
                glyph: YYGlyph.playlist,
              ),
            ],
          ],
        ),
      ),
    ),
    SliverList.builder(
      itemCount: controller.content?.entries.length ?? 0,
      itemBuilder: (_, index) {
        final entry = controller.content!.entries[index];
        final track = entry.track;
        final id = entry.entry.id;
        return GestureDetector(
          key: ValueKey(('playlist-entry', id)),
          behavior: HitTestBehavior.opaque,
          onLongPress: () => menu(id),
          onSecondaryTapUp: (_) => menu(id),
          child: YYTrackTile(
            title: entryTitle(entry),
            subtitle: track?.artists.join(' / ') ?? '保留来源引用，可从歌单移除',
            sourceLabel: availabilityLabel(entry),
            durationLabel: track == null
                ? '—'
                : '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
            artwork: YYArtworkKind.local,
            playing:
                track != null &&
                playback.trackRef == track.ref &&
                playback.data.playing,
            onPressed: controller.canPlayEntry(id)
                ? () => unawaited(controller.playEntry(id))
                : null,
            allowMoreWhenDisabled: true,
            onMore: controller.canOpenEntry(id) ? () => menu(id) : null,
          ),
        );
      },
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            if (controller.content case final data?) ...[
              if (data.totalCount > PlaylistContentController.maxVisibleCount ||
                  data.page.offset > 0)
                _windowNavigation(data, 'bottom')
              else
                Text(
                  '已读取 ${data.entries.length} / ${data.totalCount} 条',
                  style: YYTypography.caption,
                ),
            ],
            if (controller.canLoadMore) ...[
              const SizedBox(height: 12),
              _loadMoreButton(controller.content!),
            ],
            const SizedBox(height: 12),
            Text('可从歌曲菜单添加。播放操作不改变歌单内容。', style: YYTypography.caption),
          ],
        ),
      ),
    ),
  ];

  Widget _loadMoreButton(PlaylistContent snapshot) => YYButton(
    label: '更多歌曲',
    onPressed: () {
      if (canInteract()) controller.loadMore(snapshot);
    },
  );

  Widget _windowNavigation(PlaylistContent snapshot, String location) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        snapshot.entries.isEmpty
            ? '共 ${snapshot.totalCount} 条'
            : '当前第 ${snapshot.page.offset + 1}–${snapshot.page.offset + snapshot.entries.length} 条 / 共 ${snapshot.totalCount} 条',
        style: YYTypography.caption,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          YYButton(
            key: ValueKey(('playlist-window-previous', location)),
            label: '上一组',
            onPressed: controller.canShowPreviousWindow
                ? () {
                    if (canInteract()) controller.showPreviousWindow(snapshot);
                  }
                : null,
          ),
          YYButton(
            key: ValueKey(('playlist-window-next', location)),
            label: '下一组',
            onPressed: controller.canShowNextWindow
                ? () {
                    if (canInteract()) controller.showNextWindow(snapshot);
                  }
                : null,
          ),
        ],
      ),
    ],
  );

  static String entryTitle(PlaylistContentEntry entry) =>
      entry.track?.title ?? '未解析的歌曲';
  static String availabilityLabel(PlaylistContentEntry entry) =>
      switch (entry.track?.availability) {
        null => '未解析',
        TrackAvailability.available =>
          entry.entry.track.sourceType == MusicSourceType.local ? '本地' : '在线引用',
        TrackAvailability.localMissing => '文件失效',
        TrackAvailability.sourceDisabled => '来源停用',
        TrackAvailability.sourceRemoved => '来源已移除',
        TrackAvailability.unsupported => '暂不支持',
      };
}
