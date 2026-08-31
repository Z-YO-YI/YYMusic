import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_icon.dart';
import 'package:yymusic/design_system/yy_surface.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  testWidgets('original 44 SVGs decode and render with declared semantics', (
    tester,
  ) async {
    expect(YYGlyph.values.length, 44);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        designHarness(
          Center(
            child: Wrap(
              children: [
                for (final glyph in YYGlyph.values)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: YYIcon(glyph: glyph, semanticLabel: glyph.label),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(YYIcon), findsNWidgets(44));
      expect(find.bySemanticsLabel('歌词'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'button pointer, keyboard, disabled/loading and semantic states',
    (tester) async {
      final focus = FocusNode();
      final appearance = YYAppearanceController()..setReduceMotion(true);
      addTearDown(focus.dispose);
      addTearDown(appearance.dispose);
      final semantics = tester.ensureSemantics();
      try {
        var count = 0;
        Widget subject({bool disabled = false, bool loading = false}) =>
            designHarness(
              Center(
                child: YYButton(
                  label: '测试操作',
                  onPressed: disabled ? null : () => count++,
                  loading: loading,
                  selected: true,
                  style: YYButtonStyle.primary,
                  focusNode: focus,
                ),
              ),
              appearance: appearance,
              scale: 1.3,
            );
        await tester.pumpWidget(subject());
        final button = find.byType(YYButton);
        expect(tester.getSize(button).shortestSide, greaterThanOrEqualTo(44));
        await tester.tap(button);
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(count, 3);
        final node = tester.getSemantics(find.bySemanticsLabel('测试操作'));
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
        expect(
          node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
        for (final state in [(true, false), (false, true)]) {
          await tester.pumpWidget(
            subject(disabled: state.$1, loading: state.$2),
          );
          await tester.tap(button);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          expect(count, 3);
          final disabledNode = tester.getSemantics(
            find.bySemanticsLabel('测试操作'),
          );
          expect(disabledNode.flagsCollection.isEnabled, ui.Tristate.isFalse);
          expect(
            disabledNode.getSemanticsData().hasAction(ui.SemanticsAction.tap),
            isFalse,
          );
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'hover, press and keyboard focus have distinct native decorations',
    (tester) async {
      final previousStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );
      final focus = FocusNode();
      final appearance = YYAppearanceController()..setReduceMotion(true);
      addTearDown(focus.dispose);
      addTearDown(appearance.dispose);
      await tester.pumpWidget(
        designHarness(
          Center(
            child: YYButton(label: '状态', onPressed: () {}, focusNode: focus),
          ),
          appearance: appearance,
        ),
      );
      BoxDecoration decoration() =>
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as BoxDecoration;
      final original = decoration().color;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(YYButton)));
      await tester.pump();
      expect(decoration().color, isNot(original));
      await mouse.down(tester.getCenter(find.byType(YYButton)));
      await tester.pump(const Duration(milliseconds: 150));
      expect(decoration().color, const YYPalette(Brightness.light).pressed);
      await mouse.up();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      focus.requestFocus();
      await tester.pump();
      expect(
        (decoration().border! as Border).top.color,
        const YYPalette(Brightness.light).text,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reduce Glass removes only local backdrop and keeps panel geometry',
    (tester) async {
      final appearance = YYAppearanceController();
      addTearDown(appearance.dispose);
      await tester.pumpWidget(
        designHarness(
          const Center(
            child: SizedBox(
              width: 320,
              child: YYGlassSurface(height: 112, child: Text('工具栏')),
            ),
          ),
          appearance: appearance,
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      final size = tester.getSize(find.byType(YYGlassSurface));
      appearance.setReduceGlass(true);
      await tester.pump();
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.getSize(find.byType(YYGlassSurface)), size);
      expect(find.byType(ClipRRect), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
