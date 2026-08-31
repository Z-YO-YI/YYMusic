import 'app_routes.dart';

/// Session-only presentation state. Persistence belongs to a later phase.
final class AppViewState {
  final Map<AppRoute, double> _offsets = {};
  final Map<AppRoute, String> _selections = {};

  double scrollOffset(AppRoute route) => _offsets[route] ?? 0;

  void saveScrollOffset(AppRoute route, double offset) {
    if (!offset.isFinite) throw ArgumentError.value(offset, 'offset');
    _offsets[route] = offset < 0 ? 0 : offset;
  }

  String? selection(AppRoute route) => _selections[route];
  void select(AppRoute route, String? id) {
    if (id == null) {
      _selections.remove(route);
    } else {
      _selections[route] = id;
    }
  }
}
