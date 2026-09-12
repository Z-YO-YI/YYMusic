part of 'playback_favorite_controller.dart';

extension PlaybackFavoriteActions on PlaybackFavoriteController {
  bool _current(PlaybackFavoriteState expected) =>
      !_closed &&
      _ready &&
      _repository != null &&
      expected.reference != null &&
      expected.isFavorite != null &&
      identical(state, expected);

  /// Accepts only this controller's currently displayed, known projection.
  bool canSet(PlaybackFavoriteState expected) => !_busy && _current(expected);

  /// Sets the captured target, never toggles a different track after an await.
  Future<PlaybackFavoriteEditResult> setFavorite(
    PlaybackFavoriteState expected, {
    required bool favorite,
    bool Function()? canEdit,
  }) => _setFavorite(expected, favorite: favorite, canEdit: canEdit);

  bool canRetry(PlaybackFavoriteFailure expected) =>
      identical(failure, expected) &&
      expected.kind == PlaybackFavoriteFailureKind.write &&
      canSet(expected.expected);

  /// Retries the same failed intent only while its read and queue identity live.
  Future<PlaybackFavoriteEditResult> retry(
    PlaybackFavoriteFailure expected, {
    bool Function()? canEdit,
  }) => canRetry(expected)
      ? _setFavorite(
          expected.expected,
          favorite: expected.favorite!,
          canEdit: canEdit,
          retrying: expected,
        )
      : Future.value(PlaybackFavoriteEditResult.cancelled);

  void dismissFailure(PlaybackFavoriteFailure expected) {
    if (_closed || !identical(failure, expected)) return;
    _failure = null;
    _notify();
  }

  Future<PlaybackFavoriteEditResult> _setFavorite(
    PlaybackFavoriteState expected, {
    required bool favorite,
    bool Function()? canEdit,
    PlaybackFavoriteFailure? retrying,
  }) {
    if (_closed) return Future.value(PlaybackFavoriteEditResult.cancelled);
    if (_busy) return Future.value(PlaybackFavoriteEditResult.busy);
    if (!_current(expected)) {
      return Future.value(PlaybackFavoriteEditResult.cancelled);
    }
    if (favorite == expected.isFavorite) {
      return Future.value(PlaybackFavoriteEditResult.unchanged);
    }
    final done = Completer<PlaybackFavoriteEditResult>();
    _busy = true;
    _track(() async {
      var result = PlaybackFavoriteEditResult.cancelled;
      try {
        if (_current(expected) &&
            (canEdit?.call() ?? true) &&
            _current(expected)) {
          await _repository!.setFavorite(
            expected.reference!,
            favorite: favorite,
          );
          // Repository emissions alone update state, including external writes.
          result = PlaybackFavoriteEditResult.applied;
          if (retrying != null && identical(_failure, retrying)) {
            _failure = null;
          }
        }
      } catch (_) {
        _failure = PlaybackFavoriteFailure._(
          PlaybackFavoriteFailureKind.write,
          expected,
          favorite,
        );
        result = PlaybackFavoriteEditResult.failed;
      } finally {
        _busy = false;
        done.complete(result);
        _notify();
      }
    });
    _notify();
    return done.future;
  }
}
