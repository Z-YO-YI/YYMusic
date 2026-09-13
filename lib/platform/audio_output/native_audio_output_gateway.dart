import 'dart:async';

import 'package:flutter/services.dart';

import '../contracts/audio_output_gateway.dart';

/// Read/launch-only protocol. No arbitrary URI, device ID, or playback command.
final class NativeAudioOutputGateway implements AudioOutputGateway {
  NativeAudioOutputGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);
  static const channelName = 'io.github.z_y_o_y_i.yymusic/audio-output';
  final MethodChannel _channel;
  final _states = StreamController<AudioOutputSnapshot>.broadcast(sync: true);
  Future<void> _tail = Future<void>.value();
  Future<AudioOutputSnapshot>? _initializing;
  Future<void>? _closing;
  bool _closed = false;
  bool _canOpenSettings = false;

  @override
  Stream<AudioOutputSnapshot> get states => _states.stream;

  Future<T> _enqueue<T>(Future<T> Function() operation, T closedValue) {
    final result = _tail.then<T>((_) async {
      if (_closed) return closedValue;
      return operation();
    });
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<Object?> _invoke(String method) => _channel
      .invokeMethod<Object?>(method)
      .timeout(const Duration(seconds: 8));

  static AudioOutputSnapshot _parse(Object? value) {
    if (value is! Map || value['canOpenSettings'] is! bool) {
      throw const FormatException('Invalid output snapshot');
    }
    final observation = value['observation'];
    final label = value['label'];
    final AudioOutputRoute route;
    if (observation == 'unknown' && value.length == 2) {
      route = const AudioOutputRoute.unknown();
    } else if (label is String && value.length == 3) {
      route = switch (observation) {
        'systemDefault' => AudioOutputRoute.systemDefault(label),
        'playerRoute' => AudioOutputRoute.playerRoute(label),
        _ => throw const FormatException('Invalid output observation'),
      };
    } else {
      throw const FormatException('Invalid output snapshot');
    }
    return AudioOutputSnapshot(
      route: route,
      canOpenSettings: value['canOpenSettings'] as bool,
    );
  }

  Future<AudioOutputSnapshot> _read() async {
    var snapshot = const AudioOutputSnapshot.unavailable();
    try {
      snapshot = _parse(await _invoke('getState'));
    } catch (_) {
      // Missing host, denied access and malformed/stale data are not a route.
    }
    if (_closed) return const AudioOutputSnapshot.unavailable();
    _canOpenSettings = snapshot.canOpenSettings;
    _states.add(snapshot);
    return _closed ? const AudioOutputSnapshot.unavailable() : snapshot;
  }

  @override
  Future<AudioOutputSnapshot> initialize() {
    if (_closed) return Future.value(const AudioOutputSnapshot.unavailable());
    return _initializing ??= _enqueue(
      _read,
      const AudioOutputSnapshot.unavailable(),
    );
  }

  @override
  Future<AudioOutputSnapshot> refresh() =>
      _enqueue(_read, const AudioOutputSnapshot.unavailable());

  @override
  Future<AudioOutputSettingsResult> openSystemSettings() => _enqueue(() async {
    if (!_canOpenSettings) return AudioOutputSettingsResult.unavailable;
    try {
      return switch (await _invoke('openSystemSettings')) {
        'opened' => AudioOutputSettingsResult.opened,
        'unavailable' => AudioOutputSettingsResult.unavailable,
        _ => AudioOutputSettingsResult.failed,
      };
    } on MissingPluginException {
      _canOpenSettings = false;
      return AudioOutputSettingsResult.unavailable;
    } catch (_) {
      return AudioOutputSettingsResult.failed;
    }
  }, AudioOutputSettingsResult.unavailable);

  @override
  Future<void> close() {
    _closed = true;
    return _closing ??= _release();
  }

  Future<void> _release() async {
    await _tail;
    _canOpenSettings = false;
    await _states.close();
  }
}
