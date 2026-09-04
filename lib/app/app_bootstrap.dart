import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_data_services.dart';
import 'database_app_data_services.dart';
import 'dependency_graph.dart';
import 'layout_class.dart';
import 'yy_music_app.dart';

typedef AppDataServicesFactory = Future<AppDataServices> Function(
  YYPlatform platform,
);

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({
    super.key,
    this.platform,
    this.dataServicesFactory = createProductionAppDataServices,
  });

  final YYPlatform? platform;
  final AppDataServicesFactory dataServicesFactory;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  YYPlatform? _platform;
  DependencyGraph? _graph;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _platform =
        widget.platform ??
        (kIsWeb ? null : YYPlatform.fromTarget(defaultTargetPlatform));
    final platform = _platform;
    if (platform == null) {
      _graph = DependencyGraph();
    } else {
      unawaited(_initialize(platform));
    }
  }

  Future<void> _initialize(YYPlatform platform) async {
    try {
      final services = await widget.dataServicesFactory(platform);
      if (!mounted) {
        await services.dispose();
        return;
      }
      final graph = DependencyGraph(dataServices: services);
      await graph.initialize();
      if (!mounted) {
        graph.dispose();
        return;
      }
      setState(() => _graph = graph);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _graph?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const _BootstrapStatus(message: 'YYMusic 无法初始化本地数据');
    }
    final graph = _graph;
    if (graph == null) {
      return const _BootstrapStatus(message: 'YYMusic 正在准备本地数据');
    }
    return ProviderScope(
      overrides: [dependencyGraphProvider.overrideWithValue(graph)],
      child: YYMusicApp(platform: _platform),
    );
  }
}

class _BootstrapStatus extends StatelessWidget {
  const _BootstrapStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: const Color(0xFFF5F5F2),
      child: Center(
        child: Semantics(
          liveRegion: true,
          label: message,
          child: Text(
            message,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Color(0xFF111214),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}
