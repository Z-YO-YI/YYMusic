import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_window_toolbar.dart';
import 'package:yymusic/features/lyrics/common/lyrics_screen.dart';
import 'package:yymusic/features/player/common/player_screen.dart';
import 'package:yymusic/platform/contracts/fullscreen_gateway.dart';

import '../support/design_harness.dart';
import '../support/fake_fullscreen_gateway.dart';
import '../support/fake_window_gateway.dart';
import '../support/fullscreen_app_harness.dart';
import '../support/native_lyrics_harness.dart';

void main() {
  setUpAll(loadDesignAssets);

  testWidgets(
    'Windows F and Esc preserve page state and native session across lyrics',
    (tester) async {
      final native = FakeFullscreenGateway();
      final window = FakeWindowGateway();
      final fixture = await mountFullscreenApp(
        tester,
        fullscreen: native,
        window: window,
      );
      final player = tester.state(find.byType(PlayerScreen));
      final calls = fixture.engine.calls.length;
      expect(native.calls, ['initialize']);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await settleLyrics(tester);
      expect(native.enabled, isTrue);
      expect(find.byType(YYWindowToolbar), findsNothing);
      expect(tester.state(find.byType(PlayerScreen)), same(player));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await settleLyrics(tester);
      final lyrics = tester.state(find.byType(LyricsScreen));
      expect(native.calls, ['initialize', 'enter']);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleLyrics(tester);
      expect(native.enabled, isFalse);
      expect(tester.state(find.byType(LyricsScreen)), same(lyrics));
      expect(find.byType(YYWindowToolbar), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleLyrics(tester);
      expect(tester.state(find.byType(PlayerScreen)), same(player));
      expect(fixture.engine.calls.length, calls);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'F from home opens the player once and input fields retain letter F',
    (tester) async {
      final native = FakeFullscreenGateway();
      await mountFullscreenApp(
        tester,
        fullscreen: native,
        window: FakeWindowGateway(),
        route: '/home',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await settleLyrics(tester);
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(native.calls, ['initialize', 'enter']);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleLyrics(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleLyrics(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settleLyrics(tester);
      final field = find.byType(EditableText).first;
      await tester.tap(field);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pump();
      expect(find.byType(PlayerScreen), findsNothing);
      expect(native.calls.where((c) => c == 'enter'), hasLength(1));
    },
  );

  testWidgets(
    'actual popup restores fullscreen and blocks root F until it closes',
    (tester) async {
      final native = FakeFullscreenGateway();
      await mountFullscreenApp(
        tester,
        fullscreen: native,
        window: FakeWindowGateway(),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await settleLyrics(tester);
      final navigator = Navigator.of(tester.element(find.byType(PlayerScreen)));
      final closed = navigator.push<void>(
        RawDialogRoute<void>(
          barrierDismissible: true,
          barrierLabel: '关闭测试面板',
          pageBuilder: (context, _, _) => const Center(child: Text('测试面板')),
        ),
      );
      await settleLyrics(tester);
      expect(native.enabled, isFalse);
      final before = List<String>.of(native.calls);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
      expect(native.calls, before);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleLyrics(tester);
      await closed;
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await settleLyrics(tester);
      expect(native.enabled, isTrue);
    },
  );

  for (final size in const [
    Size(360, 800),
    Size(590, 360),
    Size(800, 1280),
    Size(1280, 800),
  ]) {
    testWidgets(
      'Android $size enters lyrics and system back restores without stopping music',
      (tester) async {
        final native = FakeFullscreenGateway();
        final fixture = await mountFullscreenApp(
          tester,
          fullscreen: native,
          platform: YYPlatform.android,
          size: size,
          route: '/lyrics',
        );
        expect(native.enabled, isTrue);
        final calls = fixture.engine.calls.length;
        expect(find.bySemanticsLabel('退出全屏'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await settleLyrics(tester);
        expect(find.byType(LyricsScreen), findsNothing);
        expect(native.enabled, isFalse);
        expect(fixture.engine.calls.length, calls);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'rotation preserves fullscreen while zero viewport restores without reentry',
    (tester) async {
      final native = FakeFullscreenGateway();
      await mountFullscreenApp(
        tester,
        fullscreen: native,
        platform: YYPlatform.android,
        size: const Size(390, 844),
        route: '/lyrics',
      );
      final state = tester.state(find.byType(LyricsScreen));
      for (final size in const [
        Size(1280, 800),
        Size(590, 360),
        Size(800, 1280),
      ]) {
        tester.view.physicalSize = size;
        await settleLyrics(tester);
        expect(tester.state(find.byType(LyricsScreen)), same(state));
        expect(native.calls, ['initialize', 'enter']);
      }
      tester.view.physicalSize = Size.zero;
      await settleLyrics(tester);
      expect(native.enabled, isFalse);
      tester.view.physicalSize = const Size(390, 844);
      await settleLyrics(tester);
      expect(tester.state(find.byType(LyricsScreen)), same(state));
      expect(native.enabled, isFalse);
      await tester.tap(find.bySemanticsLabel('进入全屏'));
      await settleLyrics(tester);
      expect(native.enabled, isTrue);
    },
  );

  testWidgets('background restores and resume requires a fresh user gesture', (
    tester,
  ) async {
    final native = FakeFullscreenGateway();
    await mountFullscreenApp(
      tester,
      fullscreen: native,
      platform: YYPlatform.android,
      size: const Size(390, 844),
      route: '/lyrics',
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await settleLyrics(tester);
    expect(native.enabled, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settleLyrics(tester);
    expect(native.calls.where((c) => c == 'enter'), hasLength(1));
    await tester.tap(find.bySemanticsLabel('进入全屏'));
    await settleLyrics(tester);
    expect(native.enabled, isTrue);
  });

  testWidgets(
    'late accepted enter cannot fullscreen home after explicit route back',
    (tester) async {
      final pending = Completer<FullscreenSnapshot>();
      final native = FakeFullscreenGateway()..onEnter = () => pending.future;
      await mountFullscreenApp(
        tester,
        fullscreen: native,
        window: FakeWindowGateway(),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await settleLyrics(tester);
      await tester.tap(find.byKey(const ValueKey('route-back')));
      await settleLyrics(tester);
      pending.complete(const FullscreenSnapshot(enabled: true));
      await settleLyrics(tester);
      expect(find.byType(PlayerScreen), findsNothing);
      expect(native.calls, ['initialize', 'enter', 'restore']);
      expect(native.enabled, isFalse);
      expect(find.byType(YYWindowToolbar), findsOneWidget);
    },
  );

  testWidgets(
    'failed entry keeps readable feedback and a successful retry clears it',
    (tester) async {
      final native = FakeFullscreenGateway()..failEnter = true;
      await mountFullscreenApp(
        tester,
        fullscreen: native,
        window: FakeWindowGateway(),
      );
      await tester.tap(find.bySemanticsLabel('进入全屏'));
      await settleLyrics(tester);
      expect(find.text('全屏操作未完成'), findsOneWidget);
      expect(find.textContaining('private diagnostic'), findsNothing);
      expect(find.byType(YYWindowToolbar), findsOneWidget);
      native.failEnter = false;
      await tester.tap(find.bySemanticsLabel('进入全屏'));
      await settleLyrics(tester);
      expect(native.enabled, isTrue);
      expect(find.text('全屏操作未完成'), findsNothing);
    },
  );

  testWidgets(
    'retained fullscreen button cannot act after its page is covered',
    (tester) async {
      final native = FakeFullscreenGateway();
      await mountFullscreenApp(
        tester,
        fullscreen: native,
        window: FakeWindowGateway(),
      );
      final retained = tester
          .widget<YYButton>(
            find.byWidgetPredicate(
              (widget) => widget is YYButton && widget.label == '进入全屏',
            ),
          )
          .onPressed!;
      await tester.tap(find.byKey(const ValueKey('player-page-queue')));
      await settleLyrics(tester);
      retained();
      await settleLyrics(tester);
      expect(native.calls, ['initialize']);
    },
  );

  testWidgets(
    'native close drains fullscreen before closing audio and completing window close',
    (tester) async {
      final gate = Completer<void>();
      final native = FakeFullscreenGateway()..closeWait = gate.future;
      final window = FakeWindowGateway();
      final fixture = await mountFullscreenApp(
        tester,
        fullscreen: native,
        window: window,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await settleLyrics(tester);
      window.requests.add(null);
      window.requests.add(null);
      await settleLyrics(tester);
      expect(native.calls.where((c) => c == 'close'), hasLength(1));
      expect(fixture.engine.disposalCount, 0);
      expect(window.calls, isNot(contains('completeClose')));
      gate.complete();
      await settleLyrics(tester);
      expect(fixture.engine.disposalCount, 1);
      expect(window.calls.where((c) => c == 'completeClose'), hasLength(1));
    },
  );

  testWidgets(
    'native fullscreen interruption restores chrome without leaving lyrics or reentering',
    (tester) async {
      final native = FakeFullscreenGateway();
      await mountFullscreenApp(
        tester,
        fullscreen: native,
        window: FakeWindowGateway(),
        route: '/lyrics',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await settleLyrics(tester);
      final state = tester.state(find.byType(LyricsScreen));
      native.emit(false);
      await settleLyrics(tester);
      expect(find.byType(YYWindowToolbar), findsOneWidget);
      expect(tester.state(find.byType(LyricsScreen)), same(state));
      expect(native.calls.where((c) => c == 'enter'), hasLength(1));
      expect(find.bySemanticsLabel('进入全屏'), findsOneWidget);
    },
  );

  testWidgets('unsupported fullscreen does not expose a false working button', (
    tester,
  ) async {
    final native = FakeFullscreenGateway()..supported = false;
    await mountFullscreenApp(
      tester,
      fullscreen: native,
      platform: YYPlatform.android,
      size: const Size(390, 844),
      route: '/lyrics',
    );
    expect(find.bySemanticsLabel('进入全屏'), findsNothing);
    expect(find.bySemanticsLabel('退出全屏'), findsNothing);
    expect(find.text('全屏操作未完成'), findsNothing);
    expect(native.calls, ['initialize']);
  });

  testWidgets(
    'narrow desktop at 130 percent retains a tappable enter and exit control',
    (tester) async {
      final native = FakeFullscreenGateway();
      await mountFullscreenApp(
        tester,
        fullscreen: native,
        window: FakeWindowGateway(),
        size: const Size(500, 640),
        route: '/lyrics',
      );
      await tester.tap(find.bySemanticsLabel('进入全屏'));
      await settleLyrics(tester);
      expect(native.enabled, isTrue);
      await tester.tap(find.bySemanticsLabel('退出全屏'));
      await settleLyrics(tester);
      expect(native.enabled, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
