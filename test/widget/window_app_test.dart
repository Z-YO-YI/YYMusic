import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/window_chrome.dart';
import 'package:yymusic/design_system/yy_window_toolbar.dart';
import 'package:yymusic/platform/contracts/window_gateway.dart';

import '../support/design_harness.dart';
import '../support/fake_window_gateway.dart';
import '../support/playback_graph_fixture.dart';
import '../support/window_app_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'root window controls use native state and exclude buttons from drag',
    (tester) async {
      final fixture = PlaybackGraphFixture();
      final window = FakeWindowGateway();
      final semantics = tester.ensureSemantics();
      try {
        await mountWindowApp(tester, fixture, window);
        expect(find.byType(YYWindowToolbar), findsOneWidget);
        expect(window.calls, ['initialize']);
        expect(
          tester
              .widget<YYWindowToolbar>(find.byType(YYWindowToolbar))
              .showWindowControls,
          isTrue,
        );
        expect(tester.getSize(find.byType(YYWindowToolbar)).height, 42);
        await tester.tap(find.bySemanticsLabel('最大化'));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('还原'), findsOneWidget);
        final drag = find.byKey(const ValueKey('window-drag-region'));
        await tester.tap(drag);
        await tester.pump(const Duration(milliseconds: 80));
        await tester.tap(drag);
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('最大化'), findsOneWidget);
        expect(window.calls.where((c) => c == 'toggleMaximize').length, 2);
        await tester.drag(drag, const Offset(40, 0));
        await tester.pumpAndSettle();
        expect(window.calls.where((c) => c == 'startDrag').length, 1);
        await tester.drag(find.bySemanticsLabel('最小化'), const Offset(0, 60));
        await tester.pumpAndSettle();
        expect(window.calls.where((c) => c == 'startDrag').length, 1);
        await tester.tap(find.bySemanticsLabel('最小化'));
        await tester.pumpAndSettle();
        expect(window.calls, contains('minimize'));
        for (final size in const [
          Size(840, 640),
          Size(599, 720),
          Size.zero,
          Size(1440, 900),
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(window.calls.where((c) => c == 'initialize').length, 1);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        try {
          await mouse.moveTo(tester.getCenter(find.bySemanticsLabel('关闭')));
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('关闭'), findsOneWidget);
          final tooltip = tester.getRect(find.text('关闭'));
          expect(tooltip.right, lessThanOrEqualTo(1440));
          expect(tooltip.top, greaterThanOrEqualTo(42));
          expect(tester.takeException(), isNull);
        } finally {
          await mouse.removePointer();
          await tester.pump();
        }
      } finally {
        semantics.dispose();
        await closeWindowApp(tester, fixture, window);
      }
    },
  );

  for (final route in [
    '/player',
    '/lyrics',
    '/settings/licenses',
    '/design-system',
  ]) {
    testWidgets('window controls remain reachable outside Shell at $route', (
      tester,
    ) async {
      final fixture = PlaybackGraphFixture();
      final window = FakeWindowGateway();
      try {
        await mountWindowApp(tester, fixture, window, route: route);
        for (final label in ['最小化', '关闭']) {
          expect(
            find
                .descendant(
                  of: find.byType(WindowChrome),
                  matching: find.bySemanticsLabel(label),
                )
                .hitTestable(),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      } finally {
        await closeWindowApp(tester, fixture, window);
      }
    });
  }

  testWidgets('Android never initializes the injected Windows gateway', (
    tester,
  ) async {
    final fixture = PlaybackGraphFixture();
    final window = FakeWindowGateway();
    try {
      await mountWindowApp(
        tester,
        fixture,
        window,
        platform: YYPlatform.android,
      );
      expect(window.calls, isEmpty);
      expect(find.bySemanticsLabel('最小化'), findsNothing);
    } finally {
      await closeWindowApp(tester, fixture, window);
    }
  });

  testWidgets(
    'native close requests drain the same graph before completing once',
    (tester) async {
      final fixture = PlaybackGraphFixture();
      final window = FakeWindowGateway();
      try {
        await mountWindowApp(tester, fixture, window);
        await window.requestClose();
        await window.requestClose();
        for (
          var i = 0;
          i < 12 && !window.calls.contains('completeClose');
          i++
        ) {
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await tester.pump();
        }
        expect(window.calls.where((c) => c == 'completeClose').length, 1);
        expect(fixture.engine.disposalCount, 1);
        expect(tester.takeException(), isNull);
      } finally {
        await closeWindowApp(tester, fixture, window);
      }
    },
  );

  testWidgets('window operation failure is fixed text and can be retried', (
    tester,
  ) async {
    final fixture = PlaybackGraphFixture();
    final window = FakeWindowGateway()
      ..commandError = StateError('private-path');
    try {
      await mountWindowApp(tester, fixture, window);
      await tester.tap(find.bySemanticsLabel('最大化'));
      await tester.pumpAndSettle();
      expect(find.text('窗口操作未完成，请重试。'), findsOneWidget);
      expect(find.textContaining('private-path'), findsNothing);
      window.commandError = null;
      await tester.tap(find.bySemanticsLabel('最大化'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('还原'), findsOneWidget);
      expect(find.text('窗口操作未完成，请重试。'), findsNothing);
      window.events.add(
        const WindowSnapshot(
          maximized: false,
          minimized: false,
          customFrame: true,
        ),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('最大化'), findsOneWidget);
    } finally {
      await closeWindowApp(tester, fixture, window);
    }
  });
}
