import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio_engine.dart';
import 'playback_state.dart';

final class PlaybackController extends ChangeNotifier {
  PlaybackController(this._engine) {
    _subscription = _engine.states.listen(
      _accept,
      onError: (Object error, StackTrace stack) {
        _accept(const PlaybackState(phase: PlaybackPhase.error));
      },
    );
  }

  final AudioEngine _engine;
  late final StreamSubscription<PlaybackState> _subscription;
  PlaybackState _state = const PlaybackState();
  bool _disposed = false;

  PlaybackState get state => _state;
  bool get isAvailable => _engine.isAvailable;
  Future<void> play() => _engine.play();
  Future<void> pause() => _engine.pause();

  void _accept(PlaybackState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
