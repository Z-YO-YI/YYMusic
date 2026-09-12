import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_player_surface.dart';
import 'package:yymusic/design_system/yy_slider.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/player/common/player_screen.dart';
import 'package:yymusic/features/player/common/shell_player.dart';
import 'package:yymusic/features/player/phone/phone_player_layout.dart';
import 'package:yymusic/features/player/tablet/tablet_player_layout.dart';
import 'package:yymusic/features/player/windows/windows_player_layout.dart';
import 'package:yymusic/playback/audio_engine_state.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/playback_graph_fixture.dart';
import 'foundation_app_test.dart' show mount;

const playerSizes = [
  (YYPlatform.android, Size(360, 800)),
  (YYPlatform.android, Size(390, 844)),
  (YYPlatform.android, Size(430, 932)),
  (YYPlatform.android, Size(590, 360)),
  (YYPlatform.android, Size(844, 390)),
  (YYPlatform.android, Size(800, 1280)),
  (YYPlatform.android, Size(1280, 800)),
  (YYPlatform.android, Size(700, 900)),
  (YYPlatform.windows, Size(1440, 900)),
  (YYPlatform.windows, Size(1024, 720)),
  (YYPlatform.windows, Size(840, 640)),
  (YYPlatform.windows, Size(500, 640)),
];

Future<PlaybackGraphFixture> mountPlayer(
  WidgetTester tester, {
  YYPlatform platform = YYPlatform.android,
  Size size = const Size(390, 844),
  bool empty = false,
  String route = '/player',
}) async {
  final fixture = PlaybackGraphFixture();
  fixture.graph.appearance.setReduceMotion(true);
  if (!empty) {
    await fixture.queue();
    await fixture.graph.playback.play();
  }
  await mount(
    tester,
    platform: platform,
    size: size,
    scale: 1.3,
    route: route,
    graph: fixture.graph,
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await closeGraph(tester, fixture.graph);
  });
  return fixture;
}

Finder pageControl(String name) =>
    find.byKey(ValueKey('player-control-page-$name'));
YYFullPlayerContent content(WidgetTester tester) =>
    tester.widget<YYFullPlayerContent>(find.byType(YYFullPlayerContent));

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'rapid duplicate player opens produce one route and can reopen after close',
    (tester) async {
      await mountPlayer(tester, route: '/home');
      final open = tester.widget<ShellPlayer>(find.byType(ShellPlayer)).onOpen!;
      open();
      open();
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen, skipOffstage: false), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('route-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
      open();
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsOneWidget);
    },
  );

  testWidgets('paused artwork scales only when reduced motion is disabled', (
    tester,
  ) async {
    final fixture = await mountPlayer(tester);
    fixture.graph.appearance.setReduceMotion(false);
    await fixture.graph.playback.pause();
    await tester.pumpAndSettle();
    final artwork = find.byKey(const ValueKey('player-page-artwork-scale'));
    expect(tester.widget<AnimatedScale>(artwork).scale, .94);
    fixture.graph.appearance.setReduceMotion(true);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(artwork).scale, 1);
    expect(tester.widget<AnimatedScale>(artwork).duration, Duration.zero);
    await fixture.graph.playback.play();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(artwork).scale, 1);
  });
  testWidgets(
    'native progress gesture commits once and pointer cancel only clears preview',
    (tester) async {
      final fixture = await mountPlayer(tester);
      final slider = find.byKey(const ValueKey('player-page-seek'));
      await tester.ensureVisible(slider);
      final box = tester.getRect(slider);
      final gesture = await tester.startGesture(
        box.centerLeft + const Offset(20, 0),
      );
      await gesture.moveTo(box.center);
      await tester.pump();
      expect(
        fixture.engine.calls.where((call) => call.startsWith('seek:')),
        isEmpty,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        fixture.engine.calls.where((call) => call.startsWith('seek:')),
        hasLength(1),
      );
      final position = fixture.graph.playback.state.position;
      expect(position, greaterThan(Duration.zero));
      final cancel = await tester.startGesture(box.center);
      await cancel.moveTo(box.centerRight - const Offset(20, 0));
      await tester.pump();
      await cancel.cancel();
      await tester.pumpAndSettle();
      expect(
        fixture.engine.calls.where((call) => call.startsWith('seek:')),
        hasLength(1),
      );
      expect(content(tester).data.position, position);
    },
  );
  for (final (platform, size) in playerSizes) {
    testWidgets(
      'native player $platform $size at 130 percent has real controls',
      (tester) async {
        final fixture = await mountPlayer(
          tester,
          platform: platform,
          size: size,
        );
        expect(find.byType(PlayerScreen), findsOneWidget);
        expect(find.byType(ShellPlayer), findsNothing);
        if (platform == YYPlatform.windows) {
          expect(find.byType(WindowsPlayerLayout), findsOneWidget);
        } else if (size.width < 600) {
          expect(find.byType(PhonePlayerLayout), findsOneWidget);
        } else {
          expect(find.byType(TabletPlayerLayout), findsOneWidget);
        }
        await tester.ensureVisible(pageControl('playback'));
        await tester.tap(pageControl('playback'));
        await tester.pumpAndSettle();
        expect(fixture.engine.calls.last, 'pause');
        await tester.ensureVisible(pageControl('next'));
        await tester.tap(pageControl('next'));
        await tester.pumpAndSettle();
        expect(fixture.graph.playbackPresenter.entryId, 'b');
        expect(content(tester).data.title, fixture.tracks[1].title);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final (platform, size) in [
    (YYPlatform.android, const Size(390, 844)),
    (YYPlatform.windows, const Size(1024, 720)),
  ]) {
    testWidgets(
      'bottom metadata opens native player and back preserves playback on $platform',
      (tester) async {
        final fixture = await mountPlayer(
          tester,
          platform: platform,
          size: size,
          route: '/home',
        );
        final player = fixture.graph.playback;
        await tester.tap(
          find.byKey(
            ValueKey(
              platform == YYPlatform.android
                  ? 'mini-player-track'
                  : 'desktop-player-track',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PlayerScreen), findsOneWidget);
        final navigation = tester
            .widget<PlayerScreen>(find.byType(PlayerScreen))
            .navigation;
        navigation.openPlayer();
        await tester.pumpAndSettle();
        expect(find.byType(PlayerScreen, skipOffstage: false), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('route-back')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
        expect(fixture.graph.playback, same(player));
        expect(fixture.engine.calls.where((call) => call == 'stop'), isEmpty);
      },
    );
  }

  testWidgets(
    'queue opens actual root queue and returns without resetting player',
    (tester) async {
      final fixture = await mountPlayer(tester);
      final navigation = tester
          .widget<PlayerScreen>(find.byType(PlayerScreen))
          .navigation;
      final snapshot = fixture.graph.playback.state.queue;
      await tester.tap(find.byKey(const ValueKey('player-page-queue')));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsNothing);
      expect(find.text('调整播放顺序或移除歌曲'), findsOneWidget);
      navigation.back();
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(fixture.graph.playback.state.queue, same(snapshot));
    },
  );

  testWidgets(
    'seek previews locally and commits once; volume, shuffle and repeat use root',
    (tester) async {
      final fixture = await mountPlayer(tester);
      content(tester).onSeekPreview!(.5);
      await tester.pump();
      expect(content(tester).data.position, const Duration(seconds: 90));
      expect(fixture.graph.playback.state.position, Duration.zero);
      content(tester).onSeekCommit!(.5);
      await tester.pumpAndSettle();
      expect(fixture.engine.calls.where((call) => call.startsWith('seek:')), [
        'seek:90000',
      ]);
      content(tester).onVolumePreview!(.25);
      await tester.pump();
      expect(fixture.engine.volume, 1);
      content(tester).onVolumeCommit!(.25);
      await tester.pumpAndSettle();
      expect(fixture.engine.volume, .25);
      content(tester).onToggleShuffle!();
      content(tester).onCycleRepeat!();
      await tester.pumpAndSettle();
      expect(fixture.graph.playback.state.shuffleEnabled, isTrue);
      expect(content(tester).data.repeat.name, 'all');
    },
  );

  testWidgets('track changes and layout switches discard old drag callbacks', (
    tester,
  ) async {
    final fixture = await mountPlayer(tester);
    final original = content(tester).onSeekCommit!;
    content(tester).onSeekPreview!(.9);
    await fixture.graph.playback.playEntry('b');
    await tester.pumpAndSettle();
    original(.9);
    expect(
      fixture.engine.calls.where((call) => call.startsWith('seek:')),
      isEmpty,
    );
    final root = fixture.graph.playback;
    for (final size in [
      const Size(430, 844),
      const Size(590, 360),
      const Size(800, 1280),
      const Size(1024, 768),
      const Size(390, 844),
    ]) {
      final old = content(tester).onSeekCommit!;
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      old(.8);
      expect(fixture.graph.playback, same(root));
      expect(fixture.graph.playback.state.position, Duration.zero);
      expect(content(tester).data.title, fixture.tracks[1].title);
      expect(tester.takeException(), isNull);
    }
    expect(
      fixture.engine.calls.where((call) => call.startsWith('seek:')),
      isEmpty,
    );
  });

  testWidgets(
    'covered, zero-area and unmounted page callbacks cannot change playback',
    (tester) async {
      final fixture = await mountPlayer(tester);
      final navigation = tester
          .widget<PlayerScreen>(find.byType(PlayerScreen))
          .navigation;
      final old = content(tester);
      navigation.openSystemPlaylist(SystemPlaylistType.queue);
      await tester.pumpAndSettle();
      old.onNext!();
      old.onSeekCommit!(.5);
      old.onVolumeCommit!(.1);
      await tester.pumpAndSettle();
      expect(fixture.graph.playbackPresenter.entryId, 'a');
      expect(fixture.engine.volume, 1);
      navigation.back();
      await tester.pumpAndSettle();
      final beforeZero = content(tester).onSeekCommit!;
      tester.view.physicalSize = Size.zero;
      await tester.pump();
      beforeZero(.5);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      final beforeClose = content(tester).onSeekCommit!;
      navigation.back();
      await tester.pumpAndSettle();
      beforeClose(.6);
      await tester.pumpAndSettle();
      expect(
        fixture.engine.calls.where((call) => call.startsWith('seek:')),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('queued seek is revoked on route exit before engine execution', (
    tester,
  ) async {
    final fixture = await mountPlayer(tester);
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    fixture.engine.pauseGate = gate.future;
    final blocking = fixture.graph.playback.pause();
    await tester.pump();
    final navigation = tester
        .widget<PlayerScreen>(find.byType(PlayerScreen))
        .navigation;
    content(tester).onSeekCommit!(.5);
    navigation.back();
    await tester.pump();
    gate.complete();
    await blocking;
    await tester.pumpAndSettle();
    expect(
      fixture.engine.calls.where((call) => call.startsWith('seek:')),
      isEmpty,
    );
  });

  testWidgets(
    'buffering or unknown duration disables seek and errors are safe',
    (tester) async {
      final fixture = await mountPlayer(tester);
      fixture.engine.events.add(
        AudioEngineState(
          phase: AudioEnginePhase.buffering,
          duration: const Duration(minutes: 3),
        ),
      );
      await tester.pump();
      expect(content(tester).onSeekCommit, isNull);
      fixture.engine.events.add(
        AudioEngineState(phase: AudioEnginePhase.playing),
      );
      await tester.pump();
      expect(content(tester).onSeekCommit, isNull);
      expect(find.text('时长未知'), findsOneWidget);
      fixture.engine.loadError = StateError('private-marker');
      content(tester).onNext!();
      await tester.pumpAndSettle();
      expect(find.text('播放暂不可用'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      expect(content(tester).onSeekCommit, isNull);
      fixture.engine.loadError = null;
      content(tester).onTogglePlayback!();
      await tester.pumpAndSettle();
      expect(content(tester).errorMessage, isNull);
    },
  );

  testWidgets(
    'empty direct entry has no fake controls and system back falls home',
    (tester) async {
      final fixture = await mountPlayer(tester, empty: true);
      expect(find.text('队列为空，请返回音乐库选择曲目。'), findsOneWidget);
      expect(find.byType(YYSlider), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
      expect(fixture.engine.calls, isEmpty);
    },
  );

  testWidgets(
    'Windows Space on focused control does not also invoke global playback',
    (tester) async {
      final fixture = await mountPlayer(
        tester,
        platform: YYPlatform.windows,
        size: const Size(1024, 720),
      );
      await tester.ensureVisible(pageControl('next'));
      // Resolve the live Focus node rather than an optional constructor input.
      Focus.of(tester.element(pageControl('next'))).requestFocus();
      await tester.pump();
      final before = fixture.engine.calls.length;
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(fixture.graph.playbackPresenter.entryId, 'b');
      expect(fixture.engine.calls.skip(before), ['stop', 'load', 'play']);
    },
  );
}
