import 'package:yymusic/domain/repositories/playback_continuation_repository.dart';

final class FakePlaybackContinuationRepository
    implements PlaybackContinuationRepository {
  bool? stored;
  Object? readError, writeError;
  Future<void>? readGate, writeGate;
  int reads = 0, disposals = 0;
  final List<bool> writes = [];

  @override
  Future<bool?> read() async {
    reads++;
    final value = stored;
    await readGate;
    if (readError case final error?) throw error;
    return value;
  }

  @override
  Future<void> save(bool enabled) async {
    writes.add(enabled);
    await writeGate;
    if (writeError case final error?) throw error;
    stored = enabled;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}
