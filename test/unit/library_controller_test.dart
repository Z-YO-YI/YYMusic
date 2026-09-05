import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/catalog_browse.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/library_entities.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/features/library/common/library_controller.dart';

import '../support/fake_domain_repositories.dart';
import '../support/library_graph_fixture.dart';

Future<void> flushLibrary() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late LibraryGraphFixture fixture;
  late LibraryController controller;
  setUp(() async {
    fixture = LibraryGraphFixture();
    controller = fixture.graph.libraryController;
    await fixture.graph.initialize();
  });
  tearDown(() async {
    await fixture.close();
  });
  test('missing storage is an error; empty catalog and public source labels remain honest', () async {
    final absent = DependencyGraph();
    try {
      absent.libraryController.start();
      await flushLibrary();
      expect(absent.libraryController.page.phase, LoadPhase.error);
    } finally {
      await absent.close();
    }
    final empty = LibraryGraphFixture(count: 0);
    try {
      empty.graph.libraryController.start();
      await flushLibrary();
      expect(empty.graph.libraryController.page.phase, LoadPhase.empty);
      await empty.sources.saveSource(
        MusicSourceConfig(
          id: 'local-test',
          name: '已保存的公开来源名',
          type: MusicSourceType.local,
          authType: MusicSourceAuthType.system,
        ),
      );
      await flushLibrary();
      expect(
        empty.graph.libraryController.sourceLabel('local-test'),
        '已保存的公开来源名',
      );
      expect(empty.graph.libraryController.sourceLabel('missing'), '来源未配置');
    } finally {
      await empty.close();
    }
  });
  test(
    'favorite write failure is safe and cannot remove existing catalog rows',
    () async {
      controller.start();
      controller.selectCategory(LibraryCategory.tracks);
      await flushLibrary();
      final gate = Completer<void>();
      fixture.collection.favoriteGate = gate.future;
      final write = controller.toggleFavorite(fixture.tracks.first);
      gate.completeError(StateError('private-credential-error'));
      await write;
      expect(controller.actionError, '操作未完成，请重试。');
      expect(controller.page.items.length, 20);
      expect(controller.busy, isFalse);
      expect(controller.isFavorite(fixture.tracks.first), isFalse);
    },
  );
  test('production root controller reads and favorites through the shared SQLite scope', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final services = await DatabaseAppDataServices.open(database);
    final graph = DependencyGraph(dataServices: services);
    try {
      await services.library.upsertTracks(fixture.tracks);
      final library = graph.libraryController;
      final ready = Completer<void>();
      void changed() {
        if (library.category == LibraryCategory.tracks &&
            library.page.phase == LoadPhase.data &&
            library.canFavorite(fixture.tracks.first) &&
            !ready.isCompleted) {
          ready.complete();
        }
      }

      library.addListener(changed);
      library.start();
      library.selectCategory(LibraryCategory.tracks);
      await ready.future.timeout(const Duration(seconds: 5));
      library.removeListener(changed);
      expect(library.page.items.length, 20);
      expect(library.repository, same(services.library));
      await library.toggleFavorite(fixture.tracks.first);
      final favorites = await services.collection.watchFavorites().first;
      expect(favorites.single.track, fixture.tracks.first.ref);
      expect((await services.collection.loadQueue()).entries, isEmpty);
    } finally {
      await graph.close();
    }
  });
  test(
    'root projection starts once and categories keep independent loaded pages',
    () async {
      controller.start();
      controller.start();
      await flushLibrary();
      expect(controller.page.items.length, 20);
      expect(fixture.repository.calls.length, 1);
      controller.selectCategory(LibraryCategory.tracks);
      await flushLibrary();
      final tracks = controller.page;
      controller.selectCategory(LibraryCategory.artists);
      await flushLibrary();
      controller.selectCategory(LibraryCategory.tracks);
      expect(controller.page, same(tracks));
      expect(fixture.repository.calls.length, 3);
      expect(() => controller.page.items.clear(), throwsUnsupportedError);
    },
  );
  test('typed sorts and directions restart offset without destroying category preferences', () async {
    controller.start();
    await flushLibrary();
    for (final category in [
      LibraryCategory.albums,
      LibraryCategory.tracks,
      LibraryCategory.artists,
      LibraryCategory.local,
    ]) {
      controller.selectCategory(category);
      await flushLibrary();
      for (var i = 0; i < controller.sortLabels.length; i++) {
        controller.setSort(i);
        await flushLibrary();
        controller.toggleDirection();
        await flushLibrary();
        final call = fixture.repository.calls.last;
        expect(call.page.offset, 0);
        final (sort, direction) = switch (call.query) {
          CatalogTrackQuery q => (q.sort.index, q.direction),
          CatalogAlbumQuery q => (q.sort.index, q.direction),
          CatalogArtistQuery q => (q.sort.index, q.direction),
          _ => throw StateError('unexpected query'),
        };
        expect(sort, i);
        expect(direction, controller.page.direction);
      }
      expect(() => controller.setSort(99), throwsArgumentError);
    }
  });
  test(
    'source and availability compose and local category forces local only',
    () async {
      controller.start();
      controller.selectCategory(LibraryCategory.tracks);
      await flushLibrary();
      controller.setSource(LibrarySource.online);
      await flushLibrary();
      expect(
        controller.page.items.whereType<Track>().every(
          (t) => t.sourceType == MusicSourceType.rest,
        ),
        isTrue,
      );
      controller.setAvailability(LibraryAvailability.unavailable);
      await flushLibrary();
      expect(controller.page.phase, LoadPhase.empty);
      controller.selectCategory(LibraryCategory.local);
      await flushLibrary();
      expect(controller.page.items.single, fixture.tracks[2]);
      controller.setSource(LibrarySource.all);
      expect(
        controller.source,
        LibrarySource.online,
      ); // Local override does not erase saved preference.
      final query = fixture.repository.calls.last.query as CatalogTrackQuery;
      expect(query.filter.sourceType, MusicSourceType.local);
      expect(
        query.filter.availability,
        isNot(contains(TrackAvailability.available)),
      );
    },
  );
  test('superseded reads cannot overwrite a new filter even if adapter ignores cancellation', () async {
    final old = Completer<PageResult<Album>>();
    fixture.repository.onAlbums = (_, _, _) => old.future;
    controller.start();
    await flushLibrary();
    final token = fixture.repository.calls.single.cancellation!;
    fixture.repository.onAlbums = null;
    controller.setSource(LibrarySource.local);
    await flushLibrary();
    expect(token.isCancelled, isTrue);
    final page = controller.page.items;
    old.complete(PageResult(items: const [], hasMore: false));
    await flushLibrary();
    expect(controller.page.items, same(page));
    expect(controller.page.loading, isFalse);
  });
  test('page errors preserve content, retry raw offset and deduplicate complete identity', () async {
    controller.start();
    controller.selectCategory(LibraryCategory.tracks);
    await flushLibrary();
    fixture.repository.fail = true;
    await controller.loadMore();
    expect(controller.page.phase, LoadPhase.error);
    expect(controller.page.items.length, 20);
    fixture.repository.fail = false;
    fixture.repository.onTracks = (_, page, _) async {
      expect(page.offset, 20);
      return PageResult(
        items: [fixture.tracks[0], fixture.tracks[20]],
        hasMore: true,
      );
    };
    await controller.loadMore();
    expect(controller.page.items.length, 21);
    fixture.repository.onTracks = (_, page, _) async {
      expect(page.offset, 22);
      return PageResult(items: const [], hasMore: true);
    };
    await controller.loadMore();
    expect(controller.page.hasMore, isFalse);
  });
  test(
    'overlong adapters are bounded and stop after 200 raw entities',
    () async {
      fixture.repository.onTracks = (_, _, _) async =>
          PageResult(items: fixture.tracks, hasMore: true);
      controller.start();
      controller.selectCategory(LibraryCategory.tracks);
      await flushLibrary();
      for (var i = 0; i < 15; i++) {
        await controller.loadMore();
      }
      final calls = fixture.repository.calls
          .where((c) => c.query is CatalogTrackQuery)
          .toList();
      expect(calls.length, 10);
      expect(calls.last.page.offset, 180);
      expect(controller.page.items.length, 20);
      expect(controller.page.capped, isTrue);
    },
  );
  test(
    'playlist stream stays independent of catalog filters and failure',
    () async {
      controller.start();
      await flushLibrary();
      final now = DateTime.utc(2026, 9, 6);
      await fixture.collection.savePlaylist(
        Playlist(id: 'personal', name: '我的歌单', createdAt: now, updatedAt: now),
      );
      controller.selectCategory(LibraryCategory.playlists);
      await flushLibrary();
      expect(controller.page.items.single, isA<Playlist>());
      final calls = fixture.repository.calls.length;
      controller.setSource(LibrarySource.online);
      controller.setAvailability(LibraryAvailability.unavailable);
      controller.setSort(3);
      expect(fixture.repository.calls.length, calls);
      expect(controller.page.items.single, isA<Playlist>());
    },
  );
  test('play uses one root queue and full identity without replacing existing entries', () async {
    controller.start();
    controller.selectCategory(LibraryCategory.tracks);
    await flushLibrary();
    expect(controller.canPlay(fixture.tracks[2]), isFalse);
    await controller.play(fixture.tracks.first);
    await controller.play(fixture.tracks[1]);
    await controller.play(fixture.tracks.first);
    expect(fixture.graph.queue.state.entries.length, 2);
    expect(fixture.engine.calls.where((c) => c == 'play').length, 3);
    expect(
      fixture.graph.playback.state.currentTrack?.ref,
      fixture.tracks.first.ref,
    );
  });
  test(
    'offscreen actions are rejected and leaving during load revokes play',
    () async {
      controller.start();
      controller.selectCategory(LibraryCategory.tracks);
      await flushLibrary();
      expect(controller.canPlay(fixture.tracks.last), isFalse);
      final gate = Completer<void>();
      fixture.engine.loadGate = gate.future;
      final playing = controller.play(fixture.tracks.first);
      await flushLibrary();
      controller.setActive(false);
      gate.complete();
      await playing;
      expect(fixture.engine.calls, isNot(contains('play')));
      expect(controller.canPlay(fixture.tracks.first), isFalse);
      controller.setActive(true);
      expect(controller.canPlay(fixture.tracks.first), isTrue);
    },
  );
  test('favorites use repository truth including unavailable tracks, without changing queue', () async {
    controller.start();
    controller.selectCategory(LibraryCategory.tracks);
    await flushLibrary();
    final missing = fixture.tracks[2];
    expect(controller.canFavorite(missing), isTrue);
    await controller.toggleFavorite(missing);
    await flushLibrary();
    expect(controller.isFavorite(missing), isTrue);
    await controller.toggleFavorite(missing);
    await flushLibrary();
    expect(controller.isFavorite(missing), isFalse);
    expect(fixture.graph.queue.state.entries, isEmpty);
  });
  test('close cancels queries, waits for late results and does not dispose borrowed storage', () async {
    final gate = Completer<PageResult<Album>>();
    fixture.repository.onAlbums = (_, _, _) => gate.future;
    controller.start();
    await flushLibrary();
    var closed = false;
    final closing = controller.close().then((_) => closed = true);
    await flushLibrary();
    expect(closed, isFalse);
    expect(fixture.repository.calls.single.cancellation!.isCancelled, isTrue);
    gate.complete(PageResult(items: const [], hasMore: false));
    await closing;
    expect(fixture.collection.disposeCount, 0);
    expect(controller.page.items, isEmpty);
  });
  test(
    'accepted favorite write is drained before root storage closes',
    () async {
      final gate = Completer<void>();
      final collection = FakeCollectionRepository()..favoriteGate = gate.future;
      final other = LibraryGraphFixture(collections: collection);
      await other.graph.initialize();
      final library = other.graph.libraryController;
      library.start();
      library.selectCategory(LibraryCategory.tracks);
      await flushLibrary();
      final action = library.toggleFavorite(other.tracks.first);
      await flushLibrary();
      var closed = false;
      final closing = other.graph.close().then((_) => closed = true);
      await flushLibrary();
      expect(closed, isFalse);
      gate.complete();
      await action;
      await closing;
      expect(collection.favoriteWriteCount, 1);
      await other.disposeFakes();
    },
  );
}
