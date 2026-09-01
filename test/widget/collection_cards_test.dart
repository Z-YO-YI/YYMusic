import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_icon.dart';
import 'package:yymusic/design_system/yy_playlist_card.dart';
import 'package:yymusic/design_system/yy_source_card.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/features/design_gallery/gallery_collection_cards.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  testWidgets('Source Card keeps final geometry, status tone and semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var actions = 0;
    try {
      await tester.pumpWidget(
        designHarness(
          Center(
            child: SizedBox(
              width: 380,
              child: YYSourceCard(
                name: '用户 API Fixture',
                meta: '未发送连接请求',
                glyph: YYGlyph.cloud,
                statusLabel: '异常',
                statusTone: YYSourceStatusTone.error,
                selected: true,
                onPressed: () => actions++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(YYSourceCard)),
        const Size(380, YYCollectionCardMetrics.sourceMinHeight),
      );
      final surface = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('yy-source-card-surface')),
      );
      final surfaceDecoration = surface.decoration! as BoxDecoration;
      expect(
        surfaceDecoration.borderRadius,
        BorderRadius.circular(YYRadius.sourceCard),
      );
      expect(
        surface.padding,
        const EdgeInsets.all(YYCollectionCardMetrics.sourcePadding),
      );
      final icon = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('yy-source-card-icon')),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('yy-source-card-icon'))),
        const Size.square(YYCollectionCardMetrics.sourceIcon),
      );
      expect(
        (icon.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(YYRadius.sourceIcon),
      );
      final dot = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('yy-source-status-dot')),
      );
      expect((dot.decoration as BoxDecoration).color, YYPalette.error);
      expect(
        tester.getSize(find.byKey(const ValueKey('yy-source-status-dot'))),
        const Size.square(YYCollectionCardMetrics.sourceStatusDot),
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel('用户 API Fixture，未发送连接请求，异常'),
      );
      expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isFalse);
      await tester.tap(find.byType(YYSourceCard));
      expect(actions, 1);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Source Card supports pointer, keyboard, disabled and loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy = previousStrategy,
    );
    final focus = FocusNode(debugLabel: 'source-card-focus');
    addTearDown(focus.dispose);
    final appearance = YYAppearanceController()..setReduceMotion(true);
    addTearDown(appearance.dispose);
    var actions = 0;

    Widget subject({VoidCallback? onPressed, bool loading = false}) =>
        designHarness(
          Center(
            child: SizedBox(
              width: 300,
              child: YYSourceCard(
                name: '很长的来源名称 Fixture Source',
                meta: '很长的来源说明但不包含真实 URL 或设备目录',
                glyph: YYGlyph.folder,
                statusLabel: loading ? '测试中' : '可用',
                statusTone: loading
                    ? YYSourceStatusTone.warning
                    : YYSourceStatusTone.positive,
                onPressed: onPressed,
                loading: loading,
                focusNode: focus,
              ),
            ),
          ),
          appearance: appearance,
          scale: 1.3,
        );

    await tester.pumpWidget(subject(onPressed: () => actions++));
    await tester.pumpAndSettle();
    final card = find.byType(YYSourceCard);
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(card));
    await tester.pump();
    BoxDecoration surfaceDecoration() =>
        tester
                .widget<AnimatedContainer>(
                  find.byKey(const ValueKey('yy-source-card-surface')),
                )
                .decoration!
            as BoxDecoration;
    expect(
      surfaceDecoration().color,
      appearance.resolve(Brightness.light).colors.pressed,
    );
    await mouse.down(tester.getCenter(card));
    await tester.pump();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      .995,
    );
    await mouse.up();
    focus.requestFocus();
    await tester.pump();
    expect(
      (surfaceDecoration().border! as Border).top.color,
      appearance.resolve(Brightness.light).colors.text,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(actions, 3);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(subject());
    await tester.tap(card);
    expect(actions, 3);
    expect(
      tester
          .getSemantics(
            find.bySemanticsLabel(
              '很长的来源名称 Fixture Source，很长的来源说明但不包含真实 URL 或设备目录，可用',
            ),
          )
          .flagsCollection
          .isEnabled,
      ui.Tristate.isFalse,
    );

    await tester.pumpWidget(subject(onPressed: () => actions++, loading: true));
    expect(find.text('正在加载来源'), findsOneWidget);
    final loading = tester.getSemantics(
      find.bySemanticsLabel(
        '很长的来源名称 Fixture Source，很长的来源说明但不包含真实 URL 或设备目录，测试中',
      ),
    );
    expect(loading.flagsCollection.isEnabled, ui.Tristate.isFalse);
    expect(loading.value, '加载中');
    await tester.tap(card);
    expect(actions, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Playlist Card keeps final desktop geometry and interactions', (
    tester,
  ) async {
    final focus = FocusNode(debugLabel: 'playlist-card-focus');
    addTearDown(focus.dispose);
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy = previousStrategy,
    );
    final appearance = YYAppearanceController()..setReduceMotion(true);
    addTearDown(appearance.dispose);
    final semantics = tester.ensureSemantics();
    var actions = 0;
    try {
      await tester.pumpWidget(
        designHarness(
          Center(
            child: SizedBox(
              width: 210,
              child: YYPlaylistCard(
                title: '喜欢的音乐',
                meta: '0 首 · Fixture',
                glyph: YYGlyph.heart,
                selected: true,
                focusNode: focus,
                onPressed: () => actions++,
              ),
            ),
          ),
          appearance: appearance,
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byType(YYPlaylistCard);
      expect(tester.getSize(card).width, 210);
      final surface = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('yy-playlist-card-surface')),
      );
      expect(surface.padding, const EdgeInsets.all(16));
      final decoration = surface.decoration! as BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.circular(YYRadius.playlistCard),
      );
      expect(decoration.boxShadow, isNotEmpty);
      final icon = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('yy-playlist-card-icon')),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('yy-playlist-card-icon'))),
        const Size.square(44),
      );
      expect(
        (icon.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(YYRadius.playlistIcon),
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel('喜欢的音乐，0 首 · Fixture'),
      );
      expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isFalse);

      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(card));
      await tester.pump();
      expect(
        tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset.dy,
        lessThan(0),
      );
      await mouse.down(tester.getCenter(card));
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        .98,
      );
      await mouse.up();
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(actions, 3);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'Playlist create, disabled and loading adapt to 130 percent phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var actions = 0;
      await tester.pumpWidget(
        designHarness(
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  child: YYPlaylistCard(
                    title: '新建歌单',
                    meta: '仅通知 Fixture',
                    glyph: YYGlyph.plus,
                    variant: YYPlaylistCardVariant.create,
                    onPressed: () => actions++,
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 160,
                  child: YYPlaylistCard(
                    title: '加载歌单',
                    meta: '不创建任务',
                    glyph: YYGlyph.playlist,
                    loading: true,
                    onPressed: _noop,
                  ),
                ),
              ],
            ),
          ),
          scale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      final surfaces = find.byKey(const ValueKey('yy-playlist-card-surface'));
      final createSurface = tester.widget<AnimatedContainer>(surfaces.first);
      expect(createSurface.padding, const EdgeInsets.all(13));
      final createDecoration = createSurface.decoration! as BoxDecoration;
      expect(createDecoration.color, const Color(0x00000000));
      expect(createDecoration.border, isNull);
      expect(createDecoration.boxShadow, isNull);
      final createBorder = tester.widget<CustomPaint>(
        find.byKey(const ValueKey('yy-playlist-card-border')).first,
      );
      expect(createBorder.foregroundPainter, isNotNull);
      final icons = find.byKey(const ValueKey('yy-playlist-card-icon'));
      expect((tester.getSize(icons.first)), const Size.square(40));
      await tester.tap(find.bySemanticsLabel('新建歌单，仅通知 Fixture'));
      expect(actions, 1);

      expect(find.text('正在加载歌单'), findsOneWidget);
      final loading = tester.getSemantics(find.bySemanticsLabel('加载歌单，不创建任务'));
      expect(loading.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(loading.value, '加载中');
      await tester.tap(find.bySemanticsLabel('加载歌单，不创建任务'));
      expect(actions, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Collection Gallery reflows and only updates local fixture text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget subject() => designHarness(
        const SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: GalleryCollectionCards(),
          ),
        ),
        scale: 1.3,
      );

      tester.view.physicalSize = const Size(390, 1400);
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();
      final firstSource = find.byKey(const ValueKey('fixture-source-0'));
      final secondSource = find.byKey(const ValueKey('fixture-source-1'));
      expect(
        tester.getTopLeft(secondSource).dy,
        greaterThan(tester.getTopLeft(firstSource).dy),
      );
      await tester.ensureVisible(secondSource);
      await tester.tap(secondSource);
      await tester.pump();
      expect(find.textContaining('用户 API Fixture（未连接）'), findsOneWidget);
      final create = find.byKey(const ValueKey('fixture-playlist-create'));
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pump();
      expect(find.text('Fixture：收到新建歌单请求（未保存）'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(1280, 900);
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(secondSource).dx,
        greaterThan(tester.getTopLeft(firstSource).dx),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

void _noop() {}
