import 'dart:async';

import 'package:flutter/foundation.dart';

import '../platform/contracts/window_gateway.dart';

/// App-root window lifetime outlives the business graph's ordered shutdown.
final class WindowPresenter extends ChangeNotifier {
  WindowPresenter(this._gateway, {required this.beforeClose}) {
    _states = _gateway.states.listen(_accept, onError: (Object _) => _fail());
    _closeRequests = _gateway.closeRequests.listen(
      (_) => unawaited(requestClose()),
    );
  }
  final WindowGateway _gateway;
  final Future<void> Function() beforeClose;
  late final StreamSubscription<WindowSnapshot> _states;
  late final StreamSubscription<void> _closeRequests;
  WindowSnapshot? _state;
  Future<void>? _initializing, _cleanup;
  bool _busy = false, _closing = false, _disposed = false, _failed = false;
  bool get available => _state?.customFrame ?? false;
  bool get canControl => available && !_busy && !_closing && !_disposed;
  bool get maximized => _state?.maximized ?? false;
  bool get closing => _closing;
  String? get errorMessage => _failed ? '窗口操作未完成，请重试。' : null;

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    try {
      final state = await _gateway.initialize();
      if (!_disposed && state != null) _accept(state);
    } catch (_) {
      _fail();
    }
  }

  void _accept(WindowSnapshot value) {
    if (_disposed) return;
    _state = value;
    _notify();
  }

  void _fail() {
    if (_disposed) return;
    _failed = true;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _run(Future<WindowSnapshot> Function() action) async {
    if (!canControl) return;
    _busy = true;
    _failed = false;
    _notify();
    try {
      _accept(await action());
    } catch (_) {
      _fail();
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> minimize() => _run(_gateway.minimize);
  Future<void> toggleMaximize() => _run(_gateway.toggleMaximize);
  Future<void> startDrag() => _run(_gateway.startDrag);

  Future<void> requestClose() async {
    if (_closing || _disposed || !available) return;
    _closing = true;
    _failed = false;
    _notify();
    try {
      try {
        await beforeClose();
      } catch (_) {
        // Graph.close already attempted every owned resource; finish shutdown.
      }
      if (!_disposed) await _gateway.completeClose();
    } catch (_) {
      _closing = false;
      _fail();
    }
  }

  Future<void> close() {
    dispose();
    return _cleanup!;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cleanup = _release();
    unawaited(_cleanup!.catchError((Object _) {}));
    super.dispose();
  }

  Future<void> _release() async {
    await _states.cancel();
    await _closeRequests.cancel();
    await _gateway.dispose();
  }
}
