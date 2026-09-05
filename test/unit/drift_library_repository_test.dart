import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/data/repositories/drift_library_repository.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';

void main() {
  late AppDatabase database;
  late DriftLibraryRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory(), clock: () => _epoch);
    repository = DriftLibraryRepository(database);
    await repository.initialize();
  });

  tearDown(() async {
    await repository.dispose();
    await database.close();
  });

  test(
    'round-trips remote and local tracks without losing domain data',
    () async {
      final remote = _remoteTrack(
        id: 'remote-1',
        title: 'Remote song',
        artists: const ['Alice', 'Bob'],
        metadata: const {
          'disc': 2,
          'explicit': false,
          'nested': {
            'tags': ['one', 'two'],
          },
        },
      );
      final local = Track(
        id: 'local-1',
        sourceId: 'local-library',
        sourceType: MusicSourceType.local,
        title: 'Local song',
        artists: const ['Local Artist'],
        duration: const Duration(milliseconds: 123456),
        localPath: r'C:\Music\local.flac',
        fileFingerprint: 'sha256-local-file',
        modifiedAt: _epoch.add(const Duration(days: 1)),
        fileSize: 4096,
        metadata: const {'codec': 'flac'},
      );

      await repository.upsertTracks([remote, local]);

      final remoteResult = await repository.getTrack(remote.ref);
      final localResult = await repository.getTrack(local.ref);
      _expectTrack(remoteResult, remote);
      _expectTrack(localResult, local);
      expect(remoteResult!.metadata['nested'], const {
        'tags': ['one', 'two'],
      });
      expect(localResult!.modifiedAt!.isUtc, isTrue);
    },
  );

  test('paginates deterministically and keeps cross-source identity', () async {
    final tracks = [
      _remoteTrack(id: 'same-id', sourceId: 'source-b', title: 'Alpha'),
      _remoteTrack(id: 'same-id', sourceId: 'source-a', title: 'Alpha'),
      _remoteTrack(id: 'track-c', sourceId: 'source-a', title: 'Charlie'),
      _remoteTrack(id: 'track-b', sourceId: 'source-a', title: 'Bravo'),
    ];
    await repository.upsertTracks(tracks);

    final first = await repository.listTracks(PageRequest(offset: 0, limit: 2));
    final second = await repository.listTracks(
      PageRequest(offset: 2, limit: 2),
    );

    expect(first.items.map((track) => track.title), ['Alpha', 'Alpha']);
    expect(first.items.map((track) => track.sourceId), [
      'source-a',
      'source-b',
    ]);
    expect(first.hasMore, isTrue);
    expect(second.items.map((track) => track.title), ['Bravo', 'Charlie']);
    expect(second.hasMore, isFalse);
    expect(await repository.getTrack(tracks[0].ref), isNotNull);
    expect(await repository.getTrack(tracks[1].ref), isNotNull);
  });

  test(
    'publishes one complete watch snapshot after an atomic upsert',
    () async {
      final emissions = <List<Track>>[];
      final initial = Completer<void>();
      final committed = Completer<void>();
      final subscription = repository.watchTracks().listen((tracks) {
        emissions.add(tracks);
        if (emissions.length == 1) initial.complete();
        if (emissions.length == 2) committed.complete();
      });
      addTearDown(subscription.cancel);
      await initial.future.timeout(const Duration(seconds: 2));

      await repository.upsertTracks([
        _remoteTrack(id: 'watch-1', title: 'Watch one'),
        _remoteTrack(id: 'watch-2', title: 'Watch two'),
      ]);
      await committed.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(emissions.map((tracks) => tracks.length), [0, 2]);
      expect(emissions[1].map((track) => track.id), ['watch-1', 'watch-2']);
    },
  );

  test(
    'rolls back the whole catalog batch and redacts SQLite errors',
    () async {
      await database.customStatement('''
      CREATE TRIGGER fail_catalog_insert
      BEFORE INSERT ON tracks
      WHEN NEW.track_id = 'trigger-fail'
      BEGIN
        SELECT RAISE(ABORT, 'private failure payload');
      END
    ''');

      DomainFailure? failure;
      try {
        await repository.upsertTracks([
          _remoteTrack(id: 'good', title: 'Good'),
          _remoteTrack(id: 'trigger-fail', title: 'Fails'),
        ]);
      } on DomainFailure catch (error) {
        failure = error;
      }

      expect(failure, isNotNull);
      expect(failure!.code, DomainFailureCode.databaseCorrupted);
      expect(failure.toString(), isNot(contains('private failure payload')));
      expect(await _count(database, 'tracks'), 0);
      expect(await _count(database, 'artists'), 0);
      expect(await _count(database, 'albums'), 0);
    },
  );

  test('derives album credits and replaces stale catalog relations', () async {
    await repository.upsertTracks([
      _remoteTrack(
        id: 'track-1',
        title: 'First',
        artists: const ['Alice', 'Bob'],
      ),
      _remoteTrack(id: 'track-2', title: 'Second', artists: const ['Bob']),
    ]);

    var albums = await repository.listAlbums(PageRequest());
    var artists = await repository.listArtists(PageRequest());
    expect(albums.items, hasLength(1));
    expect(albums.items.single.trackCount, 2);
    expect(albums.items.single.artists.map((artist) => artist.name), [
      'Alice',
      'Bob',
    ]);
    expect(
      artists.items.map(
        (artist) => '${artist.name}:${artist.trackCount}:${artist.albumCount}',
      ),
      ['Alice:1:1', 'Bob:2:1'],
    );

    await repository.upsertTracks([
      _remoteTrack(
        id: 'track-1',
        title: 'First moved',
        albumId: 'album-b',
        albumTitle: 'Album B',
        artists: const ['Carol'],
      ),
    ]);

    albums = await repository.listAlbums(PageRequest());
    artists = await repository.listArtists(PageRequest());
    expect(albums.items.map((album) => '${album.title}:${album.trackCount}'), [
      'Album A:1',
      'Album B:1',
    ]);
    expect(artists.items.map((artist) => artist.name), ['Bob', 'Carol']);
    final moved = await repository.getTrack(
      TrackRef(
        trackId: 'track-1',
        sourceId: 'source-a',
        sourceType: MusicSourceType.rest,
      ),
    );
    expect(moved!.artists, ['Carol']);
  });

  test('updates availability and reports a safe missing reference', () async {
    final track = _remoteTrack(id: 'availability', title: 'Available');
    await repository.upsertTracks([track]);
    await repository.setAvailability(
      track.ref,
      TrackAvailability.sourceRemoved,
    );
    expect(
      (await repository.getTrack(track.ref))!.availability,
      TrackAvailability.sourceRemoved,
    );

    final missing = TrackRef(
      trackId: 'missing',
      sourceId: 'source-a',
      sourceType: MusicSourceType.rest,
    );
    await expectLater(
      repository.setAvailability(missing, TrackAvailability.unsupported),
      throwsA(
        isA<DomainFailure>()
            .having(
              (failure) => failure.code,
              'code',
              DomainFailureCode.notFound,
            )
            .having((failure) => failure.sourceId, 'sourceId', 'source-a'),
      ),
    );
  });

  test('turns corrupt row content into a redacted DomainFailure', () async {
    const privateValue = 'private-row-value';
    const sourceId = 'corrupt-source';
    const trackId = 'corrupt-track';
    await database.batch((batch) {
      batch.insert(
        database.trackRecords,
        TrackRecordsCompanion.insert(
          trackId: trackId,
          sourceId: sourceId,
          sourceType: MusicSourceType.rest.name,
          title: 'Corrupt track',
          durationMs: 1,
          availability: TrackAvailability.available.name,
          metadataJson: const Value('["$privateValue"]'),
        ),
      );
      batch.insert(
        database.artistRecords,
        ArtistRecordsCompanion.insert(
          artistId: 'corrupt-artist',
          sourceId: sourceId,
          name: 'Artist',
        ),
      );
      batch.insert(
        database.trackArtistRecords,
        TrackArtistRecordsCompanion.insert(
          trackSourceType: MusicSourceType.rest.name,
          trackSourceId: sourceId,
          trackId: trackId,
          artistSourceId: sourceId,
          artistId: 'corrupt-artist',
          position: 0,
        ),
      );
    });

    DomainFailure? failure;
    try {
      await repository.getTrack(
        TrackRef(
          trackId: trackId,
          sourceId: sourceId,
          sourceType: MusicSourceType.rest,
        ),
      );
    } on DomainFailure catch (error) {
      failure = error;
    }

    expect(failure, isNotNull);
    expect(failure!.code, DomainFailureCode.databaseCorrupted);
    expect(failure.toString(), isNot(contains(privateValue)));
  });

  test('rejects ambiguous batches before writing any rows', () async {
    final duplicate = _remoteTrack(id: 'duplicate', title: 'Duplicate');
    expect(
      () => repository.upsertTracks([duplicate, duplicate]),
      throwsArgumentError,
    );
    expect(
      () => repository.upsertTracks([
        _remoteTrack(id: 'one', title: 'One', albumTitle: 'Album A'),
        _remoteTrack(id: 'two', title: 'Two', albumTitle: 'Conflicting'),
      ]),
      throwsArgumentError,
    );
    expect(
      () => repository.upsertTracks([
        _remoteTrack(
          id: 'artists',
          title: 'Artists',
          artists: const ['Same', 'Same'],
        ),
      ]),
      throwsArgumentError,
    );
    expect(await _count(database, 'tracks'), 0);
  });

  test(
    'enforces initialization, idempotent disposal and database ownership',
    () async {
      final sharedRepository = DriftLibraryRepository(database);
      expect(
        () => sharedRepository.listTracks(PageRequest()),
        throwsStateError,
      );
      await sharedRepository.initialize();
      await sharedRepository.initialize();
      await sharedRepository.dispose();
      await sharedRepository.dispose();
      expect(database.schemaVersion, 2);
      expect(() => sharedRepository.watchTracks(), throwsStateError);
      expect(await _count(database, 'tracks'), 0);

      await repository.dispose();
      final ownedRepository = DriftLibraryRepository.owned(database);
      await ownedRepository.initialize();
      await ownedRepository.dispose();
      await expectLater(
        database.customSelect('SELECT 1').get(),
        throwsA(anything),
      );
    },
  );
}

final DateTime _epoch = DateTime.utc(2026, 9, 1, 8);

Track _remoteTrack({
  required String id,
  required String title,
  String sourceId = 'source-a',
  String? albumId = 'album-a',
  String? albumTitle = 'Album A',
  List<String> artists = const ['Artist'],
  Map<String, Object?> metadata = const {},
}) => Track(
  id: id,
  sourceId: sourceId,
  sourceType: MusicSourceType.rest,
  title: title,
  artists: artists,
  duration: const Duration(minutes: 3, seconds: 4),
  albumId: albumId,
  albumTitle: albumTitle,
  artworkUri: Uri.parse('https://example.test/artwork/$id'),
  modifiedAt: _epoch,
  availability: TrackAvailability.available,
  metadata: metadata,
);

void _expectTrack(Track? actual, Track expected) {
  expect(actual, isNotNull);
  expect(actual!.ref, expected.ref);
  expect(actual.title, expected.title);
  expect(actual.artists, expected.artists);
  expect(actual.duration, expected.duration);
  expect(actual.albumId, expected.albumId);
  expect(actual.albumTitle, expected.albumTitle);
  expect(actual.artworkUri, expected.artworkUri);
  expect(actual.localPath, expected.localPath);
  expect(actual.contentUri, expected.contentUri);
  expect(actual.fileFingerprint, expected.fileFingerprint);
  expect(actual.modifiedAt, expected.modifiedAt);
  expect(actual.fileSize, expected.fileSize);
  expect(actual.availability, expected.availability);
  expect(actual.metadata, expected.metadata);
}

Future<int> _count(AppDatabase database, String table) async {
  final row = await database
      .customSelect('SELECT COUNT(*) AS n FROM $table')
      .getSingle();
  return row.read<int>('n');
}
