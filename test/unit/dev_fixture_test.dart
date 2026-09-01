import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/database_app_data_services.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/data/database/app_database.dart';
import 'package:yymusic/dev_fixture/dev_fixture.dart';
import 'package:yymusic/dev_fixture/dev_fixture_app_data_services.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/fake_domain_repositories.dart';

void main() {
  test(
    'production factory composes repositories and platform gateway',
    () async {
      for (final platform in YYPlatform.values) {
        final database = AppDatabase(NativeDatabase.memory());
        final gateway = FakeSecureCredentialGateway();
        YYPlatform? selectedPlatform;
        final services = await createProductionAppDataServices(
          platform,
          openDatabase: () async => database,
          createCredentialGateway: (selected) {
            selectedPlatform = selected;
            return gateway;
          },
        );
        expect(selectedPlatform, platform);
        expect(services.credentials, same(gateway));
        expect(
          (await services.library.listTracks(PageRequest(limit: 1))).items,
          isEmpty,
        );
        expect(await services.collection.loadQueue(), isNotNull);
        expect(await services.musicSources.watchSources().first, isEmpty);
        await services.dispose();
        await services.dispose();
        expect(
          () => services.library.listTracks(PageRequest(limit: 1)),
          throwsStateError,
        );
      }
    },
  );

  test(
    'dev factory maps audited HTML fixture through real repositories',
    () async {
      final services = await createDevFixtureAppDataServices(
        YYPlatform.windows,
      );
      addTearDown(services.dispose);

      final tracks = (await services.library.listTracks(PageRequest(limit: 20)))
          .items;
      expect(
        tracks.map((track) => track.title),
        containsAll([
          'A Quiet Orbit',
          'Slow Lines',
          'Warm Static',
          'Current No. 4',
        ]),
      );
      expect(tracks, hasLength(4));
      expect(
        tracks.every(
          (track) =>
              track.sourceId == YYDevFixture.sourceId &&
              track.availability == TrackAvailability.sourceDisabled &&
              track.localPath == null &&
              track.contentUri == null &&
              track.artworkUri == null &&
              track.metadata['fixture'] == 'audited-html-reference',
        ),
        isTrue,
      );

      final sources = await services.musicSources.watchSources().first;
      expect(sources, hasLength(1));
      final source = sources.single;
      expect(source.baseUrl, Uri.parse('https://fixture.invalid'));
      expect(source.enabled, isFalse);
      expect(source.status, MusicSourceStatus.disabled);
      expect(source.authType, MusicSourceAuthType.none);
      expect(source.credentialRef, isNull);
      expect(services.credentials, isNull);

      final albums = (await services.library.listAlbums(PageRequest(limit: 20)))
          .items;
      final artists = (await services.library.listArtists(
        PageRequest(limit: 20),
      )).items;
      expect(albums, hasLength(4));
      expect(artists, hasLength(4));

      final playlists = await services.collection.watchPlaylists().first;
      expect(
        playlists.map((playlist) => playlist.id),
        containsAll([
          YYDevFixture.nightPlaylistId,
          YYDevFixture.focusPlaylistId,
        ]),
      );
      expect(
        await services.collection.getPlaylistEntries(
          YYDevFixture.nightPlaylistId,
        ),
        hasLength(2),
      );
      final queue = await services.collection.loadQueue();
      expect(queue.entries, hasLength(3));
      expect(queue.currentEntryId, 'fixture_queue_0');
      expect(await services.collection.watchFavorites().first, isEmpty);
      expect(await services.collection.watchHistory().first, isEmpty);

      final quietOrbit = tracks.singleWhere(
        (track) => track.id == 'quiet_orbit',
      );
      final lyrics = await services.lyrics.getLyrics(quietOrbit.ref);
      expect(lyrics?.lines, hasLength(10));
      expect(lyrics?.language, 'en');
      expect(lyrics?.translationLanguage, 'zh-Hans');
    },
  );

  test(
    'production factory closes the database when gateway creation fails',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      var closeCount = 0;
      await expectLater(
        createProductionAppDataServices(
          YYPlatform.windows,
          openDatabase: () async => database,
          closeDatabase: (database) async {
            closeCount += 1;
            await database.close();
          },
          createCredentialGateway: (_) =>
              throw StateError('platform gateway unavailable'),
        ),
        throwsStateError,
      );
      expect(closeCount, 1);
    },
  );

  test('dev seeder refuses a non-empty data store without mutation', () async {
    final services = await DatabaseAppDataServices.open(
      AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(services.dispose);
    final existingSource = MusicSourceConfig(
      id: 'existing_source',
      name: 'Existing user source',
      type: MusicSourceType.rest,
      baseUrl: Uri.parse('https://existing.invalid'),
      authType: MusicSourceAuthType.none,
    );
    await services.musicSources.saveSource(existingSource);

    await expectLater(
      DevFixtureSeeder(YYDevFixture()).seedEmpty(services),
      throwsStateError,
    );

    expect(await services.musicSources.getSource(existingSource.id), isNotNull);
    expect(
      await services.musicSources.getSource(YYDevFixture.sourceId),
      isNull,
    );
    expect(
      (await services.library.listTracks(PageRequest(limit: 20))).items,
      isEmpty,
    );
  });

  test('dependency graph exposes and owns a complete data scope', () async {
    final services = await createDevFixtureAppDataServices(YYPlatform.android);
    final graph = DependencyGraph(dataServices: services);
    expect(graph.library, same(services.library));
    expect(graph.collection, same(services.collection));
    expect(graph.lyrics, same(services.lyrics));
    expect(graph.musicSources, same(services.musicSources));
    expect(graph.credentials, isNull);

    graph.dispose();
    graph.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(
      () => graph.library!.listTracks(PageRequest(limit: 1)),
      throwsStateError,
    );
  });
}
