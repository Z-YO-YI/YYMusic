part of 'system_playlist_controller.dart';

/// Commands use the single root player; projections never write a second queue.
extension SystemPlaylistActions on SystemPlaylistController {
  bool _canManage(SystemPlaylistContent snapshot) =>
      _canBrowse && _watchReady && identical(content, snapshot);

  bool canRemoveFavorite(SystemPlaylistContent snapshot, Object identity) =>
      type == SystemPlaylistType.favorites &&
      _canManage(snapshot) &&
      _writer.canRemoveFavorite &&
      snapshot.entries.any((e) => e.identity == identity);

  /// Accepts exact displayed references without requiring playable metadata.
  Future<void> removeFavorite(SystemPlaylistContent snapshot, Object identity) {
    if (!canRemoveFavorite(snapshot, identity)) return Future.value();
    final reference = snapshot.entries
        .firstWhere((e) => e.identity == identity)
        .reference;
    return _writer.removeFavorite(reference);
  }

  bool canClearHistory(SystemPlaylistContent snapshot) =>
      type == SystemPlaylistType.recent &&
      _canManage(snapshot) &&
      snapshot.totalCount > 0 &&
      _writer.canClearHistory;

  /// Only called after explicit native confirmation; preserves music and queue.
  Future<void> clearHistory(SystemPlaylistContent snapshot) {
    if (!canClearHistory(snapshot)) return Future.value();
    return _writer.clearHistory();
  }

  void dismissWriteFailure(SystemPlaylistWriteFailure expected) {
    if (!_disposed && _active) _writer.dismissFailure(expected);
  }

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
