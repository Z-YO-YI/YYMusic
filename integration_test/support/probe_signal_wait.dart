import 'dart:async';

/// Waits for observed facts, cancelling its subscription on every exit path.
/// A deadline is failure, never synthesized progress or successful playback.
Future<void> waitForProbeSignal(
  Stream<void> signals,
  bool Function() accepted,
  Duration timeout,
) async {
  if (accepted()) return;
  final done = Completer<void>();
  void check() {
    if (done.isCompleted) return;
    try {
      if (accepted()) done.complete();
    } catch (error, stack) {
      done.completeError(error, stack);
    }
  }

  final subscription = signals.listen(
    (_) => check(),
    onError: (Object error, StackTrace stack) {
      if (!done.isCompleted) done.completeError(error, stack);
    },
    onDone: () {
      if (!done.isCompleted) {
        done.completeError(StateError('Native probe signal closed'));
      }
    },
  );
  final timer = Timer(timeout, () {
    if (!done.isCompleted) {
      done.completeError(TimeoutException('Native probe observation deadline'));
    }
  });
  try {
    check();
    await done.future;
  } finally {
    timer.cancel();
    await subscription.cancel();
  }
}
