import 'dart:async';

import 'package:yymusic/platform/contracts/window_gateway.dart';

final class FakeWindowGateway implements WindowGateway {
  final calls = <String>[];
  final events = StreamController<WindowSnapshot>.broadcast(sync: true);
  final requests = StreamController<void>.broadcast(sync: true);
  WindowSnapshot snapshot = const WindowSnapshot(
    maximized: false,
    minimized: false,
    customFrame: true,
  );
  Future<void>? initializeGate, commandGate;
  Object? initializeError, commandError;
  bool unsupported = false;
  int disposalCount = 0;
  Future<void>? disposal;
  @override
  Stream<WindowSnapshot> get states => events.stream;
  @override
  Stream<void> get closeRequests => requests.stream;
  @override
  Future<WindowSnapshot?> initialize() async {
    calls.add('initialize');
    await initializeGate;
    if (initializeError case final error?) throw error;
    return unsupported ? null : snapshot;
  }

  Future<WindowSnapshot> _command(String name, {bool? max, bool? min}) async {
    calls.add(name);
    await commandGate;
    if (commandError case final error?) throw error;
    snapshot = WindowSnapshot(
      maximized: max ?? snapshot.maximized,
      minimized: min ?? snapshot.minimized,
      customFrame: true,
    );
    events.add(snapshot);
    return snapshot;
  }

  @override
  Future<WindowSnapshot> refresh() => _command('getState');
  @override
  Future<WindowSnapshot> minimize() => _command('minimize', min: true);
  @override
  Future<WindowSnapshot> toggleMaximize() =>
      _command('toggleMaximize', max: !snapshot.maximized, min: false);
  @override
  Future<WindowSnapshot> restore() =>
      _command('restore', max: false, min: false);
  @override
  Future<WindowSnapshot> startDrag() => _command('startDrag');
  @override
  Future<void> requestClose() async {
    calls.add('requestClose');
    requests.add(null);
  }

  @override
  Future<void> completeClose() async {
    calls.add('completeClose');
  }

  @override
  Future<void> dispose() => disposal ??= _dispose();
  Future<void> _dispose() async {
    disposalCount++;
    await events.close();
    await requests.close();
  }
}
