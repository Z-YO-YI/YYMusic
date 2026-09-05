import '../domain/models/domain_failure.dart';
import '../domain/models/track.dart';
import 'playable_source.dart';
import 'playback_source_resolver.dart';

/// Converts repository-owned local references; does not scan or access media.
final class LocalPlaybackSourceResolver implements PlaybackSourceResolver {
  const LocalPlaybackSourceResolver.android() : _android = true;
  const LocalPlaybackSourceResolver.windows() : _android = false;

  final bool _android;

  @override
  Future<PlayableSource> resolve(Track track) async {
    if (track.sourceType != MusicSourceType.local) {
      throw DomainFailure(
        code: DomainFailureCode.playbackOpenFailed,
        diagnosticId: 'playback.remote-adapter-unavailable',
        sourceId: track.sourceId,
      );
    }
    try {
      if (track.availability != TrackAvailability.available) {
        throw StateError('Local track is unavailable');
      }
      final content = track.contentUri;
      if (_android && content != null) {
        if (content.host.isEmpty ||
            content.userInfo.isNotEmpty ||
            content.hasFragment) {
          throw const FormatException('Invalid content reference');
        }
        return PlayableSource.contentUri(track: track.ref, uri: content);
      }
      final path = track.localPath;
      if (path == null || RegExp(r'[\x00-\x1f]').hasMatch(path)) {
        throw const FormatException('Missing local path');
      }
      final valid = _android
          ? path.startsWith('/') && !path.startsWith('//')
          : RegExp(r'^[A-Za-z]:[\\/].+').hasMatch(path) ||
                (RegExp(r'^\\\\[^\\/]+\\[^\\/]+\\.+').hasMatch(path) &&
                    !path.startsWith(r'\\?\') &&
                    !path.startsWith(r'\\.\'));
      if (!valid) throw const FormatException('Invalid platform local path');
      return PlayableSource.localFile(track: track.ref, path: path);
    } catch (_) {
      throw DomainFailure(
        code: DomainFailureCode.playbackOpenFailed,
        diagnosticId: 'playback.local-reference-unavailable',
        sourceId: track.sourceId,
      );
    }
  }
}
