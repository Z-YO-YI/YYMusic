/// Connected devices are not evidence of the current playback route.
enum AudioOutputObservation { unknown, systemDefault, playerRoute }

/// A native observation. A system default is not necessarily this player's sink.
final class AudioOutputRoute {
  const AudioOutputRoute.unknown()
    : observation = AudioOutputObservation.unknown,
      label = null;

  factory AudioOutputRoute.systemDefault(String label) => AudioOutputRoute._(
    AudioOutputObservation.systemDefault,
    _validatedLabel(label),
  );

  factory AudioOutputRoute.playerRoute(String label) => AudioOutputRoute._(
    AudioOutputObservation.playerRoute,
    _validatedLabel(label),
  );

  const AudioOutputRoute._(this.observation, this.label);
  final AudioOutputObservation observation;
  final String? label;

  static String _validatedLabel(String value) {
    final label = value.trim();
    if (label.isEmpty ||
        label.runes.length > 128 ||
        label.runes.any((rune) => rune < 32 || (rune >= 127 && rune <= 159))) {
      // Device labels can contain user names; never include input in errors.
      throw const FormatException('Invalid audio output label');
    }
    return label;
  }

  @override
  bool operator ==(Object other) =>
      other is AudioOutputRoute &&
      observation == other.observation &&
      label == other.label;
  @override
  int get hashCode => Object.hash(observation, label);
  @override
  String toString() => 'AudioOutputRoute(${observation.name})';
}

final class AudioOutputSnapshot {
  const AudioOutputSnapshot({
    required this.route,
    required this.canOpenSettings,
  });
  const AudioOutputSnapshot.unavailable()
    : route = const AudioOutputRoute.unknown(),
      canOpenSettings = false;

  final AudioOutputRoute route;
  final bool canOpenSettings;

  @override
  bool operator ==(Object other) =>
      other is AudioOutputSnapshot &&
      route == other.route &&
      canOpenSettings == other.canOpenSettings;
  @override
  int get hashCode => Object.hash(route, canOpenSettings);
  @override
  String toString() =>
      'AudioOutputSnapshot(${route.observation.name}, settings: $canOpenSettings)';
}

/// Opened means the OS accepted launching settings, not a route switch.
enum AudioOutputSettingsResult { opened, unavailable, failed }

/// Native implementations must observe routes, not guess from attached devices.
/// No device-switch command is exposed until backend support is implemented.
abstract interface class AudioOutputGateway {
  Stream<AudioOutputSnapshot> get states;
  Future<AudioOutputSnapshot> initialize();

  /// Re-read native state after returning from settings or an OS route event.
  /// Errors are not permission to retain a stale route as currently confirmed.
  Future<AudioOutputSnapshot> refresh();
  Future<AudioOutputSettingsResult> openSystemSettings();

  /// Revoke future work, drain accepted native calls, detach event listeners.
  /// Must not close a borrowed audio engine or change playback.
  Future<void> close();
}

/// Honest fallback for runners without a native output protocol.
final class UnavailableAudioOutputGateway implements AudioOutputGateway {
  const UnavailableAudioOutputGateway();
  @override
  Stream<AudioOutputSnapshot> get states => const Stream.empty();
  @override
  Future<AudioOutputSnapshot> initialize() async =>
      const AudioOutputSnapshot.unavailable();
  @override
  Future<AudioOutputSnapshot> refresh() async =>
      const AudioOutputSnapshot.unavailable();
  @override
  Future<AudioOutputSettingsResult> openSystemSettings() async =>
      AudioOutputSettingsResult.unavailable;
  @override
  Future<void> close() async {}
}
