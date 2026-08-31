import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components.dart';
import 'pages.dart';
import 'shell.dart';
import 'theme.dart';

class SonicGalleryApp extends StatefulWidget {
  const SonicGalleryApp({super.key});

  @override
  State<SonicGalleryApp> createState() => _SonicGalleryAppState();
}

class _SonicGalleryAppState extends State<SonicGalleryApp> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final palette = _darkMode ? SgPalette.dark : SgPalette.light;
    return MaterialApp(
      title: '声场画廊 Sonic Gallery',
      debugShowCheckedModeBanner: false,
      theme: sonicTheme(palette),
      home: AppFrame(
        darkMode: _darkMode,
        onThemeChanged: (value) => setState(() => _darkMode = value),
      ),
    );
  }
}

class AppFrame extends StatefulWidget {
  const AppFrame({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<AppFrame> createState() => _AppFrameState();
}

class _AppFrameState extends State<AppFrame> {
  AppView _view = AppView.home;
  AppView _previousView = AppView.home;
  bool _playing = true;
  bool _queueOpen = false;

  void _navigate(AppView view) {
    setState(() {
      if (view != AppView.player) _previousView = view;
      _view = view;
      if (view != AppView.player && view != AppView.search) {
        _queueOpen = false;
      }
    });
  }

  void _openPlayer() {
    setState(() {
      if (_view != AppView.player) _previousView = _view;
      _view = AppView.player;
    });
  }

  void _closePlayer() => setState(() => _view = _previousView);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = constraints.maxWidth < 600
            ? SgLayout.compact
            : constraints.maxWidth < 1024
                ? SgLayout.medium
                : SgLayout.expanded;
        final content = _buildPage(layout);

        if (layout == SgLayout.compact && _view == AppView.player) {
          final p = context.palette;
          return Stack(
            children: [
              PlayerPage(
                layout: layout,
                playing: _playing,
                onTogglePlaying: () => setState(() => _playing = !_playing),
                onClose: _closePlayer,
                onQueue: () => setState(() => _queueOpen = !_queueOpen),
              ),
              if (_queueOpen) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _queueOpen = false),
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
                    child: QueuePanel(
                      compact: true,
                      onClose: () => setState(() => _queueOpen = false),
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.space): () => setState(() => _playing = !_playing),
            const SingleActivator(LogicalKeyboardKey.keyK, control: true): () => _navigate(AppView.search),
            const SingleActivator(LogicalKeyboardKey.keyO, control: true): () => _navigate(AppView.localMusic),
            const SingleActivator(LogicalKeyboardKey.comma, control: true): () => _navigate(AppView.settings),
            const SingleActivator(LogicalKeyboardKey.keyL, control: true): () => _navigate(AppView.library),
            const SingleActivator(LogicalKeyboardKey.keyQ, control: true): () => setState(() => _queueOpen = !_queueOpen),
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (_queueOpen) {
                setState(() => _queueOpen = false);
              } else if (_view == AppView.player) {
                _closePlayer();
              }
            },
          },
          child: Focus(
            autofocus: true,
            child: SgResponsiveShell(
              layout: layout,
              view: _view,
              content: content,
              playing: _playing,
              queueOpen: _queueOpen,
              darkMode: widget.darkMode,
              onNavigate: _navigate,
              onOpenPlayer: _openPlayer,
              onTogglePlaying: () => setState(() => _playing = !_playing),
              onToggleQueue: () => setState(() => _queueOpen = !_queueOpen),
              onToggleTheme: () => widget.onThemeChanged(!widget.darkMode),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(SgLayout layout) {
    switch (_view) {
      case AppView.home:
        return HomePage(
          layout: layout,
          onOpenPlayer: _openPlayer,
          onOpenLocal: () => _navigate(AppView.localMusic),
          onOpenSearch: () => _navigate(AppView.search),
          onOpenSettings: () => _navigate(AppView.settings),
        );
      case AppView.discover:
        return DiscoverPage(layout: layout, onOpenPlayer: _openPlayer);
      case AppView.search:
        return SearchPage(layout: layout, onOpenPlayer: _openPlayer, autofocus: true);
      case AppView.library:
        return LibraryPage(
          layout: layout,
          onOpenLocal: () => _navigate(AppView.localMusic),
          onOpenPlayer: _openPlayer,
        );
      case AppView.localMusic:
        return LocalMusicPage(layout: layout, onOpenPlayer: _openPlayer);
      case AppView.settings:
        return SettingsPage(
          layout: layout,
          darkMode: widget.darkMode,
          onThemeChanged: widget.onThemeChanged,
        );
      case AppView.player:
        return PlayerPage(
          layout: layout,
          playing: _playing,
          onTogglePlaying: () => setState(() => _playing = !_playing),
          onClose: _closePlayer,
          onQueue: () => setState(() => _queueOpen = !_queueOpen),
        );
    }
  }
}
