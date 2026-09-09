/// Native fullscreen session, not a claim that transient system bars are hidden.
final class FullscreenSnapshot {
  const FullscreenSnapshot({required this.enabled});
  final bool enabled;
}

final class FullscreenOperationException implements Exception {
  const FullscreenOperationException();
  @override
  String toString() => 'Fullscreen operation unavailable';
}

/// OS fullscreen is independent from the /player and /lyrics route stack.
abstract interface class FullscreenGateway {
  Stream<FullscreenSnapshot> get states;

  /// Null means the native runner does not implement this protocol.
  Future<FullscreenSnapshot?> initialize();
  Future<FullscreenSnapshot> enter();
  Future<FullscreenSnapshot> restore();

  /// Revoke queued commands, drain in-flight work, then restore and detach.
  Future<void> close();
}
