import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';

import 'close_graph.dart';
import 'fake_fullscreen_gateway.dart';
import 'fake_window_gateway.dart';
import 'lyrics_fixture.dart';
import 'native_lyrics_harness.dart';

Future<LyricsFixture> mountFullscreenApp(
  WidgetTester tester, {
  required FakeFullscreenGateway fullscreen,
  FakeWindowGateway? window,
  YYPlatform platform = YYPlatform.windows,
  Size size = const Size(1440, 900),
  String route = '/player',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  late LyricsFixture fixture;
  await tester.runAsync(() async {
    fixture = LyricsFixture();
    fixture.graph.appearance.setReduceMotion(true);
    await fixture.initialize();
    await fixture.graph.playback.seek(const Duration(seconds: 15));
    await fixture.graph.playback.play();
  });
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await settleLyrics(tester);
    await closeGraph(tester, fixture.graph);
    // Native fakes were created in the binding zone; drain it during teardown.
    var released = false;
    final release = Future.wait<void>([
      fullscreen.close(),
      if (window != null) window.dispose(),
    ]).then((_) => released = true);
    for (var i = 0; i < 12 && !released; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(Duration.zero);
    }
    expect(
      released,
      isTrue,
      reason: 'Native resources must actually finish closing',
    );
    await release;
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dependencyGraphProvider.overrideWith((ref) {
          ref.onDispose(fixture.graph.dispose);
          return fixture.graph;
        }),
      ],
      child: RepaintBoundary(
        key: const ValueKey('fullscreen-app'),
        child: YYMusicApp(
          platform: platform,
          initialLocation: route,
          fullscreenGateway: fullscreen,
          windowGateway: window,
        ),
      ),
    ),
  );
  await settleLyrics(tester);
  return fixture;
}
