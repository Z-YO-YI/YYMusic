part of 'playlist_content_controller.dart';

/// Actions borrow root services; content remains the repository projection.
extension PlaylistContentActions on PlaylistContentController {
  void setActive(bool value) {
    if (_disposed || _active == value) return;
    _active = value;
    if (!value) _intent++;
  }

  PlaylistContentEntry? entryFor(String id) =>
      content?.entries.where((e) => e.entry.id == id).firstOrNull;

  bool canOpenEntry(String id) =>
      !_disposed && _active && isCurrent && entryFor(id) != null;

  bool canPlayEntry(String id) =>
      canOpenEntry(id) &&
      !busy &&
      (_playback?.isAvailable ?? false) &&
      entryFor(id)!.isAvailable;

  bool canManageEntry(String id) =>
      canOpenEntry(id) && !busy && (_writer?.isAvailable ?? false);

  bool canMoveEntry(String id, {required bool up}) {
    if (!canManageEntry(id)) return false;
    final items = content!.entries;
    final index = items.indexWhere((e) => e.entry.id == id);
    return up
        ? index > 0
        : index + 1 < items.length &&
              (index + 2 < items.length || !content!.hasMore);
  }

  Future<void> playEntry(String id) {
    if (!canPlayEntry(id)) return Future.value();
    final entry = entryFor(id)!.entry;
    final intent = _intent;
    _actionBusy = true;
    _actionError = null;
    final work = _track(() async {
      try {
        await _playback!.playCatalogTrack(
          entry.track,
          canPlay: () => !_disposed && _active && intent == _intent,
        );
      } catch (_) {
        if (!_disposed && intent == _intent) _actionError = '播放未完成，请重试。';
      } finally {
        _actionBusy = false;
        _notify();
      }
    });
    _notify();
    return work;
  }

  Future<void> removeEntry(String id) {
    if (!canManageEntry(id)) return Future.value();
    return _writeEntry(() => _writer!.removeEntry(playlistId, id));
  }

  Future<void> moveEntry(String id, {required bool up}) {
    if (!canMoveEntry(id, up: up)) return Future.value();
    final items = content!.entries;
    final index = items.indexWhere((e) => e.entry.id == id);
    final anchor = up
        ? items[index - 1].entry.id
        : index + 2 < items.length
        ? items[index + 2].entry.id
        : null;
    return _writeEntry(
      () => _writer!.moveEntry(playlistId, id, beforeEntryId: anchor),
    );
  }

  Future<void> _writeEntry(Future<PlaylistCommandResult> Function() invoke) {
    _actionBusy = true;
    _actionError = null;
    _intent++;
    final result = Completer<PlaylistCommandResult>();
    // Register first, then let the root writer synchronously accept the command.
    final work = _track(() async {
      try {
        final outcome = await result.future;
        if (!_disposed) {
          if (!outcome.succeeded) _actionError = outcome.message;
          if (_watchReady) _requestRead();
        }
      } finally {
        _actionBusy = false;
        _notify();
      }
    });
    try {
      result.complete(invoke());
    } catch (_) {
      result.complete(
        const PlaylistCommandResult(PlaylistCommandStatus.failed),
      );
    }
    _notify();
    return work;
  }
}
