import 'dart:async';

import 'package:flutter/foundation.dart';

import '../contracts/audio_output_gateway.dart';

/// Borrows the gateway. Its owner must await close before closing the gateway.
/// Device names remain transient; observations never imply a route switch.
final class AudioOutputController extends ChangeNotifier {
  AudioOutputController(this._gateway);

  final AudioOutputGateway _gateway;
  AudioOutputSnapshot _snapshot = const AudioOutputSnapshot.unavailable();
  StreamSubscription<AudioOutputSnapshot>? _subscription;
  Future<void>? _worker, _initializing, _closing;
  bool _started = false, _pending = false, _closed = false;
  bool _notifierDisposed = false;
  int _eventRevision = 0, _notificationDepth = 0;

  AudioOutputSnapshot get snapshot => _snapshot;

  Future<void> initialize() {
    if (_closed) return _closing ?? Future<void>.value();
    return _initializing ??= _request();
  }

  /// Suitable for an explicit refresh or a future foreground lifecycle binding.
  /// Bursts during a read share one drain and request one trailing fresh read.
  Future<void> refresh() {
    if (_closed) return _closing ?? Future<void>.value();
    final work = _request();
    _initializing ??= work;
    return work;
  }

  Future<void> _request() {
    _pending = true;
    return _worker ??= Future<void>(_drainReads).whenComplete(() {
      _worker = null;
      // A request may arrive after the loop exits but before this continuation.
      if (_pending && !_closed) return _request();
    });
  }

  Future<void> _drainReads() async {
    while (!_closed && _pending) {
      _pending = false;
      final first = !_started;
      _started = true;
      if (first) {
        try {
          _subscription = _gateway.states.listen(
            (value) {
              _eventRevision++;
              _publish(value);
            },
            onError: (Object _, StackTrace _) {
              _eventRevision++;
              _publish(const AudioOutputSnapshot.unavailable());
            },
          );
        } catch (_) {
          _publish(const AudioOutputSnapshot.unavailable());
        }
      }
      if (_closed) return;
      final revision = _eventRevision;
      var value = const AudioOutputSnapshot.unavailable();
      try {
        value = await (first ? _gateway.initialize() : _gateway.refresh());
      } catch (_) {
        // Do not retain a stale route or surface a native exception/device name.
      }
      if (!_pending && revision == _eventRevision) _publish(value);
    }
  }

  void _publish(AudioOutputSnapshot value) {
    if (_closed || _snapshot == value) return;
    _snapshot = value;
    _notificationDepth++;
    try {
      notifyListeners();
    } finally {
      _notificationDepth--;
      if (_closed) dispose();
    }
  }

  @override
  void dispose() {
    if (!_closed) {
      _closed = true;
      _pending = false;
      _snapshot = const AudioOutputSnapshot.unavailable();
      // Register before invoking the borrowed subscription's cancellation hook.
      _closing = Future<void>(() async {
        try {
          await _subscription?.cancel();
        } finally {
          await _worker;
        }
      });
      unawaited(_closing!.catchError((Object _) {}));
    }
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  /// Revokes future reads, detaches observations and drains an accepted read.
  Future<void> close() {
    dispose();
    return _closing!;
  }
}
