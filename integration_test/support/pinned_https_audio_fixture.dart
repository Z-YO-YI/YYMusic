import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

// Upstream test data only, never an application source or bundled media asset.
const httpsFixtureCommit = '43e3af79dabb43a69badffbbdfa6d421a1cdb36c';
const httpsFixtureSha256 =
    '1b35cc093f3d56732b19ff936c21b5bca8195135d63708f6c6488eba5803ddce';
const httpsFixtureLength = 88278;
const httpsFixtureDurationMs = 1000;

Uri get httpsFixtureUri => Uri.https(
  'raw.githubusercontent.com',
  '/androidx/media/$httpsFixtureCommit/'
      'libraries/test_data/src/test/assets/media/wav/sample.wav',
);

final class HttpsFixtureFailure implements Exception {
  const HttpsFixtureFailure();

  @override
  String toString() => 'HttpsFixtureFailure(unavailable-or-invalid)';
}

/// Test-only identity check; never puts response bytes or URLs into failures.
void verifyFixtureBytes(
  List<int> bytes, {
  required int expectedLength,
  required String expectedSha256,
}) {
  if (expectedLength <= 0 ||
      expectedLength > 128 * 1024 ||
      !RegExp(r'^[0-9a-f]{64}$').hasMatch(expectedSha256) ||
      bytes.length != expectedLength ||
      sha256.convert(bytes).toString() != expectedSha256) {
    throw const HttpsFixtureFailure();
  }
}

/// Default platform trust, fixed origin, no credentials, redirects or disk IO.
/// The verified bytes are discarded; native playback still uses the HTTPS URI.
Future<void> verifyPinnedHttpsFixture() async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..autoUncompress = false;
  try {
    await () async {
      final whole = await _read(client, range: false);
      verifyFixtureBytes(
        whole,
        expectedLength: httpsFixtureLength,
        expectedSha256: httpsFixtureSha256,
      );
      final prefix = await _read(client, range: true);
      verifyFixtureBytes(
        prefix,
        expectedLength: 78,
        expectedSha256: sha256.convert(whole.sublist(0, 78)).toString(),
      );
    }().timeout(const Duration(seconds: 40));
  } catch (_) {
    throw const HttpsFixtureFailure();
  } finally {
    client.close(force: true);
  }
}

Future<Uint8List> _read(HttpClient client, {required bool range}) async {
  final request = await client
      .getUrl(httpsFixtureUri)
      .timeout(const Duration(seconds: 15));
  request.followRedirects = false;
  if (range) request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-77');
  final response = await request.close().timeout(const Duration(seconds: 15));
  final length = range ? 78 : httpsFixtureLength;
  if (response.statusCode != (range ? 206 : 200) ||
      response.contentLength != length ||
      response.headers.contentType?.mimeType != 'audio/wav' ||
      response.headers.value(HttpHeaders.acceptRangesHeader) != 'bytes' ||
      (range &&
          response.headers.value(HttpHeaders.contentRangeHeader) !=
              'bytes 0-77/$httpsFixtureLength')) {
    throw const HttpsFixtureFailure();
  }
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in response.timeout(const Duration(seconds: 15))) {
    if (bytes.length + chunk.length > length) {
      throw const HttpsFixtureFailure();
    }
    bytes.add(chunk);
  }
  if (bytes.length != length) throw const HttpsFixtureFailure();
  return bytes.takeBytes();
}
