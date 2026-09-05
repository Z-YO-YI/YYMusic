import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/catalog_browse.dart';
import 'package:yymusic/domain/models/catalog_search.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/library_entities.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_controller.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';

import '../support/catalog_detail_probe.dart';
import '../support/fake_domain_repositories.dart';

void main() {
  late CatalogDetailProbe repository;
  late CatalogDetailSessions sessions;
  late Album album;
  late Artist artist;
  setUp(() {
    repository = CatalogDetailProbe();
    album = detailAlbum();
    artist = detailArtist();
    repository.albumData[album.ref] = album;
    repository.artistData[artist.ref] = artist;
    repository.trackData.addAll([
      for (var i = 0; i < 45; i++) detailTrack('$i'),
    ]);
    sessions = CatalogDetailSessions(repository: repository);
  });
  tearDown(() async => sessions.close());

  CatalogDetailController openAlbum() =>
      sessions.open(AlbumDetailTarget(album.ref));
  CatalogDetailController openArtist() =>
      sessions.open(ArtistDetailTarget(artist.ref));

  test('construction stays idle, start is shared and published pages are immutable', () async {
    final controller = openAlbum();
    expect(controller.summary.phase, LoadPhase.idle);
    expect(repository.calls, isEmpty);
    final first = controller.start();
    expect(controller.start(), same(first));
    await first;
    expect(controller.summary.data, isA<AlbumDetailSummary>());
    expect(controller.summary.data!.trackCount, 240);
    expect(controller.tracks.items.length, 20);
    expect(controller.albums.phase, LoadPhase.idle);
    await controller.loadMoreAlbums();
    expect(repository.calls.map((call) => call.kind), ['album', 'tracks']);
    final query = repository.calls.last.query as CatalogTrackQuery;
    expect(query.album, album.ref);
    expect(query.artist, isNull);
    expect(query.filter.isAll, isTrue);
    expect(() => controller.tracks.items.clear(), throwsUnsupportedError);
    final old = controller.tracks;
    await controller.loadMoreTracks();
    expect(old.items.length, 20);
    expect(controller.tracks.items.length, 40);
  });

  test(
    'missing repository, missing entity and known empty album are distinct',
    () async {
      final absent = CatalogDetailSessions();
      try {
        final controller = absent.open(AlbumDetailTarget(album.ref));
        await controller.start();
        expect(controller.summary.phase, LoadPhase.error);
        expect(controller.summary.failure!.sourceId, isNull);
      } finally {
        await absent.close();
      }
      repository.albumData.clear();
      final missing = openAlbum();
      await missing.start();
      expect(missing.summary.phase, LoadPhase.empty);
      await missing.loadMoreTracks();
      expect(repository.calls.length, 1);
      repository.albumData[album.ref] = detailAlbum(count: 0);
      repository.trackData.clear();
      await missing.refresh();
      expect(missing.summary.phase, LoadPhase.data);
      expect(missing.summary.data!.trackCount, 0);
      expect(missing.tracks.phase, LoadPhase.empty);
    },
  );

  test(
    'artist tracks do not wait for albums and section retry is isolated',
    () async {
      final gate = Completer<PageResult<Album>>();
      final started = Completer<void>();
      repository.onAlbums = (_, _, _) {
        started.complete();
        return gate.future;
      };
      final controller = openArtist();
      final load = controller.start();
      await started.future;
      await waitFor(
        controller,
        () => controller.tracks.phase == LoadPhase.data,
      );
      expect(controller.summary.data, isA<ArtistDetailSummary>());
      expect(controller.albums.loading, isTrue);
      gate.completeError(StateError('private-message'));
      await load;
      expect(controller.albums.phase, LoadPhase.error);
      expect(controller.tracks.items.length, 20);
      expect(controller.summary.phase, LoadPhase.data);
      final trackReads = repository.calls
          .where((call) => call.kind == 'tracks')
          .length;
      repository.onAlbums = null;
      await controller.loadMoreAlbums();
      expect(controller.albums.items.single.ref, album.ref);
      expect(
        repository.calls.where((call) => call.kind == 'tracks').length,
        trackReads,
      );
      expect(
        (repository.calls.last.query as CatalogAlbumQuery).artist,
        artist.ref,
      );
      final query =
          repository.calls.firstWhere((call) => call.kind == 'tracks').query
              as CatalogTrackQuery;
      expect(query.artist, artist.ref);
      expect(query.album, isNull);
    },
  );

  test(
    'track error does not hide artist albums or launch an album retry',
    () async {
      repository.onTracks = (_, _, _) async =>
          throw StateError('private-message');
      final controller = openArtist();
      await controller.start();
      expect(controller.tracks.phase, LoadPhase.error);
      expect(controller.albums.phase, LoadPhase.data);
      repository.onTracks = null;
      await controller.loadMoreTracks();
      expect(controller.tracks.items.length, 20);
      expect(repository.calls.where((call) => call.kind == 'albums').length, 1);
    },
  );

  test('summary failures strip raw diagnostic/source text while retaining classification', () async {
    repository.onAlbum = (_, _) async => throw DomainFailure(
      code: DomainFailureCode.databaseCorrupted,
      diagnosticId: 'private-diagnostic',
      sourceId: 'private-source',
    );
    final controller = openAlbum();
    await controller.start();
    expect(controller.summary.phase, LoadPhase.error);
    final failure = controller.summary.failure!;
    expect(failure.code, DomainFailureCode.databaseCorrupted);
    expect(failure.toString(), isNot(contains('private')));
    expect(failure.retryable, isTrue);
    expect(repository.calls.length, 1);
    repository.onAlbum = null;
    await controller.refresh();
    expect(controller.summary.phase, LoadPhase.data);
  });

  test(
    'same IDs across sources never substitute for the requested summary',
    () async {
      repository.onAlbum = (_, _) async => detailAlbum(source: 'other-source');
      final controller = openAlbum();
      await controller.start();
      expect(
        controller.summary.failure!.code,
        DomainFailureCode.schemaMismatch,
      );
      expect(repository.calls.length, 1);
      repository.onArtist = (_, _) async =>
          detailArtist(source: 'other-source');
      final other = openArtist();
      await other.start();
      expect(other.summary.failure!.code, DomainFailureCode.schemaMismatch);
      expect(repository.calls.length, 2);
    },
  );

  test('foreign track source or album rejects the whole page without partial append', () async {
    final controller = openAlbum();
    await controller.start();
    for (final wrong in [
      detailTrack('wrong', source: 'other'),
      detailTrack('wrong', album: 'other'),
    ]) {
      repository.onTracks = (_, _, _) async =>
          PageResult(items: [detailTrack('valid'), wrong], hasMore: true);
      await controller.loadMoreTracks();
      expect(controller.tracks.phase, LoadPhase.error);
      expect(controller.tracks.failure!.code, DomainFailureCode.schemaMismatch);
      expect(controller.tracks.items.length, 20);
      expect(controller.tracks.rawCount, 20);
    }
    repository.onTracks = null;
    await controller.loadMoreTracks();
    expect(controller.tracks.items.length, 40);
  });

  test('artist page rejects foreign sources but retains compilations with other album credits', () async {
    repository.onAlbums = (_, _, _) async =>
        PageResult(items: [detailAlbum(source: 'other')], hasMore: false);
    repository.onTracks = (_, _, _) async => PageResult(
      items: [detailTrack('wrong', source: 'other')],
      hasMore: false,
    );
    final controller = openArtist();
    await controller.start();
    expect(controller.albums.failure!.code, DomainFailureCode.schemaMismatch);
    expect(controller.tracks.failure!.code, DomainFailureCode.schemaMismatch);
    repository.onAlbums = null;
    await controller.loadMoreAlbums();
    expect(controller.albums.items.single.artists.single.id, 'album-artist');
    expect(controller.albums.phase, LoadPhase.data);
  });

  test('full track identity, unavailable references and raw offsets survive deduplication', () async {
    final local = detailTrack(
      'same',
      availability: TrackAvailability.localMissing,
    );
    final remote = detailTrack(
      'same',
      type: MusicSourceType.rest,
      availability: TrackAvailability.sourceRemoved,
    );
    repository.onTracks = (_, page, _) async => PageResult(
      items: page.offset == 0
          ? [local, local, remote]
          : [local, detailTrack('next')],
      hasMore: page.offset == 0,
    );
    final controller = openAlbum();
    await controller.start();
    expect(controller.tracks.items.map((t) => t.ref), [local.ref, remote.ref]);
    expect(controller.tracks.rawCount, 3);
    await controller.loadMoreTracks();
    expect(repository.calls.last.page!.offset, 3);
    expect(controller.tracks.items.length, 3);
    expect(controller.tracks.rawCount, 5);
    expect(
      controller.tracks.items.first.availability,
      TrackAvailability.localMissing,
    );
    await controller.loadMoreTracks();
    expect(repository.calls.length, 3);
  });

  test(
    'repeated and oversized pages stop at 200 raw rows, not 200 unique rows',
    () async {
      repository.onTracks = (_, _, _) async => PageResult(
        items: [for (var i = 0; i < 27; i++) detailTrack('same')],
        hasMore: true,
      );
      repository.onAlbums = (_, _, _) async => PageResult(
        items: [for (var i = 0; i < 25; i++) album],
        hasMore: true,
      );
      final controller = openArtist();
      await controller.start();
      for (var i = 0; i < 12; i++) {
        await controller.loadMoreTracks();
        await controller.loadMoreAlbums();
      }
      expect(controller.tracks.capped, isTrue);
      expect(controller.albums.capped, isTrue);
      expect(controller.tracks.rawCount, 200);
      expect(controller.albums.rawCount, 200);
      expect(controller.tracks.items.length, 1);
      expect(controller.albums.items.length, 1);
      for (final kind in ['tracks', 'albums']) {
        final reads = repository.calls
            .where((call) => call.kind == kind)
            .toList();
        expect(reads.length, 10);
        expect(reads.map((call) => call.page!.offset), [
          for (var i = 0; i < 10; i++) i * 20,
        ]);
        expect(reads.every((call) => call.page!.limit == 20), isTrue);
      }
    },
  );

  test(
    'short intermediate pages cannot grow the final page beyond the raw cap',
    () async {
      repository.onTracks = (_, page, _) async => PageResult(
        items: [
          for (var i = 0; i < (page.offset == 0 ? 15 : 20); i++)
            detailTrack('${page.offset + i}'),
        ],
        hasMore: true,
      );
      repository.onAlbums = (_, page, _) async => PageResult(
        items: [
          for (var i = 0; i < (page.offset == 0 ? 18 : 20); i++)
            detailAlbum(id: 'album-${page.offset + i}'),
        ],
        hasMore: true,
      );
      final controller = openArtist();
      await controller.start();
      for (var i = 0; i < 12; i++) {
        await controller.loadMoreTracks();
        await controller.loadMoreAlbums();
        expect(controller.tracks.rawCount, lessThanOrEqualTo(200));
        expect(controller.albums.rawCount, lessThanOrEqualTo(200));
      }
      expect(controller.tracks.items.length, 200);
      expect(controller.albums.items.length, 200);
      expect(
        repository.calls.lastWhere((call) => call.kind == 'tracks').page!.limit,
        5,
      );
      expect(
        repository.calls.lastWhere((call) => call.kind == 'albums').page!.limit,
        2,
      );
    },
  );

  test(
    'empty pages terminate even when a malformed adapter advertises more',
    () async {
      repository.onTracks = (_, _, _) async =>
          PageResult(items: [], hasMore: true);
      repository.onAlbums = (_, _, _) async =>
          PageResult(items: [], hasMore: true);
      final controller = openArtist();
      await controller.start();
      await controller.loadMoreTracks();
      await controller.loadMoreAlbums();
      expect(controller.tracks.phase, LoadPhase.empty);
      expect(controller.albums.phase, LoadPhase.empty);
      expect(controller.tracks.hasMore, isFalse);
      expect(controller.albums.hasMore, isFalse);
      expect(repository.calls.length, 3);
    },
  );

  test(
    'later album failure retries at the original offset and keeps earlier data',
    () async {
      repository.albumData.addAll({
        for (var i = 0; i < 25; i++)
          detailAlbum(id: 'album-$i').ref: detailAlbum(id: 'album-$i'),
      });
      final controller = openArtist();
      await controller.start();
      final original = controller.albums.items;
      repository.onAlbums = (_, _, _) async =>
          throw StateError('private-error');
      await controller.loadMoreAlbums();
      expect(controller.albums.items, original);
      expect(controller.albums.rawCount, 20);
      expect(controller.albums.failure!.toString(), isNot(contains('private')));
      repository.onAlbums = null;
      await controller.loadMoreAlbums();
      expect(repository.calls.last.page!.offset, 20);
      expect(controller.albums.items.length, 26);
      expect(controller.albums.hasMore, isFalse);
    },
  );

  test('duplicate load-more calls cannot overlap the same page', () async {
    final gate = Completer<PageResult<Track>>();
    final entered = Completer<void>();
    repository.onTracks = (_, _, _) {
      entered.complete();
      return gate.future;
    };
    final controller = openAlbum();
    final load = controller.start();
    await entered.future;
    await controller.loadMoreTracks();
    await controller.loadMoreTracks();
    expect(repository.calls.length, 2);
    gate.complete(PageResult(items: [], hasMore: false));
    await load;
  });

  test(
    'refresh discards stale summaries and does not launch stale child queries',
    () async {
      final gate = Completer<Album?>();
      final entered = Completer<void>();
      SearchCancellation? oldToken;
      repository.onAlbum = (_, token) {
        oldToken = token;
        entered.complete();
        return gate.future;
      };
      final controller = openAlbum();
      final first = controller.start();
      await entered.future;
      repository.onAlbum = null;
      await controller.refresh();
      expect(oldToken!.isCancelled, isTrue);
      final state = controller.summary;
      gate.complete(null);
      await first;
      expect(controller.summary, same(state));
      expect(repository.calls.where((call) => call.kind == 'tracks').length, 1);
    },
  );

  test('refresh cancels both old pages and late success/error cannot notify or replace', () async {
    final trackGate = Completer<PageResult<Track>>();
    final albumGate = Completer<PageResult<Album>>();
    final started = Completer<void>();
    repository.onTracks = (_, _, _) => trackGate.future;
    repository.onAlbums = (_, _, _) {
      started.complete();
      return albumGate.future;
    };
    final controller = openArtist();
    final first = controller.start();
    await started.future;
    final tokens = repository.calls.map((call) => call.token!).toList();
    repository.onTracks = null;
    repository.onAlbums = null;
    await controller.refresh();
    expect(tokens.every((token) => token.isCancelled), isTrue);
    final tracks = controller.tracks;
    final albums = controller.albums;
    var notified = 0;
    controller.addListener(() => notified++);
    trackGate.completeError(StateError('private-old-error'));
    albumGate.complete(PageResult(items: [], hasMore: false));
    await first;
    expect(controller.tracks, same(tracks));
    expect(controller.albums, same(albums));
    expect(notified, 0);
  });

  test(
    'refresh from a summary listener does not launch old-generation pages',
    () async {
      final controller = openAlbum();
      Future<void>? second;
      var refreshed = false;
      controller.addListener(() {
        if (controller.summary.phase == LoadPhase.data && !refreshed) {
          refreshed = true;
          second = controller.refresh();
        }
      });
      await controller.start();
      await second;
      expect(repository.calls.map((call) => call.kind), [
        'album',
        'album',
        'tracks',
      ]);
    },
  );

  test(
    'refresh before start is a load, not a reason for start to reset the page',
    () async {
      final controller = openAlbum();
      await controller.refresh();
      await controller.loadMoreTracks();
      await controller.start();
      expect(controller.tracks.items.length, 40);
      expect(repository.calls.length, 3);
    },
  );

  test('closing one session leaves peers usable and retires only after reads drain', () async {
    final gate = Completer<Album?>();
    final entered = Completer<void>();
    repository.onAlbum = (_, _) {
      entered.complete();
      return gate.future;
    };
    final a = openAlbum();
    final b = openArtist();
    final load = a.start();
    await entered.future;
    var closed = false;
    final close = a.close().then((_) => closed = true);
    expect(sessions.retainedSessionCount, 2);
    expect(repository.calls.first.token!.isCancelled, isTrue);
    await b.start();
    expect(b.tracks.phase, LoadPhase.data);
    expect(closed, isFalse);
    await a.refresh();
    await a.loadMoreTracks();
    gate.complete(album);
    await load;
    await close;
    expect(sessions.retainedSessionCount, 1);
    expect(a.close(), same(a.close()));
    await b.close();
    expect(sessions.retainedSessionCount, 0);
  });

  test('closing immediately rejects queued reads and new sessions', () async {
    final controller = openAlbum();
    final load = controller.start();
    final close = sessions.close();
    expect(sessions.close(), same(close));
    expect(openArtist, throwsStateError);
    await close;
    await load;
    expect(repository.calls, isEmpty);
    expect(sessions.retainedSessionCount, 0);
  });

  test('root close waits for already-closing sessions before disposing borrowed storage', () async {
    final library = FakeLibraryRepository();
    final graph = DependencyGraph(library: library, catalogBrowse: repository);
    final gate = Completer<PageResult<Track>>();
    final entered = Completer<void>();
    repository.onTracks = (_, _, _) {
      entered.complete();
      return gate.future;
    };
    final controller = graph.catalogDetails.open(AlbumDetailTarget(album.ref));
    final load = controller.start();
    await entered.future;
    final localClose = controller.close();
    var closed = false;
    final rootClose = graph.close().then((_) => closed = true);
    await Future<void>.delayed(Duration.zero);
    expect(closed, isFalse);
    expect(library.disposeCount, 0);
    expect(
      () => graph.catalogDetails.open(AlbumDetailTarget(album.ref)),
      throwsStateError,
    );
    gate.complete(PageResult(items: [], hasMore: false));
    await load;
    await localClose;
    await rootClose;
    expect(library.disposeCount, 1);
    expect(graph.catalogDetails.retainedSessionCount, 0);
  });
}

Future<void> waitFor(
  CatalogDetailController controller,
  bool Function() ready,
) async {
  if (ready()) return;
  final done = Completer<void>();
  void changed() {
    if (ready() && !done.isCompleted) done.complete();
  }

  controller.addListener(changed);
  try {
    await done.future.timeout(const Duration(seconds: 5));
  } finally {
    controller.removeListener(changed);
  }
}
