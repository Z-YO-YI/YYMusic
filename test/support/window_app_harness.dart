import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';

import 'close_graph.dart';
import 'fake_window_gateway.dart';
import 'playback_graph_fixture.dart';

Future<void> mountWindowApp(
  WidgetTester tester,
  PlaybackGraphFixture fixture,
  FakeWindowGateway window, {
  Size size = const Size(1440, 900),
  YYPlatform platform = YYPlatform.windows,
  String route = '/home',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dependencyGraphProvider.overrideWith((ref) {
          ref.onDispose(fixture.graph.dispose);
          return fixture.graph;
        }),
      ],
      child: RepaintBoundary(
        key: const ValueKey('window-app'),
        child: YYMusicApp(
          platform: platform,
          initialLocation: route,
          windowGateway: window,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> closeWindowApp(
  WidgetTester tester,
  PlaybackGraphFixture fixture,
  FakeWindowGateway window,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await closeGraph(tester, fixture.graph);
  await window.dispose();
  expect(window.disposalCount, 1);
}
