import 'dart:async';

import 'package:flutter/services.dart';

import '../contracts/window_gateway.dart';

/// Only this adapter knows the runner protocol; no arbitrary HWND or paths.
final class WindowsWindowGateway implements WindowGateway {
  WindowsWindowGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);
  static const channelName = 'io.github.z_y_o_y_i.yymusic/window';
  final MethodChannel _channel;
  final _states = StreamController<WindowSnapshot>.broadcast(sync: true);
  final _closeRequests = StreamController<void>.broadcast(sync: true);
  Future<WindowSnapshot?>? _initializing;
  Future<void>? _disposing;
  bool _disposed = false;
  bool _connected = false;
  @override
  Stream<WindowSnapshot> get states => _states.stream;
  @override
  Stream<void> get closeRequests => _closeRequests.stream;

  @override
  Future<WindowSnapshot?> initialize() => _initializing ??= _connect();

  Future<WindowSnapshot?> _connect() async {
    if (_disposed) throw const WindowOperationException();
    _channel.setMethodCallHandler(_handle);
    try {
      final result = _parse(
        await _channel
            .invokeMethod<Object?>('configure')
            .timeout(const Duration(seconds: 8)),
      );
      if (_disposed) return null;
      _connected = result.customFrame;
      return result;
    } on MissingPluginException {
      return null;
    } catch (_) {
      // Failed/late native setup must not leave a captionless, uncontrolled app.
      await _detach();
      throw const WindowOperationException();
    }
  }

  Future<void> _handle(MethodCall call) async {
    if (_disposed) return;
    if (call.method == 'closeRequested') {
      _closeRequests.add(null);
    } else if (call.method == 'stateChanged') {
      try {
        _states.add(_parse(call.arguments));
      } catch (_) {
        _states.addError(const WindowOperationException());
      }
    }
  }

  static WindowSnapshot _parse(Object? value) {
    if (value case {
      'maximized': final bool max,
      'minimized': final bool min,
      'customFrame': final bool custom,
    }) {
      return WindowSnapshot(
        maximized: max,
        minimized: min,
        customFrame: custom,
      );
    }
    throw const WindowOperationException();
  }

  Future<Object?> _invoke(String method, {bool drag = false}) async {
    if (_disposed || !_connected) throw const WindowOperationException();
    try {
      final pending = _channel.invokeMethod<Object?>(method);
      return await (drag
          ? pending
          : pending.timeout(const Duration(seconds: 8)));
    } catch (_) {
      throw const WindowOperationException();
    }
  }

  Future<WindowSnapshot> _state(String method, {bool drag = false}) async =>
      _parse(await _invoke(method, drag: drag));
  @override
  Future<WindowSnapshot> refresh() => _state('getState');
  @override
  Future<WindowSnapshot> minimize() => _state('minimize');
  @override
  Future<WindowSnapshot> toggleMaximize() => _state('toggleMaximize');
  @override
  Future<WindowSnapshot> restore() => _state('restore');
  @override
  Future<WindowSnapshot> startDrag() => _state('startDrag', drag: true);
  @override
  Future<void> requestClose() async {
    await _invoke('requestClose');
  }

  @override
  Future<void> completeClose() async {
    await _invoke('completeClose');
  }

  Future<void> _detach() async {
    try {
      await _channel
          .invokeMethod<void>('detach')
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Missing/disappearing runner is expected during teardown.
    }
  }

  @override
  Future<void> dispose() {
    final existing = _disposing;
    if (existing != null) return existing;
    _disposed = true;
    _channel.setMethodCallHandler(null);
    return _disposing = _release();
  }

  Future<void> _release() async {
    if (_initializing != null) await _detach();
    await _states.close();
    await _closeRequests.close();
  }
}
