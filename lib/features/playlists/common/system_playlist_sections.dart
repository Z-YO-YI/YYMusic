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
import '../../../domain/models/collection_models.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/system_playlist_content.dart';
import '../../../domain/models/track.dart';
import 'system_playlist_controller.dart';
import 'system_playlist_presentation.dart';

/// Controlled native sections; each Shell-specific layout chooses composition.
final class SystemPlaylistSections {
  const SystemPlaylistSections({
    required this.controller,
    required this.navigation,
    required this.playback,
    required this.canInteract,
  });
  final SystemPlaylistController controller;
  final AppNavigation navigation;
  final PlaybackPresenter playback;
  final bool Function() canInteract;

  Widget get toolbar => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        YYButton(
          label: '返回',
          style: YYButtonStyle.quiet,
          onPressed: () {
            if (canInteract()) navigation.back();
          },
        ),
        const SizedBox(width: 12),
        Expanded(child: Text('系统歌单', style: YYTypography.sectionTitle)),
        YYIconButton(
          label: '刷新系统歌单',
          glyph: YYGlyph.refresh,
          onPressed: () {
            if (canInteract()) controller.refresh();
          },
        ),
      ],
    ),
  );

  Widget get summary => Builder(
    builder: (context) {
      final theme = YYTheme.of(context), data = controller.content;
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
                  glyph: controller.type.glyph,
                  color: theme.accent.readableOn(theme.colors.elevated),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(controller.type.title, style: YYTypography.pageTitle),
            const SizedBox(height: 8),
            Text(controller.type.description, style: YYTypography.caption),
            if (data != null) ...[
              const SizedBox(height: 8),
              Text(
                '${data.totalCount} 条 · ${controller.isCurrent ? '已读取' : '上次读取'}',
                style: YYTypography.caption,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '系统歌单不能重命名或删除。',
              style: YYTypography.caption.copyWith(
                color: theme.colors.secondary,
              ),
            ),
          ],
        ),
      );
    },
  );

  List<Widget> get content {
    final data = controller.content;
    final historyFailure = playback.historyFailure;
    final canRetryHistory = playback.canRetryHistory;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('歌曲列表', style: YYTypography.sectionTitle),
              const SizedBox(height: 8),
              Text(
                controller.type == SystemPlaylistType.queue
                    ? '点击播放准确的队列条目，重复歌曲仍各自保留。'
                    : '点击播放歌曲，保留当前队列。',
                style: YYTypography.caption,
              ),
              if (data != null &&
                  (data.totalCount > 200 || data.page.offset > 0)) ...[
                const SizedBox(height: 12),
                _navigation(data, 'top'),
              ],
              if (controller.busy) ...[
                const SizedBox(height: 12),
                const Text('正在准备播放…'),
              ],
              if (controller.actionError case final message?) ...[
                const SizedBox(height: 12),
                YYErrorBanner(title: '播放未完成', message: message),
              ],
              if (controller.type == SystemPlaylistType.recent &&
                  historyFailure != null) ...[
                const SizedBox(height: 12),
                YYErrorBanner(
                  title: '播放历史未保存',
                  message: playback.historyBusy
                      ? '正在保存记录，播放不受影响。'
                      : canRetryHistory
                      ? '最近一次记录保存失败，当前播放不受影响。'
                      : '部分记录未保存。可重新播放对应歌曲再记录，当前播放不受影响。',
                  actionLabel: playback.historyBusy
                      ? null
                      : canRetryHistory
                      ? '重试保存'
                      : '知道了',
                  onAction: playback.historyBusy
                      ? null
                      : () {
                          if (!canInteract()) return;
                          if (canRetryHistory) {
                            unawaited(playback.retryHistory(historyFailure));
                          } else {
                            playback.dismissHistoryFailure(historyFailure);
                          }
                        },
                ),
              ],
              if (controller.phase == LoadPhase.error) ...[
                const SizedBox(height: 12),
                YYErrorBanner(
                  title: '系统歌单读取失败',
                  message: '已显示内容暂不可操作，请重试。',
                  actionLabel: '重试系统歌单',
                  onAction: () {
                    if (canInteract()) controller.refresh();
                  },
                ),
              ],
              if (controller.loading || controller.phase == LoadPhase.idle) ...[
                const SizedBox(height: 12),
                const YYSkeleton(height: 72, semanticLabel: '系统歌单加载中'),
              ],
              if (controller.phase == LoadPhase.empty) ...[
                const SizedBox(height: 12),
                YYEmptyState(
                  message: controller.type.emptyMessage,
                  glyph: controller.type.glyph,
                ),
              ],
            ],
          ),
        ),
      ),
      SliverList.builder(
        itemCount: data?.entries.length ?? 0,
        itemBuilder: (_, index) {
          final snapshot = data!,
              entry = snapshot.entries[index],
              track = entry.track;
          final current = controller.type == SystemPlaylistType.queue
              ? playback.entryId == entry.entryId
              : track != null && playback.trackRef == track.ref;
          return YYTrackTile(
            key: ValueKey(('system-entry', entry.identity)),
            title: track?.title ?? '未解析的歌曲',
            subtitle:
                '${current ? '当前项 · ' : ''}${track?.artists.join(' / ') ?? '保留来源引用'}',
            sourceLabel: availabilityLabel(entry),
            durationLabel: track == null
                ? '—'
                : '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
            artwork: YYArtworkKind.local,
            playing: current && playback.data.playing,
            showMore: false,
            onPressed: controller.canPlayEntry(snapshot, entry.identity)
                ? () {
                    if (canInteract()) {
                      unawaited(controller.playEntry(snapshot, entry.identity));
                    }
                  }
                : null,
          );
        },
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              if (data != null) ...[
                _navigation(data, 'bottom'),
                if (controller.canLoadMore) ...[
                  const SizedBox(height: 12),
                  YYButton(
                    label: '更多歌曲',
                    onPressed: () {
                      if (canInteract()) controller.loadMore(data);
                    },
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Text('不可用歌曲保留引用，暂不能播放。', style: YYTypography.caption),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _navigation(SystemPlaylistContent snapshot, String location) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        snapshot.entries.isEmpty
            ? '共 ${snapshot.totalCount} 条'
            : '当前第 ${snapshot.page.offset + 1}–${snapshot.page.offset + snapshot.entries.length} 条 / 共 ${snapshot.totalCount} 条',
        style: YYTypography.caption,
      ),
      if (snapshot.totalCount > 200 || snapshot.page.offset > 0) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            YYButton(
              key: ValueKey(('system-previous', location)),
              label: '上一组',
              onPressed: controller.canShowPreviousWindow
                  ? () {
                      if (canInteract()) {
                        controller.showPreviousWindow(snapshot);
                      }
                    }
                  : null,
            ),
            YYButton(
              key: ValueKey(('system-next', location)),
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
    ],
  );

  static String availabilityLabel(SystemPlaylistEntry entry) =>
      switch (entry.track?.availability) {
        null => '未解析',
        TrackAvailability.available =>
          entry.reference.sourceType == MusicSourceType.local ? '本地' : '在线引用',
        TrackAvailability.localMissing => '文件失效',
        TrackAvailability.sourceDisabled => '来源停用',
        TrackAvailability.sourceRemoved => '来源已移除',
        TrackAvailability.unsupported => '暂不支持',
      };
}
