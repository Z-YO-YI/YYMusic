import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/playback_sleep_action.dart';
import 'package:yymusic/features/player/common/sleep_remaining_text.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/design_harness.dart';
import '../support/sleep_panel_harness.dart';

void main() {
  setUpAll(loadDesignAssets);

  for (final scenario in [
    'clock',
    'hidden',
    'owner',
    'throw',
    'background',
    'reset',
    'zero',
    'unmount',
  ]) {
    testWidgets('countdown $scenario preserves root ownership', (tester) async {
      var now = DateTime.utc(2026, 9, 13);
      final f = SleepPanelFixture(clock: () => now);
      var active = true;
      var throws = false;
      Future<void> mount() async {
        await tester.pumpWidget(
          designHarness(
            SleepRemainingText(
              presenter: f.presenter,
              active: active,
              isCurrent: () {
                if (throws) throw StateError('revoked');
                return f.current;
              },
            ),
            appearance: f.appearance,
          ),
        );
        await tester.pump();
      }

      try {
        f.playback.setSleepTimer(PlaybackSleepDuration.fifteen);
        final original = f.playback.sleepTimer;
        final action = f.presenter.sleepAction(
          PlaybackSleepChoice.thirty,
          isCurrent: () => true,
        )!;
        var notifications = 0;
        f.presenter.addListener(() => notifications++);
        await mount();
        expect(find.text('剩余 15:00'), findsOneWidget);
        expect(
          tester
              .widget<Semantics>(find.byType(Semantics).last)
              .properties
              .liveRegion,
          isFalse,
        );
        now = now.add(const Duration(seconds: 61));
        switch (scenario) {
          case 'clock':
            await tester.pump(const Duration(seconds: 1));
            expect(find.text('剩余 13:59'), findsOneWidget);
            now = now.subtract(const Duration(seconds: 120));
            await tester.pump(const Duration(seconds: 1));
            expect(find.text('剩余 15:59'), findsOneWidget);
          case 'hidden':
            active = false;
            await mount();
            await tester.pump(const Duration(seconds: 3));
            expect(find.textContaining('剩余'), findsNothing);
            active = true;
            await mount();
            expect(find.text('剩余 13:59'), findsOneWidget);
          case 'owner':
          case 'throw':
            f.current = false;
            throws = scenario == 'throw';
            await tester.pump(const Duration(seconds: 1));
            expect(find.textContaining('剩余'), findsNothing);
            f.current = true;
            throws = false;
            await mount();
            expect(find.text('剩余 13:59'), findsOneWidget);
          case 'background':
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            await tester.pump();
            await tester.pump(const Duration(seconds: 2));
            expect(find.textContaining('剩余'), findsNothing);
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.paused,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await tester.pump();
            await tester.pump();
            expect(find.text('剩余 13:59'), findsOneWidget);
          case 'reset':
            f.playback.setSleepTimer(null);
            await tester.pump();
            await tester.pump();
            expect(find.textContaining('剩余'), findsNothing);
            f.playback.setSleepTimer(PlaybackSleepDuration.sixty);
            await tester.pump();
            await tester.pump();
            expect(find.text('剩余 60:00'), findsOneWidget);
          case 'zero':
            now = now.add(const Duration(hours: 1));
            await tester.pump(const Duration(seconds: 1));
            expect(find.text('剩余 00:00'), findsOneWidget);
          case 'unmount':
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(seconds: 3));
        }
        if (scenario != 'reset') {
          expect(identical(f.playback.sleepTimer, original), isTrue);
          expect(notifications, 0);
          expect(action(), PlaybackSleepActionResult.accepted);
        }
        expect(f.engine.calls, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await closeSleepPanel(tester, f);
      }
    });
  }
}
