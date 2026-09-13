import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/production_audio.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/platform/audio_output/native_audio_output_gateway.dart';
import 'package:yymusic/platform/contracts/audio_output_gateway.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_audio_output_gateway.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('production factory chooses native output for both platforms', () async {
    for (final platform in YYPlatform.values) {
      final gateway = createProductionAudioOutputGateway(platform);
      expect(gateway, isA<NativeAudioOutputGateway>());
      await gateway.close();
    }
  });

  test('default graph remains honestly unavailable', () async {
    final graph = DependencyGraph();
    await graph.initialize();
    await flush();
    expect(graph.audioOutput.snapshot, const AudioOutputSnapshot.unavailable());
    await graph.close();
  });

  test(
    'root initializes once and closes observer before owned gateway',
    () async {
      final gateway = FakeAudioOutputGateway();
      final engine = FakeAudioEngine();
      final graph = DependencyGraph(
        audioEngine: engine,
        audioOutputGateway: gateway,
      );
      await graph.initialize();
      await graph.initialize();
      await flush();
      expect(gateway.calls, ['initialize']);
      expect(
        graph.audioOutput.snapshot.route.observation,
        AudioOutputObservation.systemDefault,
      );
      expect(engine.calls.where((call) => call == 'play'), isEmpty);
      await graph.close();
      await graph.close();
      expect(gateway.calls, ['initialize', 'close']);
      expect(engine.disposalCount, 1);
    },
  );

  test('slow optional observation does not delay root startup, but close drains it', () async {
    final gate = Completer<AudioOutputSnapshot>();
    final gateway = FakeAudioOutputGateway()..onRead = () => gate.future;
    final engine = FakeAudioEngine();
    final graph = DependencyGraph(
      audioEngine: engine,
      audioOutputGateway: gateway,
    );
    await graph.initialize();
    await flush();
    expect(gateway.calls, ['initialize']);
    var closed = false;
    final closing = graph.close().then((_) => closed = true);
    await flush();
    expect(closed, isFalse);
    expect(gateway.calls, ['initialize']);
    expect(engine.disposalCount, 0);
    gate.complete(const AudioOutputSnapshot.unavailable());
    await closing;
    expect(gateway.calls, ['initialize', 'close']);
    expect(engine.disposalCount, 1);
    await graph.audioOutput.refresh();
    expect(gateway.calls, ['initialize', 'close']);
  });

  test(
    'gateway close failure is safe and does not skip engine cleanup',
    () async {
      final gateway = FakeAudioOutputGateway()
        ..closeError = StateError('private output payload');
      final engine = FakeAudioEngine();
      final graph = DependencyGraph(
        audioEngine: engine,
        audioOutputGateway: gateway,
      );
      await graph.initialize();
      await flush();
      await expectLater(
        graph.close(),
        throwsA(
          isA<DomainFailure>().having(
            (failure) => failure.diagnosticId,
            'safe diagnostic',
            'app.shutdown-failed',
          ),
        ),
      );
      expect(engine.disposalCount, 1);
    },
  );

  test('close before initialize revokes native reads', () async {
    final gateway = FakeAudioOutputGateway();
    final graph = DependencyGraph(audioOutputGateway: gateway);
    await graph.close();
    await graph.initialize();
    expect(gateway.calls, ['close']);
  });
}
