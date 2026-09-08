import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_feedback.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/playlists/common/system_playlist_screen.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/design_harness.dart';
import '../support/playback_history_probe.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';

Future<void> confirmPagePlayback(
  WidgetTester tester,
  SystemPlaylistFixture f,
) async {
  f.engine.events.add(historyState(0));
  f.engine.events.add(historyState(150));
  await settleContent(tester);
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size) in const [
    (YYPlatform.android, Size(390, 1000)),
    (YYPlatform.android, Size(1024, 768)),
    (YYPlatform.windows, Size(1440, 1000)),
  ]) {
    testWidgets(
      '$platform $size recent view moves a truly played track to the top without cancelling audio',
      (tester) async {
        final f = SystemPlaylistFixture();
        await mountSystemPlaylist(
          tester,
          f,
          platform: platform,
          size: size,
          type: SystemPlaylistType.recent,
        );
        final selected = systemState(tester).controller.content!.entries.last;
        await revealSystemRow(tester, selected.identity);
        await tester.tap(systemRow(selected.identity));
        await settleContent(tester);
        expect(
          systemState(tester).controller.content!.entries.first.reference,
          isNot(selected.reference),
        );
        await confirmPagePlayback(tester, f);
        expect(
          systemState(tester).controller.content!.entries.first.reference,
          selected.reference,
        );
        expect(f.graph.playback.state.phase, PlaybackPhase.playing);
        expect(f.graph.playback.state.queue.entries.length, 5);
        expect(f.engine.calls.where((e) => e == 'play').length, 1);
        expect(f.graph.playback.history.failure, isNull);
        expect(tester.takeException(), isNull);
        await closeSystemPlaylist(tester, f);
      },
    );
  }

  testWidgets(
    'safe history error has a working retry without stopping or restarting playback',
    (tester) async {
      final f = SystemPlaylistFixture();
      f.collection.onHistoryRecord = (_) async =>
          throw StateError('private-marker');
      await mountSystemPlaylist(tester, f, type: SystemPlaylistType.recent);
      await f.graph.playback.play();
      await confirmPagePlayback(tester, f);
      expect(find.text('播放历史未保存'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      final banner = tester.widget<YYErrorBanner>(find.byType(YYErrorBanner));
      final before = List.of(f.engine.calls);
      f.collection.onHistoryRecord = null;
      await tester.ensureVisible(find.text('重试保存'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('重试保存'));
      await settleContent(tester);
      expect(find.text('播放历史未保存'), findsNothing);
      expect(f.graph.playback.state.phase, PlaybackPhase.playing);
      expect(f.engine.calls, before);
      banner.onAction!();
      await settleContent(tester);
      expect(f.engine.calls, before);
      await closeSystemPlaylist(tester, f);
    },
  );

  testWidgets(
    'covered history failure callback cannot retry; older failure can be acknowledged',
    (tester) async {
      final f = SystemPlaylistFixture();
      var writes = 0;
      f.collection.onHistoryRecord = (_) async {
        writes++;
        throw StateError('private-marker');
      };
      await mountSystemPlaylist(tester, f, type: SystemPlaylistType.recent);
      await f.graph.playback.play();
      await confirmPagePlayback(tester, f);
      final old = tester.widget<YYErrorBanner>(find.byType(YYErrorBanner));
      final router = GoRouter.of(
        tester.element(find.byType(SystemPlaylistScreen)),
      );
      unawaited(router.push<void>('/design-system'));
      await tester.pumpAndSettle();
      old.onAction!();
      await settleContent(tester);
      expect(writes, 1);
      router.pop();
      await settleContent(tester);
      f.collection.onHistoryRecord = null;
      await f.graph.playback.playEntry('q-4');
      await confirmPagePlayback(tester, f);
      expect(f.graph.playback.history.canRetry, isFalse);
      await tester.ensureVisible(find.text('知道了'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('知道了'));
      await settleContent(tester);
      expect(find.text('播放历史未保存'), findsNothing);
      expect(f.graph.playback.state.phase, PlaybackPhase.playing);
      await closeSystemPlaylist(tester, f);
    },
  );
}
