import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/design_system/yy_window_toolbar.dart';
import 'package:yymusic/design_system/yy_windows_sidebar.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/shared/foundation_button.dart';
import 'package:yymusic/shells/android_phone_shell.dart';
import 'package:yymusic/shells/android_tablet_shell.dart';
import 'package:yymusic/shells/windows_shell.dart';

import '../support/fake_audio_engine.dart';

Future<void> mount(
  WidgetTester tester, {
  required YYPlatform platform,
  required Size size,
  DependencyGraph? graph,
  String route = '/home',
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (graph != null)
          dependencyGraphProvider.overrideWith((ref) {
            ref.onDispose(graph.dispose);
            return graph;
          }),
      ],
      child: YYMusicApp(platform: platform, initialLocation: route),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Windows stays Windows below Android phone width', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await mount(
        tester,
        platform: YYPlatform.windows,
        size: const Size(1440, 900),
      );
      expect(
        tester.widget<WindowsShell>(find.byType(WindowsShell)).layout,
        YYLayoutClass.windowsExpanded,
      );
      expect(find.byType(YYWindowsSidebar), findsOneWidget);
      expect(find.byType(YYWindowToolbar), findsOneWidget);
      expect(tester.getSize(find.byType(YYWindowsSidebar)).width, 240);
      expect(find.text('Inspector 结构预留 · Phase 5'), findsOneWidget);
      expect(find.bySemanticsLabel('最小化'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('windows-nav-library')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-library')), findsOneWidget);
      for (final (width, layout) in [
        (1024.0, YYLayoutClass.windowsStandard),
        (840.0, YYLayoutClass.windowsNarrow),
        (599.0, YYLayoutClass.windowsNarrow),
      ]) {
        tester.view.physicalSize = Size(width, 720);
        await tester.pumpAndSettle();
        expect(
          tester.widget<WindowsShell>(find.byType(WindowsShell)).layout,
          layout,
        );
        expect(find.byType(AndroidPhoneShell), findsNothing);
        expect(
          tester.getSize(find.byType(YYWindowsSidebar)).width,
          layout == YYLayoutClass.windowsNarrow ? 72 : 240,
        );
        expect(
          find.text('Inspector 结构预留 · Phase 5'),
          layout == YYLayoutClass.windowsExpanded
              ? findsOneWidget
              : findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'Android resizing and routes preserve one graph, playback and selection',
    (tester) async {
      final engine = FakeAudioEngine();
      final graph = DependencyGraph(audioEngine: engine);
      await mount(
        tester,
        platform: YYPlatform.android,
        size: const Size(390, 844),
        graph: graph,
      );
      final playback = graph.playback;
      final queue = graph.queue;
      engine.events.add(
        AudioEngineState(
          phase: AudioEnginePhase.paused,
          position: Duration(seconds: 42),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('nav-library')));
      await tester.pumpAndSettle();
      graph.viewState.select(AppRoute.library, 'selection-for-test');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-library')), findsOneWidget);
      expect(find.byType(AndroidPhoneShell), findsOneWidget);
      for (final size in [
        const Size(600, 900),
        const Size(1280, 800),
        const Size(844, 390),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('screen-library')), findsOneWidget);
        expect(find.byType(WindowsShell), findsNothing);
        expect(
          size.width < 600
              ? find.byType(AndroidPhoneShell)
              : find.byType(AndroidTabletShell),
          findsOneWidget,
        );
        expect(graph.playback, same(playback));
        expect(graph.queue, same(queue));
        expect(graph.playback.state.position, const Duration(seconds: 42));
        expect(
          graph.viewState.selection(AppRoute.library),
          'selection-for-test',
        );
        expect(engine.disposalCount, 0);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(engine.disposalCount, 1);
    },
  );

  testWidgets('player and lyrics have independent stack return targets', (
    tester,
  ) async {
    await mount(
      tester,
      platform: YYPlatform.android,
      size: const Size(430, 932),
    );
    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-player')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-player')), findsOneWidget);
    expect(find.byType(AndroidPhoneShell), findsNothing);
    await tester.tap(find.byKey(const ValueKey('open-lyrics')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-lyrics')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('route-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-player')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-library')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-lyrics')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-library')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct lyrics entry has deterministic home fallback', (
    tester,
  ) async {
    await mount(
      tester,
      platform: YYPlatform.windows,
      size: const Size(1024, 720),
      route: '/lyrics',
    );
    expect(find.byKey(const ValueKey('screen-lyrics')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('route-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
  });

  testWidgets(
    'actual scroll offset survives route and phone to tablet changes',
    (tester) async {
      final graph = DependencyGraph();
      await mount(
        tester,
        platform: YYPlatform.android,
        size: const Size(390, 500),
        graph: graph,
      );
      final home = find.byKey(const ValueKey('screen-home'));
      await tester.drag(home, const Offset(0, -60));
      await tester.pumpAndSettle();
      final offset = graph.viewState.scrollOffset(AppRoute.home);
      expect(offset, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('nav-search')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      final restored = tester.state<ScrollableState>(
        find.descendant(of: home, matching: find.byType(Scrollable)),
      );
      expect(restored.position.pixels, closeTo(offset, 1));
      tester.view.physicalSize = const Size(600, 500);
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: home, matching: find.byType(Scrollable)),
      );
      // Wider text reflows to fewer lines. Preserve the offset within the new
      // valid extent, rather than requiring an out-of-range scroll position.
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      expect(
        scrollable.position.pixels,
        closeTo(offset.clamp(0, scrollable.position.maxScrollExtent), 1),
      );
      expect(find.byType(AndroidTabletShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unknown location recovers without showing untrusted path', (
    tester,
  ) async {
    await mount(
      tester,
      platform: YYPlatform.android,
      size: const Size(390, 844),
      route: '/unknown?secret=test-only',
    );
    expect(find.text('页面不存在'), findsOneWidget);
    expect(find.textContaining('test-only'), findsNothing);
    await tester.tap(find.text('返回首页'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
  });

  testWidgets('360dp at 130 percent text has usable semantic controls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await mount(
        tester,
        platform: YYPlatform.android,
        size: const Size(360, 800),
        scale: 1.3,
      );
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('音乐库'), findsOneWidget);
      for (final element in find.byType(FoundationButton).evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
      await tester.tap(find.byKey(const ValueKey('nav-search')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-search')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
