import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/production_audio.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/local_playback_source_resolver.dart';
import 'package:yymusic/playback/playable_source.dart';

Track _track({String? path, Uri? content, bool remote = false}) => Track(
  id: 'local-example',
  sourceId: 'source-example',
  sourceType: remote ? MusicSourceType.rest : MusicSourceType.local,
  title: 'Example',
  artists: const ['Example'],
  duration: Duration.zero,
  localPath: path,
  contentUri: content,
  metadata: const {'streamUrl': 'https://metadata.invalid/not-an-adapter'},
);

void main() {
  test('Android preserves content identity before any path fallback', () async {
    final resolver = createProductionSourceResolver(YYPlatform.android);
    final track = _track(
      path: '/storage/example/music.wav',
      content: Uri.parse('content://media/external/audio/media/7'),
    );
    final source = await resolver.resolve(track);
    expect(source.track, track.ref);
    expect(source.kind, PlayableSourceKind.contentUri);
    expect(source.uri, track.contentUri);
    expect(source.headers, isEmpty);
    expect(source.toString(), isNot(contains('external/audio')));
    final file = await resolver.resolve(
      _track(path: '/data/example/music.wav'),
    );
    expect(file.kind, PlayableSourceKind.localFile);
    expect(file.localPath, '/data/example/music.wav');
  });

  test(
    'Windows accepts drive/UNC paths without interpreting URI characters',
    () async {
      final resolver = createProductionSourceResolver(YYPlatform.windows);
      for (final path in [
        r'C:\Music\歌曲 #1.wav',
        'D:/Music/100% music.wav',
        r'\\server\share\music.wav',
      ]) {
        final source = await resolver.resolve(_track(path: path));
        expect(source.kind, PlayableSourceKind.localFile);
        expect(source.localPath, path);
        expect(source.headers, isEmpty);
        expect(source.uri, isNull);
      }
    },
  );

  test(
    'invalid and cross-platform references fail without leaking locators',
    () async {
      for (final (resolver, track) in [
        (
          const LocalPlaybackSourceResolver.android(),
          _track(path: r'C:\Music\private-marker.wav'),
        ),
        (
          const LocalPlaybackSourceResolver.android(),
          _track(path: '//private-marker/file'),
        ),
        (
          const LocalPlaybackSourceResolver.android(),
          _track(path: '/private-marker\nfile'),
        ),
        (
          const LocalPlaybackSourceResolver.android(),
          _track(
            path: '/valid/file',
            content: Uri.parse('content:///private-marker'),
          ),
        ),
        (
          const LocalPlaybackSourceResolver.android(),
          _track(content: Uri.parse('content://user@private-marker/file')),
        ),
        (
          const LocalPlaybackSourceResolver.windows(),
          _track(path: '/private-marker/file'),
        ),
        (
          const LocalPlaybackSourceResolver.windows(),
          _track(path: 'C:private-marker'),
        ),
        (
          const LocalPlaybackSourceResolver.windows(),
          _track(path: r'\\?\C:\private-marker'),
        ),
        (
          const LocalPlaybackSourceResolver.windows(),
          _track(path: r'\\.\pipe\private-marker'),
        ),
        (
          const LocalPlaybackSourceResolver.windows(),
          _track(path: r'\\private-marker\share'),
        ),
        (
          const LocalPlaybackSourceResolver.windows(),
          _track(content: Uri.parse('content://media/private-marker')),
        ),
      ]) {
        await expectLater(
          resolver.resolve(track),
          throwsA(
            isA<DomainFailure>()
                .having(
                  (error) => error.diagnosticId,
                  'diagnostic',
                  'playback.local-reference-unavailable',
                )
                .having(
                  (error) => error.toString(),
                  'safe message',
                  isNot(contains('private-marker')),
                ),
          ),
        );
      }
    },
  );

  test(
    'REST metadata is not a source adapter and unavailable locals stay blocked',
    () async {
      for (final resolver in [
        const LocalPlaybackSourceResolver.android(),
        const LocalPlaybackSourceResolver.windows(),
      ]) {
        await expectLater(
          resolver.resolve(_track(remote: true)),
          throwsA(
            isA<DomainFailure>().having(
              (error) => error.diagnosticId,
              'adapter required',
              'playback.remote-adapter-unavailable',
            ),
          ),
        );
        await expectLater(
          resolver.resolve(
            _track(path: '/private-marker/file')
                .withAvailability(TrackAvailability.localMissing),
          ),
          throwsA(isA<DomainFailure>()),
        );
      }
    },
  );
}
