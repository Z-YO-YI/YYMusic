import 'package:flutter/material.dart';

import 'components.dart';
import 'icons.dart';
import 'models.dart';
import 'theme.dart';

enum SgLayout { compact, medium, expanded }

typedef PageAction = void Function();

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.layout,
    required this.onOpenPlayer,
    required this.onOpenLocal,
    required this.onOpenSearch,
    required this.onOpenSettings,
  });

  final SgLayout layout;
  final PageAction onOpenPlayer;
  final PageAction onOpenLocal;
  final PageAction onOpenSearch;
  final PageAction onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SgPageScroll(
      layout: layout,
      slivers: [
        SliverToBoxAdapter(
          child: _PageHeading(
            title: '今天听什么',
            subtitle: '8 月 29 日 · 星期六',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (layout != SgLayout.compact)
                  SizedBox(
                    width: layout == SgLayout.expanded ? 280 : 220,
                    child: SgPressable(
                      onPressed: onOpenSearch,
                      semanticLabel: '打开搜索',
                      builder: (context, hovered, focused, pressed) =>
                          _SearchShortcut(hovered: hovered, focused: focused),
                    ),
                  ),
                if (layout != SgLayout.compact)
                  const SizedBox(width: SgSpace.x3),
                const SgSourceSelector(label: '全部来源'),
                const SizedBox(width: SgSpace.x2),
                _Avatar(
                  compact: layout == SgLayout.compact,
                  onPressed: onOpenSettings,
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x8)),
        if (layout == SgLayout.compact)
          SliverToBoxAdapter(
            child: ContinueListeningCard(
              compact: true,
              onPressed: onOpenPlayer,
            ),
          )
        else
          SliverToBoxAdapter(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 7,
                    child: ContinueListeningCard(
                      compact: false,
                      onPressed: onOpenPlayer,
                    ),
                  ),
                  const SizedBox(width: SgSpace.x5),
                  Expanded(
                    flex: 5,
                    child: _DeviceRelayCard(onPressed: onOpenPlayer),
                  ),
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x10)),
        const SliverToBoxAdapter(
          child: SgSectionHeader(
            title: '最近播放',
            subtitle: '继续你的聆听动线',
            action: '查看全部',
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x5)),
        SliverToBoxAdapter(
          child: AlbumCollection(
            layout: layout,
            albums: albums,
            onAlbum: onOpenPlayer,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x10)),
        SliverToBoxAdapter(
          child: SgSectionHeader(
            title: '为你推荐',
            subtitle: '根据最近的收藏与完整播放生成',
            action: layout == SgLayout.compact ? null : '刷新推荐',
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x5)),
        SliverToBoxAdapter(
          child: AlbumCollection(
            layout: layout,
            albums: [...albums.reversed],
            onAlbum: onOpenPlayer,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x10)),
        SliverToBoxAdapter(
          child: LocalMusicShortcut(
            layout: layout,
            onPressed: onOpenLocal,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x12)),
      ],
    );
  }
}

class ContinueListeningCard extends StatelessWidget {
  const ContinueListeningCard({
    super.key,
    required this.compact,
    required this.onPressed,
  });

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SgPressable(
      onPressed: onPressed,
      semanticLabel: '继续播放夜航',
      borderRadius: BorderRadius.circular(SgRadius.card),
      builder: (context, hovered, focused, pressed) => AnimatedContainer(
        duration: SgDuration.hover,
        padding: EdgeInsets.all(compact ? SgSpace.x4 : SgSpace.x6),
        decoration: BoxDecoration(
          color: hovered ? p.surfaceSecondary : p.surface,
          borderRadius: BorderRadius.circular(SgRadius.card),
          border: Border.all(color: focused ? p.accent : p.divider, width: focused ? 2 : 1),
        ),
        child: Row(
          children: [
            SgAlbumArt(
              index: 0,
              size: compact ? 76 : 128,
              radius: compact ? SgRadius.cover : SgRadius.coverLarge,
            ),
            SizedBox(width: compact ? SgSpace.x4 : SgSpace.x6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '继续播放',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: p.accent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .4,
                            ),
                      ),
                      if (!compact) ...[
                        const SizedBox(width: SgSpace.x2),
                        const SgTag('本地音乐'),
                      ],
                    ],
                  ),
                  SizedBox(height: compact ? SgSpace.x2 : SgSpace.x3),
                  Text(
                    '夜航',
                    style: compact
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: SgSpace.x1),
                  Text('林渡 · 远岸来信', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: SgSpace.x3),
                  const SgProgressBar(value: .54),
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.only(top: SgSpace.x1),
                      child: Text(
                        '02:16 / 04:12',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: compact ? SgSpace.x2 : SgSpace.x5),
            Container(
              width: compact ? 46 : 54,
              height: compact ? 46 : 54,
              decoration: BoxDecoration(color: p.textPrimary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: SgIcon(SgGlyph.play, size: compact ? 19 : 22, color: p.background),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceRelayCard extends StatelessWidget {
  const _DeviceRelayCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(SgSpace.x6),
      decoration: BoxDecoration(
        color: p.surfaceSecondary,
        borderRadius: BorderRadius.circular(SgRadius.card),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(SgRadius.icon),
                ),
                alignment: Alignment.center,
                child: SgIcon(SgGlyph.windows, size: 20, color: p.textPrimary),
              ),
              const Spacer(),
              const SgTag('在线', success: true),
            ],
          ),
          const SizedBox(height: SgSpace.x5),
          Text('跨设备继续播放', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: SgSpace.x2),
          Text('书房 Windows · “夜航” 02:16', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: SgSpace.x5),
          SgButton(
            label: '在此设备继续',
            glyph: SgGlyph.play,
            compact: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class LocalMusicShortcut extends StatelessWidget {
  const LocalMusicShortcut({
    super.key,
    required this.layout,
    required this.onPressed,
  });

  final SgLayout layout;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SgPressable(
      onPressed: onPressed,
      semanticLabel: '打开本地音乐',
      builder: (context, hovered, focused, pressed) => AnimatedContainer(
        duration: SgDuration.hover,
        padding: EdgeInsets.all(layout == SgLayout.compact ? SgSpace.x5 : SgSpace.x6),
        decoration: BoxDecoration(
          color: hovered ? p.surfaceTertiary : p.surfaceSecondary,
          borderRadius: BorderRadius.circular(SgRadius.card),
          border: Border.all(color: focused ? p.accent : p.divider, width: focused ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(SgRadius.input),
              ),
              alignment: Alignment.center,
              child: SgIcon(SgGlyph.folder, size: 24, color: p.accent),
            ),
            const SizedBox(width: SgSpace.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('本地音乐', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: SgSpace.x1),
                  Text('1,248 首歌曲 · 12 分钟前完成扫描', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            SgIcon(SgGlyph.arrowLeft, size: 18, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}

class AlbumCollection extends StatelessWidget {
  const AlbumCollection({
    super.key,
    required this.layout,
    required this.albums,
    required this.onAlbum,
  });

  final SgLayout layout;
  final List<Album> albums;
  final VoidCallback onAlbum;

  @override
  Widget build(BuildContext context) {
    if (layout == SgLayout.compact) {
      const width = 154.0;
      return SizedBox(
        height: 218,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          itemCount: albums.length,
          separatorBuilder: (_, __) => const SizedBox(width: SgSpace.x4),
          itemBuilder: (context, index) => SgAlbumCard(
            album: albums[index],
            width: width,
            onPressed: onAlbum,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (layout == SgLayout.expanded
            ? (constraints.maxWidth / 190).floor().clamp(4, 6)
            : (constraints.maxWidth / 180).floor().clamp(3, 5))
            .toInt();
        final gap = SgSpace.x5;
        final width = (constraints.maxWidth - gap * (count - 1)) / count;
        return Wrap(
          spacing: gap,
          runSpacing: SgSpace.x8,
          children: albums
              .take(count)
              .map((album) => SgAlbumCard(album: album, width: width, onPressed: onAlbum))
              .toList(),
        );
      },
    );
  }
}

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({
    super.key,
    required this.layout,
    required this.onOpenPlayer,
  });

  final SgLayout layout;
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const moods = ['专注', '通勤', '清晨', '夜晚', '运动', '阅读'];
    return SgPageScroll(
      layout: layout,
      slivers: [
        const SliverToBoxAdapter(
          child: _PageHeading(title: '发现', subtitle: '编辑选择与新的声音'),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x8)),
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 720;
              final moodCard = Container(
                      padding: const EdgeInsets.all(SgSpace.x6),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(SgRadius.card),
                        border: Border.all(color: p.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('按此刻的状态', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: SgSpace.x2),
                          Text('选择一个场景，让音乐靠近你。', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: SgSpace.x5),
                          Wrap(
                            spacing: SgSpace.x2,
                            runSpacing: SgSpace.x2,
                            children: moods
                                .map((mood) => SgButton(
                                      label: mood,
                                      compact: true,
                                      kind: SgButtonKind.secondary,
                                      onPressed: onOpenPlayer,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    );
              if (wide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 7, child: _EditorialFeature(onPressed: onOpenPlayer)),
                      const SizedBox(width: SgSpace.x5),
                      Expanded(flex: 5, child: moodCard),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EditorialFeature(onPressed: onOpenPlayer),
                  const SizedBox(height: SgSpace.x5),
                  moodCard,
                ],
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x10)),
        const SliverToBoxAdapter(
          child: SgSectionHeader(title: '编辑精选', subtitle: '来自声场编辑部的本周选择', action: '查看全部'),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x5)),
        SliverToBoxAdapter(
          child: AlbumCollection(layout: layout, albums: albums, onAlbum: onOpenPlayer),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x10)),
        const SliverToBoxAdapter(
          child: SgSectionHeader(title: '新歌速递', subtitle: '多个音乐来源的最新作品'),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x4)),
        SliverList.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) => SgTrackRow(
            track: tracks[index],
            index: index + 1,
            desktop: layout == SgLayout.expanded,
            onPressed: onOpenPlayer,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x12)),
      ],
    );
  }
}

class _EditorialFeature extends StatelessWidget {
  const _EditorialFeature({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SgPressable(
      onPressed: onPressed,
      semanticLabel: '编辑精选：夜色航行',
      borderRadius: BorderRadius.circular(SgRadius.card),
      builder: (context, hovered, focused, pressed) => Container(
        padding: const EdgeInsets.all(SgSpace.x6),
        decoration: BoxDecoration(
          color: p.playerBackground,
          borderRadius: BorderRadius.circular(SgRadius.card),
          border: Border.all(color: focused ? p.accent : p.divider, width: focused ? 2 : 1),
        ),
        child: Row(
          children: [
            const SgAlbumArt(index: 0, size: 144, radius: SgRadius.coverLarge),
            const SizedBox(width: SgSpace.x6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '编辑精选',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: p.accent,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: SgSpace.x3),
                  Text('夜色航行', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: SgSpace.x2),
                  Text('把世界的音量调低，听见海面与城市之间的呼吸。',
                      style: Theme.of(context).textTheme.bodyMedium, maxLines: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.layout,
    required this.onOpenPlayer,
    this.autofocus = false,
  });

  final SgLayout layout;
  final VoidCallback onOpenPlayer;
  final bool autofocus;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  int _segment = 0;
  int _source = 0;

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    final sources = ['全部来源', '本地音乐', '服务 A', '服务 B'];
    return SgPageScroll(
      layout: widget.layout,
      slivers: [
        SliverToBoxAdapter(
          child: _PageHeading(
            title: '搜索',
            subtitle: searching ? '正在多个来源中查找“$_query”' : '在所有音乐里找到你想听的',
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x6)),
        SliverToBoxAdapter(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SgSearchField(
              autofocus: widget.autofocus,
              initialValue: _query,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x4)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sources.length,
              separatorBuilder: (_, __) => const SizedBox(width: SgSpace.x2),
              itemBuilder: (context, index) => SgButton(
                label: sources[index],
                compact: true,
                kind: index == _source ? SgButtonKind.primary : SgButtonKind.secondary,
                onPressed: () => setState(() => _source = index),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x8)),
        if (!searching) ...[
          SliverToBoxAdapter(child: _SearchDiscovery(onQuery: (value) => setState(() => _query = value))),
        ] else ...[
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SgSegmentedControl(
                items: const ['综合', '歌曲', '专辑', '艺术家', '歌单'],
                selected: _segment,
                onChanged: (index) => setState(() => _segment = index),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x6)),
          SliverToBoxAdapter(
            child: SgSectionHeader(
              title: _segment == 0 ? '最佳匹配' : const ['综合', '歌曲', '专辑', '艺术家', '歌单'][_segment],
              subtitle: '已聚合 4 个音乐来源',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x3)),
          SliverList.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) => SgTrackRow(
              track: tracks[index],
              index: index + 1,
              desktop: widget.layout == SgLayout.expanded,
              onPressed: widget.onOpenPlayer,
              onMore: () {},
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x12)),
      ],
    );
  }
}

class _SearchDiscovery extends StatelessWidget {
  const _SearchDiscovery({required this.onQuery});

  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    const hot = ['夜航', '林渡', '华语新声', '城市民谣', '纯音乐', '爵士现场'];
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SgSectionHeader(title: '热门搜索', subtitle: '此刻大家都在听'),
        const SizedBox(height: SgSpace.x4),
        Wrap(
          spacing: SgSpace.x2,
          runSpacing: SgSpace.x2,
          children: List.generate(
            hot.length,
            (index) => SgPressable(
              onPressed: () => onQuery(hot[index]),
              semanticLabel: hot[index],
              builder: (context, hovered, focused, pressed) => Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: SgSpace.x4, vertical: SgSpace.x3),
                decoration: BoxDecoration(
                  color: hovered ? p.surfaceTertiary : p.surfaceSecondary,
                  borderRadius: BorderRadius.circular(SgRadius.button),
                  border: focused ? Border.all(color: p.accent, width: 2) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${index + 1}'.padLeft(2, '0'),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.accent)),
                    const SizedBox(width: SgSpace.x3),
                    Text(hot[index], style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: SgSpace.x10),
        const SgSectionHeader(title: '最近查找的艺术家'),
        const SizedBox(height: SgSpace.x4),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: SgSpace.x5),
            itemBuilder: (context, index) => SizedBox(
              width: 88,
              child: Column(
                children: [
                  ClipOval(child: SgAlbumArt(index: index, size: 72, radius: 36)),
                  const SizedBox(height: SgSpace.x2),
                  Text(albums[index].artist, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.layout,
    required this.onOpenLocal,
    required this.onOpenPlayer,
  });

  final SgLayout layout;
  final VoidCallback onOpenLocal;
  final VoidCallback onOpenPlayer;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    return SgPageScroll(
      layout: widget.layout,
      slivers: [
        const SliverToBoxAdapter(child: _PageHeading(title: '资料库', subtitle: '你的音乐，按自己的方式整理')),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x6)),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SgSegmentedControl(
              items: const ['全部', '本地', '收藏', '歌单', '专辑', '艺术家'],
              selected: _segment,
              onChanged: (index) {
                setState(() => _segment = index);
                if (index == 1) widget.onOpenLocal();
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x8)),
        SliverToBoxAdapter(child: LocalMusicShortcut(layout: widget.layout, onPressed: widget.onOpenLocal)),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x10)),
        const SliverToBoxAdapter(child: SgSectionHeader(title: '最近添加', subtitle: '过去 30 天加入资料库')),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x5)),
        SliverToBoxAdapter(
          child: AlbumCollection(layout: widget.layout, albums: albums, onAlbum: widget.onOpenPlayer),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x10)),
        const SliverToBoxAdapter(child: SgSectionHeader(title: '收藏歌曲', subtitle: '共 268 首')),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x3)),
        SliverList.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) => SgTrackRow(
            track: tracks[index],
            index: index + 1,
            desktop: widget.layout == SgLayout.expanded,
            onPressed: widget.onOpenPlayer,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x12)),
      ],
    );
  }
}

class LocalMusicPage extends StatefulWidget {
  const LocalMusicPage({
    super.key,
    required this.layout,
    required this.onOpenPlayer,
  });

  final SgLayout layout;
  final VoidCallback onOpenPlayer;

  @override
  State<LocalMusicPage> createState() => _LocalMusicPageState();
}

class _LocalMusicPageState extends State<LocalMusicPage> {
  bool _scanning = false;
  double _progress = .72;

  void _scan() {
    setState(() {
      _scanning = true;
      _progress = .12;
    });
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _progress = .58);
    });
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _progress = .88);
    });
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _progress = 1;
          _scanning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SgPageScroll(
      layout: widget.layout,
      slivers: [
        SliverToBoxAdapter(
          child: _PageHeading(
            title: '本地音乐',
            subtitle: '1,248 首歌曲 · 76 张专辑 · 32 位艺术家',
            trailing: Wrap(
              spacing: SgSpace.x2,
              runSpacing: SgSpace.x2,
              children: [
                SgButton(
                  label: widget.layout == SgLayout.compact ? '添加' : '添加文件夹',
                  glyph: SgGlyph.folder,
                  kind: SgButtonKind.secondary,
                  compact: true,
                  onPressed: _scan,
                ),
                SgButton(
                  label: '重新扫描',
                  glyph: SgGlyph.plus,
                  compact: true,
                  onPressed: _scan,
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x6)),
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(SgSpace.x5),
            decoration: BoxDecoration(
              color: _scanning ? p.accentSoft : p.surface,
              borderRadius: BorderRadius.circular(SgRadius.card),
              border: Border.all(color: _scanning ? p.accent : p.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SgIcon(_scanning ? SgGlyph.search : SgGlyph.check,
                        size: 22, color: _scanning ? p.accent : p.success),
                    const SizedBox(width: SgSpace.x3),
                    Expanded(
                      child: Text(
                        _scanning ? '正在建立音乐资料库' : '资料库已是最新状态',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      _scanning ? '已发现 ${(_progress * 1248).round()} 首歌曲' : '12 分钟前',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: SgSpace.x3),
                AnimatedSwitcher(
                  duration: SgDuration.page,
                  child: SgProgressBar(key: ValueKey(_progress), value: _progress),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x5)),
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth > 760 ? 3 : 1;
              const gap = SgSpace.x3;
              final width = (constraints.maxWidth - gap * (count - 1)) / count;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _LibraryStat(width: width, value: '18', label: '缺少封面', glyph: SgGlyph.library),
                  _LibraryStat(width: width, value: '43', label: '缺少歌词', glyph: SgGlyph.lyrics),
                  _LibraryStat(width: width, value: '6', label: '重复文件', glyph: SgGlyph.queue),
                ],
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x8)),
        SliverToBoxAdapter(
          child: Row(
            children: [
              const Expanded(child: SgSectionHeader(title: '歌曲', subtitle: '按最近添加排序')),
              SgIconButton(glyph: SgGlyph.filter, onPressed: () {}, tooltip: '筛选'),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x3)),
        SliverList.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) => SgTrackRow(
            track: tracks[index],
            index: index + 1,
            desktop: widget.layout == SgLayout.expanded,
            onPressed: widget.onOpenPlayer,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x12)),
      ],
    );
  }
}

class _LibraryStat extends StatelessWidget {
  const _LibraryStat({required this.width, required this.value, required this.label, required this.glyph});

  final double width;
  final String value;
  final String label;
  final SgGlyph glyph;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: width,
      padding: const EdgeInsets.all(SgSpace.x4),
      decoration: BoxDecoration(
        color: p.surfaceSecondary,
        borderRadius: BorderRadius.circular(SgRadius.card),
      ),
      child: Row(
        children: [
          SgIcon(glyph, size: 21, color: p.textSecondary),
          const SizedBox(width: SgSpace.x3),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.layout,
    required this.playing,
    required this.onTogglePlaying,
    required this.onClose,
    required this.onQueue,
  });

  final SgLayout layout;
  final bool playing;
  final VoidCallback onTogglePlaying;
  final VoidCallback onClose;
  final VoidCallback onQueue;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  double _progress = .54;
  bool _lyrics = true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (widget.layout == SgLayout.compact) {
      return ColoredBox(
        color: p.playerBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(SgSpace.x5, SgSpace.x2, SgSpace.x5, SgSpace.x8),
            child: Column(
              children: [
                Row(
                  children: [
                    SgIconButton(glyph: SgGlyph.arrowDown, onPressed: widget.onClose, tooltip: '收起播放器'),
                    const Spacer(),
                    Column(
                      children: [
                        Text('正在播放', style: Theme.of(context).textTheme.labelMedium),
                        Text('本地音乐 · Hi-Res', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    const Spacer(),
                    SgIconButton(glyph: SgGlyph.more, onPressed: () {}, tooltip: '更多'),
                  ],
                ),
                const SizedBox(height: SgSpace.x6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.maxWidth * .86;
                    return SgAlbumArt(index: 0, size: size, radius: SgRadius.coverLarge);
                  },
                ),
                const SizedBox(height: SgSpace.x8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('夜航', style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: SgSpace.x1),
                      Text('林渡 · 远岸来信', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: p.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: SgSpace.x6),
                SgProgressBar(value: _progress, onChanged: (v) => setState(() => _progress = v)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('02:16', style: Theme.of(context).textTheme.labelMedium),
                    Text('-01:56', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
                const SizedBox(height: SgSpace.x4),
                _PlayerControls(playing: widget.playing, onToggle: widget.onTogglePlaying, large: true),
                const SizedBox(height: SgSpace.x6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SgIconButton(glyph: SgGlyph.heart, onPressed: () {}, tooltip: '收藏'),
                    SgIconButton(glyph: SgGlyph.lyrics, onPressed: () => setState(() => _lyrics = !_lyrics), tooltip: '歌词', selected: _lyrics),
                    SgIconButton(glyph: SgGlyph.device, onPressed: () {}, tooltip: '设备'),
                    SgIconButton(glyph: SgGlyph.queue, onPressed: widget.onQueue, tooltip: '播放队列'),
                  ],
                ),
                if (_lyrics) ...[
                  const SizedBox(height: SgSpace.x8),
                  const LyricsView(compact: true),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: p.playerBackground,
      child: Padding(
        padding: EdgeInsets.all(widget.layout == SgLayout.expanded ? SgSpace.x10 : SgSpace.x8),
        child: Column(
          children: [
            Row(
              children: [
                SgIconButton(glyph: SgGlyph.arrowLeft, onPressed: widget.onClose, tooltip: '返回'),
                const SizedBox(width: SgSpace.x2),
                Text('正在播放', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                const SgTag('本地音乐'),
                const SizedBox(width: SgSpace.x2),
                const SgTag('Hi-Res', accent: true),
                SgIconButton(glyph: SgGlyph.more, onPressed: () {}, tooltip: '更多'),
              ],
            ),
            const SizedBox(height: SgSpace.x6),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 470),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final size = constraints.maxWidth.clamp(260.0, 470.0).toDouble();
                                return SgAlbumArt(index: 0, size: size, radius: SgRadius.coverLarge);
                              },
                            ),
                            const SizedBox(height: SgSpace.x6),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('夜航', style: Theme.of(context).textTheme.headlineLarge),
                                      Text('林渡 · 远岸来信', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: p.textSecondary)),
                                    ],
                                  ),
                                ),
                                SgIconButton(glyph: SgGlyph.heart, onPressed: () {}, tooltip: '收藏'),
                              ],
                            ),
                            const SizedBox(height: SgSpace.x4),
                            SgProgressBar(value: _progress, onChanged: (v) => setState(() => _progress = v)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('02:16', style: Theme.of(context).textTheme.labelMedium),
                                Text('04:12', style: Theme.of(context).textTheme.labelMedium),
                              ],
                            ),
                            const SizedBox(height: SgSpace.x4),
                            _PlayerControls(playing: widget.playing, onToggle: widget.onTogglePlaying, large: false),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: SgSpace.x12),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        SgSegmentedControl(
                          items: const ['歌词', '队列'],
                          selected: _lyrics ? 0 : 1,
                          onChanged: (value) => setState(() => _lyrics = value == 0),
                        ),
                        const SizedBox(height: SgSpace.x6),
                        Expanded(child: _lyrics ? const LyricsView() : QueuePanel(compact: false, onClose: widget.onQueue)),
                      ],
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
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({required this.playing, required this.onToggle, required this.large});

  final bool playing;
  final VoidCallback onToggle;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SgIconButton(glyph: SgGlyph.shuffle, onPressed: () {}, tooltip: '随机播放'),
        SizedBox(width: large ? SgSpace.x3 : SgSpace.x2),
        SgIconButton(glyph: SgGlyph.previous, onPressed: () {}, tooltip: '上一首', size: 52, iconSize: 25),
        SizedBox(width: large ? SgSpace.x4 : SgSpace.x3),
        SgPressable(
          onPressed: onToggle,
          semanticLabel: playing ? '暂停' : '播放',
          borderRadius: BorderRadius.circular(36),
          builder: (context, hovered, focused, pressed) => Container(
            width: large ? 66 : 58,
            height: large ? 66 : 58,
            decoration: BoxDecoration(
              color: p.textPrimary,
              shape: BoxShape.circle,
              border: focused ? Border.all(color: p.accent, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: SgIcon(playing ? SgGlyph.pause : SgGlyph.play,
                size: large ? 27 : 24, color: p.background),
          ),
        ),
        SizedBox(width: large ? SgSpace.x4 : SgSpace.x3),
        SgIconButton(glyph: SgGlyph.next, onPressed: () {}, tooltip: '下一首', size: 52, iconSize: 25),
        SizedBox(width: large ? SgSpace.x3 : SgSpace.x2),
        SgIconButton(glyph: SgGlyph.repeat, onPressed: () {}, tooltip: '循环播放'),
      ],
    );
  }
}

class LyricsView extends StatelessWidget {
  const LyricsView({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lines = <(String, String?)>[
      ('城市慢慢熄灭了回声', null),
      ('海面留下一条银色的路', 'A silver road remains across the sea'),
      ('我沿着夜色向远岸航行', 'I sail toward the distant shore'),
      ('让风替我收好没有寄出的信', null),
      ('当清晨从地平线醒来', null),
      ('我们会在同一首歌里重逢', 'We will meet again in the same song'),
    ];
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: compact ? SgSpace.x2 : SgSpace.x8),
      itemCount: lines.length,
      separatorBuilder: (_, __) => SizedBox(height: compact ? SgSpace.x5 : SgSpace.x8),
      itemBuilder: (context, index) {
        final active = index == 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lines[index].$1,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: active ? p.accent : p.textPrimary.withValues(alpha: active ? 1 : .48),
                    fontSize: active ? (compact ? 22 : 26) : (compact ? 19 : 22),
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
            if (lines[index].$2 != null) ...[
              const SizedBox(height: SgSpace.x2),
              Text(
                lines[index].$2!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: active ? p.textSecondary : p.textTertiary,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class QueuePanel extends StatelessWidget {
  const QueuePanel({
    super.key,
    required this.compact,
    required this.onClose,
  });

  final bool compact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.surface.withValues(alpha: 0),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? SgSpace.x5 : SgSpace.x6,
              compact ? SgSpace.x3 : SgSpace.x6,
              compact ? SgSpace.x3 : SgSpace.x4,
              SgSpace.x3,
            ),
            child: Row(
              children: [
                Expanded(child: Text('接下来播放', style: Theme.of(context).textTheme.titleLarge)),
                SgButton(label: '清空', compact: true, kind: SgButtonKind.text, onPressed: () {}),
                if (compact) SgIconButton(glyph: SgGlyph.close, onPressed: onClose, tooltip: '关闭'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? SgSpace.x5 : SgSpace.x6),
            child: Row(
              children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle)),
                const SizedBox(width: SgSpace.x2),
                Text('当前播放 · 夜航', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                SgToggle(value: true, label: '自动续播', onChanged: (_) {}),
              ],
            ),
          ),
          const SizedBox(height: SgSpace.x3),
          Divider(height: 1, color: p.divider),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(compact ? SgSpace.x4 : SgSpace.x5),
              itemCount: tracks.length,
              itemBuilder: (context, index) => SgTrackRow(track: tracks[index], onPressed: () {}),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.layout,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final SgLayout layout;
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _unifiedSearch = true;
  bool _sync = true;
  bool _reduceTransparency = false;

  @override
  Widget build(BuildContext context) {
    return SgPageScroll(
      layout: widget.layout,
      slivers: [
        const SliverToBoxAdapter(child: _PageHeading(title: '设置', subtitle: '服务、同步与播放体验')),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x8)),
        SliverToBoxAdapter(
          child: _SettingsGroup(
            title: '音乐服务',
            children: [
              _SettingRow(
                glyph: SgGlyph.search,
                title: '统一搜索',
                subtitle: '在已连接的服务与本地音乐中同时查找',
                trailing: SgToggle(value: _unifiedSearch, onChanged: (v) => setState(() => _unifiedSearch = v)),
              ),
              const _ServiceRow(name: '音乐服务 A', account: 'gallery_user', connected: true, quality: '无损 / Hi-Res'),
              const _ServiceRow(name: '音乐服务 B', account: '需要重新授权', connected: false, quality: '最高无损'),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x6)),
        SliverToBoxAdapter(
          child: _SettingsGroup(
            title: '跨端同步',
            children: [
              _SettingRow(
                glyph: SgGlyph.device,
                title: '同步播放状态',
                subtitle: '收藏、歌单、队列和播放进度保持一致',
                trailing: SgToggle(value: _sync, onChanged: (v) => setState(() => _sync = v)),
              ),
              const _DeviceSettingRow(glyph: SgGlyph.windows, name: '书房 Windows', detail: '本机 · 正在播放'),
              const _DeviceSettingRow(glyph: SgGlyph.phone, name: 'Pixel 10', detail: '在线 · 2 分钟前同步'),
              const _DeviceSettingRow(glyph: SgGlyph.tablet, name: '客厅平板', detail: '离线 · 昨天 22:08'),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x6)),
        SliverToBoxAdapter(
          child: _SettingsGroup(
            title: '外观与可用性',
            children: [
              _SettingRow(
                glyph: widget.darkMode ? SgGlyph.moon : SgGlyph.sun,
                title: '深色模式',
                subtitle: '在低光环境中使用近黑中性界面',
                trailing: SgToggle(value: widget.darkMode, onChanged: widget.onThemeChanged),
              ),
              _SettingRow(
                glyph: SgGlyph.library,
                title: '减少透明度',
                subtitle: '将玻璃导航替换为高不透明度表面',
                trailing: SgToggle(
                  value: _reduceTransparency,
                  onChanged: (v) => setState(() => _reduceTransparency = v),
                ),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: SgSpace.x12)),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: SgSpace.x4),
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(SgRadius.card),
            border: Border.all(color: p.divider),
          ),
          child: Column(
            children: List.generate(children.length, (index) {
              return Column(
                children: [
                  children[index],
                  if (index < children.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 72),
                      child: Divider(height: 1, color: p.divider),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.glyph, required this.title, required this.subtitle, required this.trailing});

  final SgGlyph glyph;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final leading = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: p.surfaceSecondary, borderRadius: BorderRadius.circular(SgRadius.icon)),
      alignment: Alignment.center,
      child: SgIcon(glyph, size: 20, color: p.textPrimary),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: SgSpace.x1),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.all(SgSpace.x4),
        child: constraints.maxWidth < 560
            ? Column(
                children: [
                  Row(
                    children: [
                      leading,
                      const SizedBox(width: SgSpace.x4),
                      Expanded(child: copy),
                    ],
                  ),
                  const SizedBox(height: SgSpace.x3),
                  Align(alignment: Alignment.centerRight, child: trailing),
                ],
              )
            : Row(
                children: [
                  leading,
                  const SizedBox(width: SgSpace.x4),
                  Expanded(child: copy),
                  const SizedBox(width: SgSpace.x4),
                  trailing,
                ],
              ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.name, required this.account, required this.connected, required this.quality});

  final String name;
  final String account;
  final bool connected;
  final String quality;

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      glyph: SgGlyph.library,
      title: name,
      subtitle: '$account · $quality',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SgTag(connected ? '已连接' : '需授权', success: connected, accent: !connected),
          const SizedBox(width: SgSpace.x2),
          SgButton(
            label: connected ? '管理' : '重新授权',
            compact: true,
            kind: connected ? SgButtonKind.secondary : SgButtonKind.primary,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _DeviceSettingRow extends StatelessWidget {
  const _DeviceSettingRow({required this.glyph, required this.name, required this.detail});

  final SgGlyph glyph;
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      glyph: glyph,
      title: name,
      subtitle: detail,
      trailing: SgIconButton(glyph: SgGlyph.more, onPressed: () {}, tooltip: '设备操作'),
    );
  }
}

class SgPageScroll extends StatelessWidget {
  const SgPageScroll({
    super.key,
    required this.layout,
    required this.slivers,
  });

  final SgLayout layout;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final horizontal = layout == SgLayout.compact
        ? SgSpace.x4
        : layout == SgLayout.medium
            ? SgSpace.x6
            : SgSpace.x10;
    return CustomScrollView(
      key: PageStorageKey(layout),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontal, SgSpace.x8, horizontal, 0),
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        if (subtitle != null) ...[
          const SizedBox(height: SgSpace.x1),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (trailing != null && constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: SgSpace.x3),
              trailing!,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: copy),
            if (trailing != null) ...[
              const SizedBox(width: SgSpace.x4),
              trailing!,
            ],
          ],
        );
      },
    );
  }
}

class _SearchShortcut extends StatelessWidget {
  const _SearchShortcut({required this.hovered, required this.focused});

  final bool hovered;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: SgDuration.hover,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: SgSpace.x3),
      decoration: BoxDecoration(
        color: hovered ? p.surfaceTertiary : p.surfaceSecondary,
        borderRadius: BorderRadius.circular(SgRadius.input),
        border: focused ? Border.all(color: p.accent, width: 2) : null,
      ),
      child: Row(
        children: [
          SgIcon(SgGlyph.search, size: 17, color: p.textSecondary),
          const SizedBox(width: SgSpace.x2),
          Expanded(child: Text('搜索音乐', style: Theme.of(context).textTheme.bodyMedium)),
          const SgTag('Ctrl K'),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.compact, required this.onPressed});

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = compact ? 40.0 : 42.0;
    return SgPressable(
      onPressed: onPressed,
      semanticLabel: '账户与设置',
      borderRadius: BorderRadius.circular(size / 2),
      builder: (context, hovered, focused, pressed) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hovered ? p.surfaceSecondary : p.accentSoft,
          shape: BoxShape.circle,
          border: Border.all(color: focused ? p.accent : p.divider, width: focused ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          '声',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: p.accent, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
