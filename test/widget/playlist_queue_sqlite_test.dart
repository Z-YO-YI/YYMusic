import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/playlist_location.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/data/database/app_database.dart';

import '../support/catalog_detail_probe.dart';
import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playlist_content_harness.dart';
import '../support/playlist_content_probe.dart';
import 'library_queue_actions_test.dart' show tapQueueFeedback;

void main() {
  setUpAll(loadDesignAssets);
  for (final unresolved in [false, true]) {
    for (final next in [false, true]) {
      testWidgets(
        'SQLite playlist unresolved=$unresolved next=$next retries and preserves original duplicates',
        (tester) async {
          tester.view.physicalSize = const Size(390, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = AppDatabase(NativeDatabase.memory()),
              track = detailTrack('queue-sql');
          final original = [
            contentItem('sql', 'a', 0, track).entry,
            contentItem('sql', 'b', 1, track).entry,
          ];
          final engine = FakeAudioEngine();
          final graph = (await tester.runAsync(() async {
            final services = await DatabaseAppDataServices.open(db);
            if (!unresolved) await services.library.upsertTracks([track]);
            await services.collection.createPlaylist(contentPlaylist('sql'));
            await services.collection.replacePlaylistEntries('sql', original);
            final graph = DependencyGraph(
              dataServices: services,
              audioEngine: engine,
              playbackSourceResolver: FakePlaybackSourceResolver(),
            );
            await graph.initialize();
            return graph;
          }))!;
          try {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [dependencyGraphProvider.overrideWithValue(graph)],
                child: YYMusicApp(
                  platform: YYPlatform.android,
                  initialLocation: playlistLocation('sql').toString(),
                ),
              ),
            );
            await settleContent(tester);
            expect(
              playlistState(tester).controller.content!.entries[1].track,
              unresolved ? isNull : isNotNull,
            );
            await openEntryMenu(tester, 'b');
            await tester.runAsync(
              () => db.customStatement('''
            CREATE TRIGGER fail_playlist_queue BEFORE INSERT ON queue_entries
            BEGIN SELECT RAISE(ABORT, 'private-marker'); END
          '''),
            );
            await tester.tap(find.text(next ? '下一首播放' : '添加到队列'));
            await settleContent(tester);
            final failure = graph.queue.editFailure!;
            expect(
              (await tester.runAsync(graph.collection!.loadQueue))!.entries,
              isEmpty,
            );
            expect(find.textContaining('private-marker'), findsNothing);
            await tester.runAsync(
              () => db.customStatement('DROP TRIGGER fail_playlist_queue'),
            );
            await tapQueueFeedback(tester, '重试队列操作');
            final saved = (await tester.runAsync(graph.collection!.loadQueue))!;
            expect(
              saved.entries.single.id,
              failure.edit.apply(updatedAt: saved.updatedAt)!.entries.single.id,
            );
            expect(saved.entries.single.track, track.ref);
            expect(saved.currentEntryId, isNull);
            await openEntryMenu(tester, 'a');
            await tester.tap(find.text('添加到队列'));
            await settleContent(tester);
            final duplicate = (await tester.runAsync(
              graph.collection!.loadQueue,
            ))!;
            expect(duplicate.entries.map((e) => e.id).toSet(), hasLength(2));
            expect(
              duplicate.entries.every((e) => e.track == track.ref),
              isTrue,
            );
            expect(duplicate.currentEntryId, isNull);
            final playlist = (await tester.runAsync(
              () => graph.collection!.getPlaylistEntries('sql'),
            ))!;
            expect(
              playlist.map((e) => (e.id, e.position, e.track, e.addedAt)),
              original.map((e) => (e.id, e.position, e.track, e.addedAt)),
            );
            expect(
              await tester.runAsync(() => graph.library!.getTrack(track.ref)),
              unresolved ? isNull : isNotNull,
            );
            expect(engine.calls, isEmpty);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await closeGraph(tester, graph);
          }
        },
      );
    }
  }
}
