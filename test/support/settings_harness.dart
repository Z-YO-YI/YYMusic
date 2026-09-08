import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';

import 'close_graph.dart';
import 'fake_window_gateway.dart';

Future<void> pumpSettings(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(Duration.zero);
  }
  await tester.pumpAndSettle();
}

Future<void> mountSettings(
  WidgetTester tester,
  DependencyGraph graph, {
  Size size = const Size(390, 844),
  YYPlatform platform = YYPlatform.android,
  double scale = 1.3,
  bool initialize = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (initialize) {
    final starting = graph.initialize();
    await pumpSettings(tester);
    await starting;
  }
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('settings-golden'),
      child: ProviderScope(
        overrides: [dependencyGraphProvider.overrideWithValue(graph)],
        child: YYMusicApp(
          platform: platform,
          initialLocation: '/settings',
          windowGateway: platform == YYPlatform.windows
              ? FakeWindowGateway()
              : null,
        ),
      ),
    ),
  );
  await pumpSettings(tester);
}

Future<void> unmountSettings(WidgetTester tester, DependencyGraph graph) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await closeGraph(tester, graph);
}
