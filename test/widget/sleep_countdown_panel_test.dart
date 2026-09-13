import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_option_card.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/design_harness.dart';
import '../support/sleep_panel_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final platform in YYPlatform.values) {
    for (final hidden in ['ticker', 'focus', 'close']) {
      testWidgets('panel countdown $platform $hidden keeps root deadline', (
        tester,
      ) async {
        var now = DateTime.utc(2026, 9, 13);
        final f = SleepPanelFixture(clock: () => now);
        try {
          await mountSleepPanel(tester, f, platform: platform);
          await tester.tap(find.byKey(const ValueKey('sleep-fifteen')));
          await tester.pumpAndSettle();
          expect(find.text('剩余 15:00'), findsOneWidget);
          final before = f.playback.sleepTimer;
          final old = tester
              .widget<YYOptionCard>(find.byKey(const ValueKey('sleep-thirty')))
              .onPressed!;
          now = now.add(const Duration(seconds: 61));
          await tester.pump(const Duration(seconds: 1));
          expect(find.text('剩余 13:59'), findsOneWidget);
          expect(identical(before, f.playback.sleepTimer), isTrue);
          expect(f.presenter.selectedSleepChoice?.name, 'fifteen');
          // Text refresh must not revoke the parent's captured option action.
          old();
          await tester.pumpAndSettle();
          expect(f.playback.sleepTimer.duration, PlaybackSleepDuration.thirty);
          expect(find.text('剩余 30:00'), findsOneWidget);
          final reset = f.playback.sleepTimer;
          if (hidden == 'close') {
            await tester.tap(find.byKey(const ValueKey('sleep-done')));
          } else {
            await mountSleepPanel(
              tester,
              f,
              platform: platform,
              tickersEnabled: hidden != 'ticker',
              focusable: hidden != 'focus',
            );
          }
          now = now.add(const Duration(seconds: 123));
          await tester.pump(const Duration(seconds: 2));
          expect(find.textContaining('剩余'), findsNothing);
          expect(identical(reset, f.playback.sleepTimer), isTrue);
          if (hidden != 'close') {
            await mountSleepPanel(tester, f, platform: platform);
            expect(find.text('剩余 27:57'), findsOneWidget);
          }
          expect(f.engine.calls, isEmpty);
          expect(tester.takeException(), isNull);
        } finally {
          await closeSleepPanel(tester, f);
        }
      });
    }
  }
}
