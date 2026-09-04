import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/platform/contracts/media_session_gateway.dart';
import 'package:yymusic/playback/playable_source.dart';
import 'package:yymusic/playback/playback_source_resolver.dart';
import 'package:yymusic/playback/playback_state.dart';

final class FakePlaybackSourceResolver implements PlaybackSourceResolver {
  FakePlaybackSourceResolver({this.failure});

  final DomainFailure? failure;
  final List<TrackRef> resolved = [];

  @override
  Future<PlayableSource> resolve(Track track) async {
    resolved.add(track.ref);
    final error = failure;
    if (error != null) throw error;
    if (track.sourceType == MusicSourceType.local) {
      final contentUri = track.contentUri;
      if (contentUri != null) {
        return PlayableSource.contentUri(track: track.ref, uri: contentUri);
      }
      return PlayableSource.localFile(track: track.ref, path: track.localPath!);
    }
    return PlayableSource.networkStream(
      track: track.ref,
      uri: Uri.parse('https://media.invalid/ephemeral-stream'),
      headers: const {'Authorization': 'Bearer test-only-secret'},
    );
  }
}

final class FakeMediaSessionGateway implements MediaSessionGateway {
  MediaSessionCallbacks? callbacks;
  final List<String> calls = [];
  final List<TrackRef> metadata = [];
  final List<PlaybackState> states = [];
  int disposalCount = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<void> initialize(MediaSessionCallbacks value) async {
    callbacks = value;
    calls.add('initialize');
  }

  @override
  Future<void> updateMetadata(Track track) async {
    metadata.add(track.ref);
    calls.add('metadata');
  }

  @override
  Future<void> updatePlaybackState(PlaybackState state) async {
    states.add(state);
    calls.add('state');
  }

  @override
  Future<void> clear() async => calls.add('clear');

  @override
  Future<void> dispose() async {
    disposalCount++;
    calls.add('dispose');
  }
}
