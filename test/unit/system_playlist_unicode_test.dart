import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_collection_repository.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/repositories/collection_repository.dart';

import '../support/catalog_detail_probe.dart';
import '../support/fake_domain_repositories.dart';
import '../support/playlist_content_probe.dart';
import 'system_playlist_repository_test.dart' show systemHistory;

void main() {
  for (final fake in [false, true]) {
    test(
      '${fake ? 'Fake' : 'SQLite'} Unicode ties use database binary ordering, not UTF-16 code units',
      () async {
        final tracks = [detailTrack('x\u{10000}'), detailTrack('x\uE000')];
        late CollectionRepository repository;
        if (fake) {
          final value = FakeCollectionRepository(
            contentTracks: tracks,
            clock: () => contentEpoch,
          );
          repository = value;
          addTearDown(value.dispose);
        } else {
          final database = AppDatabase(NativeDatabase.memory());
          final services = await DatabaseAppDataServices.open(database);
          final value = DriftCollectionRepository(
            database,
            clock: () => contentEpoch,
          );
          repository = value;
          addTearDown(() async {
            await value.dispose();
            await services.dispose();
          });
          await services.library.upsertTracks(tracks);
        }
        for (final track in tracks) {
          await repository.setFavorite(track.ref, favorite: true);
          await repository.recordHistory(
            systemHistory(track.id, track.ref, contentEpoch),
          );
        }
        for (final type in [
          SystemPlaylistType.favorites,
          SystemPlaylistType.recent,
        ]) {
          final data = await repository.readSystemPlaylistContent(
            type,
            PageRequest(),
          );
          expect(data.entries.map((e) => e.reference.trackId), [
            'x\uE000',
            'x\u{10000}',
          ]);
        }
      },
    );
  }
}
