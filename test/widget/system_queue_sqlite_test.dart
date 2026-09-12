import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/system_playlist_location.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';

import '../support/catalog_detail_probe.dart';
import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_audio_engine.dart';
import '../support/fake_playback_dependencies.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/playlist_content_probe.dart';
import '../support/system_playlist_harness.dart';
import 'library_queue_actions_test.dart' show tapQueueFeedback;
import 'system_queue_actions_test.dart' show openSystemQueueMenu;

void main() {
  setUpAll(loadDesignAssets);
  for (final type in [
    SystemPlaylistType.favorites,
    SystemPlaylistType.recent,
  ]) {
    for (final unresolved in [false, true]) {
      for (final next in [false, true]) {
        testWidgets(
          'SQLite $type unresolved=$unresolved next=$next preserves history/favorites through failure and retry',
          (tester) async {
            tester.view.physicalSize = const Size(390, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final db = AppDatabase(NativeDatabase.memory()),
                track = detailTrack('queue-sql');
            final engine = FakeAudioEngine();
            final graph = (await tester.runAsync(() async {
              final services = await DatabaseAppDataServices.open(db);
              if (!unresolved) await services.library.upsertTracks([track]);
              await services.collection.setFavorite(track.ref, favorite: true);
              await services.collection.recordHistory(
                PlayHistoryEntry(
                  id: 'original-history',
                  track: track.ref,
                  startedAt: contentEpoch,
                  lastPosition: const Duration(seconds: 42),
                ),
              );
              final graph = DependencyGraph(
                dataServices: services,
                audioEngine: engine,
                playbackSourceResolver: FakePlaybackSourceResolver(),
              );
              await graph.initialize();
              return graph;
            }))!;
            try {
              final favorites = (await tester.runAsync(
                () => graph.collection!.watchFavorites().first,
              ))!;
              final history = (await tester.runAsync(
                () => graph.collection!.watchHistory().first,
              ))!;
              await tester.pumpWidget(
                ProviderScope(
                  overrides: [dependencyGraphProvider.overrideWithValue(graph)],
                  child: YYMusicApp(
                    platform: YYPlatform.android,
                    initialLocation: systemPlaylistLocation(type).toString(),
                  ),
                ),
              );
              await settleContent(tester);
              final source = systemState(tester)
                  .controller
                  .content!
                  .entries
                  .single;
              expect(source.track, unresolved ? isNull : isNotNull);
              await openSystemQueueMenu(tester, id: source.identity);
              await tester.runAsync(
                () => db.customStatement('''
              CREATE TRIGGER fail_system_queue BEFORE INSERT ON queue_entries
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
                () => db.customStatement('DROP TRIGGER fail_system_queue'),
              );
              await tapQueueFeedback(tester, '重试队列操作');
              final saved = (await tester.runAsync(
                graph.collection!.loadQueue,
              ))!;
              expect(
                saved.entries.single.id,
                failure.edit
                    .apply(updatedAt: saved.updatedAt)!
                    .entries
                    .single
                    .id,
              );
              expect(saved.entries.single.id, isNot(source.entryId));
              expect(saved.entries.single.track, track.ref);
              expect(saved.currentEntryId, isNull);
              await openSystemQueueMenu(tester, id: source.identity);
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
              final afterFavorites = (await tester.runAsync(
                () => graph.collection!.watchFavorites().first,
              ))!;
              final afterHistory = (await tester.runAsync(
                () => graph.collection!.watchHistory().first,
              ))!;
              expect(
                afterFavorites.map((e) => (e.track, e.addedAt)),
                favorites.map((e) => (e.track, e.addedAt)),
              );
              expect(
                afterHistory.map(
                  (e) => (e.id, e.track, e.startedAt, e.lastPosition),
                ),
                history.map(
                  (e) => (e.id, e.track, e.startedAt, e.lastPosition),
                ),
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
}
