import 'package:yymusic/domain/models/sleep_timer_snapshot.dart';
import 'package:yymusic/domain/repositories/sleep_timer_repository.dart';

final class FakeSleepTimerRepository implements SleepTimerRepository {
  SleepTimerSnapshot? stored;
  final writes = <SleepTimerSnapshot?>[];
  int reads = 0, disposeCount = 0;
  Future<void>? readGate, writeGate;
  Object? readError, writeError;
  Future<void> Function(SleepTimerSnapshot?)? onWrite;
  bool closed = false;
  @override
  Future<SleepTimerSnapshot?> read() async {
    if (closed) throw StateError('closed');
    reads++;
    final value = stored;
    await readGate;
    if (readError case final error?) throw error;
    return value;
  }

  Future<void> _write(SleepTimerSnapshot? value) async {
    if (closed) throw StateError('closed');
    writes.add(value);
    await writeGate;
    await onWrite?.call(value);
    if (writeError case final error?) throw error;
    if (closed) throw StateError('closed before write finished');
    stored = value;
  }

  @override
  Future<void> save(SleepTimerSnapshot value) => _write(value);
  @override
  Future<void> clear() => _write(null);
  @override
  Future<void> dispose() async {
    closed = true;
    disposeCount++;
  }
}
