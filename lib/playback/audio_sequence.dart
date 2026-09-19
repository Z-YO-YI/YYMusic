import '../domain/models/domain_validation.dart';
import '../domain/models/track.dart';
import 'playable_source.dart';

/// Short-lived resolved queue item. Never persist or log its source.
final class AudioSequenceEntry {
  AudioSequenceEntry({
    required String entryId,
    required this.source,
    this.cycle = 0,
  }) : entryId = DomainValidation.identifier(entryId, 'entryId') {
    if (cycle < 0) throw ArgumentError('Audio cycle must not be negative');
  }

  final String entryId;
  final PlayableSource source;
  final int cycle;
}

/// Immutable load request, not a second queue owner. Repeated tracks are valid;
/// entry IDs identify their distinct occurrences. Each request is a fresh batch.
final class AudioSequence {
  factory AudioSequence(List<AudioSequenceEntry> entries) {
    final snapshot = List<AudioSequenceEntry>.unmodifiable(entries);
    _validateSequenceEntries(snapshot);
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
        cycle: entries[i].cycle,
      ),
  ]);
}

/// Immutable, ephemeral extension of one exact loaded tail, not a new batch.
final class AudioSequenceAppend {
  factory AudioSequenceAppend({
    required AudioSequenceCursor expectedTail,
    required List<AudioSequenceEntry> entries,
  }) {
    final snapshot = List<AudioSequenceEntry>.unmodifiable(entries);
    _validateSequenceEntries(snapshot, previousCycle: expectedTail.cycle);
    return AudioSequenceAppend._(expectedTail, snapshot);
  }
  AudioSequenceAppend._(this.expectedTail, this.entries);
  final AudioSequenceCursor expectedTail;
  final List<AudioSequenceEntry> entries;
  List<AudioSequenceCursor> get cursors => List.unmodifiable([
    for (var i = 0; i < entries.length; i++)
      AudioSequenceCursor._(
        sequenceIdentity: expectedTail.sequenceIdentity,
        index: expectedTail.index + 1 + i,
        entryId: entries[i].entryId,
        track: entries[i].source.track,
        cycle: entries[i].cycle,
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
    required this.cycle,
  });

  final Object sequenceIdentity;

  /// Absolute ordinal within the batch; native window indices may be rebased.
  final int index;
  final String entryId;
  final TrackRef track;
  final int cycle;
}

void _validateSequenceEntries(
  List<AudioSequenceEntry> entries, {
  int? previousCycle,
}) {
  if (entries.isEmpty ||
      entries.map((entry) => (entry.cycle, entry.entryId)).toSet().length !=
          entries.length) {
    throw ArgumentError('Audio sequence needs nonempty, unique occurrences');
  }
  var previous = previousCycle ?? entries.first.cycle;
  for (final entry in entries) {
    if (entry.cycle < previous || entry.cycle > previous + 1) {
      throw ArgumentError('Audio cycles must progress in order');
    }
    previous = entry.cycle;
  }
}
