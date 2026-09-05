import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_player_surface.dart';
import 'package:yymusic/design_system/yy_slider.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/features/player/common/shell_player.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/playback_graph_fixture.dart';
import 'foundation_app_test.dart' show mount;

Finder control(String id) => find.byKey(ValueKey('player-control-$id'));

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size, phone) in [
    (YYPlatform.android, const Size(390, 844), true),
    (YYPlatform.android, const Size(844, 390), false),
    (YYPlatform.android, const Size(1024, 768), false),
    (YYPlatform.windows, const Size(1440, 900), false),
  ]) {
    testWidgets(
      'real $platform shell $size uses one shared player at 130 percent',
      (tester) async {
        final fixture = PlaybackGraphFixture();
        await fixture.queue();
        await mount(
          tester,
          platform: platform,
          size: size,
          graph: fixture.graph,
          scale: 1.3,
        );
        expect(find.byType(ShellPlayer), findsOneWidget);
        final prefix = phone ? 'mini' : 'desktop';
        await tester.tap(control('$prefix-playback'));
        await tester.pumpAndSettle();
        expect(fixture.engine.calls, ['load', 'play']);
        expect(find.text(fixture.tracks.first.title), findsOneWidget);
        final metadata = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label ==
                    '正在播放，${fixture.tracks.first.title}，${fixture.tracks.first.artists.single}',
          ),
        );
        expect(metadata.properties.button, isNot(true));
        expect(metadata.properties.onTap, isNull);
        await tester.tap(control('$prefix-playback'));
        await tester.pumpAndSettle();
        expect(fixture.engine.calls.last, 'pause');
        await tester.tap(control('$prefix-next'));
        await tester.pumpAndSettle();
        expect(fixture.graph.playbackPresenter.entryId, 'b');
        final before = fixture.engine.calls.length;
        if (!phone) {
          final bar = tester.widget<YYDesktopPlayerBar>(
            find.byType(YYDesktopPlayerBar),
          );
          expect(bar.onToggleFavorite, isNull);
          expect(bar.onOpenQueue, isNull);
          expect(bar.onOpenFullscreen, isNull);
        }
        expect(fixture.engine.calls.length, before);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await closeGraph(tester, fixture.graph);
        expect(fixture.engine.disposalCount, 1);
      },
    );
  }

  testWidgets('empty, error and retry are real states without private detail', (
    tester,
  ) async {
    final fixture = PlaybackGraphFixture();
    await mount(
      tester,
      platform: YYPlatform.android,
      size: const Size(390, 844),
      graph: fixture.graph,
    );
    expect(
      tester.widget<YYMiniPlayer>(find.byType(YYMiniPlayer)).onTogglePlayback,
      isNull,
    );
    await fixture.queue();
    await tester.pumpAndSettle();
    fixture.engine.loadError = StateError('private-file-marker');
    await tester.tap(control('mini-playback'));
    await tester.pumpAndSettle();
    expect(find.text('播放暂不可用'), findsOneWidget);
    expect(find.textContaining('private-file-marker'), findsNothing);
    fixture.engine.loadError = null;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('播放暂不可用'), findsNothing);
    expect(fixture.engine.calls, ['load', 'load', 'play']);
    await tester.pumpWidget(const SizedBox.shrink());
    await closeGraph(tester, fixture.graph);
  });

  testWidgets(
    'slider preview does not seek, cancel resets and old entry cannot commit',
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
      YYSlider slider(String label) => tester
          .widgetList<YYSlider>(find.byType(YYSlider))
          .singleWhere((s) => s.label == label);
      final original = slider('播放进度');
      original.onChanged!(.5);
      await tester.pump();
      expect(fixture.engine.calls.where((c) => c.startsWith('seek:')), isEmpty);
      original.onChangeCancel!();
      await tester.pump();
      expect(slider('播放进度').value, 0);
      slider('播放进度').onChanged!(.5);
      slider('播放进度').onChangeEnd!(.5);
      await tester.pumpAndSettle();
      expect(fixture.engine.calls.last, 'seek:90000');
      final oldBar = tester.widget<YYDesktopPlayerBar>(
        find.byType(YYDesktopPlayerBar),
      );
      await fixture.graph.playbackPresenter.next();
      await tester.pumpAndSettle();
      // The presenter must also reject a stale captured callback identity.
      await fixture.graph.playbackPresenter.seek(.8, expectedEntryId: 'a');
      expect(fixture.engine.calls.where((c) => c.startsWith('seek:')), [
        'seek:90000',
      ]);
      expect(oldBar.data.title, fixture.tracks.first.title);
      final volume = slider('音量');
      volume.onChanged!(.3);
      expect(fixture.engine.volume, 1);
      volume.onChangeEnd!(.3);
      await tester.pumpAndSettle();
      expect(fixture.engine.volume, .3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await closeGraph(tester, fixture.graph);
    },
  );

  testWidgets('Windows Space toggles once and does not intercept an editor', (
    tester,
  ) async {
    final fixture = PlaybackGraphFixture();
    await fixture.queue();
    await mount(
      tester,
      platform: YYPlatform.windows,
      size: const Size(1440, 900),
      graph: fixture.graph,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(fixture.engine.calls, ['load', 'play']);
    await tester.tap(find.byKey(const ValueKey('windows-nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开源许可'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EditableText));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(fixture.engine.calls, ['load', 'play']);
    await tester.pumpWidget(const SizedBox.shrink());
    await closeGraph(tester, fixture.graph);
  });

  testWidgets('active drag cancels on entry change and Windows layout resize', (
    tester,
  ) async {
    final fixture = PlaybackGraphFixture();
    await fixture.queue();
    await fixture.graph.playbackPresenter.togglePlayback();
    await mount(
      tester,
      platform: YYPlatform.windows,
      size: const Size(1440, 900),
      graph: fixture.graph,
      scale: 1.3,
    );
    final progress = find.byWidgetPredicate(
      (widget) => widget is YYSlider && widget.label == '播放进度',
    );
    Future<TestGesture> drag() async {
      final gesture = await tester.startGesture(tester.getCenter(progress));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      return gesture;
    }

    final cancelled = await drag();
    await cancelled.cancel();
    await tester.pump();
    expect(tester.widget<YYSlider>(progress).value, 0);
    final oldEntryDrag = await drag();
    await fixture.graph.playbackPresenter.next();
    await tester.pumpAndSettle();
    await oldEntryDrag.up();
    await tester.pump();
    expect(fixture.graph.playbackPresenter.entryId, 'b');
    expect(fixture.graph.playbackPresenter.data.playing, isTrue);
    final beforeResize = List<String>.of(fixture.engine.calls);
    final resizeDrag = await drag();
    tester.view.physicalSize = const Size(840, 640);
    await tester.pumpAndSettle();
    await resizeDrag.up();
    await tester.pump();
    expect(progress, findsNothing);
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    expect(tester.widget<YYSlider>(progress).value, 0);
    expect(fixture.engine.calls, beforeResize);
    expect(
      fixture.engine.calls.where((call) => call.startsWith('seek:')),
      isEmpty,
    );
    expect(fixture.engine.disposalCount, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await closeGraph(tester, fixture.graph);
  });

  testWidgets('phone/tablet split view preserves playback without reloading', (
    tester,
  ) async {
    final fixture = PlaybackGraphFixture();
    await fixture.queue();
    await fixture.graph.playbackPresenter.togglePlayback();
    await mount(
      tester,
      platform: YYPlatform.android,
      size: const Size(390, 844),
      graph: fixture.graph,
      scale: 1.3,
    );
    for (final size in [
      const Size(1024, 768),
      const Size(844, 390),
      const Size(599, 900),
      const Size(390, 844),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(fixture.graph.playbackPresenter.entryId, 'a');
      expect(fixture.graph.playbackPresenter.data.playing, isTrue);
      expect(fixture.engine.calls, ['load', 'play']);
      expect(fixture.engine.disposalCount, 0);
      expect(find.byType(ShellPlayer), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await closeGraph(tester, fixture.graph);
  });

  test(
    'player primary shadow matches the App.tsx override, not button accent',
    () {
      final shadow = YYShadows.playerControl.single;
      expect(shadow.color, const Color(0x290F1214));
      expect(shadow.offset, const Offset(0, 8));
      expect(shadow.blurRadius, 22);
    },
  );
}
