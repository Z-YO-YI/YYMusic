part of 'shell_player.dart';

extension _ShellFavoriteActions on _PlayerControlsState {
  bool _canFavorite(int generation) {
    if (!mounted || !_favoriteVisible || generation != _favoriteGeneration) {
      return false;
    }
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    final box = context.findRenderObject();
    return box is RenderBox &&
        box.hasSize &&
        box.size.width > 0 &&
        box.size.height > 0;
  }

  VoidCallback? _favoriteAction(int generation) {
    final controller = widget.favorite;
    if (controller == null) return null;
    final expected = controller.state;
    if (!controller.canSet(expected)) return null;
    final target = !expected.isFavorite!;
    return () {
      if (!_canFavorite(generation)) return;
      unawaited(
        controller.setFavorite(
          expected,
          favorite: target,
          canEdit: () => _canFavorite(generation),
        ),
      );
    };
  }
}
