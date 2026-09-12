part of 'shell_player.dart';

extension _ShellFavoriteActions on _PlayerControlsState {
  // Inline menus exclude their covered subtree without changing ModalRoute.
  bool _focusAllowsFavorite({bool createDependency = false}) {
    final node = Focus.maybeOf(
      context,
      scopeOk: true,
      createDependency: createDependency,
    );
    return node == null ||
        (node.descendantsAreFocusable &&
            node.ancestors.every(
              (ancestor) => ancestor.descendantsAreFocusable,
            ));
  }

  bool _canUseShellAction(int generation) {
    if (!mounted || !_favoriteVisible || generation != _favoriteGeneration) {
      return false;
    }
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    if (!_focusAllowsFavorite()) return false;
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
      if (!_canUseShellAction(generation)) return;
      unawaited(
        controller.setFavorite(
          expected,
          favorite: target,
          canEdit: () => _canUseShellAction(generation),
        ),
      );
    };
  }

  VoidCallback? _queueAction(int generation) =>
      _navigationAction(generation, widget.onOpenQueue);

  VoidCallback? _navigationAction(int generation, VoidCallback? open) {
    if (open == null) return null;
    return () {
      if (!_canUseShellAction(generation)) return;
      // Revoke before navigation, including rapid calls before the next frame.
      _favoriteRouteChanged();
      open();
    };
  }
}
