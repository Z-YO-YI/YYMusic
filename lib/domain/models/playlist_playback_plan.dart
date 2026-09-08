import 'domain_validation.dart';
import 'track.dart';

/// Playback-only reference; never contains media paths, URLs or full metadata.
final class PlaylistPlaybackEntry {
  PlaylistPlaybackEntry({
    required String id,
    required this.position,
    required this.track,
    this.availability,
  }) : id = DomainValidation.identifier(id, 'entryId') {
    if (position < 0) throw ArgumentError('Negative playlist position');
  }
  final String id;
  final int position;
  final TrackRef track;
  final TrackAvailability? availability;
  bool get isAvailable => availability == TrackAvailability.available;
}

/// Complete lightweight snapshot for an explicit whole-playlist command.
/// Unlike a browse window it is not truncated, joined to artists or cached in UI.
final class PlaylistPlaybackPlan {
  PlaylistPlaybackPlan({
    required String playlistId,
    required Iterable<PlaylistPlaybackEntry> entries,
  }) : playlistId = DomainValidation.identifier(playlistId, 'playlistId'),
       entries = List.unmodifiable(entries) {
    final ids = <String>{};
    for (var i = 0; i < this.entries.length; i++) {
      final entry = this.entries[i];
      if (entry.position != i || !ids.add(entry.id)) {
        throw ArgumentError('Incomplete or ambiguous playlist playback plan');
      }
    }
  }
  final String playlistId;
  final List<PlaylistPlaybackEntry> entries;
}
