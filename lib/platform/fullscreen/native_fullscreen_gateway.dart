import 'dart:async';

import 'package:flutter/services.dart';

import '../contracts/fullscreen_gateway.dart';

/// One root-owned channel instance; never accepts HWND, paths or UI flags.
final class NativeFullscreenGateway implements FullscreenGateway {
  NativeFullscreenGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);
  static const channelName = 'io.github.z_y_o_y_i.yymusic/fullscreen';
  final MethodChannel _channel;
  final _states = StreamController<FullscreenSnapshot>.broadcast(sync: true);
  Future<void> _tail = Future<void>.value();
  Future<FullscreenSnapshot?>? _initializing;
  Future<void>? _closing;
  bool _closed = false, _connected = false;

  @override
  Stream<FullscreenSnapshot> get states => _states.stream;

  static FullscreenSnapshot _parse(Object? value) {
    if (value case {'enabled': final bool enabled}) {
      return FullscreenSnapshot(enabled: enabled);
    }
    throw const FullscreenOperationException();
  }

  Future<Object?> _invoke(String method) => _channel
      .invokeMethod<Object?>(method)
      .timeout(const Duration(seconds: 8));

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    if (_closed) return Future<T>.error(const FullscreenOperationException());
    final result = _tail.then((_) async {
      if (_closed) throw const FullscreenOperationException();
      try {
        return await operation();
      } catch (_) {
        throw const FullscreenOperationException();
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<FullscreenSnapshot?> initialize() {
    if (_closed) return Future.error(const FullscreenOperationException());
    return _initializing ??= _enqueue(() async {
      _channel.setMethodCallHandler(_event);
      try {
        final state = _parse(await _invoke('configure'));
        _connected = !_closed;
        return _closed ? null : state;
      } on MissingPluginException {
        return null;
      }
    });
  }

  Future<void> _event(MethodCall call) async {
    if (_closed || !_connected || call.method != 'stateChanged') return;
    try {
      _states.add(_parse(call.arguments));
    } catch (_) {
      _states.addError(const FullscreenOperationException());
    }
  }

  Future<FullscreenSnapshot> _command(String method) => _enqueue(() async {
    if (!_connected) throw const FullscreenOperationException();
    return _parse(await _invoke(method));
  });
  @override
  Future<FullscreenSnapshot> enter() => _command('enter');
  @override
  Future<FullscreenSnapshot> restore() => _command('restore');

  @override
  Future<void> close() {
    if (_closing != null) return _closing!;
    _closed = true;
    return _closing = _release();
  }

  Future<void> _release() async {
    await _tail;
    try {
      if (_initializing != null) {
        try {
          await _invoke('detach');
        } on MissingPluginException {
          // Unsupported host never acquired a native session.
        }
      }
    } catch (_) {
      throw const FullscreenOperationException();
    } finally {
      _connected = false;
      _channel.setMethodCallHandler(null);
      await _states.close();
    }
  }
}
