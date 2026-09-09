import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/yy_feedback.dart';
import '../design_system/yy_theme.dart';
import '../design_system/yy_tokens.dart';
import '../platform/contracts/fullscreen_gateway.dart';
import '../platform/contracts/window_gateway.dart';
import '../platform/fullscreen/native_fullscreen_gateway.dart';
import '../platform/windows/windows_window_gateway.dart';
import 'app_router.dart';
import 'app_routes.dart';
import 'dependency_graph.dart';
import 'fullscreen_presenter.dart';
import 'fullscreen_route_observer.dart';
import 'layout_class.dart';
import 'window_chrome.dart';
import 'window_presenter.dart';

class YYMusicApp extends ConsumerStatefulWidget {
  const YYMusicApp({
    super.key,
    this.platform,
    this.initialLocation = '/home',
    this.windowGateway,
    this.fullscreenGateway,
  });
  final YYPlatform? platform;
  final String initialLocation;
  final WindowGateway? windowGateway;
  final FullscreenGateway? fullscreenGateway;

  @override
  ConsumerState<YYMusicApp> createState() => _YYMusicAppState();
}

class _YYMusicAppState extends ConsumerState<YYMusicApp>
    with WidgetsBindingObserver {
  AppRouter? _router;
  WindowPresenter? _window;
  FullscreenPresenter? _fullscreen;
  FlutterView? _view;
  bool _tickersEnabled = true;

  @override
  void initState() {
    super.initState();
    final platform =
        widget.platform ??
        (kIsWeb ? null : YYPlatform.fromTarget(defaultTargetPlatform));
    if (platform != null) {
      final graph = ref.read(dependencyGraphProvider);
      _fullscreen = FullscreenPresenter(
        widget.fullscreenGateway ??
            graph.fullscreen ??
            NativeFullscreenGateway(),
        automatic: platform == YYPlatform.android,
      );
      WidgetsBinding.instance.addObserver(this);
      _fullscreen!.setForeground(
        WidgetsBinding.instance.lifecycleState == null ||
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      );
      unawaited(_fullscreen!.initialize());
      if (platform == YYPlatform.windows) {
        _window = WindowPresenter(
          widget.windowGateway ?? WindowsWindowGateway(),
          beforeClose: () async {
            try {
              await _fullscreen!.close();
            } finally {
              await graph.close();
            }
          },
        );
        unawaited(_window!.initialize());
      }
      _router = AppRouter(
        platform: platform,
        fullscreen: _fullscreen,
        fullscreenObserver: FullscreenRouteObserver(_fullscreen!),
        viewState: ref.read(dependencyGraphProvider).viewState,
        licenses: ref.read(dependencyGraphProvider).licenses,
        playbackPresenter: ref.read(dependencyGraphProvider).playbackPresenter,
        lyricsController: ref.read(dependencyGraphProvider).lyricsController,
        homeController: ref.read(dependencyGraphProvider).home,
        searchController: ref.read(dependencyGraphProvider).search,
        libraryController: ref.read(dependencyGraphProvider).libraryController,
        catalogDetails: ref.read(dependencyGraphProvider).catalogDetails,
        playlistController: ref.read(dependencyGraphProvider).playlists,
        playlistContents: ref.read(dependencyGraphProvider).playlistContents,
        playlistAdds: ref.read(dependencyGraphProvider).playlistAdds,
        systemPlaylists: ref.read(dependencyGraphProvider).systemPlaylists,
        appearanceSettings: ref
            .read(dependencyGraphProvider)
            .appearanceSettings,
        audioBackendSelected: ref
            .read(dependencyGraphProvider)
            .playback
            .isAvailable,
        initialLocation: widget.initialLocation,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _view = View.maybeOf(context);
    _tickersEnabled = TickerMode.valuesOf(context).enabled;
    didChangeMetrics();
  }

  @override
  void didChangeMetrics() {
    final size = _view?.physicalSize;
    _fullscreen?.setVisible(_tickersEnabled && (size == null || !size.isEmpty));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _fullscreen?.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fullscreen?.dispose();
    _window?.dispose();
    _router?.dispose();
    super.dispose();
  }

  bool get _typing {
    final focused = FocusManager.instance.primaryFocus?.context;
    return focused?.widget is EditableText ||
        focused?.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _fullscreenFromKeyboard() {
    if (_typing) return;
    final fullscreen = _fullscreen;
    if (fullscreen == null) return;
    if (fullscreen.eligible) {
      fullscreen.toggle();
    } else if (fullscreen.canOpenPlayer) {
      fullscreen.enterOnNextPlayer();
      _router?.openPlayer();
    }
  }

  void _escapeFromKeyboard() {
    if ((widget.platform ?? YYPlatform.fromTarget(defaultTargetPlatform)) ==
            YYPlatform.windows &&
        (_fullscreen?.exitBeforeBack ?? false)) {
      _fullscreen!.restore();
    } else {
      _router?.back();
    }
  }

  Widget _nativeFrame(Widget child) => ListenableBuilder(
    listenable: _fullscreen!,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          if (_fullscreen!.errorMessage case final message?)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight / 3),
              child: SingleChildScrollView(
                child: SafeArea(
                  bottom: false,
                  child: YYErrorBanner(
                    title: '全屏操作未完成',
                    message: message,
                    actionLabel: _fullscreen!.available ? '恢复系统显示' : null,
                    onAction: _fullscreen!.available && !_fullscreen!.busy
                        ? _fullscreen!.restore
                        : null,
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          Expanded(
            child: _window == null
                ? child
                : WindowFrame(
                    presenter: _window!,
                    hideChrome: _fullscreen!.hideChrome,
                    child: child,
                  ),
          ),
        ],
      ),
    ),
  );

  void _toggleFromKeyboard() {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused?.widget is EditableText ||
        focused?.findAncestorWidgetOfExactType<EditableText>() != null) {
      return;
    }
    unawaited(
      ref.read(dependencyGraphProvider).playbackPresenter.togglePlayback(),
    );
  }

  void _lyricsFromKeyboard() {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused?.widget is EditableText ||
        focused?.findAncestorWidgetOfExactType<EditableText>() != null) {
      return;
    }
    _router?.openLyrics();
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    if (router == null) {
      return const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Text('YYMusic 当前仅支持 Windows 与 Android')),
      );
    }
    return WidgetsApp.router(
      title: 'YYMusic',
      color: const Color(0xFFF5F5F2),
      debugShowCheckedModeBanner: false,
      textStyle: YYTypography.text(color: const Color(0xFF111214)),
      routerConfig: router.config,
      builder: (context, child) {
        final appearance = ref.watch(dependencyGraphProvider).appearance;
        return ListenableBuilder(
          listenable: appearance,
          builder: (context, _) {
            final theme = appearance.resolve(
              MediaQuery.platformBrightnessOf(context),
              systemReduceMotion: MediaQuery.disableAnimationsOf(context),
            );
            return YYAppearanceScope(
              controller: appearance,
              child: YYTheme(
                data: theme,
                child: DefaultTextStyle(
                  style: YYTypography.text(color: theme.colors.text),
                  child: ColoredBox(
                    color: theme.colors.base,
                    child: CallbackShortcuts(
                      bindings: {
                        if ((widget.platform ??
                                YYPlatform.fromTarget(defaultTargetPlatform)) ==
                            YYPlatform.windows)
                          const SingleActivator(
                            LogicalKeyboardKey.keyF,
                            includeRepeats: false,
                          ): _fullscreenFromKeyboard,
                        if ((widget.platform ??
                                YYPlatform.fromTarget(defaultTargetPlatform)) ==
                            YYPlatform.windows)
                          const SingleActivator(
                            LogicalKeyboardKey.space,
                            includeRepeats: false,
                          ): _toggleFromKeyboard,
                        if ((widget.platform ??
                                YYPlatform.fromTarget(defaultTargetPlatform)) ==
                            YYPlatform.windows)
                          const SingleActivator(
                            LogicalKeyboardKey.keyL,
                            includeRepeats: false,
                          ): _lyricsFromKeyboard,
                        const SingleActivator(
                          LogicalKeyboardKey.arrowLeft,
                          alt: true,
                        ): router.back,
                        const SingleActivator(LogicalKeyboardKey.escape):
                            _escapeFromKeyboard,
                        const SingleActivator(
                          LogicalKeyboardKey.keyK,
                          control: true,
                        ): () {
                          router.goTo(AppRoute.search);
                          ref
                              .read(dependencyGraphProvider)
                              .search
                              .requestFocus();
                        },
                        const SingleActivator(
                          LogicalKeyboardKey.keyL,
                          control: true,
                        ): () =>
                            router.goTo(AppRoute.library),
                        const SingleActivator(
                          LogicalKeyboardKey.comma,
                          control: true,
                        ): () =>
                            router.goTo(AppRoute.settings),
                      },
                      child: Focus(
                        autofocus: true,
                        child: _nativeFrame(child ?? const SizedBox.shrink()),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
