import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/pinned_https_audio_fixture.dart';

void main() {
  test(
    'test fixture identity is fixed to one credential-free HTTPS commit',
    () {
      expect(httpsFixtureUri.scheme, 'https');
      expect(httpsFixtureUri.host, 'raw.githubusercontent.com');
      expect(httpsFixtureUri.userInfo, isEmpty);
      expect(httpsFixtureUri.hasQuery, isFalse);
      expect(httpsFixtureUri.path, contains('/$httpsFixtureCommit/'));
      expect(httpsFixtureCommit, matches(r'^[0-9a-f]{40}$'));
      expect(httpsFixtureSha256, matches(r'^[0-9a-f]{64}$'));
      expect(httpsFixtureLength, 88278);
      expect(httpsFixtureDurationMs, 1000);
    },
  );
  test('in-memory identity check accepts exact bytes and rejects drift', () {
    final sample = [1, 2, 3];
    final hash = sha256.convert(sample).toString();
    verifyFixtureBytes(sample, expectedLength: 3, expectedSha256: hash);
    for (final bytes in [
      [1, 2],
      [1, 2, 4],
      [1, 2, 3, 4],
    ]) {
      expect(
        () =>
            verifyFixtureBytes(bytes, expectedLength: 3, expectedSha256: hash),
        throwsA(isA<HttpsFixtureFailure>()),
      );
    }
  });
  test(
    'invalid identity and oversized fixtures fail without private details',
    () {
      for (final length in [-1, 0, 128 * 1024 + 1]) {
        expect(
          () => verifyFixtureBytes(
            [],
            expectedLength: length,
            expectedSha256: httpsFixtureSha256,
          ),
          throwsA(isA<HttpsFixtureFailure>()),
        );
      }
      expect(
        () => verifyFixtureBytes(
          [1],
          expectedLength: 1,
          expectedSha256: 'private-token',
        ),
        throwsA(isA<HttpsFixtureFailure>()),
      );
      expect(
        const HttpsFixtureFailure().toString(),
        'HttpsFixtureFailure(unavailable-or-invalid)',
      );
    },
  );
}
