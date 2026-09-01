import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_artwork_placeholder.dart';
import 'package:yymusic/design_system/yy_player_data.dart';
import 'package:yymusic/design_system/yy_player_surface.dart';
import 'package:yymusic/design_system/yy_slider.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  YYNowPlayingViewData data({
    bool playing = true,
    bool favorite = true,
    bool shuffle = true,
    YYRepeatState repeat = YYRepeatState.one,
  }) => YYNowPlayingViewData(
    title: 'A Quiet Orbit',
    artist: 'Luna Harbor',
    position: const Duration(minutes: 1, seconds: 14),
    duration: const Duration(minutes: 3, seconds: 48),
    artwork: YYArtworkKind.orbit,
    playing: playing,
    favorite: favorite,
    shuffle: shuffle,
    repeat: repeat,
  );

  test('presentation data copies controlled values without owning a clock', () {
    final original = data();
    expect(original.progress, closeTo(74 / 228, .0001));
    final changed = original.copyWith(
      position: const Duration(seconds: 114),
      playing: false,
      volume: .4,
    );
    expect(changed.position, const Duration(seconds: 114));
    expect(changed.playing, isFalse);
    expect(changed.volume, .4);
    expect(original.position, const Duration(seconds: 74));
    expect(original.playing, isTrue);
    expect(original.volume, .72);
  });

  testWidgets(
    'Mini Player keeps 64/48/42 geometry and independent native actions',
    (tester) async {
      final previousStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );
      final appearance = YYAppearanceController()..setReduceMotion(true);
      addTearDown(appearance.dispose);
      final semantics = tester.ensureSemantics();
      var opened = 0;
      var playback = 0;
      var next = 0;
      Widget subject({bool loading = false}) => designHarness(
        FocusTraversalGroup(
          child: Focus(
            autofocus: true,
            child: Center(
              child: SizedBox(
                width: 366,
                child: YYMiniPlayer(
                  data: data(),
                  loading: loading,
                  onOpen: () => opened++,
                  onTogglePlayback: () => playback++,
                  onNext: () => next++,
                ),
              ),
            ),
          ),
        ),
        appearance: appearance,
        scale: 1.3,
      );
      try {
        await tester.pumpWidget(subject());
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(YYMiniPlayer)),
          const Size(366, YYPlayerMetrics.miniHeight),
        );
        final artwork = tester.widget<YYArtworkPlaceholder>(
          find.byType(YYArtworkPlaceholder),
        );
        expect(artwork.dimension, YYPlayerMetrics.miniArtwork);
        expect(artwork.role, YYArtworkRole.miniPlayer);
        expect(
          tester.getSize(
            find.byKey(const ValueKey('player-control-mini-playback')),
          ),
          const Size.square(YYPlayerMetrics.primaryControlVisual),
        );
        expect(
          tester.getSize(find.bySemanticsLabel('暂停')).shortestSide,
          greaterThanOrEqualTo(YYSpace.touchTarget),
        );

        final track = find.bySemanticsLabel('打开正在播放，A Quiet Orbit，Luna Harbor');
        final trackNode = tester.getSemantics(track);
        expect(trackNode.flagsCollection.isButton, isTrue);
        expect(
          trackNode.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isTrue,
        );

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(track));
        await tester.pump();
        expect(
          tester
              .widget<YYArtworkPlaceholder>(find.byType(YYArtworkPlaceholder))
              .hovered,
          isTrue,
        );
        final playSurface = find.byKey(
          const ValueKey('player-control-mini-playback'),
        );
        await mouse.moveTo(tester.getCenter(playSurface));
        await mouse.down(tester.getCenter(playSurface));
        await tester.pump();
        expect(
          tester
              .widget<AnimatedScale>(
                find.ancestor(
                  of: playSurface,
                  matching: find.byType(AnimatedScale),
                ),
              )
              .scale,
          .94,
        );
        await mouse.up();

        await tester.tap(track);
        await tester.tap(find.bySemanticsLabel('暂停'));
        await tester.tap(find.bySemanticsLabel('下一首'));
        expect((opened, playback, next), (1, 2, 1));

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(opened, 2);

        await tester.pumpWidget(subject(loading: true));
        await tester.tap(track);
        await tester.tap(find.bySemanticsLabel('暂停'));
        await tester.tap(find.bySemanticsLabel('下一首'));
        expect((opened, playback, next), (2, 2, 1));
        expect(
          tester.getSemantics(track).flagsCollection.isEnabled,
          ui.Tristate.isFalse,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Desktop Player keeps 88dp geometry and every tool is independent',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final appearance = YYAppearanceController()..setReduceMotion(true);
      addTearDown(appearance.dispose);
      final calls = <String>[];
      final seekPreviews = <double>[];
      final seekCommits = <double>[];
      var seekCancels = 0;
      final volumePreviews = <double>[];
      final volumeCommits = <double>[];
      await tester.pumpWidget(
        designHarness(
          Center(
            child: SizedBox(
              width: 1400,
              child: YYDesktopPlayerBar(
                data: data(),
                onOpen: () => calls.add('open'),
                onTogglePlayback: () => calls.add('playback'),
                onPrevious: () => calls.add('previous'),
                onNext: () => calls.add('next'),
                onToggleShuffle: () => calls.add('shuffle'),
                onCycleRepeat: () => calls.add('repeat'),
                onToggleFavorite: () => calls.add('favorite'),
                onOpenFullscreen: () => calls.add('fullscreen'),
                onOpenLyrics: () => calls.add('lyrics'),
                onOpenQueue: () => calls.add('queue'),
                onOpenSettings: () => calls.add('settings'),
                onSeekPreview: seekPreviews.add,
                onSeekCommit: seekCommits.add,
                onSeekCancel: () => seekCancels++,
                onVolumePreview: volumePreviews.add,
                onVolumeCommit: volumeCommits.add,
              ),
            ),
          ),
          appearance: appearance,
          scale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(YYDesktopPlayerBar)),
        const Size(1400, YYPlayerMetrics.desktopHeight),
      );
      final artwork = tester.widget<YYArtworkPlaceholder>(
        find.byType(YYArtworkPlaceholder),
      );
      expect(artwork.dimension, YYPlayerMetrics.desktopArtwork);
      expect(artwork.role, YYArtworkRole.desktopPlayer);
      expect(find.byType(YYSlider), findsNWidgets(2));
      expect(find.byKey(const ValueKey('desktop-volume')), findsOneWidget);
      expect(
        tester.getSize(
          find.byKey(const ValueKey('player-control-desktop-playback')),
        ),
        const Size.square(YYPlayerMetrics.primaryControlVisual),
      );
      expect(
        tester.getSize(find.bySemanticsLabel('上一首')).shortestSide,
        greaterThanOrEqualTo(YYSpace.touchTarget),
      );

      for (final (label, call) in [
        ('打开正在播放，A Quiet Orbit，Luna Harbor', 'open'),
        ('关闭随机播放', 'shuffle'),
        ('上一首', 'previous'),
        ('暂停', 'playback'),
        ('下一首', 'next'),
        ('单曲循环', 'repeat'),
        ('全屏播放', 'fullscreen'),
        ('打开全屏歌词', 'lyrics'),
        ('取消收藏', 'favorite'),
        ('打开队列', 'queue'),
        ('播放设置', 'settings'),
      ]) {
        await tester.tap(find.bySemanticsLabel(label));
        expect(calls.last, call);
      }
      expect(calls.length, 11);
      expect(calls.where((value) => value == 'open').length, 1);

      final progress = find.bySemanticsLabel('播放进度');
      final progressGesture = await tester.startGesture(
        tester.getCenter(progress),
      );
      await progressGesture.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(seekPreviews, isNotEmpty);
      expect(seekCommits, isEmpty);
      await progressGesture.up();
      await tester.pump();
      expect(seekCommits, hasLength(1));
      final cancelled = await tester.startGesture(tester.getCenter(progress));
      await cancelled.moveBy(const Offset(-30, 0));
      await tester.pump();
      await cancelled.cancel();
      await tester.pump();
      expect(seekCancels, 1);
      expect(seekCommits, hasLength(1));

      final volume = find.bySemanticsLabel('音量');
      final volumeBounds = tester.getRect(volume);
      await tester.tapAt(Offset(volumeBounds.left + 2, volumeBounds.center.dy));
      await tester.pump();
      expect(volumePreviews, isNotEmpty);
      expect(volumeCommits, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact and low-width Desktop Player fail closed without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(840, 300);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var activations = 0;
      for (final width in [816.0, 640.0]) {
        await tester.pumpWidget(
          designHarness(
            Center(
              child: SizedBox(
                width: width,
                child: YYDesktopPlayerBar(
                  data: data(),
                  compact: true,
                  loading: width == 816,
                  onOpen: () => activations++,
                  onTogglePlayback: () => activations++,
                  onPrevious: () => activations++,
                  onNext: () => activations++,
                  onToggleShuffle: () => activations++,
                  onCycleRepeat: () => activations++,
                  onToggleFavorite: () => activations++,
                  onOpenFullscreen: () => activations++,
                  onOpenLyrics: () => activations++,
                  onOpenQueue: () => activations++,
                ),
              ),
            ),
            scale: 1.3,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(YYDesktopPlayerBar)).height,
          YYPlayerMetrics.desktopCompactHeight,
        );
        expect(find.bySemanticsLabel('播放进度'), findsNothing);
        expect(find.byKey(const ValueKey('desktop-volume')), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.bySemanticsLabel('暂停'));
      await tester.tap(find.bySemanticsLabel('下一首'));
      expect(activations, 2);
    },
  );
}
