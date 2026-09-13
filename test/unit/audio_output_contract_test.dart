import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/platform/contracts/audio_output_gateway.dart';

void main() {
  test('unknown route has no invented label', () {
    const route = AudioOutputRoute.unknown();
    expect(route.label, isNull);
    expect(route.observation, AudioOutputObservation.unknown);
  });

  test('system default and actual player route are distinct observations', () {
    final system = AudioOutputRoute.systemDefault('Speaker');
    final player = AudioOutputRoute.playerRoute('Speaker');
    expect(system, isNot(player));
    expect(system.observation, AudioOutputObservation.systemDefault);
    expect(player.observation, AudioOutputObservation.playerRoute);
  });

  for (final make in [
    AudioOutputRoute.systemDefault,
    AudioOutputRoute.playerRoute,
  ]) {
    test('$make normalizes labels and compares value identity', () {
      final first = make('  耳机 🎵  ');
      final second = make('耳机 🎵');
      expect(first.label, '耳机 🎵');
      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(make('Speaker')));
    });
    test('$make counts Unicode scalar values rather than UTF-16 units', () {
      expect(make('🎵' * 128).label, '🎵' * 128);
      expect(() => make('🎵' * 129), throwsFormatException);
    });
    for (final bad in [
      '',
      '   ',
      'private\nname',
      'private\u0000name',
      'private\u007fname',
      'private\u0085name',
    ]) {
      test('$make rejects malformed label without leaking it', () {
        try {
          make(bad);
          fail('Expected a validation failure');
        } on FormatException catch (error) {
          expect(error.source, isNull);
          expect(error.message, 'Invalid audio output label');
          expect(error.toString(), isNot(contains('private')));
        }
      });
    }
  }

  test('debug representations never disclose personal device labels', () {
    final route = AudioOutputRoute.playerRoute('Private person headphones');
    final snapshot = AudioOutputSnapshot(route: route, canOpenSettings: true);
    expect(route.toString(), isNot(contains('Private person')));
    expect(snapshot.toString(), isNot(contains('Private person')));
  });

  test('settings capability is independent of route knowledge', () {
    const unknownWithSettings = AudioOutputSnapshot(
      route: AudioOutputRoute.unknown(),
      canOpenSettings: true,
    );
    final knownWithoutSettings = AudioOutputSnapshot(
      route: AudioOutputRoute.systemDefault('Speaker'),
      canOpenSettings: false,
    );
    expect(unknownWithSettings.route.label, isNull);
    expect(unknownWithSettings.canOpenSettings, isTrue);
    expect(knownWithoutSettings.canOpenSettings, isFalse);
  });

  test('snapshot equality includes route provenance and capability', () {
    final first = AudioOutputSnapshot(
      route: AudioOutputRoute.systemDefault('Speaker'),
      canOpenSettings: true,
    );
    final second = AudioOutputSnapshot(
      route: AudioOutputRoute.systemDefault('Speaker'),
      canOpenSettings: true,
    );
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(
      first,
      isNot(AudioOutputSnapshot(route: first.route, canOpenSettings: false)),
    );
    expect(
      first,
      isNot(
        AudioOutputSnapshot(
          route: AudioOutputRoute.playerRoute('Speaker'),
          canOpenSettings: true,
        ),
      ),
    );
  });

  test('unavailable gateway never claims a route or settings launch', () async {
    const gateway = UnavailableAudioOutputGateway();
    expect(await gateway.initialize(), const AudioOutputSnapshot.unavailable());
    expect(await gateway.refresh(), const AudioOutputSnapshot.unavailable());
    expect(await gateway.states.toList(), isEmpty);
    expect(
      await gateway.openSystemSettings(),
      AudioOutputSettingsResult.unavailable,
    );
    await gateway.close();
    await gateway.close();
    expect(
      await gateway.openSystemSettings(),
      AudioOutputSettingsResult.unavailable,
    );
  });
}
