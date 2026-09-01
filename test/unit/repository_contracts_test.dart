import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/lyrics.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/sensitive_credential.dart';
import 'package:yymusic/domain/models/track.dart';

import '../support/fake_domain_repositories.dart';

void main() {
  test(
    'LibraryRepository fake pages, watches and updates availability',
    () async {
      final first = _track('b');
      final second = _track('a');
      final localTwin = Track(
        id: second.id,
        sourceId: second.sourceId,
        sourceType: MusicSourceType.local,
        title: 'Local twin',
        artists: const ['Fixture Artist'],
        duration: const Duration(minutes: 3),
        localPath: r'C:\Music\local-twin.flac',
      );
      final repository = FakeLibraryRepository(
        tracks: [first, second, localTwin],
      );

      await repository.initialize();
      final events = StreamIterator(repository.watchTracks());
      expect(await events.moveNext(), isTrue);
      final initial = events.current;
      final page = await repository.listTracks(PageRequest(limit: 1));
      final nextEvent = events.moveNext();
      await Future<void>.delayed(Duration.zero);
      await repository.setAvailability(
        second.ref,
        TrackAvailability.sourceRemoved,
      );
      expect(await nextEvent, isTrue);
      final updated = events.current;
      await events.cancel();

      expect(repository.initializeCount, 1);
      expect(page.items.single.id, 'a');
      expect(page.hasMore, isTrue);
      expect(initial, hasLength(3));
      expect(
        (await repository.getTrack(second.ref))?.availability,
        TrackAvailability.sourceRemoved,
      );
      expect(await repository.getTrack(localTwin.ref), same(localTwin));
      expect(
        updated.singleWhere((track) => track.ref == second.ref).availability,
        TrackAvailability.sourceRemoved,
      );
      await repository.dispose();
    },
  );

  test(
    'DependencyGraph accepts and disposes a LibraryRepository fake once',
    () async {
      final repository = FakeLibraryRepository();
      final graph = DependencyGraph(library: repository);

      graph.dispose();
      graph.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(repository.disposeCount, 1);
    },
  );

  test(
    'CollectionRepository fake preserves duplicate queue track entries',
    () async {
      final track = _track('duplicate').ref;
      final repository = FakeCollectionRepository();
      final queue = QueueSnapshot(
        entries: [
          QueueEntry(id: 'entry-1', track: track, position: 0, addedAt: _epoch),
          QueueEntry(id: 'entry-2', track: track, position: 1, addedAt: _epoch),
        ],
        currentEntryId: 'entry-2',
        updatedAt: _epoch,
      );

      final events = StreamIterator(repository.watchQueue());
      expect(await events.moveNext(), isTrue);
      final initial = events.current;
      final nextEvent = events.moveNext();
      await Future<void>.delayed(Duration.zero);
      await repository.saveQueue(queue);
      expect(await nextEvent, isTrue);
      final updated = events.current;
      await events.cancel();

      expect(initial.entries, isEmpty);
      expect(updated.entries, hasLength(2));
      expect(updated.entries.map((entry) => entry.id), ['entry-1', 'entry-2']);
      await repository.dispose();
    },
  );

  test(
    'Lyrics and source repositories are independently replaceable fakes',
    () async {
      final track = _track('lyrics').ref;
      final lyricsRepository = FakeLyricsRepository();
      final sourceRepository = FakeMusicSourceRepository();
      final document = LyricsDocument(
        track: track,
        kind: LyricsKind.plain,
        lines: [LyricsLine(text: 'Plain lyric')],
        language: 'en',
      );
      final source = MusicSourceConfig(
        id: 'source-rest',
        name: 'REST Music',
        type: MusicSourceType.rest,
        baseUrl: Uri.parse('https://music.invalid/api'),
        authType: MusicSourceAuthType.bearer,
        credentialRef: 'credential-1',
      );

      await lyricsRepository.saveLyrics(document);
      await sourceRepository.saveSource(source);

      expect(await lyricsRepository.getLyrics(track), same(document));
      expect(
        (await sourceRepository.getSource('source-rest'))?.credentialRef,
        'credential-1',
      );
      await sourceRepository.dispose();
    },
  );

  test(
    'SecureCredentialGateway fake stores secrets outside source config',
    () async {
      final gateway = FakeSecureCredentialGateway();
      final credential = SensitiveCredential(
        kind: SensitiveCredentialKind.bearerToken,
        fields: const {'token': 'ephemeral-secret'},
      );

      final reference = await gateway.saveCredential(credential);
      final config = MusicSourceConfig(
        id: 'source-rest',
        name: 'REST Music',
        type: MusicSourceType.rest,
        baseUrl: Uri.parse('https://music.invalid/api'),
        authType: MusicSourceAuthType.bearer,
        credentialRef: reference,
      );

      expect(config.credentialRef, reference);
      expect(config.toString(), isNot(contains('ephemeral-secret')));
      expect(
        (await gateway.readCredential(reference))?.fields['token'],
        'ephemeral-secret',
      );
      await gateway.deleteCredential(reference);
      expect(await gateway.readCredential(reference), isNull);
    },
  );
}

final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

Track _track(String id) => Track(
  id: id,
  sourceId: 'source-rest',
  sourceType: MusicSourceType.rest,
  title: 'Track $id',
  artists: const ['Fixture Artist'],
  duration: const Duration(minutes: 3),
);
