part of 'player_screen.dart';

extension _PlayerFavoriteActions on _PlayerScreenState {
  VoidCallback? _favoriteAction(int generation) {
    final controller = widget.favorite;
    if (controller == null) return null;
    final expected = controller.state;
    if (!controller.canSet(expected)) return null;
    final target = !expected.isFavorite!;
    return () {
      if (!_canInteract(generation)) return;
      unawaited(
        controller.setFavorite(
          expected,
          favorite: target,
          canEdit: () => _canInteract(generation),
        ),
      );
    };
  }
}
