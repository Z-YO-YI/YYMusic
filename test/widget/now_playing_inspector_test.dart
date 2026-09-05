import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_player_surface.dart';
import 'package:yymusic/design_system/yy_slider.dart';
import 'package:yymusic/features/player/common/shell_player.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/playback_graph_fixture.dart';
import 'foundation_app_test.dart' show mount;

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size) in [
    (YYPlatform.windows, const Size(1440, 900)),
    (YYPlatform.android, const Size(1200, 800)),
  ]) {
    testWidgets('$platform inspector and bottom bar converge on one player', (
      tester,
    ) async {
      final fixture = PlaybackGraphFixture();
      await fixture.queue();
      await mount(
        tester,
        platform: platform,
        size: size,
        graph: fixture.graph,
        scale: 1.3,
      );
      YYNowPlayingInspector panel() =>
          tester.widget(find.byType(YYNowPlayingInspector));
      YYDesktopPlayerBar bar() =>
          tester.widget(find.byType(YYDesktopPlayerBar));
      expect(panel().queueCount, 2);
      expect(panel().data.playing, isFalse);
      await tester.tap(
        find.byKey(const ValueKey('player-control-inspector-playback')),
      );
      await tester.pumpAndSettle();
      expect(fixture.engine.calls, ['load', 'play']);
      expect(panel().data.playing, isTrue);
      expect(bar().data.playing, isTrue);
      expect(panel().sourceLabel, '在线音乐源');
      await tester.tap(
        find.byKey(const ValueKey('player-control-desktop-playback')),
      );
      await tester.pumpAndSettle();
      expect(panel().statusLabel, '已暂停');
      await tester.tap(
        find.byKey(const ValueKey('player-control-inspector-next')),
      );
      await tester.pumpAndSettle();
      expect(panel().data.title, fixture.tracks.last.title);
      expect(bar().data.title, panel().data.title);
      panel().onToggleShuffle!();
      panel().onCycleRepeat!();
      await tester.pump();
      expect(bar().data.shuffle, isTrue);
      expect(bar().data.repeat, panel().data.repeat);
      final progress = tester
          .widgetList<YYSlider>(find.byType(YYSlider))
          .singleWhere((s) => s.label == '详情播放进度');
      progress.onChanged!(.5);
      await tester.pump();
      expect(panel().data.position, const Duration(seconds: 90));
      expect(bar().data.position, Duration.zero);
      progress.onChangeEnd!(.5);
      await tester.pumpAndSettle();
      expect(bar().data.position, const Duration(seconds: 90));
      expect(panel().data.position, bar().data.position);
      final before = List<String>.of(fixture.engine.calls);
      tester.view.physicalSize = platform == YYPlatform.windows
          ? const Size(1024, 720)
          : const Size(599, 800);
      await tester.pumpAndSettle();
      expect(find.byType(YYNowPlayingInspector), findsNothing);
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(panel().data.position, const Duration(seconds: 90));
      expect(fixture.engine.calls, before);
      expect(fixture.engine.disposalCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await closeGraph(tester, fixture.graph);
    });
  }

  testWidgets('inspector handles loading, safe failure and shared retry', (
    tester,
  ) async {
    final fixture = PlaybackGraphFixture();
    await mount(
      tester,
      platform: YYPlatform.windows,
      size: const Size(1440, 900),
      graph: fixture.graph,
    );
    YYNowPlayingInspector panel() =>
        tester.widget(find.byType(YYNowPlayingInspector));
    expect(panel().queueCount, 0);
    expect(panel().onTogglePlayback, isNull);
    await fixture.queue();
    final gate = Completer<void>();
    fixture.engine.loadGate = gate.future;
    fixture.engine.loadError = StateError('private-inspector-marker');
    final pending = fixture.graph.playbackPresenter.togglePlayback();
    await tester.pump();
    expect(panel().loading, isTrue);
    expect(panel().onTogglePlayback, isNull);
    expect(
      tester
          .widget<YYDesktopPlayerBar>(find.byType(YYDesktopPlayerBar))
          .onTogglePlayback,
      isNull,
    );
    gate.complete();
    await pending;
    await tester.pumpAndSettle();
    expect(panel().statusLabel, '播放失败');
    expect(panel().errorMessage, isNotNull);
    expect(find.textContaining('private-inspector-marker'), findsNothing);
    fixture.engine.loadError = null;
    panel().onTogglePlayback!();
    await tester.pumpAndSettle();
    expect(panel().errorMessage, isNull);
    expect(fixture.engine.calls, ['load', 'load', 'play']);
    await tester.pumpWidget(const SizedBox.shrink());
    await closeGraph(tester, fixture.graph);
  });

  testWidgets(
    'same-entry reload invalidates an in-progress Inspector preview',
    (tester) async {
      final fixture = PlaybackGraphFixture();
      await fixture.queue();
      await fixture.graph.playbackPresenter.togglePlayback();
      await mount(
        tester,
        platform: YYPlatform.windows,
        size: const Size(1440, 900),
        graph: fixture.graph,
      );
      YYNowPlayingInspector panel() =>
          tester.widget(find.byType(YYNowPlayingInspector));
      panel().onSeekPreview!(.8);
      await tester.pump();
      expect(panel().data.progress, .8);
      final gate = Completer<void>();
      fixture.engine.loadGate = gate.future;
      final reloading = fixture.graph.playback.playEntry('a');
      await tester.pumpAndSettle();
      expect(panel().loading, isTrue);
      expect(panel().onSeekCommit, isNull);
      gate.complete();
      await reloading;
      await tester.pumpAndSettle();
      expect(panel().data.progress, 0);
      expect(
        fixture.engine.calls.where((call) => call.startsWith('seek:')),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await closeGraph(tester, fixture.graph);
    },
  );

  testWidgets('260dp inspector scrolls independently in a short viewport', (
    tester,
  ) async {
    final fixture = PlaybackGraphFixture();
    await fixture.queue();
    await fixture.graph.playbackPresenter.togglePlayback();
    tester.view.physicalSize = const Size(260, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      designHarness(
        ShellPlayer(
          presenter: fixture.graph.playbackPresenter,
          inspector: true,
        ),
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(find.text('播放队列 · 2 首').hitTestable(), findsOneWidget);
    expect(fixture.engine.calls, ['load', 'play']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await closeGraph(tester, fixture.graph);
  });
}
