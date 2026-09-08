import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/pagination.dart';

import '../support/catalog_detail_probe.dart';
import '../support/playlist_content_probe.dart';
import 'system_playlist_repository_test.dart' show systemHistory, systemQueue;

void main() {
  test('virtual system projections survive SQLite reopen without creating parents or changing source data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'yymusic-system-view-',
    );
    final file = File('${directory.path}/catalog.sqlite');
    DatabaseAppDataServices? services;
    try {
      final track = detailTrack('stored');
      services = await DatabaseAppDataServices.open(
        AppDatabase(NativeDatabase(file)),
      );
      await services.library.upsertTracks([track]);
      await services.collection.setFavorite(track.ref, favorite: true);
      await services.collection.recordHistory(
        systemHistory('h', track.ref, contentEpoch),
      );
      await services.collection.saveQueue(
        systemQueue([track.ref, track.ref], current: 'q-1'),
      );
      await services.dispose();
      services = await DatabaseAppDataServices.open(
        AppDatabase(NativeDatabase(file)),
      );
      for (final type in SystemPlaylistType.values) {
        final content = await services.collection.readSystemPlaylistContent(
          type,
          PageRequest(),
        );
        expect(content.totalCount, type == SystemPlaylistType.queue ? 2 : 1);
        expect(content.entries.every((e) => e.track!.ref == track.ref), isTrue);
        expect(
          content.currentQueueEntryId,
          type == SystemPlaylistType.queue ? 'q-1' : null,
        );
      }
      expect(await services.collection.watchPlaylists().first, isEmpty);
      expect(
        (await services.library.getTrack(track.ref))!.localPath,
        track.localPath,
      );
    } finally {
      await services?.dispose();
      // Only exact fixture files in the newly created test directory; no recursive deletion.
      for (final suffix in ['', '-wal', '-shm']) {
        final fixture = File('${file.path}$suffix');
        if (await fixture.exists()) await fixture.delete();
      }
      await directory.delete();
    }
  });
}
