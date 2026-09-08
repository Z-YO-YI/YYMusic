import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_lyrics_line.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/domain/models/lyrics.dart';
import 'package:yymusic/features/lyrics/common/lyrics_viewport.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/lyrics_fixture.dart';

LyricsDocument viewportDocument({
  int count = 100,
  bool plain = false,
  Duration offset = Duration.zero,
}) => LyricsDocument(
  track: lyricsTracks.first.ref,
  kind: plain ? LyricsKind.plain : LyricsKind.synchronized,
  language: 'en',
  translationLanguage: 'zh',
  offset: offset,
  lines: [
    for (var i = 0; i < count; i++)
      LyricsLine(
        text: i % 3 == 0
            ? 'Line $i with a longer title that wraps across the viewport'
            : 'Line $i',
        translation: '翻译 $i · 当前测试歌词',
        start: plain ? null : Duration(seconds: i * 2),
        end: plain ? null : Duration(seconds: i * 2 + 1),
      ),
  ],
);

class ViewportProbe extends ChangeNotifier {
  ViewportProbe({LyricsDocument? document})
    : document = document ?? viewportDocument();
  LyricsDocument document;
  Object snapshot = Object();
  int? index = 50;
  Duration position = const Duration(seconds: 100);
  bool active = true, translation = true, phone = true, seekEnabled = true;
  final seeks = <int>[];
  void change(VoidCallback update) {
    update();
    notifyListeners();
  }

  Widget get body => ListenableBuilder(
    listenable: this,
    builder: (context, _) => ColoredBox(
      color: const Color(0xFF34454D),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: LyricsViewport(
          document: document,
          snapshotKey: snapshot,
          activeIndex: index,
          position: position,
          active: active,
          phoneLayout: phone,
          showTranslation: translation,
          onSeek: seekEnabled ? seeks.add : null,
        ),
      ),
    ),
  );
}

Future<void> mountViewport(
  WidgetTester tester,
  ViewportProbe probe, {
  Size size = const Size(390, 700),
  YYAppearanceController? appearance,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(probe.dispose);
  await tester.pumpWidget(
    designHarness(probe.body, scale: 1.3, appearance: appearance),
  );
  await tester.pumpAndSettle();
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
}

Finder activeLine() => find.byWidgetPredicate(
  (w) => w is YYLyricsLine && w.state == YYLyricsLineState.active,
);
ScrollController viewportScroll(WidgetTester tester) => tester
    .widget<CustomScrollView>(find.byKey(const ValueKey('lyrics-scroll')))
    .controller!;
void expectCentered(WidgetTester tester) {
  final line = tester.getRect(activeLine());
  final view = tester.getRect(find.byKey(const ValueKey('lyrics-scroll')));
  expect((line.center.dy - view.center.dy).abs(), lessThan(3));
}

void main() {
  setUpAll(loadDesignAssets);
  testWidgets(
    'resume after browsing far away rebuilds the anchor instead of retaining old pixel offset',
    (tester) async {
      final probe = ViewportProbe(document: viewportDocument(count: 10000))
        ..index = 5000;
      await mountViewport(tester, probe);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
      await tester.pumpAndSettle();
      viewportScroll(tester).jumpTo(10000);
      await tester.pumpAndSettle();
      probe.change(() => probe.index = 8000);
      await tester.pump();
      await tester.tap(find.text('回到当前歌词'));
      await tester.pumpAndSettle();
      expect(activeLine(), findsOneWidget);
      expectCentered(tester);
      expect(find.byType(YYLyricsLine).evaluate().length, lessThan(35));
    },
  );
  testWidgets(
    'position ticks keep the same viewport and automatic follow never takes outside focus',
    (tester) async {
      final probe = ViewportProbe();
      final outside = FocusNode();
      addTearDown(outside.dispose);
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(probe.dispose);
      await tester.pumpWidget(
        designHarness(
          Column(
            children: [
              Focus(focusNode: outside, child: const SizedBox(height: 50)),
              Expanded(child: probe.body),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      outside.requestFocus();
      await tester.pump();
      final scroll = viewportScroll(tester);
      for (var i = 0; i < 30; i++) {
        probe.change(() => probe.position += const Duration(milliseconds: 10));
        await tester.pump();
        expect(viewportScroll(tester), same(scroll));
      }
      probe.change(() => probe.index = 90);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(outside));
      expectCentered(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'manual browsing during a timing gap does not jump back to the first line',
    (tester) async {
      final probe = ViewportProbe();
      await mountViewport(tester, probe);
      probe.change(() => probe.index = null);
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
      await tester.pumpAndSettle();
      final scroll = viewportScroll(tester);
      final offset = scroll.offset;
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(viewportScroll(tester), same(scroll));
      expect(scroll.offset, offset);
      probe.change(() => probe.index = 51);
      await tester.pumpAndSettle();
      expectCentered(tester);
    },
  );
  testWidgets(
    'disabled seek and a new document invalidate retained callbacks',
    (tester) async {
      final probe = ViewportProbe();
      await mountViewport(tester, probe);
      final callback = tester.widget<YYLyricsLine>(activeLine()).onPressed!;
      probe.change(() => probe.seekEnabled = false);
      await tester.pumpAndSettle();
      callback();
      expect(probe.seeks, isEmpty);
      expect(tester.takeException(), isNull);
      probe.change(() => probe.seekEnabled = true);
      await tester.pumpAndSettle();
      final previous = tester.widget<YYLyricsLine>(activeLine()).onPressed!;
      probe.change(() {
        probe.document = viewportDocument(count: 3);
        probe.index = 1;
      });
      await tester.pumpAndSettle();
      previous();
      expect(probe.seeks, isEmpty);
      expectCentered(tester);
    },
  );
  testWidgets(
    'pending manual resume is cancelled by deactivation and disposal',
    (tester) async {
      final probe = ViewportProbe();
      await mountViewport(tester, probe);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
      await tester.pumpAndSettle();
      probe.change(() => probe.active = false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('回到当前歌词'), findsNothing);
      probe.change(() => probe.active = true);
      await tester.pumpAndSettle();
      expectCentered(tester);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 6));
      expect(probe.seeks, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('plain lyrics expose text semantics without disabled buttons', (
    tester,
  ) async {
    final probe = ViewportProbe(document: viewportDocument(plain: true));
    await mountViewport(tester, probe);
    final semantics = tester.ensureSemantics();
    try {
      for (final element in find.byType(YYLyricsLine).evaluate()) {
        final node = tester.getSemantics(find.byWidget(element.widget));
        expect(node.flagsCollection.isButton, isFalse);
        expect(
          node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isFalse,
        );
      }
    } finally {
      semantics.dispose();
    }
  });
  testWidgets(
    'real root lyrics snapshot drives highlight and offset seek without a second clock',
    (tester) async {
      late LyricsFixture fixture;
      await tester.runAsync(() async {
        fixture = LyricsFixture();
        fixture.repository.documents[lyricsTracks.first.ref] = timedLyrics(
          lyricsTracks.first.ref,
          offset: const Duration(seconds: 3),
        );
        await fixture.initialize();
        fixture.graph.lyricsController.setActive(true);
        await flushLyrics();
        await fixture.graph.playback.seek(const Duration(seconds: 15));
      });
      final controller = fixture.graph.lyricsController;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await closeGraph(tester, fixture.graph);
      });
      await tester.pumpWidget(
        designHarness(
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final snapshot = controller.state;
              return LyricsViewport(
                document: snapshot.data!,
                snapshotKey: snapshot,
                activeIndex: controller.activeIndex,
                position: fixture.graph.playback.state.position,
                phoneLayout: true,
                onSeek: (index) {
                  controller.seekLine(index, expectedState: snapshot);
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<YYLyricsLine>(activeLine()).text, 'Test line 0');
      await tester.tap(activeLine());
      await tester.runAsync(flushLyrics);
      await tester.pumpAndSettle();
      expect(fixture.engine.calls.last, 'seek:13000');
      expect(fixture.repository.reads, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await closeGraph(tester, fixture.graph);
    },
  );
  for (final size in [
    const Size(360, 800),
    const Size(590, 360),
    const Size(800, 1280),
    const Size(1280, 800),
    const Size(1440, 900),
    const Size(500, 640),
  ]) {
    testWidgets(
      'lyrics viewport centers variable-height bilingual line at $size and 130 percent',
      (tester) async {
        final probe = ViewportProbe()..phone = size.width < 600;
        await mountViewport(tester, probe, size: size);
        expect(activeLine(), findsOneWidget);
        expectCentered(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(activeLine());
        expect(probe.seeks, [50]);
      },
    );
  }
  testWidgets(
    'ten thousand lines remain lazy and first last and distant seeks center exactly',
    (tester) async {
      final probe = ViewportProbe(document: viewportDocument(count: 10000))
        ..index = 5000;
      await mountViewport(tester, probe);
      for (final index in [5000, 9999, 0, 7000, 23]) {
        probe.change(() {
          probe.index = index;
          probe.position = Duration(seconds: index * 2);
        });
        await tester.pumpAndSettle();
        expectCentered(tester);
        expect(find.byType(YYLyricsLine).evaluate().length, lessThan(35));
        expect(probe.seeks, isEmpty);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'touch browsing pauses follow then resumes five seconds after scrolling',
    (tester) async {
      final probe = ViewportProbe();
      await mountViewport(tester, probe);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text('回到当前歌词'), findsOneWidget);
      final scroll = viewportScroll(tester);
      final offset = scroll.offset;
      probe.change(() => probe.index = 90);
      await tester.pump();
      expect(viewportScroll(tester), same(scroll));
      expect(scroll.offset, offset);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('回到当前歌词'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('回到当前歌词'), findsNothing);
      expectCentered(tester);
      expect(probe.seeks, isEmpty);
    },
  );
  testWidgets('mouse wheel and explicit resume affect scrolling only', (
    tester,
  ) async {
    final probe = ViewportProbe()..phone = false;
    await mountViewport(tester, probe, size: const Size(1024, 720));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.byType(CustomScrollView)),
        scrollDelta: const Offset(0, 240),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('回到当前歌词'), findsOneWidget);
    probe.change(() => probe.index = 10);
    await tester.pump();
    await tester.tap(find.text('回到当前歌词'));
    await tester.pumpAndSettle();
    expectCentered(tester);
    expect(probe.seeks, isEmpty);
  });
  testWidgets(
    'snapshot replacement active state size and disposal reject old callbacks',
    (tester) async {
      final probe = ViewportProbe();
      await mountViewport(tester, probe);
      final first = tester.widget<YYLyricsLine>(activeLine()).onPressed!;
      probe.change(() => probe.snapshot = Object());
      await tester.pumpAndSettle();
      first();
      final second = tester.widget<YYLyricsLine>(activeLine()).onPressed!;
      probe.change(() => probe.active = false);
      await tester.pumpAndSettle();
      second();
      probe.change(() => probe.active = true);
      await tester.pumpAndSettle();
      final third = tester.widget<YYLyricsLine>(activeLine()).onPressed!;
      tester.view.physicalSize = Size.zero;
      await tester.pump();
      third();
      tester.view.physicalSize = const Size(500, 700);
      await tester.pumpAndSettle();
      third();
      final fourth = tester.widget<YYLyricsLine>(activeLine()).onPressed!;
      await tester.pumpWidget(const SizedBox.shrink());
      fourth();
      await tester.pump(const Duration(seconds: 8));
      expect(probe.seeks, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'translation toggle and resizing recenter without seeking or changing focused control',
    (tester) async {
      final probe = ViewportProbe()..phone = false;
      await mountViewport(tester, probe, size: const Size(500, 640));
      final node = Focus.of(
        tester.element(
          find
              .descendant(
                of: activeLine(),
                matching: find.byType(AnimatedScale),
              )
              .first,
        ),
      );
      node.requestFocus();
      await tester.pump();
      probe.change(() => probe.translation = false);
      await tester.pumpAndSettle();
      expect(tester.widget<YYLyricsLine>(activeLine()).translation, isNull);
      expect(tester.widget<YYLyricsLine>(activeLine()).phoneLayout, isFalse);
      expectCentered(tester);
      expect(FocusManager.instance.primaryFocus, same(node));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(probe.seeks, [50]);
    },
  );
  testWidgets('plain lyrics never highlight seek or start auto follow', (
    tester,
  ) async {
    final probe = ViewportProbe(document: viewportDocument(plain: true))
      ..index = 10;
    await mountViewport(tester, probe);
    expect(activeLine(), findsNothing);
    for (final line in tester.widgetList<YYLyricsLine>(
      find.byType(YYLyricsLine),
    )) {
      expect(line.onPressed, isNull);
    }
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(find.text('回到当前歌词'), findsNothing);
    expect(probe.seeks, isEmpty);
  });
  testWidgets(
    'gaps and offsets preserve past and future with no false highlight',
    (tester) async {
      final probe =
          ViewportProbe(
              document: viewportDocument(offset: const Duration(seconds: 10)),
            )
            ..index = null
            ..position = const Duration(milliseconds: 11500);
      await mountViewport(tester, probe);
      expect(activeLine(), findsNothing);
      final lines = tester
          .widgetList<YYLyricsLine>(find.byType(YYLyricsLine))
          .toList();
      expect(
        lines.firstWhere((line) => line.text.startsWith('Line 0 ')).state,
        YYLyricsLineState.past,
      );
      expect(
        lines.firstWhere((line) => line.text == 'Line 1').state,
        YYLyricsLineState.future,
      );
    },
  );
  testWidgets(
    'reduced motion disables every lyric scale while preserving current semantics',
    (tester) async {
      final probe = ViewportProbe();
      final appearance = YYAppearanceController()..setReduceMotion(true);
      addTearDown(appearance.dispose);
      await mountViewport(tester, probe, appearance: appearance);
      final semantics = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(activeLine()).flagsCollection.isSelected,
          ui.Tristate.isTrue,
        );
        for (final scale in tester.widgetList<AnimatedScale>(
          find.descendant(
            of: find.byType(LyricsViewport),
            matching: find.byType(AnimatedScale),
          ),
        )) {
          expect(scale.scale, 1);
          expect(scale.duration, Duration.zero);
        }
      } finally {
        semantics.dispose();
      }
    },
  );
}
