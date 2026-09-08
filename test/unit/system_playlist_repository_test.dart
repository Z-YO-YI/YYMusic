import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_collection_repository.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/collection_repository.dart';

import '../support/catalog_detail_probe.dart';
import '../support/fake_domain_repositories.dart';
import '../support/playlist_content_probe.dart';

PlayHistoryEntry systemHistory(String id, TrackRef ref, DateTime time) =>
    PlayHistoryEntry(
      id: id,
      track: ref,
      startedAt: time,
      lastPosition: Duration.zero,
    );

QueueSnapshot systemQueue(List<TrackRef> refs, {String? current}) =>
    QueueSnapshot(
      entries: [
        for (var i = 0; i < refs.length; i++)
          QueueEntry(
            id: 'q-$i',
            track: refs[i],
            position: i,
            addedAt: contentEpoch,
          ),
      ],
      updatedAt: contentEpoch,
      currentEntryId: current,
    );

void main() {
  for (final fake in [false, true]) {
    group(fake ? 'Fake' : 'SQLite', () {
      late CollectionRepository repository;
      late Future<void> Function(List<Track>) catalog;
      late Future<void> Function() close;
      late DateTime now;
      setUp(() async {
        now = contentEpoch;
        if (fake) {
          final value = FakeCollectionRepository(clock: () => now);
          repository = value;
          catalog = (tracks) async => value.setContentTracks(tracks);
          close = value.dispose;
        } else {
          final database = AppDatabase(NativeDatabase.memory());
          final services = await DatabaseAppDataServices.open(database);
          final value = DriftCollectionRepository(database, clock: () => now);
          repository = value;
          catalog = services.library.upsertTracks;
          close = () async {
            await value.dispose();
            await services.dispose();
          };
        }
      });
      tearDown(() => close());
      test(
        'all three virtual views exist empty without persisted parent records',
        () async {
          for (final type in SystemPlaylistType.values) {
            final empty = await repository.readSystemPlaylistContent(
              type,
              PageRequest(offset: 19),
            );
            expect(empty.type, type);
            expect(empty.totalCount, 0);
            expect(empty.entries, isEmpty);
            expect(empty.hasMore, isFalse);
            expect(empty.currentQueueEntryId, isNull);
          }
          expect(await repository.watchPlaylists().first, isEmpty);
        },
      );
      test('favorites sort deterministically with full identity and retain every missing or unavailable reference', () async {
        final tracks = [
          detailTrack('same', source: 'a'),
          detailTrack('same', source: 'a', type: MusicSourceType.rest),
          detailTrack('same', source: 'b', type: MusicSourceType.rest),
          for (final availability in TrackAvailability.values)
            detailTrack(availability.name, availability: availability),
        ];
        await catalog(tracks);
        final missing = detailTrack('missing').ref;
        final ordered = [...tracks.map((t) => t.ref), missing]
          ..sort((a, b) {
            final values = [
              a.sourceType.name.compareTo(b.sourceType.name),
              a.sourceId.compareTo(b.sourceId),
              a.trackId.compareTo(b.trackId),
            ];
            return values.firstWhere((n) => n != 0, orElse: () => 0);
          });
        for (final ref in ordered.reversed) {
          await repository.setFavorite(ref, favorite: true);
        }
        final result = await repository.readSystemPlaylistContent(
          SystemPlaylistType.favorites,
          PageRequest(),
        );
        expect(result.totalCount, tracks.length + 1);
        expect(result.entries.map((e) => e.reference), ordered);
        expect(result.entries.every((e) => e.entryId == null), isTrue);
        expect(
          result.entries.singleWhere((e) => e.reference == missing).track,
          isNull,
        );
        expect(result.entries.where((e) => e.isAvailable).length, 4);
        final tail = await repository.readSystemPlaylistContent(
          SystemPlaylistType.favorites,
          PageRequest(offset: 2, limit: 2),
        );
        expect(
          tail.entries.map((e) => e.reference),
          result.entries.skip(2).take(2).map((e) => e.reference),
        );
        expect(tail.entries.map((e) => e.position), [2, 3]);
        now = contentEpoch.add(const Duration(seconds: 1));
        await repository.setFavorite(ordered.last, favorite: true);
        final newest = await repository.readSystemPlaylistContent(
          SystemPlaylistType.favorites,
          PageRequest(),
        );
        expect(newest.entries.first.reference, ordered.last);
        expect(newest.entries.first.addedAt, now);
        expect(newest.totalCount, ordered.length);
        await repository.setFavorite(ordered.first, favorite: false);
        expect(
          (await repository.readSystemPlaylistContent(
            SystemPlaylistType.favorites,
            PageRequest(),
          )).totalCount,
          ordered.length - 1,
        );
        expect(await repository.watchPlaylists().first, isEmpty);
      });
      test('recent retains 20, replays move full reference to top, and clear never deletes catalog', () async {
        final tracks = List.generate(25, (i) => detailTrack('$i'));
        await catalog(tracks);
        for (var i = 0; i < 25; i++) {
          await repository.recordHistory(
            systemHistory(
              'h-$i',
              tracks[i].ref,
              contentEpoch.add(Duration(seconds: i)),
            ),
          );
        }
        var data = await repository.readSystemPlaylistContent(
          SystemPlaylistType.recent,
          PageRequest(),
        );
        expect(data.totalCount, 20);
        expect(data.entries.first.entryId, 'h-24');
        expect(data.entries.last.entryId, 'h-5');
        await repository.recordHistory(
          systemHistory(
            'replayed',
            tracks[8].ref,
            contentEpoch.add(const Duration(seconds: 30)),
          ),
        );
        data = await repository.readSystemPlaylistContent(
          SystemPlaylistType.recent,
          PageRequest(),
        );
        expect(data.entries.first.entryId, 'replayed');
        expect(
          data.entries.where((e) => e.reference == tracks[8].ref).length,
          1,
        );
        expect(data.totalCount, 20);
        await repository.clearHistory();
        expect(
          (await repository.readSystemPlaylistContent(
            SystemPlaylistType.recent,
            PageRequest(),
          )).entries,
          isEmpty,
        );
        await repository.setFavorite(tracks.first.ref, favorite: true);
        expect(
          (await repository.readSystemPlaylistContent(
            SystemPlaylistType.favorites,
            PageRequest(),
          )).entries.single.track!.ref,
          tracks.first.ref,
        );
      });
      test('queue preserves repeated refs and current ID outside window without mutation', () async {
        final a = detailTrack('a');
        final b = detailTrack(
          'b',
          availability: TrackAvailability.sourceDisabled,
        );
        await catalog([a, b]);
        final refs = [a.ref, a.ref, b.ref, detailTrack('missing').ref];
        await repository.saveQueue(systemQueue(refs, current: 'q-3'));
        final data = await repository.readSystemPlaylistContent(
          SystemPlaylistType.queue,
          PageRequest(limit: 2),
        );
        expect(data.entries.map((e) => e.entryId), ['q-0', 'q-1']);
        expect(data.entries.map((e) => e.reference).toSet().length, 1);
        expect(data.currentQueueEntryId, 'q-3');
        final tail = await repository.readSystemPlaylistContent(
          SystemPlaylistType.queue,
          PageRequest(offset: 2),
        );
        expect(tail.entries.every((e) => !e.isAvailable), isTrue);
        expect(tail.entries.last.track, isNull);
        expect(
          (await repository.loadQueue()).entries.map((e) => e.track),
          refs,
        );
        final beyond = await repository.readSystemPlaylistContent(
          SystemPlaylistType.queue,
          PageRequest(offset: 200),
        );
        expect(beyond.entries, isEmpty);
        expect(beyond.totalCount, 4);
        expect(beyond.currentQueueEntryId, 'q-3');
      });
      test('invalidation is type-specific, has no initial event and stops after cancellation', () async {
        final counts = {for (final type in SystemPlaylistType.values) type: 0};
        final subscriptions = [
          for (final type in SystemPlaylistType.values)
            repository
                .watchSystemPlaylistChanges(type)
                .listen((_) => counts[type] = counts[type]! + 1),
        ];
        addTearDown(() async {
          for (final sub in subscriptions) {
            await sub.cancel();
          }
        });
        await contentTick();
        expect(counts.values, everyElement(0));
        final ref = detailTrack('a').ref;
        await repository.setFavorite(ref, favorite: true);
        await contentTick();
        expect(counts[SystemPlaylistType.favorites], greaterThan(0));
        expect(counts[SystemPlaylistType.recent], 0);
        expect(counts[SystemPlaylistType.queue], 0);
        await repository.recordHistory(systemHistory('h', ref, contentEpoch));
        await repository.saveQueue(systemQueue([ref]));
        await contentTick();
        final before = Map.of(counts);
        await catalog([detailTrack('a')]);
        await contentTick();
        for (final type in SystemPlaylistType.values) {
          expect(counts[type], greaterThan(before[type]!));
        }
        for (final sub in subscriptions) {
          await sub.cancel();
        }
        final cancelled = Map.of(counts);
        await repository.clearHistory();
        await repository.saveQueue(systemQueue([]));
        await repository.setFavorite(ref, favorite: false);
        await contentTick();
        expect(counts, cancelled);
      });
    });
  }
}
