/// Stores only the automatic queue continuation preference, never playback state.
abstract interface class PlaybackContinuationRepository {
  /// Null means missing; corrupt/unknown records must fail without being deleted.
  Future<bool?> read();

  /// Atomically replaces this setting. Accepted operations run in call order.
  Future<void> save(bool enabled);

  /// Rejects new work and drains accepted operations; does not close borrowed DB.
  Future<void> dispose();
}
