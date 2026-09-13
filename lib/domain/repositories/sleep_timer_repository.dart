import '../models/sleep_timer_snapshot.dart';

/// One dedicated setting, borrowed app storage; implementations must serialize
/// accepted operations in invocation order, including reads and clear.
abstract interface class SleepTimerRepository {
  /// Null only for missing data. Invalid data and I/O failures must not masquerade
  /// as missing, leak raw records, write defaults, or silently delete records.
  Future<SleepTimerSnapshot?> read();

  /// Atomically replaces only this setting, including its original deadline.
  Future<void> save(SleepTimerSnapshot value);

  /// Deletes only this setting; earlier saves must not resurrect it afterwards.
  Future<void> clear();

  /// Rejects new work and drains accepted work. Idempotent; never closes the
  /// borrowed database. Errors remain observable on their operation futures.
  Future<void> dispose();
}
