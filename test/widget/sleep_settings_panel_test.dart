import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_option_card.dart';
import 'package:yymusic/features/player/common/sleep_settings_panel.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/design_harness.dart';
import '../support/sleep_panel_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  testWidgets('real route cover and uncover revoke pre-cover callbacks', (
    tester,
  ) async {
    final f = SleepPanelFixture();
    final navigator = GlobalKey<NavigatorState>();
    try {
      await tester.pumpWidget(
        designHarness(
          Navigator(
            key: navigator,
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              pageBuilder: (_, _, _) => SleepSettingsPanel(
                presenter: f.presenter,
                platform: YYPlatform.windows,
                isCurrent: () => true,
                onClose: () => f.closes++,
              ),
            ),
          ),
          appearance: f.appearance,
        ),
      );
      await tester.pumpAndSettle();
      final old = tester
          .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-fifteen')))
          .onPressed!;
      final covering = navigator.currentState!.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => const SizedBox.expand(),
        ),
      );
      await tester.pumpAndSettle();
      old();
      expect(f.playback.sleepTimer.phase, PlaybackSleepPhase.off);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      await covering;
      old();
      expect(f.playback.sleepTimer.phase, PlaybackSleepPhase.off);
      await tester.tap(find.byKey(const ValueKey('sleep-fifteen')));
      await tester.pumpAndSettle();
      expect(f.playback.sleepTimer.duration, PlaybackSleepDuration.fifteen);
    } finally {
      await closeSleepPanel(tester, f);
    }
  });
  for (final hidden in ['ticker', 'focus', 'zero']) {
    testWidgets('$hidden revokes retained surface actions', (tester) async {
      final f = SleepPanelFixture();
      try {
        await mountSleepPanel(tester, f);
        final old = tester
            .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-fifteen')))
            .onPressed!;
        await mountSleepPanel(
          tester,
          f,
          tickersEnabled: hidden != 'ticker',
          focusable: hidden != 'focus',
          size: hidden == 'zero' ? Size.zero : const Size(390, 900),
        );
        old();
        expect(f.playback.sleepTimer.phase, PlaybackSleepPhase.off);
        expect(tester.takeException(), isNull);
      } finally {
        await closeSleepPanel(tester, f);
      }
    });
  }
  testWidgets('host removal restores prior focus without canceling sleep', (
    tester,
  ) async {
    final f = SleepPanelFixture();
    final previous = FocusNode();
    var visible = false;
    try {
      await tester.pumpWidget(
        designHarness(
          StatefulBuilder(
            builder: (context, update) => Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: YYButton(
                    label: '打开睡眠设置',
                    focusNode: previous,
                    onPressed: () => update(() => visible = true),
                  ),
                ),
                if (visible)
                  SleepSettingsPanel(
                    presenter: f.presenter,
                    platform: YYPlatform.windows,
                    isCurrent: () => visible,
                    onClose: () => update(() => visible = false),
                  ),
              ],
            ),
          ),
          appearance: f.appearance,
        ),
      );
      previous.requestFocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开睡眠设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sleep-thirty')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SleepSettingsPanel), findsNothing);
      expect(previous.hasFocus, isTrue);
      expect(f.playback.sleepTimer.duration, PlaybackSleepDuration.thirty);
    } finally {
      await closeSleepPanel(tester, f);
      previous.dispose();
    }
  });
  testWidgets('selected and disabled options expose exact native semantics', (
    tester,
  ) async {
    final f = SleepPanelFixture();
    final semantics = tester.ensureSemantics();
    try {
      await mountSleepPanel(tester, f);
      final off = tester
          .getSemantics(find.byKey(const ValueKey('sleep-off')))
          .getSemanticsData();
      expect(off.flagsCollection.isButton, isTrue);
      expect(off.flagsCollection.isSelected, ui.Tristate.isTrue);
      final end = tester
          .getSemantics(find.byKey(const ValueKey('sleep-currentEntry')))
          .getSemanticsData();
      expect(end.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(end.label, contains('请先开始播放当前歌曲'));
    } finally {
      semantics.dispose();
      await closeSleepPanel(tester, f);
    }
  });
  for (final (name, platform, size) in const [
    ('phone', YYPlatform.android, Size(390, 900)),
    ('tablet', YYPlatform.android, Size(800, 1000)),
    ('windows', YYPlatform.windows, Size(1440, 1000)),
  ]) {
    testWidgets('$name applies five real options without audio work', (
      tester,
    ) async {
      final f = SleepPanelFixture();
      await f.start();
      try {
        await mountSleepPanel(tester, f, platform: platform, size: size);
        expect(
          find.byKey(
            ValueKey(name == 'phone' ? 'yy-bottom-sheet' : 'yy-dialog'),
          ),
          findsOneWidget,
        );
        for (final (choice, duration) in [
          ('fifteen', PlaybackSleepDuration.fifteen),
          ('thirty', PlaybackSleepDuration.thirty),
          ('sixty', PlaybackSleepDuration.sixty),
        ]) {
          await tester.tap(find.byKey(ValueKey('sleep-$choice')));
          await tester.pumpAndSettle();
          expect(f.playback.sleepTimer.duration, duration);
          expect(
            tester
                .widget<YYOptionCard>(find.byKey(ValueKey('sleep-$choice')))
                .selected,
            isTrue,
          );
        }
        await tester.tap(find.byKey(const ValueKey('sleep-currentEntry')));
        await tester.pumpAndSettle();
        expect(f.playback.sleepTimer.entryId, 'graph-fixture-entry');
        expect(find.text('本曲结束后暂停'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('sleep-off')));
        await tester.pumpAndSettle();
        expect(f.playback.sleepTimer.phase, PlaybackSleepPhase.off);
        expect(f.engine.calls, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await closeSleepPanel(tester, f);
      }
    });

    testWidgets(
      '$name old selection and close cannot act after permission ends',
      (tester) async {
        final f = SleepPanelFixture();
        try {
          await mountSleepPanel(tester, f, platform: platform, size: size);
          final select = tester
              .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-fifteen')))
              .onPressed!;
          final close = tester
              .widget<YYButton>(find.byKey(const ValueKey('sleep-done')))
              .onPressed!;
          f.current = false;
          select();
          close();
          await tester.pump();
          expect(f.closes, 0);
          expect(f.playback.sleepTimer.phase, PlaybackSleepPhase.off);
          f.current = true;
          select();
          close();
          expect(f.closes, 0);
          expect(f.playback.sleepTimer.phase, PlaybackSleepPhase.off);
        } finally {
          await closeSleepPanel(tester, f);
        }
      },
    );
  }

  testWidgets('empty panel disables current entry but allows minute intent', (
    tester,
  ) async {
    final f = SleepPanelFixture();
    try {
      await mountSleepPanel(tester, f);
      expect(
        tester
            .widget<YYOptionCard>(
              find.byKey(const ValueKey('sleep-currentEntry')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('sleep-fifteen')));
      await tester.pumpAndSettle();
      expect(f.playback.sleepTimer.duration, PlaybackSleepDuration.fifteen);
      expect(f.engine.calls, isEmpty);
    } finally {
      await closeSleepPanel(tester, f);
    }
  });

  testWidgets(
    'rebuild revokes retained callbacks and reflects external intent',
    (tester) async {
      final f = SleepPanelFixture();
      try {
        await mountSleepPanel(tester, f);
        final old = tester
            .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-fifteen')))
            .onPressed!;
        f.playback.setSleepTimer(PlaybackSleepDuration.sixty);
        await tester.pumpAndSettle();
        old();
        expect(f.playback.sleepTimer.duration, PlaybackSleepDuration.sixty);
        expect(
          tester
              .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-sixty')))
              .selected,
          isTrue,
        );
      } finally {
        await closeSleepPanel(tester, f);
      }
    },
  );

  testWidgets(
    'same-frame stale root action reports rejection instead of overwrite',
    (tester) async {
      final f = SleepPanelFixture();
      try {
        await mountSleepPanel(tester, f);
        final old = tester
            .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-fifteen')))
            .onPressed!;
        f.playback.setSleepTimer(PlaybackSleepDuration.sixty);
        old();
        await tester.pumpAndSettle();
        expect(f.playback.sleepTimer.duration, PlaybackSleepDuration.sixty);
        expect(find.text('播放状态已变化，请重新选择。'), findsOneWidget);
      } finally {
        await closeSleepPanel(tester, f);
      }
    },
  );

  testWidgets('failure is visible and contains no raw scheduler detail', (
    tester,
  ) async {
    final f = SleepPanelFixture(schedulerFails: true);
    try {
      await mountSleepPanel(tester, f);
      await tester.tap(find.byKey(const ValueKey('sleep-fifteen')));
      await tester.pumpAndSettle();
      expect(find.text('睡眠定时未完成，请重新设置。'), findsOneWidget);
      expect(find.text('设置未完成，请重新选择。'), findsOneWidget);
      expect(find.textContaining('private-scheduler'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('sleep-off')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sleep-action-error')), findsNothing);
    } finally {
      await closeSleepPanel(tester, f);
    }
  });

  testWidgets('keyboard Tab and Enter select, Esc closes exactly once', (
    tester,
  ) async {
    final f = SleepPanelFixture();
    try {
      await mountSleepPanel(
        tester,
        f,
        platform: YYPlatform.windows,
        size: const Size(1024, 768),
      );
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'YY modal close');
      // Flutter's scrollable may itself take a traversal stop before cards.
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        if (FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<YYOptionCard>()
                ?.title ==
            '15 分钟') {
          break;
        }
      }
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<YYOptionCard>()
            ?.title,
        '15 分钟',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(f.playback.sleepTimer.duration, PlaybackSleepDuration.fifteen);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(f.closes, 1);
      expect(f.playback.sleepTimer.duration, PlaybackSleepDuration.fifteen);
    } finally {
      await closeSleepPanel(tester, f);
    }
  });

  testWidgets('short Android sheet scrolls without overflow at 130 percent', (
    tester,
  ) async {
    final f = SleepPanelFixture();
    await f.start();
    try {
      await mountSleepPanel(tester, f, size: const Size(844, 390));
      expect(find.byKey(const ValueKey('yy-bottom-sheet')), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('sleep-currentEntry')),
      );
      await tester.tap(find.byKey(const ValueKey('sleep-currentEntry')));
      await tester.pumpAndSettle();
      expect(f.playback.sleepTimer.entryId, 'graph-fixture-entry');
      expect(tester.takeException(), isNull);
    } finally {
      await closeSleepPanel(tester, f);
    }
  });

  testWidgets('unmounted callbacks cannot mutate root', (tester) async {
    final f = SleepPanelFixture();
    try {
      await mountSleepPanel(tester, f);
      final old = tester
          .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-fifteen')))
          .onPressed!;
      await tester.pumpWidget(const SizedBox.shrink());
      old();
      expect(f.playback.sleepTimer.phase, PlaybackSleepPhase.off);
    } finally {
      await closeSleepPanel(tester, f);
    }
  });
}
