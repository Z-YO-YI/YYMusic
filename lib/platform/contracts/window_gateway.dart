/// Native window state; never inferred from the current Flutter viewport.
final class WindowSnapshot {
  const WindowSnapshot({
    required this.maximized,
    required this.minimized,
    required this.customFrame,
  });
  final bool maximized, minimized, customFrame;
}

final class WindowOperationException implements Exception {
  const WindowOperationException();
  @override
  String toString() => 'Window operation unavailable';
}

abstract interface class WindowGateway {
  Stream<WindowSnapshot> get states;
  Stream<void> get closeRequests;

  /// Null means this runner does not implement window controls.
  Future<WindowSnapshot?> initialize();
  Future<WindowSnapshot> refresh();
  Future<WindowSnapshot> minimize();
  Future<WindowSnapshot> toggleMaximize();
  Future<WindowSnapshot> restore();
  Future<WindowSnapshot> startDrag();
  Future<void> requestClose();
  Future<void> completeClose();
  Future<void> dispose();
}
