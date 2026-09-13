import '../domain/models/domain_validation.dart';
import '../domain/models/track.dart';
import 'playable_source.dart';

/// Short-lived resolved queue item. Never persist or log its source.
final class AudioSequenceEntry {
  AudioSequenceEntry({required String entryId, required this.source})
    : entryId = DomainValidation.identifier(entryId, 'entryId');

  final String entryId;
  final PlayableSource source;
}

/// Immutable load request, not a second queue owner. Repeated tracks are valid;
/// entry IDs identify their distinct occurrences. Each request is a fresh batch.
final class AudioSequence {
  factory AudioSequence(List<AudioSequenceEntry> entries) {
    final snapshot = List<AudioSequenceEntry>.unmodifiable(entries);
    if (snapshot.isEmpty ||
        snapshot.map((entry) => entry.entryId).toSet().length !=
            snapshot.length) {
      throw ArgumentError('Audio sequence needs nonempty, unique entries');
    }
    return AudioSequence._(snapshot);
  }

  AudioSequence._(this.entries);
  final List<AudioSequenceEntry> entries;
  final Object identity = Object();

  /// State projections retain identity only, not this request or its locators.
  List<AudioSequenceCursor> get cursors => List.unmodifiable([
    for (var i = 0; i < entries.length; i++)
      AudioSequenceCursor._(
        sequenceIdentity: identity,
        index: i,
        entryId: entries[i].entryId,
        track: entries[i].source.track,
      ),
  ]);
}

/// Ephemeral playback fact. It cannot prove the root's queue is still current;
/// the root must compare the batch identity and its own queue/policy revision.
final class AudioSequenceCursor {
  const AudioSequenceCursor._({
    required this.sequenceIdentity,
    required this.index,
    required this.entryId,
    required this.track,
  });

  final Object sequenceIdentity;
  final int index;
  final String entryId;
  final TrackRef track;
}
