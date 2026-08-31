/// OS fullscreen is independent from the /player and /lyrics route stack.
abstract interface class FullscreenGateway {
  bool get isSupported;
  Future<void> enter();
  Future<void> restore();
}
