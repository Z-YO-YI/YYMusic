import 'dart:async';

import 'package:flutter/foundation.dart';

import '../platform/contracts/fullscreen_gateway.dart';

/// Root-owned native session. Route/lifecycle changes revoke pending intent.
final class FullscreenPresenter extends ChangeNotifier {
  FullscreenPresenter(this._gateway, {required this.automatic}) {
    _subscription = _gateway.states.listen(
      _acceptEvent,
      onError: (Object _) {
        if (_closed) return;
        _failed = true;
        _desired = false;
        _needsRestore = true;
        _schedule();
      },
    );
  }

  final FullscreenGateway _gateway;
  final bool automatic;
  late final StreamSubscription<FullscreenSnapshot> _subscription;
  Future<void>? _initializing, _worker, _cleanup;
  Object? _route;
  bool Function()? _isCurrent;
  bool _eligible = false, _modal = false, _foreground = true, _visible = true;
  bool _available = false, _enabled = false, _desired = false;
  bool _closed = false, _busy = false, _failed = false, _needsRestore = false;
  bool _notifyPending = false, _enterNextPlayer = false;
  bool? _executingTarget;
  int _eventVersion = 0;

  bool get available => _available && !_closed;
  bool get enabled => _enabled;
  bool get busy => _busy;
  bool get eligible => _eligible && (_isCurrent?.call() ?? false);
  bool get _valid => eligible && _foreground && _visible && !_closed;
  bool get canToggle => available && _valid && !_busy;
  bool get canOpenPlayer =>
      available && !_modal && _foreground && _visible && !_closed;
  bool get exitBeforeBack =>
      eligible &&
      (_enabled || _desired || _executingTarget == true || _needsRestore);
  bool get hideChrome => _enabled && !_failed && !_closed;
  String? get errorMessage => _failed ? '全屏操作未完成。播放不受影响，请恢复系统显示后重试。' : null;

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    try {
      final version = _eventVersion;
      final state = await _gateway.initialize();
      if (_closed) return;
      _available = state != null;
      if (version == _eventVersion) _enabled = state?.enabled ?? false;
      if (_enabled && !_valid) _needsRestore = true;
      _schedule();
    } catch (_) {
      if (!_closed) _failed = true;
    }
    _notify();
  }

  /// Called by the root Navigator, including native popup coverage.
  void setRoute(
    Object route, {
    required bool eligible,
    required bool modal,
    required bool Function() isCurrent,
    required bool player,
  }) {
    if (_closed || identical(_route, route)) return;
    final continued = _eligible && eligible && _desired;
    _route = route;
    _eligible = eligible;
    _modal = modal;
    _isCurrent = isCurrent;
    final requested = _enterNextPlayer && player;
    _enterNextPlayer = false;
    _desired = _valid && (continued || automatic || requested);
    if (!_desired && (_enabled || _executingTarget == true)) {
      _needsRestore = true;
    }
    _schedule();
  }

  /// A single explicit keyboard intent; any different route/lifecycle revokes it.
  void enterOnNextPlayer() {
    if (canOpenPlayer) _enterNextPlayer = true;
  }

  void setForeground(bool value) {
    if (_closed || _foreground == value) return;
    _foreground = value;
    if (!value) restore();
    _notify();
  }

  void setVisible(bool value) {
    if (_closed || _visible == value) return;
    _visible = value;
    if (!value) restore();
    _notify();
  }

  void toggle() {
    if (!canToggle) return;
    _failed = false;
    _desired = !_enabled;
    _schedule();
  }

  /// Also cancels entry while its native response is still pending.
  void restore() {
    if (_closed) return;
    _desired = false;
    _enterNextPlayer = false;
    _needsRestore = _available;
    _schedule();
  }

  void _acceptEvent(FullscreenSnapshot state) {
    if (_closed) return;
    _eventVersion++;
    _enabled = state.enabled;
    // A lifecycle exit must win over an older, late enter response.
    if (!state.enabled && _executingTarget != false) _desired = false;
    if (state.enabled && !_valid) _needsRestore = true;
    _schedule();
  }

  void _schedule() {
    _notify();
    if (_closed || !_available || _worker != null) return;
    _worker = Future<void>.microtask(_drive);
  }

  Future<void> _drive() async {
    var entryFailed = false;
    try {
      while (!_closed) {
        if (!_valid) _desired = false;
        final target = _desired && !_needsRestore;
        if (!_needsRestore && _enabled == target) break;
        _busy = true;
        _executingTarget = target;
        _notify();
        final version = _eventVersion;
        try {
          final state = await (target ? _gateway.enter() : _gateway.restore());
          if (_closed) break;
          if (version == _eventVersion) _enabled = state.enabled;
          if (state.enabled != target) {
            throw const FullscreenOperationException();
          }
          if (!target) {
            _needsRestore = false;
            if (!entryFailed) _failed = false;
          } else if (!_valid || !_desired) {
            _needsRestore = true;
          }
        } catch (_) {
          if (_closed) break;
          _failed = true;
          _desired = false;
          _needsRestore = true;
          entryFailed = target;
          // One recovery attempt after a failed enter, never a retry loop.
          if (!target) break;
        } finally {
          _executingTarget = null;
        }
      }
    } finally {
      _busy = false;
      _worker = null;
      _notify();
    }
  }

  // Navigator notifications may arrive in build: defer only UI notification.
  void _notify() {
    if (_closed || _notifyPending) return;
    _notifyPending = true;
    scheduleMicrotask(() {
      _notifyPending = false;
      if (!_closed) notifyListeners();
    });
  }

  Future<void> close() {
    dispose();
    return _cleanup!;
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    _desired = _enterNextPlayer = false;
    _cleanup = _release();
    unawaited(_cleanup!.catchError((Object _) {}));
    super.dispose();
  }

  Future<void> _release() async {
    await _initializing;
    await _worker;
    await _subscription.cancel();
    await _gateway.close();
  }
}
