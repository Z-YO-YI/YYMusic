import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_slider.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';

import '../support/design_harness.dart';

void main() {
  testWidgets('3/14 geometry, 44dp target, endpoints and one discrete commit', (
    tester,
  ) async {
    var value = .5;
    final starts = <double>[], ends = <double>[];
    await tester.pumpWidget(
      designHarness(
        Center(
          child: SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) => YYSlider(
                label: '进度',
                value: value,
                onChanged: (next) => setState(() => value = next),
                onChangeStart: starts.add,
                onChangeEnd: ends.add,
              ),
            ),
          ),
        ),
      ),
    );
    final slider = find.byType(YYSlider);
    expect(tester.getSize(slider), const Size(300, 44));
    expect(
      tester.getSize(find.byKey(const ValueKey('slider-track'))).height,
      3,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('slider-thumb'))),
      const Size(14, 14),
    );
    final bounds = tester.getRect(slider);
    await tester.tapAt(Offset(bounds.left + 1, bounds.center.dy));
    await tester.pump();
    expect(value, 0);
    await tester.tapAt(Offset(bounds.right - 1, bounds.center.dy));
    await tester.pump();
    expect(value, 1);
    expect(starts, [.5, 0]);
    expect(ends, [0, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'horizontal drag previews continuously then commits once; cancellation does not commit',
    (tester) async {
      var value = .25;
      final updates = <double>[], ends = <double>[];
      var starts = 0, cancels = 0;
      await tester.pumpWidget(
        designHarness(
          Center(
            child: SizedBox(
              width: 300,
              child: StatefulBuilder(
                builder: (context, setState) => YYSlider(
                  label: '进度',
                  value: value,
                  onChanged: (next) {
                    updates.add(next);
                    setState(() => value = next);
                  },
                  onChangeStart: (_) => starts++,
                  onChangeEnd: ends.add,
                  onChangeCancel: () => cancels++,
                ),
              ),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.byType(YYSlider));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(45, 0));
      await tester.pump();
      expect(starts, 1);
      expect(updates.length, greaterThanOrEqualTo(2));
      expect(ends, isEmpty);
      await gesture.up();
      await tester.pump();
      expect(ends, [value]);
      final cancelled = await tester.startGesture(center);
      await cancelled.moveBy(const Offset(-60, 0));
      await tester.pump();
      await cancelled.cancel();
      await tester.pump();
      expect(cancels, 1);
      expect(ends.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('vertical scrolling through slider never changes its value', (
    tester,
  ) async {
    var changes = 0;
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      designHarness(
        SingleChildScrollView(
          controller: scroll,
          child: Column(
            children: [
              const SizedBox(height: 100),
              YYSlider(label: '进度', value: .5, onChanged: (_) => changes++),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      ),
    );
    await tester.drag(find.byType(YYSlider), const Offset(0, -90));
    await tester.pumpAndSettle();
    expect(changes, 0);
    expect(scroll.offset, greaterThan(0));
  });

  testWidgets('keyboard, semantic increment and RTL preserve value direction', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final focus = FocusNode();
    addTearDown(focus.dispose);
    try {
      for (final direction in TextDirection.values) {
        var value = .5;
        await tester.pumpWidget(
          designHarness(
            Directionality(
              textDirection: direction,
              child: Center(
                child: SizedBox(
                  width: 300,
                  child: StatefulBuilder(
                    builder: (context, setState) => YYSlider(
                      label: '音量',
                      value: value,
                      step: .1,
                      focusNode: focus,
                      onChanged: (next) => setState(() => value = next),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(value, closeTo(direction == TextDirection.ltr ? .6 : .4, .001));
        await tester.pumpAndSettle();
        var node = tester.getSemantics(find.byType(YYSlider));
        // Flutter adds bidi embedding marks when merging RTL semantics.
        expect(node.label.replaceAll(RegExp(r'[\u202A-\u202E]'), ''), '音量');
        expect(node.flagsCollection.isSlider, isTrue);
        tester.binding.performSemanticsAction(
          ui.SemanticsActionEvent(
            type: ui.SemanticsAction.increase,
            nodeId: node.id,
            viewId: tester.view.viewId,
          ),
        );
        await tester.pump();
        expect(value, closeTo(direction == TextDirection.ltr ? .7 : .5, .001));
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        expect(value, 1);
        node = tester.getSemantics(find.byType(YYSlider));
        expect(
          node.getSemanticsData().hasAction(ui.SemanticsAction.increase),
          isFalse,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        expect(value, 0);
        final bounds = tester.getRect(find.byType(YYSlider));
        await tester.tapAt(Offset(bounds.left + 1, bounds.center.dy));
        await tester.pump();
        expect(value, direction == TextDirection.ltr ? 0 : 1);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'disabled, loading, collapsed range and mid-drag disable do not commit',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var calls = 0, ends = 0;
      for (final (disabled, loading, max) in [
        (true, false, 1.0),
        (false, true, 1.0),
        (false, false, 0.0),
      ]) {
        await tester.pumpWidget(
          designHarness(
            Center(
              child: SizedBox(
                width: 300,
                child: YYSlider(
                  label: '不可用',
                  value: 0,
                  max: max,
                  loading: loading,
                  focusNode: focus,
                  onChanged: disabled ? null : (_) => calls++,
                  onChangeEnd: (_) => ends++,
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(YYSlider));
        await tester.drag(find.byType(YYSlider), const Offset(80, 0));
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
      }
      expect(calls, 0);
      expect(ends, 0);
      var enabled = true;
      late StateSetter update;
      await tester.pumpWidget(
        designHarness(
          Center(
            child: SizedBox(
              width: 300,
              child: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return YYSlider(
                    label: '中途禁用',
                    value: .5,
                    onChanged: enabled ? (_) => calls++ : null,
                    onChangeEnd: (_) => ends++,
                  );
                },
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(YYSlider)),
      );
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(calls, greaterThan(0));
      update(() => enabled = false);
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(ends, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hover uses 1.24 scale and Reduced Motion removes its duration', (
    tester,
  ) async {
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy = previousStrategy,
    );
    final appearance = YYAppearanceController();
    addTearDown(appearance.dispose);
    await tester.pumpWidget(
      designHarness(
        Center(
          child: SizedBox(
            width: 300,
            child: YYSlider(label: '悬停', value: .5, onChanged: (_) {}),
          ),
        ),
        appearance: appearance,
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(YYSlider)));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      YYSliderMetrics.hoverScale,
    );
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      const Duration(milliseconds: 130),
    );
    appearance.setReduceMotion(true);
    await tester.pump();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      Duration.zero,
    );
    await mouse.removePointer();
  });
}
