part of 'lyrics_screen.dart';

extension _LyricsFavoriteActions on _LyricsScreenState {
  VoidCallback? _favoriteAction(int generation) {
    final controller = widget.favorite;
    if (controller == null) return null;
    final expected = controller.state;
    if (!controller.canSet(expected) || !_wantsActive) return null;
    final target = !expected.isFavorite!;
    return () {
      if (!_canUse(generation)) return;
      unawaited(
        controller.setFavorite(
          expected,
          favorite: target,
          canEdit: () => _canUse(generation),
        ),
      );
    };
  }
}
