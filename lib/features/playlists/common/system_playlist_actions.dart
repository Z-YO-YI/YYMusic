part of 'system_playlist_controller.dart';

/// Commands use the single root player; projections never write a second queue.
extension SystemPlaylistActions on SystemPlaylistController {
  bool canPlayEntry(SystemPlaylistContent snapshot, Object identity) {
    if (!_canBrowse ||
        !identical(content, snapshot) ||
        !(_playback?.isAvailable ?? false)) {
      return false;
    }
    final entry = snapshot.entries
        .where((e) => e.identity == identity)
        .firstOrNull;
    if (entry == null || !entry.isAvailable) return false;
    return type != SystemPlaylistType.queue || _rootContains(entry);
  }

  bool _rootContains(SystemPlaylistEntry entry) => _playback!
      .state
      .queue
      .entries
      .any((e) => e.id == entry.entryId && e.track == entry.reference);

  /// Accepts only a currently displayed entry and preserves duplicate queue IDs.
  Future<void> playEntry(SystemPlaylistContent snapshot, Object identity) {
    if (!canPlayEntry(snapshot, identity)) return Future.value();
    final entry = snapshot.entries.firstWhere((e) => e.identity == identity);
    final intent = ++_intent;
    bool current() =>
        !_disposed &&
        _active &&
        _watchReady &&
        intent == _intent &&
        (type != SystemPlaylistType.queue || _rootContains(entry));
    _actionBusy = true;
    _actionError = null;
    final work = _track(() async {
      try {
        if (!current()) return;
        if (type == SystemPlaylistType.queue) {
          await _playback!.playEntry(entry.entryId!, canPlay: current);
        } else {
          await _playback!.playCatalogTrack(entry.reference, canPlay: current);
        }
      } catch (_) {
        if (current()) _actionError = '播放未完成，请重试。';
      } finally {
        _actionBusy = false;
        _notify();
      }
    });
    _notify();
    return work;
  }
}
