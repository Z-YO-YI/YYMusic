import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/yy_theme.dart';
import '../design_system/yy_tokens.dart';
import '../platform/contracts/window_gateway.dart';
import '../platform/windows/windows_window_gateway.dart';
import 'app_router.dart';
import 'app_routes.dart';
import 'dependency_graph.dart';
import 'layout_class.dart';
import 'window_chrome.dart';
import 'window_presenter.dart';

class YYMusicApp extends ConsumerStatefulWidget {
  const YYMusicApp({
    super.key,
    this.platform,
    this.initialLocation = '/home',
    this.windowGateway,
  });
  final YYPlatform? platform;
  final String initialLocation;
  final WindowGateway? windowGateway;

  @override
  ConsumerState<YYMusicApp> createState() => _YYMusicAppState();
}

class _YYMusicAppState extends ConsumerState<YYMusicApp> {
  AppRouter? _router;
  WindowPresenter? _window;

  @override
  void initState() {
    super.initState();
    final platform =
        widget.platform ??
        (kIsWeb ? null : YYPlatform.fromTarget(defaultTargetPlatform));
    if (platform != null) {
      if (platform == YYPlatform.windows) {
        _window = WindowPresenter(
          widget.windowGateway ?? WindowsWindowGateway(),
          beforeClose: ref.read(dependencyGraphProvider).close,
        );
        unawaited(_window!.initialize());
      }
      _router = AppRouter(
        platform: platform,
        viewState: ref.read(dependencyGraphProvider).viewState,
        licenses: ref.read(dependencyGraphProvider).licenses,
        playbackPresenter: ref.read(dependencyGraphProvider).playbackPresenter,
        audioBackendSelected: ref
            .read(dependencyGraphProvider)
            .playback
            .isAvailable,
        initialLocation: widget.initialLocation,
      );
    }
  }

  @override
  void dispose() {
    _window?.dispose();
    _router?.dispose();
    super.dispose();
  }

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
                            LogicalKeyboardKey.space,
                            includeRepeats: false,
                          ): _toggleFromKeyboard,
                        const SingleActivator(
                          LogicalKeyboardKey.arrowLeft,
                          alt: true,
                        ): router.back,
                        const SingleActivator(LogicalKeyboardKey.escape):
                            router.back,
                        const SingleActivator(
                          LogicalKeyboardKey.keyK,
                          control: true,
                        ): () =>
                            router.goTo(AppRoute.search),
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
                        child: _window == null
                            ? child ?? const SizedBox.shrink()
                            : WindowFrame(
                                presenter: _window!,
                                child: child ?? const SizedBox.shrink(),
                              ),
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
