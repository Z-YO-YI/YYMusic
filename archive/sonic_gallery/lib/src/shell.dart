import 'package:flutter/material.dart';

import 'components.dart';
import 'icons.dart';
import 'pages.dart';
import 'theme.dart';

enum AppView { home, discover, search, library, localMusic, settings, player }

class SgResponsiveShell extends StatelessWidget {
  const SgResponsiveShell({
    super.key,
    required this.layout,
    required this.view,
    required this.content,
    required this.playing,
    required this.queueOpen,
    required this.darkMode,
    required this.onNavigate,
    required this.onOpenPlayer,
    required this.onTogglePlaying,
    required this.onToggleQueue,
    required this.onToggleTheme,
  });

  final SgLayout layout;
  final AppView view;
  final Widget content;
  final bool playing;
  final bool queueOpen;
  final bool darkMode;
  final ValueChanged<AppView> onNavigate;
  final VoidCallback onOpenPlayer;
  final VoidCallback onTogglePlaying;
  final VoidCallback onToggleQueue;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case SgLayout.compact:
        return _CompactShell(
          view: view,
          content: content,
          playing: playing,
          queueOpen: queueOpen,
          onNavigate: onNavigate,
          onOpenPlayer: onOpenPlayer,
          onTogglePlaying: onTogglePlaying,
          onToggleQueue: onToggleQueue,
        );
      case SgLayout.medium:
        return _MediumShell(
          view: view,
          content: content,
          playing: playing,
          queueOpen: queueOpen,
          onNavigate: onNavigate,
          onOpenPlayer: onOpenPlayer,
          onTogglePlaying: onTogglePlaying,
          onToggleQueue: onToggleQueue,
          onToggleTheme: onToggleTheme,
          darkMode: darkMode,
        );
      case SgLayout.expanded:
        return _ExpandedShell(
          view: view,
          content: content,
          playing: playing,
          queueOpen: queueOpen,
          onNavigate: onNavigate,
          onOpenPlayer: onOpenPlayer,
          onTogglePlaying: onTogglePlaying,
          onToggleQueue: onToggleQueue,
          onToggleTheme: onToggleTheme,
          darkMode: darkMode,
        );
    }
  }
}

class _CompactShell extends StatelessWidget {
  const _CompactShell({
    required this.view,
    required this.content,
    required this.playing,
    required this.queueOpen,
    required this.onNavigate,
    required this.onOpenPlayer,
    required this.onTogglePlaying,
    required this.onToggleQueue,
  });

  final AppView view;
  final Widget content;
  final bool playing;
  final bool queueOpen;
  final ValueChanged<AppView> onNavigate;
  final VoidCallback onOpenPlayer;
  final VoidCallback onTogglePlaying;
  final VoidCallback onToggleQueue;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.background,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 142),
                child: AnimatedSwitcher(
                  duration: SgDuration.page,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(key: ValueKey(view), child: content),
                ),
              ),
            ),
            Positioned(
              left: SgSpace.x3,
              right: SgSpace.x3,
              bottom: 76,
              child: MobileMiniPlayer(
                playing: playing,
                onOpen: onOpenPlayer,
                onTogglePlaying: onTogglePlaying,
              ),
            ),
            Positioned(
              left: SgSpace.x3,
              right: SgSpace.x3,
              bottom: SgSpace.x2,
              child: MobileNavigation(
                selected: _rootIndex(view),
                onChanged: (index) => onNavigate(_rootView(index)),
              ),
            ),
            if (queueOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: onToggleQueue,
                  child: ColoredBox(color: p.scrim),
                ),
              ),
              Positioned(
                left: SgSpace.x2,
                right: SgSpace.x2,
                bottom: SgSpace.x2,
                height: MediaQuery.sizeOf(context).height * .68,
                child: SgGlassPanel(
                  borderRadius: SgRadius.dialog,
                  child: QueuePanel(compact: true, onClose: onToggleQueue),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MobileMiniPlayer extends StatelessWidget {
  const MobileMiniPlayer({
    super.key,
    required this.playing,
    required this.onOpen,
    required this.onTogglePlaying,
  });

  final bool playing;
  final VoidCallback onOpen;
  final VoidCallback onTogglePlaying;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SgGlassPanel(
      borderRadius: SgRadius.card,
      child: Stack(
        children: [
          SgPressable(
            onPressed: onOpen,
            semanticLabel: '打开正在播放',
            borderRadius: BorderRadius.circular(SgRadius.card),
            builder: (context, hovered, focused, pressed) => SizedBox(
              height: 58,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(SgSpace.x2, SgSpace.x2, 96, SgSpace.x2),
                child: Row(
                  children: [
                    const SgAlbumArt(index: 0, size: 42, radius: 9),
                    const SizedBox(width: SgSpace.x3),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('夜航', maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('林渡', maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 44,
            top: 7,
            child: SgIconButton(
              glyph: playing ? SgGlyph.pause : SgGlyph.play,
              onPressed: onTogglePlaying,
              tooltip: playing ? '暂停' : '播放',
              size: 44,
              iconSize: 20,
            ),
          ),
          Positioned(
            right: 2,
            top: 7,
            child: SgIconButton(glyph: SgGlyph.next, onPressed: () {}, tooltip: '下一首', size: 44, iconSize: 20),
          ),
          Positioned(
            left: SgSpace.x2,
            right: SgSpace.x2,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Container(height: 2, color: p.surfaceTertiary),
                  FractionallySizedBox(widthFactor: .54, child: Container(height: 2, color: p.accent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobileNavigation extends StatelessWidget {
  const MobileNavigation({super.key, required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  static const items = <(String, SgGlyph)>[
    ('首页', SgGlyph.home),
    ('发现', SgGlyph.discover),
    ('搜索', SgGlyph.search),
    ('资料库', SgGlyph.library),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SgGlassPanel(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        height: 54,
        child: Row(
          children: List.generate(items.length, (index) {
            final active = index == selected;
            return Expanded(
              child: SgPressable(
                onPressed: () => onChanged(index),
                semanticLabel: items[index].$1,
                borderRadius: BorderRadius.circular(17),
                builder: (context, hovered, focused, pressed) => AnimatedContainer(
                  duration: SgDuration.panel,
                  decoration: BoxDecoration(
                    color: active
                        ? p.accentSoft
                        : hovered
                            ? p.surfaceSecondary
                            : p.surface.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(17),
                    border: focused ? Border.all(color: p.accent, width: 2) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SgIcon(items[index].$2, size: 20, color: active ? p.accent : p.textSecondary, filled: active),
                      const SizedBox(height: 2),
                      Text(
                        items[index].$1,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: active ? p.accent : p.textSecondary,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _MediumShell extends StatelessWidget {
  const _MediumShell({
    required this.view,
    required this.content,
    required this.playing,
    required this.queueOpen,
    required this.darkMode,
    required this.onNavigate,
    required this.onOpenPlayer,
    required this.onTogglePlaying,
    required this.onToggleQueue,
    required this.onToggleTheme,
  });

  final AppView view;
  final Widget content;
  final bool playing;
  final bool queueOpen;
  final bool darkMode;
  final ValueChanged<AppView> onNavigate;
  final VoidCallback onOpenPlayer;
  final VoidCallback onTogglePlaying;
  final VoidCallback onToggleQueue;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SgSpace.x3),
          child: Row(
            children: [
              TabletRail(
                selected: _rootIndex(view),
                darkMode: darkMode,
                onChanged: (index) => onNavigate(_rootView(index)),
                onSettings: () => onNavigate(AppView.settings),
                onToggleTheme: onToggleTheme,
              ),
              const SizedBox(width: SgSpace.x3),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(SgRadius.card),
                              child: AnimatedSwitcher(
                                duration: SgDuration.page,
                                child: KeyedSubtree(key: ValueKey(view), child: content),
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: SgDuration.panel,
                            width: queueOpen ? 320 : 0,
                            margin: EdgeInsets.only(left: queueOpen ? SgSpace.x3 : 0),
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: p.surface,
                              borderRadius: BorderRadius.circular(SgRadius.card),
                              border: queueOpen ? Border.all(color: p.divider) : null,
                            ),
                            child: queueOpen
                                ? QueuePanel(compact: false, onClose: onToggleQueue)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: SgSpace.x3),
                    DesktopPlayer(
                      compact: true,
                      playing: playing,
                      onOpen: onOpenPlayer,
                      onTogglePlaying: onTogglePlaying,
                      onToggleQueue: onToggleQueue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TabletRail extends StatelessWidget {
  const TabletRail({
    super.key,
    required this.selected,
    required this.darkMode,
    required this.onChanged,
    required this.onSettings,
    required this.onToggleTheme,
  });

  final int selected;
  final bool darkMode;
  final ValueChanged<int> onChanged;
  final VoidCallback onSettings;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const icons = [SgGlyph.home, SgGlyph.discover, SgGlyph.search, SgGlyph.library];
    return SizedBox(
      width: 84,
      child: SgGlassPanel(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SgSpace.x3),
          child: Column(
            children: [
              _BrandMark(compact: true),
              const SizedBox(height: SgSpace.x8),
              ...List.generate(icons.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: SgSpace.x1, horizontal: SgSpace.x3),
                  child: SgIconButton(
                    glyph: icons[index],
                    onPressed: () => onChanged(index),
                    tooltip: MobileNavigation.items[index].$1,
                    size: 52,
                    selected: selected == index,
                  ),
                );
              }),
              const Spacer(),
              SgIconButton(
                glyph: darkMode ? SgGlyph.sun : SgGlyph.moon,
                onPressed: onToggleTheme,
                tooltip: darkMode ? '浅色模式' : '深色模式',
              ),
              SgIconButton(glyph: SgGlyph.settings, onPressed: onSettings, tooltip: '设置'),
              const SizedBox(height: SgSpace.x2),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: p.accentSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('声', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.accent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedShell extends StatelessWidget {
  const _ExpandedShell({
    required this.view,
    required this.content,
    required this.playing,
    required this.queueOpen,
    required this.darkMode,
    required this.onNavigate,
    required this.onOpenPlayer,
    required this.onTogglePlaying,
    required this.onToggleQueue,
    required this.onToggleTheme,
  });

  final AppView view;
  final Widget content;
  final bool playing;
  final bool queueOpen;
  final bool darkMode;
  final ValueChanged<AppView> onNavigate;
  final VoidCallback onOpenPlayer;
  final VoidCallback onTogglePlaying;
  final VoidCallback onToggleQueue;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.background,
      child: Column(
        children: [
          WindowsTitleBar(view: view),
          Expanded(
            child: Row(
              children: [
                DesktopSidebar(
                  view: view,
                  darkMode: darkMode,
                  onNavigate: onNavigate,
                  onToggleTheme: onToggleTheme,
                ),
                VerticalDivider(width: 1, color: p.divider),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: AnimatedSwitcher(
                        duration: SgDuration.page,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(key: ValueKey(view), child: content),
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: SgDuration.panel,
                  width: queueOpen ? 340 : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: p.surface,
                    border: queueOpen ? Border(left: BorderSide(color: p.divider)) : null,
                  ),
                  child: queueOpen ? QueuePanel(compact: false, onClose: onToggleQueue) : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.divider),
          DesktopPlayer(
            playing: playing,
            onOpen: onOpenPlayer,
            onTogglePlaying: onTogglePlaying,
            onToggleQueue: onToggleQueue,
          ),
        ],
      ),
    );
  }
}

class WindowsTitleBar extends StatelessWidget {
  const WindowsTitleBar({super.key, required this.view});

  final AppView view;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final title = {
      AppView.home: '首页',
      AppView.discover: '发现',
      AppView.search: '搜索',
      AppView.library: '资料库',
      AppView.localMusic: '本地音乐',
      AppView.settings: '设置',
      AppView.player: '正在播放',
    }[view]!;
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          const SizedBox(width: SgSpace.x3),
          SgIconButton(glyph: SgGlyph.arrowLeft, onPressed: () {}, tooltip: '返回', size: 38, iconSize: 17),
          SgIconButton(glyph: SgGlyph.arrowLeft, onPressed: null, tooltip: '前进', size: 38, iconSize: 17),
          const SizedBox(width: SgSpace.x3),
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          _WindowButton(kind: _WindowButtonKind.minimize, onPressed: () {}),
          _WindowButton(kind: _WindowButtonKind.maximize, onPressed: () {}),
          _WindowButton(kind: _WindowButtonKind.close, onPressed: () {}, danger: true),
          Container(width: 1, height: 20, color: p.divider),
        ],
      ),
    );
  }
}

enum _WindowButtonKind { minimize, maximize, close }

class _WindowButton extends StatelessWidget {
  const _WindowButton({required this.kind, required this.onPressed, this.danger = false});

  final _WindowButtonKind kind;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SgPressable(
      onPressed: onPressed,
      semanticLabel: kind.name,
      borderRadius: BorderRadius.zero,
      builder: (context, hovered, focused, pressed) => Container(
        width: 46,
        height: 46,
        color: hovered ? (danger ? p.error : p.surfaceSecondary) : p.surface.withValues(alpha: 0),
        alignment: Alignment.center,
        child: CustomPaint(
          size: const Size(12, 12),
          painter: _WindowGlyphPainter(kind, hovered && danger ? p.surface : p.textPrimary),
        ),
      ),
    );
  }
}

class _WindowGlyphPainter extends CustomPainter {
  const _WindowGlyphPainter(this.kind, this.color);

  final _WindowButtonKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    switch (kind) {
      case _WindowButtonKind.minimize:
        canvas.drawLine(Offset(1, size.height - 2), Offset(size.width - 1, size.height - 2), paint);
        break;
      case _WindowButtonKind.maximize:
        canvas.drawRect(Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3), paint);
        break;
      case _WindowButtonKind.close:
        canvas.drawLine(const Offset(1.5, 1.5), Offset(size.width - 1.5, size.height - 1.5), paint);
        canvas.drawLine(Offset(size.width - 1.5, 1.5), Offset(1.5, size.height - 1.5), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _WindowGlyphPainter oldDelegate) => oldDelegate.kind != kind || oldDelegate.color != color;
}

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.view,
    required this.darkMode,
    required this.onNavigate,
    required this.onToggleTheme,
  });

  final AppView view;
  final bool darkMode;
  final ValueChanged<AppView> onNavigate;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 232,
      color: p.glass,
      padding: const EdgeInsets.fromLTRB(SgSpace.x4, SgSpace.x5, SgSpace.x4, SgSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: SgSpace.x2),
            child: _BrandMark(),
          ),
          const SizedBox(height: SgSpace.x8),
          _SidebarItem(label: '首页', glyph: SgGlyph.home, selected: view == AppView.home, onPressed: () => onNavigate(AppView.home)),
          _SidebarItem(label: '发现', glyph: SgGlyph.discover, selected: view == AppView.discover, onPressed: () => onNavigate(AppView.discover)),
          _SidebarItem(label: '搜索', glyph: SgGlyph.search, selected: view == AppView.search, onPressed: () => onNavigate(AppView.search), shortcut: 'Ctrl K'),
          _SidebarItem(label: '资料库', glyph: SgGlyph.library, selected: view == AppView.library, onPressed: () => onNavigate(AppView.library)),
          const SizedBox(height: SgSpace.x6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SgSpace.x3),
            child: Text('我的资料库', style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(height: SgSpace.x2),
          _SidebarItem(label: '本地音乐', glyph: SgGlyph.folder, selected: view == AppView.localMusic, onPressed: () => onNavigate(AppView.localMusic)),
          _SidebarItem(label: '收藏歌曲', glyph: SgGlyph.heart, selected: false, onPressed: () => onNavigate(AppView.library)),
          _SidebarItem(label: '歌单', glyph: SgGlyph.queue, selected: false, onPressed: () => onNavigate(AppView.library)),
          _SidebarItem(label: '专辑', glyph: SgGlyph.library, selected: false, onPressed: () => onNavigate(AppView.library)),
          const Spacer(),
          _SidebarItem(
            label: darkMode ? '浅色模式' : '深色模式',
            glyph: darkMode ? SgGlyph.sun : SgGlyph.moon,
            selected: false,
            onPressed: onToggleTheme,
          ),
          _SidebarItem(label: '设置', glyph: SgGlyph.settings, selected: view == AppView.settings, onPressed: () => onNavigate(AppView.settings), shortcut: 'Ctrl ,'),
          const SizedBox(height: SgSpace.x3),
          Divider(color: p.divider),
          const SizedBox(height: SgSpace.x2),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: p.accentSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('声', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.accent)),
              ),
              const SizedBox(width: SgSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('声场用户', style: Theme.of(context).textTheme.titleMedium),
                    Text('同步已开启', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.glyph,
    required this.selected,
    required this.onPressed,
    this.shortcut,
  });

  final String label;
  final SgGlyph glyph;
  final bool selected;
  final VoidCallback onPressed;
  final String? shortcut;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: SgSpace.x1),
      child: SgPressable(
        onPressed: onPressed,
        semanticLabel: label,
        builder: (context, hovered, focused, pressed) => AnimatedContainer(
          duration: SgDuration.hover,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: SgSpace.x3),
          decoration: BoxDecoration(
            color: selected
                ? p.accentSoft
                : hovered
                    ? p.surfaceSecondary
                    : p.surface.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(SgRadius.input),
            border: focused ? Border.all(color: p.accent, width: 2) : null,
          ),
          child: Row(
            children: [
              SgIcon(glyph, size: 20, color: selected ? p.accent : p.textSecondary, filled: selected),
              const SizedBox(width: SgSpace.x3),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: selected ? p.accent : p.textPrimary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
              if (shortcut != null)
                Text(shortcut!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: p.textPrimary, borderRadius: BorderRadius.circular(11)),
          alignment: Alignment.center,
          child: CustomPaint(size: const Size(20, 20), painter: _BrandPainter(p.background, p.accent)),
        ),
        if (!compact) ...[
          const SizedBox(width: SgSpace.x3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('声场画廊', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text('SONIC GALLERY', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 9, letterSpacing: 1.1)),
            ],
          ),
        ],
      ],
    );
  }
}

class _BrandPainter extends CustomPainter {
  const _BrandPainter(this.foreground, this.accent);

  final Color foreground;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 2..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    paint.color = foreground;
    canvas.drawCircle(Offset(size.width * .38, size.height * .5), size.width * .22, paint);
    paint.color = accent;
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width * .6, size.height * .5), radius: size.width * .28), -1.2, 2.4, false, paint);
  }

  @override
  bool shouldRepaint(covariant _BrandPainter oldDelegate) => oldDelegate.foreground != foreground || oldDelegate.accent != accent;
}

class DesktopPlayer extends StatelessWidget {
  const DesktopPlayer({
    super.key,
    required this.playing,
    required this.onOpen,
    required this.onTogglePlaying,
    required this.onToggleQueue,
    this.compact = false,
  });

  final bool playing;
  final VoidCallback onOpen;
  final VoidCallback onTogglePlaying;
  final VoidCallback onToggleQueue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final height = compact ? 72.0 : 86.0;
    return Container(
      height: height,
      color: p.surface,
      padding: EdgeInsets.symmetric(horizontal: compact ? SgSpace.x4 : SgSpace.x6),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 180 : 300,
            child: SgPressable(
              onPressed: onOpen,
              semanticLabel: '打开正在播放',
              builder: (context, hovered, focused, pressed) => Row(
                children: [
                  SgAlbumArt(index: 0, size: compact ? 48 : 52, radius: 10),
                  const SizedBox(width: SgSpace.x3),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('夜航', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                        Text('林渡', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (!compact) SgIconButton(glyph: SgGlyph.heart, onPressed: () {}, tooltip: '收藏', size: 40),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!compact) SgIconButton(glyph: SgGlyph.shuffle, onPressed: () {}, tooltip: '随机', size: 36, iconSize: 17),
                    SgIconButton(glyph: SgGlyph.previous, onPressed: () {}, tooltip: '上一首', size: 38, iconSize: 19),
                    const SizedBox(width: SgSpace.x2),
                    SgPressable(
                      onPressed: onTogglePlaying,
                      semanticLabel: playing ? '暂停' : '播放',
                      borderRadius: BorderRadius.circular(22),
                      builder: (context, hovered, focused, pressed) => Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: p.textPrimary, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: SgIcon(playing ? SgGlyph.pause : SgGlyph.play, size: 18, color: p.background),
                      ),
                    ),
                    const SizedBox(width: SgSpace.x2),
                    SgIconButton(glyph: SgGlyph.next, onPressed: () {}, tooltip: '下一首', size: 38, iconSize: 19),
                    if (!compact) SgIconButton(glyph: SgGlyph.repeat, onPressed: () {}, tooltip: '循环', size: 36, iconSize: 17),
                  ],
                ),
                if (!compact)
                  Row(
                    children: [
                      Text('02:16', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(width: SgSpace.x2),
                      const Expanded(child: SgProgressBar(value: .54)),
                      const SizedBox(width: SgSpace.x2),
                      Text('04:12', style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(
            width: compact ? 100 : 320,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!compact) ...[
                  const SgTag('Hi-Res', accent: true),
                  SgIconButton(glyph: SgGlyph.device, onPressed: () {}, tooltip: '设备', size: 40, iconSize: 18),
                  SgIconButton(glyph: SgGlyph.lyrics, onPressed: onOpen, tooltip: '歌词', size: 40, iconSize: 18),
                ],
                SgIconButton(glyph: SgGlyph.queue, onPressed: onToggleQueue, tooltip: '播放队列', size: 40, iconSize: 18),
                SgIconButton(glyph: SgGlyph.volume, onPressed: () {}, tooltip: '音量', size: 40, iconSize: 18),
                if (!compact)
                  SizedBox(
                    width: 72,
                    child: SgProgressBar(value: .72, onChanged: (_) {}),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int _rootIndex(AppView view) {
  switch (view) {
    case AppView.home:
      return 0;
    case AppView.discover:
      return 1;
    case AppView.search:
      return 2;
    case AppView.library:
    case AppView.localMusic:
    case AppView.settings:
    case AppView.player:
      return 3;
  }
}

AppView _rootView(int index) {
  return const [AppView.home, AppView.discover, AppView.search, AppView.library][index.clamp(0, 3).toInt()];
}
