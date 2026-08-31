import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_navigation.dart';
import 'package:yymusic/design_system/yy_surface.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/shells/shell_chrome.dart';

import '../support/design_harness.dart';
import 'foundation_app_test.dart' show mount;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  testWidgets(
    'phone capsule is 64/32 with four accessible targets and no side indicator',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var selected = 0;
        await tester.pumpWidget(
          designHarness(
            Center(
              child: SizedBox(
                width: 336,
                child: StatefulBuilder(
                  builder: (context, setState) => YYMobileBottomNavigation(
                    destinations: androidDestinations,
                    selectedIndex: selected,
                    onSelected: (index) => setState(() => selected = index),
                  ),
                ),
              ),
            ),
            scale: 1.3,
          ),
        );
        expect(
          tester.getSize(find.byType(YYMobileBottomNavigation)).height,
          64,
        );
        expect(
          tester.widget<YYGlassSurface>(find.byType(YYGlassSurface)).radius,
          32,
        );
        expect(find.byType(YYNavigationSelectionIndicator), findsNothing);
        for (final element in find.byType(YYNavigationItem).evaluate()) {
          expect(
            tester.getSize(find.byWidget(element.widget)).shortestSide,
            greaterThanOrEqualTo(44),
          );
        }
        await tester.tap(find.byKey(const ValueKey('nav-library')));
        await tester.pumpAndSettle();
        expect(selected, 2);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('音乐库'))
              .flagsCollection
              .isSelected,
          ui.Tristate.isTrue,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'rail has one 3x18 indicator and can reach settings at low height',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        designHarness(
          Center(
            child: StatefulBuilder(
              builder: (context, setState) => YYTabletNavigationRail(
                height: 140,
                destinations: androidDestinations,
                selectedIndex: selected,
                onSelected: (index) => setState(() => selected = index),
              ),
            ),
          ),
          scale: 1.3,
        ),
      );
      expect(tester.getSize(find.byType(YYTabletNavigationRail)).width, 72);
      expect(
        tester.getSize(find.byType(YYNavigationSelectionIndicator)),
        const Size(3, 18),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('nav-settings')));
      await tester.tap(find.byKey(const ValueKey('nav-settings')));
      await tester.pumpAndSettle();
      expect(selected, 3);
      expect(find.byType(YYNavigationSelectionIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selection boundaries adapt to low contrast without changing raw accents',
    (tester) async {
      for (final (mode, hex, needsOutline) in [
        (YYThemeMode.light, '#FFFFFF', true),
        (YYThemeMode.dark, '#000000', true),
        (YYThemeMode.light, '#FF3B5C', false),
        (YYThemeMode.dark, '#00A67E', false),
      ]) {
        final appearance = YYAppearanceController()
          ..setMode(mode)
          ..setCustomAccent(hex)
          ..setReduceMotion(true);
        addTearDown(appearance.dispose);
        await tester.pumpWidget(
          designHarness(
            Center(
              child: YYTabletNavigationRail(
                height: 300,
                destinations: androidDestinations,
                selectedIndex: 0,
                onSelected: (_) {},
              ),
            ),
            appearance: appearance,
          ),
        );
        await tester.pumpAndSettle();
        final theme = YYTheme.of(
          tester.element(find.byType(YYTabletNavigationRail)),
        );
        expect(theme.accent.originalHex, hex);
        for (final (id, selected) in [('home', true), ('search', false)]) {
          final decoration =
              tester
                      .widget<AnimatedContainer>(
                        find.descendant(
                          of: find.byKey(ValueKey('nav-$id')),
                          matching: find.byType(AnimatedContainer),
                        ),
                      )
                      .decoration!
                  as BoxDecoration;
          final border = decoration.border! as Border;
          if (selected && needsOutline) {
            expect(
              YYAccent.contrast(border.top.color, decoration.color!),
              greaterThanOrEqualTo(4.5),
            );
          } else {
            expect(border.top.color.a, 0);
          }
        }
        final marker =
            tester
                    .widget<Container>(
                      find.descendant(
                        of: find.byType(YYNavigationSelectionIndicator),
                        matching: find.byType(Container),
                      ),
                    )
                    .decoration!
                as BoxDecoration;
        expect(marker.color, theme.accent.color);
        expect(marker.border, needsOutline ? isNotNull : isNull);
        expect(
          tester.getSize(find.byType(YYNavigationSelectionIndicator)),
          const Size(3, 18),
        );
      }
    },
  );

  testWidgets(
    'navigation keyboard actions and disabled state do not need Material',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var calls = 0;
      Widget subject(bool enabled) => designHarness(
        Center(
          child: SizedBox(
            width: 64,
            height: 64,
            child: YYNavigationItem(
              destination: androidDestinations[0],
              selected: false,
              focusNode: focus,
              onPressed: enabled ? () => calls++ : null,
            ),
          ),
        ),
      );
      await tester.pumpWidget(subject(true));
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(calls, 2);
      await tester.pumpWidget(subject(false));
      await tester.tap(find.byType(YYNavigationItem));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, 2);
    },
  );

  testWidgets(
    'real Android routes preserve graph across 599/600 and SafeArea insets',
    (tester) async {
      final graph = DependencyGraph();
      await mount(
        tester,
        platform: YYPlatform.android,
        size: const Size(390, 844),
        graph: graph,
        scale: 1.3,
      );
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(YYMobileBottomNavigation)).bottom,
        lessThanOrEqualTo(844 - 34),
      );
      await tester.tap(find.byKey(const ValueKey('nav-library')));
      await tester.pumpAndSettle();
      final queue = graph.queue, playback = graph.playback;
      for (final size in [
        const Size(599, 900),
        const Size(600, 900),
        const Size(1280, 800),
        const Size(844, 390),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('screen-library')), findsOneWidget);
        expect(graph.queue, same(queue));
        expect(graph.playback, same(playback));
        expect(
          find.byType(YYMobileBottomNavigation),
          size.width < 600 ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(YYTabletNavigationRail),
          size.width >= 600 ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull, reason: '$size');
      }
      await tester.tap(find.byKey(const ValueKey('open-player')));
      await tester.pumpAndSettle();
      expect(find.byType(YYMobileBottomNavigation), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-library')), findsOneWidget);
      expect(graph.playback.isAvailable, isFalse);
    },
  );
}
