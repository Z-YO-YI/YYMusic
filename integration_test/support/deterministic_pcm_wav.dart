import 'dart:typed_data';

const int pocWavSampleRate = 16000;
const int pocWavFrequencyHz = 440;
const Duration pocWavDuration = Duration(seconds: 3);

/// Builds a deterministic, low-amplitude PCM16 mono square-wave test tone.
///
/// The bytes are generated at runtime so no user audio or binary fixture is
/// stored in the repository. The result is only suitable for native playback
/// verification, not as product media.
Uint8List buildDeterministicPcmWav({
  Duration duration = pocWavDuration,
  int sampleRate = pocWavSampleRate,
  int frequencyHz = pocWavFrequencyHz,
  double amplitude = 0.12,
}) {
  if (duration <= Duration.zero || duration > const Duration(seconds: 10)) {
    throw ArgumentError.value(
      duration,
      'duration',
      'must be between 0 and 10 seconds',
    );
  }
  if (sampleRate < 8000 || sampleRate > 48000) {
    throw ArgumentError.value(
      sampleRate,
      'sampleRate',
      'must be between 8000 and 48000',
    );
  }
  if (frequencyHz <= 0 || frequencyHz * 2 >= sampleRate) {
    throw ArgumentError.value(
      frequencyHz,
      'frequencyHz',
      'must be below the Nyquist frequency',
    );
  }
  if (!amplitude.isFinite || amplitude <= 0 || amplitude > 0.25) {
    throw ArgumentError.value(
      amplitude,
      'amplitude',
      'must be greater than 0 and no more than 0.25',
    );
  }

  final sampleCount =
      duration.inMicroseconds * sampleRate ~/ Duration.microsecondsPerSecond;
  if (sampleCount <= 0) {
    throw ArgumentError.value(duration, 'duration', 'produces no samples');
  }
  const channelCount = 1;
  const bitsPerSample = 16;
  const bytesPerSample = bitsPerSample ~/ 8;
  final dataLength = sampleCount * bytesPerSample;
  final bytes = Uint8List(44 + dataLength);
  final data = ByteData.sublistView(bytes);

  _writeAscii(bytes, 0, 'RIFF');
  data.setUint32(4, 36 + dataLength, Endian.little);
  _writeAscii(bytes, 8, 'WAVE');
  _writeAscii(bytes, 12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, channelCount, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * bytesPerSample, Endian.little);
  data.setUint16(32, channelCount * bytesPerSample, Endian.little);
  data.setUint16(34, bitsPerSample, Endian.little);
  _writeAscii(bytes, 36, 'data');
  data.setUint32(40, dataLength, Endian.little);

  final peak = (0x7fff * amplitude).round();
  for (var index = 0; index < sampleCount; index++) {
    final halfWave = index * frequencyHz * 2 ~/ sampleRate;
    data.setInt16(
      44 + index * bytesPerSample,
      halfWave.isEven ? peak : -peak,
      Endian.little,
    );
  }
  return bytes;
}

void _writeAscii(Uint8List bytes, int offset, String value) {
  for (var index = 0; index < value.length; index++) {
    bytes[offset + index] = value.codeUnitAt(index);
  }
}
