import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_navigation.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/design_system/yy_window_toolbar.dart';
import 'package:yymusic/design_system/yy_windows_sidebar.dart';
import 'package:yymusic/shells/shell_chrome.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  testWidgets(
    'expanded Windows sidebar keeps audited geometry, semantics and actions',
    (tester) async {
      final previousStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );
      tester.view.physicalSize = const Size(1024, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      var selected = 0;
      var managed = 0;
      var account = 0;
      try {
        await tester.pumpWidget(
          designHarness(
            Center(
              child: SizedBox(
                height: 640,
                child: StatefulBuilder(
                  builder: (context, setState) => YYWindowsSidebar(
                    compact: false,
                    destinations: primaryDestinations,
                    selectedIndex: selected,
                    onSelected: (index) => setState(() => selected = index),
                    sourceLabel: '音乐源尚未接入',
                    sourceDescription: '等待 Repository。',
                    onManageSources: () => managed++,
                    onAccountMore: () => account++,
                  ),
                ),
              ),
            ),
            scale: 1.3,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(YYWindowsSidebar)).width,
          YYWindowsMetrics.sidebarExpandedWidth,
        );
        expect(find.text('YY Listener'), findsOneWidget);
        expect(find.text('本地账户'), findsOneWidget);
        expect(find.text('音乐源尚未接入'), findsOneWidget);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('首页'))
              .flagsCollection
              .isSelected,
          ui.Tristate.isTrue,
        );
        expect(
          tester.getSize(find.byType(YYNavigationSelectionIndicator)),
          const Size(3, 18),
        );

        await tester.tap(find.bySemanticsLabel('搜索'));
        await tester.pumpAndSettle();
        expect(selected, 1);
        await tester.tap(find.bySemanticsLabel('管理音乐源'));
        await tester.tap(find.bySemanticsLabel('更多账户选项'));
        expect((managed, account), (1, 1));

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        final library = find.byKey(const ValueKey('windows-nav-library'));
        await mouse.moveTo(tester.getCenter(library));
        await tester.pump();
        final hoverDecoration =
            tester.widget<AnimatedContainer>(library).decoration!
                as BoxDecoration;
        expect(hoverDecoration.color, isNot(const Color(0x00000000)));
        await mouse.down(tester.getCenter(library));
        await tester.pump();
        expect(
          tester
              .widget<AnimatedScale>(
                find.ancestor(
                  of: library,
                  matching: find.byType(AnimatedScale),
                ),
              )
              .scale,
          .98,
        );
        await mouse.up();
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'compact Windows sidebar is 72dp, keyboard reachable and shows tooltip',
    (tester) async {
      tester.view.physicalSize = const Size(840, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = 0;
      await tester.pumpWidget(
        designHarness(
          FocusTraversalGroup(
            child: Focus(
              autofocus: true,
              child: Center(
                child: SizedBox(
                  height: 500,
                  child: StatefulBuilder(
                    builder: (context, setState) => YYWindowsSidebar(
                      compact: true,
                      destinations: primaryDestinations,
                      selectedIndex: selected,
                      onSelected: (index) => setState(() => selected = index),
                      sourceLabel: '不得显示',
                      sourceDescription: '不得显示',
                    ),
                  ),
                ),
              ),
            ),
          ),
          scale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(YYWindowsSidebar)).width,
        YYWindowsMetrics.sidebarCompactWidth,
      );
      expect(find.text('YY Listener'), findsNothing);
      expect(find.text('不得显示'), findsNothing);
      expect(find.text('首页'), findsNothing);
      expect(find.bySemanticsLabel('首页'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 1);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(
        tester.getCenter(find.byKey(const ValueKey('windows-nav-library'))),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('音乐库'), findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(find.text('音乐库'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Windows toolbar keeps controls separate and never fakes them', (
    tester,
  ) async {
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy = previousStrategy,
    );
    var minimize = 0;
    var maximize = 0;
    var close = 0;
    await tester.pumpWidget(
      designHarness(
        Center(
          child: SizedBox(
            width: 900,
            child: YYWindowToolbar(
              onMinimize: () => minimize++,
              onToggleMaximize: () => maximize++,
              onClose: () => close++,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(YYWindowToolbar)).height,
      YYWindowsMetrics.toolbarHeight,
    );
    await tester.tap(find.bySemanticsLabel('最小化'));
    await tester.tap(find.bySemanticsLabel('最大化'));
    await tester.tap(find.bySemanticsLabel('关闭'));
    expect((minimize, maximize, close), (1, 1, 1));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    final closeSurface = find.byKey(const ValueKey('window-control-关闭'));
    await mouse.moveTo(tester.getCenter(closeSurface));
    await tester.pump();
    final decoration =
        tester.widget<AnimatedContainer>(closeSurface).decoration!
            as BoxDecoration;
    expect(decoration.color, YYPalette.error.withValues(alpha: .13));

    await tester.pumpWidget(
      designHarness(
        const Center(
          child: SizedBox(
            width: 840,
            child: YYWindowToolbar(showWindowControls: false),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('最小化'), findsNothing);
    expect(find.bySemanticsLabel('最大化'), findsNothing);
    expect(find.bySemanticsLabel('关闭'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
