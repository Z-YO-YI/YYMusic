import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_album_card.dart';
import '../../../design_system/yy_artwork_placeholder.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_source_card.dart';
import '../../../design_system/yy_surface.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../design_system/yy_track_tile.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/music_source.dart';
import '../../../domain/models/track.dart';
import 'home_controller.dart';

/// Shared data and controlled sections; each platform composes its own page.
final class HomeSections {
  const HomeSections({
    required this.controller,
    required this.playback,
    required this.navigation,
    required this.width,
  });
  final HomeController controller;
  final PlaybackPresenter playback;
  final AppNavigation navigation;
  final double width;
  TextStyle get titleStyle => YYTypography.pageTitle;
  YYGlyph get refreshGlyph => YYGlyph.refresh;
  YYGlyph get galleryGlyph => YYGlyph.palette;
  TextStyle captionStyle(BuildContext context) =>
      YYTypography.caption.copyWith(color: YYTheme.of(context).colors.tertiary);

  Widget hero({required bool wide}) => _HomeHero(sections: this, wide: wide);

  Widget continuing({required int columns}) => _Section(
    title: '继续聆听',
    subtitle: '从最近播放的曲目继续',
    action: YYButton(
      label: '查看全部',
      style: YYButtonStyle.quiet,
      onPressed: () => navigation.goTo(AppRoute.library),
    ),
    child: _state(
      controller.history,
      empty: '还没有播放历史',
      retry: controller.retryHistory,
      builder: (tracks) => LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 12,
          runSpacing: 20,
          children: [
            for (final track in tracks.take(6))
              SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 12) / columns,
                child: YYAlbumCard(
                  title: track.title,
                  subtitle: _artist(track),
                  artwork: YYArtworkKind.local,
                  onPressed: controller.canPlay(track)
                      ? () => unawaited(controller.play(track))
                      : null,
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget get recent => YYSurface(
    padding: const EdgeInsets.all(16),
    child: _Section(
      title: '最近添加',
      subtitle: '最近 7 天加入曲库 · 最多 20 首',
      child: _state(
        controller.recent,
        empty: '最近 7 天没有新入库的曲目',
        retry: () => unawaited(controller.refreshCatalog()),
        builder: _tracks,
      ),
    ),
  );

  Widget get sources => YYSurface(
    padding: const EdgeInsets.all(16),
    child: _Section(
      title: '你的音乐源',
      subtitle: '显示已保存的来源状态',
      action: YYIconButton(
        label: '打开设置（来源配置开发中）',
        glyph: YYGlyph.settings,
        onPressed: () => navigation.goTo(AppRoute.settings),
      ),
      child: _state(
        controller.sources,
        empty: '尚未配置音乐源',
        retry: controller.retrySources,
        builder: (sources) => Column(
          children: [
            for (final source in sources)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: YYSourceCard(
                  name: source.name,
                  meta: source.type == MusicSourceType.local
                      ? '本地音乐'
                      : '第三方在线来源',
                  glyph: source.type == MusicSourceType.local
                      ? YYGlyph.folder
                      : YYGlyph.cloud,
                  statusLabel: source.enabled
                      ? _sourceLabel(source.status)
                      : '已停用',
                  statusTone: !source.enabled
                      ? YYSourceStatusTone.neutral
                      : switch (source.status) {
                          MusicSourceStatus.connected =>
                            YYSourceStatusTone.positive,
                          MusicSourceStatus.error ||
                          MusicSourceStatus.unauthorized ||
                          MusicSourceStatus.schemaMismatch =>
                            YYSourceStatusTone.error,
                          MusicSourceStatus.testing ||
                          MusicSourceStatus.rateLimited ||
                          MusicSourceStatus.offline =>
                            YYSourceStatusTone.warning,
                          _ => YYSourceStatusTone.neutral,
                        },
                  onPressed: () => navigation.goTo(AppRoute.settings),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget get history => _Section(
    title: '最近播放',
    subtitle: '最近 20 首，快速返回熟悉的旋律',
    action: _ClearHistory(controller: controller),
    child: _state(
      controller.history,
      empty: '播放歌曲后会出现在这里',
      retry: controller.retryHistory,
      builder: _tracks,
    ),
  );

  Widget get error => (controller.actionError ?? playback.errorMessage) == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: YYErrorBanner(
            title: '操作未完成',
            message: controller.actionError ?? playback.errorMessage!,
          ),
        );

  Widget _tracks(List<Track> tracks) => Column(
    children: [
      for (final track in tracks)
        YYTrackTile(
          playing: playback.trackRef == track.ref && playback.data.playing,
          title: track.title,
          subtitle: _artist(track),
          sourceLabel: track.availability == TrackAvailability.available
              ? track.sourceType == MusicSourceType.local
                    ? '本地'
                    : '在线来源'
              : _availability(track.availability),
          durationLabel:
              '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
          artwork: YYArtworkKind.local,
          onPressed: controller.canPlay(track)
              ? () => unawaited(controller.play(track))
              : null,
        ),
    ],
  );
}

class _ClearHistory extends StatefulWidget {
  const _ClearHistory({required this.controller});
  final HomeController controller;
  @override
  State<_ClearHistory> createState() => _ClearHistoryState();
}

class _ClearHistoryState extends State<_ClearHistory> {
  bool _confirming = false;
  @override
  Widget build(BuildContext context) => !_confirming
      ? YYButton(
          label: '清除历史',
          style: YYButtonStyle.quiet,
          onPressed: widget.controller.canClearHistory
              ? () => setState(() => _confirming = true)
              : null,
        )
      : SizedBox(
          width: 180,
          child: Column(
            children: [
              const Text('只清除历史，不删除歌曲', style: TextStyle(fontSize: 10)),
              Wrap(
                spacing: 4,
                children: [
                  YYButton(
                    label: '取消',
                    style: YYButtonStyle.quiet,
                    onPressed: () => setState(() => _confirming = false),
                  ),
                  YYButton(
                    label: '确认清除',
                    onPressed: widget.controller.canClearHistory
                        ? () async {
                            await widget.controller.clearHistory();
                            if (mounted) setState(() => _confirming = false);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.sections, required this.wide});
  final HomeSections sections;
  final bool wide;
  @override
  Widget build(BuildContext context) {
    final home = sections.controller;
    final colors = YYTheme.of(context).colors;
    final featured = home.featured.firstOrNull;
    final loading =
        featured == null &&
        (home.history.phase == LoadPhase.loading ||
            home.localSelection.phase == LoadPhase.loading);
    if (loading) {
      return const YYSkeleton(
        height: 240,
        radius: YYRadius.hero,
        semanticLabel: '正在准备今日精选',
      );
    }
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YYMUSIC MIX · 今日精选',
          style: YYTypography.text(
            size: 10.5,
            weight: 760,
            spacing: .55,
            color: YYTheme.of(context).accent.readableOn(colors.elevated),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          featured?.title ?? '所有音乐，回到一个安静的位置。',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: YYTypography.text(
            size: wide ? 36 : 28,
            weight: 800,
            spacing: -2.1,
            height: 1.16,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          featured == null
              ? '从你的曲库和最近播放中，找到下一首想听的音乐。'
              : '${_artist(featured)} · 来自你的曲库',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: YYTypography.text(
            size: 13,
            height: 1.7,
            color: colors.secondary,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            YYButton(
              key: const ValueKey('home-play-featured'),
              label: '播放今日精选',
              glyph: YYGlyph.play,
              style: YYButtonStyle.primary,
              onPressed: featured != null && home.canPlay(featured)
                  ? () => unawaited(home.play(featured))
                  : null,
            ),
            YYButton(
              key: const ValueKey('home-open-library'),
              label: '打开音乐库',
              glyph: YYGlyph.library,
              onPressed: () => sections.navigation.goTo(AppRoute.library),
            ),
          ],
        ),
        if (featured == null) ...[
          const SizedBox(height: 14),
          if (home.localSelection.phase == LoadPhase.error &&
              home.history.phase != LoadPhase.data)
            YYErrorBanner(
              title: '精选暂时不可用',
              message: '曲库读取未完成，可以重试。',
              actionLabel: '重试',
              onAction: () {
                unawaited(home.refreshCatalog());
                home.retryHistory();
              },
            )
          else
            const YYEmptyState(message: '暂无可播放的精选曲目'),
        ],
      ],
    );
    return DecoratedBox(
      key: const ValueKey('home-hero'),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(YYRadius.hero),
        border: Border.all(color: colors.border),
        boxShadow: YYShadows.hero,
      ),
      child: Padding(
        padding: EdgeInsets.all(wide ? 28 : 22),
        child: wide
            ? Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 24),
                  ExcludeSemantics(
                    child: SizedBox.square(
                      dimension: 164,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.text,
                          border: Border.all(
                            color: colors.strongBorder,
                            width: 16,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: YYTheme.of(context).accent.color,
                            ),
                            child: Center(
                              child: YYIcon(
                                glyph: YYGlyph.music,
                                size: 24,
                                color: YYTheme.of(context).accent.onAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : copy,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: YYTypography.sectionTitle),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: YYTypography.text(
                    size: 11,
                    color: YYTheme.of(context).colors.tertiary,
                  ),
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
      const SizedBox(height: 16),
      child,
    ],
  );
}

Widget _state<T>(
  LoadState<List<T>> state, {
  required String empty,
  required VoidCallback retry,
  required Widget Function(List<T>) builder,
}) => switch (state.phase) {
  LoadPhase.idle || LoadPhase.loading => const YYSkeleton(height: 120),
  LoadPhase.empty => YYEmptyState(message: empty, glyph: YYGlyph.music),
  LoadPhase.error => YYErrorBanner(
    title: '暂时无法读取',
    message: '其他首页内容仍可使用。',
    actionLabel: '重试',
    onAction: retry,
  ),
  LoadPhase.data => builder(state.data!),
};
String _artist(Track track) =>
    track.artists.isEmpty ? '未知艺人' : track.artists.join(' / ');
String _availability(TrackAvailability value) => switch (value) {
  TrackAvailability.available => '可播放',
  TrackAvailability.localMissing => '文件失效',
  TrackAvailability.sourceDisabled => '来源停用',
  TrackAvailability.sourceRemoved => '来源已移除',
  TrackAvailability.unsupported => '暂不支持',
};
String _sourceLabel(MusicSourceStatus value) => switch (value) {
  MusicSourceStatus.connected => '已连接',
  MusicSourceStatus.disconnected => '未连接',
  MusicSourceStatus.testing => '正在测试',
  MusicSourceStatus.error => '连接失败',
  MusicSourceStatus.disabled => '已停用',
  MusicSourceStatus.unauthorized => '需授权',
  MusicSourceStatus.rateLimited => '请求受限',
  MusicSourceStatus.schemaMismatch => '响应不匹配',
  MusicSourceStatus.offline => '离线',
};
