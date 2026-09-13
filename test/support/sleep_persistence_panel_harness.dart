import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/sleep_timer_snapshot.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../unit/sleep_persistence_controller_test.dart'
    show flushSleepPersistence;
import 'fake_sleep_timer_repository.dart';
import 'sleep_panel_harness.dart';

Future<SleepPanelFixture> persistentSleepFixture(
  WidgetTester tester,
  FakeSleepTimerRepository repo, {
  String state = 'restored',
}) async {
  late SleepPanelFixture fixture;
  await tester.runAsync(() async {
    if (state == 'restored') {
      repo.stored = SleepTimerSnapshot(
        durationMinutes: 15,
        deadline: DateTime.utc(
          2026,
          9,
          13,
        ).add(const Duration(minutes: 13, seconds: 59)),
      );
    }
    if (state == 'load-failure') repo.readError = StateError('private-marker');
    fixture = SleepPanelFixture(repository: repo);
    await fixture.persistence!.initialize();
    if (state == 'save-failure') {
      repo.writeError = StateError('private-marker');
      fixture.playback.setSleepTimer(PlaybackSleepDuration.fifteen);
      await flushSleepPersistence();
    }
  });
  return fixture;
}

Future<void> settleSleepStorage(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump();
    await tester.runAsync(flushSleepPersistence);
  }
  await tester.pumpAndSettle();
}

Future<void> closePersistentSleepPanel(
  WidgetTester tester,
  SleepPanelFixture fixture,
  FakeSleepTimerRepository repo,
) async {
  repo.readError = null;
  repo.writeError = null;
  final storage = fixture.persistence!;
  if (storage.canRetry) storage.retry(storage.failure!);
  await settleSleepStorage(tester);
  await closeSleepPanel(tester, fixture);
  await repo.dispose();
}
