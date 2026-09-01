import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/load_state.dart';
import 'package:yymusic/domain/models/lyrics.dart';
import 'package:yymusic/domain/models/music_source.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/sensitive_credential.dart';
import 'package:yymusic/domain/models/track.dart';

void main() {
  group('Track and stable references', () {
    test('freezes artists and nested metadata without storing stream URLs', () {
      final artists = ['Luna Harbor'];
      final tags = <Object?>['quiet'];
      final track = Track(
        id: 'track-orbit',
        sourceId: 'source-rest',
        sourceType: MusicSourceType.rest,
        title: 'A Quiet Orbit',
        artists: artists,
        duration: const Duration(minutes: 3, seconds: 48),
        artworkUri: Uri.parse('https://media.invalid/art/orbit'),
        metadata: {'tags': tags, 'disc': 1},
      );

      artists.add('Mutation');
      tags.add('mutation');

      expect(track.artists, ['Luna Harbor']);
      expect(track.metadata['tags'], ['quiet']);
      expect(() => track.artists.add('blocked'), throwsUnsupportedError);
      expect(
        track.ref,
        TrackRef(
          trackId: 'track-orbit',
          sourceId: 'source-rest',
          sourceType: MusicSourceType.rest,
        ),
      );
      expect(
        track.withAvailability(TrackAvailability.sourceRemoved).availability,
        TrackAvailability.sourceRemoved,
      );
    });

    test('separates local media references from remote tracks', () {
      expect(
        () => Track(
          id: 'local-missing',
          sourceId: 'source-local',
          sourceType: MusicSourceType.local,
          title: 'Missing',
          artists: const ['Unknown'],
          duration: Duration.zero,
        ),
        throwsArgumentError,
      );
      expect(
        () => Track(
          id: 'remote-path',
          sourceId: 'source-rest',
          sourceType: MusicSourceType.rest,
          title: 'Remote',
          artists: const ['Unknown'],
          duration: Duration.zero,
          localPath: r'C:\music\remote.mp3',
        ),
        throwsArgumentError,
      );
      expect(
        () => Track(
          id: 'local-http',
          sourceId: 'source-local',
          sourceType: MusicSourceType.local,
          title: 'Wrong URI',
          artists: const ['Unknown'],
          duration: Duration.zero,
          contentUri: Uri.parse('https://media.invalid/42'),
        ),
        throwsArgumentError,
      );
      expect(_localTrack().contentUri, Uri.parse('content://media/audio/42'));
    });

    test('rejects non-finite values before metadata reaches JSON storage', () {
      expect(
        () => Track(
          id: 'not-finite',
          sourceId: 'source-rest',
          sourceType: MusicSourceType.rest,
          title: 'Invalid metadata',
          artists: const ['Unknown'],
          duration: Duration.zero,
          metadata: const {'gain': double.nan},
        ),
        throwsArgumentError,
      );
      expect(
        () => Track(
          id: 'album-pair',
          sourceId: 'source-rest',
          sourceType: MusicSourceType.rest,
          title: 'Invalid album',
          artists: const ['Unknown'],
          duration: Duration.zero,
          albumId: 'album-only',
        ),
        throwsArgumentError,
      );
      expect(
        () => Track(
          id: 'duplicate-artists',
          sourceId: 'source-rest',
          sourceType: MusicSourceType.rest,
          title: 'Invalid artists',
          artists: const ['Same', 'Same'],
          duration: Duration.zero,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Collections and queue identity', () {
    test('allows duplicate tracks through independent queue entry IDs', () {
      final ref = _remoteTrack('track-a').ref;
      final entries = [
        _queueEntry('entry-a', ref, 0),
        _queueEntry('entry-b', ref, 1),
      ];
      final snapshot = QueueSnapshot(
        entries: entries,
        currentEntryId: 'entry-b',
        updatedAt: _epoch,
      );

      entries.clear();
      expect(snapshot.entries, hasLength(2));
      expect(snapshot.entries[0].track, snapshot.entries[1].track);
      expect(snapshot.currentEntryId, 'entry-b');
      expect(() => snapshot.entries.clear(), throwsUnsupportedError);
    });

    test('rejects duplicate entry IDs, positions and missing cursor', () {
      final ref = _remoteTrack('track-a').ref;
      expect(
        () => QueueSnapshot(
          entries: [_queueEntry('same', ref, 0), _queueEntry('same', ref, 1)],
          updatedAt: _epoch,
        ),
        throwsArgumentError,
      );
      expect(
        () => QueueSnapshot(
          entries: [_queueEntry('one', ref, 1), _queueEntry('two', ref, 2)],
          updatedAt: _epoch,
        ),
        throwsArgumentError,
      );
      expect(
        () => QueueSnapshot(
          entries: [_queueEntry('one', ref, 0), _queueEntry('two', ref, 0)],
          updatedAt: _epoch,
        ),
        throwsArgumentError,
      );
      expect(
        () => QueueSnapshot(
          entries: [_queueEntry('one', ref, 0)],
          currentEntryId: 'missing',
          updatedAt: _epoch,
        ),
        throwsArgumentError,
      );
    });

    test('protects system playlist identity and timestamps', () {
      expect(
        () => Playlist(
          id: 'favorites',
          name: '喜欢的音乐',
          createdAt: _epoch,
          updatedAt: _epoch,
          isSystem: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => Playlist(
          id: 'local-time',
          name: 'Local time',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        throwsArgumentError,
      );
      expect(
        () => Playlist(
          id: 'custom',
          name: 'Custom',
          createdAt: _epoch.add(const Duration(days: 1)),
          updatedAt: _epoch,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Lyrics documents', () {
    test('keeps synchronized bilingual lines ordered and immutable', () {
      final lines = [
        LyricsLine(
          start: Duration.zero,
          end: const Duration(seconds: 12),
          text: 'Let the room grow quiet',
          translation: '让房间慢慢安静下来',
        ),
        LyricsLine(
          start: const Duration(seconds: 12),
          end: const Duration(seconds: 31),
          text: 'We move in a smaller orbit',
          translation: '我们沿着更小的轨道前行',
        ),
      ];
      final document = LyricsDocument(
        track: _remoteTrack('track-lyrics').ref,
        kind: LyricsKind.synchronized,
        lines: lines,
        language: 'en',
        translationLanguage: 'zh-Hans',
        offset: const Duration(milliseconds: -120),
      );

      lines.clear();
      expect(document.lines, hasLength(2));
      expect(document.offset, const Duration(milliseconds: -120));
      expect(() => document.lines.clear(), throwsUnsupportedError);
    });

    test('rejects mistimed, unsorted or mismatched translation documents', () {
      final ref = _remoteTrack('track-lyrics').ref;
      expect(
        () => LyricsDocument(
          track: ref,
          kind: LyricsKind.plain,
          lines: [
            LyricsLine(
              start: Duration.zero,
              end: const Duration(seconds: 1),
              text: 'Timed',
            ),
          ],
          language: 'en',
        ),
        throwsArgumentError,
      );
      expect(
        () => LyricsDocument(
          track: ref,
          kind: LyricsKind.synchronized,
          lines: [
            LyricsLine(
              start: const Duration(seconds: 2),
              end: const Duration(seconds: 3),
              text: 'Second',
            ),
            LyricsLine(
              start: const Duration(seconds: 1),
              end: const Duration(seconds: 2),
              text: 'First',
            ),
          ],
          language: 'en',
        ),
        throwsArgumentError,
      );
      expect(
        () => LyricsDocument(
          track: ref,
          kind: LyricsKind.plain,
          lines: [LyricsLine(text: 'Plain', translation: '翻译')],
          language: 'en',
        ),
        throwsArgumentError,
      );
    });
  });

  group('Source and secret boundaries', () {
    test('accepts only HTTPS REST configuration and restricted mappings', () {
      final source = MusicSourceConfig(
        id: 'source-rest',
        name: 'REST Music',
        type: MusicSourceType.rest,
        baseUrl: Uri.parse('https://music.invalid/api'),
        authType: MusicSourceAuthType.bearer,
        credentialRef: 'credential-rest',
        publicHeaders: const {'Accept-Language': 'zh-CN'},
        endpoints: const {'search': '/v1/search'},
        responseMapping: const {'trackId': 'data.items[].id'},
      );

      expect(source.credentialRef, 'credential-rest');
      expect(source.publicHeaders, {'Accept-Language': 'zh-CN'});
      expect(
        () => source.publicHeaders['X-Test'] = 'x',
        throwsUnsupportedError,
      );
      expect(
        () => MusicSourceConfig(
          id: 'insecure',
          name: 'Insecure',
          type: MusicSourceType.rest,
          baseUrl: Uri.parse('http://music.invalid'),
          authType: MusicSourceAuthType.none,
        ),
        throwsArgumentError,
      );
      expect(
        () => MusicSourceConfig(
          id: 'embedded-secret',
          name: 'Embedded secret',
          type: MusicSourceType.rest,
          baseUrl: Uri.parse('https://user:password@music.invalid/api'),
          authType: MusicSourceAuthType.none,
        ),
        throwsArgumentError,
      );
    });

    test('rejects secret headers and executable response mappings', () {
      expect(
        () => _source(publicHeaders: const {'Authorization': 'Bearer secret'}),
        throwsArgumentError,
      );
      expect(
        () => _source(publicHeaders: const {'ApiKey': 'secret'}),
        throwsArgumentError,
      );
      expect(
        () => _source(publicHeaders: const {'X-Test': 'safe\r\ninjected'}),
        throwsArgumentError,
      );
      expect(
        () => _source(publicHeaders: const {' X-Test': 'safe'}),
        throwsArgumentError,
      );
      expect(
        () => _source(publicHeaders: const {'X-Test': 'one', 'x-test': 'two'}),
        throwsArgumentError,
      );
      expect(
        () => _source(responseMapping: const {'trackId': 'items.map(run())'}),
        throwsArgumentError,
      );
    });

    test('redacts credential string output and freezes secret fields', () {
      final original = {'token': 'super-secret-value'};
      final credential = SensitiveCredential(
        kind: SensitiveCredentialKind.bearerToken,
        fields: original,
      );
      original['token'] = 'mutated';

      expect(credential.fields['token'], 'super-secret-value');
      expect(credential.toString(), isNot(contains('super-secret-value')));
      expect(credential.toString(), contains('<redacted>'));
      expect(() => credential.fields['token'] = 'x', throwsUnsupportedError);
    });
  });

  test('load state and paging validate explicit boundaries at runtime', () {
    final failure = DomainFailure(
      code: DomainFailureCode.networkOffline,
      diagnosticId: 'diag-offline-1',
      retryable: true,
    );
    expect(const LoadState<List<Track>>.idle().phase, LoadPhase.idle);
    expect(const LoadState<List<Track>>.loading().phase, LoadPhase.loading);
    expect(const LoadState<List<Track>>.empty().phase, LoadPhase.empty);
    expect(LoadState<List<Track>>.data(const []).phase, LoadPhase.data);
    expect(LoadState<List<Track>>.error(failure).failure, same(failure));
    expect(() => PageRequest(offset: -1), throwsArgumentError);
    expect(() => PageRequest(limit: 201), throwsArgumentError);
    expect(
      DomainFailure(
        code: DomainFailureCode.unauthorized,
        diagnosticId: 'diag-auth-1',
        sourceId: 'source-rest',
      ).toString(),
      isNot(contains('Authorization')),
    );
    expect(
      () => DomainFailure(
        code: DomainFailureCode.unknown,
        diagnosticId: 'unsafe?id=secret',
      ),
      throwsArgumentError,
    );
  });
}

final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

Track _remoteTrack(String id) => Track(
  id: id,
  sourceId: 'source-rest',
  sourceType: MusicSourceType.rest,
  title: 'Track $id',
  artists: const ['Fixture Artist'],
  duration: const Duration(minutes: 3),
);

Track _localTrack() => Track(
  id: 'track-local',
  sourceId: 'source-local',
  sourceType: MusicSourceType.local,
  title: 'Local Track',
  artists: const ['Fixture Artist'],
  duration: const Duration(minutes: 2),
  contentUri: Uri.parse('content://media/audio/42'),
  fileFingerprint: 'sha256-local-42',
  fileSize: 1024,
);

QueueEntry _queueEntry(String id, TrackRef ref, int position) =>
    QueueEntry(id: id, track: ref, position: position, addedAt: _epoch);

MusicSourceConfig _source({
  Map<String, String> publicHeaders = const {},
  Map<String, String> responseMapping = const {},
}) => MusicSourceConfig(
  id: 'source-rest',
  name: 'REST Music',
  type: MusicSourceType.rest,
  baseUrl: Uri.parse('https://music.invalid/api'),
  authType: MusicSourceAuthType.none,
  publicHeaders: publicHeaders,
  responseMapping: responseMapping,
);
