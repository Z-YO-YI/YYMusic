import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/features/queue/common/queue_screen.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';

const acknowledge = ValueKey('queue-playback-acknowledge');
const details = ValueKey('queue-playback-details');
const feedback = ValueKey('queue-playback-feedback');

Future<void> createSkippedRecord(SystemPlaylistFixture fixture) async {
  await fixture.initialize();
  await fixture.graph.playback.playEntry('q-1');
  await fixture.graph.playback.skipNext();
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size) in const [
    (YYPlatform.android, Size(360, 800)),
    (YYPlatform.android, Size(1280, 800)),
    (YYPlatform.windows, Size(1024, 720)),
  ]) {
    testWidgets('real queue feedback and acknowledgement $platform $size', (
      tester,
    ) async {
      final f = SystemPlaylistFixture();
      await createSkippedRecord(f);
      await mountSystemPlaylist(
        tester,
        f,
        location: '/queue',
        platform: platform,
        size: size,
      );
      expect(find.byKey(feedback), findsOneWidget);
      await tester.tap(find.byKey(details));
      await settleContent(tester);
      expect(find.textContaining('本地文件已失效'), findsOneWidget);
      final queue = f.graph.queue.state;
      final commands = List<String>.of(f.engine.calls);
      await tester.tap(find.byKey(acknowledge));
      await settleContent(tester);
      expect(find.byKey(feedback), findsNothing);
      expect(f.graph.queue.state, same(queue));
      expect(f.engine.calls, commands);
      expect(tester.takeException(), isNull);
      await closeSystemPlaylist(tester, f);
    });
  }

  testWidgets('old acknowledgement cannot discard a later diagnostic', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    await createSkippedRecord(f);
    await mountSystemPlaylist(tester, f, location: '/queue');
    final stale = tester.widget<YYButton>(find.byKey(acknowledge)).onPressed!;
    final old = f.graph.queue.playbackFailures;
    await createSkippedRecord(f);
    await settleContent(tester);
    stale();
    f.graph.queue.acknowledgePlaybackFailures(old);
    expect(f.graph.queue.playbackFailures.length, 2);
    await closeSystemPlaylist(tester, f);
  });

  testWidgets('leaving queue revokes old feedback actions', (tester) async {
    final f = SystemPlaylistFixture();
    await createSkippedRecord(f);
    await mountSystemPlaylist(tester, f, location: '/queue');
    final stale = tester.widget<YYButton>(find.byKey(acknowledge)).onPressed!;
    tester
        .widget<QueueScreen>(find.byType(QueueScreen))
        .navigation
        .goTo(AppRoute.home);
    await settleContent(tester);
    stale();
    expect(f.graph.queue.playbackFailures.length, 1);
    await closeSystemPlaylist(tester, f);
  });

  testWidgets('removed entry keeps safe diagnostic without stale metadata', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    await createSkippedRecord(f);
    await f.graph.queue.remove('q-2');
    await mountSystemPlaylist(tester, f, location: '/queue');
    await tester.tap(find.byKey(details));
    await settleContent(tester);
    expect(find.textContaining('已移出队列的曲目'), findsOneWidget);
    expect(find.textContaining('q-2'), findsNothing);
    await closeSystemPlaylist(tester, f);
  });

  testWidgets('short phone layout scrolls feedback controls into view', (
    tester,
  ) async {
    final f = SystemPlaylistFixture();
    await createSkippedRecord(f);
    await mountSystemPlaylist(
      tester,
      f,
      location: '/queue',
      size: const Size(568, 320),
    );
    final scroll = tester
        .state<QueueScreenState>(find.byType(QueueScreen))
        .scroll;
    for (var i = 0; i < 10 && find.byKey(details).evaluate().isEmpty; i++) {
      scroll.jumpTo(
        (scroll.offset + 80).clamp(0, scroll.position.maxScrollExtent),
      );
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byKey(details));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(details));
    await settleContent(tester);
    await tester.ensureVisible(find.byKey(acknowledge));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(acknowledge));
    await settleContent(tester);
    expect(f.graph.queue.playbackFailures, isEmpty);
    expect(tester.takeException(), isNull);
    await closeSystemPlaylist(tester, f);
  });
}
