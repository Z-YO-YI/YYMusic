import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/playback/playback_favorite_controller.dart';

import '../support/catalog_detail_probe.dart';
import '../support/fake_audio_engine.dart';
import '../support/playlist_content_probe.dart';
import 'playback_favorite_test.dart' show waitFavorite;

void main() {
  for (final unresolved in [false, true]) {
    for (final add in [false, true]) {
      test(
        'SQLite current favorite unresolved=$unresolved add=$add rollback/retry preserves queue and foreign source',
        () async {
          final db = AppDatabase(NativeDatabase.memory());
          final services = await DatabaseAppDataServices.open(db);
          final track = detailTrack('shared-id'),
              foreign = detailTrack('shared-id', source: 'other');
          if (!unresolved) {
            await services.library.upsertTracks([track, foreign]);
          }
          await services.collection.setFavorite(foreign.ref, favorite: true);
          if (!add) {
            await services.collection.setFavorite(track.ref, favorite: true);
          }
          await services.collection.recordHistory(
            PlayHistoryEntry(
              id: 'h',
              track: track.ref,
              startedAt: contentEpoch,
              lastPosition: const Duration(seconds: 37),
            ),
          );
          await services.collection.saveQueue(
            QueueSnapshot(
              entries: [
                QueueEntry(
                  id: 'first',
                  track: track.ref,
                  position: 0,
                  addedAt: contentEpoch,
                ),
                QueueEntry(
                  id: 'duplicate',
                  track: track.ref,
                  position: 1,
                  addedAt: contentEpoch,
                ),
              ],
              currentEntryId: 'duplicate',
              updatedAt: contentEpoch,
            ),
          );
          final engine = FakeAudioEngine();
          final graph = DependencyGraph(
            dataServices: services,
            audioEngine: engine,
          );
          addTearDown(graph.close);
          await graph.initialize();
          final c = graph.playbackFavorite;
          await waitFavorite(c, () => c.ready);
          expect(c.state.entryId, 'duplicate');
          expect(c.state.isFavorite, !add);
          final beforeQueue = await services.collection.loadQueue();
          final beforeHistory = await services.collection.watchHistory().first;
          final beforeFavorites = await services.collection
              .watchFavorites()
              .first;
          await db.customStatement('''
          CREATE TRIGGER fail_current_favorite BEFORE ${add ? 'INSERT' : 'DELETE'} ON favorites
          BEGIN SELECT RAISE(ABORT, 'private-marker'); END
        ''');
          expect(
            await c.setFavorite(c.state, favorite: add),
            PlaybackFavoriteEditResult.failed,
          );
          final failure = c.failure!;
          final failedFavorites = await services.collection
              .watchFavorites()
              .first;
          expect(
            failedFavorites.map((e) => (e.track, e.addedAt)),
            beforeFavorites.map((e) => (e.track, e.addedAt)),
          );
          expect(failure.message, isNot(contains('private-marker')));
          await db.customStatement('DROP TRIGGER fail_current_favorite');
          expect(await c.retry(failure), PlaybackFavoriteEditResult.applied);
          await waitFavorite(c, () => c.state.isFavorite == add);
          final favorites = await services.collection.watchFavorites().first;
          expect(favorites.any((e) => e.track == track.ref), add);
          expect(
            favorites.singleWhere((e) => e.track == foreign.ref).addedAt,
            beforeFavorites.singleWhere((e) => e.track == foreign.ref).addedAt,
          );
          final afterQueue = await services.collection.loadQueue();
          expect(
            afterQueue.entries.map(
              (e) => (e.id, e.track, e.position, e.addedAt),
            ),
            beforeQueue.entries.map(
              (e) => (e.id, e.track, e.position, e.addedAt),
            ),
          );
          expect(afterQueue.currentEntryId, beforeQueue.currentEntryId);
          expect(afterQueue.updatedAt, beforeQueue.updatedAt);
          expect(
            (await services.collection.watchHistory().first).map(
              (e) => (e.id, e.track, e.startedAt, e.lastPosition),
            ),
            beforeHistory.map(
              (e) => (e.id, e.track, e.startedAt, e.lastPosition),
            ),
          );
          final old = c.state;
          await services.collection.setFavorite(track.ref, favorite: !add);
          await waitFavorite(c, () => c.state.isFavorite == !add);
          expect(
            await c.setFavorite(old, favorite: !add),
            PlaybackFavoriteEditResult.cancelled,
          );
          expect(
            await services.library.getTrack(track.ref),
            unresolved ? isNull : isNotNull,
          );
          expect(engine.calls, isEmpty);
        },
      );
    }
  }
}
