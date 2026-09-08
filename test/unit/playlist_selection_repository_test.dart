import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_collection_repository.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/playlist_name_query.dart';
import 'package:yymusic/domain/repositories/collection_repository.dart';

import '../support/catalog_detail_probe.dart';
import '../support/fake_domain_repositories.dart';
import '../support/playlist_content_probe.dart';
import '../support/search_query_probe.dart';

void main() {
  test('root close drains a real SQLite selection future before closing its shared database', () async {
    final probe = SearchQueryProbe();
    final database = AppDatabase(NativeDatabase.memory().interceptWith(probe));
    final services = await DatabaseAppDataServices.open(database);
    final graph = DependencyGraph(dataServices: services);
    addTearDown(graph.close);
    await graph.initialize();
    await services.collection.createPlaylist(contentPlaylist('sql'));
    final entered = Completer<void>(), gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    probe.afterSelect = () async {
      if (!entered.isCompleted) entered.complete();
      await gate.future;
    };
    final picker = graph.playlistAdds.open(detailTrack('t').ref, title: '歌曲')
      ..start();
    await entered.future.timeout(const Duration(seconds: 5));
    final closing = graph.close();
    await contentTick();
    expect(probe.closeCount, 0);
    expect(graph.playlistAdds.retainedSessionCount, 1);
    probe.afterSelect = null;
    gate.complete();
    await closing;
    expect(probe.closeCount, 1);
    expect(graph.playlistAdds.retainedSessionCount, 0);
    expect(picker.canAdd('sql'), isFalse);
  });
  test(
    'filter is literal bounded and ASCII-folded, IDs use Unicode scalar order',
    () {
      expect(PlaylistNameQuery('   ').text, '');
      expect(PlaylistNameQuery(' AbC ').folded, 'abc');
      expect(PlaylistNameQuery('中').matches('歌曲中文'), isTrue);
      expect(PlaylistNameQuery('%_').matches('anything'), isFalse);
      expect(PlaylistNameQuery('ä').matches('Ä'), isFalse);
      expect(PlaylistNameQuery('a' * 512).text.length, 512);
      for (final value in ['a' * 513, 'a\n', '\u007f', '\u0085']) {
        expect(() => PlaylistNameQuery(value), throwsArgumentError);
      }
      expect(PlaylistNameQuery.compareIds('\ue000', '😀'), lessThan(0));
    },
  );
  for (final sqlite in [true, false]) {
    group(sqlite ? 'SQLite selection' : 'Fake selection', () {
      late CollectionRepository repository;
      setUp(() {
        if (sqlite) {
          final db = AppDatabase(NativeDatabase.memory());
          final store = DriftCollectionRepository(db);
          repository = store;
          addTearDown(() async {
            await store.dispose();
            await db.close();
          });
        } else {
          final store = FakeCollectionRepository();
          repository = store;
          addTearDown(store.dispose);
        }
      });
      test('custom-only deterministic windows and literal filtering', () async {
        await repository.savePlaylist(
          Playlist(
            id: 'system',
            name: '夜间混音',
            createdAt: contentEpoch,
            updatedAt: contentEpoch,
            isSystem: true,
            systemType: SystemPlaylistType.favorites,
          ),
        );
        for (final (id, name) in [
          ('z', 'Acoustic'),
          ('a', "夜间%_混音'--"),
          ('😀', '夜间'),
          ('\ue000', '夜间'),
        ]) {
          await repository.createPlaylist(contentPlaylist(id, name: name));
        }
        final first = await repository.readCustomPlaylists(
          PlaylistNameQuery(''),
          PageRequest(limit: 2),
        );
        expect(first.items.map((p) => p.id), ['a', 'z']);
        expect(first.hasMore, isTrue);
        final tail = await repository.readCustomPlaylists(
          PlaylistNameQuery(''),
          PageRequest(offset: 2, limit: 2),
        );
        expect(tail.items.map((p) => p.id), ['\ue000', '😀']);
        expect(tail.hasMore, isFalse);
        expect(() => first.items.clear(), throwsUnsupportedError);
        expect(
          (await repository.readCustomPlaylists(
            PlaylistNameQuery('ACOU'),
            PageRequest(),
          )).items.single.id,
          'z',
        );
        expect(
          (await repository.readCustomPlaylists(
            PlaylistNameQuery("%_混音'--"),
            PageRequest(),
          )).items.single.id,
          'a',
        );
        expect(
          (await repository.readCustomPlaylists(
            PlaylistNameQuery('nomatch'),
            PageRequest(),
          )).items,
          isEmpty,
        );
        expect(
          (await repository.readCustomPlaylists(
            PlaylistNameQuery(''),
            PageRequest(offset: 99),
          )).hasMore,
          isFalse,
        );
      });
      test('newer metadata sorts first and deletion is reflected without track reads', () async {
        await repository.createPlaylist(contentPlaylist('old'));
        await repository.createPlaylist(
          Playlist(
            id: 'new',
            name: '新歌单',
            createdAt: contentEpoch,
            updatedAt: contentEpoch.add(const Duration(seconds: 1)),
          ),
        );
        expect(
          (await repository.readCustomPlaylists(
            PlaylistNameQuery(''),
            PageRequest(),
          )).items.first.id,
          'new',
        );
        await repository.deletePlaylist('new');
        expect(
          (await repository.readCustomPlaylists(
            PlaylistNameQuery(''),
            PageRequest(),
          )).items.single.id,
          'old',
        );
      });
    });
  }
  test(
    'one bound SQL returns only limit+1 rows and does not decode the sentinel',
    () async {
      final probe = SearchQueryProbe();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
      final repository = DriftCollectionRepository(db);
      addTearDown(() async {
        await repository.dispose();
        await db.close();
      });
      for (var i = 0; i < 250; i++) {
        await repository.createPlaylist(
          contentPlaylist('p-${i.toString().padLeft(3, '0')}', name: 'Mix %_'),
        );
      }
      // Sentinel is beyond the visible window, so corrupted metadata is not decoded.
      await db.customStatement(
        'UPDATE playlists SET name = ? WHERE playlist_id = ?',
        [' ', 'p-201'],
      );
      probe.selects.clear();
      final result = await repository.readCustomPlaylists(
        PlaylistNameQuery(''),
        PageRequest(offset: 198, limit: 3),
      );
      expect(result.items.map((p) => p.id), ['p-198', 'p-199', 'p-200']);
      expect(result.hasMore, isTrue);
      expect(probe.selects.single.rows, 4);
      expect(probe.selects.single.args, ['', 4, 198]);
      probe.selects.clear();
      await repository.readCustomPlaylists(
        PlaylistNameQuery("%_'--"),
        PageRequest(limit: 2),
      );
      expect(probe.selects.single.args, ["%_'--", 3, 0]);
      expect(probe.selects.single.sql, isNot(contains("%_'--")));
      expect(
        probe.selects.single.sql.toLowerCase(),
        isNot(contains('playlist_entries')),
      );
    },
  );
}
