import 'dart:async';

import 'package:yymusic/platform/contracts/audio_output_gateway.dart';

final class FakeAudioOutputGateway implements AudioOutputGateway {
  final events = StreamController<AudioOutputSnapshot>.broadcast(sync: true);
  final calls = <String>[];
  Future<AudioOutputSnapshot> Function()? onRead;
  Object? closeError;
  @override
  Stream<AudioOutputSnapshot> get states => events.stream;
  Future<AudioOutputSnapshot> _read() async =>
      await onRead?.call() ??
      AudioOutputSnapshot(
        route: AudioOutputRoute.systemDefault('Test output'),
        canOpenSettings: true,
      );
  @override
  Future<AudioOutputSnapshot> initialize() {
    calls.add('initialize');
    return _read();
  }

  @override
  Future<AudioOutputSnapshot> refresh() {
    calls.add('refresh');
    return _read();
  }

  @override
  Future<AudioOutputSettingsResult> openSystemSettings() async {
    calls.add('open');
    return AudioOutputSettingsResult.opened;
  }

  @override
  Future<void> close() async {
    calls.add('close');
    if (events.hasListener) throw StateError('Observation still attached');
    await events.close();
    if (closeError case final error?) throw error;
  }
}
