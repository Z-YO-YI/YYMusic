import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_probe.dart';
import 'catalog_detail_actions_test.dart' show drainDetail;

final class ReentrantListenStream<T> extends Stream<T> {
  ReentrantListenStream(this.source, this.afterListen);
  final Stream<T> source;
  final void Function() afterListen;

  @override
  StreamSubscription<T> listen(
    void Function(T)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = source.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    afterListen();
    return subscription;
  }
}

void main() {
  test('read-only detail never subscribes to favorites; unavailable visible full references can be toggled', () async {
    final f = CatalogDetailGraphFixture();
    addTearDown(f.close);
    await f.initialize();
    final baseline = f.collection.favoriteWatchCount;
    final c = f.graph.catalogDetails.open(AlbumDetailTarget(f.album.ref));
    await c.start();
    await c.refresh();
    expect(f.collection.favoriteWatchCount, baseline);
    final missing = f.repository.trackData[2];
    expect(c.canFavorite(missing.ref), isFalse);
    c.prepareTrackActions();
    await drainDetail();
    expect(c.favoritesReady, isTrue);
    expect(c.canFavorite(missing.ref), isTrue);
    expect(c.canPlay(missing.ref), isFalse);
    final foreign = detailTrack(missing.id, source: 'other-source');
    expect(c.canFavorite(foreign.ref), isFalse);
    await c.toggleFavorite(missing.ref);
    await drainDetail();
    expect(c.isFavorite(missing.ref), isTrue);
    expect(c.isFavorite(foreign.ref), isFalse);
    expect(
      (await f.collection.watchFavorites().first).single.track,
      missing.ref,
    );
    await c.toggleFavorite(missing.ref);
    await drainDetail();
    expect(c.isFavorite(missing.ref), isFalse);
    expect(f.collection.favoriteWriteCount, 2);
    c.setActive(false);
    await c.toggleFavorite(missing.ref);
    expect(f.collection.favoriteWriteCount, 2);
    expect(f.engine.calls, isEmpty);
  });

  test(
    'unknown favorites fail closed and retry independently of loaded catalog',
    () async {
      final f = CatalogDetailGraphFixture();
      addTearDown(f.close);
      await f.initialize();
      f.collection.favoriteReader = () =>
          Stream.error(StateError('private-marker'));
      final c = f.graph.catalogDetails.open(AlbumDetailTarget(f.album.ref));
      await c.start();
      final reads = f.repository.calls.length;
      c.prepareTrackActions();
      await drainDetail();
      expect(c.favoritesReady, isFalse);
      expect(c.favoriteError, '收藏状态读取失败，请重试。');
      expect(c.canFavorite(f.repository.trackData.first.ref), isFalse);
      expect(c.summary.phase, LoadPhase.data);
      f.collection.favoriteReader = null;
      c.retryFavorites();
      await drainDetail();
      expect(c.favoritesReady, isTrue);
      expect(c.favoriteError, isNull);
      expect(f.repository.calls.length, reads);
    },
  );

  test(
    'duplicate favorite commands are ignored while a failed write is pending',
    () async {
      final f = CatalogDetailGraphFixture();
      addTearDown(f.close);
      await f.initialize();
      final c = f.graph.catalogDetails.open(AlbumDetailTarget(f.album.ref));
      await c.start();
      c.prepareTrackActions();
      await drainDetail();
      final reference = f.repository.trackData.first.ref;
      final gate = Completer<void>();
      f.collection.favoriteGate = gate.future;
      final write = c.toggleFavorite(reference);
      await c.toggleFavorite(reference);
      await drainDetail();
      expect(c.busy, isTrue);
      expect(c.canPlay(reference), isFalse);
      gate.completeError(StateError('private-marker'));
      await write;
      expect(c.actionError, '收藏未完成，请重试。');
      expect(c.isFavorite(reference), isFalse);
      expect(c.busy, isFalse);
      f.collection.favoriteGate = null;
      await c.toggleFavorite(reference);
      await drainDetail();
      expect(c.isFavorite(reference), isTrue);
      expect(c.actionError, isNull);
      expect(f.collection.favoriteWriteCount, 1);
    },
  );

  for (final action in ['leave', 'refresh', 'close']) {
    test(
      '$action does not abandon an already accepted favorite write',
      () async {
        final f = CatalogDetailGraphFixture();
        await f.initialize();
        final c = f.graph.catalogDetails.open(AlbumDetailTarget(f.album.ref));
        await c.start();
        c.prepareTrackActions();
        await drainDetail();
        final gate = Completer<void>();
        f.collection.favoriteGate = gate.future;
        final reference = f.repository.trackData.first.ref;
        final write = c.toggleFavorite(reference);
        Future<void>? closed;
        var done = false;
        if (action == 'leave') c.setActive(false);
        if (action == 'refresh') await c.refresh();
        if (action == 'close') {
          closed = f.graph.close().then((_) => done = true);
        }
        await drainDetail();
        expect(done, isFalse);
        gate.complete();
        await write;
        await closed;
        expect(
          (await f.collection.watchFavorites().first).single.track,
          reference,
        );
        expect(f.collection.favoriteWriteCount, 1);
        if (action == 'close') expect(done, isTrue);
        await f.close();
      },
    );
  }

  test(
    'root close drains a subscription created during a reentrant listen',
    () async {
      final f = CatalogDetailGraphFixture();
      await f.initialize();
      final cancel = Completer<void>();
      final stream = StreamController<List<FavoriteEntry>>(
        sync: true,
        onCancel: () => cancel.future,
      );
      Future<void>? close;
      var done = false;
      f.collection.favoriteReader = () => ReentrantListenStream(
        stream.stream,
        () => close ??= f.graph.close().then((_) => done = true),
      );
      final c = f.graph.catalogDetails.open(AlbumDetailTarget(f.album.ref));
      await c.start();
      c.prepareTrackActions();
      await drainDetail();
      expect(close, isNotNull);
      expect(done, isFalse);
      expect(f.graph.catalogDetails.retainedSessionCount, 1);
      cancel.complete();
      await close;
      expect(done, isTrue);
      expect(f.graph.catalogDetails.retainedSessionCount, 0);
      await stream.close();
      await f.disposeFakes();
    },
  );

  test(
    'retry and root close retain old subscriptions until cancellation finishes',
    () async {
      final f = CatalogDetailGraphFixture();
      await f.initialize();
      final cancel = Completer<void>();
      final stream = StreamController<List<FavoriteEntry>>(
        sync: true,
        onCancel: () => cancel.future,
      );
      f.collection.favoriteReader = () => stream.stream;
      final c = f.graph.catalogDetails.open(AlbumDetailTarget(f.album.ref));
      await c.start();
      c.prepareTrackActions();
      await drainDetail();
      stream.add([]);
      expect(c.favoritesReady, isTrue);
      f.collection.favoriteReader = null;
      c.retryFavorites();
      await drainDetail();
      expect(c.favoritesReady, isTrue);
      var done = false;
      final close = f.graph.close().then((_) => done = true);
      await drainDetail();
      expect(done, isFalse);
      cancel.complete();
      await close;
      expect(done, isTrue);
      await stream.close();
      await f.disposeFakes();
    },
  );

  test('detail favorites persist through the real shared SQLite collection and remain source scoped', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final services = await DatabaseAppDataServices.open(database);
    final graph = DependencyGraph(dataServices: services);
    addTearDown(graph.close);
    final track = detailTrack('same-id');
    final foreign = detailTrack('same-id', source: 'other-source');
    await services.library.upsertTracks([track, foreign]);
    final album = (await services.library.listAlbums(PageRequest(limit: 20)))
        .items
        .singleWhere((a) => a.sourceId == track.sourceId);
    final c = graph.catalogDetails.open(AlbumDetailTarget(album.ref));
    await c.start();
    c.prepareTrackActions();
    await drainDetail();
    expect(c.canFavorite(track.ref), isTrue);
    await c.toggleFavorite(track.ref);
    expect(
      (await services.collection.watchFavorites().first).single.track,
      track.ref,
    );
    expect(c.isFavorite(foreign.ref), isFalse);
    await c.close();
    final next = graph.catalogDetails.open(AlbumDetailTarget(album.ref));
    await next.start();
    next.prepareTrackActions();
    await drainDetail();
    expect(next.isFavorite(track.ref), isTrue);
    await next.toggleFavorite(track.ref);
    expect(await services.collection.watchFavorites().first, isEmpty);
  });
}
