import 'dart:convert';

/// Versioned single preference. No defaults, migration writes or playback effects.
abstract final class PlaybackContinuationCodec {
  static String encode(bool enabled) =>
      jsonEncode({'version': 1, 'continueAfterTrack': enabled});

  static bool decode(String source) {
    try {
      if (source.length > 128) throw const FormatException();
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic> ||
          value.length != 2 ||
          value['version'] is! int ||
          value['version'] != 1 ||
          value['continueAfterTrack'] is! bool) {
        throw const FormatException();
      }
      return value['continueAfterTrack'] as bool;
    } catch (_) {
      throw const FormatException('Invalid stored playback continuation');
    }
  }
}
