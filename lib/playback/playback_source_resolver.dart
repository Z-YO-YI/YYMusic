import '../domain/models/domain_failure.dart';
import '../domain/models/track.dart';
import 'playable_source.dart';

/// Resolves a stable Track into one short-lived source immediately before load.
abstract interface class PlaybackSourceResolver {
  Future<PlayableSource> resolve(Track track);
}

final class UnavailablePlaybackSourceResolver
    implements PlaybackSourceResolver {
  const UnavailablePlaybackSourceResolver();

  @override
  Future<PlayableSource> resolve(Track track) async => throw DomainFailure(
    code: DomainFailureCode.playbackOpenFailed,
    diagnosticId: 'playback.source-resolver-unavailable',
    sourceId: track.sourceId,
  );
}
