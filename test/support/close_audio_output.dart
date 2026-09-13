import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/platform/audio_output/audio_output_controller.dart';
import 'package:yymusic/platform/contracts/audio_output_gateway.dart';

Future<void> closeAudioOutput(
  WidgetTester tester,
  AudioOutputController output,
  AudioOutputGateway gateway,
) async {
  var closed = false;
  final closing = output
      .close()
      .then((_) => gateway.close())
      .then((_) => closed = true);
  final elapsed = Stopwatch()..start();
  while (!closed && elapsed.elapsed < const Duration(seconds: 5)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump(Duration.zero);
  }
  elapsed.stop();
  expect(closed, isTrue, reason: 'Output fixture must drain and detach');
  await closing;
}
