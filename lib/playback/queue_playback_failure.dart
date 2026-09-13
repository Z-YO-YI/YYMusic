import '../domain/models/domain_failure.dart';
import '../domain/models/track.dart';

/// Session-local bounded diagnostic, never an exception message or media URI.
final class QueuePlaybackFailure {
  const QueuePlaybackFailure({
    required this.entryId,
    required this.track,
    required this.code,
  });
  final String entryId;
  final TrackRef track;
  final DomainFailureCode code;
}
