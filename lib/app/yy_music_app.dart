import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'app_routes.dart';
import 'dependency_graph.dart';
import 'layout_class.dart';

class YYMusicApp extends ConsumerStatefulWidget {
  const YYMusicApp({super.key, this.platform, this.initialLocation = '/home'});
  final YYPlatform? platform;
  final String initialLocation;

  @override
  ConsumerState<YYMusicApp> createState() => _YYMusicAppState();
}

class _YYMusicAppState extends ConsumerState<YYMusicApp> {
  AppRouter? _router;

  @override
  void initState() {
    super.initState();
    final platform =
        widget.platform ??
        (kIsWeb ? null : YYPlatform.fromTarget(defaultTargetPlatform));
    if (platform != null) {
      _router = AppRouter(
        platform: platform,
        viewState: ref.read(dependencyGraphProvider).viewState,
        initialLocation: widget.initialLocation,
      );
    }
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
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
      textStyle: const TextStyle(
        color: Color(0xFF111214),
        fontSize: 14,
        height: 1.4,
      ),
      routerConfig: router.config,
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFF5F5F2),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
                router.back,
            const SingleActivator(LogicalKeyboardKey.escape): router.back,
            const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
                router.goTo(AppRoute.search),
            const SingleActivator(LogicalKeyboardKey.keyL, control: true): () =>
                router.goTo(AppRoute.library),
            const SingleActivator(
              LogicalKeyboardKey.comma,
              control: true,
            ): () =>
                router.goTo(AppRoute.settings),
          },
          child: Focus(
            autofocus: true,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
