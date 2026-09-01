import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_artwork_placeholder.dart';
import 'package:yymusic/design_system/yy_lyrics_line.dart';
import 'package:yymusic/design_system/yy_lyrics_player_dock.dart';
import 'package:yymusic/design_system/yy_player_data.dart';
import 'package:yymusic/design_system/yy_queue_tile.dart';
import 'package:yymusic/design_system/yy_slider.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/features/design_gallery/gallery_queue_lyrics_primitives.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  YYNowPlayingViewData data({bool playing = true, bool favorite = true}) =>
      YYNowPlayingViewData(
        title: 'A Quiet Orbit',
        artist: 'Luna Harbor · Fixture',
        position: const Duration(minutes: 1, seconds: 14),
        duration: const Duration(minutes: 3, seconds: 48),
        artwork: YYArtworkKind.orbit,
        playing: playing,
        favorite: favorite,
      );

  testWidgets('Queue Tile keeps final geometry and independent actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final focus = FocusNode(debugLabel: 'queue-main');
    addTearDown(focus.dispose);
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy = previousStrategy,
    );
    final calls = <String>[];
    try {
      await tester.pumpWidget(
        designHarness(
          Center(
            child: SizedBox(
              width: 700,
              child: YYQueueTile(
                title: 'A Quiet Orbit',
                meta: 'Luna Harbor · Fixture',
                durationLabel: '3:48',
                artwork: YYArtworkKind.orbit,
                current: true,
                focusNode: focus,
                onPressed: () => calls.add('open'),
                onMoveUp: () => calls.add('up'),
                onMoveDown: () => calls.add('down'),
                onRemove: () => calls.add('remove'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tile = find.byType(YYQueueTile);
      expect(tester.getSize(tile).width, 700);
      expect(
        tester.getSize(tile).height,
        greaterThanOrEqualTo(YYQueueLyricsMetrics.queueMinHeight),
      );
      final surface = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('yy-queue-tile-surface')),
      );
      expect(
        surface.padding,
        const EdgeInsets.all(YYQueueLyricsMetrics.queuePadding),
      );
      expect(
        (surface.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(12),
      );
      final artwork = tester.widget<YYArtworkPlaceholder>(
        find.byType(YYArtworkPlaceholder),
      );
      expect(artwork.dimension, YYQueueLyricsMetrics.queueArtwork);
      expect(artwork.role, YYArtworkRole.queue);
      expect(artwork.role.radius, YYRadius.queueArtwork);
      expect(
        tester.getSize(find.byKey(const ValueKey('queue-action-up'))),
        const Size.square(YYQueueLyricsMetrics.queueActionVisual),
      );
      expect(
        tester.getSize(find.bySemanticsLabel('A Quiet Orbit：上移')).shortestSide,
        greaterThanOrEqualTo(YYSpace.touchTarget),
      );
      final main = find.bySemanticsLabel(
        'A Quiet Orbit，Luna Harbor · Fixture，3:48',
      );
      final node = tester.getSemantics(main);
      expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isFalse);
      expect(node.value, '当前队列项');
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('yy-queue-actions')),
            )
            .opacity,
        0,
      );

      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(tile));
      await tester.pump();
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('yy-queue-actions')),
            )
            .opacity,
        1,
      );
      await tester.tap(main);
      await tester.tap(find.bySemanticsLabel('A Quiet Orbit：上移'));
      await tester.tap(find.bySemanticsLabel('A Quiet Orbit：下移'));
      await tester.tap(find.bySemanticsLabel('A Quiet Orbit：移除'));
      expect(calls, ['open', 'up', 'down', 'remove']);

      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls.last, 'open');
      expect(calls.where((value) => value == 'open'), hasLength(2));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Queue immersive, phone, disabled and loading fail closed', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var calls = 0;

    Widget subject({bool loading = false, bool enabled = true}) =>
        designHarness(
          Center(
            child: SizedBox(
              width: 360,
              child: YYQueueTile(
                title: '很长的队列标题 Fixture',
                meta: '很长的艺人与来源说明',
                durationLabel: '12:34',
                artwork: YYArtworkKind.tide,
                density: YYQueueTileDensity.immersive,
                loading: loading,
                onPressed: enabled ? () => calls++ : null,
                onMoveUp: () => calls++,
                onMoveDown: () => calls++,
                onRemove: () => calls++,
              ),
            ),
          ),
          scale: 1.3,
        );

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final artwork = tester.widget<YYArtworkPlaceholder>(
      find.byType(YYArtworkPlaceholder),
    );
    expect(artwork.dimension, YYQueueLyricsMetrics.queueImmersiveArtwork);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('yy-queue-actions')),
          )
          .opacity,
      1,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(subject(loading: true));
    await tester.pumpAndSettle();
    expect(find.text('正在加载队列项'), findsOneWidget);
    final loadingNode = tester.getSemantics(
      find.bySemanticsLabel('很长的队列标题 Fixture，很长的艺人与来源说明，12:34'),
    );
    expect(loadingNode.flagsCollection.isEnabled, ui.Tristate.isFalse);
    expect(loadingNode.value, '加载中');
    await tester.tap(find.bySemanticsLabel('很长的队列标题 Fixture：移除'));
    expect(calls, 0);

    await tester.pumpWidget(subject(enabled: false));
    await tester.tap(find.bySemanticsLabel('很长的队列标题 Fixture，很长的艺人与来源说明，12:34'));
    await tester.tap(find.bySemanticsLabel('很长的队列标题 Fixture：下移'));
    expect(calls, 0);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'Lyrics Line keeps active state, typography and request semantics',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final appearance = YYAppearanceController()
        ..setReduceMotion(true)
        ..setReduceGlass(true);
      addTearDown(appearance.dispose);
      final focus = FocusNode(debugLabel: 'lyrics-line');
      addTearDown(focus.dispose);
      final semantics = tester.ensureSemantics();
      var calls = 0;
      try {
        await tester.pumpWidget(
          designHarness(
            const ColoredBox(
              color: Color(0xFF3D4A52),
              child: SizedBox.expand(),
            ),
            appearance: appearance,
          ),
        );
        await tester.pumpWidget(
          designHarness(
            ColoredBox(
              color: const Color(0xFF3D4A52),
              child: Center(
                child: SizedBox(
                  width: 350,
                  child: YYLyricsLine(
                    text: 'Every small sound becomes clear',
                    translation: '每个细小的声音都逐渐清晰',
                    state: YYLyricsLineState.active,
                    focusNode: focus,
                    onPressed: () => calls++,
                  ),
                ),
              ),
            ),
            appearance: appearance,
            scale: 1.3,
          ),
        );
        await tester.pumpAndSettle();
        final dot = find.byKey(const ValueKey('lyrics-active-dot'));
        expect(
          tester.getSize(dot),
          const Size.square(YYQueueLyricsMetrics.phoneLyricsActiveDot),
        );
        final dotDecoration =
            tester.widget<Container>(dot).decoration! as BoxDecoration;
        expect(
          dotDecoration.boxShadow!.single.spreadRadius,
          YYQueueLyricsMetrics.lyricsActiveRing,
        );
        final textStyle = tester
            .widget<AnimatedDefaultTextStyle>(
              find.byType(AnimatedDefaultTextStyle),
            )
            .style;
        expect(textStyle.fontSize, closeTo(390 * .098, .001));
        expect(textStyle.fontVariations!.single.value, 780);
        expect(textStyle.letterSpacing, -1.9);
        expect(textStyle.color, const Color(0xFFFFFFFF));
        expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
          Duration.zero,
        );
        final line = find.bySemanticsLabel(
          '当前歌词，Every small sound becomes clear，每个细小的声音都逐渐清晰',
        );
        expect(
          tester.getSemantics(line).flagsCollection.isSelected,
          ui.Tristate.isTrue,
        );
        await tester.tap(line);
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(calls, 2);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('Lyrics Line future/loading states never invent seek work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var calls = 0;

    Widget subject({bool loading = false, bool enabled = true}) =>
        designHarness(
          ColoredBox(
            color: const Color(0xFF315247),
            child: Center(
              child: SizedBox(
                width: 900,
                child: YYLyricsLine(
                  text: 'We follow the rhythm together',
                  translation: '我们一起跟随这段节奏',
                  state: YYLyricsLineState.future,
                  loading: loading,
                  onPressed: enabled ? () => calls++ : null,
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final style = tester
        .widget<AnimatedDefaultTextStyle>(find.byType(AnimatedDefaultTextStyle))
        .style;
    expect(style.fontSize, 64);
    expect(style.color, const Color(0x3DFFFFFF));
    expect(find.byKey(const ValueKey('lyrics-active-dot')), findsNothing);

    await tester.pumpWidget(subject(loading: true));
    await tester.pumpAndSettle();
    expect(find.text('歌词加载中'), findsOneWidget);
    final node = tester.getSemantics(
      find.bySemanticsLabel('We follow the rhythm together，我们一起跟随这段节奏'),
    );
    expect(node.flagsCollection.isEnabled, ui.Tristate.isFalse);
    expect(node.value, '加载中');
    await tester.tap(
      find.bySemanticsLabel('We follow the rhythm together，我们一起跟随这段节奏'),
    );
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lyrics Dock keeps desktop geometry and controlled actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <String>[];
    final previews = <double>[];
    final commits = <double>[];
    var cancels = 0;

    await tester.pumpWidget(
      designHarness(
        ColoredBox(
          color: const Color(0xFF3D4A52),
          child: Center(
            child: SizedBox(
              width: 1120,
              child: YYLyricsPlayerDock(
                data: data(),
                atmosphereColor: const Color(0xFF3D4A52),
                onPrevious: () => calls.add('previous'),
                onTogglePlayback: () => calls.add('playback'),
                onNext: () => calls.add('next'),
                onSeekPreview: previews.add,
                onSeekCommit: commits.add,
                onSeekCancel: () => cancels++,
                onToggleFavorite: () => calls.add('favorite'),
                onReturnToPlayer: () => calls.add('return'),
              ),
            ),
          ),
        ),
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('yy-lyrics-dock-surface')),
    );
    expect(
      (surface.decoration as BoxDecoration).borderRadius,
      BorderRadius.circular(YYRadius.lyricsDock),
    );
    final artwork = tester.widget<YYArtworkPlaceholder>(
      find.byType(YYArtworkPlaceholder),
    );
    expect(artwork.dimension, YYQueueLyricsMetrics.lyricsDockArtwork);
    expect(artwork.role, YYArtworkRole.lyricsDock);
    expect(artwork.radius, YYRadius.lyricsDockArtwork);
    expect(
      tester.getSize(find.byKey(const ValueKey('lyrics-dock-pause'))),
      const Size.square(YYQueueLyricsMetrics.lyricsDockPrimaryControl),
    );
    final slider = tester.widget<YYSlider>(find.byType(YYSlider));
    expect(slider.appearance, YYSliderAppearance.lyrics);
    expect(
      tester.getSize(find.byKey(const ValueKey('slider-track'))).height,
      YYSliderMetrics.lyricsTrackHeight,
    );

    for (final (label, expected) in [
      ('上一首', 'previous'),
      ('暂停', 'playback'),
      ('下一首', 'next'),
      ('取消收藏', 'favorite'),
      ('返回播放界面', 'return'),
    ]) {
      await tester.tap(find.bySemanticsLabel(label));
      expect(calls.last, expected);
    }
    expect(calls, ['previous', 'playback', 'next', 'favorite', 'return']);

    final progress = find.bySemanticsLabel('歌词播放进度');
    final gesture = await tester.startGesture(tester.getCenter(progress));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(previews, isNotEmpty);
    expect(commits, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(commits, hasLength(1));
    final cancelled = await tester.startGesture(tester.getCenter(progress));
    await cancelled.moveBy(const Offset(-30, 0));
    await tester.pump();
    await cancelled.cancel();
    await tester.pump();
    expect(cancels, 1);
    expect(commits, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lyrics Dock phone reflows, hides favorite and fails closed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final appearance = YYAppearanceController()
      ..setReduceGlass(true)
      ..setReduceMotion(true);
    addTearDown(appearance.dispose);
    var calls = 0;

    await tester.pumpWidget(
      designHarness(
        ColoredBox(
          color: const Color(0xFF245064),
          child: Center(
            child: SizedBox(
              width: 366,
              child: YYLyricsPlayerDock(
                data: data(),
                atmosphereColor: const Color(0xFF245064),
                loading: true,
                onPrevious: () => calls++,
                onTogglePlayback: () => calls++,
                onNext: () => calls++,
                onSeekPreview: (_) => calls++,
                onSeekCommit: (_) => calls++,
                onToggleFavorite: () => calls++,
                onReturnToPlayer: () => calls++,
              ),
            ),
          ),
        ),
        appearance: appearance,
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    final artwork = tester.widget<YYArtworkPlaceholder>(
      find.byType(YYArtworkPlaceholder),
    );
    expect(artwork.dimension, YYQueueLyricsMetrics.phoneLyricsDockArtwork);
    expect(artwork.radius, 11);
    expect(find.bySemanticsLabel('取消收藏'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('lyrics-dock-pause'))),
      const Size.square(YYQueueLyricsMetrics.phoneLyricsDockPrimaryControl),
    );
    expect(
      (tester
                  .widget<DecoratedBox>(
                    find.byKey(const ValueKey('yy-lyrics-dock-surface')),
                  )
                  .decoration
              as BoxDecoration)
          .color!
          .a,
      1,
    );
    for (final label in ['上一首', '暂停', '下一首', '返回播放界面']) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.flagsCollection.isEnabled, ui.Tristate.isFalse);
      await tester.tap(find.bySemanticsLabel(label));
    }
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('歌词播放进度'))
          .flagsCollection
          .isEnabled,
      ui.Tristate.isFalse,
    );
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Queue/Lyrics Gallery only updates local fixture labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      designHarness(
        const SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: GalleryQueueLyricsPrimitives(),
          ),
        ),
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.bySemanticsLabel('Slow Lines，Mira Coast · Fixture，4:12'),
    );
    await tester.pump();
    expect(find.textContaining('选择队列项 2'), findsOneWidget);
    final line = find.bySemanticsLabel(
      'We follow the rhythm together，我们一起跟随这段节奏',
    );
    await tester.ensureVisible(line);
    await tester.tap(line);
    await tester.pump();
    expect(find.textContaining('请求跳转歌词 3'), findsOneWidget);
    await tester.ensureVisible(find.bySemanticsLabel('返回播放界面'));
    await tester.tap(find.bySemanticsLabel('返回播放界面'));
    await tester.pump();
    expect(find.textContaining('未导航'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
