import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_album_card.dart';
import 'package:yymusic/design_system/yy_artwork_placeholder.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/design_system/yy_track_tile.dart';
import 'package:yymusic/features/design_gallery/gallery_content_cards.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  testWidgets(
    'album card keeps audited geometry and supports pointer, keyboard and semantics',
    (tester) async {
      final focus = FocusNode();
      final appearance = YYAppearanceController()..setReduceMotion(true);
      addTearDown(focus.dispose);
      addTearDown(appearance.dispose);
      final semantics = tester.ensureSemantics();
      var activations = 0;
      try {
        Widget subject({VoidCallback? onPressed, bool loading = false}) =>
            designHarness(
              Center(
                child: SizedBox(
                  width: 160,
                  child: YYAlbumCard(
                    title: 'A Quiet Orbit',
                    subtitle: 'Luna Harbor · EP',
                    artwork: YYArtworkKind.orbit,
                    selected: true,
                    loading: loading,
                    focusNode: focus,
                    onPressed: onPressed,
                  ),
                ),
              ),
              appearance: appearance,
            );
        await tester.pumpWidget(subject(onPressed: () => activations++));
        await tester.pumpAndSettle();
        final card = find.byType(YYAlbumCard);
        expect(tester.getSize(card).width, 160);
        expect(
          tester
              .widget<YYArtworkPlaceholder>(find.byType(YYArtworkPlaceholder))
              .role,
          YYArtworkRole.album,
        );
        final node = tester.getSemantics(
          find.bySemanticsLabel('A Quiet Orbit，Luna Harbor · EP'),
        );
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
        expect(
          node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isTrue,
        );

        await tester.tap(card);
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(activations, 3);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(card));
        await tester.pump();
        expect(
          tester
              .widget<YYArtworkPlaceholder>(find.byType(YYArtworkPlaceholder))
              .hovered,
          isTrue,
        );
        await mouse.down(tester.getCenter(card));
        await tester.pump();
        expect(
          tester
              .widget<AnimatedScale>(
                find.byKey(const ValueKey('yy-album-card-art-motion')),
              )
              .scale,
          .98,
        );
        await mouse.up();
        focus.requestFocus();
        await tester.pump();
        final focusedDecoration =
            tester
                    .widget<AnimatedContainer>(
                      find.byKey(const ValueKey('yy-album-card-surface')),
                    )
                    .decoration!
                as BoxDecoration;
        expect(
          (focusedDecoration.border! as Border).top.color,
          const YYPalette(Brightness.light).text,
        );

        await tester.pumpWidget(subject());
        await tester.tap(card);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(activations, 4);
        final disabled = tester.getSemantics(
          find.bySemanticsLabel('A Quiet Orbit，Luna Harbor · EP'),
        );
        expect(disabled.flagsCollection.isEnabled, ui.Tristate.isFalse);
        expect(
          disabled.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isFalse,
        );

        await tester.pumpWidget(
          subject(onPressed: () => activations++, loading: true),
        );
        expect(find.text('正在加载'), findsOneWidget);
        await tester.tap(card);
        expect(activations, 4);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('track primary and more actions remain independent', (
    tester,
  ) async {
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy = previousStrategy,
    );
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final focus = FocusNode();
    final appearance = YYAppearanceController()..setReduceMotion(true);
    addTearDown(focus.dispose);
    addTearDown(appearance.dispose);
    final semantics = tester.ensureSemantics();
    var primary = 0;
    var more = 0;
    try {
      await tester.pumpWidget(
        designHarness(
          Center(
            child: SizedBox(
              width: 620,
              child: YYTrackTile(
                title: 'A Quiet Orbit',
                subtitle: 'Luna Harbor · The Small Hours',
                sourceLabel: 'Cloud API',
                durationLabel: '3:48',
                artwork: YYArtworkKind.orbit,
                playing: true,
                focusNode: focus,
                onPressed: () => primary++,
                onMore: () => more++,
              ),
            ),
          ),
          appearance: appearance,
        ),
      );
      await tester.pumpAndSettle();
      final main = find.bySemanticsLabel(
        'A Quiet Orbit，Luna Harbor · The Small Hours，Cloud API，3:48',
      );
      final overflow = find.bySemanticsLabel('A Quiet Orbit 的更多操作');
      final node = tester.getSemantics(main);
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(node.getSemanticsData().value, '正在播放');
      expect(find.text('3:48'), findsOneWidget);

      await tester.tap(main);
      expect((primary, more), (1, 0));
      await tester.tap(overflow);
      expect((primary, more), (1, 1));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(main));
      await tester.pump();
      BoxDecoration surfaceDecoration() =>
          tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('yy-track-tile-surface')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(
        surfaceDecoration().color,
        Color.alphaBlend(
          appearance.accent.soft,
          const YYPalette(Brightness.light).elevated,
        ),
      );
      await mouse.down(tester.getCenter(main));
      await tester.pump();
      expect(
        tester
            .widget<AnimatedScale>(
              find.ancestor(
                of: find.byKey(const ValueKey('yy-track-tile-surface')),
                matching: find.byType(AnimatedScale),
              ),
            )
            .scale,
        .995,
      );
      await mouse.up();
      focus.requestFocus();
      await tester.pump();
      expect(
        (surfaceDecoration().border! as Border).top.color,
        const YYPalette(Brightness.light).text,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect((primary, more), (4, 1));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'track phone layout hides duration, survives 130 percent and disables both actions',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final appearance = YYAppearanceController()
        ..setMode(YYThemeMode.dark)
        ..setCustomAccent('#FFFFFF')
        ..setReduceMotion(true);
      addTearDown(appearance.dispose);
      var primary = 0;
      var more = 0;
      await tester.pumpWidget(
        designHarness(
          const SizedBox(
            width: 350,
            child: YYTrackTile(
              title: '很长的曲目标题用于窄屏省略验证 A Quiet Orbit',
              subtitle: 'Luna Harbor · The Small Hours',
              sourceLabel: 'Cloud API Very Long Source',
              durationLabel: '3:48',
              artwork: YYArtworkKind.orbit,
              onPressed: null,
              onMore: null,
            ),
          ),
          appearance: appearance,
          scale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3:48'), findsNothing);
      expect(find.text('Cloud API Very Long Source'), findsOneWidget);
      expect(
        tester.getSize(find.text('Cloud API Very Long Source')).width,
        lessThanOrEqualTo(58),
      );
      expect(
        tester.getSize(find.byType(YYTrackTile)).height,
        greaterThanOrEqualTo(58),
      );
      await tester.tap(find.byType(YYTrackTile));
      expect((primary, more), (0, 0));
      await tester.pumpWidget(
        designHarness(
          SizedBox(
            width: 350,
            child: YYTrackTile(
              title: '加载曲目',
              subtitle: '加载状态示例',
              sourceLabel: 'REST',
              durationLabel: '2:56',
              artwork: YYArtworkKind.noon,
              loading: true,
              onPressed: () => primary++,
              onMore: () => more++,
            ),
          ),
          appearance: appearance,
          scale: 1.3,
        ),
      );
      await tester.pump();
      expect(find.text('正在加载曲目'), findsOneWidget);
      final loadingNode = tester.getSemantics(
        find.bySemanticsLabel('加载曲目，加载状态示例，REST，2:56'),
      );
      expect(loadingNode.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(loadingNode.getSemanticsData().value, '加载中');
      expect(
        loadingNode.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        isFalse,
      );
      await tester.tap(find.byType(YYTrackTile));
      await tester.tap(find.bySemanticsLabel('加载曲目 的更多操作'));
      expect((primary, more), (0, 0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('gallery fixtures update labels without starting playback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      designHarness(
        const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: GalleryContentCards(),
        ),
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('正在加载曲目'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fixture-album-0')));
    await tester.pump();
    expect(find.text('已选择专辑组件：A Quiet Orbit'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Slow Lines 的更多操作'));
    await tester.pump();
    expect(find.text('Slow Lines：更多操作尚未接入弹层'), findsOneWidget);
    expect(find.textContaining('正在播放'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
