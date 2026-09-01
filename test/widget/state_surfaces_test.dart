import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_feedback.dart';
import 'package:yymusic/design_system/yy_icon.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_theme_swatch.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/features/design_gallery/gallery_state_surfaces.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  testWidgets('Theme Swatch keeps 30px visual inside a 44px selected action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        designHarness(
          const Center(
            child: YYThemeSwatch(
              label: '白色主题色',
              color: Color(0xFFFFFFFF),
              selected: true,
              onPressed: _noop,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final action = find.byType(YYThemeSwatch);
      expect(tester.getSize(action), const Size.square(YYSpace.touchTarget));
      expect(
        tester.getSize(find.byKey(const ValueKey('theme-swatch-白色主题色'))),
        const Size.square(YYFeedbackMetrics.themeSwatchVisual),
      );
      final node = tester.getSemantics(action);
      expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      final selection = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('theme-swatch-selection')),
      );
      final border = (selection.decoration as BoxDecoration).border! as Border;
      expect(border.top.color, const Color(0xFF000000));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'Theme Swatch handles mouse, keyboard, disabled and loading states',
    (tester) async {
      final focus = FocusNode(debugLabel: 'swatch-focus');
      addTearDown(focus.dispose);
      final previousStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );
      final semantics = tester.ensureSemantics();
      var activations = 0;
      try {
        await tester.pumpWidget(
          designHarness(
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  YYThemeSwatch(
                    label: '珊瑚红',
                    color: const Color(0xFFFF3B5C),
                    selected: false,
                    onPressed: () => activations++,
                    focusNode: focus,
                  ),
                  const YYThemeSwatch(
                    label: '禁用主题色',
                    color: Color(0xFF2C6BED),
                    selected: false,
                    onPressed: null,
                  ),
                  YYThemeSwatch(
                    label: '加载主题色',
                    color: const Color(0xFF00A67E),
                    selected: false,
                    loading: true,
                    onPressed: () => activations++,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final active = find.byType(YYThemeSwatch).first;
        final motion = find.descendant(
          of: active,
          matching: find.byType(AnimatedScale),
        );
        final mouse = await tester.createGesture(
          kind: ui.PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(active));
        await tester.pumpAndSettle();
        expect(tester.widget<AnimatedScale>(motion).scale, 1.06);
        await mouse.down(tester.getCenter(active));
        await tester.pump();
        expect(tester.widget<AnimatedScale>(motion).scale, .9);
        await mouse.up();

        await tester.tap(active);
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(activations, 4);

        await tester.tap(find.bySemanticsLabel('禁用主题色'));
        await tester.tap(find.bySemanticsLabel('加载主题色'));
        expect(activations, 4);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('禁用主题色'))
              .flagsCollection
              .isEnabled,
          ui.Tristate.isFalse,
        );
        final loading = tester.getSemantics(find.bySemanticsLabel('加载主题色'));
        expect(loading.flagsCollection.isEnabled, ui.Tristate.isFalse);
        expect(loading.value, '加载中');
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('Empty State keeps compact geometry at 130 percent on phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var actions = 0;
    await tester.pumpWidget(
      designHarness(
        Center(
          child: SizedBox(
            width: 280,
            child: YYEmptyState(
              message: '播放队列为空。\n可从歌曲菜单添加。',
              glyph: YYGlyph.queue,
              action: YYButton(
                label: '浏览本地 Fixture',
                onPressed: () => actions++,
              ),
            ),
          ),
        ),
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();

    final padding = tester.widget<Padding>(
      find.byKey(const ValueKey('yy-empty-state')),
    );
    expect(
      padding.padding,
      const EdgeInsets.symmetric(
        horizontal: YYFeedbackMetrics.emptyHorizontalPadding,
        vertical: YYFeedbackMetrics.emptyVerticalPadding,
      ),
    );
    expect(tester.widget<YYIcon>(find.byType(YYIcon)).size, 24);
    expect(find.bySemanticsLabel('空状态，播放队列为空。\n可从歌曲菜单添加。'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('浏览本地 Fixture'));
    expect(actions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Error Banner exposes live feedback and independent action states',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var actions = 0;
      Widget subject({VoidCallback? onAction, bool loading = false}) =>
          designHarness(
            Center(
              child: SizedBox(
                width: 620,
                child: YYErrorBanner(
                  title: '音乐源失败',
                  message: '请稍后重试',
                  actionLabel: '重试',
                  onAction: onAction,
                  actionLoading: loading,
                ),
              ),
            ),
          );
      try {
        await tester.pumpWidget(subject());
        final banner = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('yy-error-banner')),
        );
        final decoration = banner.decoration as BoxDecoration;
        expect(
          decoration.borderRadius,
          BorderRadius.circular(YYFeedbackMetrics.bannerRadius),
        );
        expect(decoration.color, YYPalette.error.withValues(alpha: .09));
        expect(
          (decoration.border! as Border).top.color,
          YYPalette.error.withValues(alpha: .18),
        );
        final error = tester.getSemantics(
          find.bySemanticsLabel('错误，音乐源失败。请稍后重试'),
        );
        expect(error.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('重试'))
              .flagsCollection
              .isEnabled,
          ui.Tristate.isFalse,
        );

        await tester.pumpWidget(
          subject(onAction: () => actions++, loading: true),
        );
        final loading = tester.getSemantics(find.bySemanticsLabel('重试'));
        expect(loading.flagsCollection.isEnabled, ui.Tristate.isFalse);
        expect(loading.value, '加载中');
        await tester.tap(find.bySemanticsLabel('重试'));
        expect(actions, 0);

        await tester.pumpWidget(subject(onAction: () => actions++));
        await tester.tap(find.bySemanticsLabel('重试'));
        expect(actions, 1);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('Skeleton is a static solid placeholder with live semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        designHarness(
          const Center(
            child: SizedBox(
              width: 210,
              child: YYSkeleton(height: 18, semanticLabel: '歌曲列表正在加载'),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('yy-skeleton'))),
        const Size(210, 18),
      );
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(YYSkeleton),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      final theme = YYTheme.of(tester.element(find.byType(YYSkeleton)));
      expect(decoration.color, theme.colors.subtle);
      expect(decoration.gradient, isNull);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(YYFeedbackMetrics.skeletonRadius),
      );
      expect(
        find.descendant(
          of: find.byType(YYSkeleton),
          matching: find.byType(ShaderMask),
        ),
        findsNothing,
      );
      final node = tester.getSemantics(find.bySemanticsLabel('歌曲列表正在加载'));
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Gallery feedback fixture reflows without starting real work', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget subject() => designHarness(
      const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: GalleryStateSurfaces(),
        ),
      ),
      scale: 1.3,
    );

    tester.view.physicalSize = const Size(390, 1000);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(YYSkeleton).first).dy,
      greaterThan(tester.getTopLeft(find.byType(YYEmptyState)).dy),
    );
    await tester.ensureVisible(find.bySemanticsLabel('重试 Fixture'));
    await tester.tap(find.bySemanticsLabel('重试 Fixture'));
    await tester.pump();
    expect(find.text('Fixture：收到重试请求（未访问网络）'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(YYSkeleton).first).dx,
      greaterThan(tester.getTopLeft(find.byType(YYEmptyState)).dx),
    );
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
