import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/deterministic_pcm_wav.dart';

void main() {
  test('generates a deterministic three-second PCM16 mono WAV', () {
    final bytes = buildDeterministicPcmWav();
    final data = ByteData.sublistView(bytes);

    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    expect(String.fromCharCodes(bytes.sublist(12, 16)), 'fmt ');
    expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');
    expect(data.getUint16(20, Endian.little), 1);
    expect(data.getUint16(22, Endian.little), 1);
    expect(data.getUint32(24, Endian.little), pocWavSampleRate);
    expect(data.getUint16(34, Endian.little), 16);
    expect(data.getUint32(40, Endian.little), 96000);
    expect(bytes, hasLength(96044));
    expect(
      sha256.convert(bytes).toString(),
      '571edd11f9568729867f4a1db7b5f4318e3868024e41253f5c5ca4a09787d51e',
    );
  });

  test('rejects unsafe or undecodable generator parameters', () {
    expect(
      () => buildDeterministicPcmWav(duration: Duration.zero),
      throwsArgumentError,
    );
    expect(
      () => buildDeterministicPcmWav(sampleRate: 7999),
      throwsArgumentError,
    );
    expect(
      () => buildDeterministicPcmWav(frequencyHz: 8000),
      throwsArgumentError,
    );
    expect(
      () => buildDeterministicPcmWav(amplitude: 0.26),
      throwsArgumentError,
    );
  });
}
