import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';

import '../support/design_harness.dart';
import '../support/fake_sleep_timer_repository.dart';
import '../support/sleep_panel_harness.dart';
import '../support/sleep_persistence_panel_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final platform in YYPlatform.values) {
    testWidgets('$platform restored timer has honest persistent notice', (
      tester,
    ) async {
      final repo = FakeSleepTimerRepository();
      final f = await persistentSleepFixture(tester, repo);
      try {
        await mountSleepPanel(tester, f, platform: platform);
        expect(find.text('剩余 13:59'), findsOneWidget);
        expect(find.text('分钟定时保留原截止时间；本曲结束仅在本次启动有效。'), findsOneWidget);
        expect(find.byKey(const ValueKey('sleep-storage-retry')), findsNothing);
        expect(f.engine.calls, isEmpty);
      } finally {
        await closePersistentSleepPanel(tester, f, repo);
      }
    });
    testWidgets(
      '$platform retry is once per current failure and old callback is revoked',
      (tester) async {
        final repo = FakeSleepTimerRepository();
        final f = await persistentSleepFixture(
          tester,
          repo,
          state: 'load-failure',
        );
        try {
          await mountSleepPanel(tester, f, platform: platform);
          expect(find.text('未能读取已保存定时，请重试；本次设置仍可使用。'), findsOneWidget);
          final old = tester
              .widget<YYButton>(
                find.byKey(const ValueKey('sleep-storage-retry')),
              )
              .onPressed!;
          old();
          old();
          await settleSleepStorage(tester);
          expect(repo.reads, 2);
          old();
          await settleSleepStorage(tester);
          expect(repo.reads, 2);
          repo.readError = null;
          await tester.ensureVisible(
            find.byKey(const ValueKey('sleep-storage-retry')),
          );
          await tester.tap(find.byKey(const ValueKey('sleep-storage-retry')));
          await settleSleepStorage(tester);
          expect(repo.reads, 3);
          expect(f.persistence!.failure, isNull);
          expect(
            find.byKey(const ValueKey('sleep-storage-retry')),
            findsNothing,
          );
          expect(find.textContaining('private-marker'), findsNothing);
        } finally {
          await closePersistentSleepPanel(tester, f, repo);
        }
      },
    );
    testWidgets('$platform hidden panel revokes retry callback', (
      tester,
    ) async {
      final repo = FakeSleepTimerRepository();
      final f = await persistentSleepFixture(
        tester,
        repo,
        state: 'load-failure',
      );
      try {
        await mountSleepPanel(tester, f, platform: platform);
        final old = tester
            .widget<YYButton>(find.byKey(const ValueKey('sleep-storage-retry')))
            .onPressed!;
        await mountSleepPanel(
          tester,
          f,
          platform: platform,
          tickersEnabled: false,
        );
        old();
        await settleSleepStorage(tester);
        expect(repo.reads, 1);
        expect(tester.takeException(), isNull);
      } finally {
        await closePersistentSleepPanel(tester, f, repo);
      }
    });
  }
}
