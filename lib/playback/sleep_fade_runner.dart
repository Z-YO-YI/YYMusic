import 'dart:async';

import 'sleep_fade_envelope.dart';

enum SleepFadeStatus { completed, cancelled, failed }

enum SleepFadeOperation { ownership, clock, gain, pause, schedule, restore }

/// Safe diagnostics: never expose backend exception messages or source data.
final class SleepFadeOutcome {
  const SleepFadeOutcome(
    this.status, {
    this.failure,
    this.restorationFailed = false,
  });

  final SleepFadeStatus status;
  final SleepFadeOperation? failure;
  final bool restorationFailed;
}

/// One root-owned fade. Each callback must use the root's command serialization.
///
/// Waiting occurs outside that queue. [writeGain] receives a multiplier, not a
/// user volume: the owner must apply its latest intent and shield UI projection.
/// [restore] must remain usable during owner shutdown and restore the latest
/// intent, even after a cancelled in-flight write. No engine is owned here.
final class SleepFadeRunner {
  factory SleepFadeRunner({
    required Future<void> Function(double) writeGain,
    required Future<void> Function() pause,
    required Future<void> Function() restore,
    required bool Function() isCurrent,
    Duration Function()? elapsed,
    Timer Function(Duration, void Function())? scheduler,
  }) => SleepFadeRunner._(
    writeGain,
    pause,
    restore,
    isCurrent,
    elapsed,
    scheduler ?? Timer.new,
  );

  SleepFadeRunner._(
    this._writeGain,
    this._pause,
    this._restore,
    this._isCurrent,
    this._elapsed,
    this._scheduler,
  );

  final Future<void> Function(double) _writeGain;
  final Future<void> Function() _pause;
  final Future<void> Function() _restore;
  final bool Function() _isCurrent;
  final Duration Function()? _elapsed;
  final Timer Function(Duration, void Function()) _scheduler;
  Future<SleepFadeOutcome>? _done;
  Timer? _wake;
  Completer<void>? _waiting;
  bool _cancelled = false;

  /// Idempotent; registration precedes any borrowed callback or reentrant close.
  Future<SleepFadeOutcome> start() => _done ??= Future<SleepFadeOutcome>(_run);

  void cancel() {
    _cancelled = true;
    _wake?.cancel();
    _wake = null;
    final waiting = _waiting;
    _waiting = null;
    if (waiting != null && !waiting.isCompleted) waiting.complete();
  }

  /// Cancels waits, drains accepted callbacks and observes restoration failure.
  Future<SleepFadeOutcome> close() {
    cancel();
    return start();
  }

  Future<SleepFadeOutcome> _run() async {
    final watch = Stopwatch()..start();
    var elapsed = Duration.zero;
    var operation = SleepFadeOperation.ownership;
    SleepFadeOperation? failure;
    var restorationFailed = false;
    var touched = false;
    var status = SleepFadeStatus.cancelled;
    try {
      while (true) {
        operation = SleepFadeOperation.ownership;
        if (_cancelled || !_isCurrent()) break;
        operation = SleepFadeOperation.clock;
        final observed = _elapsed?.call() ?? watch.elapsed;
        if (observed > elapsed) elapsed = observed;
        operation = SleepFadeOperation.ownership;
        if (_cancelled || !_isCurrent()) break;
        operation = SleepFadeOperation.gain;
        // A failed write can still have changed native amplitude.
        touched = true;
        await _writeGain(SleepFadeEnvelope.gainAt(elapsed));
        operation = SleepFadeOperation.ownership;
        if (_cancelled || !_isCurrent()) break;
        if (SleepFadeEnvelope.isComplete(elapsed)) {
          operation = SleepFadeOperation.pause;
          await _pause();
          operation = SleepFadeOperation.ownership;
          if (!_cancelled && _isCurrent()) status = SleepFadeStatus.completed;
          break;
        }
        operation = SleepFadeOperation.schedule;
        await _wait(SleepFadeEnvelope.nextDelay(elapsed));
      }
    } catch (_) {
      failure = operation;
      status = SleepFadeStatus.failed;
    } finally {
      watch.stop();
      _wake?.cancel();
      _wake = null;
      if (touched) {
        try {
          await _restore();
        } catch (_) {
          restorationFailed = true;
          failure ??= SleepFadeOperation.restore;
          status = SleepFadeStatus.failed;
        }
      }
    }
    return SleepFadeOutcome(
      status,
      failure: failure,
      restorationFailed: restorationFailed,
    );
  }

  Future<void> _wait(Duration delay) async {
    if (_cancelled) return;
    final waiting = Completer<void>();
    _waiting = waiting;
    try {
      final wake = _scheduler(delay, () {
        if (!identical(_waiting, waiting)) return;
        _waiting = null;
        if (!waiting.isCompleted) waiting.complete();
      });
      // A scheduler may fire or cancel reentrantly before returning its Timer.
      if (_cancelled || !identical(_waiting, waiting)) {
        wake.cancel();
      } else {
        _wake = wake;
      }
      await waiting.future;
    } finally {
      if (identical(_waiting, waiting)) _waiting = null;
      _wake?.cancel();
      _wake = null;
    }
  }
}
