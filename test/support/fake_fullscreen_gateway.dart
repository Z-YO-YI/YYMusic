import 'dart:async';

import 'package:yymusic/platform/contracts/fullscreen_gateway.dart';

final class FakeFullscreenGateway implements FullscreenGateway {
  final calls = <String>[];
  final events = StreamController<FullscreenSnapshot>.broadcast(sync: true);
  bool enabled = false,
      supported = true,
      failEnter = false,
      failRestore = false;
  bool failInitialize = false;
  Future<void>? initializeWait, closeWait;
  Future<FullscreenSnapshot> Function()? onEnter;
  Future<FullscreenSnapshot?> Function()? onInitialize;
  Future<void>? _close;

  @override
  Stream<FullscreenSnapshot> get states => events.stream;
  @override
  Future<FullscreenSnapshot?> initialize() async {
    calls.add('initialize');
    if (onInitialize case final action?) return action();
    await initializeWait;
    if (failInitialize) throw StateError('private diagnostic');
    return supported ? FullscreenSnapshot(enabled: enabled) : null;
  }

  void emit(bool value) {
    enabled = value;
    events.add(FullscreenSnapshot(enabled: value));
  }

  @override
  Future<FullscreenSnapshot> enter() async {
    calls.add('enter');
    if (onEnter case final action?) return action();
    if (failEnter) throw StateError('private diagnostic');
    emit(true);
    return const FullscreenSnapshot(enabled: true);
  }

  @override
  Future<FullscreenSnapshot> restore() async {
    calls.add('restore');
    if (failRestore) throw StateError('private diagnostic');
    emit(false);
    return const FullscreenSnapshot(enabled: false);
  }

  @override
  Future<void> close() => _close ??= _release();
  Future<void> _release() async {
    calls.add('close');
    await closeWait;
    enabled = false;
    await events.close();
  }
}
