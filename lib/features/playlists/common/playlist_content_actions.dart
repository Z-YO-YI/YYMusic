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

  /// A soft reference may be queued even when its metadata is unavailable.
  bool Function()? queueSourcePermit(
    PlaylistContent expected,
    PlaylistContentEntry entry,
  ) {
    bool available() =>
        !_disposed &&
        _active &&
        isCurrent &&
        !busy &&
        identical(content, expected) &&
        expected.entries.any((item) => identical(item, entry));
    if (!available()) return null;
    final intent = _intent;
    return () => intent == _intent && available();
  }

  bool get canPlayAll =>
      _canBrowse &&
      (_playback?.isAvailable ?? false) &&
      (content?.totalCount ?? 0) > 0;

  /// Reads a complete lightweight plan, not the currently displayed window.
  Future<void> playAll(PlaylistContent expected, {required bool shuffle}) {
    if (!canPlayAll || !identical(content, expected)) return Future.value();
    final intent = ++_intent;
    bool current() => !_disposed && _active && intent == _intent;
    _actionBusy = true;
    _actionError = _actionNote = null;
    final work = _track(() async {
      try {
        if (!current()) return;
        final plan = await _repository!.readPlaylistPlaybackPlan(playlistId);
        if (!current()) return;
        if (plan == null) {
          _actionError = '此歌单已不存在，请刷新。';
          return;
        }
        if (plan.playlistId != playlistId) {
          throw StateError('Wrong playlist plan');
        }
        final tracks = plan.entries
            .where((e) => e.isAvailable)
            .map((e) => e.track)
            .toList();
        if (tracks.isEmpty) {
          _actionNote = '歌单中没有可播放的歌曲，当前队列未改变。';
          return;
        }
        final started = await _playback!.playCatalogSelection(
          tracks,
          shuffle: shuffle,
          canPlay: current,
        );
        if (current() && started) {
          final skipped = plan.entries.length - tracks.length;
          _actionNote =
              '已切换到包含 ${tracks.length} 首歌曲的队列。'
              '${skipped == 0 ? '' : '跳过 $skipped 条不可用引用，原歌单仍保留。'}';
        }
      } catch (_) {
        if (current()) _actionError = '歌单播放未完成，请重试。';
      } finally {
        _actionBusy = false;
        _notify();
      }
    });
    _notify();
    return work;
  }

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
    _actionNote = null;
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
    _actionNote = null;
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
