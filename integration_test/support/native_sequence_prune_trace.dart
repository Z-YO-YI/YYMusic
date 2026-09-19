import 'package:yymusic/playback/just_audio_backend.dart';

/// Probe-only stages; no native messages or media identifiers are accepted.
enum NativeSequencePruneStage { before, snapshot, accepted, rejected, failed }

/// Bounded raw facts for diagnosing a failed prefix edit, not a success result.
final class NativeSequencePruneTrace {
  static const maxSamples = 32;
  final List<Map<String, Object?>> _samples = [];
  (int?, JustAudioProcessingPhase, bool, int)? _previousSnapshot;
  var _droppedSamples = 0;

  /// Keeps the initial sample and a bounded tail; repeated 100ms buckets coalesce.
  void record(
    NativeSequencePruneStage stage,
    JustAudioPlayerSnapshot snapshot, {
    required Duration elapsed,
  }) {
    final key = (
      snapshot.currentIndex,
      snapshot.processing,
      snapshot.playing,
      snapshot.position.inMilliseconds ~/ 100,
    );
    if (stage == NativeSequencePruneStage.snapshot &&
        key == _previousSnapshot) {
      return;
    }
    _previousSnapshot = key;
    if (_samples.length == maxSamples) {
      _samples.removeAt(1);
      _droppedSamples++;
    }
    _samples.add(
      Map.unmodifiable({
        'stage': stage.name,
        'elapsedMs': elapsed.inMilliseconds,
        'rawIndex': snapshot.currentIndex,
        'processing': snapshot.processing.name,
        'playing': snapshot.playing,
        'positionMs': snapshot.position.inMilliseconds,
      }),
    );
  }

  /// Deliberately separate from nativeSequence success metrics and host gates.
  Map<String, Object?> toJson({required String sourceCommit}) {
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(sourceCommit)) {
      throw const FormatException('Invalid diagnostic identity');
    }
    return Map.unmodifiable({
      'schemaVersion': 1,
      'sourceCommit': sourceCommit,
      'purpose': 'native-sequence-prefix-trace',
      'droppedSamples': _droppedSamples,
      'samples': List<Map<String, Object?>>.unmodifiable(_samples),
    });
  }
}
